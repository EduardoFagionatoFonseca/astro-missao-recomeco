extends Control
## Shows one source-backed question after the first completion of a task.
signal closed

const QUESTIONS_PATH := "res://data/task_questions.json"

var questions: Dictionary = {}
var completed: Dictionary = {}
var current_task := ""
var content: VBoxContainer
var topic: Label
var prompt: Label
var answers: VBoxContainer
var explanation: Label
var source: LinkButton
var proceed: Button
var answered := false

func _ready() -> void:
	var file := FileAccess.open(QUESTIONS_PATH, FileAccess.READ)
	if file != null:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary: questions = parsed
	theme = preload("res://scripts/ui/ui_theme.gd").create()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color("07101de8")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", preload("res://scripts/ui/ui_theme.gd").box(Color("17191d"), Color("bad3a7"), 24))
	center.add_child(panel)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	topic = _label(23)
	prompt = _label(32)
	answers = VBoxContainer.new()
	answers.add_theme_constant_override("separation", 8)
	content.add_child(answers)
	explanation = _label(24)
	source = LinkButton.new()
	source.add_theme_font_size_override("font_size", 20)
	content.add_child(source)
	proceed = Button.new()
	proceed.custom_minimum_size.y = 56
	proceed.pressed.connect(_close)
	content.add_child(proceed)
	get_viewport().size_changed.connect(_layout)
	GameOptions.language_changed.connect(_render)
	_layout()
	hide()

func _label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(label)
	return label

func _layout() -> void:
	content.custom_minimum_size.x = minf(740, maxf(240, get_viewport_rect().size.x - 110))

func open_task(task: String) -> bool:
	if visible or completed.has(task) or not questions.has(task): return false
	current_task = task
	answered = false
	show()
	_render()
	return true

func _render() -> void:
	if current_task.is_empty(): return
	var entry: Dictionary = questions[current_task]
	var localized: Dictionary = entry.get(GameOptions.language, entry.pt_BR)
	topic.text = localized.topic
	prompt.text = localized.question
	for child in answers.get_children():
		answers.remove_child(child)
		child.queue_free()
	for i in range(localized.answers.size()):
		var button := Button.new()
		button.text = localized.answers[i]
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.custom_minimum_size.y = 58
		button.add_theme_font_size_override("font_size", 24)
		button.pressed.connect(_answer.bind(i))
		answers.add_child(button)
	answers.visible = not answered
	explanation.text = localized.explanation
	explanation.visible = answered
	source.text = entry.source
	source.uri = entry.url
	source.visible = answered
	proceed.text = tr("Continuar missão")
	proceed.visible = answered
	if answered: proceed.grab_focus()

func _answer(index: int) -> void:
	if answered: return
	if index != int(questions[current_task].correct):
		answers.get_child(index).disabled = true
		explanation.text = tr("Tente outra resposta.")
		explanation.show()
		return
	answered = true
	_render()

func _close() -> void:
	if not answered: return
	completed[current_task] = true
	current_task = ""
	hide()
	closed.emit()
