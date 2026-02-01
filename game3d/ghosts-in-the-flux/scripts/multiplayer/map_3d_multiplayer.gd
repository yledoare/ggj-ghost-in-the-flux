extends Node3D

@export var wall_scene: PackedScene
@export var player_scene: PackedScene

var spawned_player_ids: Array = []
var pause_menu: Control
var is_paused: bool = false
var current_plane_size: float = 20.0  # Store the current plane size for reliable access
@onready var lazer_mask_button = $HUD/LazerMaskButton
@onready var kill_counter_label = $HUD/KillCounter

func _ready():
	# Reset enemy counters for new game
	Globals.reset_enemy_counters()
	
	# Connect to player connection/disconnection signals
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
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
	
	# Defer setup to ensure all nodes are properly initialized
	call_deferred("_setup_game")
	# Setup pause menu
	call_deferred("_setup_pause_menu")

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
	if is_paused:
		pause_menu.show_pause()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		pause_menu.hide_pause()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_resume_game():
	toggle_pause()

func _on_return_to_menu():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Disconnect from multiplayer
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_lazer_mask_pressed():
	var local_player = get_local_player()
	if local_player:
		local_player.toggle_headband()
		_update_lazer_button_appearance()

func _update_lazer_button_appearance():
	var local_player = get_local_player()
	if local_player and lazer_mask_button:
		if local_player.lazer_mask_active:
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

func get_local_player():
	var my_id = multiplayer.get_unique_id()
	for player in $Players.get_children():
		if player.player_id == my_id:
			return player
	return null

func _setup_game():
	randomize_plane_size()
	
	# Spawn obstacles on all clients (deterministic with fixed seeds)
	call_deferred("spawn_obstacles")
	
	# Only server spawns players and enemies
	if multiplayer.is_server():
		call_deferred("spawn_all_players")
		# Spawn enemies after players with a small delay
		call_deferred("_spawn_enemies_delayed")

func randomize_plane_size():
	# Use a fixed seed for deterministic plane size across all clients
	var rng = RandomNumberGenerator.new()
	rng.seed = 54321  # Fixed seed for consistent plane size
	var plane_size = rng.randf_range(Globals.plane_min_size, Globals.plane_max_size)
	
	# Store the current plane size for player access
	current_plane_size = plane_size
	
	var floor_mesh = $Floor/MeshInstance3D
	if floor_mesh and floor_mesh.mesh:
		floor_mesh.mesh.size = Vector2(plane_size, plane_size)
	
	var floor_collision = $Floor/CollisionShape3D
	if floor_collision and floor_collision.shape:
		floor_collision.shape.size = Vector3(plane_size, 0.2, plane_size)
	
	var enemy_spawner = $EnemySpawner
	if enemy_spawner:
		enemy_spawner.spawn_radius = plane_size * 0.4

func spawn_obstacles():
	if not wall_scene:
		push_error("Wall scene not assigned!")
		return
	
	# Use a fixed seed for deterministic obstacle placement across all clients
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345  # Fixed seed for consistent obstacle placement
	
	var plane_size = $Floor/MeshInstance3D.mesh.size.x
	var half_size = plane_size * 0.5
	
	for i in range(Globals.nb_obstacles):
		var wall = wall_scene.instantiate()
		
		var spawn_pos = Vector3.ZERO
		var attempts = 0
		
		while attempts < 50:
			spawn_pos.x = rng.randf_range(-half_size + 1, half_size - 1)
			spawn_pos.z = rng.randf_range(-half_size + 1, half_size - 1)
			spawn_pos.y = 0
			
			# Just ensure it's not in the center spawn area
			if spawn_pos.length() >= 4.0:
				break
			
			attempts += 1
		
		wall.position = spawn_pos
		wall.rotation.y = rng.randf_range(0, 2 * PI)
		wall.name = "Wall_" + str(i)
		
		$Obstacles.add_child(wall, true)

func spawn_all_players():
	# Spawn player for host
	spawn_player(1)
	
	# Spawn players for all connected peers
	var network_manager = get_node_or_null("/root/NetworkManager")
	if network_manager:
		for player_id in network_manager.players:
			if player_id != 1 and player_id not in spawned_player_ids:
				spawn_player(player_id)

func spawn_player(peer_id: int):
	if peer_id in spawned_player_ids:
		return
	
	if not player_scene:
		push_error("Player scene not assigned!")
		return
	
	var player = player_scene.instantiate()
	player.name = "Player_" + str(peer_id)
	player.player_id = peer_id
	
	# Calculate spawn position (spread players around center)
	var spawn_index = spawned_player_ids.size()
	var angle = spawn_index * (2.0 * PI / 8.0)  # Spread up to 8 players in circle
	var spawn_radius = 3.0
	
	player.position = Vector3(
		cos(angle) * spawn_radius,
		2.0,
		sin(angle) * spawn_radius
	)
	
	$Players.add_child(player, true)
	spawned_player_ids.append(peer_id)
	
	print("Spawned player for peer: ", peer_id)

func _on_player_connected(peer_id: int):
	if multiplayer.is_server():
		# Small delay to ensure player is fully registered
		await get_tree().create_timer(0.1).timeout
		spawn_player(peer_id)

func _on_player_disconnected(peer_id: int):
	# Remove the disconnected player's node
	var player_node = $Players.get_node_or_null("Player_" + str(peer_id))
	if player_node:
		player_node.queue_free()
		spawned_player_ids.erase(peer_id)
		print("Removed player for peer: ", peer_id)

func _spawn_enemies_delayed():
	# Wait for players to be spawned
	await get_tree().create_timer(0.5).timeout
	
	var enemy_spawner = $EnemySpawner
	if enemy_spawner:
		enemy_spawner.spawn_enemies()
