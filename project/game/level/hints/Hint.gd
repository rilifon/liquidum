class_name Hint
extends Control

const ALPHA_SPEED = 4.0
const HIDE_ALPHA = 0.5
const HIGHLIGHT_SPEED = 5.0

@onready var Hints = {
	E.Walls.Top: $Hints/Top,
	E.Walls.Right: $Hints/Right,
	E.Walls.Bottom: $Hints/Bottom,
	E.Walls.Left:$Hints/Left,
}
@onready var ContentContainer = $VBoxContainer
@onready var EditorButtons = $VBoxContainer/EditorButtons
@onready var ToggleHintType: TextureButton = $VBoxContainer/EditorButtons/ToggleHintType
@onready var ToggleVisibility: TextureButton = $VBoxContainer/EditorButtons/ToggleVisibility
@onready var HintsContainer = $VBoxContainer/HintsContainer
@onready var Number = %Number
@onready var Boat = %Boat
@onready var DummyLabel = %DummyLabel
@onready var Highlight = %Highlight

var editor_mode := false
var hint_type : E.HintType = E.HintType.Hidden
var is_boat := false
var hint_value := 0.0
var hint_alpha := 1.0
var is_dummy := false
var highlight := false

func _ready():
	Highlight.modulate.a = 0.0
	disable_editor()
	DummyLabel.hide()
	set_boat(false)
	set_status(E.HintStatus.Normal)
	for side in Hints.keys():
		set_hint_visibility(side, true)


func _process(dt):
	if highlight:
		Highlight.modulate.a = min(Highlight.modulate.a + HIGHLIGHT_SPEED*dt, 1.0)
	else:
		Highlight.modulate.a = max(Highlight.modulate.a - HIGHLIGHT_SPEED*dt, 0.0)
	
	if is_dummy:
		return
	
	if ToggleHintType.is_pressed():
		if hint_alpha < 1.0:
			hint_alpha = min(hint_alpha + ALPHA_SPEED*dt, 1.0)
			update_label()
	else:
		if hint_alpha > 0.0:
			hint_alpha = max(hint_alpha - ALPHA_SPEED*dt, 0.0)
			update_label()
	if ToggleVisibility.is_pressed():
		HintsContainer.modulate.a = min(HintsContainer.modulate.a + ALPHA_SPEED*dt, 1.0)
	else:
		HintsContainer.modulate.a = max(HintsContainer.modulate.a - ALPHA_SPEED*dt, HIDE_ALPHA)


func set_boat(value):
	is_boat = value
	Boat.visible = value


func set_value(new_value : float) -> void:
	hint_value = new_value
	update_label()


func set_highlight(value: bool) -> void:
	highlight = value


func set_hint_type(new_type : E.HintType) -> void:
	hint_type = new_type
	update_label()

func should_be_visible() -> bool:
	return ToggleVisibility.is_pressed()

func should_have_type() -> bool:
	return ToggleHintType.is_pressed()

func set_visibility(vis: bool, type: bool) -> void:
	ToggleVisibility.set_pressed(vis)
	ToggleHintType.set_pressed(type)


func alpha_t(text : String, alpha : float) -> String:
	var color = Global.COLORS.normal
	color.a = alpha
	return "[color=%s]%s[/color]" % ["#"+color.to_html(true),text]


func update_label() -> void:
	Number.text = ""
	var value = str(hint_value) if hint_value != -1 else "?"
	match hint_type:
		E.HintType.Zero, E.HintType.Hidden:
			Number.text += value
			DummyLabel.text = "?"
		E.HintType.Together:
			if editor_mode:
				Number.text += alpha_t("{ ", hint_alpha) + value + alpha_t(" }", hint_alpha)
			else:
				Number.text += "{ " + value + " }"
				DummyLabel.text = "{ ? }"
		E.HintType.Separated:
			if editor_mode:
				Number.text += alpha_t("- ", hint_alpha) + value + alpha_t(" -", hint_alpha)
			else:
				Number.text += "- " + value + " -"
				DummyLabel.text = "- ? -"


func no_hint() -> void:
	Number.text = ""
	hide()


func dummy_hint() -> void:
	is_dummy = true
	show()
	DummyLabel.show()
	ContentContainer.hide()


func set_hint_visibility(which : E.Walls, value : bool) -> void:
	Hints[which].visible = value


func set_status(status: E.HintStatus) -> void:
	if hint_value == -1:
		Number.add_theme_color_override("default_color", Global.COLORS.normal)
	else:
		match status:
			E.HintStatus.Normal:
				Number.add_theme_color_override("default_color", Global.COLORS.normal)
			E.HintStatus.Satisfied:
				Number.add_theme_color_override("default_color", Global.COLORS.satisfied)
			E.HintStatus.Wrong:
				Number.add_theme_color_override("default_color", Global.COLORS.error)


func enable_editor() -> void:
	editor_mode = true
	EditorButtons.show()
	if is_boat:
		ToggleVisibility.set_pressed(false)
	ToggleHintType.set_pressed(false)


func disable_editor() -> void:
	editor_mode = false
	EditorButtons.hide()
