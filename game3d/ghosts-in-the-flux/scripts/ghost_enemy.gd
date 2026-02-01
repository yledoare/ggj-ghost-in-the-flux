extends CharacterBody3D

@export var speed: float = 2.0
@export var detection_range: float = 20.0

var player: Node3D = null
@onready var ghost_model = $GhostModel
@onready var animation_player: AnimationPlayer = null

var idle_animation: String = ""
var move_animation: String = ""

var health: int = 3  # Enemies need 3 hits to die
var max_health: int = 3

func _ready():
	# Add to enemy group for projectile collision detection
	add_to_group("enemy")
	
	# Find the player in the scene
	player = get_tree().get_first_node_in_group("player")
	
	# Find AnimationPlayer in the ghost model
	if ghost_model:
		animation_player = ghost_model.get_node_or_null("AnimationPlayer")
		if animation_player:
			var animations = animation_player.get_animation_list()
			if animations.size() > 0:
				# Look for idle and move animations
				for anim_name in animations:
					if anim_name.to_lower().contains("idle"):
						idle_animation = anim_name
					elif anim_name == "Move" or anim_name.to_lower().contains("move") or anim_name.to_lower().contains("walk") or anim_name.to_lower().contains("run"):
						move_animation = anim_name
				
				# If no specific animations found, use first as idle
				if idle_animation == "":
					idle_animation = animations[0]
				
				# Play idle animation initially
				animation_player.play(idle_animation)
				var anim = animation_player.get_animation(idle_animation)
				if anim:
					anim.loop_mode = Animation.LOOP_LINEAR
				
				# Set loop mode for move animation if it exists
				if move_animation != "":
					var move_anim = animation_player.get_animation(move_animation)
					if move_anim:
						move_anim.loop_mode = Animation.LOOP_LINEAR
			else:
				push_warning("No animations found in ghost model")
		else:
			push_warning("No AnimationPlayer found in ghost model")

func _physics_process(_delta: float) -> void:
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
		
		# Play move animation if available
		if animation_player and move_animation != "" and animation_player.current_animation != move_animation:
			animation_player.play(move_animation)
		
		# Rotate ghost model to face AWAY from player (reverse facing)
		if ghost_model and direction.length() > 0:
			var away_direction = -direction  # Face opposite direction
			var target_position = global_position + away_direction * 10.0  # Look 10 units away
			ghost_model.look_at(target_position, Vector3.UP)
			ghost_model.rotation.x = 0
			ghost_model.rotation.z = 0
	else:
		# Not moving, play idle animation
		velocity = Vector3.ZERO
		if animation_player and idle_animation != "" and animation_player.current_animation != idle_animation:
			animation_player.play(idle_animation)

func take_damage(amount: int):
	health -= amount
	print("Enemy took ", amount, " damage! Health: ", health, "/", max_health)
	
	if health <= 0:
		# Enemy dies
		Globals.enemies_killed += 1
		Globals.enemy_killed.emit()
		queue_free()
