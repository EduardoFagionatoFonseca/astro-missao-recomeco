extends Node
## Owns the music players, interaction chime, and location-based music mix.
var game: Node3D
var planet_music: AudioStreamPlayer
var base_music_player: AudioStreamPlayer
var effects_player: AudioStreamPlayer

func _ready() -> void:
	game = get_parent()
	planet_music = $PlanetMusic
	base_music_player = $BaseMusic
	effects_player = $Effects

func build() -> void:
	game.music = planet_music
	planet_music.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	planet_music.bus = "Music"
	planet_music.stream = preload("res://assets/audio/space-galaxy.mp3")
	planet_music.stream.loop = true
	planet_music.volume_db = linear_to_db(game.PLANET_MUSIC_GAIN)
	planet_music.play()
	game.base_music = base_music_player
	base_music_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	base_music_player.bus = "Music"
	base_music_player.stream = preload("res://assets/audio/space-ship.mp3")
	base_music_player.stream.loop = true
	base_music_player.volume_db = -80
	base_music_player.play()
	game.sound = effects_player
	effects_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	effects_player.bus = "Interactions"
	game.event_audio = game.get_node("EventAudio")
	game.alert_audio = game.event_audio.players["solar"]
	game.fog_audio = game.event_audio.players["fog"]

func update_music(delta: float) -> void:
	if game.music == null or game.base_music == null: return
	if game.won or (game.intro_video != null and game.intro_video.active): return
	game.music_mix = move_toward(game.music_mix, 1.0 if game.inside else 0.0, delta / 1.2)
	var duck := 0.25 if game.dead else 0.4 if game.solar_phase == "active" else 1.0
	game.music.volume_db = linear_to_db(maxf(0.0001, (1.0 - game.music_mix) * game.PLANET_MUSIC_GAIN * duck))
	game.base_music.volume_db = linear_to_db(maxf(0.0001, game.music_mix * game.BASE_MUSIC_GAIN * duck))

func play_chime(frequency: float) -> void:
	if game.sound == null or game.muted: return
	var data := PackedByteArray()
	var length := 6615
	data.resize(length * 2)
	for i in range(length):
		var t := float(i) / 22050.0
		var wave := sin(TAU * frequency * t) + sin(TAU * frequency * 1.5 * t) * 0.25
		data.encode_s16(i * 2, int(wave * exp(-t * 15) * 4500))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	game.sound.stream = stream
	game.sound.play()
