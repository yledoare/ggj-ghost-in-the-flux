extends CharacterBody3D

@export var speed: float = 2.0
@export var detection_range: float = 20.0

var player: Node3D = null

func _ready():
	# Find the player in the scene
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	# Calculate distance to player
	var distance = global_position.distance_to(player.global_position)
	
	# Only move if player is within detection range
	if distance < detection_range:
		# Calculate direction to player
		var direction = (player.global_position - global_position).normalized()
		direction.y = 0  # Keep movement on XZ plane
		
		# Move toward player
		velocity = direction * speed
		move_and_slide()
		
		# Rotate to face player
		if direction.length() > 0:
			look_at(player.global_position, Vector3.UP)
			rotation.x = 0
			rotation.z = 0
