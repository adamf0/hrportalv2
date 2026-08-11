package presentation

import (
	"sync"

	"github.com/gofiber/websocket/v2"
)

type RealtimeAttendancePayload struct {
	Type        string `json:"type"` // "initial_state", "check_in", "check_out"
	Nip         string `json:"nip"`
	Nidn        string `json:"nidn,omitempty"`
	Tanggal     string `json:"tanggal"`
	AbsenMasuk  string `json:"absen_masuk,omitempty"`
	AbsenKeluar string `json:"absen_keluar,omitempty"`
}

type AttendanceWsHub struct {
	clients map[string]*websocket.Conn
	mu      sync.RWMutex
}

var GlobalAttendanceWsHub = &AttendanceWsHub{
	clients: make(map[string]*websocket.Conn),
}

func (h *AttendanceWsHub) Register(key string, conn *websocket.Conn) {
	if key == "" {
		return
	}
	h.mu.Lock()
	defer h.mu.Unlock()
	h.clients[key] = conn
}

func (h *AttendanceWsHub) RegisterUser(nip string, nidn string, conn *websocket.Conn) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if nip != "" {
		h.clients[nip] = conn
	}
	if nidn != "" {
		h.clients[nidn] = conn
	}
}

func (h *AttendanceWsHub) Unregister(key string) {
	if key == "" {
		return
	}
	h.mu.Lock()
	defer h.mu.Unlock()
	if conn, ok := h.clients[key]; ok {
		conn.Close()
		delete(h.clients, key)
	}
}

func (h *AttendanceWsHub) UnregisterUser(nip string, nidn string) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if nip != "" {
		if conn, ok := h.clients[nip]; ok && conn != nil {
			conn.Close()
			delete(h.clients, nip)
		}
	}
	if nidn != "" {
		if conn, ok := h.clients[nidn]; ok && conn != nil {
			conn.Close()
			delete(h.clients, nidn)
		}
	}
}

func (h *AttendanceWsHub) BroadcastToUser(nip string, nidn string, payload RealtimeAttendancePayload) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	sent := false
	if nip != "" {
		if conn, ok := h.clients[nip]; ok && conn != nil {
			_ = conn.WriteJSON(payload)
			sent = true
		}
	}
	if !sent && nidn != "" {
		if conn, ok := h.clients[nidn]; ok && conn != nil {
			_ = conn.WriteJSON(payload)
		}
	}
}
