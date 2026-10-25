extends Control
## One objective and a projected route starting at the astronaut.
var done: Dictionary = {}
var started: Dictionary = {}
var caption := ""
var objective_id := ""
var clock := 0.0
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

func update_guide(state: Node3D, delta: float) -> void:
	game = state
	clock += delta
	hide()
	objective_id = ""
	route.clear()
	if not game.controls.enabled: return
	var continuous := GameOptions.difficulty == 0
	var oxy: float = game.oxygen / game.MAX_RESERVE * 100
	var food: float = game.food / game.MAX_RESERVE * 100
	var onboarding: bool = game.found[1] >= 2
	var needs := {
		"oxygen": oxy <= 25 or (onboarding and oxy < 80 and not done.has("oxygen")),
		"food": food <= 25 or (onboarding and food < 80 and not done.has("food")),
		"energy": game.energy_charge <= 30,
		"signal": not game.communications_online or (game.found[1] >= 6 and not game.signal_transmitted),
		"solar": game.solar_phase == "active" or (game.solar_phase == "warning" and game.communications_online and game.solar_clock >= game.SOLAR_WARNING - 5),
		"parts": game.found[1] < (6 if continuous else 2)
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
		if game.found[1] >= 6 and game.communications_online and game.signal_transmitted and game.collected < game.TOTAL: objective_id = "supplies"
		elif game.collected >= game.TOTAL: objective_id = "rescue"
	if objective_id.is_empty(): return
	caption = {"solar": "Entre no abrigo", "oxygen": "Recupere oxigênio", "energy": "Repare a energia", "food": "Encontre comida", "signal": "Restaure o sinal", "parts": "Reúna peças", "supplies": "Reúna suprimentos", "rescue": "Aguarde no abrigo"}[objective_id]
	destination = game.camp_normal * game.R
	if objective_id == "food":
		destination = game.base_room.position + game.base_room.STATIONS.exit if game.inside else game.garden_normal * game.R
	elif objective_id in ["parts", "supplies"]:
		if game.inside: destination = game.base_room.position + game.base_room.STATIONS.exit
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
		if objective_id == "energy" or (objective_id == "oxygen" and not game.energy_ready): destination = game.base_room.position + game.base_room.STATIONS.energy
		elif objective_id == "signal": destination = game.base_room.position + game.base_room.STATIONS.signal
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
	if game.inside:
		for i in range(25): route.append(camera.unproject_position(origin.lerp(destination, i / 24.0) + Vector3.UP * 0.12))
	else:
		var target := destination.normalized()
		if game.normal.angle_to(target) < 0.01: return
		# Follow the ground and stop at the horizon, never through the planet.
		for i in range(65):
			var direction: Vector3 = game.normal.slerp(target, i / 64.0).normalized()
			var world: Vector3 = direction * (game.R + game.terrain.height_at(direction) + 0.2)
			if i == 0: world = origin + game.normal * 0.12
			if i > 1 and direction.dot((camera.global_position - world).normalized()) < 0.12: break
			if camera.is_position_behind(world): break
			route.append(camera.unproject_position(world))

func _draw() -> void:
	if route.size() < 2: return
	draw_polyline(route, Color("101c3099"), 10, true)
	draw_polyline(route, Color("b7d8bfc9"), 4, true)
	var distance := fmod(clock * 32, 56.0)
	for i in range(1, route.size()):
		var previous := distance
		distance += route[i].distance_to(route[i - 1])
		if floori(distance / 56) > floori(previous / 56) and i < route.size() - 4:
			_draw_head(route[i], (route[i] - route[i - 1]).normalized(), 8)
	_draw_head(route[-1], (route[-1] - route[-2]).normalized(), 17)

func _draw_head(at: Vector2, direction: Vector2, length: float) -> void:
	var side := direction.orthogonal()
	var head := PackedVector2Array([at - direction * length + side * length * 0.65, at, at - direction * length - side * length * 0.65])
	draw_polyline(head, Color("101c30"), 9, true)
	draw_polyline(head, Color("f2ba90"), 4, true)
