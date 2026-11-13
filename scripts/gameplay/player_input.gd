extends Control
## One action map for keyboard, mouse and independent touch pointers.
signal interact_requested
signal jump_requested

var mobile := false
var enabled := false
var movement := Vector2.ZERO
var stick_id := -1
var stick_center := Vector2(168, 700)
var stick_radius := 100.0
var control_scale := 1.0
var action_rect := Rect2()
var jump_rect := Rect2()
var action_text := "Interagir"
var action_available := false
var jump_available := true

static func detect_mobile() -> bool:
	if OS.has_feature("web"):
		# Touch alone also matches Windows laptops. Never use window width.
		return bool(JavaScriptBridge.eval("(function(){const u=navigator.userAgent;return (/Android|iPhone|iPod|iPad/i.test(u)&&navigator.maxTouchPoints>0)||(navigator.platform==='MacIntel'&&navigator.maxTouchPoints>1);})()"))
	return OS.has_feature("android") or OS.has_feature("ios")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mobile = detect_mobile() or "--mobile-test" in OS.get_cmdline_user_args()
	for action in ["move_left", "move_right", "move_forward", "move_back", "interact", "jump"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	var bindings := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN], "interact": [KEY_E], "jump": [KEY_SPACE]}
	for action: String in bindings:
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key as Key
			if not InputMap.action_has_event(action, event): InputMap.action_add_event(action, event)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var view := get_viewport_rect().size
	if view.x <= 0.0 or view.y <= 0.0: return
	control_scale = clampf(minf(view.x / 800.0, view.y / 450.0), 0.62, 1.0)
	var margin := 20.0 * control_scale
	var button_width := minf(260.0 * control_scale, view.x * 0.39)
	var button_height := maxf(54.0, 78.0 * control_scale)
	var button_gap := 12.0 * control_scale
	stick_radius = clampf(minf(view.x, view.y) * 0.16, 62.0, 96.0)
	stick_center = Vector2(maxf(stick_radius + margin, view.x * 0.19), view.y - stick_radius - margin)
	var bottom_gap := margin
	if mobile:
		var screen_height := float(DisplayServer.window_get_size().y)
		if OS.has_feature("web"):
			screen_height = float(JavaScriptBridge.eval("window.visualViewport ? window.visualViewport.height : window.innerHeight"))
		bottom_gap = clampf(86.0 * view.y / maxf(screen_height, 1.0), margin, view.y * 0.4)
	action_rect = Rect2(view.x - button_width - margin, view.y - button_height - bottom_gap, button_width, button_height)
	jump_rect = Rect2(view.x - button_width - margin, action_rect.position.y - button_height - button_gap, button_width, button_height)
	reset()

func set_enabled(value: bool) -> void:
	if enabled != value: reset()
	enabled = value
	queue_redraw()

func reset() -> void:
	stick_id = -1
	movement = Vector2.ZERO
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: reset()

func direction() -> Vector2:
	if not enabled: return Vector2.ZERO
	var keyboard := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	return (keyboard + movement).limit_length()

func _unhandled_key_input(event: InputEvent) -> void:
	if not enabled or not event.is_pressed() or event.is_echo(): return
	if event.is_action_pressed("interact"):
		interact_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("jump"):
		jump_requested.emit()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not mobile or not enabled: return
	if event is InputEventScreenTouch:
		if event.pressed:
			if stick_id == -1 and event.position.distance_to(stick_center) < stick_radius * 1.5:
				stick_id = event.index
				_update_stick(event.position)
			elif action_rect.has_point(event.position):
				if action_available: interact_requested.emit()
			elif jump_rect.has_point(event.position):
				if jump_available: jump_requested.emit()
			else: return
		else:
			if event.index == stick_id:
				stick_id = -1
				movement = Vector2.ZERO
			else: return
		get_viewport().set_input_as_handled()
		queue_redraw()
	elif event is InputEventScreenDrag and event.index == stick_id:
		_update_stick(event.position)
		get_viewport().set_input_as_handled()

func _update_stick(at: Vector2) -> void:
	var offset := (at - stick_center) / stick_radius
	movement = Vector2(offset.x, -offset.y).limit_length()
	if movement.length() < 0.12: movement = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	if not mobile or not enabled: return
	draw_circle(stick_center, stick_radius, Color("10151caa"))
	draw_arc(stick_center, stick_radius, 0, TAU, 64, Color("b7d8bfbb"), 2.5 * control_scale, true)
	draw_circle(stick_center + Vector2(movement.x, -movement.y) * stick_radius * 0.62, 31.0 * control_scale, Color("d4e5d7dd"))
	_draw_button(action_rect, action_text, Color("f2ba90ef") if action_available else Color("a3b7c477"))
	_draw_button(jump_rect, "Saltar", Color("b7d8bfdd") if jump_available else Color("a3b7c455"))

func _draw_button(rect: Rect2, text: String, color: Color) -> void:
	text = tr(text)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("191c21ef")
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(roundi(16.0 * control_scale))
	draw_style_box(style, rect)
	var font := ThemeDB.fallback_font
	var font_size := roundi(25.0 * control_scale)
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, rect.position + Vector2((rect.size.x - width) / 2, rect.size.y / 2 + font_size * 0.34), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
