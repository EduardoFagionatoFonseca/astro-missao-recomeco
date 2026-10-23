extends RefCounted
## Behavioral regression tests, run alongside the original survival/world suite.
func run(game: Node3D) -> void:
	var controls: Control = game.controls
	controls.set_enabled(true)
	controls.mobile = true
	var touch := InputEventScreenTouch.new()
	touch.index = 4
	touch.pressed = true
	touch.position = controls.stick_center + Vector2(85, 0)
	controls._input(touch)
	assert(controls.direction().x > 0.7)
	touch.index = 8
	touch.position = controls.jump_rect.get_center()
	controls._input(touch)
	assert(controls.direction().x > 0.7)
	touch.pressed = false
	controls._input(touch)
	assert(controls.direction().x > 0.7)
	controls.set_enabled(false)
	assert(controls.movement == Vector2.ZERO and controls.stick_id == -1)
	controls.mobile = controls.detect_mobile()
	game.normal = game.camp_normal
	var saved: Vector3 = game.normal
	game._apply_location(true)
	assert(game.inside and game._at_camp() and game.base_room.visible)
	var room: Node3D = game.base_room
	var next: Vector3 = room.move_player(room.position, Vector3(100, 0, 100))
	assert(next.x <= 4.5 and next.z <= 3.35)
	var blocked: Vector3 = room.move_player(room.position + Vector3(-2.4, 0, -1.6), Vector3(-1, 0, 0))
	assert(is_equal_approx(blocked.x, -2.4))
	assert(room.station_at(room.position + Vector3(-2.3, 0, -1.6)) == "energy")
	assert(room.station_at(room.position + Vector3(2.3, 0, -1.6)) == "signal")
	var puzzle: Control = game.minigames
	puzzle.open_power(false)
	var previous_food: float = game.food
	var previous_solar: float = game.solar_clock
	game._process(10)
	assert(game.food == previous_food and game.solar_clock == previous_solar)
	puzzle._select_source(0)
	puzzle._select_target(1)
	assert(puzzle.connected.count(true) == 0)
	for i in range(3):
		puzzle._select_source(i)
		puzzle._select_target(i)
	assert(game.energy_ready and game.energy_charge == 100)
	puzzle.open_signal(false, 6, false)
	assert(puzzle.completed and not game.signal_transmitted)
	puzzle.open_signal(true, 5, false)
	assert(puzzle.completed and not game.signal_transmitted)
	puzzle.open_signal(true, 6, false)
	puzzle.frequency.value = 64
	puzzle.alignment.value = 38
	puzzle._process(1.5)
	assert(not game.signal_transmitted and puzzle.hold_time == 1.5)
	puzzle.frequency.value = 0
	puzzle._process(0.1)
	assert(puzzle.hold_time == 0)
	puzzle.frequency.value = 64
	puzzle.frozen = true
	puzzle._process(10)
	assert(puzzle.hold_time == 0 and not game.signal_transmitted)
	puzzle.frozen = false
	puzzle._process(3.1)
	assert(game.signal_transmitted and game.ship == null)
	puzzle.close()
	game._apply_location(false)
	assert(not game.inside and game.normal.is_equal_approx(saved))
	# A location transition cannot resurrect previously collected world objects.
	game.items[0].taken = true
	game.items[0].node.hide()
	game._apply_location(true)
	game._apply_location(false)
	assert(not game.items[0].node.visible)
	game.items[0].taken = false
	game.items[0].node.show()
	game._update_energy(1000)
	assert(not game.energy_ready)
	game.signal_transmitted = false
	game.energy_charge = 0
	load("res://tests/mission_balance.gd").new().run(game)
	game._update_controls()
	assert(ResourceLoader.exists("res://assets/cinematics/intro.ogv"))
	print("PASS: multi-touch, input cancellation, interior bounds/furniture, station proximity, cables, signal locks/stability/pause, power depletion, return position and video asset")
