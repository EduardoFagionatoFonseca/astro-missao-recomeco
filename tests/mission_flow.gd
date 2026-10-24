extends RefCounted

func run(game: Node3D) -> void:
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
	var forecast := "solar_warning_%d" % game.solar_cycle
	game.feedback.seen.erase(forecast)
	game.solar_phase = "calm"
	game.solar_clock = game.SOLAR_INTERVAL - 0.1
	game._update_solar_notices()
	assert(not game.feedback.seen.has(forecast))
	game.solar_phase = "warning"
	game.solar_clock = game.SOLAR_WARNING - 4.1
	game._update_solar_notices()
	assert(not game.feedback.seen.has(forecast))
	game.feedback.current_time = 3
	game.solar_clock = game.SOLAR_WARNING - 4
	game._update_solar_notices()
	assert(game.feedback.seen.has(forecast) and game.feedback.current_time == 0)
	game.feedback.active = true
	game.feedback.tick(0.02)
	assert(game.feedback.dialogue.text.contains("4 s") and game.feedback.speaker.text == game.feedback.AXIOS)
	game._update_solar_notices()
	assert(game.feedback.current_time > 0) # Does not keep interrupting itself.
	game.feedback.seen.erase(forecast)
	game.communications_online = false
	game.feedback.set_link(false)
	game._update_solar_notices()
	assert(not game.feedback.seen.has(forecast))
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
	print("PASS: antenna auto-close/lock/re-enable, radio warning only 4 seconds before fog with preemption/offline gating, growing exposure effect cleared by shelter")
