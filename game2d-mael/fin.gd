extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"player/brouillard2".visible = true
	$"player".dialogue = true
	Dialogic.start("fin")
