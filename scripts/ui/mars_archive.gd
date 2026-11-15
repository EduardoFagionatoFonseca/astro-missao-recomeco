extends Control
signal visibility_updated

const UI := preload("res://scripts/ui/ui_theme.gd")
const PHOTOS := [
	preload("res://assets/mars/PIA19400.jpg"),
	preload("res://assets/mars/PIA23202.jpg"),
	preload("res://assets/mars/PIA17944.jpg"),
	preload("res://assets/mars/PIA20281.jpg"),
	preload("res://assets/mars/PIA24622.jpg"),
	preload("res://assets/mars/PIA25172.jpg"),
	preload("res://assets/mars/PIA25829.jpg"),
	preload("res://assets/mars/PIA21498.jpg"),
]
const ICON := preload("res://assets/ui/mars_archive.svg")

var catalog: Array
var unlocked: Array[int] = []
var pending: Array[int] = []
var unseen: Array[int] = []
var selected := -1
var launcher: Button
var badge: Label
var overlay: ColorRect
var panel: PanelContainer
var title: Label
var detail: TextureRect
var caption: Label
var credit: Label
var source: Button
var cards: Array[Button] = []
var toast: PanelContainer
var presenting := false

func _ready() -> void:
	theme = UI.create()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://assets/mars/provenance.json"))
	launcher = Button.new()
	launcher.custom_minimum_size = Vector2(224, 60)
	launcher.icon = ICON
	launcher.expand_icon = true
	launcher.add_theme_constant_override("icon_max_width", 32)
	launcher.add_theme_font_size_override("font_size", 23)
	launcher.pressed.connect(open)
	add_child(launcher)
	badge = _label(launcher, "", 18, Color("171c23"))
	badge.add_theme_stylebox_override("normal", UI.box(Color("f2ba90"), Color("f2ba90"), 4))
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.position = Vector2(194, -13)
	badge.custom_minimum_size = Vector2(36, 30)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay = ColorRect.new()
	overlay.color = Color("080d14e8")
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.box(Color("171c23"), Color("687d84"), 24))
	overlay.add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	panel.add_child(body)
	var header := HBoxContainer.new()
	body.add_child(header)
	title = _label(header, "", 33, Color("b7d8bf"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close_button := Button.new()
	close_button.text = "Fechar"
	close_button.custom_minimum_size = Vector2(142, 54)
	close_button.pressed.connect(close)
	header.add_child(close_button)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 24)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(content)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	content.add_child(grid)
	for i in range(PHOTOS.size()):
		var button := Button.new()
		button.custom_minimum_size = Vector2(130, 100)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.pressed.connect(_select.bind(i))
		grid.add_child(button)
		cards.append(button)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 8)
	content.add_child(info)
	detail = TextureRect.new()
	detail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.custom_minimum_size.y = 210
	info.add_child(detail)
	caption = _label(info, "", 25, Color("f0e9d9"))
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	credit = _label(info, "", 18, Color("a3b7c4"))
	credit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	source = Button.new()
	source.text = "Fonte NASA ↗"
	source.custom_minimum_size.y = 46
	source.pressed.connect(func(): OS.shell_open(catalog[selected].source))
	info.add_child(source)
	overlay.hide()
	GameOptions.language_changed.connect(_refresh)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_refresh()
	hide()

func _label(parent: Control, value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _layout() -> void:
	var view := get_viewport_rect().size
	launcher.position = Vector2(22, 358)
	panel.size = Vector2(1120, 650)
	panel.scale = Vector2.ONE * minf(1.0, minf((view.x - 36) / panel.size.x, (view.y - 36) / panel.size.y))
	panel.position = (view - panel.size * panel.scale) * 0.5

func is_open() -> bool:
	return overlay.visible

func open() -> void:
	if not is_visible_in_tree() or overlay.visible: return
	overlay.show()
	if selected < 0 and not unlocked.is_empty(): _select(unlocked[-1])
	_refresh()
	visibility_updated.emit()

func close() -> void:
	if not overlay.visible: return
	overlay.hide()
	visibility_updated.emit()

func _select(index: int) -> void:
	selected = index
	unseen.erase(index)
	_refresh()

func _refresh() -> void:
	var english := GameOptions.language == "en"
	launcher.text = tr("Índice de Marte")
	badge.text = " %d " % unseen.size()
	badge.visible = not unseen.is_empty()
	title.text = tr("Índice de Marte") + "   %02d / %02d" % [unlocked.size(), PHOTOS.size()]
	for i in range(cards.size()):
		var available := i in unlocked
		cards[i].disabled = not available
		cards[i].icon = PHOTOS[i] if available else null
		cards[i].text = "" if available else "%02d" % (i + 1)
		cards[i].tooltip_text = str(catalog[i].title_en if english else catalog[i].title) if available else tr("Foto ainda não encontrada")
		cards[i].modulate = Color.WHITE if i == selected else Color("d1dce4")
	detail.texture = null if selected < 0 else PHOTOS[selected]
	caption.text = tr("Colete fotografias na superfície para abrir os registros.") if selected < 0 else str(catalog[selected].title_en if english else catalog[selected].title)
	credit.text = "" if selected < 0 else "%s\n%s • %s" % [catalog[selected].caption, catalog[selected].credit, catalog[selected].id]
	source.visible = selected >= 0

func collect(index: int) -> void:
	if index in unlocked: return
	unlocked.append(index)
	pending.append(index)
	_refresh()
	if not presenting: _play_queue()

func _play_queue() -> void:
	presenting = true
	while not pending.is_empty():
		var index: int = pending.pop_front()
		toast = PanelContainer.new()
		toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
		toast.add_theme_stylebox_override("panel", UI.box(Color("1a222b"), Color("f2ba90"), 12))
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 15)
		toast.add_child(row)
		var photo := TextureRect.new()
		photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		photo.texture = PHOTOS[index]
		photo.custom_minimum_size = Vector2(135, 82)
		photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(photo)
		var name: String = catalog[index].title_en if GameOptions.language == "en" else catalog[index].title
		var message := _label(row, tr("FOTO RECUPERADA") + "\n" + name, 20, Color("f2e1ce"))
		message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		message.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(toast)
		toast.reset_size()
		toast.modulate.a = 0.0
		toast.position = _toast_origin()
		var animation := create_tween()
		animation.tween_property(toast, "modulate:a", 1.0, 0.18)
		animation.tween_interval(1.35)
		animation.tween_method(_fly, 0.0, 1.0, 0.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		await animation.finished
		toast.queue_free()
		if selected != index: unseen.append(index)
		_refresh()
	presenting = false

func _toast_origin() -> Vector2:
	var view := get_viewport_rect().size
	return Vector2((view.x - toast.size.x) * 0.5, view.y * 0.21)

func _fly(weight: float) -> void:
	toast.scale = Vector2.ONE.lerp(Vector2.ONE * 0.17, weight)
	toast.position = _toast_origin().lerp(launcher.position + launcher.size * 0.5, weight)
	toast.modulate.a = 1.0 - weight * weight

func _unhandled_key_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
