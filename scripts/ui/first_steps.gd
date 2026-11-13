extends Control
## One objective and a projected route starting at the astronaut.
var done: Dictionary = {}
var started: Dictionary = {}
var caption := ""
var objective_id := ""
var game: Node3D
var hint: Label
var route := PackedVector2Array()
var destination := Vector3.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hint = Label.new()
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 28)
	hint.add_theme_color_override("font_color", Color("f2e2c8"))
	hint.add_theme_color_override("font_outline_color", Color("101c30"))
	hint.add_theme_constant_override("outline_size", 6)
	add_child(hint)
	hide()

func _process(_delta: float) -> void:
	if game != null and (not game.playing or game.dead or game.won or not game.controls.enabled): hide()

func update_guide(state: Node3D, _delta: float) -> void:
	game = state
	hide()
	objective_id = ""
	route.clear()
	if not game.controls.enabled: return
	var continuous := GameOptions.difficulty == 0
	var oxy: float = game.oxygen / game.MAX_RESERVE * 100
	var food: float = game.food / game.MAX_RESERVE * 100
	var reserve_threshold := 30.0 if continuous else 25.0
	var needs := {
		"oxygen": oxy <= reserve_threshold and not (game._at_camp() and game.energy_ready),
		"food": food <= reserve_threshold,
		"energy": game.energy_charge <= 30,
		"signal": not game.communications_online or (game.found[1] >= game.GOALS[1] and not game.signal_transmitted),
		"solar": game.solar_phase == "active" or (game.solar_phase == "warning" and game.communications_online and game.solar_clock >= game.SOLAR_WARNING - 5),
		"parts": game.found[1] < (game.GOALS[1] if continuous else 2)
	}
	var resolved := {"oxygen": oxy >= 80, "food": food >= 80, "energy": game.energy_charge > 90, "signal": game.signal_transmitted and game.communications_online, "solar": game.inside or game.solar_phase == "calm", "parts": not needs.parts}
	for key in needs:
		if started.has(key) and resolved[key]:
			done[key] = true
			started.erase(key)
		if needs[key] and not resolved[key] and (continuous or not done.has(key)): started[key] = true
	var priorities := {"solar": -100.0 if game.solar_phase == "active" else -20.0, "oxygen": oxy, "food": food, "energy": float(game.energy_charge) + 10, "signal": 110.0, "parts": 150.0}
	if game.solar_phase == "active": priorities.solar = -200 + (game.EXPOSURE_LIMIT - game.exposure) * 10
	if oxy <= 0: priorities.oxygen = -200 + (game.VITAL_GRACE - game.oxygen_empty_time) * 10
	if food <= 0: priorities.food = -200 + (game.VITAL_GRACE - game.food_empty_time) * 10
	if not game.energy_ready: priorities.energy = minf(priorities.energy, float(priorities.oxygen) - 1)
	var best := INF
	for key in priorities:
		if not started.has(key) or (done.has(key) and not continuous) or resolved[key]: continue
		if float(priorities[key]) < best:
			best = priorities[key]
			objective_id = key
	if objective_id.is_empty() and continuous:
		if game.found[1] >= game.GOALS[1] and game.communications_online and game.signal_transmitted and game.collected < game.TOTAL: objective_id = "supplies"
		elif game.collected >= game.TOTAL: objective_id = "rescue"
	if objective_id.is_empty(): return
	caption = {"solar": "Entre no abrigo", "oxygen": "Recupere oxigênio", "energy": "Repare a energia", "food": "Encontre comida", "signal": "Restaure o sinal", "parts": "Reúna peças", "supplies": "Reúna fotos e combustível", "rescue": "Aguarde a nave"}[objective_id]
	destination = game.camp_normal * game.R
	if objective_id == "food":
		destination = game.base_room.position + game.base_room.station_positions["exit"] if game.inside else game.garden_normal * game.R
	elif objective_id in ["parts", "supplies"]:
		if game.inside: destination = game.base_room.position + game.base_room.station_positions["exit"]
		else:
			var closest := -2.0
			for item in game.items:
				if not item.taken and game._item_available(item) and (objective_id == "supplies" or item.kind == 1) and item.normal.dot(game.normal) > closest:
					closest = item.normal.dot(game.normal)
					destination = item.node.global_position
	elif objective_id == "rescue" and game.ship_landed:
		caption = "Embarque na nave"
		destination = game.ship_normal * game.R
	elif game.inside:
		if objective_id == "energy" or (objective_id == "oxygen" and not game.energy_ready): destination = game.base_room.position + game.base_room.station_positions["energy"]
		elif objective_id == "signal": destination = game.base_room.position + game.base_room.station_positions["signal"]
		else: destination = game.avatar.global_position
	_build_route()
	hint.text = tr(caption)
	hint.size = Vector2(minf(660, size.x - 80), 48)
	hint.position = Vector2((size.x - hint.size.x) / 2, size.y - 440)
	show()
	queue_redraw()

func _build_route() -> void:
	var camera: Camera3D = game.camera
	var origin: Vector3 = game.avatar.global_position
	if origin.distance_to(destination) < 0.7: return
	var avatar_up: Vector3 = Vector3.UP if game.inside else game.normal
	var feet := camera.unproject_position(origin)
	var helmet := camera.unproject_position(origin + avatar_up * 1.85)
	var player_bounds := Rect2(feet, Vector2.ZERO).expand(helmet).grow(maxf(12.0, feet.distance_to(helmet) * 0.42))
	if game.inside:
		for i in range(1, 33):
			var point := origin.lerp(destination, i / 32.0) + Vector3.UP * 0.1
			if camera.is_position_behind(point): break
			if not _append_route_point(camera.unproject_position(point), player_bounds): break
	else:
		var target := destination.normalized()
		if game.normal.angle_to(target) < 0.01: return
		# Follow the ground and stop at the horizon, never through the planet.
		var angle: float = game.normal.angle_to(target)
		var tangent: Vector3 = target.slide(game.normal).normalized()
		if tangent.is_zero_approx(): tangent = game.north
		var steps := maxi(2, ceili(angle * game.R / 0.40))
		for i in range(1, steps + 1):
			var along := angle * float(i) / steps
			var direction: Vector3 = game.normal * cos(along) + tangent * sin(along)
			var world: Vector3 = direction * (game.R + game.terrain.height_at(direction) + 0.2)
			if i > 1 and direction.dot((camera.global_position - world).normalized()) < 0.12: break
			if camera.is_position_behind(world): break
			if not _append_route_point(camera.unproject_position(world), player_bounds): break

func _append_route_point(point: Vector2, player_bounds: Rect2) -> bool:
	if not game.first_person or game.inside:
		if player_bounds.has_point(point): return route.is_empty()
		if not route.is_empty():
			var start := route[-1]
			var corner := player_bounds.position
			var end := player_bounds.end
			var edges := [corner, Vector2(end.x, corner.y), end, Vector2(corner.x, end.y)]
			for i in range(edges.size()):
				if Geometry2D.segment_intersects_segment(start, point, edges[i], edges[(i + 1) % edges.size()]) != null: return false
	route.append(point)
	return true

func _draw() -> void:
	if route.size() < 2: return
	draw_polyline(route, Color("101c30cc"), 9, true)
	draw_polyline(route, Color("b7d8bfe0"), 3, true)
	var end := route[-1]
	for i in range(route.size() - 2, -1, -1):
		if end.distance_to(route[i]) >= 24.0:
			_draw_head(end, (end - route[i]).normalized(), 14)
			break

func _draw_head(at: Vector2, direction: Vector2, length: float) -> void:
	var side := direction.orthogonal()
	var head := PackedVector2Array([at - direction * length + side * length * 0.65, at, at - direction * length - side * length * 0.65])
	draw_polyline(head, Color("101c30"), 9, true)
	draw_polyline(head, Color("f2ba90"), 4, true)
