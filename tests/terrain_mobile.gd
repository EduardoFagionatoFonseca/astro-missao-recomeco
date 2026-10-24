extends RefCounted

func run(game: Node3D) -> void:
	var controls: Control = game.controls
	controls.mobile = true
	controls.set_enabled(true)
	game.inside = false
	var p: Dictionary = game.terrain.platforms[0]
	var up: Vector3 = p.normal
	var tangent := Vector3.RIGHT.slide(up).normalized()
	game.normal = (up + tangent * tan((p.radius + 0.24) / game.R)).normalized()
	game.altitude = game.terrain.height_at(game.normal)
	game.hop = 0
	game.hop_velocity = 0
	game.north = -tangent.slide(game.normal).normalized()
	game.camera.position = game.normal * 39 - game.north * 29
	game.camera.look_at(game.normal * 2, game.north)
	game.pad = Vector2(0, 1)
	for i in range(24): game._update_movement(0.02)
	assert(game.terrain.height_at(game.normal) < 0.1) # Cannot walk through a ledge.
	assert(not game._can_reach(game.items[0]))
	game.pad = Vector2.ZERO
	var touch := InputEventScreenTouch.new()
	touch.index = 7
	touch.pressed = true
	touch.position = controls.stick_center + Vector2(0, -100)
	controls._input(touch)
	touch.index = 9
	touch.position = controls.jump_rect.get_center()
	controls._input(touch)
	assert(game.hop_velocity > 0 and controls.direction().y > 0.9)
	var reached := false
	for i in range(50):
		game._update_movement(0.02)
		if acos(clampf(game.normal.dot(up), -1, 1)) * game.R < 0.22:
			reached = true
			break
	assert(reached)
	controls.reset()
	for i in range(65): game._update_movement(0.02)
	assert(is_equal_approx(game.altitude, p.height) and game.hop == 0)
	assert(game._can_reach(game.items[0]))
	game.pad = Vector2(0, 1)
	for i in range(70): game._update_movement(0.02)
	assert(absf(game.altitude - game.terrain.height_at(game.normal)) < 0.01 and game.hop == 0)
	game.pad = Vector2.ZERO
	var crater: Dictionary = game.terrain.craters[0]
	assert(game.terrain.height_at(crater.normal) < -0.25)
	# All eight touch directions normalize to the same speed; release/focus reset.
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(), Vector2(1, -1).normalized(), Vector2(-1, -1).normalized()]:
		game.normal = Vector3.UP
		game.altitude = 0
		game.hop = 0
		game.hop_velocity = 0
		game.camera.position = Vector3.UP * 39 + Vector3.BACK * 29
		game.camera.look_at(Vector3.UP * 2, Vector3.FORWARD)
		touch.index = 7
		touch.pressed = true
		touch.position = controls.stick_center + Vector2(direction.x, -direction.y) * 100
		controls._input(touch)
		assert(controls.direction().length() <= 1.001)
		game._update_movement(0.08)
		var distance: float = acos(clampf(game.normal.y, -1, 1)) * game.R
		assert(absf(distance - game.MOVE_SPEED * 0.08) < 0.01)
		controls._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		assert(controls.direction() == Vector2.ZERO and controls.stick_id == -1)
	controls.mobile = controls.detect_mobile()
	game.normal = Vector3.UP
	game.north = Vector3.FORWARD
	game.altitude = 0
	game.avatar.position = Vector3.UP * game.R
	print("PASS: ledge blocks walking, moving multi-touch jump reaches/lands on ledge, elevated pickup reach, edge fall, crater depth, 8 normalized mobile directions and focus cancellation")
