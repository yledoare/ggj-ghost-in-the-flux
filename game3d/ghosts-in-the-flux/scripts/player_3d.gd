extends CharacterBody3D

# Movement parameters
@export var speed: float = 5.0
@export var acceleration: float = 10.0
@export var friction: float = 10.0

func _physics_process(delta: float) -> void:
	# Get input direction from keyboard (arrows, WASD) and gamepad
	var input_x := Input.get_axis("ui_left", "ui_right")
	var input_z := Input.get_axis("ui_up", "ui_down")
	
	# Add WASD support
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		input_x = -1.0
	elif Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		input_x = 1.0
	
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		input_z = -1.0
	elif Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		input_z = 1.0
	
	# Calculate movement direction in 3D space (XZ plane)
	var direction := Vector3(input_x, 0, input_z).normalized()
	
	if direction:
		# Apply acceleration when moving
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	else:
		# Apply friction when not moving
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0
	
	move_and_slide()
