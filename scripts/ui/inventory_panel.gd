extends Control
## Stackable 36-slot backpack and a selectable nine-slot Minecraft-style hotbar.
signal inventory_changed(counts: Dictionary)
signal use_item_requested(item_id: String, slot_index: int)

const SLOT_COUNT := 36
const HOTBAR_SIZE := 9
const MAX_STACK := 64
const SLOT_SIZE := Vector2(54, 54)
const SLOT_GAP := 6
const ITEM_ICON_TEXTURES := {
	"oxygen_tube": preload("res://assets/ui/items/oxygen.svg"),
	"meal_pack": preload("res://assets/ui/items/ration.svg"),
	"stone": preload("res://assets/ui/items/stone.svg"),
	"antenna_part": preload("res://assets/ui/items/antenna.svg"),
	"fuel_cell": preload("res://assets/ui/items/fuel.svg")
}
const ITEM_DEFINITIONS := {
	"oxygen_tube": {"name": "Cilindro de oxigênio", "icon": "O₂"},
	"meal_pack": {"name": "Ração", "icon": "RA"},
	"stone": {"name": "Pedra marciana", "icon": "PD"},
	"antenna_part": {"name": "Peça de antena", "icon": "AN"},
	"fuel_cell": {"name": "Célula de combustível", "icon": "CB"}
}

var game: Node3D
var slots: Array[Dictionary] = []
var opened := false
var selected_slot := 0
var hotbar: HBoxContainer
var hotbar_buttons: Array[Button] = []
var hotbar_icons: Array[TextureRect] = []
var hotbar_counts: Array[Label] = []
var hotbar_keys: Array[Label] = []
var backpack_panel: PanelContainer
var inventory_buttons: Array[Button] = []
var inventory_icons: Array[TextureRect] = []
var inventory_counts: Array[Label] = []
var inventory_keys: Array[Label] = []
var status_label: Label
var drag_origin := -1
var drag_stack: Dictionary = {}
var last_snapshot: Array[Dictionary] = []
var last_selected_slot := -1

func _ready() -> void:
	theme = preload("res://scripts/ui/ui_theme.gd").create()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	for slot_index in range(SLOT_COUNT):
		slots.append(_empty_slot())
	_build_backpack()
	_build_hotbar()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_refresh()

func _empty_slot() -> Dictionary:
	return {"item_id": "", "count": 0}

func configure(mission: Node3D) -> void:
	game = mission
	for item_id: String in game.inventory:
		var amount := int(game.inventory[item_id])
		if amount > 0: add_item(item_id, amount, false)
	_emit_inventory()
	_refresh()

func _build_backpack() -> void:
	var shade := ColorRect.new()
	shade.color = Color("070b12b8")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.gui_input.connect(_on_shade_input)
	shade.name = "InventoryShade"
	add_child(shade)
	shade.hide()
	backpack_panel = PanelContainer.new()
	backpack_panel.name = "Backpack"
	backpack_panel.custom_minimum_size = Vector2(602, 378)
	backpack_panel.add_theme_stylebox_override("panel", preload("res://scripts/ui/ui_theme.gd").box(Color("191c21f8"), Color("b9a373"), 18))
	add_child(backpack_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	backpack_panel.add_child(column)
	var heading := Label.new()
	heading.text = "MOCHILA DE EXPLORAÇÃO"
	heading.add_theme_font_size_override("font_size", 23)
	heading.add_theme_color_override("font_color", Color("f0e9d9"))
	column.add_child(heading)
	var grid := GridContainer.new()
	grid.columns = HOTBAR_SIZE
	grid.add_theme_constant_override("h_separation", SLOT_GAP)
	grid.add_theme_constant_override("v_separation", SLOT_GAP)
	column.add_child(grid)
	for slot_index in range(SLOT_COUNT):
		var slot_button := _make_slot_button(slot_index, inventory_buttons, inventory_icons, inventory_counts, inventory_keys)
		slot_button.pressed.connect(request_use_slot.bind(slot_index))
		grid.add_child(slot_button)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color("a3b7c4"))
	status_label.text = "Clique usa itens consumíveis  ·  Arraste organiza  ·  F ou clique direito usa  ·  I fecha"
	column.add_child(status_label)
	backpack_panel.hide()

func _build_hotbar() -> void:
	hotbar = HBoxContainer.new()
	hotbar.name = "Hotbar"
	hotbar.add_theme_constant_override("separation", SLOT_GAP)
	add_child(hotbar)
	for slot_index in range(HOTBAR_SIZE):
		var slot_button := _make_slot_button(slot_index, hotbar_buttons, hotbar_icons, hotbar_counts, hotbar_keys)
		slot_button.pressed.connect(select_hotbar.bind(slot_index))
		hotbar.add_child(slot_button)

func _make_slot_button(slot_index: int, buttons: Array[Button], icon_rects: Array[TextureRect], count_labels: Array[Label], key_labels: Array[Label]) -> Button:
	var button_script := preload("res://scripts/ui/inventory_slot_button.gd")
	var slot_button: Button = button_script.new()
	slot_button.call("configure", self, slot_index)
	slot_button.custom_minimum_size = SLOT_SIZE
	slot_button.add_theme_font_size_override("font_size", 18)
	slot_button.add_theme_color_override("font_color", Color("f0e9d9"))
	slot_button.focus_mode = Control.FOCUS_NONE
	var item_icon := TextureRect.new()
	item_icon.name = "ItemIcon"
	item_icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	item_icon.offset_left = -19
	item_icon.offset_top = -19
	item_icon.offset_right = 19
	item_icon.offset_bottom = 19
	item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_button.add_child(item_icon)
	var count_label := Label.new()
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	count_label.offset_left = -30
	count_label.offset_top = -21
	count_label.offset_right = -3
	count_label.offset_bottom = -1
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.add_theme_color_override("font_color", Color.WHITE)
	count_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	count_label.add_theme_constant_override("shadow_offset_x", 1)
	count_label.add_theme_constant_override("shadow_offset_y", 1)
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_button.add_child(count_label)
	var key_label := Label.new()
	key_label.text = str(slot_index + 1) if slot_index < HOTBAR_SIZE else ""
	key_label.position = Vector2(4, 1)
	key_label.add_theme_font_size_override("font_size", 11)
	key_label.add_theme_color_override("font_color", Color("bac3c8"))
	key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_button.add_child(key_label)
	buttons.append(slot_button)
	icon_rects.append(item_icon)
	count_labels.append(count_label)
	key_labels.append(key_label)
	return slot_button

func _on_shade_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_inventory()
		get_viewport().set_input_as_handled()

func toggle_inventory() -> void:
	if opened: close_inventory()
	else: open_inventory()

func open_inventory() -> void:
	if opened: return
	opened = true
	get_node("InventoryShade").show()
	backpack_panel.show()
	hotbar.hide()
	_layout()
	_refresh()
	if game != null: game._update_controls()

func close_inventory() -> void:
	if not opened: return
	opened = false
	get_node("InventoryShade").hide()
	backpack_panel.hide()
	hotbar.show()
	if game != null: game._update_controls()

func select_hotbar(slot_index: int) -> void:
	selected_slot = clampi(slot_index, 0, HOTBAR_SIZE - 1)
	_refresh()

func use_selected_item() -> void:
	request_use_slot(selected_slot)

func request_use_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= slots.size(): return
	var item_id: String = slots[slot_index].item_id
	if item_id in ["oxygen_tube", "meal_pack"]:
		use_item_requested.emit(item_id, slot_index)

func get_selected_item() -> Dictionary:
	return slots[selected_slot].duplicate()

func get_quantity(item_id: String) -> int:
	var total := 0
	for stack in slots:
		if stack.item_id == item_id: total += int(stack.count)
	return total

func can_add(item_id: String, amount := 1) -> bool:
	var remaining := amount
	for stack in slots:
		if stack.item_id == item_id: remaining -= MAX_STACK - int(stack.count)
	for stack in slots:
		if stack.item_id.is_empty(): remaining -= MAX_STACK
	return remaining <= 0

func add_item(item_id: String, amount := 1, notify := true) -> int:
	if not ITEM_DEFINITIONS.has(item_id) or amount <= 0: return amount
	var remaining := amount
	for stack in slots:
		if stack.item_id != item_id or int(stack.count) >= MAX_STACK: continue
		var moved: int = mini(remaining, MAX_STACK - int(stack.count))
		stack.count = int(stack.count) + moved
		remaining -= moved
		if remaining == 0: break
	if remaining > 0:
		for slot_index in range(slots.size()):
			if not slots[slot_index].item_id.is_empty(): continue
			var moved: int = mini(remaining, MAX_STACK)
			slots[slot_index] = {"item_id": item_id, "count": moved}
			remaining -= moved
			if remaining == 0: break
	if remaining != amount:
		_refresh()
		if notify: _emit_inventory()
	return remaining

func remove_item_from_slot(slot_index: int, amount := 1) -> bool:
	if slot_index < 0 or slot_index >= slots.size() or amount <= 0: return false
	var stack: Dictionary = slots[slot_index]
	if stack.item_id.is_empty() or int(stack.count) < amount: return false
	stack.count = int(stack.count) - amount
	if int(stack.count) == 0: slots[slot_index] = _empty_slot()
	_refresh()
	_emit_inventory()
	return true

func begin_drag(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= slots.size() or slots[slot_index].item_id.is_empty(): return {}
	drag_origin = slot_index
	drag_stack = slots[slot_index].duplicate()
	slots[slot_index] = _empty_slot()
	_refresh()
	return {"inventory_stack": true, "origin": slot_index, "stack": drag_stack.duplicate()}

func drop_stack(target_index: int, drag_data: Dictionary) -> void:
	if not drag_data.get("inventory_stack", false): return
	var source_index := int(drag_data.get("origin", -1))
	var incoming: Dictionary = drag_data.get("stack", {}).duplicate()
	if source_index < 0 or source_index >= slots.size() or target_index < 0 or target_index >= slots.size(): return
	if source_index == target_index:
		slots[source_index] = incoming
	elif slots[target_index].item_id.is_empty():
		slots[target_index] = incoming
	elif slots[target_index].item_id == incoming.item_id and int(slots[target_index].count) < MAX_STACK:
		var moved: int = mini(int(incoming.count), MAX_STACK - int(slots[target_index].count))
		slots[target_index].count = int(slots[target_index].count) + moved
		incoming.count = int(incoming.count) - moved
		slots[source_index] = incoming if int(incoming.count) > 0 else _empty_slot()
	else:
		var displaced: Dictionary = slots[target_index]
		slots[target_index] = incoming
		slots[source_index] = displaced
	drag_origin = -1
	drag_stack.clear()
	_refresh()
	_emit_inventory()

func finish_drag(successful: bool) -> void:
	if drag_origin < 0: return
	if not successful: slots[drag_origin] = drag_stack.duplicate()
	drag_origin = -1
	drag_stack.clear()
	_refresh()
	_emit_inventory()

func _emit_inventory() -> void:
	var counts: Dictionary = {}
	for stack in slots:
		if stack.item_id.is_empty(): continue
		counts[stack.item_id] = int(counts.get(stack.item_id, 0)) + int(stack.count)
	inventory_changed.emit(counts)

func refresh() -> void:
	_refresh()

func _refresh() -> void:
	if hotbar_buttons.is_empty(): return
	if slots == last_snapshot and selected_slot == last_selected_slot: return
	for slot_index in range(SLOT_COUNT):
		_update_slot(slot_index, inventory_buttons[slot_index], inventory_icons[slot_index], inventory_counts[slot_index], inventory_keys[slot_index])
		if slot_index < HOTBAR_SIZE:
			_update_slot(slot_index, hotbar_buttons[slot_index], hotbar_icons[slot_index], hotbar_counts[slot_index], hotbar_keys[slot_index])
	if game != null and status_label != null:
		var active: Dictionary = slots[selected_slot]
		var selected_name: String = str(ITEM_DEFINITIONS.get(active.item_id, {}).get("name", "Mão vazia")) if not active.item_id.is_empty() else "Mão vazia"
		status_label.text = "%s   ·   Clique usa itens consumíveis  ·  F ou clique direito usa  ·  I fecha" % selected_name
	last_snapshot = slots.duplicate(true)
	last_selected_slot = selected_slot

func _update_slot(slot_index: int, button: Button, item_icon: TextureRect, count_label: Label, key_label: Label) -> void:
	var stack: Dictionary = slots[slot_index]
	var definition: Dictionary = ITEM_DEFINITIONS.get(stack.item_id, {})
	item_icon.texture = ITEM_ICON_TEXTURES.get(stack.item_id) as Texture2D
	item_icon.visible = item_icon.texture != null
	button.text = "" if item_icon.visible else str(definition.get("icon", ""))
	button.tooltip_text = str(definition.get("name", "Espaço vazio"))
	count_label.text = str(stack.count) if int(stack.count) > 1 else ""
	key_label.add_theme_color_override("font_color", Color("f0e9d9") if slot_index == selected_slot else Color("bac3c8"))
	var selected := slot_index == selected_slot
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("353a40") if not stack.item_id.is_empty() else Color("20242a")
	normal.border_color = Color("e4c47c") if selected else Color("505861")
	normal.set_border_width_all(4 if selected else 2)
	normal.set_corner_radius_all(5)
	normal.content_margin_left = 2
	normal.content_margin_right = 2
	normal.content_margin_top = 2
	normal.content_margin_bottom = 2
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("4b5158")
	hover.border_color = Color("f0d58e")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)

func _layout() -> void:
	var view := get_viewport_rect().size
	hotbar.size = Vector2(HOTBAR_SIZE * SLOT_SIZE.x + (HOTBAR_SIZE - 1) * SLOT_GAP, SLOT_SIZE.y)
	hotbar.position = Vector2((view.x - hotbar.size.x) * 0.5, view.y - SLOT_SIZE.y - 22)
	backpack_panel.size = backpack_panel.custom_minimum_size
	backpack_panel.position = (view - backpack_panel.size) * 0.5

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not game is Node3D: return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			select_hotbar(posmod(selected_slot - 1, HOTBAR_SIZE))
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			select_hotbar((selected_slot + 1) % HOTBAR_SIZE)
			get_viewport().set_input_as_handled()
