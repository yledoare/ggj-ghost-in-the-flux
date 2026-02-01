extends Node3D

@export var wall_scene: PackedScene

var pause_menu: Control
var is_paused: bool = false
@onready var lazer_mask_button = $HUD/LazerMaskButton
@onready var kill_counter_label = $HUD/KillCounter
@onready var player = $Player3D

func _ready():
	# Reset enemy counters for new game
	Globals.reset_enemy_counters()
	
	randomize_plane_size()
	# Defer obstacle spawning to ensure all nodes are properly initialized
	call_deferred("spawn_obstacles")
	# Setup pause menu
	call_deferred("_setup_pause_menu")
	
	# Connect HUD button
	lazer_mask_button.pressed.connect(_on_lazer_mask_pressed)
	
	# Enable toggle mode for the button
	lazer_mask_button.toggle_mode = true
	
	# Update button appearance
	_update_lazer_button_appearance()
	
	# Initialize kill counter
	_update_kill_counter()
	
	# Connect enemy killed signal
	Globals.enemy_killed.connect(_on_enemy_killed)
	
	# Add to map group for player communication
	add_to_group("map")

func _setup_pause_menu():
	var pause_scene = preload("res://scenes/pause_menu.tscn")
	pause_menu = pause_scene.instantiate()
	add_child(pause_menu)
	pause_menu.resume_game.connect(_on_resume_game)
	pause_menu.return_to_menu.connect(_on_return_to_menu)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	if is_paused:
		pause_menu.show_pause()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		pause_menu.hide_pause()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_game():
	toggle_pause()

func _on_return_to_menu():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func randomize_plane_size():
	var plane_size = randf_range(Globals.plane_min_size, Globals.plane_max_size)
	
	# Update plane mesh size
	var floor_mesh = $Floor/MeshInstance3D
	if floor_mesh and floor_mesh.mesh:
		floor_mesh.mesh.size = Vector2(plane_size, plane_size)
	
	# Update collision shape size
	var floor_collision = $Floor/CollisionShape3D
	if floor_collision and floor_collision.shape:
		floor_collision.shape.size = Vector3(plane_size, 0.2, plane_size)
	
	# Update enemy spawner radius to match plane size
	var enemy_spawner = $EnemySpawner
	if enemy_spawner:
		enemy_spawner.spawn_radius = plane_size * 0.4  # 40% of plane size

func spawn_obstacles():
	if not wall_scene:
		push_error("Wall scene not assigned!")
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if player == null or not player.is_inside_tree():
		push_error("Player not found or not in tree!")
		return
	var plane_size = $Floor/MeshInstance3D.mesh.size.x
	var half_size = plane_size * 0.5
	
	for i in range(Globals.nb_obstacles):
		var wall = wall_scene.instantiate()
		
		# Generate random position on the planea
		var spawn_pos = Vector3.ZERO
		var valid_position = false
		var attempts = 0
		
		while not valid_position and attempts < 50:
			spawn_pos.x = randf_range(-half_size + 1, half_size - 1)
			spawn_pos.z = randf_range(-half_size + 1, half_size - 1)
			spawn_pos.y = 0
			
			# Check distance from player (at least 4 units)
			var distance_from_player = spawn_pos.distance_to(player.global_position)
			if distance_from_player >= 4.0:
				valid_position = true
			
			attempts += 1
		
		wall.position = spawn_pos
		
		# Random rotation for variety
		wall.rotation.y = randf_range(0, 2 * PI)
		
		add_child(wall)

func _on_lazer_mask_pressed():
	if player:
		player.toggle_headband()
		_update_lazer_button_appearance()

func _update_lazer_button_appearance():
	if player and lazer_mask_button:
		if player.lazer_mask_active:
			lazer_mask_button.modulate = Color.GREEN  # Green tint when active
			lazer_mask_button.button_pressed = true  # Keep button in pressed state
		else:
			lazer_mask_button.modulate = Color.WHITE  # Normal when inactive
			lazer_mask_button.button_pressed = false  # Reset button state

func _update_kill_counter():
	if kill_counter_label:
		var total = Globals.num_enemies  # Use configured total instead of spawned count
		kill_counter_label.text = "Kills: %d/%d" % [Globals.enemies_killed, total]

func _on_enemy_killed():
	_update_kill_counter()
