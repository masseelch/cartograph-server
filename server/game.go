package cartograph

import "github.com/masseelch/go-token"

type Game struct {
	ID      token.Token      `json:"id"`
	Players map[string]*Plan `json:"players"`
}

func NewGame() *Game {
	t, err := token.GenerateToken(6)
	if err != nil {
		panic(err)
	}

	return &Game{
		ID:      t,
		Players: make(map[string]*Plan),
	}
}
