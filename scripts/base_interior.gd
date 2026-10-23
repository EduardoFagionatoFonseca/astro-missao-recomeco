extends Node3D
## A roofless room with solid furniture footprints and a fixed readable camera.
const STATIONS := {"energy": Vector3(-3.6, 0, -1.6), "signal": Vector3(3.6, 0, -1.6), "exit": Vector3(0, 0, 3.0)}
const BLOCKERS := [Rect2(-4.6, -2.6, 1.8, 2.0), Rect2(2.8, -2.6, 1.8, 2.0), Rect2(-4.6, 1.0, 1.6, 1.8)]
var lights: Array[MeshInstance3D] = []
var status: Label3D

func _ready() -> void:
	position = Vector3(0, -100, 0)
	_box(Vector3(10, 0.24, 8), Vector3(0, -0.14, 0), Color("647e81"))
	_box(Vector3(10.4, 0.18, 8.4), Vector3(0, -0.32, 0), Color("253b49"))
	for x in range(-4, 5):
		_box(Vector3(0.025, 0.012, 7.5), Vector3(x, 0, 0), Color("829697"))
	for z in range(-3, 4):
		_box(Vector3(9.5, 0.012, 0.025), Vector3(0, 0, z), Color("829697"))
	_box(Vector3(10, 2.9, 0.25), Vector3(0, 1.4, -4), Color("b8c6bd"))
	for x in [-5, 5]:
		_box(Vector3(0.24, 1.1, 8), Vector3(x, 0.5, 0), Color("b8c6bd"))
	_box(Vector3(3.8, 1.8, 0.08), Vector3(0, 1.6, -3.83), Color("243c55"))
	_box(Vector3(3.45, 1.45, 0.08), Vector3(0, 1.6, -3.75), Color("c18b70"))
	_box(Vector3(0.06, 1.5, 0.08), Vector3(0, 1.6, -3.65), Color("e5decb"))
	# A low far-side silhouette visible through the window.
	_box(Vector3(3.4, 0.35, 0.05), Vector3(0, 1.0, -3.65), Color("9c6356"))
	for side in [-1, 1]:
		var x: float = side * 3.7
		_box(Vector3(1.5, 0.8, 1.5), Vector3(x, 0.4, -1.6), Color("36525e"))
		var screen := _box(Vector3(1.35, 0.12, 1.2), Vector3(x, 0.87, -1.6), Color("182e41"))
		screen.rotation.x = -0.22
		for i in range(3):
			var lamp := _box(Vector3(0.23, 0.04, 0.09), Vector3(x - 0.4 + i * 0.4, 0.98, -1.35), Color("f2ba90"))
			lights.append(lamp)
	_label("ENERGIA", Vector3(-3.6, 1.8, -2.4), 34)
	_label("COMUNICAÇÃO", Vector3(3.5, 1.8, -2.4), 30)
	status = _label("RESERVA DE EMERGÊNCIA", Vector3(0, 2.8, -3.5), 26)
	_box(Vector3(1.2, 0.4, 2.2), Vector3(-3.9, 0.2, 2), Color("3d5964"))
	_box(Vector3(1.1, 0.2, 1.7), Vector3(-3.9, 0.5, 2.15), Color("b7d8bf"))
	_box(Vector3(0.8, 0.23, 0.35), Vector3(-3.9, 0.6, 1.45), Color("e7dfc9"))
	_box(Vector3(2.5, 0.04, 0.9), Vector3(0, 0.02, 3.35), Color("f2ba90"))
	_label("SAÍDA", Vector3(0, 0.18, 3.5), 30)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 5, 0)
	lamp.omni_range = 16
	lamp.light_color = Color("ffe8bf")
	lamp.light_energy = 2.0
	add_child(lamp)
	visible = false

func _box(size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	node.material_override = mat
	add_child(node)
	node.position = at
	return node

func _label(text: String, at: Vector3, size: int) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.009
	label.position = at
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("f0e9d9")
	add_child(label)
	return label

func move_player(from: Vector3, direction: Vector3) -> Vector3:
	var local := from - position
	# Resolve axes separately for sliding along walls and consoles.
	var next := local
	next.x = clampf(local.x + direction.x, -4.5, 4.5)
	if _blocked(next): next.x = local.x
	next.z = clampf(local.z + direction.z, -3.35, 3.35)
	if _blocked(next): next.z = local.z
	next.y = 0
	return position + next

func _blocked(at: Vector3) -> bool:
	for rect: Rect2 in BLOCKERS:
		if rect.grow(0.22).has_point(Vector2(at.x, at.z)): return true
	return false

func station_at(at: Vector3) -> String:
	var local := at - position
	for key: String in STATIONS:
		if local.distance_to(STATIONS[key]) < (1.95 if key != "exit" else 1.1): return key
	return ""

func set_power(ready: bool, charge: float) -> void:
	status.text = "ENERGIA %d%%  /  O₂ ATIVO" % charge if ready else "RESERVA DE EMERGÊNCIA  /  REPARE A ENERGIA"
	for light in lights:
		light.material_override.albedo_color = Color("b7d8bf") if ready else Color("f2ba90")
