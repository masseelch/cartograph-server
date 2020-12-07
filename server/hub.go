package cartograph

import (
	"encoding/json"
)

type Hub struct {
	game *Game

	// All registered clients.
	clients map[string]*Client

	// Inbound messages from the clients.
	broadcast chan *Client

	// Register requests from the clients.
	register chan *Client

	// Unregister requests from clients.
	unregister chan *Client
}

func NewHub() *Hub {
	return &Hub{
		game:       NewGame(),
		broadcast:  make(chan *Client),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		clients:    make(map[string]*Client),
	}
}

func (h *Hub) gameData() []byte {
	j, err := json.Marshal(h.game)
	if err != nil {
		panic(err)
	}

	return j
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.clients[client.nickname] = client
			if _, ok := h.game.Players[client.nickname]; !ok {
				h.game.Players[client.nickname] = NewDefaultPlan()
			}
			client.send <- h.gameData()
		case client := <-h.unregister:
			if _, ok := h.clients[client.nickname]; ok {
				delete(h.clients, client.nickname)
				close(client.send)
			}
		case <-h.broadcast:
			for _, client := range h.clients {
				select {
				case client.send <- h.gameData():
				default:
					close(client.send)
					delete(h.clients, client.nickname)
				}
			}
		}
	}
}
