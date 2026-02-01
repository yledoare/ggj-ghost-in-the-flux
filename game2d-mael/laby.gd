extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"player".SPEED = 400
	$"player/lab".play()
