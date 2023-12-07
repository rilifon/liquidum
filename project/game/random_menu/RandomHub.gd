class_name RandomHub
extends Control

const RANDOM := "random"

@onready var Continue: Button = $Center/VBox/Continue
@onready var Completed: Label = $CompletedCount

var completed_count: int

func _enter_tree() -> void:
	call_deferred(&"_update")

func _update() -> void:
	Continue.visible = FileManager.load_level(RANDOM) != null
	completed_count = FileManager.load_user_data().random_levels_completed
	Completed.text = "%s: %d" % [tr(&"RANDOM_COMPLETED"), completed_count]

func _on_back_pressed() -> void:
	AudioManager.play_sfx("button_pressed")
	TransitionManager.pop_scene()

func gen_level(hints_builder: Callable, strategies: Array, forced_strategies: Array) -> void:
	var g: GridModel
	var solver := SolverModel.new()
	for i in 1000:
		var hints: Level.HintVisibility = hints_builder.call()
		g = Generator.new(randi(), false).generate(hints.row.size(), hints.col.size())
		g.set_auto_update_hints(false)
		hints.apply_to_grid(g)
		var g2 := GridImpl.import_data(g.export_data(), GridModel.LoadMode.Testing)
		g2.clear_content()
		if solver.can_solve_with_strategies(g2, strategies, forced_strategies):
			print("Created level after %d tries" % (i + 1))
			break
	# There may be an existing level save
	FileManager.clear_level(RANDOM)
	FileManager.save_random_level(LevelData.new("", g.export_data(), ""))
	load_existing()

func load_existing() -> void:
	var data := FileManager.load_random_level()
	if data == null:
		return
	var level := Global.create_level(GridImpl.import_data(data.grid_data, GridModel.LoadMode.Solution), RANDOM, data.full_name)
	level.won.connect(_level_completed)
	TransitionManager.push_scene(level)

func _confirm_new_level() -> bool:
	AudioManager.play_sfx("button_pressed")
	if Continue.visible and ConfirmationScreen.start_confirmation(&"CONFIRM_NEW_RANDOM"):
		return await ConfirmationScreen.pressed
	return true

func _level_completed() -> void:
	# Save was already deleted
	completed_count += 1
	FileManager.save_user_data(UserData.new(completed_count))

func _easy_visibility() -> Level.HintVisibility:
	return Level.HintVisibility.default(5, 5)

func _on_easy_pressed() -> void:
	if await _confirm_new_level():
		gen_level(_easy_visibility, ["BasicRow", "BasicCol"], [])

func _on_continue_pressed() -> void:
	AudioManager.play_sfx("button_pressed")
	load_existing()

func _vis_array_or(a: Array[int], val: int, count: int) -> void:
	var b: Array[int] = []
	for i in a.size():
		b.append(val if i < count else 0)
	b.shuffle()
	for i in a.size():
		a[i] |= b[i]

func _medium_visibility() -> Level.HintVisibility:
	var h := Level.HintVisibility.new()
	for i in 6:
		h.row.append(0)
		h.col.append(0)
	for a in [h.row, h.col]:
		_vis_array_or(a, HintBar.WATER_COUNT_VISIBLE, mini(randi_range(3, 8), 6))
		_vis_array_or(a, HintBar.WATER_TYPE_VISIBLE, maxi(randi_range(-3, 4), 0))
	return h

func _on_medium_pressed():
	if await _confirm_new_level():
		gen_level(_medium_visibility, ["BasicCol", "BasicRow", "TogetherRow", "TogetherCol", "SeparateRow", "SeparateCol"], ["MediumCol", "MediumRow"])


func _on_hard_pressed():
	pass # Replace with function body.
