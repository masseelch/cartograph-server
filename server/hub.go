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

func (h *Hub) playerData(nickname string) []byte {
	j, err := json.Marshal(h.game.Players[nickname])
	if err != nil {
		panic(err)
	}

	return j
}

func (h *Hub) Clear() {
	h.game = NewGame()
}

func (h *Hub) Run() {
	for {
		select {
		case c := <-h.register:
			h.clients[c.nickname] = c
			if _, ok := h.game.Players[c.nickname]; !ok {
				h.game.Players[c.nickname] = &Player{c.nickname, NewDefaultPlan()}
			}
			c.send <- h.gameData()

			// Tell all other clients that there is a new one.
			d := h.playerData(c.nickname)
			for _, client := range h.clients {
				if client.nickname != c.nickname {
					select {
					case client.send <- d:
					default:
						close(client.send)
						delete(h.clients, client.nickname)
					}
				}
			}
		case client := <-h.unregister:
			if _, ok := h.clients[client.nickname]; ok {
				delete(h.clients, client.nickname)
				close(client.send)
			}
		case updatedClient := <-h.broadcast:
			d := h.playerData(updatedClient.nickname)
			for _, client := range h.clients {
				select {
				case client.send <- d:
				default:
					close(client.send)
					delete(h.clients, client.nickname)
				}
			}
		}
	}
}

