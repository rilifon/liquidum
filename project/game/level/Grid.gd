extends Control

const REGULAR_CELL = preload("res://game/level/cells/RegularCell.tscn")

@onready var Columns = $CenterContainer/GridContainer/Columns
@onready var HintBars = {
	"top": $CenterContainer/GridContainer/HintBarTop,
	"left": $CenterContainer/GridContainer/HintBarLeft,
}

var grid_logic : GridModel
var rows : int
var columns : int
var mouse_hold_status : int

func _input(event):
	if event is InputEventMouseButton:
		if not event.pressed:
			mouse_hold_status = E.MouseDragState.None
	elif grid_logic and event.is_action_pressed("undo"):
		grid_logic.undo()
		update()
	elif grid_logic and event.is_action_pressed("redo"):
		grid_logic.redo()
		update()
		

func setup(level : String) -> void:
	grid_logic = GridImpl.from_str(level)
	rows = grid_logic.rows()
	columns = grid_logic.cols() 
	for child in Columns.get_children():
		Columns.remove_child(child)
	for i in rows:
		var new_row = HBoxContainer.new()
		new_row.add_theme_constant_override("separation", 0)
		Columns.add_child(new_row)
		for j in columns:
			var cell_data = grid_logic.get_cell(i, j)
			create_cell(new_row, cell_data, i, j)
	setup_hints()
	update()

func auto_solve() -> void:
	SolverModel.new().apply_strategies(grid_logic)
	update()

#Assumes grid_logic is already setup
func setup_hints():
	assert(grid_logic, "Grid Logic not properly set to setup grid hints")
	HintBars.top.setup(grid_logic.hint_all_cols())
	HintBars.left.setup(grid_logic.hint_all_rows())


func create_cell(new_row : Node, cell_data : GridImpl.CellModel, n : int, m : int) -> Cell:
	var cell = REGULAR_CELL.instantiate()
	new_row.add_child(cell)
	
	var type := E.CellType.Single
	for diag in E.Diagonal.values():
		if cell_data.wall_at(diag):
			type = diag
	cell.setup(type, n, m)
	
	for side in E.Side.values():
		if cell_data.wall_at(side):
			cell.set_wall(side)
	
	cell.pressed_water.connect(_on_cell_pressed_water)
	cell.pressed_air.connect(_on_cell_pressed_air)
	cell.mouse_entered.connect(_on_cell_mouse_entered)
	
	return cell


func update() -> void:
	update_visuals()
	update_hints()


func update_visuals() -> void:
	for i in rows:
		for j in columns:
			var cell_data := grid_logic.get_cell(i, j)
			var cell := get_cell(i, j) as Cell
			if cell_data.water_full():
				cell.set_water(E.Single, true)
				cell.remove_air()
			elif cell_data.air_full():
				cell.remove_water()
				cell.set_air(E.Single, true)
			elif cell_data.nothing_full():
				cell.remove_water()
				cell.remove_air()
			else:
				for corner in E.Corner.values():
					cell.set_water(corner, cell_data.water_at(corner))
					cell.set_air(corner, cell_data.air_at(corner))


func update_hints() -> void:
	for i in rows:
		var hint = HintBars.left.get_hint(i)
		if grid_logic.is_row_hint_wrong(i):
			hint.set_error()
		elif grid_logic.is_row_hint_satisfied(i):
			hint.set_satisfied()
		else:
			hint.set_normal()
	for j in columns:
		var hint = HintBars.top.get_hint(j)
		if grid_logic.is_col_hint_wrong(j):
			hint.set_error()
		elif grid_logic.is_col_hint_satisfied(j):
			hint.set_satisfied()
		else:
			hint.set_normal()

func get_cell(i: int, j: int) -> Node:
	return Columns.get_child(i).get_child(j)


func _on_cell_pressed_water(i: int, j: int, which: E.Waters) -> void:
	assert(which != E.Waters.None)
	
	var cell_data := grid_logic.get_cell(i, j)
	var corner = E.Corner.BottomLeft if which == E.Single else (which as E.Corner)
	if cell_data.water_at(corner):
		mouse_hold_status = E.MouseDragState.RemoveWater
		cell_data.remove_water_or_air(corner)
	else:
		mouse_hold_status = E.MouseDragState.Water
		cell_data.put_water(corner)
	update()


func _on_cell_pressed_air(i: int, j: int, which: E.Waters) -> void:
	assert(which != E.Waters.None)
	var cell_data := grid_logic.get_cell(i, j)
	var corner = E.Corner.BottomLeft if which == E.Single else (which as E.Corner)
	if cell_data.air_at(corner):
		mouse_hold_status = E.MouseDragState.RemoveAir
		cell_data.remove_water_or_air(corner)
	else:
		mouse_hold_status = E.MouseDragState.Air
		cell_data.put_air(corner)
	update()


func _on_cell_mouse_entered(i: int, j: int, which: E.Waters) -> void:
	if mouse_hold_status == E.MouseDragState.None:
		return
	
	var cell_data := grid_logic.get_cell(i, j)
	var corner = E.Corner.BottomLeft if which == E.Single else (which as E.Corner)
	if mouse_hold_status == E.MouseDragState.Water and cell_data.nothing_at(corner):
		cell_data.put_water(corner)
	elif mouse_hold_status == E.MouseDragState.Air and cell_data.nothing_at(corner):
		cell_data.put_air(corner)
	elif mouse_hold_status == E.MouseDragState.RemoveWater and cell_data.water_at(corner):
		cell_data.remove_water_or_air(corner)
	elif mouse_hold_status == E.MouseDragState.RemoveAir and cell_data.air_at(corner):
		cell_data.remove_water_or_air(corner)
	
	update()
	
