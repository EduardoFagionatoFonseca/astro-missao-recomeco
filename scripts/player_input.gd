extends Control
## One action map for keyboard, mouse and independent touch pointers.
signal interact_requested
signal jump_requested

var mobile := false
var enabled := false
var movement := Vector2.ZERO
var running := false
var stick_id := -1
var run_ids: Array[int] = []
var stick_center := Vector2(168, 700)
var stick_radius := 100.0
var action_rect := Rect2()
var jump_rect := Rect2()
var run_rect := Rect2()
var action_text := "Interagir"
var action_available := false

static func detect_mobile() -> bool:
	if OS.has_feature("web"):
		# Touch alone also matches Windows laptops. Never use window width.
		return bool(JavaScriptBridge.eval("(function(){const u=navigator.userAgent;return (/Android|iPhone|iPod|iPad/i.test(u)&&navigator.maxTouchPoints>0)||(navigator.platform==='MacIntel'&&navigator.maxTouchPoints>1);})()"))
	return OS.has_feature("android") or OS.has_feature("ios")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mobile = detect_mobile() or "--mobile-test" in OS.get_cmdline_user_args()
	for action in ["move_left", "move_right", "move_forward", "move_back", "interact", "jump", "run"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	var bindings := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN], "interact": [KEY_E], "jump": [KEY_SPACE], "run": [KEY_SHIFT]}
	for action: String in bindings:
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event): InputMap.action_add_event(action, event)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var view := get_viewport_rect().size
	stick_center = Vector2(172, view.y - 174)
	action_rect = Rect2(view.x - 290, view.y - 205, 238, 86)
	jump_rect = Rect2(view.x - 208, view.y - 315, 156, 80)
	run_rect = Rect2(view.x - 430, view.y - 110, 160, 76)
	reset()

func set_enabled(value: bool) -> void:
	if enabled != value: reset()
	enabled = value
	queue_redraw()

func reset() -> void:
	stick_id = -1
	run_ids.clear()
	movement = Vector2.ZERO
	running = false
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: reset()

func direction() -> Vector2:
	if not enabled: return Vector2.ZERO
	var keyboard := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	return (keyboard + movement).limit_length()

func is_running() -> bool:
	return enabled and (running or Input.is_action_pressed("run"))

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
			elif jump_rect.has_point(event.position): jump_requested.emit()
			elif run_rect.has_point(event.position):
				run_ids.append(event.index)
				running = true
			else: return
		else:
			if event.index == stick_id:
				stick_id = -1
				movement = Vector2.ZERO
			elif event.index in run_ids:
				run_ids.erase(event.index)
				running = not run_ids.is_empty()
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
	draw_circle(stick_center, stick_radius, Color("15283a99"))
	draw_arc(stick_center, stick_radius, 0, TAU, 64, Color("b7d8bf99"), 3, true)
	draw_circle(stick_center + Vector2(movement.x, -movement.y) * stick_radius * 0.65, 39, Color("b7d8bfcc"))
	_draw_button(action_rect, action_text, Color("f2ba90ef") if action_available else Color("a3b7c477"))
	_draw_button(jump_rect, "Saltar", Color("b7d8bfdd"))
	_draw_button(run_rect, "Correr", Color("f2ba90ef") if running else Color("a3b7c4bb"))

func _draw_button(rect: Rect2, text: String, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("15283ad9")
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	draw_style_box(style, rect)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
	draw_string(font, rect.position + Vector2((rect.size.x - width) / 2, rect.size.y / 2 + 10), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, color)
