extends Area3D

@export var speed: float = 12.0
@export var damage: int = 30
@export var rotation_speed: float = 5.0

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
	# Create a fireball shoot sound (lower pitch, more rumbling)
	var shoot_wav = AudioStreamWAV.new()
	shoot_wav.format = AudioStreamWAV.FORMAT_16_BITS
	shoot_wav.mix_rate = 44100
	shoot_wav.stereo = true

	var frames = 4410  # 0.1 seconds
	var data = PackedByteArray()

	for i in range(frames):
		var t = float(i) / frames
		# Lower frequency sine wave at 220Hz (A note octave lower)
		var sample = sin(t * 220.0 * 2.0 * PI) * 12000.0 * (1.0 - t)
		var noise = (randf() - 0.5) * 4000.0 * (1.0 - t)  # Add some noise
		sample += noise

		# Convert to 16-bit stereo
		var int_sample = int(sample)
		data.append(int_sample & 0xFF)
		data.append((int_sample >> 8) & 0xFF)
		data.append(int_sample & 0xFF)
		data.append((int_sample >> 8) & 0xFF)

	shoot_wav.data = data
	$ShootSound.stream = shoot_wav

	# Create hit sound (explosion-like)
	var hit_wav = AudioStreamWAV.new()
	hit_wav.format = AudioStreamWAV.FORMAT_16_BITS
	hit_wav.mix_rate = 44100
	hit_wav.stereo = true

	var hit_frames = 8820  # 0.2 seconds
	var hit_data = PackedByteArray()

	for i in range(hit_frames):
		var t = float(i) / hit_frames
		var noise = (randf() - 0.5) * 2.0
		var tone = sin(t * 60.0 * 2.0 * PI)  # Low frequency rumble
		var sample = (noise * 0.7 + tone * 0.5) * (1.0 - t * t) * 24576.0
		hit_data.append(int(sample) & 0xFF)
		hit_data.append((int(sample) >> 8) & 0xFF)

	hit_wav.data = hit_data
	$HitSound.stream = hit_wav

func _physics_process(delta):
	# Move the projectile
	position += direction * speed * delta

	# Add slight rotation for visual effect
	rotation.z += rotation_speed * delta
	rotation.y += rotation_speed * 0.5 * delta

func _on_timer_timeout():
	queue_free()

func _on_screen_exited():
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player") and body != shooter:  # Only damage player
		# Deal damage to the player
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_play_hit_sound()
		# Delay destruction to let sound play
		await get_tree().create_timer(0.2).timeout
		queue_free()
	elif body.is_in_group("obstacle"):
		# Hit a wall or obstacle, just destroy the projectile
		queue_free()
	# Note: Fireballs do NOT damage other enemies

func _play_shoot_sound():
	if $ShootSound and $ShootSound.stream:
		$ShootSound.play()

func _play_hit_sound():
	if $HitSound and $HitSound.stream:
		$HitSound.play()