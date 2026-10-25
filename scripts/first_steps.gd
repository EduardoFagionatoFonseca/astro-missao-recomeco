extends Control
## First-use guidance follows a world direction, including the far side of Mars.
var done: Dictionary = {}
var started: Dictionary = {}
var marker := Vector2.ZERO
var heading := Vector2.UP
var caption := ""
var clock := 0.0
var game: Node3D
var hint: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hint = Label.new()
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 26)
	hint.add_theme_color_override("font_color", Color("b7d8bf"))
	hint.add_theme_color_override("font_outline_color", Color("101c30"))
	hint.add_theme_constant_override("outline_size", 5)
	add_child(hint)
	hide()

func _process(_delta: float) -> void:
	if game != null and (not game.playing or game.dead or game.won or not game.controls.enabled): hide()

func update_guide(state: Node3D, delta: float) -> void:
	game = state
	clock += delta
	hide()
	if not game.controls.enabled: return
	var triggers := {
		"oxygen": game.oxygen <= game.MAX_RESERVE * 0.25,
		"food": game.food <= game.MAX_RESERVE * 0.25,
		"energy": game.energy_charge <= 30,
		"signal": not game.communications_online or (game.found[1] >= 6 and not game.signal_transmitted),
		"solar": game.solar_phase == "active" or (game.solar_phase == "warning" and game.communications_online and game.solar_clock >= game.SOLAR_WARNING - 5),
		"parts": game.found[1] < 2
	}
	for key in triggers:
		if triggers[key] and not done.has(key): started[key] = true
	if game.oxygen > game.MAX_RESERVE * 0.75 and started.has("oxygen"): done["oxygen"] = true
	if game.food > game.MAX_RESERVE * 0.75 and started.has("food"): done["food"] = true
	if game.energy_charge > 90 and started.has("energy"): done["energy"] = true
	if game.signal_transmitted and game.communications_online and started.has("signal"): done["signal"] = true
	if (game.inside or game.solar_phase == "calm") and started.has("solar"): done["solar"] = true
	if game.found[1] >= 2: done["parts"] = true
	for key in ["solar", "oxygen", "energy", "food", "signal", "parts"]:
		if done.has(key) or not started.has(key): continue
		if key == "solar" and game.inside: continue
		var target: Vector3 = game.camp_normal * game.R
		caption = {"solar": "Entre no abrigo", "oxygen": "Volte ao abrigo", "energy": "Repare a energia", "food": "Vá à estufa", "signal": "Restaure o sinal", "parts": "Reúna peças"}[key]
		if key == "food":
			if game.inside: target = game.base_room.position + game.base_room.STATIONS.exit
			else: target = game.garden_normal * game.R
		elif key == "parts":
			if game.inside: continue
			var closest := -2.0
			for item in game.items:
				if item.kind == 1 and not item.taken and item.normal.dot(game.normal) > closest:
					closest = item.normal.dot(game.normal)
					target = item.node.global_position
		elif game.inside:
			if key == "energy" or (key == "oxygen" and not game.energy_ready): target = game.base_room.position + game.base_room.STATIONS.energy
			elif key == "signal": target = game.base_room.position + game.base_room.STATIONS.signal
			else: continue
		_point(target)
		show()
		break
	queue_redraw()

func _point(target: Vector3) -> void:
	var camera: Camera3D = game.camera
	var origin: Vector3 = game.avatar.global_position
	var vector := target - origin
	if not game.inside:
		vector = target.normalized().slide(game.normal).normalized() * 4
		if vector.length_squared() < 0.01: vector = game.north * 2
	var start := camera.unproject_position(origin)
	var end := camera.unproject_position(origin + vector)
	heading = (end - start).normalized()
	if heading.length_squared() < 0.01: heading = Vector2.DOWN
	# Keep guidance clear of the character, bottom notices and mobile buttons.
	marker = Vector2(size.x * 0.5, size.y * 0.56) + heading * 38
	hint.text = tr(caption)
	hint.size = Vector2(600, 42)
	hint.position = Vector2((size.x - 600) / 2, size.y * 0.66)

func _draw() -> void:
	if not visible: return
	var at := marker + heading * sin(clock * 4) * 5
	var side := heading.orthogonal()
	draw_circle(at, 28, Color("101c30dd"))
	draw_line(at - heading * 17, at + heading * 15, Color("b7d8bf"), 5, true)
	draw_polyline(PackedVector2Array([at - heading * 2 + side * 13, at + heading * 15, at - heading * 2 - side * 13]), Color("f2ba90"), 5, true)
