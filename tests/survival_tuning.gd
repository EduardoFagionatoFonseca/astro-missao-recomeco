extends RefCounted

func run(game: Node3D) -> void:
	assert(game.start_menu.actions.get_theme_stylebox("panel") is StyleBoxEmpty)
	assert(game.start_menu.start.get_theme_stylebox("normal").bg_color.r > game.start_menu.start.get_theme_stylebox("normal").bg_color.b)
	assert(not game.has_method("_toggle_pause"))
	assert(game.distant_light.position.length() >= 175 and game.distant_light.mesh.radius > 6)
	assert(is_equal_approx(game.moon.mesh.radius, 2.25))
	game._update_music(2)
	assert(is_equal_approx(db_to_linear(game.music.volume_db), 0.16))
	game._apply_location(true)
	game._update_music(2)
	assert(is_equal_approx(db_to_linear(game.base_music.volume_db), 0.24))
	# The full event is audible both inside and outside, without restarting on entry.
	game.solar_phase = "warning"
	game.solar_clock = game.SOLAR_WARNING - 0.05
	game._update_radiation(0.1)
	assert(game.solar_phase == "active" and game.alert_audio.playing and game.fog_audio.playing)
	assert(game.fog_audio.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD)
	game._apply_location(false)
	assert(game.alert_audio.playing and game.fog_audio.playing)
	game._update_radiation(0.4)
	game._apply_location(true)
	assert(game.fog_audio.playing)
	game._update_radiation(game.SOLAR_DURATION)
	assert(game.solar_phase == "calm" and not game.fog_audio.playing and not game.alert_audio.playing)
	game._apply_location(false)
	game.solar_clock = 0
	game.exposure = 0
	# Suit notices work offline, combine simultaneous lows, and rearm on recovery.
	game.feedback.set_link(false)
	game.oxygen_low = false
	game.food_low = false
	game.oxygen_critical = false
	game.food_critical = false
	game.oxygen = 20
	game.food = 20
	game._resource_warnings()
	assert(not game.feedback.notice_requires_link)
	assert(game.feedback.notice_label.text.contains("O₂") and game.feedback.notice_label.text.contains("Comida"))
	var serial: int = game.health_notice_serial
	game.feedback.set_link(false)
	assert(game.feedback.notice_time > 0)
	game._resource_warnings()
	assert(game.health_notice_serial == serial)
	game.oxygen = game.MAX_RESERVE
	game.food = game.MAX_RESERVE
	game._resource_warnings()
	game.oxygen = 10
	game._resource_warnings()
	assert(game.health_notice_serial > serial and game.feedback.notice_label.text.contains("crítico"))
	game.oxygen = game.MAX_RESERVE
	game.food = game.MAX_RESERVE
	game._resource_warnings()
	game.feedback.notice_time = 0
	game.feedback.set_link(game.communications_online)
	game.event_audio.stop_all()
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	game._unhandled_key_input(escape)
	var previous_food: float = game.food
	game._process(0.1)
	assert(game.food < previous_food)
	print("PASS: transparent action row, warm Start, quieter separate music gains, distant larger Sun/smaller Moon, radiation sound across shelter until event end, offline resource notices and Escape cannot pause")
