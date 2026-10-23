extends Control
signal finished
const DURATION := 22.0
const CAPTIONS := [
	"Uma tempestade separou você da expedição em Marte.",
	"A tripulação precisou recuar. Você alcançou o abrigo a tempo.",
	"“Vamos voltar por você. Mantenha o sinal ativo.”",
	"Cuide do abrigo. Reúna suprimentos. Faça sua tripulação encontrar você."
]
var player: VideoStreamPlayer
var caption: Label
var clock := 0.0
var active := false
var fallback := false

func _ready() -> void:
	theme = preload("res://scripts/ui_theme.gd").create()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("07111c")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var frame := AspectRatioContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.ratio = 16.0 / 9.0
	frame.stretch_mode = AspectRatioContainer.STRETCH_FIT
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	player = VideoStreamPlayer.new()
	player.expand = true
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(player)
	player.finished.connect(_finish)
	var footer := PanelContainer.new()
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -160
	var style := StyleBoxFlat.new()
	style.bg_color = Color("07111cdd")
	style.content_margin_left = 60
	style.content_margin_right = 60
	style.content_margin_top = 24
	footer.add_theme_stylebox_override("panel", style)
	add_child(footer)
	caption = Label.new()
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 32)
	caption.add_theme_color_override("font_color", Color("f0e9d9"))
	footer.add_child(caption)
	var title := Label.new()
	title.text = "ASTRO  /  UM PEQUENO RECOMEÇO"
	title.position = Vector2(54, 42)
	title.add_theme_font_size_override("font_size", 26)
	add_child(title)
	var skip := Button.new()
	skip.text = "Pular  >"
	skip.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	skip.offset_left = -240
	skip.offset_right = -46
	skip.offset_top = 32
	skip.offset_bottom = 108
	skip.add_theme_font_size_override("font_size", 28)
	skip.pressed.connect(_finish)
	add_child(skip)
	hide()

func begin(muted: bool) -> void:
	clock = 0
	active = true
	show()
	caption.text = CAPTIONS[0]
	var path := "res://assets/cinematics/intro.ogv"
	fallback = not ResourceLoader.exists(path)
	if not fallback:
		player.stream = load(path)
		player.volume_db = -80 if muted else -8
		player.play()
		fallback = player.stream == null

func _process(delta: float) -> void:
	if not active: return
	clock += delta
	# Use video time for captions; a decoder stall must not trap the player.
	var time := player.stream_position if not fallback else clock
	if clock > 4.0 and time < 0.1:
		fallback = true
		player.stop()
	caption.text = CAPTIONS[mini(3, int(time / 5.5))]
	if clock >= DURATION + 3 or (fallback and clock >= DURATION): _finish()

func _unhandled_key_input(event: InputEvent) -> void:
	if active and event.is_pressed() and not event.is_echo() and event is InputEventKey:
		if event.physical_keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER]:
			_finish()
			get_viewport().set_input_as_handled()

func _finish() -> void:
	if not active: return
	active = false
	player.stop()
	hide()
	finished.emit()
