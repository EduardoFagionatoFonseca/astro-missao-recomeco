extends Control
## Short illustrated scenes that introduce each readiness question.
signal finished

const DURATION := 6.4
var active := false
var clock := 0.0
var scene_key := "life_support"
var captions: Array[String] = []
var scene_title := ""
var scene_number := 1
var scene_total := 5
var displayed_caption_index := -1
var caption_tween: Tween
var header_panel: PanelContainer
var footer_panel: PanelContainer
var title_label: Label
var chapter_label: Label
var phase_label: Label
var badge_panel: PanelContainer
var badge_label: Label
var progress_line: ProgressBar
var caption_meta_label: Label
var caption_label: Label
var skip_button: Button
var stage_viewport: SubViewport
var stage_root: Node3D
var scene_group: Node3D
var stage_camera: Camera3D
var astronaut_root: Node3D
var moving_sun: Node3D
var plants: Array[Node3D] = []
var astronaut_start := Vector3.ZERO
var cinematic_center := Vector3(0.0, 1.05, 0.0)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_cinematic_stage()
	header_panel = PanelContainer.new()
	header_panel.position = Vector2(34, 22)
	header_panel.custom_minimum_size = Vector2(730, 106)
	header_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color("07111cd9")
	header_style.border_color = Color("8fae9a")
	header_style.set_border_width_all(1)
	header_style.border_width_left = 5
	header_style.set_corner_radius_all(8)
	header_style.content_margin_left = 22
	header_style.content_margin_right = 22
	header_style.content_margin_top = 12
	header_style.content_margin_bottom = 12
	header_panel.add_theme_stylebox_override("panel", header_style)
	add_child(header_panel)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 18)
	header_panel.add_child(header_row)
	badge_panel = PanelContainer.new()
	badge_panel.custom_minimum_size = Vector2(64, 64)
	badge_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color("14242ddd")
	badge_style.border_color = Color("b7d8bf")
	badge_style.set_border_width_all(1)
	badge_style.set_corner_radius_all(14)
	badge_panel.add_theme_stylebox_override("panel", badge_style)
	header_row.add_child(badge_panel)
	badge_label = _label("", 22, Color("f0e9d9"))
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.add_theme_font_size_override("font_size", 22)
	badge_panel.add_child(badge_label)
	var header_copy := VBoxContainer.new()
	header_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_copy.add_theme_constant_override("separation", 3)
	header_row.add_child(header_copy)
	var chapter_row := HBoxContainer.new()
	chapter_row.add_theme_constant_override("separation", 10)
	header_copy.add_child(chapter_row)
	chapter_label = _label("", 18, Color("bad3a7"))
	chapter_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chapter_row.add_child(chapter_label)
	phase_label = _label("", 14, Color("f2ba90"))
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	chapter_row.add_child(phase_label)
	title_label = _label("", 34, Color("f0e9d9"))
	header_copy.add_child(title_label)
	progress_line = ProgressBar.new()
	progress_line.show_percentage = false
	progress_line.custom_minimum_size = Vector2(180, 5)
	progress_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_line.add_theme_stylebox_override("background", _progress_style(Color("26313b")))
	progress_line.add_theme_stylebox_override("fill", _progress_style(Color("b7d8bf")))
	header_copy.add_child(progress_line)
	footer_panel = PanelContainer.new()
	footer_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer_panel.offset_top = -154
	var footer_style := StyleBoxFlat.new()
	footer_style.bg_color = Color("07111cf0")
	footer_style.border_color = Color("8fae9a")
	footer_style.set_border_width_all(1)
	footer_style.border_width_top = 2
	footer_style.set_corner_radius_all(10)
	footer_style.content_margin_left = 44
	footer_style.content_margin_right = 250
	footer_style.content_margin_top = 24
	footer_style.content_margin_bottom = 24
	footer_panel.add_theme_stylebox_override("panel", footer_style)
	add_child(footer_panel)
	var footer_copy := VBoxContainer.new()
	footer_copy.add_theme_constant_override("separation", 4)
	footer_panel.add_child(footer_copy)
	caption_meta_label = _label("REGISTRO DA TRIPULAÇÃO", 12, Color("bad3a7"))
	footer_copy.add_child(caption_meta_label)
	caption_label = _label("", 26)
	caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer_copy.add_child(caption_label)
	skip_button = Button.new()
	skip_button.text = "PULAR   >"
	skip_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_button.offset_left = -250
	skip_button.offset_right = -48
	skip_button.offset_top = -112
	skip_button.offset_bottom = -38
	skip_button.add_theme_font_size_override("font_size", 20)
	skip_button.add_theme_color_override("font_color", Color("f0e9d9"))
	skip_button.add_theme_color_override("font_hover_color", Color.WHITE)
	skip_button.add_theme_stylebox_override("normal", _button_style(Color("202b36ef"), Color("a3b7c4")))
	skip_button.add_theme_stylebox_override("hover", _button_style(Color("2c3c49f5"), Color("f2ba90")))
	skip_button.add_theme_stylebox_override("pressed", _button_style(Color("16222cf5"), Color("b7d8bf")))
	skip_button.mouse_filter = Control.MOUSE_FILTER_STOP
	skip_button.pressed.connect(_finish)
	add_child(skip_button)
	get_viewport().size_changed.connect(_layout_cinematic_ui)
	_layout_cinematic_ui()
	hide()

func _layout_cinematic_ui() -> void:
	var view := get_viewport_rect().size
	if view.x <= 0.0 or view.y <= 0.0: return
	var scale_factor := clampf(minf(view.x / 1280.0, view.y / 800.0), 0.58, 1.0)
	var margin := 24.0 * scale_factor
	var header_width := minf(view.x * 0.68, 730.0 * scale_factor)
	var skip_width := minf(view.x * 0.31, 202.0 * scale_factor)
	var skip_height := maxf(48.0, 74.0 * scale_factor)
	var footer_height := minf(154.0 * scale_factor, view.y * 0.32)
	header_panel.position = Vector2(margin, margin)
	header_panel.custom_minimum_size = Vector2(maxf(0.0, header_width), 0.0)
	var header_style := header_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if header_style != null:
		header_style.content_margin_left = 18.0 * scale_factor
		header_style.content_margin_right = 18.0 * scale_factor
		header_style.content_margin_top = 10.0 * scale_factor
		header_style.content_margin_bottom = 10.0 * scale_factor
	chapter_label.add_theme_font_size_override("font_size", maxi(12, roundi(18.0 * scale_factor)))
	phase_label.add_theme_font_size_override("font_size", maxi(11, roundi(14.0 * scale_factor)))
	title_label.add_theme_font_size_override("font_size", maxi(20, roundi(34.0 * scale_factor)))
	badge_panel.custom_minimum_size = Vector2(64.0 * scale_factor, 64.0 * scale_factor)
	badge_label.add_theme_font_size_override("font_size", maxi(17, roundi(22.0 * scale_factor)))
	progress_line.custom_minimum_size = Vector2(minf(200.0 * scale_factor, header_width * 0.42), 5.0 * scale_factor)
	footer_panel.offset_top = -footer_height
	var footer_style := footer_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if footer_style != null:
		footer_style.content_margin_left = 28.0 * scale_factor
		footer_style.content_margin_right = skip_width + margin * 2.0
		footer_style.content_margin_top = 12.0 * scale_factor
		footer_style.content_margin_bottom = 12.0 * scale_factor
	caption_meta_label.add_theme_font_size_override("font_size", maxi(10, roundi(12.0 * scale_factor)))
	caption_label.add_theme_font_size_override("font_size", maxi(16, roundi(25.0 * scale_factor)))
	skip_button.offset_left = -skip_width - margin
	skip_button.offset_right = -margin
	skip_button.offset_top = -margin - skip_height
	skip_button.offset_bottom = -margin
	skip_button.add_theme_font_size_override("font_size", maxi(14, roundi(20.0 * scale_factor)))
	if stage_viewport != null:
		stage_viewport.size = Vector2i(maxi(2, roundi(view.x)), maxi(2, roundi(view.y)))
		_update_stage_camera(0.0, true)

func _label(text: String, font_size: int, color: Color = Color("f0e9d9")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _progress_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	return style

func _button_style(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func play_question(question: Dictionary, index: int, total: int) -> void:
	clock = 0.0
	active = true
	stage_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	scene_key = str(question.get("scene", "life_support"))
	scene_title = str(question.get("cutscene_title", "CENA DE TREINAMENTO"))
	scene_number = index + 1
	scene_total = total
	captions.clear()
	for line in question.get("cutscene_captions", []):
		captions.append(str(line))
	if captions.is_empty(): captions.append(str(question.get("question", "")))
	chapter_label.text = "TREINAMENTO DE PRONTIDÃO"
	phase_label.text = "%02d / %02d" % [scene_number, scene_total]
	progress_line.max_value = scene_total
	progress_line.value = scene_number
	badge_label.text = {"life_support": "O₂", "radiation": "UV", "power": "⚡", "food": "BIO", "planning": "NAV"}.get(scene_key, "ISS")
	caption_meta_label.text = "REGISTRO DA TRIPULAÇÃO   ·   %02d:%02d" % [int(clock) / 60, int(clock) % 60]
	title_label.text = scene_title
	caption_label.text = captions[0]
	displayed_caption_index = 0
	header_panel.modulate.a = 0.0
	header_panel.position.x = 24
	footer_panel.modulate.a = 0.0
	var entrance := create_tween().set_parallel(true)
	entrance.tween_property(header_panel, "modulate:a", 1.0, 0.42)
	entrance.tween_property(header_panel, "position:x", 34.0, 0.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entrance.tween_property(footer_panel, "modulate:a", 1.0, 0.38).set_delay(0.12)
	show()
	_build_question_scene()

func _process(delta: float) -> void:
	if not active: return
	clock += delta
	_update_cinematic_animation()
	var caption_index := mini(captions.size() - 1, int(clock / DURATION * captions.size()))
	if caption_index != displayed_caption_index:
		displayed_caption_index = caption_index
		if caption_tween and caption_tween.is_running(): caption_tween.kill()
		caption_tween = create_tween()
		caption_tween.tween_property(caption_label, "modulate:a", 0.0, 0.12)
		caption_tween.tween_callback(_set_caption.bind(caption_index))
		caption_tween.tween_property(caption_label, "modulate:a", 1.0, 0.24)
	caption_meta_label.text = "REGISTRO DA TRIPULAÇÃO   ·   %02d:%02d" % [int(clock) / 60, int(clock) % 60]
	if clock >= DURATION: _finish()

func _unhandled_key_input(event: InputEvent) -> void:
	if active and event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_ESCAPE]:
			_finish()
			get_viewport().set_input_as_handled()

func _finish() -> void:
	if not active: return
	active = false
	stage_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	hide()
	finished.emit()

func _draw() -> void:
	pass

func _build_cinematic_stage() -> void:
	var stage_container := SubViewportContainer.new()
	stage_container.name = "Cinematic3D"
	stage_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_container.stretch = true
	stage_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_viewport = SubViewport.new()
	stage_viewport.size = Vector2i(1280, 800)
	stage_viewport.own_world_3d = true
	stage_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	stage_container.add_child(stage_viewport)
	add_child(stage_container)
	stage_root = Node3D.new()
	stage_root.name = "CinematicWorld"
	stage_viewport.add_child(stage_root)
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("010207")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("9daec1")
	environment.ambient_light_energy = 0.48
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.24
	environment.glow_strength = 0.55
	world_environment.environment = environment
	stage_root.add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -28, 0)
	sun.light_color = Color("ffe2c0")
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	stage_root.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(28, 140, 0)
	fill.light_color = Color("9bbbd2")
	fill.light_energy = 0.32
	stage_root.add_child(fill)
	var rim := OmniLight3D.new()
	rim.light_color = Color("91b7d0")
	rim.light_energy = 1.1
	rim.omni_range = 12.0
	rim.position = Vector3(-4.5, 3.2, 3.2)
	stage_root.add_child(rim)
	stage_camera = Camera3D.new()
	stage_camera.fov = 52.0
	stage_camera.position = Vector3(0, 4.6, 13.5)
	stage_camera.look_at(cinematic_center, Vector3.UP)
	stage_viewport.add_child(stage_camera)
	stage_camera.make_current()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(180, 180)
	var ground := MeshInstance3D.new()
	ground.mesh = ground_mesh
	ground.position.y = -0.18
	ground.material_override = _stage_material(Color("684b3c"))
	stage_root.add_child(ground)
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.075
	star_mesh.height = 0.15
	star_mesh.radial_segments = 6
	star_mesh.rings = 3
	var star_material := _stage_material(Color("d8e4ea"), true)
	star_material.emission_enabled = true
	star_material.emission = Color("adc8da")
	star_material.emission_energy_multiplier = 0.75
	var star_field := MultiMesh.new()
	star_field.transform_format = MultiMesh.TRANSFORM_3D
	star_field.mesh = star_mesh
	star_field.instance_count = 150
	var star_rng := RandomNumberGenerator.new()
	star_rng.seed = 47591
	for index in range(star_field.instance_count):
		var star_transform := Transform3D.IDENTITY
		star_transform.origin = Vector3(star_rng.randf_range(-52.0, 52.0), star_rng.randf_range(5.5, 34.0), -48.0 - star_rng.randf_range(0.0, 12.0))
		var size_factor := star_rng.randf_range(0.35, 1.15)
		star_transform.basis = Basis.IDENTITY.scaled(Vector3.ONE * size_factor)
		star_field.set_instance_transform(index, star_transform)
	var stars := MultiMeshInstance3D.new()
	stars.multimesh = star_field
	stars.material_override = star_material
	stage_root.add_child(stars)
	for side in [-1.0, 1.0]:
		var distant_rock := _spawn_asset("rock_largeA", stage_root, 5.0)
		distant_rock.position = Vector3(side * 10.0, 0.5, -7.0)
		distant_rock.scale *= Vector3(1.7, 0.75, 1.1)

func _stage_material(color: Color, unshaded := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	if unshaded: material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

func _stage_mesh(parent: Node3D, mesh: Mesh, color: Color, position: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _stage_material(color)
	instance.position = position
	parent.add_child(instance)
	return instance

func _stage_box(parent: Node3D, dimensions: Vector3, color: Color, position: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	return _stage_mesh(parent, mesh, color, position)

func _stage_ball(parent: Node3D, radius: float, color: Color, position: Vector3) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 24
	mesh.rings = 12
	return _stage_mesh(parent, mesh, color, position)

func _spawn_asset(asset_name: String, parent: Node3D, size: float) -> Node3D:
	var root := Node3D.new()
	root.name = asset_name
	parent.add_child(root)
	var mesh := load("res://assets/space/" + asset_name + ".obj") as Mesh
	if mesh == null:
		push_warning("Modelo de cutscene não encontrado: " + asset_name)
		return root
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	root.add_child(instance)
	var bounds := mesh.get_aabb()
	var factor := size / maxf(bounds.size.y, 0.01)
	instance.scale = Vector3.ONE * factor
	instance.position.y = -bounds.position.y * factor
	return root

func _build_question_scene() -> void:
	if scene_group != null:
		scene_group.queue_free()
	scene_group = Node3D.new()
	scene_group.name = "QuestionScene"
	stage_root.add_child(scene_group)
	astronaut_root = null
	moving_sun = null
	plants.clear()
	cinematic_center = Vector3(0.0, 1.05, 0.0)
	var dome_position := Vector3(-2.0, 0.0, -1.0)
	match scene_key:
		"life_support":
			_build_dome(dome_position)
			_spawn_asset("machine_generator", scene_group, 0.95).position = Vector3(2.0, 0.0, -1.0)
			_stage_cylinder(Vector3(0.38, 1.35, 0.38), Color("a9c8c1"), Vector3(1.1, 0.68, 0.1))
			_stage_box(scene_group, Vector3(0.42, 0.18, 0.16), Color("718e92"), Vector3(1.1, 1.3, 0.1))
			_add_astronaut(Vector3(-0.2, 0.0, 1.5))
		"radiation":
			cinematic_center = Vector3(0.35, 2.0, -0.8)
			_build_dome(Vector3(-1.5, 0.0, -1.0))
			_add_astronaut(Vector3(0.0, 0.0, 1.1))
			moving_sun = _stage_ball(scene_group, 1.0, Color("f2ba90"), Vector3(4.6, 7.1, -8.0))
			moving_sun.material_override = _stage_material(Color("ffd5a1"), true)
			for ring_index in range(3):
				var pulse_mesh := TorusMesh.new()
				pulse_mesh.inner_radius = 1.3 + ring_index * 0.42
				pulse_mesh.outer_radius = 1.36 + ring_index * 0.42
				var pulse := _stage_mesh(scene_group, pulse_mesh, Color("efa978"), moving_sun.position + Vector3(0, 0, 0.6))
				pulse.material_override = _stage_material(Color("efa978"), true)
		"power":
			for x in range(3):
				var panel := _stage_box(scene_group, Vector3(0.76, 0.09, 0.78), Color("527a98"), Vector3(-2.0 + x * 0.92, 0.65, -1.0))
				panel.rotation.z = -0.18
				_stage_cylinder(Vector3(0.07, 0.45, 0.07), Color("d5d8c6"), Vector3(-2.0 + x * 0.92, 0.27, -1.0))
			_spawn_asset("machine_generator", scene_group, 0.9).position = Vector3(2.2, 0.0, -1.0)
			_add_astronaut(Vector3(0.2, 0.0, 1.2))
			var status_light := _stage_ball(scene_group, 0.18, Color("ef866c"), Vector3(2.2, 1.0, -1.0))
			status_light.material_override = _stage_material(Color("ef866c"), true)
		"food":
			cinematic_center = Vector3(0.65, 1.0, 0.0)
			_build_dome(Vector3(-1.2, 0.0, -1.0))
			for x in range(3):
				var plant_root := Node3D.new()
				plant_root.position = Vector3(-0.1 + x * 0.8, 0.0, -0.7)
				scene_group.add_child(plant_root)
				_stage_box(plant_root, Vector3(0.56, 0.22, 0.62), Color("766d55"), Vector3(0, 0.12, 0))
				var stem := _stage_cylinder(Vector3(0.065, 0.75, 0.065), Color("7eaa79"), Vector3(0, 0.56, 0), plant_root)
				for side in [-1.0, 1.0]:
					var leaf := _stage_ball(plant_root, 0.16, Color("a6c99a"), Vector3(side * 0.18, 0.75, 0))
					leaf.scale = Vector3(1.5, 0.55, 0.7)
				plants.append(plant_root)
				plants.append(stem)
			_add_astronaut(Vector3(2.4, 0.0, 1.2))
			_stage_box(scene_group, Vector3(0.38, 0.5, 0.3), Color("e2ad68"), Vector3(3.4, 0.25, 0.7))
		"planning":
			cinematic_center = Vector3(0.0, 1.0, 0.0)
			_spawn_asset("rover", scene_group, 1.45).position = Vector3(2.6, 0.0, -1.1)
			_add_astronaut(Vector3(-3.4, 0.0, 1.0))
			for marker_index in range(4):
				var marker := _stage_ball(scene_group, 0.11, Color("e9b27f"), Vector3(-2.1 + marker_index * 1.25, 0.18, 0.55))
				marker.material_override = _stage_material(Color("e9b27f"), true)
			var part := _stage_box(scene_group, Vector3(0.5, 0.5, 0.42), Color("9ac2c8"), Vector3(3.7, 0.28, 0.5))
			part.rotation.y = 0.35
	_animate_scene(0.0)

func _build_dome(position: Vector3) -> void:
	var dome_mesh := SphereMesh.new()
	dome_mesh.radius = 1.55
	dome_mesh.height = 2.25
	dome_mesh.radial_segments = 32
	dome_mesh.rings = 16
	var dome := _stage_mesh(scene_group, dome_mesh, Color("c8d0c4"), position + Vector3(0, 0.9, 0))
	dome.scale = Vector3(1.0, 0.76, 1.0)
	var window := _stage_box(scene_group, Vector3(0.66, 0.48, 0.07), Color("65878d"), position + Vector3(-0.35, 0.95, 1.37))
	window.rotation.y = -0.15
	_stage_box(scene_group, Vector3(0.36, 0.92, 0.12), Color("667f83"), position + Vector3(0.75, 0.48, 1.28))
	_stage_ball(scene_group, 0.09, Color("e9c77b"), position + Vector3(0.85, 0.5, 1.36))
	_spawn_asset("satelliteDish_detailed", scene_group, 0.95).position = position + Vector3(-0.65, 1.95, -0.1)

func _stage_cylinder(dimensions: Vector3, color: Color, position: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = dimensions.x
	mesh.bottom_radius = dimensions.z
	mesh.height = dimensions.y
	mesh.radial_segments = 24
	return _stage_mesh(scene_group if parent == null else parent, mesh, color, position)

func _add_astronaut(position: Vector3) -> void:
	astronaut_root = _spawn_asset("astronautA", scene_group, 1.8)
	astronaut_root.position = position
	astronaut_start = position
	astronaut_root.rotation.y = PI

func _update_cinematic_animation() -> void:
	_animate_scene(clock)

func _animate_scene(time: float) -> void:
	if astronaut_root != null:
		astronaut_root.position = astronaut_start + Vector3(0, absf(sin(time * 3.0)) * 0.055, 0)
		astronaut_root.rotation.y = PI + sin(time * 1.35) * 0.09
	if moving_sun != null:
		moving_sun.scale = Vector3.ONE * (1.0 + absf(sin(time * 1.8)) * 0.08)
	for index in range(plants.size()):
		plants[index].rotation.z = sin(time * 1.7 + index) * 0.06
	_update_stage_camera(time)

func _update_stage_camera(time: float, immediate := false) -> void:
	if stage_camera == null or stage_viewport == null: return
	var view := Vector2(stage_viewport.size)
	var aspect := maxf(view.x / maxf(view.y, 1.0), 0.01)
	var horizontal_fov := 2.0 * atan(tan(deg_to_rad(stage_camera.fov * 0.5)) * aspect)
	var distance := maxf(13.5, 8.8 / (2.0 * tan(horizontal_fov * 0.5)))
	var desired := cinematic_center + Vector3(sin(time * 0.24) * 0.2, 3.55, distance + sin(time * 0.32) * 0.16)
	var look_target := cinematic_center + Vector3(0.0, 0.12, 0.0)
	var target_basis := Basis.looking_at((look_target - desired).normalized(), Vector3.UP)
	if immediate:
		stage_camera.position = desired
		stage_camera.basis = target_basis
	else:
		var weight := 1.0 - exp(-2.8 * get_process_delta_time())
		stage_camera.position = stage_camera.position.lerp(desired, weight)
		stage_camera.basis = stage_camera.basis.slerp(target_basis, weight).orthonormalized()

func _set_caption(index: int) -> void:
	caption_label.text = captions[index]
