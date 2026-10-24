extends Node
## Original event sounds. Separate channels keep life support distinct from solar weather.
const RATE := 22050
const LEVELS := {"solar": -20.0, "fog": -23.0, "vitals": -8.0, "energy": -12.0, "disconnect": -11.0, "radio": -19.0, "typing": -25.0, "collect": -8.0, "death": -9.0}
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
	if kind == "typing" and players[kind].playing: return
	if not muted: players[kind].play()

func stop_all() -> void:
	for player: AudioStreamPlayer in players.values(): player.stop()

func set_muted(value: bool) -> void:
	muted = value
	for kind: String in players:
		players[kind].volume_db = -80.0 if muted else LEVELS[kind]

func set_paused(value: bool) -> void:
	for player: AudioStreamPlayer in players.values(): player.stream_paused = value

func _synthesize(kind: String) -> AudioStreamWAV:
	var seconds: float = {"solar": 3.6, "fog": 2.4, "vitals": 0.7, "energy": 0.9, "disconnect": 0.85, "radio": 0.24, "typing": 0.035, "collect": 0.48, "death": 1.5}[kind]
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
			"solar", "fog":
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
			"typing":
				sample = (noise * 0.17 + sin(TAU * 1700 * t) * 0.06) * (1 - exp(-t * 1800)) * exp(-t * 140)
			"collect":
				# Soft tactile click plus a rising, overlapping bell triad.
				sample = noise * 0.12 * exp(-t * 180)
				for note in range(3):
					var age := t - note * 0.035
					if age < 0: continue
					var frequency: float = [784.0, 987.77, 1174.66][note]
					var envelope := (1 - exp(-age * 700)) * exp(-age * 12)
					sample += (sin(TAU * frequency * age) * 0.25 + sin(TAU * frequency * 2 * age) * 0.035) * envelope
			"death":
				var envelope := (1 - exp(-t * 60)) * exp(-t * 2.7)
				var frequency := 210.0 * t - 48.0 * t * t
				sample = (sin(TAU * frequency) * 0.42 + sin(TAU * frequency * 0.75) * 0.16 + low * 0.12) * envelope
		data.encode_s16(i * 2, int(clampf(sample, -0.9, 0.9) * 24000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	return stream
