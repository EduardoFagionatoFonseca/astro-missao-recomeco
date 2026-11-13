extends Node3D
## Builds the authored exterior world from reusable primitives and project assets.
## Runtime state remains in the mission controller so this node can focus on world assembly.
@export_group("Distribuição")
@export_range(0, 1200, 1) var star_count := 900
@export_range(0, 500, 1) var rock_count := 200
@export_range(0, 100, 1) var crater_count := 24
@export_range(0, 100, 1) var horizon_marker_count := 32
@export_range(0, 2147483647, 1) var world_seed := 60318

@export_group("Pontos de interesse")
@export var camp_direction := Vector3(0.07, 1.0, 0.12)
@export var garden_direction := Vector3(0.9, -0.15, -0.5)
@export var sun_direction := Vector3(-0.45, -0.65, -0.6)

var game: Node3D

func build(mission: Node3D) -> void:
	game = mission
	game.rng.seed = world_seed
	game.camp_normal = camp_direction.normalized()
	game.garden_normal = garden_direction.normalized()
	game.solar_axis = sun_direction.normalized()
	_build_environment()
	_build_planet()
	_build_camp()
	_build_items()

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
	root.position = up * (game.R + game.terrain.height_at(up))
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
	game.world_environment = settings
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("010207")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("cbd8ed")
	settings.ambient_light_energy = 0.4
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	settings.tonemap_exposure = 0.9
	settings.glow_enabled = true
	settings.glow_intensity = 0.28
	settings.glow_strength = 0.62
	settings.glow_bloom = 0.04
	env.environment = settings
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("ffe4bd")
	sun.light_energy = 0.82
	sun.rotation_degrees = Vector3(-42, -30, -15)
	sun.shadow_enabled = true
	sun.shadow_bias = 0.035
	sun.shadow_normal_bias = 1.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 85
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color("8fb9dc")
	fill.light_energy = 0.22
	fill.rotation_degrees = Vector3(35, 135, 0)
	fill.shadow_enabled = false
	add_child(fill)
	var star_mat := _material(Color("d7e3f0"), 1.0)
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(star_count):
		var direction := Vector3(game.rng.randf_range(-1, 1), game.rng.randf_range(-1, 1), game.rng.randf_range(-1, 1)).normalized()
		var star := _ball(self, game.rng.randf_range(0.07, 0.18), game.CREAM, direction * 95.0)
		star.material_override = star_mat
	game.moon = _ball(self, 2.25, Color("829fb1"), Vector3(-38, 27, -58))
	game.distant_light = _ball(self, 6.8, game.PEACH, game.solar_axis * 180.0)
	var source_material := _material(Color("ffdbad"), 1.0)
	source_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	game.distant_light.material_override = source_material
	game.distant_light.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var halo_mesh := QuadMesh.new()
	halo_mesh.size = Vector2(40, 40)
	game.distant_halo = _mesh(self, halo_mesh, game.PEACH, game.solar_axis * 180.0)
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
	game.distant_halo.material_override = halo_material
	game.distant_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _build_planet() -> void:
	var planet := _mesh(self, game.terrain.make_planet(), Color.WHITE)
	planet.name = "LittleMars"
	planet.material_override.vertex_color_use_as_albedo = true
	for platform in game.terrain.platforms:
		var ledge := _mesh(self, game.terrain.make_platform(platform), Color.WHITE)
		ledge.name = "JumpLedge"
		ledge.material_override.vertex_color_use_as_albedo = true
		ledge.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in range(rock_count):
		var n := _fibonacci(i, rock_count)
		if n.dot(Vector3.UP) > 0.975:
			continue
		var root := _surface(n)
		root.rotate_object_local(Vector3.UP, game.rng.randf() * TAU)
		var stone := _asset("rock_largeA", root, game.rng.randf_range(0.12, 0.65))
		stone.scale *= Vector3(1.2, 0.7, 1.1)
	for i in range(crater_count):
		var n := _fibonacci(i, crater_count)
		if n.dot(Vector3.UP) > 0.93:
			continue
		var root := _surface(n)
		var crater := _asset("craterLarge", root, 0.13)
		crater.scale *= 0.85
	for i in range(horizon_marker_count):
		var angle := float(i) / float(maxi(horizon_marker_count, 1)) * TAU
		var n := Vector3(sin(angle) * 0.22, 1.0, cos(angle) * 0.22).normalized()
		var root := _surface(n)
		_cylinder(root, 0.045, 0.23, Color("eac49e"), Vector3(0, 0.12, 0))
	game.solar_fog = MeshInstance3D.new()
	add_child(game.solar_fog)
	var shell := SphereMesh.new()
	shell.radius = game.R + 1.5
	shell.height = (game.R + 1.5) * 2
	game.solar_fog.mesh = shell
	var fog_material := ShaderMaterial.new()
	fog_material.shader = preload("res://shaders/radiation_fog.gdshader")
	game.solar_fog.material_override = fog_material
	game.solar_fog.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	game.solar_fog.hide()

func _fibonacci(i: int, count: int) -> Vector3:
	var y := 1.0 - (float(i) + 0.5) / float(count) * 2.0
	var a := float(i) * 2.39996323
	var r := sqrt(1.0 - y * y)
	return Vector3(cos(a) * r, y, sin(a) * r)

func _build_camp() -> void:
	var camp := _surface(game.camp_normal)
	var dome := _ball(camp, 0.95, Color("d5d8c6"), Vector3(-0.8, 0.33, 0))
	dome.scale.y = 0.75
	_box(camp, Vector3(0.6, 0.65, 0.35), Color("617e86"), Vector3(-0.8, 0.32, -0.8))
	_box(camp, Vector3(0.36, 0.32, 0.05), game.MINT, Vector3(-0.8, 0.36, -1.0))
	_asset("satelliteDish_detailed", camp, 1.2).position = Vector3(1.2, 0, 0)
	_asset("machine_generator", camp, 0.6).position = Vector3(-1.6, 0, 1.0)
	_asset("rover", camp, 0.5).position = Vector3(1.4, 0, 1.6)
	for i in range(2):
		var panel := _box(camp, Vector3(0.7, 0.07, 0.9), Color("648eab"), Vector3(-2.2 - i * 0.8, 0.32, 0))
		panel.rotation.z = -0.2
		_cylinder(camp, 0.04, 0.3, game.CREAM, Vector3(-2.2 - i * 0.8, 0.15, 0))
	var garden := _surface(game.garden_normal)
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
	var garden_sign := Label3D.new()
	garden_sign.text = "ESTUFA"
	garden_sign.font_size = 42
	garden_sign.pixel_size = 0.008
	garden_sign.position = Vector3(0, 1.9, 0)
	garden_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	garden.add_child(garden_sign)

func _build_items() -> void:
	for i in range(game.TOTAL):
		var n := _fibonacci(i, game.TOTAL)
		# First pickup is visible by the camp; the rest invite a complete orbit.
		if i == 0:
			n = game.terrain.platforms[0].normal
		var root := _surface(n)
		var kind := 1 if i < game.GOALS[1] else 0 if i < game.GOALS[1] + game.GOALS[0] else 2
		var visual := Node3D.new()
		root.add_child(visual)
		var photo := i - int(game.GOALS[1]) if kind == 0 else -1
		if kind == 0:
			_box(visual, Vector3(0.62, 0.44, 0.07), Color("242f39"), Vector3(0, 0.48, 0))
			var card := QuadMesh.new()
			card.size = Vector2(0.54, 0.35)
			var image := _mesh(visual, card, Color.WHITE, Vector3(0, 0.48, 0.04))
			var surface := StandardMaterial3D.new()
			surface.albedo_texture = preload("res://scripts/ui/mars_archive.gd").PHOTOS[photo]
			surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			surface.cull_mode = BaseMaterial3D.CULL_DISABLED
			image.material_override = surface
		elif kind == 1:
			_box(visual, Vector3(0.34, 0.42, 0.28), game.MINT, Vector3(0, 0.23, 0))
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
		var ring := _mesh(root, ring_mesh, [game.PEACH, game.MINT, Color("dfcc97")][kind], Vector3(0, 0.08, 0))
		var marker := _ball(root, 0.065, [game.PEACH, game.MINT, Color("dfcc97")][kind], Vector3(0, 1.1, 0))
		marker.material_override = _material([game.PEACH, game.MINT, Color("dfcc97")][kind], 0.5)
		game.items.append({"node": root, "normal": n, "visual": visual, "marker": marker, "ring": ring, "kind": kind, "photo": photo, "taken": false})
	game._sync_resource_visibility()
