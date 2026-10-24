extends RefCounted

func run(game: Node3D) -> void:
	assert(game.MAX_RESERVE == 105 and game._percent(game.MAX_RESERVE) == 100)
	assert(game.ENERGY_INTERVAL == 75 * 0.85 and game.SIGNAL_INTERVAL == 100 * 0.85)
	game.normal = game.camp_normal
	game.inside = true
	game.oxygen = 60
	game.food = game.MAX_RESERVE
	game.energy_ready = false
	game._update_survival(1)
	assert(is_equal_approx(game.oxygen, 60 - game.OXYGEN_RATE))
	game._on_power_repaired()
	game._update_survival(1)
	assert(game.oxygen > 60)
	game.avatar.position = game.base_room.position + Vector3(-2.3, 0, -1.6)
	game.energy_charge = 29
	game._interact()
	assert(game.minigames.visible and not game.minigames.sources[0].disabled)
	game.minigames.close()
	game.avatar.position = game.normal * game.R
	game.base_room.set_solar("warning")
	assert(game.base_room.window_glass.material_override.emission_enabled)
	assert(game.base_room.window_light.light_energy > 0)
	game.base_room.set_solar("calm")
	assert(not game.base_room.window_glass.material_override.emission_enabled)
	game.inside = false
	var feedback: Control = game.feedback
	feedback.set_link(false)
	game.communications_online = false
	feedback.transmit("offline_test", "Oculto")
	assert(feedback.queue.is_empty() and not feedback.seen.has("offline_test"))
	game.solar_phase = "calm"
	game.solar_clock = game.SOLAR_INTERVAL - 15
	var forecast := "solar_early_%d" % game.solar_cycle
	feedback.seen.erase(forecast)
	game._update_solar_notices()
	assert(not feedback.seen.has(forecast))
	game.communications_online = true
	feedback.set_link(true)
	game._update_solar_notices()
	assert(feedback.seen.has(forecast) and feedback.queue.back().speaker == feedback.AXIOS)
	game.energy_clock = 0
	game.energy_low_announced = false
	game.energy_ready = true
	game._update_energy(game.ENERGY_INTERVAL * 0.71)
	assert(game.energy_low_announced and game.energy_charge < 30)
	feedback.set_link(false)
	assert(feedback.queue.is_empty() and not feedback.radio.visible)
	# Completing or skipping the video opens the briefing, never active gameplay.
	game.intro_video.active = true
	game.intro_video._finish()
	assert(game.intro.visible and not game.playing and not game.controls.enabled)
	var before := [game.oxygen, game.food, game.energy_clock, game.signal_clock, game.solar_clock]
	game._process(4)
	assert(before == [game.oxygen, game.food, game.energy_clock, game.signal_clock, game.solar_clock])
	var view: Vector2 = game.get_viewport().get_visible_rect().size
	assert(is_equal_approx(game.intro.panel.size.x * game.intro.panel.size.y / (view.x * view.y), 0.7056))
	assert(game.material_icons.size() == 3)
	assert(game.intro.page_index == 0)
	game.intro._next()
	assert(game.intro.page_index == 1 and not game.playing)
	game._process(4)
	assert(before == [game.oxygen, game.food, game.energy_clock, game.signal_clock, game.solar_clock])
	game.intro._next()
	assert(game.playing and not game.intro.visible)
	game.communications_online = true
	feedback.set_link(true)
	game.signal_clock = 0
	game.energy_clock = 0
	game.energy_ready = true
	game.energy_charge = 100
	game.signal_transmitted = false
	game.solar_phase = "calm"
	game.solar_clock = 0
	game.oxygen = game.MAX_RESERVE
	game.food = game.MAX_RESERVE
	print("PASS: power-dependent oxygen, AXIOS/link-gated forecasts, illuminated window, 15/5 percent balance, post-video frozen briefing and item thumbnails")
