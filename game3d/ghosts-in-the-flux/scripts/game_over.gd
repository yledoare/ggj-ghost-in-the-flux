extends Control

signal restart_game
signal return_to_menu

@onready var restart_button: Button = $VBoxContainer/RestartButton
@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton

func _ready():
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	hide()

func _on_restart_pressed():
	restart_game.emit()

func _on_main_menu_pressed():
	return_to_menu.emit()

func show_game_over():
	show()
	restart_button.grab_focus()