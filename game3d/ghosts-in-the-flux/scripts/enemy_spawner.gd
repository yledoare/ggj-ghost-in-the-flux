extends Node3D

@export var ghost_scene: PackedScene
@export var spawn_radius: float = 8.0
@export var min_distance_from_player: float = 3.0

func _ready():
	spawn_enemies()

func spawn_enemies():
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("Player not found!")
		return
	
	var num_enemies = Globals.num_enemies
	
	for i in range(num_enemies):
		var ghost = ghost_scene.instantiate()
		
		# Generate random position around the map
		var spawn_pos = Vector3.ZERO
		var valid_position = false
		var attempts = 0
		
		while not valid_position and attempts < 20:
			spawn_pos.x = randf_range(-spawn_radius, spawn_radius)
			spawn_pos.z = randf_range(-spawn_radius, spawn_radius)
			spawn_pos.y = 0
			
			# Check distance from player
			var distance = spawn_pos.distance_to(player.global_position)
			if distance >= min_distance_from_player:
				valid_position = true
			
			attempts += 1
		
		ghost.global_position = spawn_pos
		add_child(ghost)
