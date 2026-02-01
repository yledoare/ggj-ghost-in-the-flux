extends CharacterBody3D

# Movement parameters
@export var speed: float = 5.0
@export var acceleration: float = 10.0
@export var friction: float = 10.0
@export var deadzone: float = 0.2

# Camera zoom parameters
@export var zoom_speed: float = 2.0
@export var min_zoom: float = 3.0
@export var max_zoom: float = 30.0
@onready var camera = $Camera3D
@onready var headband = $Headband
@onready var mesh = $MeshInstance3D
var current_zoom: float = 10.0
var lazer_mask_active: bool = false

var laser_projectile_scene = preload("res://scenes/laser_projectile.tscn")

func _ready():
	current_zoom = camera.position.z  # Initialize with current camera position

func _input(event):
	# Handle mouse wheel for zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			current_zoom = max(min_zoom, current_zoom - zoom_speed)
			update_camera_zoom()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			current_zoom = min(max_zoom, current_zoom + zoom_speed)
			update_camera_zoom()
	
	# Handle shooting with left mouse button when lazer mask is active
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if lazer_mask_active:
			shoot_laser()
	
	# Handle space key for lazer mask toggle
	if event.is_action_pressed("jump"):
		toggle_headband()
		# Notify the map to update HUD button
		var map = get_tree().get_first_node_in_group("map")
		if map and map.has_method("_update_lazer_button_appearance"):
			map._update_lazer_button_appearance()

func update_camera_zoom():
	if camera:
		# Update camera position (assuming camera is positioned behind player)
		var camera_pos = camera.position
		camera_pos.z = current_zoom
		# Adjust height based on zoom for better perspective
		camera_pos.y = 8 + (current_zoom - min_zoom) * 0.3
		camera.position = camera_pos

func _physics_process(delta: float) -> void:
	# Initialize input values
	var input_x := 0.0
	var input_z := 0.0
	
	# Check D-pad first (gamepad arrows)
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT):
		input_x = -1.0
	elif Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT):
		input_x = 1.0
	else:
		# Check analog stick with deadzone
		var joy_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
		if abs(joy_x) > deadzone:
			input_x = joy_x
		
		# Keyboard overrides analog stick
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			input_x = -1.0
		elif Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			input_x = 1.0
	
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP):
		input_z = -1.0
	elif Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN):
		input_z = 1.0
	else:
		# Check analog stick with deadzone
		var joy_z = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		if abs(joy_z) > deadzone:
			input_z = joy_z
		
		# Keyboard overrides analog stick
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			input_z = -1.0
		elif Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
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
	
	# Get current plane size from the map (more reliable than reading mesh)
	var plane_size = 20.0  # default fallback
	var map = get_tree().get_first_node_in_group("map")
	if map and "current_plane_size" in map:
		plane_size = map.current_plane_size
		print("Player detected plane size from map: ", plane_size)  # Debug print
	
	# Keep player within plane boundaries - clamp to prevent falling off edges
	# Account for player collision radius (0.5) to allow reaching the visual edge
	var player_radius = 0.5
	var half_size = plane_size * 0.5 - player_radius
	position.x = clamp(position.x, -half_size, half_size)
	position.z = clamp(position.z, -half_size, half_size)

func equip_headband():
	lazer_mask_active = true  # Always activate when called
	if mesh and mesh.get_surface_override_material_count() > 0:
		var material = mesh.get_surface_override_material(0)
		if material:
			material.albedo_color = Color.RED

func toggle_headband():
	lazer_mask_active = !lazer_mask_active
	if mesh and mesh.get_surface_override_material_count() > 0:
		var material = mesh.get_surface_override_material(0)
		if material:
			if lazer_mask_active:
				material.albedo_color = Color.RED
			else:
				material.albedo_color = Color(0.2, 0.6, 1, 1)  # Default blue color

func shoot_laser():
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()
	if camera:
		var from = camera.project_ray_origin(mouse_pos)
		var dir = camera.project_ray_normal(mouse_pos)
		
		# Find intersection with ground plane (y = 0)
		var plane = Plane(Vector3.UP, 0)
		var intersection = plane.intersects_ray(from, dir)
		
		if intersection:
			var target_dir = (intersection - position).normalized()
			spawn_laser(position + Vector3(0, 1, 0) + target_dir * 1.5, target_dir)
		else:
			# Fallback to forward direction
			spawn_laser(position + Vector3(0, 1, 0) + transform.basis.z * 1.5, transform.basis.z.normalized())
	else:
		# Fallback if no camera
		spawn_laser(position + Vector3(0, 1, 0) + transform.basis.z * 1.5, transform.basis.z.normalized())

func spawn_laser(pos: Vector3, dir: Vector3):
	var laser = laser_projectile_scene.instantiate()
	laser.position = pos
	laser.direction = dir
	laser.shooter = self
	get_parent().add_child(laser)

func take_damage(amount: int):
	print("Player took ", amount, " damage!")
	# TODO: Implement health system
