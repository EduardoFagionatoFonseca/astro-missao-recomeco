extends Control
signal start_requested
signal settings_requested
var content: VBoxContainer
var actions: PanelContainer
var start: Button
var gear: Button

func _ready() -> void:
	theme = preload("res://scripts/ui_theme.gd").create()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var art := TextureRect.new()
	art.texture = preload("res://assets/ui/menu-mars-2d.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ float edge=0.28+0.22*smoothstep(0.45,1.0,UV.y); COLOR=vec4(0.015,0.035,0.06,edge); }"
	material.shader = shader
	shade.material = material
	add_child(shade)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	add_child(content)
	_text("MARTE  /  UMA NOVA CHANCE", 22, Color("bad3a7"))
	_text("ASTRO", 124)
	_text("Um pequeno recomeço.", 38)
	_text("Explore Marte. Cuide do abrigo. Volte para casa.", 26, Color("b8c2c8"))
	actions = PanelContainer.new()
	actions.add_theme_stylebox_override("panel", preload("res://scripts/ui_theme.gd").box(Color("111e2aeb"), Color("738e92"), 24))
	add_child(actions)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 14)
	actions.add_child(stack)
	var hint := Label.new()
	hint.text = "UMA MISSÃO. UM SINAL. UM RECOMEÇO."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color("bad3a7"))
	stack.add_child(hint)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	stack.add_child(row)
	var balance := Control.new()
	balance.custom_minimum_size.x = 112
	row.add_child(balance)
	start = Button.new()
	start.text = "COMEÇAR   >"
	start.custom_minimum_size = Vector2(560, 112)
	start.add_theme_font_size_override("font_size", 36)
	start.pressed.connect(func(): start_requested.emit())
	row.add_child(start)
	gear = Button.new()
	gear.icon = preload("res://assets/ui/gear.svg")
	gear.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gear.custom_minimum_size = Vector2(112, 112)
	gear.tooltip_text = "Configurações de som"
	gear.pressed.connect(func(): settings_requested.emit())
	row.add_child(gear)
	get_viewport().size_changed.connect(_layout)
	content.resized.connect(_layout)
	actions.resized.connect(_layout)
	_layout()

func _text(text: String, size: int, color := Color("f2f1e9")) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	content.add_child(label)

func _layout() -> void:
	var view := get_viewport_rect().size
	content.position = Vector2((view.x - content.size.x) / 2, view.y * 0.09)
	actions.position = Vector2((view.x - actions.size.x) / 2, view.y - actions.size.y - 38)
