class_name SettingsScreen
extends CanvasLayer

signal pause_toggled(active : bool)

@onready var AnimPlayer = $AnimationPlayer
@onready var SoundSettings = {
	"master": $Settings/CenterContainer/VBoxContainer/MasterSoundContainer/HSlider,
	"bgm": $Settings/CenterContainer/VBoxContainer/BGMSoundContainer/HSlider,
	"sfx": $Settings/CenterContainer/VBoxContainer/SFXSoundContainer/HSlider,
}
@onready var Fullscreen = $Settings/CenterContainer/VBoxContainer/FullscreenContainer/CheckBox
@onready var BG = $BG
@onready var PauseButton = $PauseButton
@onready var TitleContainer = %TitleContainer
@onready var LevelTitle = %LevelTitle
@onready var LevelID = %LevelID

var active := false
var is_disabled := false

func _ready():
	TitleContainer.hide()
	BG.hide()


func disable_button():
	is_disabled = true
	PauseButton.disabled = true


func enable_button():
	is_disabled = false
	PauseButton.disabled = false


func toggle_pause() -> void:
	if is_disabled:
		return
	active = not active
	if active:
		AudioManager.play_sfx("enable_settings")
		setup_values()
		AnimPlayer.play("enable")
	else:
		AudioManager.play_sfx("disable_settings")
		save_values()
		AnimPlayer.play("disable")
	emit_signal("pause_toggled", active)


func save_values():
	Profile.set_option("master_volume", SoundSettings.master.get_value()/100.0)
	Profile.set_option("bgm_volume", SoundSettings.bgm.get_value()/100.0)
	Profile.set_option("sfx_volume", SoundSettings.sfx.get_value()/100.0)
	Profile.set_option("fullscreen", Fullscreen.button_pressed)
	FileManager.save_profile()


func setup_values():
	SoundSettings.master.set_value(Profile.get_option("master_volume")*100)
	SoundSettings.bgm.set_value(Profile.get_option("bgm_volume")*100)
	SoundSettings.sfx.set_value(Profile.get_option("sfx_volume")*100)
	Fullscreen.button_pressed = Global.is_fullscreen()


func set_level_name(level_name: String, section := -1, level := -1) ->  void:
	if level_name != "":
		TitleContainer.show()
		LevelTitle.text = level_name
		if level != -1 and section != -1:
			LevelID.show()
			LevelID.text = "%d - %d" % [section, level]
		else:
			LevelID.hide()
	else:
		TitleContainer.hide()


func _on_volume_slider_value_changed(value, bus : int):
	AudioManager.set_bus_volume(bus, float(value)/100.0)


func _on_pause_button_pressed():
	toggle_pause()


func _on_fullscreen_toggled(button_pressed):
	if Global.is_fullscreen() != button_pressed:
		Global.toggle_fullscreen()
		if button_pressed:
			AudioManager.play_sfx("checkbox_pressed")
		else:
			AudioManager.play_sfx("checkbox_unpressed")


func _on_save_n_quit_button_pressed():
	AudioManager.play_sfx("button_back")
	save_values()
	FileManager.save_and_quit()


func _on_button_mouse_entered():
	AudioManager.play_sfx("button_hover")
