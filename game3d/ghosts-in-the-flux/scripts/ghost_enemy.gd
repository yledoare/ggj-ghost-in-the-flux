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
var is_dead: bool = false

# Fireball shooting variables
var fireball_projectile_scene = preload("res://scenes/fireball_projectile.tscn")
var shoot_timer: Timer = null
var cooldown_timer: Timer = null
var can_shoot: bool = true

func _ready():
	# Add to enemy group for projectile collision detection
	add_to_group("enemy")
	
	# Find the player in the scene
	player = get_tree().get_first_node_in_group("player")
	
	# Setup shooting timer
	shoot_timer = Timer.new()
	shoot_timer.wait_time = 2.0  # Shoot every 2 seconds
	shoot_timer.one_shot = false
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(shoot_timer)
	shoot_timer.start()
	
	# Setup cooldown timer
	cooldown_timer = Timer.new()
	cooldown_timer.wait_time = 0.5  # 0.5 second cooldown
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)
	add_child(cooldown_timer)
	
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
	if player == null or is_dead:
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

func _on_shoot_timer_timeout():
	if can_shoot and player != null and not is_dead:
		# Random chance to shoot (50% chance)
		if randf() < 0.5:
			shoot_fireball()

func _on_cooldown_timer_timeout():
	if not is_dead and is_inside_tree():
		can_shoot = true

func shoot_fireball():
	if is_dead or player == null:
		return
	
	# Check if we're in the scene tree before accessing global_position
	if not is_inside_tree():
		return
	
	# Store parent reference early
	var parent = get_parent()
	if parent == null:
		return
	
	# Create fireball projectile
	var fireball = fireball_projectile_scene.instantiate()
	
	# Set position slightly in front of the enemy
	var shoot_position = global_position + Vector3(0, 1, 0)  # Shoot from chest height
	
	# Calculate direction towards player with some randomness
	var base_direction = (player.global_position - global_position).normalized()
	var random_offset = Vector3(
		randf_range(-0.3, 0.3),  # Small horizontal spread
		randf_range(-0.1, 0.1),  # Small vertical spread
		randf_range(-0.3, 0.3)   # Small depth spread
	)
	var direction = (base_direction + random_offset).normalized()
	fireball.direction = direction
	
	# Set the shooter to avoid self-damage
	fireball.shooter = self
	
	# Add to scene first, then set global position
	parent.add_child(fireball)
	fireball.global_position = shoot_position
	
	# Prevent shooting again immediately
	can_shoot = false
	if cooldown_timer and is_inside_tree():
		cooldown_timer.start()  # Start cooldown timer

func take_damage(amount: int):
	health -= amount
	print("Enemy took ", amount, " damage! Health: ", health, "/", max_health)
	
	if health <= 0:
		# Enemy dies
		is_dead = true
		# Disconnect and stop timers to prevent further callbacks
		if shoot_timer:
			shoot_timer.timeout.disconnect(_on_shoot_timer_timeout)
			shoot_timer.stop()
		if cooldown_timer:
			cooldown_timer.timeout.disconnect(_on_cooldown_timer_timeout)
			cooldown_timer.stop()
		Globals.enemies_killed += 1
		Globals.enemy_killed.emit()
		queue_free()
