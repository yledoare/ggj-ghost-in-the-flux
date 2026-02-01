extends Node

# Global game variables
var num_enemies: int = 5

# Plane size variables
var plane_min_size: float = 25.0
var plane_max_size: float = 35.0

# Obstacle variables
var nb_obstacles: int = 5

# Enemy tracking
var total_enemies: int = 0
var enemies_killed: int = 0

# Signals
signal enemy_killed

func reset_enemy_counters():
	total_enemies = 0
	enemies_killed = 0
