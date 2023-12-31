extends Control

const STYLES = {
	"normal": {
		"normal": preload("res://assets/ui/LevelButton/NormalStyle.tres"),
		"hover": preload("res://assets/ui/LevelButton/HoverStyle.tres"),
		"pressed": preload("res://assets/ui/LevelButton/PressedStyle.tres"),
	},
	"completed": {
		"normal": preload("res://assets/ui/LevelButton/CompletedNormalStyle.tres"),
		"hover": preload("res://assets/ui/LevelButton/CompletedHoverStyle.tres"),
		"pressed": preload("res://assets/ui/LevelButton/CompletedPressedStyle.tres"),
	}
}

signal pressed
signal had_first_win

@onready var MainButton = $Button
@onready var ShaderEffect = $Button/ShaderEffect
@onready var OngoingSolution = %OngoingSolution
@onready var AnimPlayer = $AnimationPlayer
@onready var HardIcon: TextureRect = $HardIcon

var my_section := -1
var my_level := -1
var data = false


func _ready():
	ShaderEffect.material = ShaderEffect.material.duplicate()
	ShaderEffect.material.set_shader_parameter("rippleRate", randf_range(1.6, 3.5))


func setup(section : int, level : int, active : bool) -> void:
	my_section = section
	my_level = level
	MainButton.text = str(level)
	# Maybe make this less hardcoded in the future
	HardIcon.visible = level >= 7 or section == 6
	if active:
		enable()
		data = LevelLister.get_game_level_data(section, level)
		change_style_boxes(data and data.is_completed())
		set_ongoing_solution(data and not data.is_solution_empty())
	else:
		set_ongoing_solution(false)
		disable()


func unlock():
	AnimPlayer.play("unlock")


func set_ongoing_solution(status: bool) -> void:
	OngoingSolution.visible = status


func change_style_boxes(completed : bool) -> void:
	var styles = STYLES.completed if completed else STYLES.normal
	MainButton.add_theme_stylebox_override("normal", styles.normal)
	MainButton.add_theme_stylebox_override("hover", styles.hover)
	MainButton.add_theme_stylebox_override("pressed", styles.pressed)


func set_effect_alpha(value : float) -> void:
	ShaderEffect.material.set_shader_parameter("alpha", value)


func enable() -> void:
	MainButton.disabled = false
	ShaderEffect.show()
	HardIcon.modulate.a = 1.0

func disable() -> void:
	MainButton.disabled = true
	ShaderEffect.hide()
	HardIcon.modulate.a = 0.0


func _on_button_pressed():
	if my_level != -1 and my_section != -1:
		var level_data := FileManager.load_level_data(my_section, my_level)
		var level_name := LevelLister.level_name(my_section, my_level)
		var grid := GridImpl.import_data(level_data.grid_data, GridModel.LoadMode.Solution)
		var level_node := Global.create_level(grid, level_name, level_data.full_name, level_data.description, ["l%02d_%02d" % [my_section, my_level]], my_level, my_section)
		level_node.won.connect(_level_completed)
		level_node.had_first_win.connect(_on_level_had_first_win)
		TransitionManager.push_scene(level_node)


func _level_completed(info: Level.WinInfo) -> void:
	if info.first_win:
		SteamStats.update_campaign_stats()


func _on_level_had_first_win():
	had_first_win.emit(self)


func _on_button_mouse_entered():
	AudioManager.play_sfx("button_hover")
	mouse_entered.emit()


func _on_button_mouse_exited():
	mouse_exited.emit()
