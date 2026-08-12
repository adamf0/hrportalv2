package helper

import (
	"log"
	"sync"

	"github.com/gofiber/websocket/v2"
)

type SdmWsHub struct {
	clients map[*websocket.Conn]bool
	mu      sync.RWMutex
}

var GlobalSdmWsHub = &SdmWsHub{
	clients: make(map[*websocket.Conn]bool),
}

func (h *SdmWsHub) Register(conn *websocket.Conn) {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.clients[conn] = true
	log.Printf("[SDM WebSocket] Client connected. Total active SDM clients: %d", len(h.clients))
}

func (h *SdmWsHub) Unregister(conn *websocket.Conn) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if _, ok := h.clients[conn]; ok {
		conn.Close()
		delete(h.clients, conn)
		log.Printf("[SDM WebSocket] Client disconnected. Remaining SDM clients: %d", len(h.clients))
	}
}

func (h *SdmWsHub) Broadcast(payload interface{}) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	for conn := range h.clients {
		if conn != nil {
			err := conn.WriteJSON(payload)
			if err != nil {
				log.Printf("[SDM WebSocket] Error broadcasting to client: %v", err)
			}
		}
	}
}
