extends Node3D

@export var wall_scene: PackedScene
@export var campfire_scene: PackedScene
@export var num_campfires: int = 3

var pause_menu: Control
var game_over_menu: Control
var is_paused: bool = false
var current_plane_size: float = 20.0  # Store the current plane size for reliable access
@onready var lazer_mask_button = $HUD/LazerMaskButton
@onready var gaz_mask_button = $HUD/GazMaskButton
@onready var kill_counter_label = $HUD/KillCounter
@onready var health_bar = $HUD/HealthBar
@onready var health_label = $HUD/HealthLabel
@onready var player = $Player3D

func _ready():
	# Reset enemy counters for new game
	Globals.reset_enemy_counters()
	
	randomize_plane_size()
	# Defer obstacle spawning to ensure all nodes are properly initialized
	call_deferred("spawn_obstacles")
	call_deferred("spawn_campfires")
	# Setup pause menu
	call_deferred("_setup_pause_menu")
	
	# Hide mouse cursor for gameplay
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	
	# Connect HUD button
	lazer_mask_button.pressed.connect(_on_lazer_mask_pressed)
	gaz_mask_button.pressed.connect(_on_gaz_mask_pressed)
	
	# Disable the buttons since they're now just visual indicators
	lazer_mask_button.disabled = true
	gaz_mask_button.disabled = true
	
	# Update button appearance
	_update_lazer_button_appearance()
	_update_gaz_button_appearance()
	
	# Initialize kill counter
	_update_kill_counter()
	
	# Initialize health display
	_update_health_display()
	
	# Connect enemy killed signal
	Globals.enemy_killed.connect(_on_enemy_killed)
	
	# Connect player health changed signal
	player.health_changed.connect(_on_player_health_changed)
	
	# Connect player death signal
	player.player_died.connect(_on_player_died)
	
	# Add to map group for player communication
	add_to_group("map")

func _setup_pause_menu():
	var pause_scene = preload("res://scenes/pause_menu.tscn")
	pause_menu = pause_scene.instantiate()
	add_child(pause_menu)
	pause_menu.resume_game.connect(_on_resume_game)
	pause_menu.return_to_menu.connect(_on_return_to_menu)
	
	# Setup game over menu
	var game_over_scene = preload("res://scenes/game_over.tscn")
	game_over_menu = game_over_scene.instantiate()
	add_child(game_over_menu)
	game_over_menu.restart_game.connect(_on_restart_game)
	game_over_menu.return_to_menu.connect(_on_return_to_menu)

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
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)

func _on_resume_game():
	toggle_pause()

func _on_return_to_menu():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func randomize_plane_size():
	var plane_size = randf_range(Globals.plane_min_size, Globals.plane_max_size)
	
	# Store the current plane size for player access
	current_plane_size = plane_size
	
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

func spawn_campfires():
	if not campfire_scene:
		push_warning("Campfire scene not assigned!")
		return
	
	var plane_size = $Floor/MeshInstance3D.mesh.size.x
	var half_size = plane_size * 0.5
	
	# Get all wall positions to avoid spawning campfires too close to them
	var wall_positions = []
	for child in get_children():
		if child.is_in_group("wall"):
			wall_positions.append(child.global_position)
	
	for i in range(num_campfires):
		var campfire = campfire_scene.instantiate()
		
		# Generate random position on the plane
		var spawn_pos = Vector3.ZERO
		var valid_position = false
		var attempts = 0
		
		while not valid_position and attempts < 100:
			spawn_pos.x = randf_range(-half_size + 2, half_size - 2)
			spawn_pos.z = randf_range(-half_size + 2, half_size - 2)
			spawn_pos.y = 0
			
			# Check distance from player (at least 6 units)
			var distance_from_player = spawn_pos.distance_to(player.global_position)
			
			# Check distance from walls (at least 3 units)
			var too_close_to_wall = false
			for wall_pos in wall_positions:
				if spawn_pos.distance_to(wall_pos) < 3.0:
					too_close_to_wall = true
					break
			
			if distance_from_player >= 6.0 and not too_close_to_wall:
				valid_position = true
			
			attempts += 1
		
		if valid_position:
			campfire.position = spawn_pos
			add_child(campfire)

func _on_lazer_mask_pressed():
	# HUD button is now just a visual indicator - don't toggle here
	# The toggle is only controlled by space bar
	pass

func _update_lazer_button_appearance():
	if player and lazer_mask_button:
		if player.lazer_mask_active:
			lazer_mask_button.modulate = Color.GREEN  # Green tint when active
			lazer_mask_button.button_pressed = true  # Keep button in pressed state
		else:
			lazer_mask_button.modulate = Color.WHITE  # Normal when inactive
			lazer_mask_button.button_pressed = false  # Reset button state

func _on_gaz_mask_pressed():
	# HUD button is now just a visual indicator - don't toggle here
	# The toggle is only controlled by touch 2
	pass

func _update_gaz_button_appearance():
	if player and gaz_mask_button:
		if player.gaz_mask_active:
			gaz_mask_button.modulate = Color.GREEN  # Green tint when active
			gaz_mask_button.button_pressed = true  # Keep button in pressed state
		else:
			gaz_mask_button.modulate = Color.WHITE  # Normal when inactive
			gaz_mask_button.button_pressed = false  # Reset button state

func _update_kill_counter():
	if kill_counter_label:
		var total = Globals.num_enemies  # Use configured total instead of spawned count
		kill_counter_label.text = "Kills: %d/%d" % [Globals.enemies_killed, total]

func _on_enemy_killed():
	_update_kill_counter()

func _update_health_display():
	if health_bar and health_label and player:
		var current = player.current_health
		var max_h = player.max_health
		
		# Update progress bar (0-100 range)
		health_bar.value = float(current) / float(max_h) * 100.0
		
		# Update label text
		health_label.text = "Health: %d/%d" % [current, max_h]
		
		# Change color based on health
		if current <= 25:
			health_bar.modulate = Color.RED
		elif current <= 50:
			health_bar.modulate = Color.ORANGE
		else:
			health_bar.modulate = Color.GREEN

func _on_player_health_changed(current: int, max_health: int):
	_update_health_display()

func _on_player_died():
	# Show game over menu
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	game_over_menu.show_game_over()

func _on_restart_game():
	# Restart the current scene
	get_tree().paused = false
	get_tree().reload_current_scene()
