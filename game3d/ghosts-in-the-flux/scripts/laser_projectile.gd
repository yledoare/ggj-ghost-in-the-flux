extends Area3D

@export var speed: float = 15.0
@export var damage: int = 10
@export var rotation_speed: float = 10.0

var direction: Vector3 = Vector3.FORWARD
var shooter: Node = null

func _ready():
	# Connect signals
	$Timer.timeout.connect(_on_timer_timeout)
	$VisibleOnScreenNotifier3D.screen_exited.connect(_on_screen_exited)
	body_entered.connect(_on_body_entered)
	
	# Use preloaded sounds
	$ShootSound.stream = Globals.laser_shoot_sound
	$HitSound.stream = Globals.laser_hit_sound
	
	# Play shoot sound
	_play_shoot_sound()

func _create_sounds():
	# Create shoot sound (simple beep)
	var shoot_wav = AudioStreamWAV.new()
	shoot_wav.format = AudioStreamWAV.FORMAT_16_BITS
	shoot_wav.mix_rate = 22050
	shoot_wav.stereo = false
	
	var shoot_data = PackedByteArray()
	for i in range(1103):  # 0.05 seconds (shorter)
		var t = float(i) / 1103.0
		var sample = sin(t * 600.0 * 2.0 * PI) * (1.0 - t) * 16384.0  # Lower volume (half), lower frequency
		shoot_data.append(int(sample) & 0xFF)
		shoot_data.append((int(sample) >> 8) & 0xFF)
	
	shoot_wav.data = shoot_data
	$ShootSound.stream = shoot_wav
	
	# Create hit sound (explosion)
	var hit_wav = AudioStreamWAV.new()
	hit_wav.format = AudioStreamWAV.FORMAT_16_BITS
	hit_wav.mix_rate = 22050
	hit_wav.stereo = false
	
	var hit_data = PackedByteArray()
	for i in range(4410):  # 0.2 seconds
		var t = float(i) / 4410.0
		var noise = (randf() - 0.5) * 2.0
		var tone = sin(t * 80.0 * 2.0 * PI)  # Even lower frequency
		var sample = (noise * 0.8 + tone * 0.6) * (1.0 - t * t) * 24576.0  # Higher volume (3/4 of max)
		hit_data.append(int(sample) & 0xFF)
		hit_data.append((int(sample) >> 8) & 0xFF)
	
func _physics_process(delta):
	# Move the projectile
	position += direction * speed * delta
	
	# Add rotation for visual effect
	rotation.z += rotation_speed * delta

func _on_timer_timeout():
	queue_free()

func _on_screen_exited():
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player") and body != shooter:  # Don't hit the shooter
		# Deal damage to the player
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_play_hit_sound()
		queue_free()
	elif body.is_in_group("enemy"):
		# Damage enemy instead of instant kill
		if body.has_method("take_damage"):
			body.take_damage(1)  # Deal 1 damage per hit
			_play_hit_sound()
		queue_free()

func _play_shoot_sound():
	if $ShootSound and $ShootSound.stream:
		print("Playing shoot sound, stream data size: ", $ShootSound.stream.data.size())
		$ShootSound.play()
	else:
		print("ShootSound or stream is null!")

func _play_hit_sound():
	if $HitSound and $HitSound.stream:
		print("Playing hit sound, stream data size: ", $HitSound.stream.data.size())
		$HitSound.play()
	else:
		print("HitSound or stream is null!")