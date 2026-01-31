extends Control

# Video
@onready var fullscreen_checkbox: CheckBox = $VBoxContainer/TabContainer/Vidéo/FullscreenContainer/FullscreenCheckBox
@onready var vsync_checkbox: CheckBox = $VBoxContainer/TabContainer/Vidéo/VSyncContainer/VSyncCheckBox
@onready var resolution_option: OptionButton = $VBoxContainer/TabContainer/Vidéo/ResolutionContainer/ResolutionOption

# Audio
@onready var master_slider: HSlider = $VBoxContainer/TabContainer/Audio/MasterContainer/MasterSlider
@onready var music_slider: HSlider = $VBoxContainer/TabContainer/Audio/MusicContainer/MusicSlider
@onready var sfx_slider: HSlider = $VBoxContainer/TabContainer/Audio/SFXContainer/SFXSlider
@onready var mute_checkbox: CheckBox = $VBoxContainer/TabContainer/Audio/MuteContainer/MuteCheckBox

# Controls
@onready var forward_button: Button = $"VBoxContainer/TabContainer/Contrôles/ForwardContainer/ForwardButton"
@onready var backward_button: Button = $"VBoxContainer/TabContainer/Contrôles/BackwardContainer/BackwardButton"
@onready var left_button: Button = $"VBoxContainer/TabContainer/Contrôles/LeftContainer/LeftButton"
@onready var right_button: Button = $"VBoxContainer/TabContainer/Contrôles/RightContainer/RightButton"
@onready var jump_button: Button = $"VBoxContainer/TabContainer/Contrôles/JumpContainer/JumpButton"
@onready var reset_controls_button: Button = $"VBoxContainer/TabContainer/Contrôles/ResetButton"

@onready var back_button: Button = $VBoxContainer/BackButton

var waiting_for_input: bool = false
var current_action: String = ""
var current_button: Button = null

var resolutions: Array = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

var action_to_button: Dictionary = {}

func _ready():
	_setup_resolution_options()
	_load_settings()
	_setup_control_buttons()
	
	# Video connections
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	vsync_checkbox.toggled.connect(_on_vsync_toggled)
	resolution_option.item_selected.connect(_on_resolution_selected)
	
	# Audio connections
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	mute_checkbox.toggled.connect(_on_mute_toggled)
	
	# Controls connections
	forward_button.pressed.connect(_on_control_button_pressed.bind("move_forward", forward_button))
	backward_button.pressed.connect(_on_control_button_pressed.bind("move_backward", backward_button))
	left_button.pressed.connect(_on_control_button_pressed.bind("move_left", left_button))
	right_button.pressed.connect(_on_control_button_pressed.bind("move_right", right_button))
	jump_button.pressed.connect(_on_control_button_pressed.bind("jump", jump_button))
	reset_controls_button.pressed.connect(_on_reset_controls_pressed)
	
	back_button.pressed.connect(_on_back_pressed)

func _setup_resolution_options():
	resolution_option.clear()
	for res in resolutions:
		resolution_option.add_item("%d x %d" % [res.x, res.y])

func _setup_control_buttons():
	action_to_button = {
		"move_forward": forward_button,
		"move_backward": backward_button,
		"move_left": left_button,
		"move_right": right_button,
		"jump": jump_button
	}
	_update_control_button_labels()

func _update_control_button_labels():
	for action in action_to_button:
		var button = action_to_button[action]
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			var event = events[0]
			if event is InputEventKey:
				button.text = OS.get_keycode_string(event.keycode) if event.keycode != 0 else OS.get_keycode_string(event.physical_keycode)
			elif event is InputEventMouseButton:
				button.text = "Mouse " + str(event.button_index)
		else:
			button.text = "Non assigné"

func _load_settings():
	# Load video settings
	fullscreen_checkbox.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	vsync_checkbox.button_pressed = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	
	# Find current resolution in list
	var current_res = DisplayServer.window_get_size()
	for i in range(resolutions.size()):
		if resolutions[i] == current_res:
			resolution_option.select(i)
			break
	
	# Load audio settings
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

# Video callbacks
func _on_fullscreen_toggled(button_pressed: bool):
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_vsync_toggled(button_pressed: bool):
	if button_pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _on_resolution_selected(index: int):
	if index >= 0 and index < resolutions.size():
		var res = resolutions[index]
		DisplayServer.window_set_size(res)
		# Center window
		var screen_size = DisplayServer.screen_get_size()
		var window_pos = (screen_size - res) / 2
		DisplayServer.window_set_position(window_pos)

# Audio callbacks
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

# Controls callbacks
func _on_control_button_pressed(action: String, button: Button):
	waiting_for_input = true
	current_action = action
	current_button = button
	button.text = "..."

func _input(event):
	if waiting_for_input:
		if event is InputEventKey and event.pressed:
			_remap_action(current_action, event)
			waiting_for_input = false
			current_button = null
			current_action = ""
			get_viewport().set_input_as_handled()

func _remap_action(action: String, event: InputEvent):
	# Remove old mappings
	InputMap.action_erase_events(action)
	# Add new mapping
	InputMap.action_add_event(action, event)
	# Update button labels
	_update_control_button_labels()

func _on_reset_controls_pressed():
	# Reset to default WASD + Space
	var defaults = {
		"move_forward": KEY_W,
		"move_backward": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"jump": KEY_SPACE
	}
	
	for action in defaults:
		InputMap.action_erase_events(action)
		var event = InputEventKey.new()
		event.keycode = defaults[action]
		InputMap.action_add_event(action, event)
	
	_update_control_button_labels()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
