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

# Preloaded sounds for projectiles
var laser_shoot_sound: AudioStreamWAV
var laser_hit_sound: AudioStreamWAV

func _ready():
	print("Globals _ready called")
	_create_projectile_sounds()

func _create_projectile_sounds():
	print("Creating projectile sounds...")
	# Create shoot sound (simple beep)
	laser_shoot_sound = AudioStreamWAV.new()
	laser_shoot_sound.format = AudioStreamWAV.FORMAT_16_BITS
	laser_shoot_sound.mix_rate = 22050
	laser_shoot_sound.stereo = false
	
	var shoot_data = PackedByteArray()
	for i in range(1103):  # 0.05 seconds
		var t = float(i) / 1103.0
		var sample = sin(t * 600.0 * 2.0 * PI) * (1.0 - t) * 16384.0  # Lower volume (half), lower frequency
		shoot_data.append(int(sample) & 0xFF)
		shoot_data.append((int(sample) >> 8) & 0xFF)
	
	laser_shoot_sound.data = shoot_data
	print("Shoot sound created, data size: ", laser_shoot_sound.data.size())
	
	# Create hit sound (explosion)
	laser_hit_sound = AudioStreamWAV.new()
	laser_hit_sound.format = AudioStreamWAV.FORMAT_16_BITS
	laser_hit_sound.mix_rate = 22050
	laser_hit_sound.stereo = false
	
	var hit_data = PackedByteArray()
	for i in range(4410):  # 0.2 seconds
		var t = float(i) / 4410.0
		var noise = (randf() - 0.5) * 2.0
		var tone = sin(t * 80.0 * 2.0 * PI)
		var sample = (noise * 0.8 + tone * 0.6) * (1.0 - t * t) * 24576.0
		hit_data.append(int(sample) & 0xFF)
		hit_data.append((int(sample) >> 8) & 0xFF)
	
	laser_hit_sound.data = hit_data

func reset_enemy_counters():
	total_enemies = 0
	enemies_killed = 0
