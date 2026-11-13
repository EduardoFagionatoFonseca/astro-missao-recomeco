extends Node3D
## A gentle exploration game on a complete spherical world.

@export_group("Regras e sobrevivência")
@export_range(1.0, 100.0, 0.5) var R: float = 32.0
@export var GOALS: Array[int] = [8, 6, 8]
@export_range(1, 1000, 1) var TOTAL: int = 22
@export_range(0.0, 20.0, 0.1) var OXYGEN_RATE: float = 1.18
@export_range(0.0, 20.0, 0.1) var FOOD_RATE: float = 0.78
@export_range(1.0, 150.0, 0.5) var MAX_RESERVE: float = 105.0
@export_range(0.1, 30.0, 0.1) var EXPOSURE_LIMIT: float = 3.0
@export_range(0.0, 30.0, 0.1) var VITAL_GRACE: float = 3.0
@export_range(0.1, 20.0, 0.1) var SHELTER_RADIUS: float = 3.1

@export_group("Ciclos de eventos")
@export_range(1.0, 600.0, 0.5) var SOLAR_INTERVAL: float = 100.0
@export_range(1.0, 60.0, 0.5) var SOLAR_WARNING: float = 5.0
@export_range(1.0, 60.0, 0.5) var SOLAR_DURATION: float = 12.0
@export_range(1.0, 600.0, 0.5) var ENERGY_INTERVAL: float = 63.75
@export_range(1.0, 600.0, 0.5) var SIGNAL_INTERVAL: float = 85.0

@export_group("Movimentação")
@export_range(0.1, 20.0, 0.01) var MOVE_SPEED: float = 5.8401
@export_range(2.0, 12.0, 0.1) var THIRD_PERSON_DISTANCE := 8.0
@export_range(1.0, 10.0, 0.1) var THIRD_PERSON_HEIGHT := 6.6
@export_range(35.0, 75.0, 1.0) var THIRD_PERSON_FOV := 44.0
@export_range(1.0, 12.0, 0.1) var CAMERA_POSITION_SMOOTHING := 3.8
@export_range(1.0, 12.0, 0.1) var CAMERA_ROTATION_SMOOTHING := 4.6

@export_group("Música")
@export_range(0.0, 1.0, 0.01) var PLANET_MUSIC_GAIN: float = 0.16
@export_range(0.0, 1.0, 0.01) var BASE_MUSIC_GAIN: float = 0.24

@export_group("Paleta da interface e do mundo")
@export var CREAM: Color = Color("f0e9d9")
@export var MUTED: Color = Color("a3b7c4")
@export var PEACH: Color = Color("f2ba90")
@export var MINT: Color = Color("b7d8bf")
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
var terrain := preload("res://scripts/world/planet_terrain.gd").new()
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
var oxygen := 105.0
var food := 105.0
var exposure := 0.0
var camp_normal := Vector3(0.07, 1, 0.12).normalized()
var garden_normal := Vector3(0.9, -0.15, -0.5).normalized()
var solar_clock := 0.0
var solar_phase := "calm"
var solar_remaining := 100.0
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
var survival_timer: PanelContainer
var survival_timer_label: Label
var qa_clock := 0.0
var guide: Control
var task_question: Control
var oxygen_question_pending := false
var mission_map: Control
var photo_archive: Control
var returning_to_menu := false
var first_person := false

func _pressure() -> float:
	return GameOptions.pressure(float(collected) / TOTAL)

func _ready() -> void:
	terrain.R = R
	oxygen = MAX_RESERVE
	food = MAX_RESERVE
	solar_remaining = SOLAR_INTERVAL
	auto_check = "--smoke-test" in OS.get_cmdline_user_args() and not Engine.has_meta("astro_smoke_completed")
	if auto_check:
		GameOptions.difficulty = 1
		GameOptions.chase_camera = false
		TranslationServer.set_locale("pt_BR")
	capture = "--capture" in OS.get_cmdline_user_args() or "--capture-intro" in OS.get_cmdline_user_args() or "--capture-fog" in OS.get_cmdline_user_args() or "--capture-critical" in OS.get_cmdline_user_args() or "--capture-base" in OS.get_cmdline_user_args() or "--capture-power" in OS.get_cmdline_user_args() or "--capture-signal" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-"): capture = true
	$World.build(self)
	for child in $World.get_children():
		if child is Node3D and not child is Light3D: exterior_nodes.append(child)
	avatar = $Actors/Avatar
	camera = $Actors/Camera3D
	astronaut = _asset("astronautA", avatar, 1.8)
	# Kenney's astronaut faces +Z; the movement frame faces -Z.
	astronaut.rotation.y = PI
	avatar.position = normal * R
	_align(avatar, normal, north)
	camera.fov = THIRD_PERSON_FOV
	camera.near = 0.1
	camera.far = 350.0
	_update_third_person_camera(false)
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
		camera.fov = THIRD_PERSON_FOV
		_update_third_person_camera(false)
	if "--capture-warning" in OS.get_cmdline_user_args():
		solar_phase = "warning"
		solar_clock = 2
		solar_remaining = SOLAR_WARNING - solar_clock
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
		load("res://tests/mission_flow.gd").new().run(self)
		load("res://tests/countdowns_audio.gd").new().run(self)
		load("res://tests/survival_tuning.gd").new().run(self)
		load("res://tests/terrain_mobile.gd").new().run(self)
		load("res://tests/radio_resources.gd").new().run(self)
		load("res://tests/progression_guidance.gd").new().run(self)
		for i in range(TOTAL): _collect(i)
		assert(collected == TOTAL and found == GOALS and ship != null)
		ship_timer = 12.0
		_update_ship(0.1)
		assert(ship_landed)
		normal = ship_normal
		_interact()
		assert(won and outro_video.active and not start_menu.visible)
		Engine.set_meta("astro_smoke_completed", true)
		var watcher: Node = load("res://tests/menu_return.gd").new()
		get_tree().root.add_child(watcher)
		watcher.watch()
		outro_video._finish()
		return
	_update_controls()
	if portrait_hint.visible or task_question.visible or photo_archive.is_open() or returning_to_menu: return
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
	if oxygen_question_pending and controls.enabled:
		oxygen_question_pending = false
		_ask_task("oxygen")
	_update_items(delta)
	_update_ship(delta)
	_update_hud(delta)
	_update_prompt()
	guide.update_guide(self, delta)
	mission_map.refresh()

func _update_movement(delta: float) -> void:
	$ExplorationSystem.update_movement(delta)

func _item_available(item: Dictionary) -> bool:
	return $ExplorationSystem.item_available(item)

func _sync_resource_visibility() -> void:
	$ExplorationSystem.sync_resource_visibility()

func _can_reach(item: Dictionary) -> bool:
	return $ExplorationSystem.can_reach(item)

func _nearest() -> int:
	return $ExplorationSystem.nearest()

func _update_items(delta: float) -> void:
	$ExplorationSystem.update_items(delta)

func _collect(index: int) -> void:
	$ExplorationSystem.collect(index)

func _try_rescue() -> void:
	$ExplorationSystem.try_rescue()

func _update_ship(delta: float) -> void:
	$ExplorationSystem.update_ship(delta)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if intro_video.active or outro_video.active or audio_settings.visible or task_question.visible or photo_archive.is_open() or portrait_hint.visible: return
		if event.physical_keycode == KEY_V and controls.enabled and not inside:
			first_person = not first_person
			$ExplorationSystem.chase.reset()
			_update_camera_mode()
			feedback.notice_message("camera_mode", "Visão em primeira pessoa (V)" if first_person else "Visão de exploração (V)", false)
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == KEY_M and controls.enabled and not inside:
			mission_map.toggle_expanded()
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == KEY_ESCAPE and playing and not won and not dead:
			if minigames.visible: minigames.close()
			else: audio_settings.open()
			get_viewport().set_input_as_handled()

func _interact() -> void:
	$ExplorationSystem.interact()

func _at_camp() -> bool:
	return inside or normal.dot(camp_normal) > cos(SHELTER_RADIUS / R)

func _at_garden() -> bool:
	return normal.dot(garden_normal) > cos(2.4 / R)

func _update_survival(delta: float) -> void:
	$SurvivalSystem.update_survival(delta)

func _update_radiation(delta: float) -> void:
	$SurvivalSystem.update_radiation(delta)

func _resource_warnings(delta := 0.0) -> void:
	$SurvivalSystem.update_resource_warnings(delta)

func _update_last_chance(delta: float) -> void:
	$SurvivalSystem.update_last_chance(delta)

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
	world_environment.background_color = Color("010207").lerp(Color("050912"), brightness * 0.35)
	world_environment.ambient_light_energy = 0.22 + brightness * 0.05
	if feedback != null: feedback.solar_intensity(brightness, inside)
	distant_light.scale = Vector3.ONE * (0.5 + activity * 1.3)
	distant_halo.scale = Vector3.ONE * (0.7 + activity * 1.2)
	distant_halo.material_override.albedo_color = Color(1.0, 0.6, 0.27, activity * 0.65)

func _style(color: Color, border := Color.TRANSPARENT, radius := 18) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(mini(radius, 18))
	box.shadow_color = Color("00000055")
	box.shadow_size = 5
	box.shadow_offset = Vector2(0, 3)
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 18
	box.content_margin_bottom = 18
	return box

func _label(text: String, font_size: int, color := CREAM) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", roundi(font_size * 1.12))
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.theme = preload("res://scripts/ui/ui_theme.gd").create()
	button.text = text
	button.custom_minimum_size.y = 96
	button.add_theme_font_size_override("font_size", 30)
	button.pressed.connect(callback)
	return button

func _modal(title: String, subtitle: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme = preload("res://scripts/ui/ui_theme.gd").create()
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
	$HUD/HUDBuilder.build(self)

func _start() -> void:
	start_menu.hide()
	if auto_check or capture:
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
	food_label.text = tr("COMIDA") + "   " + str(ceili(_percent(food))) + "%"
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
	var grace := clampf(maxf(oxygen_empty_time, food_empty_time) / VITAL_GRACE, 0, 1)
	power_label.add_theme_color_override("font_color", Color("ef7777") if energy_charge <= 30 else MINT)
	power_label.modulate.a = 0.72 + pulse * 0.28 if energy_charge <= 30 else 1.0
	var intensity := depleted * 0.65 + grace * 0.3
	if dead: intensity = 0.98
	vignette_material.set_shader_parameter("intensity", intensity)
	vignette_material.set_shader_parameter("radiation", clampf(exposure / EXPOSURE_LIMIT, 0, 1) if not inside and not dead and solar_phase == "active" else 0.0)
	_update_survival_timer()

func _update_camera_mode() -> void:
	var outside_first_person := first_person and not inside
	astronaut.visible = not outside_first_person
	if inside:
		camera.fov = 44.0
	elif outside_first_person:
		camera.fov = 68.0
	else:
		camera.fov = 36.0 if controls.mobile else THIRD_PERSON_FOV

func _update_third_person_camera(smooth: bool = true, delta: float = 1.0) -> void:
	if camera == null or avatar == null: return
	# Keep the follow camera on a stable compass heading. Following the astronaut's
	# facing direction makes camera-relative controls orbit and feel unpredictable.
	var forward_reference := north.slide(normal).normalized()
	if forward_reference.length() < 0.1:
		forward_reference = -avatar.global_basis.z.slide(normal).normalized()
	var backward := -forward_reference
	var target := avatar.global_position + normal * 1.25
	var framing := 0.85 if controls != null and controls.mobile else 1.0
	var desired := avatar.global_position + (normal * THIRD_PERSON_HEIGHT + backward * THIRD_PERSON_DISTANCE) * framing
	_update_camera_transform(desired, target, normal, smooth, delta)

func _update_camera_transform(desired: Vector3, target: Vector3, up: Vector3, smooth: bool, delta: float) -> void:
	var target_basis := Basis.looking_at((target - desired).normalized(), up.normalized())
	if smooth:
		var position_weight := 1.0 - exp(-CAMERA_POSITION_SMOOTHING * delta)
		var rotation_weight := 1.0 - exp(-CAMERA_ROTATION_SMOOTHING * delta)
		camera.global_position = camera.global_position.lerp(desired, position_weight)
		camera.global_basis = camera.global_basis.slerp(target_basis, rotation_weight).orthonormalized()
	else:
		camera.global_position = desired
		camera.global_basis = target_basis

func _update_survival_timer() -> void:
	var lines: Array[String] = []
	if playing and not dead and not won:
		if solar_phase == "warning" and not inside:
			lines.append(tr("NÉVOA SOLAR EM") + "   %.1f s" % maxf(0.0, solar_remaining))
		if solar_phase == "active" and not inside:
			lines.append(tr("RADIAÇÃO") + "   %.1f s" % maxf(0, EXPOSURE_LIMIT - exposure))
		if oxygen <= 0.0 and not (_at_camp() and energy_ready):
			lines.append("O₂   %.1f s" % (oxygen / OXYGEN_RATE + maxf(0, VITAL_GRACE - oxygen_empty_time)))
		if food <= 0.0:
			lines.append(tr("COMIDA") + "   %.1f s" % maxf(0, VITAL_GRACE - food_empty_time))
	survival_timer.visible = not lines.is_empty()
	survival_timer_label.text = "\n".join(lines)
	if GameOptions.language == "pt_BR": survival_timer_label.text = survival_timer_label.text.replace(".", ",")
	survival_timer.reset_size()
	var view := get_viewport().get_visible_rect().size
	survival_timer.position = Vector2((view.x - survival_timer.size.x) / 2, view.y - 170)

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

func _return_to_menu() -> void:
	if returning_to_menu: return
	returning_to_menu = true
	playing = false
	_update_controls()
	get_tree().call_deferred("reload_current_scene")

func _build_audio() -> void:
	$AudioManager.build()

func _update_music(delta: float) -> void:
	$AudioManager.update_music(delta)

func _chime(frequency: float) -> void:
	$AudioManager.play_chime(frequency)

func _mute() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)

func _build_expansion() -> void:
	base_room = $BaseInterior
	controls = hud.get_node("PlayerInput")
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
	feedback = hud.get_node("MissionFeedback")
	feedback.typing_tick.connect(func(): event_audio.play("typing"))
	feedback.transmission_started.connect(func(): event_audio.play("radio"))
	guide = hud.get_node("FirstSteps")
	task_question = hud.get_node("TaskQuestion")
	task_question.closed.connect(_update_controls)
	mission_map = hud.get_node("MissionMap")
	mission_map.configure(self)
	photo_archive = preload("res://scripts/ui/mars_archive.gd").new()
	photo_archive.name = "MarsArchive"
	hud.add_child(photo_archive)
	photo_archive.visibility_updated.connect(_update_controls)
	audio_settings.menu_requested.connect(_return_to_menu)
	GameOptions.camera_changed.connect($ExplorationSystem.chase.reset)
	hud.move_child(audio_settings, -1)
	minigames = hud.get_node("BaseMinigames")
	minigames.power_repaired.connect(_on_power_repaired)
	minigames.signal_sent.connect(_on_signal_sent)
	minigames.closed.connect(_update_controls)
	survival_timer = PanelContainer.new()
	survival_timer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	survival_timer.custom_minimum_size.x = 420
	survival_timer.add_theme_stylebox_override("panel", _style(Color("211c19ef"), Color("ce8758"), 4))
	survival_timer_label = _label("", 30, PEACH)
	survival_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	survival_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	survival_timer.add_child(survival_timer_label)
	hud.add_child(survival_timer)
	survival_timer.hide()
	intro_video = hud.get_node("IntroVideo")
	intro_video.finished.connect(_show_briefing)
	outro_video = hud.get_node("OutroVideo")
	outro_video.finished.connect(_return_to_menu)
	intro.configure(material_icons, controls.mobile)
	GameOptions.language_changed.connect(func():
		prompt_target = ""
		intro.configure(material_icons, controls.mobile)
	)
	hud.move_child(task_question, -1)
	portrait_hint = PanelContainer.new()
	portrait_hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait_hint.add_theme_stylebox_override("panel", _style(Color("101215")))
	var rotate_text := _label(tr("Gire o celular para retomar a missão."), 48, CREAM)
	GameOptions.language_changed.connect(func(): rotate_text.text = tr("Gire o celular para retomar a missão."))
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
	for modal in [death_panel]:
		modal.resized.connect(_center_modal.bind(modal))
	_layout_ui()
	_update_controls()

func _layout_ui() -> void:
	var view := get_viewport().get_visible_rect().size
	var ui_layout: Node = $HUD/HUDBuilder
	objectives_ui.position = Vector2(view.x - ui_layout.objectives_right_margin, ui_layout.objectives_top_margin)
	controls._layout()
	mission_map._layout()
	_update_camera_mode()
	mute_ui.position = Vector2(view.x - ui_layout.sound_button_right_margin, ui_layout.sound_button_top_margin)
	mute_ui.custom_minimum_size = ui_layout.sound_button_size
	prompt.position = Vector2((view.x - 450) / 2, view.y - ui_layout.prompt_bottom_margin)
	for modal in [death_panel]: _center_modal(modal)
	portrait_hint.visible = controls.mobile and view.y > view.x
	_update_controls()

func _center_modal(modal: Control) -> void:
	modal.position = (get_viewport().get_visible_rect().size - modal.size) / 2

func _update_controls() -> void:
	if controls == null: return
	minigames.frozen = portrait_hint.visible or audio_settings.visible
	var archive_open: bool = photo_archive.is_open()
	var active := playing and not returning_to_menu and not archive_open and not dead and not won and not transitioning and not minigames.visible and not portrait_hint.visible and not audio_settings.visible and not task_question.visible
	controls.set_enabled(active)
	photo_archive.visible = archive_open or active
	controls.jump_available = not inside
	_sync_resource_visibility()
	if feedback.link_online != communications_online: feedback.set_link(communications_online)
	feedback.active = playing and not dead and not won
	if not active:
		prompt.hide()
		prompt_target = ""
	base_status.visible = playing and not intro_video.active and not won and not dead
	power_label.visible = base_status.visible
	power_label.text = tr("ENERGIA %d%%") % energy_charge if energy_ready else tr("ENERGIA OFF / O₂ OFF")
	base_status.text = tr("RÁDIO ONLINE") if communications_online else tr("RÁDIO OFFLINE")
	if mission_map != null:
		mission_map.visible = not archive_open and playing and not dead and not won and not inside and not intro_video.active and not minigames.visible and not audio_settings.visible and not task_question.visible and not portrait_hint.visible

func _publish_web_test_state() -> void:
	var forward := (-camera.global_basis.z).slide(normal).normalized()
	var right := camera.global_basis.x.slide(normal).normalized()
	var state := {"normal": [normal.x, normal.y, normal.z], "right": [right.x, right.y, right.z], "forward": [forward.x, forward.y, forward.z], "inside": inside, "hop": hop, "altitude": altitude, "floor": terrain.height_at(normal), "mobile": controls.mobile, "enabled": controls.enabled, "stick": controls.stick_id, "playing": playing, "dead": dead, "oxygen": oxygen, "platform": [terrain.platforms[0].normal.x, terrain.platforms[0].normal.y, terrain.platforms[0].normal.z], "camp": [camp_normal.x, camp_normal.y, camp_normal.z], "position": [avatar.position.x, avatar.position.y, avatar.position.z]}
	state["language"] = GameOptions.language
	state["difficulty"] = GameOptions.difficulty
	state["pressure"] = _pressure()
	state["guide"] = guide.hint.text if guide.visible else ""
	state["objective"] = guide.objective_id
	state["route_points"] = guide.route.size()
	state["logical_size"] = [get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y]
	state["camera_fov"] = camera.fov
	state["action_rect"] = [controls.action_rect.position.x, controls.action_rect.position.y, controls.action_rect.size.x, controls.action_rect.size.y]
	state["jump_rect"] = [controls.jump_rect.position.x, controls.jump_rect.position.y, controls.jump_rect.size.x, controls.jump_rect.size.y]
	state["elapsed"] = elapsed
	state["settings"] = audio_settings.visible
	state["caption"] = intro_video.caption.text if intro_video.active else ""
	JavaScriptBridge.eval("window.__astroQA = %s;" % JSON.stringify(state))

func _jump() -> void:
	if controls.enabled and not inside and hop == 0 and hop_velocity == 0: hop_velocity = 2.4

func _update_prompt() -> void:
	if not controls.enabled: return
	var target := ""
	var text := ""
	if inside:
		target = base_room.station_at(avatar.position)
		if target == "signal" and signal_transmitted and communications_online: target = ""
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
			target = "photo" if items[near].kind == 0 else "collect"
			text = "Coletar foto" if target == "photo" else "Coletar material"
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
		prompt.text = ("" if controls.mobile else "[E] ") + tr(text)
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
	if to_inside and solar_phase != "calm": _ask_task("radiation")

func _apply_location(to_inside: bool) -> void:
	if to_inside:
		exterior_normal = normal
		exterior_north = north
	inside = to_inside
	_update_camera_mode()
	if inside: exposure = 0.0
	hop = 0
	altitude = 0.0 if inside else terrain.height_at(exterior_normal)
	hop_velocity = 0
	base_room.visible = inside
	for node in exterior_nodes: node.visible = not inside
	_sync_resource_visibility()
	if ship != null: ship.visible = not inside
	if inside:
		avatar.position = base_room.position + Vector3(0, 0, 2.6)
		avatar.basis = Basis.IDENTITY
		camera.global_position = avatar.global_position + Vector3(0, 3.0, 5.5)
		camera.look_at(avatar.global_position + Vector3(0, 1.0, -0.4), Vector3.UP)
	else:
		normal = exterior_normal
		north = exterior_north
		avatar.position = normal * (R + altitude)
		_align(avatar, normal, north)
		$ExplorationSystem.update_exterior_camera(false, 0.0)
	solar_fog.visible = not inside and solar_phase == "active"
	_update_distant_light()
	base_room.set_power(energy_ready, energy_charge)
	base_room.set_solar(solar_phase)
	controls.reset()
	prompt_target = ""

func _update_indoor_movement(delta: float) -> void:
	var input: Vector2 = controls.direction()
	var forward := (-camera.global_basis.z).slide(Vector3.UP).normalized()
	var right := camera.global_basis.x.slide(Vector3.UP).normalized()
	var direction := right * input.x + forward * input.y
	avatar.position = base_room.move_player(avatar.position, direction * MOVE_SPEED * delta)
	if direction.length() > 0.05:
		_align(avatar, Vector3.UP, direction)
		walk += delta * 8
	astronaut.position.y = absf(sin(walk)) * input.length() * 0.055
	astronaut.rotation.z = sin(walk) * input.length() * 0.045
	var camera_back := Vector3.BACK
	var camera_target := avatar.global_position + Vector3(0, 1.0, 0)
	var camera_desired := avatar.global_position + Vector3(0, 3.0, 0) + camera_back * 5.5
	_update_camera_transform(camera_desired, camera_target, Vector3.UP, true, delta)

func _update_solar_notices() -> void:
	if not communications_online: return
	if solar_phase == "warning" and solar_clock >= SOLAR_WARNING - 5:
		var seconds := ceili(SOLAR_WARNING - solar_clock)
		feedback.transmit("solar_warning_%d" % solar_cycle, tr("Radiação em %d s. Entre no abrigo.") % seconds, true, feedback.AXIOS, true, true)

func _update_energy(delta: float) -> void:
	$MissionProgression.advance(delta)

func _on_power_repaired() -> void:
	$MissionProgression.power_repaired()
	if _ask_task("power"): minigames.close()

func _on_signal_sent() -> void:
	$MissionProgression.signal_sent()
	if signal_transmitted: _ask_task("signal")

func _ask_task(task: String) -> bool:
	if not playing or dead or won or capture or "--smoke-test" in OS.get_cmdline_user_args(): return false
	if not task_question.open_task(task): return false
	_update_controls()
	return true

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
		avatar.position = normal * R
		_align(avatar, normal, north)
		_update_third_person_camera(false)
		var expected: Vector3 = (camera.basis.x.slide(normal).normalized() * input_direction.x + (-camera.basis.z).slide(normal).normalized() * input_direction.y).normalized()
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
	_update_third_person_camera(false)

func _assert_survival() -> void:
	normal = Vector3.DOWN
	energy_ready = true
	oxygen = MAX_RESERVE
	food = MAX_RESERVE
	_update_survival(10)
	assert(is_equal_approx(oxygen, MAX_RESERVE - 10.0 * OXYGEN_RATE * _pressure()))
	assert(is_equal_approx(food, MAX_RESERVE - 10.0 * FOOD_RATE * _pressure()))
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
	_update_radiation(EXPOSURE_LIMIT - 0.01)
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
	_update_last_chance(3.01)
	assert(dead and collected == previous_items)
	dead = false
	death_panel.hide()
	oxygen = MAX_RESERVE
	food = 0
	_update_last_chance(3.01)
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

