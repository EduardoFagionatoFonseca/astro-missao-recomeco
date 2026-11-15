extends RefCounted

func run(game: Node3D) -> void:
	game.inside = false
	game.found = [0, 0, 0]
	game.collected = 0
	game.signal_transmitted = false
	game.communications_online = true
	for item in game.items: item.taken = false
	game._sync_resource_visibility()
	var photo := -1
	var fuels: Array[int] = []
	for i in range(game.items.size()):
		var item: Dictionary = game.items[i]
		assert(item.node.visible == (item.kind == game.ItemKind.PART))
		if item.kind == game.ItemKind.PHOTO: photo = i
		if item.kind == game.ItemKind.FUEL: fuels.append(i)
	var last_fuel: int = fuels.pop_back()
	game.normal = game.items[photo].normal
	assert(game._nearest() != photo)
	game._collect(photo)
	assert(game.collected == 0)
	game._on_signal_sent()
	assert(not game.signal_transmitted and not game.items[photo].node.visible)
	for i in range(game.items.size()):
		if game.items[i].kind == game.ItemKind.PART: game._collect(i)
	assert(game.found == [0, 6, 0] and game.collected == 6)
	game._on_power_repaired()
	game._on_signal_sent()
	assert(game.signal_transmitted and not game.items[photo].node.visible and game.items[last_fuel].node.visible)
	for index in fuels: game._collect(index)
	game._collect(photo)
	assert(game.found == [0, 6, 7] and not game._rover_unlocked())
	assert(is_equal_approx(game._move_speed(), game.MOVE_SPEED))
	assert(not game.items[photo].node.visible and game._nearest() != photo)
	game._update_energy(game.SIGNAL_INTERVAL + 0.01)
	assert(not game.communications_online and not game.items[last_fuel].node.visible)
	game._collect(last_fuel)
	assert(game.found == [0, 6, 7])
	game._apply_location(true)
	game._apply_location(false)
	assert(not game.items[photo].node.visible and not game.items[last_fuel].node.visible)
	game._on_power_repaired()
	game._on_signal_sent()
	game.normal = game.items[last_fuel].normal
	game.altitude = game.terrain.height_at(game.normal)
	game._interact()
	assert(game._rover_unlocked() and game.rover.visible and game.rover.get_parent() == game)
	assert(is_equal_approx(game._move_speed(), game.MOVE_SPEED * 1.20))
	assert(game.items[photo].node.visible and game.feedback.seen.has("rover_unlocked"))
	var quiz: Control = game.task_question
	var metadata := {"collection": {"items": [{"data": [{"nasa_id": "PIA25172", "title": "Perseverance Looks Toward 'Santa Cruz'"}]}]}}
	quiz._apply_rover_photo_metadata(metadata)
	assert(quiz.open_task(quiz.ROVER_TASK) and quiz.prompt.text.contains("Santa Cruz"))
	assert(not game.hud_root.visible and not game.feedback.visible and not game.mission_map.visible)
	var vitals := [game.oxygen, game.food, game.solar_clock]
	game._process(10)
	assert(vitals == [game.oxygen, game.food, game.solar_clock])
	quiz._answer(1)
	assert(quiz.proceed.visible and quiz.source.visible and quiz.source.tooltip_text.contains("Perseverance"))
	quiz._close()
	assert(not quiz.open_task(quiz.ROVER_TASK) and game.hud_root.visible and game.mission_map.visible)
	game._update_hud(0)
	assert(game.objectives_ui.get_child(0).visible and not game.objectives_ui.get_child(1).visible and not game.objectives_ui.get_child(2).visible)
	game._apply_location(true)
	assert(not game.rover.visible and not game.items[photo].node.visible)
	game._apply_location(false)
	assert(game.rover.visible and game.items[photo].node.visible)
	var previous_rover: Vector3 = game.rover.position
	game.pad = Vector2(0, 1)
	for step in range(40): game._update_movement(1.0 / 60.0)
	game.pad = Vector2.ZERO
	var rover_up: Vector3 = game.rover.position.normalized()
	assert(game.rover.position.distance_to(previous_rover) > 0.5)
	assert(absf(game.rover.position.length() - game.R - game.terrain.height_at(rover_up)) < 0.01)
	assert(game.normal.angle_to(rover_up) * game.R < 3.0)
	game._update_energy(game.SIGNAL_INTERVAL + 0.01)
	assert(not game.items[photo].node.visible and game._rover_unlocked() and game.rover.visible)
	assert(is_equal_approx(game._move_speed(), game.MOVE_SPEED * 1.20))
	game._on_power_repaired()
	game._on_signal_sent()
	game.normal = game.items[photo].normal
	game.altitude = game.terrain.height_at(game.normal)
	game._update_prompt()
	assert(game.prompt_target == "photo")
	game._interact()
	assert(game.found == [1, 6, 8] and not game.items[photo].node.visible)
	assert(game.items[photo].photo in game.photo_archive.unlocked)
	assert(game.event_audio.players.photo.playing)
	game.photo_archive.open()
	assert(game.photo_archive.is_open() and not game.mission_map.visible)
	assert(game.event_audio.players.archive.playing)
	assert(game.event_audio.players.archive.stream.data != game.event_audio.players.photo.stream.data)
	game.event_audio.players.archive.stop()
	game.photo_archive.cards[game.items[photo].photo].pressed.emit()
	assert(game.event_audio.players.archive.playing)
	game.photo_archive.close()
	assert(game.mission_map.visible)
	# Settings keep independent gains but do not stop survival.
	var before := [game.oxygen, game.food, game.solar_clock, game.energy_clock, game.signal_clock]
	var previous: float = game.audio_settings.sliders[2].value
	game.audio_settings.open()
	game.audio_settings.sliders[2].value = 0
	assert(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Interactions")) == 0)
	assert(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Alerts")) > 0)
	game._process(1)
	assert(game.food < before[1] and game.solar_clock > before[2] and game.energy_clock > before[3])
	assert(not game.controls.enabled)
	game.audio_settings.sliders[2].value = previous
	game.audio_settings.close()
	game._update_music(1.3)
	assert(game.music.volume_db > game.base_music.volume_db)
	game.inside = true
	game._update_music(1.3)
	assert(game.base_music.volume_db > game.music.volume_db)
	assert(game.music.stream.resource_path.ends_with("space-galaxy.mp3"))
	assert(game.base_music.stream.resource_path.ends_with("space-ship.mp3"))
	assert(game.music.stream.loop and game.base_music.stream.loop)
	game.inside = false
	game.normal = game.camp_normal
	game.oxygen = game.MAX_RESERVE
	game.food = game.MAX_RESERVE
	print("PASS: antenna → fuel → rover and photos, ground-following companion, inventory and boost retained offline, settings and audio")
