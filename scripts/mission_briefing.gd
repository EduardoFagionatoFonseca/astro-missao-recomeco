extends Control
signal accepted
var panel: PanelContainer
var content: VBoxContainer
var controls_label: Label
var page_label: Label
var title_label: Label
var body: VBoxContainer
var next_button: Button
var back_button: Button
var page_index := 0
var item_icons: Array[Texture2D] = []
var page_tween: Tween

func _ready() -> void:
	theme = preload("res://scripts/ui_theme.gd").create()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color("030405ec")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", preload("res://scripts/ui_theme.gd").box(Color("17191dfc"), Color("494e56"), 34))
	add_child(panel)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 24)
	panel.add_child(content)
	page_label = _text(content, "", 22, Color("bad3a7"))
	title_label = _text(content, "", 46)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 26)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body)
	controls_label = _text(content, "", 27, Color("adb4b8"))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 20)
	content.add_child(buttons)
	back_button = Button.new()
	back_button.text = "VOLTAR"
	back_button.custom_minimum_size = Vector2(200, 82)
	back_button.pressed.connect(func(): page_index = 0; _render())
	buttons.add_child(back_button)
	next_button = Button.new()
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_button.custom_minimum_size.y = 98
	next_button.pressed.connect(_next)
	buttons.add_child(next_button)
	get_viewport().size_changed.connect(_layout)
	_layout()
	hide()

func _text(parent: Node, text: String, size: int, color := Color("f2f1e9")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _step(title: String, text: String) -> void:
	var column := VBoxContainer.new()
	body.add_child(column)
	_text(column, title, 30)
	_text(column, text, 28, Color("adb4b8"))

func configure(icons: Array[Texture2D], mobile: bool) -> void:
	item_icons = icons
	controls_label.text = "Joystick mover   /   Saltar: subir plataformas   /   Toque usar" if mobile else "WASD mover   /   Espaço: subir plataformas   /   E usar"
	_render()

func open() -> void:
	page_index = 0
	_render()
	show()

func _next() -> void:
	if page_index == 0:
		page_index = 1
		_render()
	else:
		accepted.emit()

func _render() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	page_label.text = "GUIA DA MISSÃO   /   %d DE 2" % (page_index + 1)
	title_label.text = "Explore. Reúna. Sobreviva." if page_index == 0 else "Seu abrigo mantém você vivo."
	back_button.visible = page_index == 1
	next_button.text = "PRÓXIMO  >" if page_index == 0 else "COMEÇAR"
	if page_index == 0:
		_step("PRIMEIRO, O SINAL", "Reúna 6 peças de antena. Ative a transmissão na base.")
		var materials := HBoxContainer.new()
		body.add_child(materials)
		for i in range(item_icons.size()):
			var row := HBoxContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			materials.add_child(row)
			var icon := TextureRect.new()
			icon.texture = item_icons[i]
			icon.custom_minimum_size = Vector2(72, 72)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(icon)
			_text(row, ["5 pedras", "6 peças", "8 combustíveis"][i], 28)
		_step("DEPOIS, O RESGATE", "O sinal revela pedras e combustível. Reúna tudo para partir.")
	else:
		_step("ENERGIA E RESERVAS", "Energia gera O₂. Estufa repõe comida. Repare aos 30%.")
		_step("MANTENHA O SINAL", "Sem comunicação, recursos restantes e avisos ficam ocultos.")
		_step("NÉVOA SOLAR", "Janela acesa? Fique dentro. Exposição mata em 3 s.")
	if page_tween: page_tween.kill()
	body.modulate.a = 0
	page_tween = create_tween()
	page_tween.tween_property(body, "modulate:a", 1.0, 0.2)

func _layout() -> void:
	var view := get_viewport_rect().size
	panel.position = view * 0.08
	panel.size = view * 0.84
