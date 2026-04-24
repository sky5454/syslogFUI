package websocket

import (
	"encoding/json"
	"log"
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
	"syslog_viewer/channel"
	"syslog_viewer/message"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

type Handler struct {
	channel *channel.MessageChannel
	clients sync.Map
}

func NewHandler(msgChannel *channel.MessageChannel) *Handler {
	return &Handler{
		channel: msgChannel,
	}
}

func (h *Handler) HandleWs(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket upgrade failed: %v", err)
		return
	}

	client := &channel.Client{
		Send: make(chan []byte, 10240),  // Increased buffer
	}

	h.channel.Register(client)
	h.clients.Store(conn, client)

	defer func() {
		h.channel.Unregister(client)
		h.clients.Delete(conn)
		conn.Close()
	}()

	go h.readPump(conn)
	h.writePump(client, conn)
}

func (h *Handler) readPump(conn *websocket.Conn) {
	defer conn.Close()
	for {
		_, _, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("WebSocket read error: %v", err)
			}
			break
		}
	}
}

func (h *Handler) writePump(client *channel.Client, conn *websocket.Conn) {
	for data := range client.Send {
		if err := conn.WriteMessage(websocket.TextMessage, data); err != nil {
			log.Printf("WebSocket write error: %v", err)
			break
		}
	}
}

func (h *Handler) SendMessageHistory(conn *websocket.Conn, messages []message.SyslogMessage) error {
	for _, msg := range messages {
		data, err := json.Marshal(msg)
		if err != nil {
			continue
		}
		if err := conn.WriteMessage(websocket.TextMessage, data); err != nil {
			return err
		}
	}
	return nil
}
