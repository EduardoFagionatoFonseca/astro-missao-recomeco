extends RefCounted

func run(game: Node3D) -> void:
	assert(is_equal_approx(game.MOVE_SPEED, 3.78 * 1.03))
	assert(not InputMap.has_action("run"))
	var feedback: Control = game.feedback
	feedback.set_link(true)
	game.communications_online = true
	feedback.seen.erase("solar_tutorial")
	feedback.shelter_tutorial()
	feedback.notice_time = 2
	feedback.shelter_tutorial()
	assert(feedback.notice_time == 2) # Tutorial never repeats, including later solar cycles.
	game._on_power_repaired()
	game._update_energy(game.ENERGY_INTERVAL - 0.1)
	assert(game.energy_ready)
	game._update_energy(0.2)
	assert(not game.energy_ready and game.event_audio.players.energy.playing)
	game._on_power_repaired()
	assert(game.energy_clock == 0 and game.energy_charge == 100)
	game._on_signal_sent()
	game._update_energy(game.SIGNAL_INTERVAL + 0.1)
	assert(not game.signal_transmitted and game.event_audio.players.disconnect.playing)
	game._on_power_repaired()
	game.minigames.open_signal(true, 6, false, game.signal_failures)
	assert(game.minigames.target_frequency != 64 or game.minigames.target_alignment != 38)
	game.minigames.frequency.value = game.minigames.target_frequency
	game.minigames.alignment.value = game.minigames.target_alignment
	game.minigames._process(3.1)
	assert(game.signal_transmitted and game.signal_clock == 0)
	game.minigames.close()
	var events: Dictionary = game.event_audio.players
	assert(events.solar.stream.data != events.vitals.stream.data)
	assert(events.energy.stream.data != events.disconnect.stream.data)
	assert(events.solar.volume_db < events.vitals.volume_db)
	assert(events.collect.stream.data != events.death.stream.data)
	game.energy_charge = 25
	game.elapsed = 0
	game._update_hud(0)
	var alpha: float = game.power_label.modulate.a
	game.elapsed = 0.4
	game._update_hud(0)
	assert(game.power_label.modulate.a != alpha)
	game.energy_charge = 100
	game._update_hud(0)
	assert(game.power_label.modulate.a == 1)
	var writer := preload("res://scripts/typewriter.gd").new()
	writer.begin(feedback.dialogue, "Estamos chegando.")
	assert(feedback.dialogue.visible_characters == 0)
	writer.advance(0.04)
	assert(feedback.dialogue.visible_characters > 0 and feedback.dialogue.visible_characters < 17)
	writer.advance(1)
	assert(feedback.dialogue.visible_characters >= 17)
	game.event_audio.set_muted(true)
	for event: AudioStreamPlayer in events.values(): assert(event.volume_db == -80)
	game.event_audio.set_muted(false)
	events.vitals.play()
	game.event_audio.set_paused(true)
	assert(events.vitals.stream_paused)
	game.event_audio.set_paused(false)
	game.oxygen = 10
	game.food = 10
	game.oxygen_critical = false
	game._resource_warnings()
	assert(events.vitals.playing)
	game._update_hud(0)
	var fill: StyleBoxFlat = game.oxygen_bar.get_theme_stylebox("fill")
	assert(fill.bg_color.r > fill.bg_color.g * 1.5)
	feedback.transmit("unit_story", "Mensagem única")
	var count: int = feedback.queue.size()
	feedback.transmit("unit_story", "Mensagem duplicada")
	assert(feedback.queue.size() == count)
	game.energy_ready = false
	game.energy_charge = 0
	game.energy_clock = 0
	game.signal_transmitted = false
	game.signal_clock = 0
	game.oxygen = game.MAX_RESERVE
	game.food = game.MAX_RESERVE
	game._resource_warnings()
	for event: AudioStreamPlayer in events.values(): event.stop()
	print("PASS: interior-only radiation protection, one-time tutorial, recurring power/signal failures and retuning, unique radio messages, fixed speed and distinct alarms")
