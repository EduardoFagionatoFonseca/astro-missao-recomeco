extends Node3D
## A gentle exploration game on a complete spherical world.

const R := 12.0
const TOTAL := 18
const OXYGEN_RATE := 3.4
const FOOD_RATE := 1.8
const SOLAR_WARNING := 10.0
const SOLAR_DURATION := 10.0
const SOLAR_INTERVAL := 45.0
const WAVE_HALF_WIDTH := 0.055
const SHELTER_RADIUS := 3.1
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
var solar_remaining := SOLAR_INTERVAL
var oxygen_label: Label
var food_label: Label
var solar_wave: MeshInstance3D
var wave_hit := false
var alert_audio: AudioStreamPlayer
var wave_audio: AudioStreamPlayer
var oxygen_low := false
var food_low := false
var oxygen_critical := false
var food_critical := false
var oxygen_bar: ProgressBar
var food_bar: ProgressBar
var vignette: ColorRect
var vignette_material: ShaderMaterial
var death_panel: PanelContainer
var dead := false
var oxygen_empty_time := 0.0
var food_empty_time := 0.0
var solar_axis := Vector3(-0.7, -0.5, -0.5).normalized()
var distant_light: MeshInstance3D
var distant_halo: MeshInstance3D

func _ready() -> void:
	rng.seed = 60318
	auto_check = "--smoke-test" in OS.get_cmdline_user_args()
	capture = "--capture" in OS.get_cmdline_user_args() or "--capture-intro" in OS.get_cmdline_user_args() or "--capture-wave" in OS.get_cmdline_user_args() or "--capture-critical" in OS.get_cmdline_user_args()
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
	if "--capture-wave" in OS.get_cmdline_user_args():
		solar_phase = "active"
		solar_clock = 6.0
	if "--capture-critical" in OS.get_cmdline_user_args():
		food = 2.5
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
	distant_light = _ball(self, 0.65, PEACH, solar_axis * 42.0)
	var source_material := _material(Color("ffdbad"), 1.0)
	source_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	distant_light.material_override = source_material
	distant_light.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var halo_mesh := QuadMesh.new()
	halo_mesh.size = Vector2(7, 7)
	distant_halo = _mesh(self, halo_mesh, PEACH, solar_axis * 42.0)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1, 0.5)
	var halo_material := StandardMaterial3D.new()
	halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	halo_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	halo_material.albedo_texture = texture
	halo_material.albedo_color = Color(1.0, 0.6, 0.27, 0.2)
	distant_halo.material_override = halo_material
	distant_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

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
	solar_wave = MeshInstance3D.new()
	add_child(solar_wave)
	var wave_material := _material(Color("efac76"), 0.6)
	wave_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	wave_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	solar_wave.material_override = wave_material
	solar_wave.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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
			_box(visual, Vector3(0.35, 0.48, 0.25), Color("e2ad68"), Vector3(0, 0.24, 0))
			_box(visual, Vector3(0.18, 0.08, 0.17), Color("576d76"), Vector3(0.06, 0.51, 0))
			_box(visual, Vector3(0.37, 0.08, 0.27), Color("f1d7aa"), Vector3(0, 0.25, 0))
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
		var capture_path := "res://docs/solar-preview.png" if "--capture-wave" in OS.get_cmdline_user_args() else "res://docs/preview.png"
		if "--capture-critical" in OS.get_cmdline_user_args(): capture_path = "res://docs/critical-preview.png"
		get_viewport().get_texture().get_image().save_png(capture_path)
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
	if not playing or paused or won or dead:
		return
	elapsed += delta
	_update_movement(delta)
	_update_survival(delta)
	if dead: return
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

func _collect(index: int) -> void:
	if index < 0 or items[index].taken: return
	var item := items[index]
	item.taken = true
	item.node.visible = false
	found[item.kind] += 1
	collected += 1
	_chime(660.0 + item.kind * 110.0)
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

func _update_ship(delta: float) -> void:
	if ship == null: return
	ship_timer += delta
	var height := pow(maxf(0, 1.0 - ship_timer / 9.0), 2.0) * 20.0
	ship.position = ship_normal * (R + height)
	if ship_timer >= 9.0 and not ship_landed:
		ship_landed = true
		_chime(880)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo(): return
	if event is InputEventKey:
		if event.physical_keycode == KEY_ESCAPE and playing and not won and not dead:
			_toggle_pause()
		if not playing or paused or won or dead: return
		if event.physical_keycode == KEY_SPACE and hop == 0:
			hop_velocity = 2.4
		if event.physical_keycode == KEY_E:
			_interact()

func _interact() -> void:
	if dead: return
	if _at_garden() and food < 99.0:
		food = 100.0
		food_empty_time = 0.0
		_chime(550)
		return
	if ship_landed and normal.dot(ship_normal) > 0.975:
		_finish()
		return
	var near := _nearest()
	if near >= 0 and normal.dot(items[near].normal) > cos(1.25 / R):
		_collect(near)

func _at_camp() -> bool:
	return normal.dot(camp_normal) > cos(SHELTER_RADIUS / R)

func _at_garden() -> bool:
	return normal.dot(garden_normal) > cos(2.4 / R)

func _update_survival(delta: float) -> void:
	if _at_camp():
		oxygen = minf(100.0, oxygen + delta * 25.0)
	else:
		oxygen = maxf(0.0, oxygen - delta * OXYGEN_RATE)
	food = maxf(0.0, food - delta * FOOD_RATE)
	exposure = maxf(0.0, exposure - delta * 5.0)
	var previous_clock := solar_clock
	solar_clock += delta
	if solar_phase == "calm":
		solar_remaining = SOLAR_INTERVAL - solar_clock
		if solar_remaining <= 0.0:
			solar_phase = "warning"
			solar_clock = 0.0
			solar_remaining = SOLAR_WARNING
			_play_warning()
	elif solar_phase == "warning":
		solar_remaining = SOLAR_WARNING - solar_clock
		if floori(previous_clock) != floori(solar_clock): _play_warning()
		if solar_remaining <= 0.0:
			solar_phase = "active"
			solar_clock = 0.0
			solar_remaining = SOLAR_DURATION
			wave_hit = false
			if not muted: wave_audio.play()
	else:
		solar_remaining = SOLAR_DURATION - solar_clock
		if not wave_hit and _wave_contact(normal, previous_clock, solar_clock):
			wave_hit = true
			oxygen = maxf(0, oxygen - 35.0)
			food = maxf(0, food - 12.0)
			exposure = 60.0
			_chime(150)
		if solar_remaining <= 0.0:
			solar_phase = "calm"
			solar_clock = 0.0
			solar_remaining = SOLAR_INTERVAL
			wave_audio.stop()
	solar_wave.visible = solar_phase == "active"
	if solar_wave.visible: _draw_wave()
	_update_last_chance(delta)
	_update_distant_light()
	_resource_warnings()

func _wave_contact(at: Vector3, from_time: float, to_time: float) -> bool:
	# Sweep across the actual front, so a fast frame cannot skip a collision.
	if at.dot(camp_normal) >= cos(SHELTER_RADIUS / R): return false
	var angle := acos(clampf(at.dot(solar_axis), -1, 1))
	var before := clampf(from_time / SOLAR_DURATION, 0, 1) * PI
	var after := clampf(to_time / SOLAR_DURATION, 0, 1) * PI
	return angle >= before - WAVE_HALF_WIDTH and angle <= after + WAVE_HALF_WIDTH

func _wave_point(angle: float, azimuth: float) -> Vector3:
	var axis := solar_axis
	var tangent := Vector3.RIGHT.slide(axis).normalized()
	var bitangent := axis.cross(tangent).normalized()
	return (axis * cos(angle) + (tangent * cos(azimuth) + bitangent * sin(azimuth)) * sin(angle)).normalized()

func _draw_wave() -> void:
	# The wave originates from the same world direction as the distant light.
	var angle := clampf(solar_clock / SOLAR_DURATION, 0, 1) * PI
	var vertices := PackedVector3Array()
	for i in range(128):
		var a := TAU * i / 128.0
		var b := TAU * (i + 1) / 128.0
		var points := [
			_wave_point(maxf(0.001, angle - WAVE_HALF_WIDTH), a),
			_wave_point(minf(PI - 0.001, angle + WAVE_HALF_WIDTH), a),
			_wave_point(minf(PI - 0.001, angle + WAVE_HALF_WIDTH), b),
			_wave_point(maxf(0.001, angle - WAVE_HALF_WIDTH), b)]
		var protected := false
		for point: Vector3 in points:
			if point.dot(camp_normal) >= cos((SHELTER_RADIUS + 0.15) / R): protected = true
		if protected: continue
		for index in [0, 1, 2, 0, 2, 3]: vertices.append(points[index] * (R + 0.09))
	if vertices.is_empty():
		solar_wave.mesh = null
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	solar_wave.mesh = mesh

func _resource_warnings() -> void:
	if oxygen <= 35.0 and not oxygen_low:
		oxygen_low = true
		_play_warning()
	if food <= 30.0 and not food_low:
		food_low = true
		_play_warning()
	if oxygen <= 15.0 and not oxygen_critical:
		oxygen_critical = true
		_play_warning()
	if food <= 15.0 and not food_critical:
		food_critical = true
		_play_warning()
	if oxygen > 40.0:
		oxygen_low = false
		oxygen_critical = false
	if food > 40.0:
		food_low = false
		food_critical = false

func _update_last_chance(delta: float) -> void:
	oxygen_empty_time = oxygen_empty_time + delta if oxygen <= 0 else 0.0
	food_empty_time = food_empty_time + delta if food <= 0 else 0.0
	if oxygen_empty_time >= 2.0 or food_empty_time >= 2.0:
		_die()

func _die() -> void:
	if dead: return
	dead = true
	wave_audio.stop()
	alert_audio.stop()
	music.volume_db = -22 if not muted else -80
	death_panel.show()
	_update_hud(0)

func _update_distant_light() -> void:
	var activity := 0.2
	if solar_phase == "warning":
		activity = 0.6 + 0.4 * (0.5 + 0.5 * sin(elapsed * 5.0))
	elif solar_phase == "active":
		activity = 1.0
	distant_light.scale = Vector3.ONE * (0.5 + activity * 1.3)
	distant_halo.scale = Vector3.ONE * (0.7 + activity * 1.2)
	distant_halo.material_override.albedo_color = Color(1.0, 0.6, 0.27, activity * 0.65)

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
	vignette = ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var edge_shader := Shader.new()
	edge_shader.code = "shader_type canvas_item; uniform float intensity = 0.0; void fragment(){ vec2 p=(UV-vec2(0.5))*vec2(1.1,1.0); float edge=smoothstep(0.18,0.66,length(p)); COLOR=vec4(0.005,0.008,0.015,edge*intensity); }"
	vignette_material = ShaderMaterial.new()
	vignette_material.shader = edge_shader
	vignette.material = vignette_material
	hud.add_child(vignette)
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
	oxygen_label = _label("O₂", 14, MINT)
	food_label = _label("ALIMENTO", 14, PEACH)
	vitals.add_child(oxygen_label)
	oxygen_bar = _vital_bar(MINT)
	vitals.add_child(oxygen_bar)
	vitals.add_child(food_label)
	food_bar = _vital_bar(PEACH)
	vitals.add_child(food_bar)
	var objectives := HBoxContainer.new()
	objectives.position = Vector2(917, 30)
	objectives.add_theme_constant_override("separation", 12)
	root.add_child(objectives)
	var names := ["REGOLITO", "ANTENA", "COMBUSTÍVEL"]
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
	var pause_button := _button("Ⅱ", _toggle_pause)
	pause_button.position = Vector2(1335, 817)
	pause_button.custom_minimum_size.x = 54
	root.add_child(pause_button)
	var mute_button := _button("♪", _mute)
	mute_button.position = Vector2(1268, 817)
	mute_button.custom_minimum_size.x = 54
	root.add_child(mute_button)
	intro = _modal("Uma pequena aventura, com cuidado.", "Reúna 6 pedras, 6 peças da antena e 6 galões de combustível para chamar o resgate.\n\nO oxigênio acaba durante a exploração: volte à base para recarregar. A estufa, do outro lado do planeta, oferece refeições frescas — pressione E para comer.\n\nUma luz no horizonte anuncia a onda solar. Escute o alerta e procure abrigo.\n\nWASD: mover · Espaço: saltitar · E: interagir\nSe uma reserva zerar, você tem mais dois segundos para se salvar.")
	intro.get_child(0).add_child(_button("Vamos explorar  →", _start))
	pause_panel = _modal("Uma pausa entre as estrelas.", "WASD ou setas: caminhar\nEspaço: saltitar · E: recolher, comer ou embarcar\nOxigênio: cerca de 29 s fora da base · comida: cerca de 56 s\nShift: andar mais rápido · Esc: pausar\n\nA base repõe oxigênio e bloqueia a radiação. Esgotar uma reserva por dois segundos encerra a partida.\nA estufa fornece alimentos, mas não é um abrigo solar.")
	pause_panel.get_child(0).add_child(_button("Continuar explorando  →", _toggle_pause))
	pause_panel.hide()
	ending = _modal("Toda pequena descoberta conta.", "Você reuniu materiais para o resgate e cuidou das reservas do traje.\n\nOxigênio exige planejamento de ida e volta. Alimentos sustentam a exploração. Um abrigo adequado protege da radiação.\n\nSua viagem de volta para casa começa agora.")
	ending.get_child(0).add_child(_button("Explorar outra vez  ↻", func(): get_tree().reload_current_scene()))
	ending.hide()
	death_panel = _modal("O silêncio tomou conta.", "A expedição terminou.\n\nCada saída precisa de reservas para voltar.\nRespire fundo e tente uma nova rota.")
	death_panel.get_child(0).add_child(_button("Recomeçar expedição  ↻", func(): get_tree().reload_current_scene()))
	death_panel.hide()

func _vital_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(265, 18)
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	var track := _style(Color("223543"), Color("49606a"), 8)
	var fill := _style(color, Color.TRANSPARENT, 7)
	for style in [track, fill]:
		style.content_margin_left = 0
		style.content_margin_right = 0
		style.content_margin_top = 0
		style.content_margin_bottom = 0
	bar.add_theme_stylebox_override("background", track)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _start() -> void:
	intro.hide()
	playing = true

func _toggle_pause() -> void:
	if not playing or won or dead: return
	paused = not paused
	pause_panel.visible = paused
	music.stream_paused = paused
	wave_audio.stream_paused = paused
	alert_audio.stream_paused = paused

func _update_hud(_delta: float) -> void:
	for i in range(3):
		counts[i].text = str(found[i]) + "/6"
		counts[i].add_theme_color_override("font_color", MINT if found[i] == 6 else MUTED)
	oxygen_label.text = "O₂                                  " + str(ceili(oxygen)) + "%"
	food_label.text = "ALIMENTO                       " + str(ceili(food)) + "%"
	oxygen_bar.value = oxygen
	food_bar.value = food
	for pair in [[oxygen_bar, oxygen, MINT], [food_bar, food, PEACH]]:
		var style: StyleBoxFlat = pair[0].get_theme_stylebox("fill")
		style.bg_color = Color("e67d68") if pair[1] < 20 else pair[2]
		pair[0].modulate.a = 0.7 + 0.3 * sin(elapsed * 6) if pair[1] < 15 else 1.0
	var depleted := 1.0 - clampf(minf(oxygen, food) / 30.0, 0, 1)
	var grace := clampf(maxf(oxygen_empty_time, food_empty_time) / 2.0, 0, 1)
	var intensity := depleted * 0.65 + grace * 0.3
	if dead: intensity = 0.98
	vignette_material.set_shader_parameter("intensity", intensity)

func _finish() -> void:
	won = true
	wave_audio.stop()
	alert_audio.stop()
	avatar.visible = false
	ending.show()
	_chime(1046.5)

func _build_audio() -> void:
	music = AudioStreamPlayer.new()
	add_child(music)
	var rate := 22050
	var duration := 32
	var data := PackedByteArray()
	data.resize(rate * duration * 2)
	# Original slow organ-like pads, deep drone and airy overtones.
	var chords := [[45, 52, 57, 60], [41, 48, 53, 57], [48, 55, 60, 64], [43, 50, 55, 62]]
	for i in range(rate * duration):
		var t := float(i) / rate
		var chord := int(t / 8.0) % 4
		var blend := smoothstep(0.0, 2.5, fmod(t, 8.0))
		var pad := 0.0
		for voice in range(4):
			for layer in range(2):
				var note: int = chords[chord if layer == 1 else posmod(chord - 1, 4)][voice]
				var f := 440.0 * pow(2.0, (note - 69.0) / 12.0)
				var weight := blend if layer == 1 else 1.0 - blend
				var detune := 1.0 + sin(t * 0.17 + voice) * 0.0008
				var organ := sin(TAU * f * detune * t) * 0.68 + sin(TAU * f * 2 * t) * 0.2 + sin(TAU * f * 3 * t) * 0.07
				pad += organ * weight * 0.07
		var envelope := pow(sin(PI * t / duration), 0.5)
		var drone := sin(TAU * 55.0 * t) * 0.08
		var air := sin(TAU * 659.25 * t + sin(t * 0.2)) * (0.025 + 0.015 * sin(t * 0.4))
		var wave := (pad + drone + air) * envelope
		data.encode_s16(i * 2, int(wave * 17000))
	music.stream = _audio_stream(data, true)
	music.volume_db = -10
	music.play()
	sound = AudioStreamPlayer.new()
	add_child(sound)
	alert_audio = AudioStreamPlayer.new()
	add_child(alert_audio)
	var alarm := PackedByteArray()
	alarm.resize(11025 * 2)
	for i in range(11025):
		var t := float(i) / rate
		var f := 740.0 if t < 0.22 else 990.0
		var envelope := minf(1.0, t * 80) * minf(1.0, (0.5 - t) * 40)
		alarm.encode_s16(i * 2, int(sin(TAU * f * t) * envelope * 4200))
	alert_audio.stream = _audio_stream(alarm)
	wave_audio = AudioStreamPlayer.new()
	add_child(wave_audio)
	var rumble := PackedByteArray()
	rumble.resize(rate * 2 * 2)
	var filtered := 0.0
	for i in range(rate * 2):
		var t := float(i) / rate
		var noise := sin(i * 127.1) * sin(i * 311.7)
		filtered = filtered * 0.94 + noise * 0.06
		var envelope := pow(sin(PI * t / 2.0), 2.0)
		var wave := (filtered * 0.6 + sin(TAU * 65 * t) * 0.15 + sin(TAU * 97 * t) * 0.1) * envelope
		rumble.encode_s16(i * 2, int(wave * 12000))
	wave_audio.stream = _audio_stream(rumble, true)
	wave_audio.volume_db = -5

func _audio_stream(data: PackedByteArray, loop := false) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = data.size() / 2
	return stream

func _play_warning() -> void:
	if alert_audio != null and not muted: alert_audio.play()

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
	wave_audio.volume_db = -80 if muted else -5
	alert_audio.volume_db = -80 if muted else 0
	sound.volume_db = -80 if muted else 0
	if not muted and solar_phase == "active" and not wave_audio.playing: wave_audio.play()

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
	assert(is_equal_approx(oxygen, 66.0) and is_equal_approx(food, 82.0))
	normal = camp_normal
	_update_survival(2)
	assert(oxygen == 100.0)
	normal = garden_normal
	food = 20
	_interact()
	assert(food == 100.0)
	assert(distant_light.position.normalized().dot(solar_axis) > 0.999)
	solar_clock = SOLAR_INTERVAL - 0.1
	solar_phase = "calm"
	_update_survival(0.2)
	assert(solar_phase == "warning" and solar_remaining == 10.0)
	solar_clock = 9.9
	_update_survival(0.2)
	assert(solar_phase == "active" and wave_audio.playing)
	var contact_normal := _wave_point(PI / 2, 0)
	assert(_wave_contact(contact_normal, 4.9, 5.1))
	assert(not _wave_contact(contact_normal, 0, 1))
	assert(not _wave_contact(camp_normal, 0, 10))
	normal = contact_normal
	oxygen = 100
	food = 100
	wave_hit = false
	solar_clock = 1.0
	_update_survival(0.1)
	assert(not wave_hit and oxygen > 99.0)
	solar_clock = 4.95
	_update_survival(0.1)
	assert(wave_hit and oxygen < 65.0)
	var after_hit := oxygen
	_update_survival(0.1)
	assert(oxygen > after_hit - 1.0)
	normal = camp_normal
	oxygen = 100
	wave_hit = false
	solar_clock = acos(clampf(camp_normal.dot(solar_axis), -1, 1)) / PI * SOLAR_DURATION
	_update_survival(0.01)
	assert(not wave_hit and oxygen == 100.0)
	if solar_wave.mesh != null:
		var mesh_vertices: PackedVector3Array = solar_wave.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for vertex in mesh_vertices:
			assert(vertex.normalized().dot(camp_normal) < cos(SHELTER_RADIUS / R))
	solar_clock = 9.9
	_update_survival(0.2)
	assert(solar_phase == "calm" and not wave_audio.playing)
	# Zero oxygen is survivable for two seconds, and recharging cancels the timer.
	normal = Vector3.DOWN
	oxygen = 0
	food = 100
	_update_last_chance(1.8)
	assert(not dead)
	_update_hud(0)
	assert(float(vignette_material.get_shader_parameter("intensity")) > 0.8)
	normal = camp_normal
	_update_survival(0.05)
	assert(oxygen > 0 and oxygen_empty_time == 0.0 and not dead)
	# Food can be restored by interacting during the grace period.
	normal = garden_normal
	food = 0
	_update_last_chance(1.7)
	assert(not dead)
	_interact()
	assert(food == 100.0 and food_empty_time == 0.0)
	# Missing either deadline loses the game, without teleportation or refunds.
	normal = Vector3.DOWN
	avatar.position = normal * R
	oxygen = 0
	var before_position := avatar.position
	var before_items := collected
	_update_last_chance(2.01)
	assert(dead and death_panel.visible)
	assert(avatar.position == before_position and collected == before_items)
	dead = false
	death_panel.hide()
	oxygen = 100
	oxygen_empty_time = 0
	food = 0
	_update_last_chance(2.01)
	assert(dead)
	dead = false
	death_panel.hide()
	food = 100
	oxygen = 100
	oxygen_empty_time = 0
	food_empty_time = 0
	exposure = 0
	solar_clock = 0
	solar_phase = "calm"
	solar_remaining = SOLAR_INTERVAL
	wave_audio.stop()
	alert_audio.stop()
	_resource_warnings()
	print("PASS: bars, vignette, two-second grace, oxygen/food recovery, death without teleport, light/wave alignment, swept contact and shelter exclusion")
