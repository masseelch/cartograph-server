package cartograph

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

	// A position in a map. or a shape
	Pos struct {
		X int
		Y int
	}

	// The tiles of a map.
	Tile struct {
		Terrain Terrain
		Pos     Pos
	}

	// A map to play on.
	// Pos(0,0) is the top-left corner of the map.
	Map struct {
		// Side length of the map-square.
		Size  int
		Tiles []Tile
	}

	// The shape of new tiles to place on the map.
	// A shape is a virtual 4x4 square. The positions mark the filled out parts of the shape.
	// Pos(0,0) marks the top left corner of a shape.
	// A shape can be rotated in 90° steps clock- or counterclockwise.
	// A shape can be
	Shape struct {
		Terrain   Terrain
		Positions []Pos
	}
)
