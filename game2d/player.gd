extends CharacterBody2D

var SPEED = 200.0
const JUMP_VELOCITY = -400.0
var dialogue = false
var marche = false
var perso = "151"
var dialogues = []

func _ready() -> void:
	$"anim".play("rien")
	Dialogic.signal_event.connect(_on_dialogic_signal)

func _physics_process(delta: float) -> void:
	if not dialogue:
		var direction := Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
			$"anim".flip_h = (direction == -1)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			
		var direction2 := Input.get_axis("ui_up", "ui_down")
		if direction2:
			velocity.y = direction2 * SPEED
		else:
			velocity.y = move_toward(velocity.y, 0, SPEED)
			
		if direction and direction2:
			velocity.x /= sqrt(2)
			velocity.y /= sqrt(2)
			
		if (direction or direction2):
			marche = true
		else:
			marche = false

		move_and_slide()
	else:
		marche = false

func _process(delta: float) -> void:
	if marche:
		$"anim".play("marche")
	else:
		$"anim".play("rien")

func _on_dialogic_signal(argument:String):
	if argument == "stopdial":
		dialogue = false
	if argument == "suiteschizo":
		$"../Timer".start(5)
	if argument == "musique":
		$"musique".play()
	if argument == "fin1":
		$"..".route()
	if argument == "passechambre":
		get_tree().change_scene_to_file("res://chambre.tscn")
	if argument == "resetlit":
		dialogues.pop_back()
	if argument == "eglise":
		get_tree().change_scene_to_file("res://eglise.tscn")
	if argument == "stopmusic":
		$"musique".stop()
	if argument == "labyrinthe":
		get_tree().change_scene_to_file("res://laby.tscn")
	if argument == "cowboydis":
		$"../cowboy".visible = false
	if argument == "fin":
		get_tree().change_scene_to_file("res://fin.tscn")
	if argument == "feuilles":
		$"eglise".play()
	if argument == "enfin":
		get_tree().change_scene_to_file("res://intro.tscn")
		
func _on_timer_timeout() -> void:
	dialogue = true
	$"brouillard2".visible = false
	$"brouillard3".visible = true
	Dialogic.start("m1")
	
func _input(event):
	if dialogue:
		if Dialogic.current_timeline == null:
			Dialogic.start(perso)

func c1():
	dialogue = true
	$"musique".stop()
	perso = "rien"
	print($"brouillard3".position.x)
	$"Camera2D".offset.x -= 400
	await get_tree().create_timer(2).timeout
	$"anim".flip_h = true
	await get_tree().create_timer(2).timeout
	$"../fantome".visible = true
	Dialogic.start("trois")
	
func c2():
	dialogue = true
	$"..".pause = true
	Dialogic.start("finroute")
	
func c3():
	dialogue = true
	Dialogic.start("dormir")

func touche_voiture():
	$"../respawn".visible = true
	$"..".pause = true

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("cc")
	if body.has_method("jesuisqui"):
		perso = body.jesuisqui()
		if perso not in dialogues:
			dialogue = true
			dialogues.append(perso)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.has_method("jesuisqui"):
		dialogue = false

func _on_respawn_pressed() -> void:
	get_tree().change_scene_to_file("res://route.tscn")
