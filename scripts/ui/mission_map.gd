extends Control
## Small top-down mission map showing known outpost, greenhouse, caches and the astronaut.

var game: Node3D
var panel_style: StyleBoxFlat
var expanded := false

func _ready() -> void:
	custom_minimum_size = Vector2(226, 226)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_style = preload("res://scripts/ui/ui_theme.gd").box(Color("111820eb"), Color("53616a"), 12)
	get_viewport().size_changed.connect(_layout)
	_layout()

func configure(mission: Node3D) -> void:
	game = mission
	queue_redraw()

func refresh() -> void:
	if game != null: queue_redraw()

func _layout() -> void:
	var view := get_viewport_rect().size
	var map_size := Vector2(360, 360) if expanded else Vector2(226, 226)
	custom_minimum_size = map_size
	size = map_size
	position = Vector2(view.x - map_size.x - 22, view.y - map_size.y - 22)

func toggle_expanded() -> void:
	expanded = not expanded
	_layout()
	queue_redraw()

func _draw() -> void:
	if game == null: return
	draw_style_box(panel_style, Rect2(Vector2.ZERO, custom_minimum_size))
	draw_string(ThemeDB.fallback_font, Vector2(16, 23), "MAPA DA MISSÃO", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("bad3a7"))
	var center := Vector2(custom_minimum_size.x * 0.5, custom_minimum_size.y * 0.57)
	var map_radius := 145.0 if expanded else 83.0
	draw_circle(center, map_radius, Color("293642"))
	draw_arc(center, map_radius, 0, TAU, 72, Color("8297a0"), 1.4, true)
	draw_arc(center, map_radius * 0.55, 0, TAU, 48, Color("53616a"), 1.0, true)
	draw_line(center + Vector2(-map_radius, 0), center + Vector2(map_radius, 0), Color("53616a"), 1.0)
	draw_line(center + Vector2(0, -map_radius), center + Vector2(0, map_radius), Color("53616a"), 1.0)
	_draw_marker(center, game.camp_normal, Color("b7d8bf"), "B")
	_draw_marker(center, game.garden_normal, Color("87b17b"), "E")
	if game.communications_online and game.signal_transmitted:
		for item in game.items:
			if not item.taken:
				_draw_marker(center, item.normal, Color("f2ba90"), "·")
		for cache in game.supplies:
			if not cache.taken:
				_draw_marker(center, cache.normal, Color("e2ad68"), "·")
	if game.ship != null:
		_draw_marker(center, game.ship_normal, Color("f0e9d9"), "R")
	_draw_marker(center, game.normal, Color("ff7468"), "▲", true)
	var map_hint := "B base   E estufa   ▲ você   M reduzir" if expanded else "B base   E estufa   ▲ você   M ampliar"
	draw_string(ThemeDB.fallback_font, Vector2(17, custom_minimum_size.y - 11), map_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 12 if expanded else 11, Color("c2cbd0"))

func _draw_marker(center: Vector2, surface_normal: Vector3, color: Color, icon: String, emphasized := false) -> void:
	var point := center + Vector2(surface_normal.x, surface_normal.z) * 67.0
	var radius := 5.5 if emphasized else 4.0
	draw_circle(point, radius + 2.0 if emphasized else radius, Color("10151c"))
	draw_circle(point, radius, color)
	if icon != "·":
		draw_string(ThemeDB.fallback_font, point + Vector2(-4, 4), icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("f0e9d9"))
	if emphasized:
		draw_arc(point, radius + 4.0, 0, TAU, 28, color.lightened(0.25), 1.2, true)
