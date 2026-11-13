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
var clip_duration := DURATION
var captions: Array = CAPTIONS
var clip_path := "res://assets/cinematics/intro.ogv"
var caption_index := -1
var caption_tween: Tween
var footer_panel: PanelContainer
var title_label: Label
var skip_button: Button

func _ready() -> void:
	theme = preload("res://scripts/ui/ui_theme.gd").create()
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
	player.bus = "Music"
	player.expand = true
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(player)
	player.finished.connect(_finish)
	var top_bar := ColorRect.new()
	top_bar.color = Color("07111cbb")
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 118
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_bar)
	var footer := PanelContainer.new()
	footer_panel = footer
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -168
	var style := StyleBoxFlat.new()
	style.bg_color = Color("07111cf0")
	style.border_color = Color("8fae9a")
	style.set_border_width_all(1)
	style.border_width_top = 2
	style.set_corner_radius_all(10)
	style.content_margin_left = 60
	style.content_margin_right = 60
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	style.shadow_color = Color("00000088")
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, -4)
	footer.add_theme_stylebox_override("panel", style)
	add_child(footer)
	caption = Label.new()
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 32)
	caption.add_theme_color_override("font_color", Color("f0e9d9"))
	footer.add_child(caption)
	title_label = Label.new()
	title_label.text = "ASTRO  /  UM PEQUENO RECOMEÇO"
	title_label.position = Vector2(54, 42)
	title_label.add_theme_font_size_override("font_size", 26)
	add_child(title_label)
	skip_button = Button.new()
	skip_button.text = "Pular  >"
	skip_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	skip_button.offset_left = -240
	skip_button.offset_right = -46
	skip_button.offset_top = 32
	skip_button.offset_bottom = 108
	skip_button.add_theme_font_size_override("font_size", 24)
	skip_button.pressed.connect(_finish)
	add_child(skip_button)
	hide()

func begin(muted: bool, departure := false) -> void:
	clock = 0
	active = true
	show()
	clip_duration = 14.0 if departure else DURATION
	captions = ["Você conseguiu voltar.", "Marte ficou para trás.", "Nenhuma missão termina sozinha."] if departure else CAPTIONS
	clip_path = "res://assets/cinematics/outro.ogv" if departure else "res://assets/cinematics/intro.ogv"
	caption.text = tr(captions[0])
	caption_index = 0
	caption.modulate.a = 0.0
	footer_panel.modulate.a = 0.0
	title_label.modulate.a = 0.0
	skip_button.modulate.a = 0.0
	var entrance := create_tween().set_parallel(true)
	entrance.tween_property(footer_panel, "modulate:a", 1.0, 0.45)
	entrance.tween_property(title_label, "modulate:a", 1.0, 0.4)
	entrance.tween_property(skip_button, "modulate:a", 1.0, 0.35).set_delay(0.12)
	entrance.tween_property(caption, "modulate:a", 1.0, 0.5).set_delay(0.18)
	fallback = not ResourceLoader.exists(clip_path)
	if not fallback:
		player.stream = load(clip_path)
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
	var next_caption := mini(captions.size() - 1, int(time / (clip_duration / captions.size())))
	if next_caption != caption_index:
		caption_index = next_caption
		if caption_tween and caption_tween.is_running(): caption_tween.kill()
		caption_tween = create_tween()
		caption_tween.tween_property(caption, "modulate:a", 0.0, 0.14)
		caption_tween.tween_callback(_show_caption.bind(next_caption))
		caption_tween.tween_property(caption, "modulate:a", 1.0, 0.3)
	if clock >= clip_duration + 3 or (fallback and clock >= clip_duration): _finish()

func _show_caption(index: int) -> void:
	caption.text = tr(captions[index])

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
