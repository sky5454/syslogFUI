package syslog

import (
	"fmt"
	"log"
	"time"

	"gopkg.in/mcuadros/go-syslog.v2"
	"syslog_viewer/channel"
	"syslog_viewer/message"
)

type Server struct {
	syslogServer *syslog.Server
	channel      *channel.MessageChannel
	isRunning    bool
}

func New(msgChannel *channel.MessageChannel) *Server {
	return &Server{
		channel: msgChannel,
	}
}

func (s *Server) Start(protocol string, address string) error {
	if s.isRunning {
		return fmt.Errorf("server already running")
	}

	s.syslogServer = syslog.NewServer()
	s.syslogServer.SetFormat(syslog.Automatic)

	logChannel := make(syslog.LogPartsChannel)
	handler := syslog.NewChannelHandler(logChannel)
	s.syslogServer.SetHandler(handler)

	switch protocol {
	case "udp":
		if err := s.syslogServer.ListenUDP(address); err != nil {
			return fmt.Errorf("failed to listen UDP: %w", err)
		}
		log.Printf("Syslog UDP server starting on %s", address)
	case "tcp":
		if err := s.syslogServer.ListenTCP(address); err != nil {
			return fmt.Errorf("failed to listen TCP: %w", err)
		}
		log.Printf("Syslog TCP server starting on %s", address)
	case "all":
		// Try to start both TCP and UDP
		udpErr := s.syslogServer.ListenUDP(address)
		tcpErr := s.syslogServer.ListenTCP(address)
		if udpErr != nil && tcpErr != nil {
			return fmt.Errorf("failed to listen on both UDP and TCP: UDP=%v, TCP=%w", udpErr, tcpErr)
		}
		log.Printf("Syslog server (UDP+TCP) starting on %s", address)
	default:
		return fmt.Errorf("unsupported protocol: %s (use: udp, tcp, all)", protocol)
	}

	if err := s.syslogServer.Boot(); err != nil {
		return fmt.Errorf("failed to boot: %w", err)
	}

	s.isRunning = true
	go s.syslogServer.Wait()

	go s.processLogs(logChannel)

	log.Printf("Syslog server started on %s (%s)", address, protocol)
	return nil
}

func (s *Server) processLogs(channel syslog.LogPartsChannel) {
	for logParts := range channel {
		msg := s.parseLogParts(logParts)
		s.channel.Broadcast(msg)
	}
}

func (s *Server) Stop() error {
	if !s.isRunning {
		return nil
	}
	s.syslogServer.Kill()
	s.isRunning = false
	log.Println("Syslog server stopped")
	return nil
}

func (s *Server) IsRunning() bool {
	return s.isRunning
}

func (s *Server) parseLogParts(logParts map[string]interface{}) *message.SyslogMessage {
	// Debug: print all available keys
	log.Printf("DEBUG logParts keys: %v", fmt.Sprintf("%v", mapKeys(logParts)))

	timestamp := time.Now()
	if ts, ok := logParts["timestamp"].(time.Time); ok {
		timestamp = ts
	}

	hostname := ""
	if host, ok := logParts["hostname"].(string); ok {
		hostname = host
	}

	// Try multiple possible keys for message
	msg := ""
	if m, ok := logParts["message"].(string); ok {
		msg = m
	} else if m, ok := logParts["msg"].(string); ok {
		msg = m
	} else if m, ok := logParts["content"].(string); ok {
		msg = m
	}

	severity := 6 // default to Info
	if sev, ok := logParts["severity"].(int); ok {
		severity = sev
	} else if sev, ok := logParts["severity"].(int64); ok {
		severity = int(sev)
	}

	facility := 1 // default to User
	if fac, ok := logParts["facility"].(int); ok {
		facility = fac
	} else if fac, ok := logParts["facility"].(int64); ok {
		facility = int(fac)
	}

	raw := ""
	if r, ok := logParts["raw"].(string); ok {
		raw = r
	}

	return &message.SyslogMessage{
		Timestamp:    timestamp,
		Host:         hostname,
		Severity:     message.SeverityToString(severity),
		SeverityCode: severity,
		Facility:     message.FacilityToString(facility),
		FacilityCode: facility,
		Message:      msg,
		RawMessage:   raw,
	}
}

func mapKeys(m map[string]interface{}) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	return keys
}
