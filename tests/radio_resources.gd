extends RefCounted

func run(game: Node3D) -> void:
	game.inside = false
	game.found = [0, 0, 0]
	game.collected = 0
	game.signal_transmitted = false
	game.communications_online = true
	for item in game.items: item.taken = false
	game._sync_resource_visibility()
	var rock := -1
	var fuel := -1
	for i in range(game.items.size()):
		var item: Dictionary = game.items[i]
		assert(item.node.visible == (item.kind == 1))
		if item.kind == 0: rock = i
		if item.kind == 2: fuel = i
	game.normal = game.items[rock].normal
	assert(game._nearest() != rock)
	game._collect(rock)
	assert(game.collected == 0)
	game._on_signal_sent()
	assert(not game.signal_transmitted and not game.items[rock].node.visible)
	for i in range(game.items.size()):
		if game.items[i].kind == 1: game._collect(i)
	assert(game.found == [0, 6, 0] and game.collected == 6)
	game._on_power_repaired()
	game._on_signal_sent()
	assert(game.signal_transmitted and game.items[rock].node.visible and game.items[fuel].node.visible)
	game._collect(rock)
	assert(game.found == [1, 6, 0])
	game._update_energy(game.SIGNAL_INTERVAL + 0.01)
	assert(not game.communications_online and not game.items[fuel].node.visible)
	game._collect(fuel)
	assert(game.found == [1, 6, 0])
	game._apply_location(true)
	game._apply_location(false)
	assert(not game.items[rock].node.visible and not game.items[fuel].node.visible)
	game._on_power_repaired()
	game._on_signal_sent()
	assert(not game.items[rock].node.visible and game.items[fuel].node.visible)
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
	print("PASS: antenna discovery, offline collection blocked, inventory retained, independent audio gains, settings keep survival running and location music")
