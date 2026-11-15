extends RefCounted

func run(game: Node3D) -> void:
	_check_warning_budget(game)
	game._on_power_repaired()
	game.found[1] = 6
	game.signal_transmitted = false
	game.communications_online = true
	game._apply_location(true)
	game.avatar.position = game.base_room.position + Vector3(2.3, 0, -1.6)
	game._interact()
	assert(game.minigames.visible)
	game.minigames.frequency.value = game.minigames.target_frequency
	game.minigames.alignment.value = game.minigames.target_alignment
	game.minigames._process(3.1)
	assert(game.signal_transmitted and not game.minigames.visible)
	game._update_prompt()
	assert(game.prompt_target == "" and not game.controls.action_available)
	game._interact()
	assert(not game.minigames.visible)
	game.minigames.open_signal(true, 6, true)
	assert(not game.minigames.visible)
	game._update_energy(game.SIGNAL_INTERVAL + 0.01)
	game._on_power_repaired()
	game._interact()
	assert(game.minigames.visible) # Failure re-enables the station.
	game.minigames.close()
	game._apply_location(false)
	game.found[1] = 0
	game.signal_transmitted = false
	game.communications_online = true
	game.signal_clock = 0
	game.feedback.set_link(true)
	game.normal = game.camp_normal
	var forecast := "solar_warning_%d" % game.solar_cycle
	game.feedback.seen.erase(forecast)
	game.solar_phase = "calm"
	game.solar_clock = game.SOLAR_INTERVAL - 0.1
	game._update_solar_notices()
	assert(not game.feedback.seen.has(forecast))
	game._update_radiation(0.11)
	assert(game.solar_phase == "warning" and game.event_audio.players.forecast.playing)
	game.feedback.current_time = 3
	game._update_solar_notices()
	assert(game.feedback.seen.has(forecast) and game.feedback.current_time == 0)
	game.feedback.active = true
	game.feedback.tick(0.02)
	assert(game.feedback.dialogue.text.contains("Radiação em %d s" % ceili(game.solar_remaining)) and game.feedback.speaker.text == game.feedback.AXIOS)
	game._update_solar_notices()
	assert(game.feedback.current_time > 0) # Does not keep interrupting itself.
	game.feedback.seen.erase(forecast)
	game.communications_online = false
	game.feedback.set_link(false)
	game._update_solar_notices()
	assert(not game.feedback.seen.has(forecast))
	game._update_hud(0)
	assert(game.survival_timer.visible and game.survival_timer_label.text == "NÉVOA SOLAR EM   4,4 s")
	game.communications_online = true
	game.feedback.set_link(true)
	game.solar_phase = "active"
	game.solar_clock = 0
	game.exposure = 0
	game._update_radiation(0.5)
	game._update_hud(0)
	var early: float = game.vignette_material.get_shader_parameter("radiation")
	game._update_radiation(1)
	game._update_hud(0)
	assert(float(game.vignette_material.get_shader_parameter("radiation")) > early)
	game._apply_location(true)
	game._update_hud(0)
	assert(float(game.vignette_material.get_shader_parameter("radiation")) == 0)
	game.solar_phase = "calm"
	game.solar_clock = 0
	game._apply_location(false)
	game._update_controls()
	print("PASS: antenna auto-close/lock/re-enable, local and radio warnings from onset, exposure cleared by shelter")

func _check_warning_budget(game: Node3D) -> void:
	var survival: Node = game.get_node("SurvivalSystem")
	var original_normal: Vector3 = game.normal
	var original_difficulty := GameOptions.difficulty
	var original_phase: String = game.solar_phase
	var original_clock: float = game.solar_clock
	var original_remaining: float = game.solar_remaining
	var original_fuel: int = game.found[game.ItemKind.FUEL]
	var original_inside: bool = game.inside
	game.inside = false
	game.normal = game.camp_normal
	GameOptions.difficulty = 1
	survival.start_warning()
	assert(is_equal_approx(game.solar_remaining, 4.0 + game.SHELTER_ENTRY_FADE + 0.25))
	game.normal = -game.camp_normal
	var distance: float = PI * game.R - game.SHELTER_RADIUS
	var travel: float = distance / game._move_speed() + game.SHELTER_ENTRY_FADE
	for difficulty in range(3):
		GameOptions.difficulty = difficulty
		survival.start_warning()
		assert(game.solar_remaining >= travel + 5.0 - difficulty)
	var walking_warning: float = game.solar_remaining
	game.found[game.ItemKind.FUEL] = game.GOALS[game.ItemKind.FUEL]
	survival.start_warning()
	assert(game.solar_remaining < walking_warning)
	var warning: float = game.solar_remaining
	game.normal = game.camp_normal
	game._update_radiation(warning - 3.0)
	game.inside = true
	survival.shelter_from_solar()
	assert(game.solar_phase == "warning" and is_equal_approx(game.solar_remaining, 3.0))
	game._update_radiation(3.01)
	assert(game.solar_phase == "active" and game.exposure == 0.0)
	game.event_audio.stop_all()
	game.found[game.ItemKind.FUEL] = original_fuel
	GameOptions.difficulty = original_difficulty
	game.normal = original_normal
	game.inside = original_inside
	game.solar_phase = original_phase
	game.solar_clock = original_clock
	game.solar_remaining = original_remaining
	game.radiation_question_pending = false
