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
@onready var head = $Head
@onready var left_eye = $Head/LeftEye
@onready var right_eye = $Head/RightEye

# Eye materials
var eye_white_material = StandardMaterial3D.new()
var eye_black_material = StandardMaterial3D.new()

var current_zoom: float = 10.0
var lazer_mask_active: bool = false
var gaz_mask_active: bool = false

# Health system
var max_health: int = 100
var current_health: int = 100

var laser_projectile_scene = preload("res://scenes/laser_projectile.tscn")

# Multiplayer sync - this will be set by the spawner
@export var player_id: int = 1:
	set(value):
		player_id = value
		# Update authority when player_id changes
		if is_inside_tree():
			_setup_authority()

var _is_local_player: bool = false

func _ready():
	# Wait a frame for multiplayer to be ready
	await get_tree().process_frame
	_setup_authority()

func _setup_authority():
	# Set this node's authority to the player's peer ID
	set_multiplayer_authority(player_id)
	
	# Check if this is the local player
	_is_local_player = (multiplayer.get_unique_id() == player_id)
	
	print("Player ", name, " - player_id: ", player_id, ", my_id: ", multiplayer.get_unique_id(), ", is_local: ", _is_local_player)
	
	# Only enable camera for local player
	if camera:
		if _is_local_player:
			camera.current = true
			current_zoom = camera.position.z
		else:
			camera.current = false
			# Hide camera for non-local players
			camera.queue_free()
	
	# Initialize eye materials
	eye_white_material.albedo_color = Color.WHITE
	eye_black_material.albedo_color = Color.BLACK
	
	# Create eye meshes
	if left_eye:
		var left_eye_mesh = SphereMesh.new()
		left_eye_mesh.radius = 0.08
		left_eye_mesh.height = 0.16
		left_eye.mesh = left_eye_mesh
	
	if right_eye:
		var right_eye_mesh = SphereMesh.new()
		right_eye_mesh.radius = 0.08
		right_eye_mesh.height = 0.16
		right_eye.mesh = right_eye_mesh
	
	# Set initial eye colors (white for default state)
	if left_eye and right_eye:
		left_eye.set_surface_override_material(0, eye_white_material)
		right_eye.set_surface_override_material(0, eye_white_material)

func _input(event):
	# Only process input if we're the local player
	if not _is_local_player:
		return
	
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
		toggle_lazer_mask()
		# Notify the map to update HUD button
		var map = get_tree().get_first_node_in_group("map")
		if map and map.has_method("_update_lazer_button_appearance"):
			map._update_lazer_button_appearance()
	
	# Handle keyboard keys 1 and 2 for mask selection
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			toggle_lazer_mask()
			var map = get_tree().get_first_node_in_group("map")
			if map and map.has_method("_update_lazer_button_appearance"):
				map._update_lazer_button_appearance()
		elif event.keycode == KEY_2:
			toggle_gaz_mask()
			var map = get_tree().get_first_node_in_group("map")
			if map and map.has_method("_update_gaz_button_appearance"):
				map._update_gaz_button_appearance()

func update_camera_zoom():
	if camera and _is_local_player:
		var camera_pos = camera.position
		camera_pos.z = current_zoom
		camera_pos.y = 8 + (current_zoom - min_zoom) * 0.3
		camera.position = camera_pos

func _physics_process(delta: float) -> void:
	# Only process input and movement for local player
	if not _is_local_player:
		return
	
	# Initialize input values
	var input_x := 0.0
	var input_z := 0.0
	
	# Check D-pad first (gamepad arrows)
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT):
		input_x = -1.0
	elif Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT):
		input_x = 1.0
	else:
		var joy_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
		if abs(joy_x) > deadzone:
			input_x = joy_x
		
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			input_x = -1.0
		elif Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			input_x = 1.0
	
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP):
		input_z = -1.0
	elif Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN):
		input_z = 1.0
	else:
		var joy_z = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		if abs(joy_z) > deadzone:
			input_z = joy_z
		
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			input_z = -1.0
		elif Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			input_z = 1.0
	
	var direction := Vector3(input_x, 0, input_z).normalized()
	
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)
	
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0
	
	move_and_slide()
	
	# Update eye direction to follow mouse cursor (only for local player)
	if _is_local_player and camera and head:
		var mouse_pos = get_viewport().get_mouse_position()
		var from = camera.project_ray_origin(mouse_pos)
		var dir = camera.project_ray_normal(mouse_pos)
		
		# Find intersection with ground plane (y = 0)
		var plane = Plane(Vector3.UP, 0)
		var intersection = plane.intersects_ray(from, dir)
		
		if intersection:
			# Make the head look at the mouse intersection point
			head.look_at(intersection, Vector3.UP)
		else:
			# Fallback to camera forward direction
			var camera_forward = -camera.global_transform.basis.z.normalized()
			head.look_at(head.global_position + camera_forward, Vector3.UP)
	
	# Get current plane size from the map (more reliable than reading mesh)
	var plane_size = 20.0
	var map = get_tree().get_first_node_in_group("map")
	if map and "current_plane_size" in map:
		plane_size = map.current_plane_size
		print("Multiplayer player detected plane size from map: ", plane_size)  # Debug print
	
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

func toggle_lazer_mask():
	lazer_mask_active = !lazer_mask_active
	update_player_color()

func toggle_gaz_mask():
	gaz_mask_active = !gaz_mask_active
	update_player_color()

func update_player_color():
	if mesh and mesh.get_surface_override_material_count() > 0:
		var material = mesh.get_surface_override_material(0)
		if material:
			if lazer_mask_active and gaz_mask_active:
				# Both masks active - orange color
				material.albedo_color = Color.ORANGE
				# Change eyes to black when any mask is active
				if left_eye and right_eye:
					left_eye.set_surface_override_material(0, eye_black_material)
					right_eye.set_surface_override_material(0, eye_black_material)
			elif lazer_mask_active:
				# Only lazer mask active - red color
				material.albedo_color = Color.RED
				# Change eyes to black when lazer mask is active
				if left_eye and right_eye:
					left_eye.set_surface_override_material(0, eye_black_material)
					right_eye.set_surface_override_material(0, eye_black_material)
			elif gaz_mask_active:
				# Only gas mask active - green color
				material.albedo_color = Color.GREEN
				# Change eyes to black when gas mask is active
				if left_eye and right_eye:
					left_eye.set_surface_override_material(0, eye_black_material)
					right_eye.set_surface_override_material(0, eye_black_material)
			else:
				# No masks active - default blue color
				material.albedo_color = Color(0.2, 0.6, 1, 1)
				# Change eyes to white when no masks are active
				if left_eye and right_eye:
					left_eye.set_surface_override_material(0, eye_white_material)
					right_eye.set_surface_override_material(0, eye_white_material)

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
			spawn_laser.rpc(position + Vector3(0, 1, 0) + target_dir * 1.5, target_dir)
		else:
			# Fallback to forward direction
			spawn_laser.rpc(position + Vector3(0, 1, 0) + transform.basis.z * 1.5, transform.basis.z.normalized())
	else:
		# Fallback if no camera
		spawn_laser.rpc(position + Vector3(0, 1, 0) + transform.basis.z * 1.5, transform.basis.z.normalized())

@rpc("any_peer", "call_local")
func spawn_laser(pos: Vector3, dir: Vector3):
	var laser = laser_projectile_scene.instantiate()
	laser.position = pos
	laser.direction = dir
	laser.shooter = self
	get_parent().add_child(laser)

func take_damage(amount: int):
	current_health -= amount
	print("Player ", name, " took ", amount, " damage! Health: ", current_health, "/", max_health)
	
	# Emit health changed signal
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		# Player dies - could add game over logic here
		print("Player ", name, " died!")
		current_health = 0

# Signal for health changes
signal health_changed(current: int, max: int)
