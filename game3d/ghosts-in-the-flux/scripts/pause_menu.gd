extends Control

signal resume_game
signal return_to_menu

@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton

# Audio controls
@onready var master_slider: HSlider = $VBoxContainer/MasterContainer/MasterSlider
@onready var music_slider: HSlider = $VBoxContainer/MusicContainer/MusicSlider
@onready var sfx_slider: HSlider = $VBoxContainer/SFXContainer/SFXSlider
@onready var mute_checkbox: CheckBox = $VBoxContainer/MuteContainer/MuteCheckBox

func _ready():
	resume_button.pressed.connect(_on_resume_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	# Audio connections
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	mute_checkbox.toggled.connect(_on_mute_toggled)
	
	hide()

func _on_resume_pressed():
	resume_game.emit()

func _on_main_menu_pressed():
	return_to_menu.emit()

func show_pause():
	_load_audio_settings()
	show()
	resume_button.grab_focus()

func hide_pause():
	hide()

func _load_audio_settings():
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		master_slider.value = AudioServer.get_bus_volume_db(master_bus)
		mute_checkbox.button_pressed = AudioServer.is_bus_mute(master_bus)
	
	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus >= 0:
		music_slider.value = AudioServer.get_bus_volume_db(music_bus)
	
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		sfx_slider.value = AudioServer.get_bus_volume_db(sfx_bus)

func _on_master_volume_changed(value: float):
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, value)

func _on_music_volume_changed(value: float):
	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus >= 0:
		AudioServer.set_bus_volume_db(music_bus, value)

func _on_sfx_volume_changed(value: float):
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, value)

func _on_mute_toggled(button_pressed: bool):
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, button_pressed)
