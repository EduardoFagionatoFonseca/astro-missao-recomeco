extends Button
## A draggable inventory slot. The inventory controller owns all item data.

var inventory_ui: Control
var slot_index := -1

func configure(controller: Control, index: int) -> void:
	inventory_ui = controller
	slot_index = index
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		inventory_ui.call("request_use_slot", slot_index)
		accept_event()

func _get_drag_data(_at_position: Vector2) -> Variant:
	var drag_data: Dictionary = inventory_ui.call("begin_drag", slot_index)
	if drag_data.is_empty(): return null
	var preview := Label.new()
	var stack: Dictionary = drag_data.stack
	preview.text = str(stack.item_id) + " × " + str(stack.count)
	preview.add_theme_font_size_override("font_size", 16)
	preview.add_theme_color_override("font_color", Color("f0e9d9"))
	set_drag_preview(preview)
	return drag_data

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and bool(data.get("inventory_stack", false))

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	inventory_ui.call("drop_stack", slot_index, data)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		inventory_ui.call("finish_drag", get_viewport().gui_is_drag_successful())
