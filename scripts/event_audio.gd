extends Node
## Original event sounds. Separate channels keep life support distinct from solar weather.
const RATE := 22050
const LEVELS := {"solar": -20.0, "wave": -23.0, "vitals": -8.0, "energy": -12.0, "disconnect": -11.0, "radio": -19.0}
var players: Dictionary = {}
var muted := false

func _ready() -> void:
	for kind: String in LEVELS:
		var player := AudioStreamPlayer.new()
		player.stream = _synthesize(kind)
		player.volume_db = LEVELS[kind]
		add_child(player)
		players[kind] = player

func play(kind: String) -> void:
	if not muted: players[kind].play()

func set_muted(value: bool) -> void:
	muted = value
	for kind: String in players:
		players[kind].volume_db = -80.0 if muted else LEVELS[kind]

func set_paused(value: bool) -> void:
	for player: AudioStreamPlayer in players.values(): player.stream_paused = value

func _synthesize(kind: String) -> AudioStreamWAV:
	var seconds: float = {"solar": 3.6, "wave": 2.4, "vitals": 0.7, "energy": 0.9, "disconnect": 0.85, "radio": 0.24}[kind]
	var data := PackedByteArray()
	data.resize(int(RATE * seconds) * 2)
	var random := RandomNumberGenerator.new()
	random.seed = 60724
	var low := 0.0
	for i in range(int(RATE * seconds)):
		var t := float(i) / RATE
		var noise := random.randf_range(-1, 1)
		low = low * 0.92 + noise * 0.08
		var sample := 0.0
		match kind:
			"solar", "wave":
				# Distant explosion: low thump, filtered dust and three fading echoes.
				for echo in range(4):
					var age := t - echo * 0.44
					if age < 0: continue
					var envelope := (1.0 - exp(-age * 35)) * exp(-age * 3.0) * pow(0.48, echo)
					sample += (sin(TAU * (48 * age + 10 * (1 - exp(-age * 5)))) * 0.42 + low * 1.1) * envelope
			"vitals":
				var phase := fmod(t, 0.34)
				if phase < 0.18:
					var envelope := sin(PI * phase / 0.18)
					sample = sin(TAU * (920 if t < 0.34 else 700) * t) * envelope * 0.45
			"energy":
				var crackle := pow(maxf(0, sin(t * 173)), 9)
				sample = ((noise - low) * crackle * 0.55 + sin(TAU * 100 * t) * 0.12) * sin(PI * t / seconds)
			"disconnect":
				var note := 1046.5 if t < 0.2 else 659.25 if t < 0.4 else 261.63
				var envelope := minf(1, t * 60) * minf(1, (seconds - t) * 15)
				sample = (sin(TAU * note * t) * 0.28 + noise * 0.035) * envelope
			"radio":
				sample = (sin(TAU * 1320 * t) * 0.15 + noise * 0.1) * sin(PI * t / seconds)
		data.encode_s16(i * 2, int(clampf(sample, -0.9, 0.9) * 24000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	return stream
