extends Control
## Short queued radio messages and a one-time shelter tutorial, timed in game time.
signal transmission_started
var active := false
var queue: Array[Dictionary] = []
var seen: Dictionary = {}
var current_time := 0.0
var notice_time := 0.0
var radio: PanelContainer
var speaker: Label
var dialogue: Label
var notice: PanelContainer
var notice_label: Label
var wash: ColorRect
var radio_tween: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash = ColorRect.new()
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash.color = Color(1, 0.91, 0.72, 0)
	add_child(wash)
	radio = _panel()
	radio.custom_minimum_size = Vector2(790, 128)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 10)
	radio.add_child(column)
	speaker = _label("TRIPULAÇÃO / TRANSMISSÃO RECEBIDA", 20, Color("b7d8bf"))
	column.add_child(speaker)
	dialogue = _label("", 27, Color("f0e9d9"))
	dialogue.custom_minimum_size.x = 730
	column.add_child(dialogue)
	notice = _panel()
	notice.custom_minimum_size = Vector2(790, 0)
	notice_label = _label("", 28, Color("f2ba90"))
	notice_label.custom_minimum_size.x = 730
	notice.add_child(notice_label)
	radio.hide()
	notice.hide()
	get_viewport().size_changed.connect(_layout)
	_layout()

func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("15283af0")
	style.border_color = Color("72908b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	return panel

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _layout() -> void:
	var view := get_viewport_rect().size
	radio.position = Vector2((view.x - 790) / 2, view.y - 285)
	notice.position = Vector2((view.x - 790) / 2, 175)

func transmit(id: String, text: String, urgent := false, from := "TRIPULAÇÃO") -> void:
	if seen.has(id): return
	seen[id] = true
	var entry := {"text": text, "speaker": from}
	if urgent: queue.push_front(entry)
	else: queue.append(entry)

func shelter_tutorial() -> void:
	if seen.has("solar_tutorial"): return
	seen["solar_tutorial"] = true
	notice_label.text = "RADIAÇÃO SOLAR\nEntre no abrigo com E ou toque. Só o INTERIOR protege você; ficar perto da base não basta."
	notice_time = 10.0

func tick(delta: float) -> void:
	radio.visible = active and current_time > 0
	notice.visible = active and notice_time > 0
	if not active: return
	if current_time <= 0 and not queue.is_empty():
		var entry: Dictionary = queue.pop_front()
		dialogue.text = entry.text
		speaker.text = entry.speaker + " / TRANSMISSÃO RECEBIDA"
		current_time = 6.0
		radio.show()
		if radio_tween: radio_tween.kill()
		radio.modulate.a = 0
		radio_tween = create_tween()
		radio_tween.tween_property(radio, "modulate:a", 1.0, 0.25)
		transmission_started.emit()
	current_time = maxf(0, current_time - delta)
	notice_time = maxf(0, notice_time - delta)
	if current_time < 0.6: radio.modulate.a = current_time / 0.6
	if notice_time < 0.8: notice.modulate.a = notice_time / 0.8
	else: notice.modulate.a = 1

func solar_intensity(value: float, sheltered: bool) -> void:
	wash.color.a = value * 0.18 if not sheltered else 0.0
