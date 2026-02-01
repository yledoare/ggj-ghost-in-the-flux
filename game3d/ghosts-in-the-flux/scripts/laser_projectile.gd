extends Area3D

@export var speed: float = 15.0
@export var damage: int = 10
@export var rotation_speed: float = 10.0

var direction: Vector3 = Vector3.FORWARD
var shooter: Node = null

func _ready():
	# Connect signals
	$Timer.timeout.connect(_on_timer_timeout)
	$VisibleOnScreenNotifier3D.screen_exited.connect(_on_screen_exited)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Move the projectile
	position += direction * speed * delta
	
	# Add rotation for visual effect
	rotation.z += rotation_speed * delta

func _on_timer_timeout():
	queue_free()

func _on_screen_exited():
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player") and body != shooter:  # Don't hit the shooter
		# Deal damage to the player
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()