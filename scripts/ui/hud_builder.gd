extends Node
## Creates the mission HUD and its editor-visible CanvasLayer children.
@export_group("Posicionamento da interface")
@export var logo_position := Vector2(42, 28)
@export var vitals_panel_position := Vector2(22, 64)
@export var vitals_panel_size := Vector2(365, 282)
@export var vitals_content_position := Vector2(42, 76)
@export var objectives_right_margin := 810.0
@export var objectives_top_margin := 28.0
@export var sound_button_right_margin := 118.0
@export var sound_button_top_margin := 160.0
@export var sound_button_size := Vector2(100, 72)
@export var prompt_bottom_margin := 166.0

var game: Node3D

func build(mission: Node3D) -> void:
	game = mission
	game.hud = game.get_node("HUD")
	_build_ui()

func _build_ui() -> void:
	game.vignette = ColorRect.new()
	game.vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.vignette_material = ShaderMaterial.new()
	game.vignette_material.shader = preload("res://shaders/exposure_screen.gdshader")
	game.vignette.material = game.vignette_material
	game.hud.add_child(game.vignette)
	var root := Control.new()
	root.theme = preload("res://scripts/ui/ui_theme.gd").create()
	game.hud_root = root
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.hud.add_child(root)
	root.hide()
	var logo: Label = game._label("ASTRO", 25)
	logo.position = logo_position
	root.add_child(logo)
	var vital_backdrop := Panel.new()
	vital_backdrop.position = vitals_panel_position
	vital_backdrop.size = vitals_panel_size
	vital_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vital_backdrop.add_theme_stylebox_override("panel", game._style(Color("191c21f0"), Color("444b54"), 18))
	root.add_child(vital_backdrop)
	var vitals := VBoxContainer.new()
	game.vitals_ui = vitals
	vitals.position = vitals_content_position
	vitals.add_theme_constant_override("separation", 8)
	root.add_child(vitals)
	game.oxygen_label = game._label("O₂", 24, game.MINT)
	game.food_label = game._label("COMIDA", 24, game.PEACH)
	vitals.add_child(game.oxygen_label)
	game.oxygen_bar = _vital_bar(game.MINT)
	vitals.add_child(game.oxygen_bar)
	vitals.add_child(game.food_label)
	game.food_bar = _vital_bar(game.PEACH)
	vitals.add_child(game.food_bar)
	var objectives := HBoxContainer.new()
	game.objectives_ui = objectives
	objectives.position = Vector2(917, objectives_top_margin)
	objectives.add_theme_constant_override("separation", 12)
	root.add_child(objectives)
	var names := ["FOTOS", "ANTENA", "COMBUST."]
	for i in range(3):
		game.material_icons.append(_make_item_icon(i))
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(250, 116)
		card.add_theme_stylebox_override("panel", preload("res://scripts/ui/ui_theme.gd").box(Color("191c21ed"), Color("444b54"), 12))
		objectives.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var icon := TextureRect.new()
		icon.texture = game.material_icons[i]
		icon.custom_minimum_size = Vector2(80, 80)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var column := VBoxContainer.new()
		row.add_child(column)
		var count_label: Label = game._label("0/%d" % game.GOALS[i], 36, [game.PEACH, game.MINT, game.CREAM][i])
		game.counts.append(count_label)
		column.add_child(count_label)
		column.add_child(game._label(names[i], 20, game.MUTED))
	var mute_button: Button = game._button("Som", func(): game.audio_settings.open())
	mute_button.text = ""
	mute_button.icon = preload("res://assets/ui/gear.svg")
	mute_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.mute_ui = mute_button
	mute_button.position = Vector2(1268, 817)
	mute_button.custom_minimum_size.x = 54
	root.add_child(mute_button)
	game.start_menu = game.hud.get_node("MainMenu")
	game.start_menu.start_requested.connect(Callable(game, "_start"))
	game.start_menu.settings_requested.connect(func(): game.audio_settings.open())
	game.intro = game.hud.get_node("MissionBriefing")
	game.intro.accepted.connect(Callable(game, "_start_game"))
	game.death_panel = game._modal("MISSÃO ENCERRADA", "Cuide das reservas. Tente outra rota.")
	game.death_panel.get_child(0).add_child(game._button("Recomeçar expedição  ", func(): get_tree().reload_current_scene()))
	game.death_panel.hide()
	game.audio_settings = game.hud.get_node("SoundSettings")
	game.audio_settings.visibility_updated.connect(Callable(game, "_update_controls"))

func _make_item_icon(kind: int) -> Texture2D:
	if kind == 0: return preload("res://assets/ui/mars_archive.svg")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(128, 128)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var stage := Node3D.new()
	viewport.add_child(stage)
	if kind == 1:
		game._box(stage, Vector3(0.34, 0.42, 0.28), game.MINT, Vector3(0, 0.23, 0))
		game._box(stage, Vector3(0.36, 0.1, 0.3), Color("607c77"), Vector3(0, 0.28, 0))
	else:
		game._box(stage, Vector3(0.35, 0.48, 0.25), Color("e2ad68"), Vector3(0, 0.24, 0))
		game._box(stage, Vector3(0.18, 0.08, 0.17), Color("576d76"), Vector3(0.06, 0.51, 0))
		game._box(stage, Vector3(0.37, 0.08, 0.27), Color("f1d7aa"), Vector3(0, 0.25, 0))
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
	bar.max_value = game.MAX_RESERVE
	bar.value = game.MAX_RESERVE
	bar.show_percentage = false
	var track: StyleBoxFlat = game._style(Color("11151a"), Color("444b54"), 8)
	var fill: StyleBoxFlat = game._style(color, Color.TRANSPARENT, 7)
	for style in [track, fill]:
		style.content_margin_left = 0
		style.content_margin_right = 0
		style.content_margin_top = 0
		style.content_margin_bottom = 0
	bar.add_theme_stylebox_override("background", track)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

