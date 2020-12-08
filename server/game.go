package cartograph

import "github.com/masseelch/go-token"

type (
	Game struct {
		ID      token.Token        `json:"id"`
		Players map[string]*Player `json:"players"`
	}
	Player struct {
		Nickname string `json:"nickname"`
		Plan     *Plan  `json:"plan"`
	}
)

func NewGame() *Game {
	t, err := token.GenerateToken(6)
	if err != nil {
		panic(err)
	}

	return &Game{
		ID:      t,
		Players: make(map[string]*Player),
	}
}
