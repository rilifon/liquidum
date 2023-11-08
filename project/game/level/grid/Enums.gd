extends Node
# These enums are made to be used interchangeably because they always have the same values.
# So be very careful when changing the order of elements.
# If necessary for type checking, you can cast between them, like:
# call_corner(corner as E.Corner)

enum { Top = 1, Right, Bottom, Left, TopLeft, TopRight, BottomRight, BottomLeft, Inc, Dec, Single, None }

enum Side { Top = 1, Right, Bottom, Left }
enum Corner { TopLeft = 5, TopRight, BottomRight, BottomLeft }
# Dec diagonal = \, Inc diagonal = /
enum Diagonal { Inc = 9, Dec }

enum CellType { IncDiag = 9, DecDiag, Single}
enum Walls {Top = 1, Right, Bottom, Left, IncDiag = 9, DecDiag}
enum Waters {TopLeft = 5, TopRight, BottomRight, BottomLeft, Single = 11, None}

func corner_is_left(corner: E.Corner) -> bool:
	return corner == Corner.TopLeft or corner == Corner.BottomLeft
func corner_is_top(corner: E.Corner) -> bool:
	return corner == Corner.TopLeft or corner == Corner.TopRight
func corner_to_diag(corner: E.Corner) -> E.Diagonal:
	if corner == E.Corner.BottomLeft or corner == E.Corner.TopRight:
		return E.Diagonal.Dec
	else:
		return E.Diagonal.Inc