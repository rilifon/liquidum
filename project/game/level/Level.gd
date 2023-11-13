extends Node2D

@onready var GridNode: GridView = $CenterContainer/GridView

func _ready():
	randomize()
	setup("""
h6.4.2.
1##...w
.L.|..╲
4wwww..
.|╲./|.
4www..w
.L../.╲
3www...
.L._╲|.""")


func setup(level : String):
	GridNode.setup(level)


func _on_solve_button_pressed():
	GridNode.auto_solve()


func _on_brush_picker_brushed_picked(mode : E.BrushMode):
	GridNode.set_brush_mode(mode)
