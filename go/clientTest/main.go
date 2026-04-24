package main

import (
	"flag"
	"fmt"
	"log"
	"net"
	"os"
	"sync"
	"time"
)

const (
	LOG_EMERG   = 0
	LOG_ALERT   = 1
	LOG_CRIT    = 2
	LOG_ERR     = 3
	LOG_WARNING = 4
	LOG_NOTICE  = 5
	LOG_INFO    = 6
	LOG_DEBUG   = 7

	LOG_KERN      = 0
	LOG_USER      = 1
	LOG_MAIL      = 2
	LOG_DAEMON    = 3
	LOG_AUTH      = 4
	LOG_SYSLOG    = 5
	LOG_LPR       = 6
	LOG_NEWS      = 7
	LOG_UUCP      = 8
	LOG_CRON      = 9
	LOG_AUTHPRIV  = 10
	LOG_FTP       = 11
)

func syslogPri(severity, facility int) int {
	return facility*8 + severity
}

var (
	serverAddr = flag.String("server", "localhost:514", "Syslog server address")
	protocol   = flag.String("protocol", "tcp", "Protocol: udp or tcp")
	threads    = flag.Int("threads", 4, "Number of concurrent threads")
	count      = flag.Int("count", 100, "Number of messages per thread")
)

func main() {
	flag.Parse()

	fmt.Printf("Starting syslog client test\n")
	fmt.Printf("Server: %s\n", *serverAddr)
	fmt.Printf("Protocol: %s\n", *protocol)
	fmt.Printf("Threads: %d\n", *threads)
	fmt.Printf("Messages per thread: %d\n", *count)
	fmt.Printf("Total messages: %d\n", *threads**count)
	fmt.Println()

	var wg sync.WaitGroup
	var sentCount int64
	var severityCount struct {
		info    int64
		warning int64
		error   int64
		debug   int64
	}
	var countMu sync.Mutex

	startTime := time.Now()

	for i := 0; i < *threads; i++ {
		wg.Add(1)
		go func(threadID int) {
			defer wg.Done()
			info, warning, error, debug := sendMessages(threadID)
			countMu.Lock()
			sentCount += int64(info + warning + error + debug)
			severityCount.info += int64(info)
			severityCount.warning += int64(warning)
			severityCount.error += int64(error)
			severityCount.debug += int64(debug)
			countMu.Unlock()
		}(i)
	}

	wg.Wait()

	elapsed := time.Since(startTime)

	fmt.Println()
	fmt.Printf("Completed!\n")
	fmt.Printf("Total time: %v\n", elapsed)
	fmt.Printf("Messages sent: %d\n", sentCount)
	fmt.Printf("  INFO:     %d\n", severityCount.info)
	fmt.Printf("  WARNING:  %d\n", severityCount.warning)
	fmt.Printf("  ERROR:    %d\n", severityCount.error)
	fmt.Printf("  DEBUG:    %d\n", severityCount.debug)
	fmt.Printf("Rate: %.2f msg/sec\n", float64(sentCount)/elapsed.Seconds())
}

func sendMessages(threadID int) (int, int, int, int) {
	var conn net.Conn
	var err error
	var infoCount, warningCount, errorCount, debugCount int

	// Connect for each message batch
	if *protocol == "tcp" {
		conn, err = net.Dial("tcp", *serverAddr)
	} else {
		conn, err = net.Dial("udp", *serverAddr)
	}

	if err != nil {
		log.Printf("Thread %d: Failed to connect: %v", threadID, err)
		return 0, 0, 0, 0
	}
	defer conn.Close()

	hostname, _ := os.Hostname()

	// 分配: INFO 70%, WARNING 20%, ERROR 8%, DEBUG 2%
	for i := 0; i < *count; i++ {
		var pri int
		var severity string
		switch i % 100 {
		case 0, 1: // 2%
			pri = syslogPri(LOG_DEBUG, LOG_USER)
			severity = "DEBUG"
		case 2, 3, 4, 5, 6, 7, 8, 9: // 8%
			pri = syslogPri(LOG_ERR, LOG_USER)
			severity = "ERROR"
		case 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29: // 20%
			pri = syslogPri(LOG_WARNING, LOG_USER)
			severity = "WARNING"
		default: // 70%
			pri = syslogPri(LOG_INFO, LOG_USER)
			severity = "INFO"
		}
		msg := fmt.Sprintf("[%s] Test #%d from thread %d", severity, i, threadID)
		// RFC5424-like format: no APPNAME[PID] before the colon, just the message
		syslogMsg := fmt.Sprintf("<%d>%s %s client: %s\n",
			pri,
			time.Now().Format("Jan 02 15:04:05"),
			hostname,
			msg)

		_, err := conn.Write([]byte(syslogMsg))
		if err != nil {
			log.Printf("Thread %d: Write error: %v", threadID, err)
			break
		}
		switch severity {
		case "DEBUG":
			debugCount++
		case "ERROR":
			errorCount++
		case "WARNING":
			warningCount++
		case "INFO":
			infoCount++
		}
	}
	return infoCount, warningCount, errorCount, debugCount
}
