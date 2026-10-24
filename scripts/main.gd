extends Node3D
## A gentle exploration game on a complete spherical world.

const R := 12.0
const GOALS := [5, 6, 8]
const TOTAL := 19
const OXYGEN_RATE := 3.4
const FOOD_RATE := 1.8
const SOLAR_WARNING := 10.0
const SOLAR_DURATION := 12.0
const SOLAR_INTERVAL := 100.0
const ENERGY_INTERVAL := 63.75
const SIGNAL_INTERVAL := 85.0
const MOVE_SPEED := 3.8934
const PLANET_MUSIC_GAIN := 0.16
const BASE_MUSIC_GAIN := 0.24
const MAX_RESERVE := 105.0
const EXPOSURE_LIMIT := 3.0
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
var won := false
var elapsed := 0.0
var hop := 0.0
var altitude := 0.0
var terrain := preload("res://scripts/planet_terrain.gd").new()
var hop_velocity := 0.0
var walk := 0.0
var ship: Node3D
var ship_normal := Vector3.UP
var ship_timer := -1.0
var ship_landed := false
var hud: CanvasLayer
var intro: Control
var start_menu: Control
var material_icons: Array[Texture2D] = []
var ending: PanelContainer
var counts: Array[Label] = []
var music: AudioStreamPlayer
var base_music: AudioStreamPlayer
var audio_settings: Control
var music_mix := 0.0
var sound: AudioStreamPlayer
var muted := false
var auto_check := false
var capture := false
var check_time := 0.0
var pad := Vector2.ZERO
var oxygen := MAX_RESERVE
var food := MAX_RESERVE
var exposure := 0.0
var camp_normal := Vector3(0.07, 1, 0.12).normalized()
var garden_normal := Vector3(0.9, -0.15, -0.5).normalized()
var solar_clock := 0.0
var solar_phase := "calm"
var solar_remaining := SOLAR_INTERVAL
var oxygen_label: Label
var food_label: Label
var solar_fog: MeshInstance3D
var alert_audio: AudioStreamPlayer
var fog_audio: AudioStreamPlayer
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
var solar_axis := Vector3(-0.45, -0.65, -0.6).normalized()
var distant_light: MeshInstance3D
var distant_halo: MeshInstance3D
var moon: MeshInstance3D
var controls: Control
var base_room: Node3D
var minigames: Control
var outro_video: Control
var intro_video: Control
var inside := false
var transitioning := false
var energy_ready := true
var energy_charge := 100.0
var signal_transmitted := false
var communications_online := true
var energy_low_announced := false
var solar_cycle := 0
var energy_clock := 0.0
var signal_clock := 0.0
var energy_failures := 0
var signal_failures := 0
var health_alarm_cooldown := 0.0
var health_notice_serial := 0
var event_audio: Node
var feedback: Control
var world_environment: Environment
var exterior_nodes: Array[Node3D] = []
var exterior_normal := Vector3.UP
var exterior_north := Vector3.FORWARD
var prompt: Button
var prompt_target := ""
var prompt_tween: Tween
var transition_veil: ColorRect
var power_label: Label
var base_status: Label
var objectives_ui: HBoxContainer
var vitals_ui: VBoxContainer
var mute_ui: Button
var portrait_hint: PanelContainer
var hud_root: Control
var qa_clock := 0.0

func _ready() -> void:
	rng.seed = 60318
	auto_check = "--smoke-test" in OS.get_cmdline_user_args()
	capture = "--capture" in OS.get_cmdline_user_args() or "--capture-intro" in OS.get_cmdline_user_args() or "--capture-fog" in OS.get_cmdline_user_args() or "--capture-critical" in OS.get_cmdline_user_args() or "--capture-base" in OS.get_cmdline_user_args() or "--capture-power" in OS.get_cmdline_user_args() or "--capture-signal" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-"): capture = true
	_build_environment()
	_build_planet()
	_build_camp()
	_build_items()
	for child in get_children():
		if child is Node3D and not child is Light3D: exterior_nodes.append(child)
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
	camera.position = normal * 39.0 - north * 29.0
	camera.look_at(normal * 2.0, north)
	_build_ui()
	_build_audio()
	_build_expansion()
	if auto_check or (capture and not "--capture-intro" in OS.get_cmdline_user_args() and not "--capture-menu" in OS.get_cmdline_user_args() and not "--capture-settings" in OS.get_cmdline_user_args()):
		_start()
	if "--capture-fog" in OS.get_cmdline_user_args():
		solar_phase = "active"
		solar_clock = 6.0
		event_audio.play("fog")
	if "--capture-outro" in OS.get_cmdline_user_args(): _finish()
	if "--capture-briefing2" in OS.get_cmdline_user_args():
		_show_briefing()
		intro._next()
	if "--capture-critical" in OS.get_cmdline_user_args():
		food = 2.5
		oxygen = 10
		normal = Vector3.DOWN
		camera.position = normal * 39.0 - north * 29.0
		camera.look_at(normal * 2.0, north)
	if "--capture-warning" in OS.get_cmdline_user_args():
		solar_phase = "warning"
		solar_clock = 7
		feedback.shelter_tutorial()
	if "--capture-settings" in OS.get_cmdline_user_args(): audio_settings.open()
	if "--capture-briefing" in OS.get_cmdline_user_args(): _show_briefing()
	if "--capture-base" in OS.get_cmdline_user_args() or "--capture-power" in OS.get_cmdline_user_args() or "--capture-signal" in OS.get_cmdline_user_args() or "--capture-window" in OS.get_cmdline_user_args():
		_apply_location(true)
		if "--capture-window" in OS.get_cmdline_user_args():
			solar_phase = "active"
			solar_clock = 6.0
			event_audio.play("fog")
			feedback.queue.clear()
		avatar.position = base_room.position + Vector3(0, 0, 1.2)
		if "--capture-power" in OS.get_cmdline_user_args(): minigames.open_power(false)
		if "--capture-signal" in OS.get_cmdline_user_args(): minigames.open_signal(true, 6, false)
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
	root.position = up * (R + terrain.height_at(up))
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
	world_environment = settings
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
	moon = _ball(self, 2.25, Color("829fb1"), Vector3(-38, 27, -58))
	distant_light = _ball(self, 6.8, PEACH, solar_axis * 180.0)
	var source_material := _material(Color("ffdbad"), 1.0)
	source_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	distant_light.material_override = source_material
	distant_light.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var halo_mesh := QuadMesh.new()
	halo_mesh.size = Vector2(40, 40)
	distant_halo = _mesh(self, halo_mesh, PEACH, solar_axis * 180.0)
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
	var planet := _mesh(self, terrain.make_planet(), Color.WHITE)
	planet.name = "LittleMars"
	planet.material_override.vertex_color_use_as_albedo = true
	for platform in terrain.platforms:
		var ledge := _mesh(self, terrain.make_platform(platform), Color.WHITE)
		ledge.name = "JumpLedge"
		ledge.material_override.vertex_color_use_as_albedo = true
		ledge.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
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
	solar_fog = MeshInstance3D.new()
	add_child(solar_fog)
	var shell := SphereMesh.new()
	shell.radius = R + 1.5
	shell.height = (R + 1.5) * 2
	solar_fog.mesh = shell
	var fog_material := ShaderMaterial.new()
	fog_material.shader = preload("res://scripts/radiation_fog.gdshader")
	solar_fog.material_override = fog_material
	solar_fog.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	solar_fog.hide()

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
			n = terrain.platforms[0].normal
		var root := _surface(n)
		var kind := 1 if i < GOALS[1] else 0 if i < GOALS[1] + GOALS[0] else 2
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
	_sync_resource_visibility()

func _process(delta: float) -> void:
	check_time += delta
	if OS.has_feature("web") and "--web-test" in OS.get_cmdline_user_args():
		qa_clock += delta
		if qa_clock >= 0.1:
			qa_clock = 0
			_publish_web_test_state()
	_update_music(delta)
	if capture and check_time > 2.0:
		var capture_path := "res://docs/solar-preview.png" if "--capture-fog" in OS.get_cmdline_user_args() else "res://docs/preview.png"
		if "--capture-critical" in OS.get_cmdline_user_args(): capture_path = "res://docs/critical-preview.png"
		if "--capture-base" in OS.get_cmdline_user_args(): capture_path = "res://docs/base-preview.png"
		if "--capture-power" in OS.get_cmdline_user_args(): capture_path = "res://docs/power-preview.png"
		if "--capture-signal" in OS.get_cmdline_user_args(): capture_path = "res://docs/signal-preview.png"
		if "--capture-warning" in OS.get_cmdline_user_args(): capture_path = "res://docs/warning-preview.png"
		if "--capture-briefing" in OS.get_cmdline_user_args(): capture_path = "res://docs/briefing-preview.png"
		if "--capture-window" in OS.get_cmdline_user_args(): capture_path = "res://docs/window-preview.png"
		if "--capture-outro" in OS.get_cmdline_user_args(): capture_path = "res://docs/outro-preview.png"
		if "--capture-briefing2" in OS.get_cmdline_user_args(): capture_path = "res://docs/briefing2-preview.png"
		if "--capture-menu" in OS.get_cmdline_user_args(): capture_path = "res://docs/menu-preview.png"
		if "--capture-settings" in OS.get_cmdline_user_args(): capture_path = "res://docs/settings-preview.png"
		get_viewport().get_texture().get_image().save_png(capture_path)
		capture = false
		music.stop()
		base_music.stop()
		await get_tree().create_timer(0.1).timeout
		get_tree().quit()
		return
	if auto_check and check_time > 0.4:
		auto_check = false
		load("res://tests/features.gd").new().run(self)
		load("res://tests/survival_tuning.gd").new().run(self)
		load("res://tests/terrain_mobile.gd").new().run(self)
		load("res://tests/radio_resources.gd").new().run(self)
		for i in range(TOTAL): _collect(i)
		assert(collected == TOTAL and found == GOALS and ship != null)
		ship_timer = 12.0
		_update_ship(0.1)
		assert(ship_landed)
		normal = ship_normal
		_interact()
		assert(won and outro_video.active and not ending.visible)
		outro_video._finish()
		assert(ending.visible)
		print("PASS: spherical placement, collection, rescue landing, boarding and completion")
		# Let pending audio buffers and queued UI nodes finish before shutdown.
		for audio in [sound, music, base_music, alert_audio, fog_audio]: audio.stop()
		for audio in event_audio.players.values(): audio.stop()
		await get_tree().create_timer(0.15).timeout
		get_tree().quit()
	_update_controls()
	feedback.tick(delta)
	if not playing or won or dead: return
	elapsed += delta
	_update_energy(delta)
	if controls.enabled:
		if inside:
			_update_indoor_movement(delta)
		else:
			_update_movement(delta)
	if inside: base_room.set_power(energy_ready, energy_charge)
	_update_survival(delta)
	if dead: return
	_update_items(delta)
	_update_ship(delta)
	_update_hud(delta)
	_update_prompt()

func _update_movement(delta: float) -> void:
	var input: Vector2 = (controls.direction() + pad).limit_length()
	var old := normal
	var forward := camera.global_basis.y.slide(normal).normalized()
	if forward.length() < 0.1: forward = north
	var right := camera.global_basis.x.slide(normal).normalized()
	var direction := (right * input.x + forward * input.y)
	if direction.length() > 0.05:
		var speed := MOVE_SPEED
		var candidate := (normal + direction * speed / R * delta).normalized()
		var floor_before := terrain.height_at(normal)
		var floor_after := terrain.height_at(candidate)
		if floor_after <= floor_before + 0.10 or altitude >= floor_after - 0.025:
			normal = candidate
		var transport := Quaternion(old, normal)
		north = (transport * north).slide(normal).normalized()
		_align(avatar, normal, direction)
		walk += delta * 8.0
	else:
		_align(avatar, normal, -avatar.basis.z)
	var ground := terrain.height_at(normal)
	if altitude > ground + 0.001 or hop_velocity > 0:
		hop_velocity -= 4.5 * delta
		altitude += hop_velocity * delta
		if altitude <= ground and hop_velocity <= 0:
			altitude = ground
			hop_velocity = 0
	else:
		altitude = ground
		hop_velocity = 0
	hop = maxf(0, altitude - ground)
	avatar.position = normal * (R + altitude)
	astronaut.position.y = absf(sin(walk)) * input.length() * 0.055
	astronaut.rotation.z = sin(walk) * input.length() * 0.045
	var desired := normal * 39.0 - north * 29.0
	camera.position = camera.position.lerp(desired, 1.0 - exp(-3.5 * delta))
	camera.look_at(normal * 2.0, north)

func _item_available(item: Dictionary) -> bool:
	return item.kind == 1 or (signal_transmitted and communications_online)

func _sync_resource_visibility() -> void:
	for item in items:
		item.node.visible = not inside and not item.taken and _item_available(item)

func _can_reach(item: Dictionary) -> bool:
	return normal.dot(item.normal) > cos(1.25 / R) and absf(altitude - terrain.height_at(item.normal)) < 0.24

func _nearest() -> int:
	var index := -1
	var best := -2.0
	for i in range(items.size()):
		if items[i].taken or not _item_available(items[i]): continue
		var dot: float = normal.dot(items[i].normal)
		if dot > best:
			best = dot
			index = i
	return index

func _update_items(_delta: float) -> void:
	for i in range(items.size()):
		var item := items[i]
		if item.taken or not _item_available(item): continue
		item.visual.position.y = 0.08 + sin(elapsed * 2.0 + i) * 0.055
		item.marker.position.y = 1.0 + sin(elapsed * 2 + i) * 0.1
		item.visual.rotation.y += _delta * 0.25

func _collect(index: int) -> void:
	if index < 0 or index >= items.size() or items[index].taken or not _item_available(items[index]): return
	var item := items[index]
	item.taken = true
	item.node.visible = false
	found[item.kind] += 1
	collected += 1
	event_audio.play("collect")
	_try_rescue()

func _try_rescue() -> void:
	if collected == TOTAL and signal_transmitted and communications_online and ship == null:
		_begin_rescue()

func _begin_rescue() -> void:
	ship_normal = (normal + north * 0.14).normalized()
	ship = _surface(ship_normal)
	ship.visible = not inside
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
	ship.position = ship_normal * (R + terrain.height_at(ship_normal) + height)
	if ship_timer >= 9.0 and not ship_landed:
		ship_landed = true
		feedback.transmit("landed", "Pousamos. Venha à nave.", true)
		_chime(880)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if intro_video.active or outro_video.active or audio_settings.visible: return
		if event.physical_keycode == KEY_ESCAPE and playing and not won and not dead:
			if minigames.visible: minigames.close()
			get_viewport().set_input_as_handled()

func _interact() -> void:
	if dead or won or transitioning or minigames.visible or audio_settings.visible: return
	if inside:
		var station: String = base_room.station_at(avatar.position)
		if station == "exit": _transition_to(false)
		elif station == "energy": minigames.open_power(energy_ready and energy_charge > 30)
		elif station == "signal": minigames.open_signal(energy_ready, found[1], signal_transmitted, signal_failures)
		_update_controls()
		return
	if ship_landed and normal.dot(ship_normal) > 0.975:
		_finish()
		return
	if _at_camp():
		_transition_to(true)
		return
	if _at_garden() and food < MAX_RESERVE - 1.0:
		food = MAX_RESERVE
		food_empty_time = 0.0
		_chime(550)
		return
	var near := _nearest()
	if near >= 0 and _can_reach(items[near]):
		_collect(near)

func _at_camp() -> bool:
	return inside or normal.dot(camp_normal) > cos(SHELTER_RADIUS / R)

func _at_garden() -> bool:
	return normal.dot(garden_normal) > cos(2.4 / R)

func _update_survival(delta: float) -> void:
	if _at_camp() and energy_ready:
		oxygen = minf(MAX_RESERVE, oxygen + delta * 25.0)
	else:
		oxygen = maxf(0.0, oxygen - delta * OXYGEN_RATE)
	food = maxf(0.0, food - delta * FOOD_RATE)
	_update_radiation(delta)
	_update_last_chance(delta)
	_update_solar_notices()
	base_room.set_solar(solar_phase)
	_update_distant_light()
	_resource_warnings(delta)

func _update_radiation(delta: float) -> void:
	var remaining := delta
	while remaining > 0.00001 and not dead:
		var duration: float = {"calm": SOLAR_INTERVAL, "warning": SOLAR_WARNING, "active": SOLAR_DURATION}[solar_phase]
		var step := minf(remaining, maxf(0.0, duration - solar_clock))
		if solar_phase == "active" and not inside:
			exposure += step
			if exposure >= EXPOSURE_LIMIT: _die()
		else:
			exposure = 0.0
		solar_clock += step
		remaining -= step
		if solar_clock >= duration:
			solar_clock = 0.0
			match solar_phase:
				"calm":
					solar_phase = "warning"
				"warning":
					solar_phase = "active"
					event_audio.play("solar")
					event_audio.play("fog")
				"active":
					solar_phase = "calm"
					solar_cycle += 1
					exposure = 0.0
					fog_audio.stop()
					alert_audio.stop()
	var duration: float = {"calm": SOLAR_INTERVAL, "warning": SOLAR_WARNING, "active": SOLAR_DURATION}[solar_phase]
	solar_remaining = duration - solar_clock
	solar_fog.visible = solar_phase == "active" and not inside

func _resource_warnings(delta := 0.0) -> void:
	health_alarm_cooldown = maxf(0, health_alarm_cooldown - delta)
	var crossed := false
	var oxygen_crossed := false
	var food_crossed := false
	if _percent(oxygen) <= 25.0 and not oxygen_low:
		oxygen_low = true
		oxygen_crossed = true
		crossed = true
	if _percent(food) <= 25.0 and not food_low:
		food_low = true
		food_crossed = true
		crossed = true
	if _percent(oxygen) <= 12.0 and not oxygen_critical:
		oxygen_critical = true
		oxygen_crossed = true
		crossed = true
	if _percent(food) <= 12.0 and not food_critical:
		food_critical = true
		food_crossed = true
		crossed = true
	if _percent(oxygen) > 35.0:
		oxygen_low = false
		oxygen_critical = false
	if _percent(food) > 35.0:
		food_low = false
		food_critical = false
	if crossed:
		health_notice_serial += 1
		var warnings: Array[String] = []
		if oxygen_crossed: warnings.append("O₂ crítico. Vá ao abrigo!" if oxygen_critical else "O₂ baixo. Volte ao abrigo.")
		if food_crossed: warnings.append("Comida crítica. Vá à estufa!" if food_critical else "Comida baixa. Vá à estufa.")
		feedback.notice_message("vitals_%d" % health_notice_serial, "\n".join(warnings), false)
	if crossed or (_percent(minf(oxygen, food)) <= 12.0 and health_alarm_cooldown <= 0):
		event_audio.play("vitals")
		health_alarm_cooldown = 8.0

func _update_last_chance(delta: float) -> void:
	oxygen_empty_time = oxygen_empty_time + delta if oxygen <= 0 else 0.0
	food_empty_time = food_empty_time + delta if food <= 0 else 0.0
	if oxygen_empty_time >= 2.0 or food_empty_time >= 2.0:
		_die()

func _die() -> void:
	if dead: return
	dead = true
	minigames.close()
	audio_settings.close()
	event_audio.stop_all()
	event_audio.play("death")
	music.volume_db = -22 if not muted else -80
	death_panel.show()
	_update_controls()
	_update_hud(0)

func _update_distant_light() -> void:
	var activity := 0.2
	var brightness := 0.0
	if solar_phase == "warning":
		brightness = smoothstep(0.0, 1.0, solar_clock / SOLAR_WARNING)
		activity = 0.35 + brightness * 0.65
	elif solar_phase == "active":
		activity = 1.0
		brightness = 0.9
	if inside: brightness = 0
	world_environment.background_color = Color("101c30").lerp(Color("e9d7b9"), brightness * 0.8)
	world_environment.ambient_light_energy = 0.35 + brightness * 0.3
	if feedback != null: feedback.solar_intensity(brightness, inside)
	distant_light.scale = Vector3.ONE * (0.5 + activity * 1.3)
	distant_halo.scale = Vector3.ONE * (0.7 + activity * 1.2)
	distant_halo.material_override.albedo_color = Color(1.0, 0.6, 0.27, activity * 0.65)

func _style(color: Color, border := Color.TRANSPARENT, radius := 18) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(mini(radius, 4))
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 18
	box.content_margin_bottom = 18
	return box

func _label(text: String, size: int, color := CREAM) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", roundi(size * 1.12))
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.theme = preload("res://scripts/ui_theme.gd").create()
	button.text = text
	button.custom_minimum_size.y = 96
	button.add_theme_font_size_override("font_size", 30)
	button.pressed.connect(callback)
	return button

func _modal(title: String, subtitle: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme = preload("res://scripts/ui_theme.gd").create()
	panel.custom_minimum_size = Vector2(900, 0)
	panel.size = Vector2(900, 0)
	panel.add_theme_stylebox_override("panel", _style(Color("191c21f5"), Color("444b54"), 24))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	panel.add_child(v)
	v.add_child(_label("ASTRO / UM PEQUENO RECOMEÇO", 13, PEACH))
	var heading := _label(title, 40)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.custom_minimum_size.x = 850
	v.add_child(heading)
	var description := _label(subtitle, 26, MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 850
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
	root.theme = preload("res://scripts/ui_theme.gd").create()
	hud_root = root
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(root)
	root.hide()
	var logo := _label("ASTRO", 25)
	logo.position = Vector2(42, 28)
	root.add_child(logo)
	var vital_backdrop := Panel.new()
	vital_backdrop.position = Vector2(22, 64)
	vital_backdrop.size = Vector2(365, 282)
	vital_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vital_backdrop.add_theme_stylebox_override("panel", _style(Color("191c21f0"), Color("444b54"), 18))
	root.add_child(vital_backdrop)
	var vitals := VBoxContainer.new()
	vitals_ui = vitals
	vitals.position = Vector2(42, 76)
	vitals.add_theme_constant_override("separation", 8)
	root.add_child(vitals)
	oxygen_label = _label("O₂", 24, MINT)
	food_label = _label("COMIDA", 24, PEACH)
	vitals.add_child(oxygen_label)
	oxygen_bar = _vital_bar(MINT)
	vitals.add_child(oxygen_bar)
	vitals.add_child(food_label)
	food_bar = _vital_bar(PEACH)
	vitals.add_child(food_bar)
	var objectives := HBoxContainer.new()
	objectives_ui = objectives
	objectives.position = Vector2(917, 30)
	objectives.add_theme_constant_override("separation", 12)
	root.add_child(objectives)
	var names := ["PEDRAS", "ANTENA", "COMBUST."]
	for i in range(3):
		material_icons.append(_make_item_icon(i))
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(250, 116)
		card.add_theme_stylebox_override("panel", preload("res://scripts/ui_theme.gd").box(Color("191c21ed"), Color("444b54"), 12))
		objectives.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var icon := TextureRect.new()
		icon.texture = material_icons[i]
		icon.custom_minimum_size = Vector2(80, 80)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var column := VBoxContainer.new()
		row.add_child(column)
		var count_label := _label("0/%d" % GOALS[i], 36, [PEACH, MINT, CREAM][i])
		counts.append(count_label)
		column.add_child(count_label)
		column.add_child(_label(names[i], 20, MUTED))
	var mute_button := _button("Som", func(): audio_settings.open())
	mute_ui = mute_button
	mute_button.position = Vector2(1268, 817)
	mute_button.custom_minimum_size.x = 54
	root.add_child(mute_button)
	start_menu = preload("res://scripts/main_menu.gd").new()
	hud.add_child(start_menu)
	start_menu.start_requested.connect(_start)
	start_menu.settings_requested.connect(func(): audio_settings.open())
	intro = preload("res://scripts/mission_briefing.gd").new()
	hud.add_child(intro)
	intro.accepted.connect(_start_game)
	ending = _modal("EM CASA.", "Sua tripulação chegou.")
	ending.get_child(0).add_child(_button("Explorar outra vez  ", func(): get_tree().reload_current_scene()))
	ending.hide()
	death_panel = _modal("MISSÃO ENCERRADA", "Cuide das reservas. Tente outra rota.")
	death_panel.get_child(0).add_child(_button("Recomeçar expedição  ", func(): get_tree().reload_current_scene()))
	death_panel.hide()
	audio_settings = preload("res://scripts/sound_settings.gd").new()
	hud.add_child(audio_settings)
	audio_settings.visibility_updated.connect(_update_controls)

func _make_item_icon(kind: int) -> Texture2D:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(128, 128)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var stage := Node3D.new()
	viewport.add_child(stage)
	if kind == 0:
		_asset("rock_largeA", stage, 0.55)
	elif kind == 1:
		_box(stage, Vector3(0.34, 0.42, 0.28), MINT, Vector3(0, 0.23, 0))
		_box(stage, Vector3(0.36, 0.1, 0.3), Color("607c77"), Vector3(0, 0.28, 0))
	else:
		_box(stage, Vector3(0.35, 0.48, 0.25), Color("e2ad68"), Vector3(0, 0.24, 0))
		_box(stage, Vector3(0.18, 0.08, 0.17), Color("576d76"), Vector3(0.06, 0.51, 0))
		_box(stage, Vector3(0.37, 0.08, 0.27), Color("f1d7aa"), Vector3(0, 0.25, 0))
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color.TRANSPARENT
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color.WHITE
	settings.ambient_light_energy = 0.8
	environment.environment = settings
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -35, 0)
	light.light_energy = 1.1
	stage.add_child(light)
	var icon_camera := Camera3D.new()
	icon_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	icon_camera.size = 1.1
	icon_camera.position = Vector3(1.1, 1, 1.4)
	stage.add_child(icon_camera)
	icon_camera.look_at(Vector3(0, 0.24, 0))
	return viewport.get_texture()

func _vital_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(300, 25)
	bar.max_value = MAX_RESERVE
	bar.value = MAX_RESERVE
	bar.show_percentage = false
	var track := _style(Color("11151a"), Color("444b54"), 8)
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
	start_menu.hide()
	if auto_check or capture or Engine.has_meta("astro_intro_seen"):
		_start_game()
	else:
		music.stop()
		base_music.stop()
		intro_video.begin(muted)

func _show_briefing() -> void:
	playing = false
	start_menu.hide()
	hud_root.hide()
	intro.open()
	_update_controls()

func _start_game() -> void:
	Engine.set_meta("astro_intro_seen", true)
	start_menu.hide()
	intro.hide()
	hud_root.show()
	playing = true
	if not music.playing: music.play()
	if not base_music.playing: base_music.play()
	feedback.transmit("start", "Estamos voltando. Mantenha-se seguro.")
	_update_controls()

func _percent(value: float) -> float:
	return clampf(value / MAX_RESERVE * 100.0, 0, 100)

func _update_hud(_delta: float) -> void:
	for i in range(3):
		counts[i].text = str(found[i]) + "/" + str(GOALS[i])
		counts[i].get_parent().get_parent().get_parent().modulate.a = 1.0 if i == 1 or (signal_transmitted and communications_online) else 0.45
		counts[i].add_theme_color_override("font_color", MINT if found[i] == GOALS[i] else MUTED)
	oxygen_label.text = "O₂   " + str(ceili(_percent(oxygen))) + "%"
	food_label.text = "COMIDA   " + str(ceili(_percent(food))) + "%"
	oxygen_bar.value = oxygen
	food_bar.value = food
	var pulse := 0.5 + 0.5 * sin(elapsed * 3.6)
	for pair in [[oxygen_bar, oxygen_label, _percent(oxygen), MINT], [food_bar, food_label, _percent(food), PEACH]]:
		var severity := clampf((30.0 - pair[2]) / 15.0, 0, 1)
		var style: StyleBoxFlat = pair[0].get_theme_stylebox("fill")
		var track: StyleBoxFlat = pair[0].get_theme_stylebox("background")
		var urgent := Color("d95057").lerp(Color("f08078"), pulse)
		style.bg_color = pair[3].lerp(urgent, severity)
		track.bg_color = Color("11151a").lerp(Color("6f303d"), severity * (0.65 + pulse * 0.2))
		pair[0].modulate.a = lerpf(1.0, 0.86 + pulse * 0.14, severity)
		pair[1].add_theme_color_override("font_color", pair[3].lerp(urgent, severity))
	var depleted := 1.0 - clampf(_percent(minf(oxygen, food)) / 30.0, 0, 1)
	var grace := clampf(maxf(oxygen_empty_time, food_empty_time) / 2.0, 0, 1)
	power_label.add_theme_color_override("font_color", Color("ef7777") if energy_charge <= 30 else MINT)
	power_label.modulate.a = 0.72 + pulse * 0.28 if energy_charge <= 30 else 1.0
	var intensity := maxf(depleted * 0.65 + grace * 0.3, exposure / EXPOSURE_LIMIT * 0.9)
	if dead: intensity = 0.98
	vignette_material.set_shader_parameter("intensity", intensity)

func _finish() -> void:
	if won: return
	won = true
	event_audio.stop_all()
	music.stop()
	base_music.stop()
	avatar.hide()
	hud_root.hide()
	_update_controls()
	outro_video.begin(muted, true)

func _show_ending() -> void:
	if won: ending.show()

func _build_audio() -> void:
	music = AudioStreamPlayer.new()
	music.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(music)
	music.bus = "Music"
	music.stream = preload("res://assets/audio/space-galaxy.mp3")
	music.stream.loop = true
	music.volume_db = linear_to_db(PLANET_MUSIC_GAIN)
	music.play()
	base_music = AudioStreamPlayer.new()
	base_music.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	base_music.bus = "Music"
	base_music.stream = preload("res://assets/audio/space-ship.mp3")
	base_music.stream.loop = true
	base_music.volume_db = -80
	add_child(base_music)
	base_music.play()
	sound = AudioStreamPlayer.new()
	sound.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	sound.bus = "Interactions"
	add_child(sound)
	event_audio = preload("res://scripts/event_audio.gd").new()
	add_child(event_audio)
	alert_audio = event_audio.players["solar"]
	fog_audio = event_audio.players["fog"]

func _update_music(delta: float) -> void:
	if music == null or base_music == null: return
	if won or (intro_video != null and intro_video.active): return
	music_mix = move_toward(music_mix, 1.0 if inside else 0.0, delta / 1.2)
	var duck := 0.25 if dead else 0.4 if solar_phase == "active" else 1.0
	music.volume_db = linear_to_db(maxf(0.0001, (1.0 - music_mix) * PLANET_MUSIC_GAIN * duck))
	base_music.volume_db = linear_to_db(maxf(0.0001, music_mix * BASE_MUSIC_GAIN * duck))

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
	AudioServer.set_bus_mute(0, muted)

func _build_expansion() -> void:
	base_room = preload("res://scripts/base_interior.gd").new()
	add_child(base_room)
	controls = preload("res://scripts/player_input.gd").new()
	hud.add_child(controls)
	controls.interact_requested.connect(_interact)
	controls.jump_requested.connect(_jump)
	prompt = _button("", _interact)
	prompt.custom_minimum_size = Vector2(450, 76)
	hud.add_child(prompt)
	prompt.hide()
	power_label = _label("", 24, MINT)
	power_label.position = Vector2(42, 265)
	hud_root.add_child(power_label)
	base_status = _label("", 24, MINT)
	base_status.position = Vector2(42, 302)
	hud_root.add_child(base_status)
	feedback = preload("res://scripts/mission_feedback.gd").new()
	hud.add_child(feedback)
	feedback.typing_tick.connect(func(): event_audio.play("typing"))
	feedback.transmission_started.connect(func(): event_audio.play("radio"))
	minigames = preload("res://scripts/base_minigames.gd").new()
	hud.add_child(minigames)
	minigames.power_repaired.connect(_on_power_repaired)
	minigames.signal_sent.connect(_on_signal_sent)
	minigames.closed.connect(_update_controls)
	intro_video = preload("res://scripts/intro_video.gd").new()
	hud.add_child(intro_video)
	intro_video.finished.connect(_show_briefing)
	outro_video = preload("res://scripts/intro_video.gd").new()
	hud.add_child(outro_video)
	outro_video.finished.connect(_show_ending)
	intro.configure(material_icons, controls.mobile)
	portrait_hint = PanelContainer.new()
	portrait_hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait_hint.add_theme_stylebox_override("panel", _style(Color("101215")))
	var rotate_text := _label("Gire o celular.\nA missão continua.", 48, CREAM)
	rotate_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotate_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait_hint.add_child(rotate_text)
	hud.add_child(portrait_hint)
	portrait_hint.hide()
	transition_veil = ColorRect.new()
	transition_veil.color = Color("101215")
	transition_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_veil.modulate.a = 0
	hud.add_child(transition_veil)
	get_viewport().size_changed.connect(_layout_ui)
	for modal in [ending, death_panel]:
		modal.resized.connect(_center_modal.bind(modal))
	_layout_ui()
	_update_controls()

func _layout_ui() -> void:
	var view := get_viewport().get_visible_rect().size
	objectives_ui.position = Vector2(view.x - 810, 28)
	mute_ui.position = Vector2(view.x - 138, 160)
	mute_ui.custom_minimum_size = Vector2(100, 72)
	prompt.position = Vector2((view.x - 450) / 2, view.y - 112)
	for modal in [ending, death_panel]: _center_modal(modal)
	portrait_hint.visible = controls.mobile and view.y > view.x
	controls.reset()
	_update_controls()

func _center_modal(modal: Control) -> void:
	modal.position = (get_viewport().get_visible_rect().size - modal.size) / 2

func _update_controls() -> void:
	if controls == null: return
	minigames.frozen = portrait_hint.visible or audio_settings.visible
	var active := playing and not dead and not won and not transitioning and not minigames.visible and not portrait_hint.visible and not audio_settings.visible
	controls.set_enabled(active)
	controls.jump_available = not inside
	_sync_resource_visibility()
	if feedback.link_online != communications_online: feedback.set_link(communications_online)
	feedback.active = playing and not dead and not won
	if not active:
		prompt.hide()
		prompt_target = ""
	base_status.visible = playing and not intro_video.active and not won and not dead
	power_label.visible = base_status.visible
	power_label.text = "ENERGIA %d%%" % energy_charge if energy_ready else "ENERGIA OFF / O₂ OFF"
	base_status.text = "RÁDIO ONLINE" if communications_online else "RÁDIO OFFLINE"

func _publish_web_test_state() -> void:
	var forward := camera.global_basis.y.slide(normal).normalized()
	var right := camera.global_basis.x.slide(normal).normalized()
	var state := {"normal": [normal.x, normal.y, normal.z], "right": [right.x, right.y, right.z], "forward": [forward.x, forward.y, forward.z], "inside": inside, "hop": hop, "altitude": altitude, "floor": terrain.height_at(normal), "mobile": controls.mobile, "enabled": controls.enabled, "stick": controls.stick_id, "playing": playing, "dead": dead, "oxygen": oxygen, "platform": [terrain.platforms[0].normal.x, terrain.platforms[0].normal.y, terrain.platforms[0].normal.z], "camp": [camp_normal.x, camp_normal.y, camp_normal.z], "position": [avatar.position.x, avatar.position.y, avatar.position.z]}
	JavaScriptBridge.eval("window.__astroQA = %s;" % JSON.stringify(state))

func _jump() -> void:
	if controls.enabled and not inside and hop == 0 and hop_velocity == 0: hop_velocity = 2.4

func _update_prompt() -> void:
	if not controls.enabled: return
	var target := ""
	var text := ""
	if inside:
		target = base_room.station_at(avatar.position)
		text = {"energy": "ENERGIA", "signal": "ANTENA", "exit": "SAIR", "": ""}[target]
	elif ship_landed and normal.dot(ship_normal) > 0.975:
		target = "board"
		text = "Embarcar"
	elif _at_camp():
		target = "enter"
		text = "ABRIGO"
	elif _at_garden() and food < MAX_RESERVE - 1.0:
		target = "food"
		text = "Comer"
	else:
		var near := _nearest()
		if near >= 0 and _can_reach(items[near]):
			target = "collect"
			text = "Coletar"
	controls.action_text = text if not text.is_empty() else "Interagir"
	controls.action_available = not target.is_empty()
	controls.queue_redraw()
	if target == prompt_target: return
	prompt_target = target
	if prompt_tween: prompt_tween.kill()
	if target.is_empty():
		prompt_tween = create_tween()
		prompt_tween.tween_property(prompt, "modulate:a", 0.0, 0.12)
		prompt_tween.tween_callback(prompt.hide)
	else:
		prompt.text = ("" if controls.mobile else "[E] ") + text
		prompt.show()
		prompt.pivot_offset = prompt.size / 2
		prompt.scale = Vector2.ONE * 0.92
		prompt.modulate.a = 0
		prompt_tween = create_tween().set_parallel(true)
		prompt_tween.tween_property(prompt, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		prompt_tween.tween_property(prompt, "modulate:a", 1.0, 0.16)

func _transition_to(to_inside: bool) -> void:
	if transitioning: return
	transitioning = true
	_update_controls()
	transition_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	var fade := create_tween()
	fade.tween_property(transition_veil, "modulate:a", 1.0, 0.18)
	await fade.finished
	_apply_location(to_inside)
	fade = create_tween()
	fade.tween_property(transition_veil, "modulate:a", 0.0, 0.22)
	await fade.finished
	transitioning = false
	transition_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_controls()
	_update_prompt()

func _apply_location(to_inside: bool) -> void:
	if to_inside:
		exterior_normal = normal
		exterior_north = north
	inside = to_inside
	if inside: exposure = 0.0
	hop = 0
	altitude = 0 if inside else terrain.height_at(exterior_normal)
	hop_velocity = 0
	base_room.visible = inside
	for node in exterior_nodes: node.visible = not inside
	_sync_resource_visibility()
	if ship != null: ship.visible = not inside
	if inside:
		avatar.position = base_room.position + Vector3(0, 0, 2.6)
		avatar.basis = Basis.IDENTITY
		camera.position = base_room.position + Vector3(0, 13, 11)
		camera.look_at(base_room.position + Vector3(0, 0, -0.2), Vector3.UP)
	else:
		normal = exterior_normal
		north = exterior_north
		avatar.position = normal * (R + altitude)
		_align(avatar, normal, north)
		camera.position = normal * 39.0 - north * 29.0
		camera.look_at(normal * 2.0, north)
	solar_fog.visible = not inside and solar_phase == "active"
	_update_distant_light()
	base_room.set_power(energy_ready, energy_charge)
	base_room.set_solar(solar_phase)
	controls.reset()
	prompt_target = ""

func _update_indoor_movement(delta: float) -> void:
	var input: Vector2 = controls.direction()
	var forward := camera.global_basis.y.slide(Vector3.UP).normalized()
	var right := camera.global_basis.x.slide(Vector3.UP).normalized()
	var direction := right * input.x + forward * input.y
	avatar.position = base_room.move_player(avatar.position, direction * MOVE_SPEED * delta)
	if direction.length() > 0.05:
		_align(avatar, Vector3.UP, direction)
		walk += delta * 8
	astronaut.position.y = absf(sin(walk)) * input.length() * 0.055
	astronaut.rotation.z = sin(walk) * input.length() * 0.045

func _update_solar_notices() -> void:
	if not communications_online: return
	if solar_phase == "calm" and solar_clock >= SOLAR_INTERVAL - 20:
		feedback.transmit("solar_early_%d" % solar_cycle, "Radiação em breve. Prepare o abrigo.", true, feedback.AXIOS)
	elif solar_phase != "calm" and not inside:
		feedback.shelter_tutorial()

func _update_energy(delta: float) -> void:
	if energy_ready:
		energy_clock += delta
		energy_charge = maxf(0, 100.0 * (1.0 - energy_clock / ENERGY_INTERVAL))
		if energy_charge <= 30 and not energy_low_announced and communications_online:
			energy_low_announced = true
			feedback.transmit("power_low_%d" % energy_failures, "Energia em 30%. Repare a base.", true, feedback.AXIOS)
		if energy_clock >= ENERGY_INTERVAL:
			energy_ready = false
			energy_charge = 0
			energy_failures += 1
			event_audio.play("energy")
			feedback.transmit("power_tutorial", "Energia baixa. Produção de O₂ interrompida.", true, feedback.AXIOS)
			if minigames.visible and minigames.mode == "signal": minigames.open_signal(false, found[1], signal_transmitted, signal_failures)
	if communications_online and ship == null:
		signal_clock += delta
		if signal_clock >= SIGNAL_INTERVAL:
			communications_online = false
			signal_transmitted = false
			_sync_resource_visibility()
			signal_failures += 1
			feedback.set_link(false)
			event_audio.play("disconnect")
			feedback.notice_message("comm_tutorial", "Sem sinal. Recursos e avisos ocultos.", false)

func _on_power_repaired() -> void:
	energy_ready = true
	energy_charge = 100
	energy_clock = 0
	energy_low_announced = false
	base_room.set_power(true, energy_charge)
	_chime(660)
	_update_controls()

func _on_signal_sent() -> void:
	communications_online = true
	feedback.set_link(true)
	signal_transmitted = found[1] >= 6
	signal_clock = 0
	_chime(880)
	if signal_transmitted: feedback.transmit("signal", "Sinal recebido. Recursos localizados.")
	_sync_resource_visibility()
	if solar_phase != "calm" and not inside: feedback.shelter_tutorial()
	_try_rescue()
	_update_controls()

func _assert_world() -> void:
	assert(items.size() == TOTAL)
	var kinds := [0, 0, 0]
	for item in items:
		assert(absf(item.node.position.length() - (R + terrain.height_at(item.normal))) < 0.01)
		assert(item.node.basis.y.dot(item.normal) > 0.99)
		kinds[item.kind] += 1
	assert(kinds == GOALS)
	assert(avatar.position.length() >= R + terrain.height_at(normal) - 0.02)
	for input_direction in [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]:
		normal = Vector3.UP
		north = Vector3.FORWARD
		camera.position = normal * 39.0 - north * 29.0
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
		if i % 55 == 0 and hop == 0: hop_velocity = 2.4
		_update_movement(0.02)
		assert(avatar.position.length() >= R + terrain.height_at(normal) - 0.02)
		if normal.y < -0.5:
			crossed_hemisphere = true
	assert(crossed_hemisphere)
	pad = Vector2.ZERO
	altitude = 0
	hop = 0
	hop_velocity = 0
	normal = Vector3.UP
	north = Vector3.FORWARD
	avatar.position = normal * R
	_align(avatar, normal, north)
	camera.position = normal * 39.0 - north * 29.0
	camera.look_at(normal * 2.0, north)

func _assert_survival() -> void:
	normal = Vector3.DOWN
	energy_ready = true
	oxygen = MAX_RESERVE
	food = MAX_RESERVE
	_update_survival(10)
	assert(is_equal_approx(oxygen, MAX_RESERVE - 34.0) and is_equal_approx(food, MAX_RESERVE - 18.0))
	normal = camp_normal
	_update_survival(2)
	assert(oxygen == MAX_RESERVE)
	normal = garden_normal
	food = 20
	_interact()
	assert(food == MAX_RESERVE)
	assert(distant_light.position.normalized().dot(solar_axis) > 0.999)
	solar_clock = SOLAR_INTERVAL - 0.1
	solar_phase = "calm"
	_update_radiation(0.2)
	assert(solar_phase == "warning" and is_equal_approx(solar_remaining, SOLAR_WARNING - 0.1))
	solar_clock = SOLAR_WARNING - 0.1
	_update_radiation(0.2)
	assert(solar_phase == "active" and fog_audio.playing)
	for point in [Vector3.UP, Vector3.DOWN, camp_normal]:
		normal = point
		exposure = 0
		_update_radiation(0.8)
		assert(is_equal_approx(exposure, 0.8) and not dead)
	_apply_location(true)
	assert(exposure == 0)
	_update_radiation(3.1)
	assert(not dead and exposure == 0)
	_apply_location(false)
	_update_radiation(2.99)
	assert(not dead)
	_update_radiation(0.02)
	assert(dead and event_audio.players.death.playing)
	dead = false
	death_panel.hide()
	exposure = 0
	inside = true
	_update_radiation(20)
	assert(solar_phase == "calm")
	inside = false
	normal = Vector3.DOWN
	oxygen = 0
	food = MAX_RESERVE
	_update_last_chance(1.8)
	assert(not dead)
	_update_hud(0)
	assert(float(vignette_material.get_shader_parameter("intensity")) > 0.8)
	normal = camp_normal
	_update_survival(0.05)
	assert(oxygen > 0 and oxygen_empty_time == 0.0 and not dead)
	normal = garden_normal
	food = 0
	_update_last_chance(1.7)
	_interact()
	assert(food == MAX_RESERVE and food_empty_time == 0.0)
	normal = Vector3.DOWN
	var previous_items := collected
	oxygen = 0
	_update_last_chance(2.01)
	assert(dead and collected == previous_items)
	dead = false
	death_panel.hide()
	oxygen = MAX_RESERVE
	food = 0
	_update_last_chance(2.01)
	assert(dead)
	dead = false
	death_panel.hide()
	oxygen = MAX_RESERVE
	food = MAX_RESERVE
	oxygen_empty_time = 0
	food_empty_time = 0
	solar_clock = 0
	solar_phase = "calm"
	solar_remaining = SOLAR_INTERVAL
	fog_audio.stop()
	alert_audio.stop()
	_resource_warnings()
	print("PASS: larger reserves, recovery, grace/death, planet-wide fog, three-second exposure and interior protection")
