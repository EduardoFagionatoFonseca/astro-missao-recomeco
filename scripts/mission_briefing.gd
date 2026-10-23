extends Control
signal accepted
var panel: PanelContainer
var content: VBoxContainer
var controls_label: Label
var material_row: HBoxContainer

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
	content.add_theme_constant_override("separation", 20)
	panel.add_child(content)
	_text("GUIA DA MISSÃO", 22, Color("bad3a7"))
	_text("Seu abrigo. Sua sobrevivência.", 46)
	_step("01", "EXPLORE", "Reúna 6 de cada item para o resgate.")
	material_row = HBoxContainer.new()
	material_row.add_theme_constant_override("separation", 24)
	content.add_child(material_row)
	_step("02", "MANTENHA", "Energia produz O₂. Comida vem da estufa.")
	_step("03", "OBSERVE", "Janela acesa: radiação. Antena ligada: avisos.")
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	controls_label = _text("WASD mover   /   Espaço saltar   /   E usar", 27, Color("adb4b8"))
	var confirm := Button.new()
	confirm.text = "ENTENDI / EXPLORAR"
	confirm.custom_minimum_size.y = 82
	confirm.pressed.connect(func(): accepted.emit())
	content.add_child(confirm)
	get_viewport().size_changed.connect(_layout)
	_layout()
	hide()

func _text(text: String, size: int, color := Color("f2f1e9")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	content.add_child(label)
	return label

func _step(number: String, title: String, text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	content.add_child(row)
	var index := Label.new()
	index.text = number
	index.add_theme_font_size_override("font_size", 44)
	index.add_theme_color_override("font_color", Color("616e66"))
	row.add_child(index)
	var column := VBoxContainer.new()
	row.add_child(column)
	for entry in [[title, 30, Color("f2f1e9")], [text, 28, Color("adb4b8")]]:
		var label := Label.new()
		label.text = entry[0]
		label.add_theme_font_size_override("font_size", entry[1])
		label.add_theme_color_override("font_color", entry[2])
		column.add_child(label)

func configure(icons: Array[Texture2D], mobile: bool) -> void:
	controls_label.text = "Joystick mover   /   Toque usar" if mobile else "WASD mover   /   Espaço saltar   /   E usar"
	for i in range(3):
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		material_row.add_child(row)
		var icon := TextureRect.new()
		icon.texture = icons[i]
		icon.custom_minimum_size = Vector2(72, 72)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var label := Label.new()
		label.text = ["Pedras", "Antena", "Combustível"][i]
		label.add_theme_font_size_override("font_size", 28)
		row.add_child(label)

func _layout() -> void:
	var view := get_viewport_rect().size
	# 84% of each axis occupies approximately 70% of the viewport area.
	panel.position = view * 0.08
	panel.size = view * 0.84
