extends Control
## Short queued radio messages and a one-time shelter tutorial, timed in game time.
signal transmission_started
signal typing_tick
const AXIOS := "Inteligência artificial AXIOS"
var active := false
var link_online := true
var current_requires_link := true
var notice_requires_link := true
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
var dialogue_writer := preload("res://scripts/typewriter.gd").new()
var notice_writer := preload("res://scripts/typewriter.gd").new()
var notice_tween: Tween

func _ready() -> void:
	theme = preload("res://scripts/ui_theme.gd").create()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash = ColorRect.new()
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash.color = Color(1, 0.91, 0.72, 0)
	add_child(wash)
	radio = _panel()
	radio.custom_minimum_size = Vector2(900, 100)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 10)
	radio.add_child(column)
	speaker = _label("TRIPULAÇÃO", 24, Color("bad3a7"))
	column.add_child(speaker)
	dialogue = _label("", 32, Color("f2f1e9"))
	dialogue.custom_minimum_size.x = 840
	column.add_child(dialogue)
	notice = _panel()
	notice.custom_minimum_size = Vector2(900, 0)
	notice_label = _label("", 32, Color("efb77c"))
	notice_label.custom_minimum_size.x = 840
	notice.add_child(notice_label)
	dialogue_writer.typing_tick.connect(func(): typing_tick.emit())
	notice_writer.typing_tick.connect(func(): typing_tick.emit())
	radio.hide()
	notice.hide()
	get_viewport().size_changed.connect(_layout)
	_layout()

func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("191c21f5")
	style.border_color = Color("555e67")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
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
	radio.position = Vector2((view.x - 900) / 2, view.y - 270)
	notice.position = Vector2((view.x - 900) / 2, view.y - 390)

func transmit(id: String, text: String, urgent := false, from := "TRIPULAÇÃO", requires_link := true, interrupt := false) -> void:
	if requires_link and not link_online: return
	if seen.has(id): return
	seen[id] = true
	var entry := {"text": text, "speaker": from, "requires_link": requires_link}
	if urgent: queue.push_front(entry)
	else: queue.append(entry)
	if interrupt: current_time = 0

func shelter_tutorial() -> void:
	notice_message("solar_tutorial", "Névoa solar a caminho. Entre no abrigo!")

func notice_message(id: String, text: String, requires_link := true) -> void:
	if requires_link and not link_online: return
	if seen.has(id): return
	seen[id] = true
	notice_writer.begin(notice_label, text)
	notice_requires_link = requires_link
	notice_time = 6.0
	if notice_tween: notice_tween.kill()
	notice.modulate.a = 0
	notice_tween = create_tween()
	notice_tween.tween_property(notice, "modulate:a", 1.0, 0.2)

func set_link(online: bool) -> void:
	link_online = online
	if online: return
	queue = queue.filter(func(entry: Dictionary): return not entry.requires_link)
	if current_requires_link:
		current_time = 0
		dialogue_writer.cancel()
		radio.hide()
	if notice_requires_link:
		notice_time = 0
		notice_writer.cancel()
		notice.hide()

func tick(delta: float) -> void:
	# Wrapped labels initially measure before the panel receives its final width.
	# Refit after layout so a short message never leaves an oversized empty panel.
	radio.reset_size()
	notice.reset_size()
	radio.visible = active and current_time > 0
	notice.visible = active and notice_time > 0
	if not active: return
	if current_time <= 0 and not queue.is_empty():
		var entry: Dictionary = queue.pop_front()
		dialogue_writer.begin(dialogue, entry.text)
		speaker.text = entry.speaker
		current_requires_link = entry.requires_link
		current_time = 4.5
		radio.show()
		if radio_tween: radio_tween.kill()
		radio.modulate.a = 0
		radio.position.y = get_viewport_rect().size.y - 262
		radio_tween = create_tween()
		radio_tween.set_parallel(true)
		radio_tween.tween_property(radio, "modulate:a", 1.0, 0.22)
		radio_tween.tween_property(radio, "position:y", get_viewport_rect().size.y - 270, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		transmission_started.emit()
	if current_time > 0: dialogue_writer.advance(delta)
	if notice_time > 0: notice_writer.advance(delta)
	current_time = maxf(0, current_time - delta)
	notice_time = maxf(0, notice_time - delta)
	if current_time < 0.6: radio.modulate.a = current_time / 0.6
	if notice_time < 0.8: notice.modulate.a = notice_time / 0.8

func solar_intensity(value: float, sheltered: bool) -> void:
	wash.color.a = value * 0.18 if not sheltered else 0.0
