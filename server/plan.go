package cartograph

import (
	"github.com/olekukonko/tablewriter"
	"github.com/ttacon/chalk"
	"math"
	"strings"
)

const (
	Blank Terrain = iota
	Field
	Forrest
	Monster
	Mountains
	Village
	Water
)

type (
	// The terrain type of a tile. Used in MapTiles and Shapes to place.
	Terrain int

	// A position in a plan.
	Pos struct {
		X int `json:"x"`
		Y int `json:"y"`
	}

	// A plan to play on.
	// Pos(0,0) is the top-left corner of the map.
	Plan struct {
		Tiles []Terrain `json:"tiles"`
		Ruins []Pos     `json:"ruins"`
	}
)

func NewDefaultPlan() *Plan {
	p := &Plan{
		Tiles: make([]Terrain, 121),
		Ruins: []Pos{{5, 1}, {1, 2}, {9, 2}, {1, 8}, {5, 9}, {9, 8}},
	}

	for i := range p.Tiles {
		switch p.IndexToPos(i) {
		case Pos{3, 1}, Pos{8, 2}, Pos{5, 5}, Pos{2, 8}, Pos{7, 9}:
			p.Tiles[i] = Mountains
		default:
			p.Tiles[i] = Blank
		}
	}

	return p
}

func (p Plan) SideLength() int {
	return int(math.Sqrt(float64(cap(p.Tiles))))
}

func (p Plan) PosToIndex(pos Pos) int {
	return pos.Y*p.SideLength() + pos.X
}

func (p Plan) IndexToPos(i int) Pos {
	x := i % p.SideLength()
	y := (i - x) / p.SideLength()

	return Pos{x, y}
}

func (p Plan) String() string {
	b := new(strings.Builder)

	// Side length of a plan.
	l := p.SideLength()

	t := tablewriter.NewWriter(b)
	t.SetRowSeparator("-")
	t.SetRowLine(true)

	for y := 0; y < l; y++ {
		row := make([]string, l)

		for x := 0; x < l; x++ {
			row[x] = p.Tiles[p.PosToIndex(Pos{x, y})].String()
		}

		t.Append(row)
	}

	t.Render()

	return b.String()
}

func (t Terrain) String() string {
	switch t {

	case Blank:
		return " "

	case Field:
		return chalk.Yellow.Color("A")

	case Forrest:
		return chalk.Green.Color("B")

	case Monster:
		return chalk.Red.Color("M")

	case Mountains:
		return chalk.White.Color("G")

	case Village:
		return chalk.Magenta.Color("D")

	case Water:
		return chalk.Blue.Color("W")
	}

	return ""
}
