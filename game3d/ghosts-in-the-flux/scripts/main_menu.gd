extends Control

@onready var single_player_button: Button = $VBoxContainer/SinglePlayerButton
@onready var multiplayer_button: Button = $VBoxContainer/MultiplayerButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var credits_button: Button = $VBoxContainer/CreditsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready():
	single_player_button.pressed.connect(_on_single_player_pressed)
	multiplayer_button.pressed.connect(_on_multiplayer_pressed)
	options_button.pressed.connect(_on_options_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Disable multiplayer button for web exports (HTML5 doesn't support proper multiplayer)
	if OS.has_feature("web"):
		multiplayer_button.disabled = true
		multiplayer_button.modulate = Color(0.5, 0.5, 0.5, 1.0)  # Gray out the button

func _on_single_player_pressed():
	get_tree().change_scene_to_file("res://scenes/map_3d.tscn")

func _on_multiplayer_pressed():
	get_tree().change_scene_to_file("res://scenes/multiplayer/lobby.tscn")

func _on_options_pressed():
	get_tree().change_scene_to_file("res://scenes/options.tscn")

func _on_credits_pressed():
	get_tree().change_scene_to_file("res://scenes/credits.tscn")

func _on_quit_pressed():
	get_tree().quit()
