extends CharacterBody2D

var Bullet = load("res://Scenes/bidon.tscn")
var est_bugge = false

func _ready():
	pass

func _shoot():
	var b = Bullet.instantiate()
	b.position.y  = position.y - 20
	if !est_bugge:
		b.position.x  = position.x
		owner.add_child(b)
	else:
		b.position.x  = position.x
		get_parent().add_child(b)
	$AnimatedSprite2D.stop()

func _on_Timer_timeout():
	$AnimatedSprite2D.play("attaque")

func _on_Area2D_area_entered(_area):
	print ("A l'attaque")
	$Timer.start(0.5)

func _on_AnimatedSprite_animation_finished():
	_shoot()
