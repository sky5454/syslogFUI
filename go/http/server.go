package http

import (
	"net/http"
	"syslog_viewer/mcp"
	"syslog_viewer/websocket"
)

type Server struct {
	handler     *websocket.Handler
	mcpServer   *mcp.Server
	server      *http.Server
}

func NewServer(addr string, handler *websocket.Handler, mcpServer *mcp.Server) *Server {
	return &Server{
		handler:   handler,
		mcpServer: mcpServer,
		server: &http.Server{
			Addr:    addr,
			Handler: nil,
		},
	}
}

func (s *Server) Start() error {
	http.HandleFunc("/ws", s.handler.HandleWs)
	http.Handle("/mcp/", s.mcpServer.Handler())
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})
	return s.server.ListenAndServe()
}

func (s *Server) Stop() error {
	return s.server.Close()
}
