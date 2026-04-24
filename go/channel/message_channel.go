package channel

import (
	"encoding/json"
	"sync"
	"time"
	"syslog_viewer/message"
)

type Client struct {
	Send chan []byte
}

type MessageChannel struct {
	mu      sync.RWMutex
	clients map[*Client]struct{}
	buffer  *CircleBuffer
}

func New(bufferSize int) *MessageChannel {
	return &MessageChannel{
		clients: make(map[*Client]struct{}),
		buffer:  NewCircleBuffer(bufferSize),
	}
}

func (mc *MessageChannel) Broadcast(msg *message.SyslogMessage) {
	mc.buffer.Add(*msg)

	data, err := json.Marshal(msg)
	if err != nil {
		return
	}

	mc.mu.RLock()
	defer mc.mu.RUnlock()

	for client := range mc.clients {
		select {
		case client.Send <- data:
		case <-time.After(time.Millisecond * 10):
			// Retry once after 10ms
			select {
			case client.Send <- data:
			default:
				// Still full, skip this client
			}
		}
	}
}

func (mc *MessageChannel) Register(client *Client) {
	mc.mu.Lock()
	defer mc.mu.Unlock()
	mc.clients[client] = struct{}{}
}

func (mc *MessageChannel) Unregister(client *Client) {
	mc.mu.Lock()
	defer mc.mu.Unlock()
	delete(mc.clients, client)
	close(client.Send)
}

func (mc *MessageChannel) GetBufferedMessages() []message.SyslogMessage {
	return mc.buffer.GetAll()
}

type CircleBuffer struct {
	messages []message.SyslogMessage
	size     int
	index    int
	mu       sync.Mutex
	count    int
}

func NewCircleBuffer(size int) *CircleBuffer {
	return &CircleBuffer{
		messages: make([]message.SyslogMessage, size),
		size:     size,
	}
}

func (cb *CircleBuffer) Add(msg message.SyslogMessage) {
	cb.mu.Lock()
	defer cb.mu.Unlock()
	cb.messages[cb.index] = msg
	cb.index = (cb.index + 1) % cb.size
	if cb.count < cb.size {
		cb.count++
	}
}

func (cb *CircleBuffer) GetAll() []message.SyslogMessage {
	cb.mu.Lock()
	defer cb.mu.Unlock()

	if cb.count == 0 {
		return []message.SyslogMessage{}
	}

	result := make([]message.SyslogMessage, 0, cb.count)

	if cb.count < cb.size {
		result = append(result, cb.messages[:cb.count]...)
	} else {
		result = append(result, cb.messages[cb.index:]...)
		result = append(result, cb.messages[:cb.index]...)
	}

	return result
}

func (mc *MessageChannel) GetBufferCapacity() int {
	return mc.buffer.size
}
