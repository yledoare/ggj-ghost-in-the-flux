extends Node2D

var pause = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"player".SPEED = 500
	$"player/Camera2D".enabled = false
	$"player/brouillard2".visible = false
	$"player/brouillard3".visible = false
	$"player/musique2".play()
	ResourceLoader.load_threaded_request("res://voiture.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Coeur/texteCoeur.text=str(Var.vie)
	if not pause:
		$"TileMap".position.x -= delta*700
