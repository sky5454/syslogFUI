package main

import (
	"flag"
	"log"
	"os"
	"os/signal"
	"syscall"

	httpPkg "syslog_viewer/http"
	"syslog_viewer/mcp"
	"syslog_viewer/syslog"
	ws "syslog_viewer/websocket"
	"syslog_viewer/channel"
)

const version = "1.0.0"

var (
	syslogProtocol = flag.String("protocol", "all", "Syslog protocol (udp, tcp, or all)")
	syslogAddress  = flag.String("syslog", "0.0.0.0:514", "Syslog server address")
	httpAddress   = flag.String("http", "localhost:8765", "HTTP/WebSocket server address")
	bufferSize    = flag.Int("buffer", 10000, "Message buffer size for replay")
)

func main() {
	flag.Parse()

	log.Printf("Go backend version: %s", version)

	msgChannel := channel.New(*bufferSize)

	wsHandler := ws.NewHandler(msgChannel)
	mcpServer := mcp.NewServer(msgChannel)

	httpSrv := httpPkg.NewServer(*httpAddress, wsHandler, mcpServer)

	syslogServer := syslog.New(msgChannel)

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-sigChan
		log.Println("Shutting down...")
		syslogServer.Stop()
		httpSrv.Stop()
		os.Exit(0)
	}()

	log.Printf("Starting syslog server on %s (%s)", *syslogAddress, *syslogProtocol)
	if err := syslogServer.Start(*syslogProtocol, *syslogAddress); err != nil {
		log.Fatalf("Failed to start syslog server: %v", err)
	}

	log.Printf("Starting HTTP/WebSocket server on %s", *httpAddress)
	if err := httpSrv.Start(); err != nil {
		log.Fatalf("Failed to start HTTP server: %v", err)
	}
}
