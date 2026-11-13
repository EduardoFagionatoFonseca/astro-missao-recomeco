extends Control
## Interactive, editor-friendly mission-readiness assessment. Questions live in data/mission_readiness.json.
signal passed
signal skipped

const QUESTIONS_PATH := "res://data/mission_readiness.json"
const MINIMUM_SCORE := 80
const CUTSCENE_SCENE := preload("res://scenes/components/mission_quiz_cutscene.tscn")

var questions: Array = []
var minimum_score := MINIMUM_SCORE
var question_index := 0
var correct_answers := 0
var answered := false
var content: VBoxContainer
var progress_label: Label
var topic_label: Label
var question_label: Label
var feedback_label: Label
var answers_box: VBoxContainer
var continue_button: Button
var skip_quiz_button: Button
var shade: ColorRect
var card: PanelContainer
var cutscene_stage: Control
var page_tween: Tween

func _ready() -> void:
	theme = preload("res://scripts/ui/ui_theme.gd").create()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var art := TextureRect.new()
	art.texture = preload("res://assets/ui/menu-mars-2d.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	shade = ColorRect.new()
	shade.color = Color("07101dea")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	cutscene_stage = CUTSCENE_SCENE.instantiate()
	cutscene_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cutscene_stage.finished.connect(_on_cutscene_finished)
	add_child(cutscene_stage)
	card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", preload("res://scripts/ui/ui_theme.gd").box(Color("17191dfc"), Color("bad3a7"), 26))
	add_child(card)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	card.add_child(content)
	progress_label = _label("", 20, Color("bad3a7"))
	content.add_child(progress_label)
	topic_label = _label("", 23, Color("f2ba90"))
	content.add_child(topic_label)
	question_label = _label("", 32)
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(question_label)
	answers_box = VBoxContainer.new()
	answers_box.add_theme_constant_override("separation", 10)
	content.add_child(answers_box)
	feedback_label = _label("", 21, Color("b7d8bf"))
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(feedback_label)
	continue_button = Button.new()
	continue_button.custom_minimum_size.y = 56
	continue_button.pressed.connect(_advance)
	content.add_child(continue_button)
	skip_quiz_button = Button.new()
	skip_quiz_button.text = "PULAR QUESTIONÁRIO"
	skip_quiz_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	skip_quiz_button.offset_left = -290
	skip_quiz_button.offset_right = -34
	skip_quiz_button.offset_top = 24
	skip_quiz_button.offset_bottom = 78
	skip_quiz_button.add_theme_font_size_override("font_size", 18)
	skip_quiz_button.pressed.connect(_skip_quiz)
	add_child(skip_quiz_button)
	_load_questions()
	get_viewport().size_changed.connect(_layout)
	_layout()
	hide()

func _label(text: String, font_size: int, color := Color("f0e9d9")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _load_questions() -> void:
	if not FileAccess.file_exists(QUESTIONS_PATH):
		push_error("Arquivo de perguntas não encontrado: " + QUESTIONS_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(QUESTIONS_PATH))
	if not parsed is Dictionary or not parsed.get("questions", []) is Array:
		push_error("Formato inválido em " + QUESTIONS_PATH)
		return
	minimum_score = int(parsed.get("minimum_score", MINIMUM_SCORE))
	questions = parsed.questions

func open() -> void:
	question_index = 0
	correct_answers = 0
	answered = false
	show()
	skip_quiz_button.show()
	_open_cutscene()

func _skip_quiz() -> void:
	if cutscene_stage != null:
		cutscene_stage.active = false
		cutscene_stage.hide()
	hide()
	skipped.emit()

func _open_cutscene() -> void:
	if question_index >= questions.size():
		_render_result()
		card.show()
		return
	card.hide()
	var question: Dictionary = questions[question_index]
	cutscene_stage.play_question(question, question_index, questions.size())

func _on_cutscene_finished() -> void:
	cutscene_stage.hide()
	_render_question()
	card.show()

func _render_question() -> void:
	for child in answers_box.get_children():
		answers_box.remove_child(child)
		child.queue_free()
	feedback_label.text = ""
	answered = false
	if question_index >= questions.size():
		_render_result()
		return
	var question: Dictionary = questions[question_index]
	progress_label.text = "PREPARO DA MISSÃO   /   %02d DE %02d" % [question_index + 1, questions.size()]
	topic_label.text = str(question.get("topic", "PREPARO"))
	question_label.text = str(question.get("question", ""))
	for answer_index in range(question.get("answers", []).size()):
		var answer_button := Button.new()
		answer_button.text = str(question.answers[answer_index])
		answer_button.custom_minimum_size = Vector2(0, 46)
		answer_button.add_theme_font_size_override("font_size", 18)
		answer_button.pressed.connect(_select_answer.bind(answer_index))
		answers_box.add_child(answer_button)
	continue_button.hide()
	continue_button.text = "PRÓXIMA CENA   >"
	_fade_content()

func _select_answer(answer_index: int) -> void:
	if answered or question_index >= questions.size(): return
	answered = true
	var question: Dictionary = questions[question_index]
	var is_correct: bool = answer_index == int(question.get("correct", -1))
	if is_correct:
		correct_answers += 1
		feedback_label.add_theme_color_override("font_color", Color("b7d8bf"))
		feedback_label.text = "CORRETO  ·  " + str(question.get("debrief", ""))
	else:
		feedback_label.add_theme_color_override("font_color", Color("f2ba90"))
		feedback_label.text = "REVISÃO  ·  " + str(question.get("debrief", ""))
	for answer_button: Button in answers_box.get_children():
		answer_button.disabled = true
	continue_button.show()
	continue_button.grab_focus()

func _advance() -> void:
	if question_index < questions.size():
		question_index += 1
		if question_index < questions.size():
			_open_cutscene()
		else:
			_render_result()
	else:
		var score := _score_percent()
		if score >= minimum_score:
			hide()
			passed.emit()
		else:
			question_index = 0
			correct_answers = 0
			_render_question()

func _score_percent() -> int:
	if questions.is_empty(): return 0
	return roundi(float(correct_answers) / float(questions.size()) * 100.0)

func _render_result() -> void:
	cutscene_stage.hide()
	for child in answers_box.get_children():
		answers_box.remove_child(child)
		child.queue_free()
	var score := _score_percent()
	progress_label.text = "AVALIAÇÃO DE PRONTIDÃO CONCLUÍDA"
	topic_label.text = "MISSÃO LIBERADA" if score >= minimum_score else "REVISÃO NECESSÁRIA"
	question_label.text = "%d%%  ·  %d de %d respostas corretas" % [score, correct_answers, questions.size()]
	feedback_label.text = "Excelente preparo. Sua missão começa agora." if score >= minimum_score else "A pontuação mínima é %d%%. Reveja os sistemas e tente novamente." % minimum_score
	feedback_label.add_theme_color_override("font_color", Color("b7d8bf") if score >= minimum_score else Color("f2ba90"))
	continue_button.text = "INICIAR MISSÃO   >" if score >= minimum_score else "REFAZER QUESTIONÁRIO"
	continue_button.show()
	_fade_content()

func _fade_content() -> void:
	if page_tween: page_tween.kill()
	content.modulate.a = 0.0
	page_tween = create_tween()
	page_tween.tween_property(content, "modulate:a", 1.0, 0.24)

func _layout() -> void:
	var view := get_viewport_rect().size
	card.position = view * 0.05
	card.size = view * 0.90
