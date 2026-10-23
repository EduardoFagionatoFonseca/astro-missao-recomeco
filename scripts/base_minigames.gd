extends Control
signal power_repaired
signal signal_sent
signal closed

const COLORS := [Color("f2ba90"), Color("b7d8bf"), Color("92bde0")]
const SYMBOLS := ["A / SOLAR", "B / BATERIA", "C / SUPORTE"]
var mode := ""
var selected := -1
var connected := [false, false, false]
var sources: Array[Button] = []
var targets: Array[Button] = []
var panel: PanelContainer
var body: VBoxContainer
var message: Label
var diagram: Control
var frequency: HSlider
var alignment: HSlider
var stability: ProgressBar
var hold_time := 0.0
var completed := false
var frozen := false

class CableDiagram extends Control:
	var game: Control
	func _draw() -> void:
		for i in range(game.sources.size()):
			if not game.connected[i]: continue
			var target: Button = game.targets[[1, 2, 0][i]]
			var a: Vector2 = game.sources[i].get_global_rect().get_center() - global_position
			var b: Vector2 = target.get_global_rect().get_center() - global_position
			a.x += 110
			b.x -= 110
			var points := PackedVector2Array()
			for step in range(25):
				var t := step / 24.0
				points.append(a.lerp(b, t) + Vector2(0, sin(t * PI) * (22 + i * 15)))
			draw_polyline(points, game.COLORS[i], 6, true)
			for point in [a, b]: draw_circle(point, 8, game.COLORS[i])

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color("07131de8")
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 650)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("152b3b")
	style.border_color = Color("607b85")
	style.set_border_width_all(2)
	style.set_corner_radius_all(26)
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 26
	style.content_margin_bottom = 26
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	panel.add_child(body)
	hide()

func _text(text: String, size := 26, color := Color("f0e9d9")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 820
	body.add_child(label)
	return label

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(230, 72)
	button.add_theme_font_size_override("font_size", 26)
	button.pressed.connect(callback)
	return button

func _clear() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	sources.clear()
	targets.clear()
	selected = -1
	hold_time = 0
	completed = false
	show()

func open_power(already_ready: bool) -> void:
	_clear()
	mode = "energy"
	if not already_ready and connected.count(true) == 3: connected = [false, false, false]
	_text("01 / DISTRIBUIÇÃO DE ENERGIA", 32, Color("f2ba90"))
	_text("Selecione uma origem e depois o destino com a mesma letra.\nConecte os três circuitos para restaurar a bateria.")
	message = _text("Energia estável. Circuitos verificados." if already_ready else "A reserva mantém o oxigênio enquanto você faz o reparo.", 23, Color("b7d8bf"))
	diagram = CableDiagram.new()
	diagram.game = self
	diagram.custom_minimum_size = Vector2(820, 270)
	body.add_child(diagram)
	for i in range(3):
		var source := _button(SYMBOLS[i], _select_source.bind(i))
		source.position = Vector2(0, i * 90)
		source.modulate = COLORS[i]
		diagram.add_child(source)
		sources.append(source)
		var target_index: int = [2, 0, 1][i]
		var target := _button(SYMBOLS[target_index], _select_target.bind(target_index))
		target.position = Vector2(590, i * 90)
		target.modulate = COLORS[target_index]
		diagram.add_child(target)
		targets.append(target)
		if already_ready: connected[i] = true
		if already_ready: source.disabled = true
	body.add_child(_button("Voltar à base", close))
	_refresh_connections()

func _select_source(index: int) -> void:
	if completed or frozen or connected[index]: return
	selected = index
	message.text = "Origem %s selecionada. Escolha o destino." % SYMBOLS[index].left(1)
	_refresh_connections()

func _select_target(index: int) -> void:
	if completed or frozen: return
	if selected < 0:
		message.text = "Selecione primeiro uma origem à esquerda."
		return
	if selected != index:
		message.text = "Circuitos diferentes. Confira a letra de cada conector."
		selected = -1
		_refresh_connections()
		return
	connected[index] = true
	selected = -1
	message.text = "%d/3 circuitos conectados." % connected.count(true)
	_refresh_connections()
	if connected.count(true) == 3:
		completed = true
		message.text = "Energia restaurada. O terminal de comunicação está disponível."
		power_repaired.emit()

func _refresh_connections() -> void:
	for i in range(sources.size()):
		sources[i].disabled = connected[i]
		sources[i].text = ("OK " if connected[i] else "> " if selected == i else "") + SYMBOLS[i]
	if is_instance_valid(diagram): diagram.queue_redraw()

func open_signal(power: bool, parts: int, sent: bool) -> void:
	_clear()
	mode = "signal"
	_text("02 / SINALIZADOR DE RESGATE", 32, Color("92bde0"))
	if not power or parts < 6 or sent:
		_text("Sua localização já foi transmitida. Reúna os materiais restantes para o pouso." if sent else "Repare a energia no painel ao lado." if not power else "Antena incompleta: %d/6 peças. Explore Marte e volte com as seis peças." % parts)
		_text("A tripulação precisa de uma transmissão estável para encontrar o abrigo.", 25, Color("b7d8bf"))
		body.add_child(_button("Voltar à base", close))
		completed = true
		return
	_text("Ajuste os dois controles até limpar a interferência.\nMantenha o sinal acima de 92% por 3 segundos.")
	message = _text("Procurando a frequência da tripulação…", 25, Color("b7d8bf"))
	_text("FREQUÊNCIA", 21)
	frequency = _slider(20)
	_text("ALINHAMENTO DA ANTENA", 21)
	alignment = _slider(80)
	stability = ProgressBar.new()
	stability.custom_minimum_size.y = 38
	body.add_child(stability)
	body.add_child(_button("Voltar à base", close))

func _slider(value: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = value
	slider.custom_minimum_size.y = 68
	var grabber := GradientTexture2D.new()
	grabber.width = 42
	grabber.height = 42
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color("b7d8bf"), Color("b7d8bf")])
	grabber.gradient = gradient
	for name in ["grabber", "grabber_highlight"]: slider.add_theme_icon_override(name, grabber)
	body.add_child(slider)
	return slider

func signal_quality() -> float:
	return clampf(100.0 - absf(frequency.value - 64) * 1.5 - absf(alignment.value - 38) * 1.5, 0, 100)

func _process(delta: float) -> void:
	if not visible or frozen or mode != "signal" or completed: return
	var quality := signal_quality()
	hold_time = minf(3.0, hold_time + delta) if quality >= 92 else 0.0
	stability.value = hold_time / 3.0 * 100
	message.text = "Sinal %d%%  /  %s" % [quality, "Transmitindo… %.1f / 3 s" % hold_time if quality >= 92 else "Ajuste até estabilizar"]
	if hold_time >= 3.0:
		completed = true
		message.text = "Localização confirmada. Sua tripulação está a caminho!"
		signal_sent.emit()

func close() -> void:
	hide()
	mode = ""
	closed.emit()
