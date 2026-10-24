extends Control
signal visibility_updated
const BUSES := ["Master", "Music", "Interactions", "Alerts"]
const NAMES := ["GERAL", "MÚSICAS", "INTERAÇÕES", "AVISOS"]
const MUSIC_MAX_GAIN := 0.8
const MUSIC_SCALE_VERSION := 2
var volumes: Dictionary = {}
var sliders: Array[HSlider] = []
var values: Array[Label] = []
var panel: PanelContainer

func _ready() -> void:
	theme = preload("res://scripts/ui_theme.gd").create()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var config := ConfigFile.new()
	config.load("user://audio.cfg")
	var migrate_music := int(config.get_value("settings", "music_scale_version", 0)) < MUSIC_SCALE_VERSION
	for bus in BUSES:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
		var value := float(config.get_value("volume", bus, 0.5 if bus == "Music" else 1.0))
		if bus == "Music" and migrate_music: value = 0.5
		_set_volume(bus, value, false)
	if migrate_music: _save_volumes()
	var shade := ColorRect.new()
	shade.color = Color("05090de8")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(920, 0)
	panel.add_theme_stylebox_override("panel", preload("res://scripts/ui_theme.gd").box(Color("171c23"), Color("4b5862"), 36))
	add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	panel.add_child(body)
	_label(body, "CONFIGURAÇÕES", 22, Color("bad3a7"))
	_label(body, "Som do seu jeito.", 42)
	for i in range(BUSES.size()):
		var row := HBoxContainer.new()
		body.add_child(row)
		var title := _label(row, NAMES[i], 25)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		values.append(_label(row, "", 25, Color("bad3a7")))
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.custom_minimum_size = Vector2(840, 44)
		slider.value = roundf(float(volumes[BUSES[i]]) * 100)
		values[i].text = "%d%%" % slider.value
		slider.value_changed.connect(func(value: float): _set_volume(BUSES[i], value / 100); values[i].text = "%d%%" % value)
		sliders.append(slider)
		body.add_child(slider)
	var close_button := Button.new()
	close_button.text = "PRONTO"
	close_button.custom_minimum_size.y = 96
	close_button.pressed.connect(close)
	body.add_child(close_button)
	get_viewport().size_changed.connect(_layout)
	panel.resized.connect(_layout)
	_layout()
	hide()

func _label(parent: Node, text: String, size: int, color := Color("f2f1e9")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _set_volume(bus: String, value: float, save := true) -> void:
	volumes[bus] = clampf(value, 0, 1)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(bus), float(volumes[bus]) * (MUSIC_MAX_GAIN if bus == "Music" else 1.0))
	if save: _save_volumes()

func _save_volumes() -> void:
	var config := ConfigFile.new()
	for name in BUSES: config.set_value("volume", name, volumes[name])
	config.set_value("settings", "music_scale_version", MUSIC_SCALE_VERSION)
	config.save("user://audio.cfg")

func open() -> void:
	show()
	_layout()
	visibility_updated.emit()

func close() -> void:
	hide()
	visibility_updated.emit()

func _layout() -> void:
	panel.position = (get_viewport_rect().size - panel.size) / 2

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
