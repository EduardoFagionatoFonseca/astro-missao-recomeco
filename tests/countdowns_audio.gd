extends RefCounted

func run(game: Node3D) -> void:
	assert(game.EXPOSURE_LIMIT == 5)
	var sound: Control = game.audio_settings
	var previous: float = sound.volumes["Music"]
	sound._set_volume("Music", 1, false)
	assert(is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Music")), 0.8))
	sound._set_volume("Music", 0.5, false)
	assert(is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Music")), 0.4))
	sound._set_volume("Music", previous, false)
	game.normal = Vector3.DOWN
	game.inside = false
	game.solar_phase = "active"
	game.solar_clock = 0
	game.exposure = 1.2
	game.oxygen = game.OXYGEN_RATE
	game.food = game.FOOD_RATE
	game.oxygen_empty_time = 0
	game.food_empty_time = 0
	game._update_hud(0)
	assert(game.survival_timer.visible)
	assert(game.survival_timer_label.text.contains("RADIAÇÃO   3,8 s"))
	assert(game.survival_timer_label.text.contains("O₂   3,0 s"))
	assert(game.survival_timer_label.text.contains("COMIDA   3,0 s"))
	game.oxygen = 0
	game.food = 0
	game.oxygen_empty_time = 1
	game.food_empty_time = 1
	game._update_hud(0)
	assert(game.survival_timer_label.text.contains("O₂   1,0 s") and game.survival_timer_label.text.contains("COMIDA   1,0 s"))
	game._apply_location(true)
	game.energy_ready = false
	game._update_hud(0)
	assert(not game.survival_timer_label.text.contains("RADIAÇÃO"))
	assert(game.survival_timer_label.text.contains("O₂"))
	game._on_power_repaired()
	game._update_hud(0)
	assert(not game.survival_timer_label.text.contains("O₂"))
	game.oxygen = game.MAX_RESERVE
	game.food = game.MAX_RESERVE
	game.oxygen_empty_time = 0
	game.food_empty_time = 0
	game.solar_phase = "calm"
	game.solar_clock = 0
	game._apply_location(false)
	game.normal = game.camp_normal
	game._update_hud(0)
	assert(not game.survival_timer.visible)
	print("PASS: radiation/life-support countdowns, grace-period timing, shelter/recovery cleanup and music scale 100%=0.8 / 50%=0.4")
