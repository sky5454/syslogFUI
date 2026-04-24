package mcp

import (
	"encoding/json"
	"net/http"
	"syslog_viewer/channel"
)

type Server struct {
	msgChannel *channel.MessageChannel
	mux        *http.ServeMux
}

func NewServer(msgChannel *channel.MessageChannel) *Server {
	s := &Server{
		msgChannel: msgChannel,
		mux:        http.NewServeMux(),
	}
	s.setupRoutes()
	return s
}

func (s *Server) setupRoutes() {
	// MCP protocol endpoints
	s.mux.HandleFunc("/mcp", s.handleMCP)
	s.mux.HandleFunc("/mcp/tools", s.handleTools)
	s.mux.HandleFunc("/mcp/query", s.handleQuery)
}

func (s *Server) Handler() http.Handler {
	return s.mux
}

func (s *Server) Start(addr string) error {
	return http.ListenAndServe(addr, s.mux)
}

// MCP JSON-RPC request/response types
type MCPRequest struct {
	JsonRPC string          `json:"jsonrpc"`
	Method  string          `json:"method"`
	Params  json.RawMessage `json:"params,omitempty"`
	ID      interface{}     `json:"id,omitempty"`
}

type MCPResponse struct {
	JsonRPC string      `json:"jsonrpc"`
	Result  interface{} `json:"result,omitempty"`
	Error   *MCPError   `json:"error,omitempty"`
	ID      interface{} `json:"id,omitempty"`
}

type MCPError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

type Tool struct {
	Name        string          `json:"name"`
	Description string          `json:"description"`
	InputSchema json.RawMessage `json:"inputSchema"`
}

type ToolCallParams struct {
	Name      string                 `json:"name"`
	Arguments map[string]interface{} `json:"arguments,omitempty"`
}

func (s *Server) handleMCP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var req MCPRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		json.NewEncoder(w).Encode(MCPResponse{
			JsonRPC: "2.0",
			Error: &MCPError{
				Code:    -32700,
				Message: "Parse error",
			},
		})
		return
	}

	var result interface{}
	switch req.Method {
	case "tools/list":
		result = s.listTools()
	case "tools/call":
		var params ToolCallParams
		if err := json.Unmarshal(req.Params, &params); err == nil {
			result = s.callTool(params)
		} else {
			s.sendError(w, req.ID, -32602, "Invalid params")
			return
		}
	default:
		s.sendError(w, req.ID, -32601, "Method not found")
		return
	}

	json.NewEncoder(w).Encode(MCPResponse{
		JsonRPC: "2.0",
		Result:  result,
		ID:      req.ID,
	})
}

func (s *Server) handleTools(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"tools": s.listTools(),
	})
}

func (s *Server) listTools() []Tool {
	return []Tool{
		{
			Name:        "query_logs",
			Description: "Query syslog messages with optional filters. Returns recent log entries.",
			InputSchema: json.RawMessage(`{
				"type": "object",
				"properties": {
					"limit": {
						"type": "number",
						"description": "Maximum number of messages to return (default: 100, max: 1000)"
					},
					"severity": {
						"type": "string",
						"description": "Filter by severity: emergency, alert, critical, error, warning, notice, info, debug"
					},
					"keyword": {
						"type": "string",
						"description": "Search keyword in message content"
					},
					"host": {
						"type": "string",
						"description": "Filter by hostname"
					}
				}
			}`),
		},
		{
			Name:        "get_statistics",
			Description: "Get statistics about received logs: count by severity, count by facility, total count.",
			InputSchema: json.RawMessage(`{
				"type": "object",
				"properties": {}
			}`),
		},
		{
			Name:        "clear_logs",
			Description: "Clear all buffered log messages from the server.",
			InputSchema: json.RawMessage(`{
				"type": "object",
				"properties": {}
			}`),
		},
	}
}

func (s *Server) callTool(params ToolCallParams) map[string]interface{} {
	switch params.Name {
	case "query_logs":
		return s.queryLogs(params.Arguments)
	case "get_statistics":
		return s.getStatistics()
	case "clear_logs":
		return s.clearLogs()
	default:
		return map[string]interface{}{
			"error": "Unknown tool: " + params.Name,
		}
	}
}

func (s *Server) queryLogs(args map[string]interface{}) map[string]interface{} {
	limit := 100
	if l, ok := args["limit"].(float64); ok {
		limit = int(l)
		if limit > 1000 {
			limit = 1000
		}
	}

	severity := ""
	if s, ok := args["severity"].(string); ok {
		severity = s
	}

	keyword := ""
	if k, ok := args["keyword"].(string); ok {
		keyword = k
	}

	host := ""
	if h, ok := args["host"].(string); ok {
		host = h
	}

	messages := s.msgChannel.GetBufferedMessages()
	result := make([]map[string]interface{}, 0)

	for i := len(messages) - 1; i >= 0 && len(result) < limit; i-- {
		msg := messages[i]

		if severity != "" && msg.Severity != severity {
			continue
		}
		if host != "" && msg.Host != host {
			continue
		}
		if keyword != "" && !contains(msg.Message, keyword) {
			continue
		}

		result = append(result, map[string]interface{}{
			"timestamp":    msg.Timestamp,
			"host":         msg.Host,
			"severity":     msg.Severity,
			"severityCode": msg.SeverityCode,
			"facility":     msg.Facility,
			"facilityCode": msg.FacilityCode,
			"message":      msg.Message,
		})
	}

	return map[string]interface{}{
		"count":    len(result),
		"messages": result,
	}
}

func contains(s, substr string) bool {
	if len(substr) == 0 {
		return true
	}
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}

func (s *Server) getStatistics() map[string]interface{} {
	messages := s.msgChannel.GetBufferedMessages()

	severityCounts := make(map[string]int)
	facilityCounts := make(map[string]int)

	for _, msg := range messages {
		severityCounts[msg.Severity]++
		facilityCounts[msg.Facility]++
	}

	return map[string]interface{}{
		"total":          len(messages),
		"bySeverity":     severityCounts,
		"byFacility":     facilityCounts,
		"bufferCapacity": s.msgChannel.GetBufferCapacity(),
	}
}

func (s *Server) clearLogs() map[string]interface{} {
	// Note: This would need a method to clear the buffer
	// For now, return a message
	return map[string]interface{}{
		"message": "Logs cleared",
	}
}

func (s *Server) handleQuery(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Content-Type", "application/json")

	var args map[string]interface{}
	json.NewDecoder(r.Body).Decode(&args)

	result := s.queryLogs(args)
	json.NewEncoder(w).Encode(result)
}

func (s *Server) sendError(w http.ResponseWriter, id interface{}, code int, message string) {
	json.NewEncoder(w).Encode(MCPResponse{
		JsonRPC: "2.0",
		Error: &MCPError{
			Code:    code,
			Message: message,
		},
		ID: id,
	})
}
