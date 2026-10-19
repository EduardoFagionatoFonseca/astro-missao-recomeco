extends Node3D
## A gentle exploration game on a complete spherical world.

const R := 12.0
const TOTAL := 18
const CREAM := Color("f0e9d9")
const MUTED := Color("a3b7c4")
const PEACH := Color("f2ba90")
const MINT := Color("b7d8bf")
var rng := RandomNumberGenerator.new()
var normal := Vector3.UP
var north := Vector3.FORWARD
var avatar: Node3D
var astronaut: Node3D
var camera: Camera3D
var items: Array[Dictionary] = []
var found := [0, 0, 0]
var collected := 0
var playing := false
var paused := false
var won := false
var elapsed := 0.0
var hop := 0.0
var hop_velocity := 0.0
var walk := 0.0
var ship: Node3D
var ship_normal := Vector3.UP
var ship_timer := -1.0
var ship_landed := false
var hud: CanvasLayer
var intro: PanelContainer
var ending: PanelContainer
var pause_panel: PanelContainer
var counts: Array[Label] = []
var tip_label: Label
var compass_label: Label
var toast_label: Label
var toast_time := 0.0
var music: AudioStreamPlayer
var sound: AudioStreamPlayer
var muted := false
var auto_check := false
var capture := false
var check_time := 0.0
var pad := Vector2.ZERO
var oxygen := 100.0
var food := 100.0
var exposure := 0.0
var camp_normal := Vector3(0.07, 1, 0.12).normalized()
var garden_normal := Vector3(0.9, -0.15, -0.5).normalized()
var solar_clock := 0.0
var solar_phase := "calm"
var solar_remaining := 70.0
var oxygen_label: Label
var food_label: Label
var solar_label: Label
var navigation := 0
var rescues := 0
var solar_wave: MeshInstance3D

func _ready() -> void:
	rng.seed = 60318
	auto_check = "--smoke-test" in OS.get_cmdline_user_args()
	capture = "--capture" in OS.get_cmdline_user_args() or "--capture-intro" in OS.get_cmdline_user_args()
	_build_environment()
	_build_planet()
	_build_camp()
	_build_items()
	avatar = Node3D.new()
	add_child(avatar)
	astronaut = _asset("astronautA", avatar, 1.8)
	# Kenney's astronaut faces +Z; the movement frame faces -Z.
	astronaut.rotation.y = PI
	avatar.position = normal * R
	_align(avatar, normal, north)
	camera = Camera3D.new()
	add_child(camera)
	camera.fov = 44.0
	camera.near = 0.1
	camera.far = 350.0
	camera.position = normal * 32.0 - north * 24.0
	camera.look_at(normal * 2.0, north)
	_build_ui()
	_build_audio()
	if auto_check or (capture and not "--capture-intro" in OS.get_cmdline_user_args()):
		_start()
	if auto_check:
		_assert_world()
		_assert_survival()

func _material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.88
	if glow > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = glow
	return mat

func _mesh(parent: Node3D, mesh: Mesh, color: Color, pos := Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _material(color)
	parent.add_child(node)
	node.position = pos
	return node

func _ball(parent: Node3D, radius: float, color: Color, pos := Vector3.ZERO) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	return _mesh(parent, mesh, color, pos)

func _box(parent: Node3D, size: Vector3, color: Color, pos := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(parent, mesh, color, pos)

func _cylinder(parent: Node3D, radius: float, height: float, color: Color, pos := Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	return _mesh(parent, mesh, color, pos)

func _align(node: Node3D, up: Vector3, forward: Vector3) -> void:
	var f := forward.slide(up).normalized()
	if f.length() < 0.1:
		f = Vector3.RIGHT.slide(up).normalized()
	var right := f.cross(up).normalized()
	node.basis = Basis(right, up, -f).orthonormalized()

func _surface(up: Vector3) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	root.position = up * R
	_align(root, up, Vector3.FORWARD)
	return root

func _asset(asset_name: String, parent: Node3D, size: float) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	var mesh: Mesh = load("res://assets/space/" + asset_name + ".obj")
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	root.add_child(instance)
	var bounds := mesh.get_aabb()
	var factor := size / maxf(bounds.size.y, 0.01)
	instance.scale = Vector3.ONE * factor
	instance.position.y = -bounds.position.y * factor
	return root

func _build_environment() -> void:
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("101c30")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("c1c4dc")
	settings.ambient_light_energy = 0.35
	settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.environment = settings
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("ffe4bd")
	sun.light_energy = 0.7
	sun.rotation_degrees = Vector3(-42, -30, -15)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 85
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color("8fb9dc")
	fill.light_energy = 0.25
	fill.rotation_degrees = Vector3(35, 135, 0)
	add_child(fill)
	var star_mat := _material(Color("b0c8df"), 0.5)
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(190):
		var direction := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		var star := _ball(self, rng.randf_range(0.035, 0.12), CREAM, direction * 95.0)
		star.material_override = star_mat
	_ball(self, 3.0, Color("829fb1"), Vector3(-38, 27, -58))

func _build_planet() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = R
	mesh.height = R * 2
	mesh.radial_segments = 72
	mesh.rings = 36
	var terrain := _mesh(self, mesh, Color("bd7f61"))
	terrain.name = "LittleMars"
	# All landmarks sit directly on the sphere; there is no flat hidden terrain.
	for i in range(65):
		var n := _fibonacci(i, 65)
		if n.dot(Vector3.UP) > 0.975:
			continue
		var root := _surface(n)
		root.rotate_object_local(Vector3.UP, rng.randf() * TAU)
		var stone := _asset("rock_largeA", root, rng.randf_range(0.12, 0.65))
		stone.scale *= Vector3(1.2, 0.7, 1.1)
	for i in range(8):
		var n := _fibonacci(i, 8)
		if n.dot(Vector3.UP) > 0.93:
			continue
		var root := _surface(n)
		var crater := _asset("craterLarge", root, 0.13)
		crater.scale *= 0.85
	for i in range(16):
		var angle := float(i) / 16 * TAU
		var n := Vector3(sin(angle) * 0.22, 1.0, cos(angle) * 0.22).normalized()
		var root := _surface(n)
		_cylinder(root, 0.045, 0.23, Color("eac49e"), Vector3(0, 0.12, 0))
	var wave_mesh := TorusMesh.new()
	wave_mesh.inner_radius = R + 0.05
	wave_mesh.outer_radius = R + 0.18
	wave_mesh.rings = 72
	wave_mesh.ring_segments = 8
	solar_wave = _mesh(self, wave_mesh, PEACH)
	solar_wave.material_override = _material(Color("efac76"), 0.5)
	solar_wave.hide()

func _fibonacci(i: int, count: int) -> Vector3:
	var y := 1.0 - (float(i) + 0.5) / float(count) * 2.0
	var a := float(i) * 2.39996323
	var r := sqrt(1.0 - y * y)
	return Vector3(cos(a) * r, y, sin(a) * r)

func _build_camp() -> void:
	var camp := _surface(camp_normal)
	var dome := _ball(camp, 0.95, Color("d5d8c6"), Vector3(-0.8, 0.33, 0))
	dome.scale.y = 0.75
	_box(camp, Vector3(0.6, 0.65, 0.35), Color("617e86"), Vector3(-0.8, 0.32, -0.8))
	_box(camp, Vector3(0.36, 0.32, 0.05), MINT, Vector3(-0.8, 0.36, -1.0))
	_asset("satelliteDish_detailed", camp, 1.2).position = Vector3(1.2, 0, 0)
	_asset("machine_generator", camp, 0.6).position = Vector3(-1.6, 0, 1.0)
	_asset("rover", camp, 0.5).position = Vector3(1.4, 0, 1.6)
	for i in range(2):
		var panel := _box(camp, Vector3(0.7, 0.07, 0.9), Color("648eab"), Vector3(-2.2 - i * 0.8, 0.32, 0))
		panel.rotation.z = -0.2
		_cylinder(camp, 0.04, 0.3, CREAM, Vector3(-2.2 - i * 0.8, 0.15, 0))
	var garden := _surface(garden_normal)
	_cylinder(garden, 1.5, 0.18, Color("738a7c"), Vector3(0, 0.09, 0))
	var glass := _ball(garden, 1.4, Color("a9d0bc"), Vector3(0, 0.55, 0))
	glass.scale.y = 0.7
	var glass_mat := _material(Color(0.61, 0.82, 0.73, 0.3))
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.material_override = glass_mat
	for x in [-0.65, 0.0, 0.65]:
		_box(garden, Vector3(0.4, 0.2, 1.2), Color("766d55"), Vector3(x, 0.3, 0))
		for z in [-0.4, 0.0, 0.4]:
			_ball(garden, 0.18, Color("87b17b"), Vector3(x, 0.65, z))
	_box(garden, Vector3(0.65, 0.8, 0.22), Color("5d8b7c"), Vector3(0, 0.4, -1.25))
	var sign := Label3D.new()
	sign.text = "ESTUFA"
	sign.font_size = 42
	sign.pixel_size = 0.008
	sign.position = Vector3(0, 1.9, 0)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	garden.add_child(sign)

func _build_items() -> void:
	for i in range(TOTAL):
		var n := _fibonacci(i, TOTAL)
		# First pickup is visible by the camp; the rest invite a complete orbit.
		if i == 0:
			n = Vector3(-0.18, 1, -0.2).normalized()
		var root := _surface(n)
		var kind := i % 3
		var visual := Node3D.new()
		root.add_child(visual)
		if kind == 0:
			_asset("rock_largeA", visual, 0.45)
		elif kind == 1:
			_box(visual, Vector3(0.34, 0.42, 0.28), MINT, Vector3(0, 0.23, 0))
			_box(visual, Vector3(0.36, 0.1, 0.3), Color("607c77"), Vector3(0, 0.28, 0))
		else:
			_cylinder(visual, 0.17, 0.46, Color("d9bc84"), Vector3(0, 0.24, 0))
			_cylinder(visual, 0.12, 0.08, Color("7e9da4"), Vector3(0, 0.5, 0))
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.38
		ring_mesh.outer_radius = 0.42
		ring_mesh.rings = 24
		ring_mesh.ring_segments = 8
		var ring := _mesh(root, ring_mesh, [PEACH, MINT, Color("dfcc97")][kind], Vector3(0, 0.08, 0))
		var marker := _ball(root, 0.065, [PEACH, MINT, Color("dfcc97")][kind], Vector3(0, 1.1, 0))
		marker.material_override = _material([PEACH, MINT, Color("dfcc97")][kind], 0.5)
		items.append({"node": root, "normal": n, "visual": visual, "marker": marker, "ring": ring, "kind": kind, "taken": false})

func _process(delta: float) -> void:
	check_time += delta
	if capture and check_time > 2.0:
		get_viewport().get_texture().get_image().save_png("res://docs/preview.png")
		get_tree().quit()
	if auto_check and check_time > 0.4:
		for i in range(TOTAL):
			normal = items[i].normal
			_interact()
		assert(collected == TOTAL)
		assert(ship != null)
		ship_timer = 12.0
		_update_ship(0.1)
		assert(ship_landed)
		_finish()
		assert(won)
		print("PASS: spherical placement, collection, rescue landing, boarding and completion")
		get_tree().quit()
	if not playing or paused or won:
		return
	elapsed += delta
	_update_movement(delta)
	_update_survival(delta)
	_update_items(delta)
	_update_ship(delta)
	_update_hud(delta)

func _update_movement(delta: float) -> void:
	var input := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): input.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): input.x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): input.y += 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): input.y -= 1
	input += pad
	input = input.limit_length()
	var old := normal
	var forward := camera.global_basis.y.slide(normal).normalized()
	if forward.length() < 0.1: forward = north
	var right := camera.global_basis.x.slide(normal).normalized()
	var direction := (right * input.x + forward * input.y)
	if direction.length() > 0.05:
		var speed := 3.0
		if Input.is_physical_key_pressed(KEY_SHIFT): speed = 4.2
		normal = (normal + direction * speed / R * delta).normalized()
		var transport := Quaternion(old, normal)
		north = (transport * north).slide(normal).normalized()
		_align(avatar, normal, direction)
		walk += delta * 8.0
	else:
		_align(avatar, normal, -avatar.basis.z)
	if hop > 0 or hop_velocity > 0:
		hop_velocity -= 4.5 * delta
		hop = maxf(0, hop + hop_velocity * delta)
		if hop == 0: hop_velocity = 0
	avatar.position = normal * (R + hop)
	astronaut.position.y = absf(sin(walk)) * input.length() * 0.055
	astronaut.rotation.z = sin(walk) * input.length() * 0.045
	var desired := normal * 32.0 - north * 24.0
	camera.position = camera.position.lerp(desired, 1.0 - exp(-3.5 * delta))
	camera.look_at(normal * 2.0, north)

func _nearest() -> int:
	var index := -1
	var best := -2.0
	for i in range(items.size()):
		if items[i].taken: continue
		var dot: float = normal.dot(items[i].normal)
		if dot > best:
			best = dot
			index = i
	return index

func _update_items(_delta: float) -> void:
	for i in range(items.size()):
		var item := items[i]
		if item.taken: continue
		item.visual.position.y = 0.08 + sin(elapsed * 2.0 + i) * 0.055
		item.marker.position.y = 1.0 + sin(elapsed * 2 + i) * 0.1
		item.visual.rotation.y += _delta * 0.25
	var near := _nearest()
	if near >= 0:
		var distance := acos(clampf(normal.dot(items[near].normal), -1, 1)) * R
		if distance < 1.25:
			tip_label.text = "[ E ] Recolher " + ["pedra de regolito", "peça da antena", "cápsula de suprimentos"][items[near].kind]
		else:
			tip_label.text = "WASD / setas: caminhar   ·   Espaço: saltitar   ·   E: recolher"
	if ship_landed:
		tip_label.text = "O resgate chegou! Aproxime-se da nave e pressione E para embarcar."
	elif _at_garden():
		tip_label.text = "[ E ] Comer na estufa · reabastecer alimentos"
	elif _at_camp():
		tip_label.text = "Abrigo seguro · oxigênio recarregando"
	elif near < 0 or normal.dot(items[near].normal) <= cos(1.25 / R):
		tip_label.text = ""

func _collect(index: int) -> void:
	if index < 0 or items[index].taken: return
	var item := items[index]
	item.taken = true
	item.node.visible = false
	found[item.kind] += 1
	collected += 1
	_chime(660.0 + item.kind * 110.0)
	var messages := ["Regolito guardado. Mais proteção para nosso abrigo.", "Uma peça a mais. O sinal da antena está ficando mais forte.", "Suprimentos encontrados. Podemos esperar o resgate com tranquilidade."]
	_toast(messages[item.kind])
	if collected == TOTAL:
		_begin_rescue()

func _begin_rescue() -> void:
	ship_normal = (normal + north * 0.14).normalized()
	ship = _surface(ship_normal)
	ship_timer = 0.0
	var body := _cylinder(ship, 0.7, 1.8, Color("e6dfcc"), Vector3(0, 1.3, 0))
	body.name = "RescueCapsule"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.7
	cone.height = 0.9
	_mesh(ship, cone, PEACH, Vector3(0, 2.65, 0))
	_ball(ship, 0.31, Color("789fb2"), Vector3(0, 1.75, -0.63)).scale = Vector3(1, 1, 0.4)
	for i in range(3):
		var a := i * TAU / 3
		var leg := _box(ship, Vector3(0.18, 0.8, 0.3), Color("a1b1ac"), Vector3(sin(a) * 0.75, 0.4, cos(a) * 0.75))
		leg.rotation.z = -sin(a) * 0.4
	_toast("Sinal recebido! A nave de resgate está a caminho. Olhe para o céu.")

func _update_ship(delta: float) -> void:
	if ship == null: return
	ship_timer += delta
	var height := pow(maxf(0, 1.0 - ship_timer / 9.0), 2.0) * 20.0
	ship.position = ship_normal * (R + height)
	if ship_timer >= 9.0 and not ship_landed:
		ship_landed = true
		_chime(880)
		_toast("Pouso concluído. Sua carona para casa chegou.")

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo(): return
	if event is InputEventKey:
		if event.physical_keycode == KEY_ESCAPE and playing and not won:
			_toggle_pause()
		if not playing or paused or won: return
		if event.physical_keycode == KEY_SPACE and hop == 0:
			hop_velocity = 2.4
		if event.physical_keycode == KEY_E:
			_interact()
		if event.physical_keycode == KEY_TAB:
			navigation = (navigation + 1) % 3

func _interact() -> void:
	if _at_garden() and food < 99.0:
		food = 100.0
		_chime(550)
		_toast("Uma refeição fresca. Alimentos reabastecidos.")
		return
	if ship_landed and normal.dot(ship_normal) > 0.975:
		_finish()
		return
	var near := _nearest()
	if near >= 0 and normal.dot(items[near].normal) > cos(1.25 / R):
		_collect(near)

func _at_camp() -> bool:
	return normal.dot(camp_normal) > cos(2.7 / R)

func _at_garden() -> bool:
	return normal.dot(garden_normal) > cos(2.4 / R)

func _update_survival(delta: float) -> void:
	if _at_camp():
		oxygen = minf(100.0, oxygen + delta * 22.0)
		exposure = maxf(0.0, exposure - delta * 20.0)
	else:
		oxygen = maxf(0.0, oxygen - delta * 1.5)
	food = maxf(0.0, food - delta * 0.55)
	solar_clock += delta
	if solar_phase == "calm":
		solar_remaining = 70.0 - solar_clock
		if solar_remaining <= 0.0:
			solar_phase = "warning"
			solar_clock = 0.0
			solar_remaining = 25.0
			_toast("Alerta solar! Você tem 25 segundos para voltar ao abrigo da base.")
	elif solar_phase == "warning":
		solar_remaining = 25.0 - solar_clock
		if solar_remaining <= 0.0:
			solar_phase = "active"
			solar_clock = 0.0
			solar_remaining = 20.0
			_toast("Onda de radiação em curso. Permaneça na base até o sinal verde.")
	else:
		solar_remaining = 20.0 - solar_clock
		if not _at_camp(): exposure = minf(100.0, exposure + delta * 9.0)
		if solar_remaining <= 0.0:
			solar_phase = "calm"
			solar_clock = 0.0
			solar_remaining = 70.0
			exposure = 0.0
			_toast("A onda passou. É seguro explorar novamente.")
	solar_wave.visible = solar_phase == "active"
	if solar_wave.visible:
		var latitude := cos(clampf(solar_clock / 20.0, 0, 1) * PI)
		solar_wave.position.y = latitude * R
		var ring_scale := maxf(0.03, sqrt(maxf(0, 1.0 - latitude * latitude)))
		solar_wave.scale = Vector3(ring_scale, 1, ring_scale)
	if oxygen <= 0.0:
		_emergency_return("Oxigênio esgotado. O traje levou você de volta ao abrigo.")
	elif food <= 0.0:
		_emergency_return("Você ficou sem energia. Após descansar, visite a estufa para comer.")
	elif exposure >= 100.0:
		_emergency_return("Exposição solar alta. Retorno de emergência ao abrigo.")

func _emergency_return(reason: String) -> void:
	rescues += 1
	normal = camp_normal
	north = Vector3.FORWARD.slide(normal).normalized()
	hop = 0.0
	hop_velocity = 0.0
	oxygen = 100.0
	food = maxf(food, 35.0)
	exposure = 0.0
	avatar.position = normal * R
	_align(avatar, normal, north)
	camera.position = normal * 32.0 - north * 24.0
	camera.look_at(normal * 2.0, north)
	_toast(reason + " Seus itens foram preservados.")

func _style(color: Color, border := Color.TRANSPARENT, radius := 18) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 18
	box.content_margin_bottom = 18
	return box

func _label(text: String, size: int, color := CREAM) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("253740"))
	button.add_theme_stylebox_override("normal", _style(PEACH, Color.TRANSPARENT, 12))
	button.add_theme_stylebox_override("hover", _style(Color("f8d2aa"), Color.TRANSPARENT, 12))
	button.add_theme_stylebox_override("pressed", _style(Color("cfa07d"), Color.TRANSPARENT, 12))
	button.pressed.connect(callback)
	return button

func _modal(title: String, subtitle: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(410, 160)
	panel.size = Vector2(620, 430)
	panel.add_theme_stylebox_override("panel", _style(Color("15283af5"), Color("526371"), 24))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	panel.add_child(v)
	v.add_child(_label("ASTRO / UM PEQUENO RECOMEÇO", 13, PEACH))
	var heading := _label(title, 37)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.custom_minimum_size.x = 560
	v.add_child(heading)
	var description := _label(subtitle, 18, MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 560
	v.add_child(description)
	hud.add_child(panel)
	return panel

func _build_ui() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(root)
	var logo := _label("✦ ASTRO", 25)
	logo.position = Vector2(42, 28)
	root.add_child(logo)
	var vitals := VBoxContainer.new()
	vitals.position = Vector2(42, 76)
	vitals.add_theme_constant_override("separation", 8)
	root.add_child(vitals)
	oxygen_label = _label("O₂  100%", 21, MINT)
	food_label = _label("Alimento  100%", 18, PEACH)
	vitals.add_child(oxygen_label)
	vitals.add_child(food_label)
	var objectives := HBoxContainer.new()
	objectives.position = Vector2(917, 30)
	objectives.add_theme_constant_override("separation", 12)
	root.add_child(objectives)
	var names := ["REGOLITO", "ANTENA", "SUPRIMENTOS"]
	for i in range(3):
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(150, 100)
		card.add_theme_stylebox_override("panel", _style(Color("15283ad9"), Color("425665"), 15))
		objectives.add_child(card)
		var column := VBoxContainer.new()
		card.add_child(column)
		var count_label := _label("0/6", 34, [PEACH, MINT, CREAM][i])
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		counts.append(count_label)
		column.add_child(count_label)
		var name_label := _label(names[i], 11, MUTED)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(name_label)
	solar_label = _label("", 19, PEACH)
	solar_label.position = Vector2(330, 45)
	solar_label.size = Vector2(570, 70)
	solar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	solar_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(solar_label)
	compass_label = _label("", 16, PEACH)
	compass_label.position = Vector2(42, 804)
	root.add_child(compass_label)
	tip_label = _label("", 16, CREAM)
	tip_label.position = Vector2(42, 840)
	root.add_child(tip_label)
	toast_label = _label("", 17, MINT)
	toast_label.position = Vector2(340, 138)
	toast_label.size = Vector2(740, 75)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(toast_label)
	var pause_button := _button("Ⅱ", _toggle_pause)
	pause_button.position = Vector2(1335, 817)
	pause_button.custom_minimum_size.x = 54
	root.add_child(pause_button)
	var mute_button := _button("♪", _mute)
	mute_button.position = Vector2(1268, 817)
	mute_button.custom_minimum_size.x = 54
	root.add_child(mute_button)
	intro = _modal("Uma pequena aventura, com cuidado.", "Reúna 6 pedras, 6 peças da antena e 6 suprimentos para chamar o resgate.\n\nO oxigênio acaba durante a exploração: volte à base para recarregar. A estufa, do outro lado do planeta, oferece refeições frescas — pressione E para comer.\n\nQuando chegar um alerta solar, volte à base em até 25 segundos e espere a onda passar.\n\nWASD: mover · Espaço: saltitar · E: interagir\nTab: alternar direção entre itens, base e estufa.")
	intro.get_child(0).add_child(_button("Vamos explorar  →", _start))
	pause_panel = _modal("Uma pausa entre as estrelas.", "WASD ou setas: caminhar\nEspaço: saltitar · E: recolher, comer ou embarcar\nTab: apontar para itens, base ou estufa\nShift: andar mais rápido · Esc: pausar\n\nA base repõe oxigênio e protege da radiação.\nA estufa fornece alimentos, mas não é um abrigo solar.")
	pause_panel.get_child(0).add_child(_button("Continuar explorando  →", _toggle_pause))
	pause_panel.hide()
	ending = _modal("Toda pequena descoberta conta.", "Você reuniu materiais para o resgate e cuidou das reservas do traje.\n\nOxigênio exige planejamento de ida e volta. Alimentos sustentam a exploração. Um abrigo adequado protege da radiação.\n\nSua viagem de volta para casa começa agora.")
	ending.get_child(0).add_child(_button("Explorar outra vez  ↻", func(): get_tree().reload_current_scene()))
	ending.hide()

func _start() -> void:
	intro.hide()
	playing = true

func _toggle_pause() -> void:
	if not playing or won: return
	paused = not paused
	pause_panel.visible = paused

func _update_hud(delta: float) -> void:
	for i in range(3):
		counts[i].text = str(found[i]) + "/6"
		counts[i].add_theme_color_override("font_color", MINT if found[i] == 6 else MUTED)
	oxygen_label.text = "O₂  " + str(ceili(oxygen)) + "%"
	food_label.text = "Alimento  " + str(ceili(food)) + "%"
	oxygen_label.add_theme_color_override("font_color", PEACH if oxygen < 35 else MINT)
	food_label.add_theme_color_override("font_color", PEACH if food < 30 else CREAM)
	solar_label.text = ""
	if solar_phase == "warning":
		solar_label.text = "☼ ALERTA SOLAR · " + str(ceili(solar_remaining)) + " s para buscar abrigo"
	elif solar_phase == "active":
		solar_label.text = ("☼ PROTEGIDO NA BASE" if _at_camp() else "☼ RADIAÇÃO · VOLTE À BASE") + " · " + str(ceili(solar_remaining)) + " s"
	toast_time = maxf(0, toast_time - delta)
	toast_label.modulate.a = minf(1.0, toast_time)
	var near := _nearest()
	var target := Vector3.ZERO
	var target_name := "Próxima descoberta"
	if near >= 0: target = items[near].normal
	if navigation == 1 or oxygen < 35 or solar_phase != "calm":
		target = camp_normal
		target_name = "Base · O₂ e abrigo"
	elif navigation == 2 or food < 30:
		target = garden_normal
		target_name = "Estufa · alimento"
	if ship != null and solar_phase == "calm" and oxygen >= 35:
		target = ship_normal
		target_name = "Nave de resgate"
	if target != Vector3.ZERO:
		var direction: Vector3 = target.slide(normal).normalized()
		var right := camera.global_basis.x.slide(normal).normalized()
		var up := camera.global_basis.y.slide(normal).normalized()
		var angle := rad_to_deg(atan2(direction.dot(right), direction.dot(up)))
		var arrows := ["↑", "↗", "→", "↘", "↓", "↙", "←", "↖"]
		var arrow_index := posmod(roundi(angle / 45.0), 8)
		var distance := acos(clampf(normal.dot(target), -1, 1)) * R
		compass_label.text = arrows[arrow_index] + "  " + target_name + " · " + str(roundi(distance)) + " m   [Tab: destino]"

func _toast(message: String) -> void:
	toast_label.text = message
	toast_time = 5.0

func _finish() -> void:
	won = true
	avatar.visible = false
	ending.show()
	_chime(1046.5)

func _build_audio() -> void:
	music = AudioStreamPlayer.new()
	add_child(music)
	var rate := 22050
	var duration := 16
	var data := PackedByteArray()
	data.resize(rate * duration * 2)
	var notes := [130.81, 164.81, 196.0, 261.63]
	for i in range(rate * duration):
		var t := float(i) / rate
		var wave := 0.0
		for n in notes:
			wave += sin(TAU * n * t) * (0.6 + 0.4 * sin(TAU * t / 8.0))
		var envelope := pow(sin(PI * t / duration), 2.0)
		data.encode_s16(i * 2, int(wave * envelope * 340))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = rate * duration
	music.stream = stream
	music.volume_db = -10
	music.play()
	sound = AudioStreamPlayer.new()
	add_child(sound)

func _chime(frequency: float) -> void:
	if sound == null or muted: return
	var data := PackedByteArray()
	var length := 6615
	data.resize(length * 2)
	for i in range(length):
		var t := float(i) / 22050.0
		var wave := sin(TAU * frequency * t) + sin(TAU * frequency * 1.5 * t) * 0.25
		data.encode_s16(i * 2, int(wave * exp(-t * 15) * 4500))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	sound.stream = stream
	sound.play()

func _mute() -> void:
	muted = not muted
	music.volume_db = -80 if muted else -10

func _assert_world() -> void:
	assert(items.size() == TOTAL)
	var kinds := [0, 0, 0]
	for item in items:
		assert(absf(item.node.position.length() - R) < 0.01)
		assert(item.node.basis.y.dot(item.normal) > 0.99)
		kinds[item.kind] += 1
	assert(kinds == [6, 6, 6])
	assert(absf(avatar.position.length() - R) < 0.01)
	for input_direction in [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]:
		normal = Vector3.UP
		north = Vector3.FORWARD
		camera.position = normal * 32.0 - north * 24.0
		camera.look_at(normal * 2.0, north)
		var expected: Vector3 = (camera.basis.x.slide(normal).normalized() * input_direction.x + camera.basis.y.slide(normal).normalized() * input_direction.y).normalized()
		pad = input_direction
		_update_movement(0.02)
		assert((normal - Vector3.UP).normalized().dot(expected) > 0.99)
		# Kenney +Z must face the same way as the actual displacement.
		assert((avatar.basis * astronaut.basis * Vector3.BACK).normalized().dot(expected) > 0.99)
	var crossed_hemisphere := false
	pad = Vector2(0, 1)
	for i in range(1800):
		_update_movement(0.02)
		assert(absf(avatar.position.length() - R) < 0.01)
		if normal.y < -0.5:
			crossed_hemisphere = true
	assert(crossed_hemisphere)
	pad = Vector2.ZERO
	normal = Vector3.UP
	north = Vector3.FORWARD
	avatar.position = normal * R
	_align(avatar, normal, north)
	camera.position = normal * 32.0 - north * 24.0
	camera.look_at(normal * 2.0, north)

func _assert_survival() -> void:
	normal = Vector3.DOWN
	oxygen = 100
	food = 100
	_update_survival(10)
	assert(oxygen == 85.0)
	assert(food < 100.0)
	normal = camp_normal
	_update_survival(1)
	assert(oxygen == 100.0)
	normal = garden_normal
	food = 20
	_interact()
	assert(food == 100.0)
	solar_clock = 69.9
	solar_phase = "calm"
	_update_survival(0.2)
	assert(solar_phase == "warning")
	solar_clock = 24.9
	_update_survival(0.2)
	assert(solar_phase == "active")
	exposure = 0
	normal = Vector3.DOWN
	_update_survival(1)
	assert(exposure > 0)
	normal = camp_normal
	_update_survival(1)
	assert(exposure == 0.0)
	solar_clock = 19.9
	_update_survival(0.2)
	assert(solar_phase == "calm")
	normal = Vector3.DOWN
	oxygen = 0.01
	var before := collected
	_update_survival(0.1)
	assert(_at_camp() and oxygen == 100.0 and collected == before)
	food = 0.01
	_update_survival(0.1)
	assert(food >= 35.0)
	assert(not _at_garden())
	food = 100
	oxygen = 100
	exposure = 0
	solar_clock = 0
	solar_phase = "calm"
	solar_remaining = 70
	toast_time = 0
	print("PASS: camera-relative movement and facing in four directions; oxygen, meals, solar warning, exposure, shelter and emergency return")
