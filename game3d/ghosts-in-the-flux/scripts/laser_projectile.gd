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
	
	# Create simple test sounds directly
	_create_simple_sounds()
	
	# Play shoot sound
	_play_shoot_sound()

func _create_simple_sounds():
	# Create a very simple beep sound
	var shoot_wav = AudioStreamWAV.new()
	shoot_wav.format = AudioStreamWAV.FORMAT_16_BITS
	shoot_wav.mix_rate = 44100  # Higher quality
	shoot_wav.stereo = true
	
	var frames = 4410  # 0.1 seconds at 44100Hz
	var data = PackedByteArray()
	
	for i in range(frames):
		var t = float(i) / frames
		# Simple sine wave at 440Hz (A note)
		var sample = sin(t * 440.0 * 2.0 * PI) * 10000.0 * (1.0 - t)  # Fade out
		
		# Convert to 16-bit stereo
		var int_sample = int(sample)
		data.append(int_sample & 0xFF)
		data.append((int_sample >> 8) & 0xFF)
		data.append(int_sample & 0xFF)  # Same for both channels
		data.append((int_sample >> 8) & 0xFF)
	
	shoot_wav.data = data
	$ShootSound.stream = shoot_wav
	print("Created simple shoot sound, data size: ", data.size())
	
	# Create hit sound
	var hit_wav = AudioStreamWAV.new()
	hit_wav.format = AudioStreamWAV.FORMAT_16_BITS
	hit_wav.mix_rate = 44100
	hit_wav.stereo = true
	
	var hit_frames = 8820  # 0.2 seconds
	var hit_data = PackedByteArray()
	
	for i in range(hit_frames):
		var t = float(i) / hit_frames
		# Noise + low tone
		var noise = (randf() - 0.5) * 2.0
		var tone = sin(t * 220.0 * 2.0 * PI)  # Lower tone
		var sample = (noise * 0.7 + tone * 0.3) * 15000.0 * (1.0 - t * t)
		
		var int_sample = int(sample)
		hit_data.append(int_sample & 0xFF)
		hit_data.append((int_sample >> 8) & 0xFF)
		hit_data.append(int_sample & 0xFF)
		hit_data.append((int_sample >> 8) & 0xFF)
	
	hit_wav.data = hit_data
	$HitSound.stream = hit_wav
	print("Created simple hit sound, data size: ", hit_data.size())

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
		# Delay destruction to let sound play
		await get_tree().create_timer(0.2).timeout
		queue_free()
	elif body.is_in_group("enemy"):
		# Damage enemy instead of instant kill
		if body.has_method("take_damage"):
			body.take_damage(1)  # Deal 1 damage per hit
			_play_hit_sound()
			# Delay destruction to let sound play
			await get_tree().create_timer(0.2).timeout
			queue_free()
		else:
			# If no take_damage method, just destroy immediately
			queue_free()
	elif body.is_in_group("obstacle"):
		# Hit a wall or obstacle, just destroy the projectile
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
