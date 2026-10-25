extends RefCounted

func run(game: Node3D) -> void:
	var options: Node = game.get_node("/root/GameOptions")
	var before: int = options.difficulty
	var last := 0.0
	for level in range(3):
		options.difficulty = level
		assert(options.pressure(0) > last)
		last = options.pressure(0)
		assert(options.pressure(1) > options.pressure(0))
		assert(options.pressure(0.5) < options.pressure(1))
	options.difficulty = 1
	var collected: int = game.collected
	game.collected = 0
	game.inside = false
	game.normal = Vector3.DOWN
	game.oxygen = game.MAX_RESERVE
	game.food = game.MAX_RESERVE
	game._update_survival(1)
	var initial: float = game.oxygen
	game.collected = game.TOTAL
	game.oxygen = game.MAX_RESERVE
	game._update_survival(1)
	assert(game.oxygen < initial)
	game.collected = collected
	game.solar_phase = "calm"
	game.solar_clock = 0
	game.oxygen = game.MAX_RESERVE
	game.food = game.MAX_RESERVE
	game.energy_charge = 100
	game.communications_online = true
	game.controls.set_enabled(true)
	var guide: Control = game.guide
	guide.done.clear()
	guide.started.clear()
	game.oxygen = 20
	guide.update_guide(game, 0)
	assert(guide.visible and guide.objective_id == "oxygen")
	game.oxygen = game.MAX_RESERVE
	guide.update_guide(game, 0)
	assert(guide.done.has("oxygen"))
	game.oxygen = 20
	guide.update_guide(game, 0)
	assert(guide.objective_id != "oxygen")
	game.food = 20
	guide.update_guide(game, 0)
	assert(guide.objective_id == "food")
	game.food = game.MAX_RESERVE
	guide.update_guide(game, 0)
	assert(guide.done.has("food"))
	game.oxygen = game.MAX_RESERVE
	game.energy_charge = 25
	guide.update_guide(game, 0)
	assert(guide.caption == "Repare a energia")
	game.energy_charge = 100
	guide.update_guide(game, 0)
	assert(guide.done.has("energy"))
	game.communications_online = false
	guide.update_guide(game, 0)
	assert(guide.caption == "Restaure o sinal")
	var sent: bool = game.signal_transmitted
	game.communications_online = true
	game.signal_transmitted = true
	guide.update_guide(game, 0)
	assert(guide.done.has("signal"))
	game.signal_transmitted = sent
	game.solar_phase = "warning"
	game.solar_clock = 5
	guide.update_guide(game, 0)
	assert(guide.caption == "Entre no abrigo")
	game.inside = true
	guide.update_guide(game, 0)
	assert(guide.done.has("solar"))
	game.inside = false
	game.solar_phase = "calm"
	game.solar_clock = 0
	TranslationServer.set_locale("en")
	assert(game.tr("COMIDA") == "FOOD")
	game.intro_video.begin(true)
	assert(game.intro_video.caption.text == "A storm separated you from the expedition on Mars.")
	game.intro_video.active = false
	game.intro_video.player.stop()
	game.intro_video.hide()
	TranslationServer.set_locale("pt_BR")
	# One active need, preempted as the relative urgency changes.
	guide.done.clear()
	guide.started.clear()
	game.oxygen = 20
	game.food = 10
	guide.update_guide(game, 0)
	assert(guide.objective_id == "food")
	game.oxygen = 5
	guide.update_guide(game, 0)
	assert(guide.objective_id == "oxygen")
	game.oxygen = game.MAX_RESERVE
	guide.update_guide(game, 0)
	assert(guide.objective_id == "food")
	game.food = game.MAX_RESERVE
	guide.update_guide(game, 0)
	for level in [1, 2]:
		options.difficulty = level
		game.oxygen = 5
		game.food = game.MAX_RESERVE
		guide.update_guide(game, 0)
		assert(guide.objective_id != "oxygen")
	options.difficulty = 0
	guide.update_guide(game, 0)
	assert(guide.objective_id == "oxygen")
	game.oxygen = game.MAX_RESERVE
	guide.update_guide(game, 0)
	game.oxygen = 5
	guide.update_guide(game, 0)
	assert(guide.objective_id == "oxygen")
	options.difficulty = before
	game.oxygen = game.MAX_RESERVE
	game.food = game.MAX_RESERVE
	guide.done.clear()
	guide.started.clear()
	guide.hide()
	print("PASS: selectable progressive difficulty, first-occurrence guidance and English video captions")
