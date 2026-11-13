extends Control
## The map is centered on the player and uses the local compass, including on the far hemisphere.
var game: Node3D
var panel_style: StyleBoxFlat
var expanded := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_style = preload("res://scripts/ui/ui_theme.gd").box(Color("111820eb"), Color("53616a"), 12)
	get_viewport().size_changed.connect(_layout)
	_layout()

func configure(mission: Node3D) -> void:
	game = mission
	_layout()

func refresh() -> void:
	queue_redraw()

func _layout() -> void:
	var view := get_viewport_rect().size
	var side := 360.0 if expanded else 226.0
	position = Vector2(view.x - side - 22, view.y - side - 22)
	if game != null and game.controls.mobile:
		var jump: Rect2 = game.controls.jump_rect
		side = minf(200.0, jump.position.y - 260.0)
		if side >= 128.0:
			position = Vector2(view.x - side - 22, jump.position.y - side - 16.0)
		else:
			side = 154.0
			position = Vector2(maxf(22.0, jump.position.x - side - 16.0), maxf(148.0, jump.position.y - 24.0))
	size = Vector2.ONE * side
	queue_redraw()

func toggle_expanded() -> void:
	expanded = not expanded
	_layout()

func _draw() -> void:
	if game == null: return
	draw_style_box(panel_style, Rect2(Vector2.ZERO, size))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(12, 22), tr("MAPA DA MISSÃO"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("bad3a7"))
	var center := size * Vector2(0.5, 0.55)
	var radius := size.x * 0.35
	draw_circle(center, radius, Color("293642"))
	draw_arc(center, radius, 0, TAU, 64, Color("8297a0"), 1.4, true)
	draw_arc(center, radius * 0.55, 0, TAU, 40, Color("53616a"), 1.0, true)
	draw_line(center - Vector2(radius, 0), center + Vector2(radius, 0), Color("53616a"))
	draw_line(center - Vector2(0, radius), center + Vector2(0, radius), Color("53616a"))
	_marker(center, radius, game.camp_normal, Color("b7d8bf"), "B")
	_marker(center, radius, game.garden_normal, Color("87b17b"), tr("E"))
	for item in game.items:
		if not item.taken and game._item_available(item):
			_marker(center, radius, item.normal, Color("f2ba90") if item.kind == 0 else Color("d9ceb4"), "")
	if game.ship != null: _marker(center, radius, game.ship_normal, Color("f0e9d9"), "R")
	if game.guide.visible and not game.guide.objective_id.is_empty():
		var offset := _project(game.guide.destination.normalized(), radius)
		if offset.length() > 4.0:
			var direction := offset.normalized()
			var tip := center + direction * clampf(offset.length(), 24.0, radius)
			var tail := center + direction * 9.0
			draw_line(tail, tip, Color("131a22"), 7.0, true)
			draw_line(tail, tip, Color("b7d8bf"), 3.0, true)
			var wing := direction.orthogonal() * 6.0
			draw_colored_polygon(PackedVector2Array([tip, tip - direction * 11.0 + wing, tip - direction * 11.0 - wing]), Color("f2ba90"))
	var facing := _direction(-game.avatar.global_basis.z).normalized()
	var side := facing.orthogonal()
	draw_circle(center, 8.0, Color("131a22"))
	draw_colored_polygon(PackedVector2Array([center + facing * 8, center - facing * 5 + side * 5, center - facing * 2, center - facing * 5 - side * 5]), Color("ff8c7e"))
	draw_string(font, Vector2(12, size.y - 9), tr("B base   E estufa"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("c2cbd0"))

func _direction(world: Vector3) -> Vector2:
	var north: Vector3 = game.north
	var right: Vector3 = north.cross(game.normal).normalized()
	return Vector2(world.dot(right), -world.dot(north))

func _project(surface: Vector3, radius: float) -> Vector2:
	var direction := _direction(surface)
	var angle: float = game.normal.angle_to(surface)
	if direction.is_zero_approx(): return Vector2.UP * radius if angle > 1.0 else Vector2.ZERO
	return direction.normalized() * minf(angle / (PI * 0.55), 1.0) * radius

func _marker(center: Vector2, radius: float, surface: Vector3, color: Color, icon: String) -> void:
	var point := center + _project(surface, radius)
	draw_circle(point, 5.0 if not icon.is_empty() else 3.0, color)
	if not icon.is_empty():
		draw_string(ThemeDB.fallback_font, point + Vector2(6, 4), icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("f0e9d9"))
