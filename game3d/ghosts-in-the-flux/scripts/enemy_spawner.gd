extends Node3D

@export var ghost_scene: PackedScene
@export var spawn_radius: float = 8.0
@export var min_distance_from_player: float = 3.0
@export var enemy_multiplier: int = 1
@export var auto_spawn: bool = true
@export var spawn_container_path: NodePath = ""  # Path to container node for multiplayer

func _ready():
	# Defer spawning to ensure all nodes are properly initialized
	if auto_spawn:
		call_deferred("spawn_enemies")

func _get_spawn_container() -> Node:
	if not spawn_container_path.is_empty():
		var container = get_node_or_null(spawn_container_path)
		if container:
			return container
	return self

func spawn_enemies():
	# Get all players in multiplayer or single player
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		push_warning("No players found, spawning enemies at random positions")
		_spawn_enemies_no_player_check()
		return
	
	var player = players[0]  # Use first player for distance check
	var container = _get_spawn_container()
	
	# Use a fixed seed for deterministic enemy placement across all clients
	var rng = RandomNumberGenerator.new()
	rng.seed = 67890  # Fixed seed for consistent enemy placement
	
	var num_enemies = Globals.num_enemies * enemy_multiplier
	
	for i in range(num_enemies):
		var ghost = ghost_scene.instantiate()
		ghost.name = "Ghost_" + str(i)
		
		# Generate random position around the map
		var spawn_pos = Vector3.ZERO
		var valid_position = false
		var attempts = 0
		
		while not valid_position and attempts < 20:
			spawn_pos.x = rng.randf_range(-spawn_radius, spawn_radius)
			spawn_pos.z = rng.randf_range(-spawn_radius, spawn_radius)
			spawn_pos.y = 0
			
			# Check distance from player
			var distance_from_player = spawn_pos.distance_to(player.global_position)
			var valid_distance = distance_from_player >= min_distance_from_player
			
			# Check distance from obstacles
			var valid_obstacle_distance = true
			var obstacles = get_tree().get_nodes_in_group("obstacle")
			for obstacle in obstacles:
				var distance_from_obstacle = spawn_pos.distance_to(obstacle.global_position)
				if distance_from_obstacle < 2.0:  # Minimum 2 units from obstacles
					valid_obstacle_distance = false
					break
			
			if valid_distance and valid_obstacle_distance:
				valid_position = true
			
			attempts += 1
		
		ghost.position = spawn_pos
		container.add_child(ghost, true)

func _spawn_enemies_no_player_check():
	var num_enemies = Globals.num_enemies * enemy_multiplier
	var container = _get_spawn_container()
	
	# Use a fixed seed for deterministic enemy placement across all clients
	var rng = RandomNumberGenerator.new()
	rng.seed = 67890  # Fixed seed for consistent enemy placement
	
	for i in range(num_enemies):
		var ghost = ghost_scene.instantiate()
		ghost.name = "Ghost_" + str(i)
		
		var spawn_pos = Vector3.ZERO
		var valid_position = false
		var attempts = 0
		
		while not valid_position and attempts < 20:
			spawn_pos.x = rng.randf_range(-spawn_radius, spawn_radius)
			spawn_pos.z = rng.randf_range(-spawn_radius, spawn_radius)
			spawn_pos.y = 0
			
			# Just check distance from center (spawn area)
			if spawn_pos.length() >= min_distance_from_player:
				valid_position = true
			
			attempts += 1
		
		ghost.position = spawn_pos
		container.add_child(ghost, true)
