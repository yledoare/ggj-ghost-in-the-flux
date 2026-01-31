extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"player/brouillard3".visible = false
	$"player".SPEED += 150
	$"player".c3()
	$"player/musique".play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
