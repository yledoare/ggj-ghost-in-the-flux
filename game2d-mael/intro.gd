extends Node2D
var simultaneous_scene = preload("res://route.tscn").instantiate()

func route():
	get_tree().change_scene_to_file("res://route.tscn")

func parametres_base():
	Dialogic.Inputs.auto_advance.enabled_forced = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Dialogic.Inputs.auto_advance.enabled_forced = true
	Dialogic.Settings.autoadvance_delay_modifier = 0.5
	Dialogic.start("dialogue_debut")
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("c1"):
		body.c1()
