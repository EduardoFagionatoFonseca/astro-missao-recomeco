extends Control
signal start_requested
signal settings_requested
var content: VBoxContainer

func _ready() -> void:
	theme = preload("res://scripts/ui_theme.gd").create()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var art := TextureRect.new()
	art.texture = preload("res://assets/ui/menu-mars.png")
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
	shader.code = "shader_type canvas_item; void fragment(){ COLOR=vec4(0.015,0.035,0.06,mix(0.65,0.02,smoothstep(0.0,0.85,UV.x))); }"
	material.shader = shader
	shade.material = material
	add_child(shade)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 22)
	add_child(content)
	_text("MARTE  /  UMA NOVA CHANCE", 22, Color("bad3a7"))
	_text("ASTRO", 112)
	_text("Um pequeno recomeço.", 34)
	var gap := Control.new()
	gap.custom_minimum_size.y = 24
	content.add_child(gap)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	content.add_child(row)
	var start := Button.new()
	start.text = "COMEÇAR   >"
	start.custom_minimum_size = Vector2(420, 90)
	start.pressed.connect(func(): start_requested.emit())
	row.add_child(start)
	var gear := Button.new()
	gear.icon = preload("res://assets/ui/gear.svg")
	gear.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gear.custom_minimum_size = Vector2(90, 90)
	gear.tooltip_text = "Configurações de som"
	gear.pressed.connect(func(): settings_requested.emit())
	row.add_child(gear)
	_text("Mantenha o sinal. Encontre o caminho de volta.", 22, Color("b8c2c8"))
	get_viewport().size_changed.connect(_layout)
	_layout()

func _text(text: String, size: int, color := Color("f2f1e9")) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	content.add_child(label)

func _layout() -> void:
	content.position = Vector2(get_viewport_rect().size.x * 0.085, get_viewport_rect().size.y * 0.24)
