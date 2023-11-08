class_name SolverModel

# Strategy for a single row or column
class RowStrategy:
	var grid: GridImpl
	func _init(grid_: GridImpl) -> void:
		grid = grid_
	# values is an array of component, that is, all triangles
	# are in the same aquarium. Since this is a row. Flooding any one will flood
	# the whole thing.
	func _apply_strategy(_values: Array[RowComponent], _water_left: float, _nothing_left: float) -> bool:
		return GridModel.must_be_implemented()
	func _apply(i: int) -> bool:
		var dfs := RowDfs.new(i, grid)
		var last_seen := grid.last_seen
		var comps: Array[RowComponent] = []
		for j in grid.cols():
			for corner in E.Corner.values():
				var cell := grid._pure_cell(i, j)
				if cell.last_seen(corner) < grid.last_seen and cell._valid_corner(corner):
					dfs.comp = RowComponent.new(grid.get_cell(i, j), corner)
					dfs.flood(i, j, corner)
					if dfs.comp.size > 0:
						comps.append(dfs.comp)
		var nothing_left := 0.
		for j in grid.cols():
			nothing_left += grid._pure_cell(i, j).nothing_count()
		var water_left := grid.hint_row(i) - grid.count_water_row(i)
		if nothing_left == 0 or comps.size() == 0:
			return false
		return self._apply_strategy(comps, water_left, nothing_left)
	func apply_any() -> bool:
		var any := false
		for i in grid.rows():
			if self._apply(i):
				any = true
		return any

class RowComponent:
	var size := 0.
	var first: GridImpl.CellWithLoc
	var corner: E.Corner
	func _init(first_: GridImpl.CellWithLoc, corner_: E.Corner) -> void:
		first = first_
		corner = corner_
	func put_water() -> void:
		first.put_water(corner)
	func put_air() -> void:
		first.put_air(corner, true)

class RowDfs extends GridImpl.Dfs:
	var row_i: int
	var comp: RowComponent
	func _init(i: int, grid_: GridImpl) -> void:
		super(grid_)
		row_i = i
	func _cell_logic(i: int, _j: int, corner: E.Corner, cell: PureCell) -> bool:
		if cell.block_at(corner) or cell.air_at(corner):
			return false
		if i == row_i and !cell.water_at(corner):
			comp.size += (1 + int(!cell.diag_wall)) * 0.5
		return true
	func _can_go_up(i: int, _j: int) -> bool:
		return i > row_i
	func _can_go_down(_i: int, _j: int) -> bool:
		return true

# - Put air in components that are too big
# - Put water everywhere if there's no more space for air
class BasicRowStrategy extends RowStrategy:
	func _apply_strategy(values: Array[RowComponent], water_left: float, nothing_left: float) -> bool:
		if water_left == nothing_left:
			print("Filling with water")
			for comp in values:
				print("size %f, i %d j %d" % [comp.size, comp.first.i, comp.first.j])
				comp.put_water()
			return true
		var any := false
		for comp in values:
			if comp.size > water_left:
				print("Putting air because %f > %f" % [comp.size, water_left])
				comp.put_air()
				any = true
		return any

# Tries to solve the puzzle as much as possible
func apply_strategies(grid: GridModel) -> void:
	for i in grid.rows():
		if grid.count_water_row(i) > 0:
			# Is this true?
			assert(false, "Can't solve partial grid")
			return
	var strategy := BasicRowStrategy.new(grid)
	while strategy.apply_any():
		print("1 pass")
