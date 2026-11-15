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
	# The storm starts at the advertised time, even when already sheltered.
	game.get_node("SurvivalSystem").start_warning()
	game._apply_location(true)
	assert(game.solar_phase == "warning" and not game.fog_audio.playing)
	var warning: float = game.solar_remaining
	game._update_radiation(warning)
	assert(game.solar_phase == "active" and game.alert_audio.playing and game.fog_audio.playing)
	assert(game.fog_audio.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD)
	assert(is_equal_approx(game.solar_remaining, game.SOLAR_SHELTER_TIME))
	game._update_hud(0)
	assert(game.survival_timer_label.text == "NÉVOA PASSA EM   3,0 s")
	game._update_radiation(2.5)
	game._apply_location(false)
	assert(game.alert_audio.playing and game.fog_audio.playing)
	game._apply_location(true)
	assert(is_equal_approx(game.solar_remaining, 0.5)) # Re-entry does not extend the storm.
	game._update_radiation(0.5)
	assert(game.solar_phase == "calm" and not game.fog_audio.playing and not game.alert_audio.playing)
	assert(game.task_question.open_task("radiation") and game.task_question.proceed.visible)
	game.task_question._close()
	assert(not game.task_question.visible)
	assert(not game.task_question.open_task("radiation"))
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
	game.audio_settings.close()
	print("PASS: transparent action row, warm Start, quieter separate music gains, distant larger Sun/smaller Moon, radiation sound across shelter until event end, offline resource notices and Escape cannot pause")
