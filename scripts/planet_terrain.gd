extends RefCounted
## Shared radial height field: the render mesh and player feet use the same surface.
const R := 12.0
var craters: Array[Dictionary] = []
var platforms: Array[Dictionary] = []
var hills: Array[Dictionary] = []

func _init() -> void:
	# A small practice ledge near the shelter, clear of its door and oxygen zone.
	platforms.append({"normal": Vector3(-0.34, 1, -0.25).normalized(), "radius": 0.95, "height": 0.38})
	craters.append({"normal": Vector3(0.38, 1, -0.26).normalized(), "radius": 1.05})
	for i in range(18):
		var y := 1.0 - (float(i) + 0.5) / 18 * 2
		var a := i * 2.39996323
		var n := Vector3(cos(a) * sqrt(1 - y*y), y, sin(a) * sqrt(1 - y*y))
		if n.dot(Vector3.UP) > 0.85 or n.dot(Vector3(0.9, -0.15, -0.5).normalized()) > 0.91: continue
		if i % 3 == 0: platforms.append({"normal": n, "radius": 0.85, "height": 0.44})
		elif i % 3 == 1: craters.append({"normal": n, "radius": 1.15})
		else: hills.append({"normal": n, "radius": 1.5})

func _distance(n: Vector3, center: Vector3) -> float:
	return acos(clampf(n.dot(center), -1, 1)) * R

func height_at(n: Vector3, include_platforms := true) -> float:
	var height := 0.0
	for crater in craters:
		if n.dot(crater.normal) < cos(crater.radius / R): continue
		var d: float = _distance(n, crater.normal) / crater.radius
		height += -0.28 * (1 - pow(d / 0.75, 2)) if d < 0.75 else 0.15 * sin((d - 0.75) / 0.25 * PI)
	for hill in hills:
		if n.dot(hill.normal) < cos(hill.radius / R): continue
		height += 0.16 * (0.5 + 0.5 * cos(_distance(n, hill.normal) / hill.radius * PI))
	if include_platforms:
		for platform in platforms:
			if n.dot(platform.normal) >= cos(platform.radius / R): height = maxf(height, platform.height)
	return height

func make_planet() -> ArrayMesh:
	var sphere := SphereMesh.new()
	sphere.radius = R
	sphere.height = R * 2
	sphere.radial_segments = 256
	sphere.rings = 128
	var arrays := sphere.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors := PackedColorArray()
	for i in range(vertices.size()):
		var n := vertices[i].normalized()
		var h := height_at(n, false)
		vertices[i] = n * (R + h)
		colors.append(Color("a76550").lerp(Color("cf8e68"), clampf((h + 0.28) / 0.44, 0, 1)))
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var source := ArrayMesh.new()
	source.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var tool := SurfaceTool.new()
	tool.create_from(source, 0)
	tool.generate_normals()
	return tool.commit()

func make_platform(platform: Dictionary) -> ArrayMesh:
	var up: Vector3 = platform.normal
	var right := Vector3.RIGHT.slide(up).normalized()
	var forward := right.cross(up).normalized()
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	for i in range(32):
		var a := TAU * i / 32
		var b := TAU * (i + 1) / 32
		var n1: Vector3 = (up + (right*cos(a)+forward*sin(a))*tan(platform.radius/R)).normalized()
		var n2: Vector3 = (up + (right*cos(b)+forward*sin(b))*tan(platform.radius/R)).normalized()
		var top1: Vector3 = n1*(R+platform.height)
		var top2: Vector3 = n2*(R+platform.height)
		var bottom1 := n1*(R-0.06)
		var bottom2 := n2*(R-0.06)
		# Curved cap and vertical walls follow the same radial footprint as height_at.
		for point in [up*(R+platform.height), top2, top1]:
			vertices.append(point)
			colors.append(Color("daa27b"))
		for point in [top1, top2, bottom2, top1, bottom2, bottom1]:
			vertices.append(point)
			colors.append(Color("99604f"))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var tool := SurfaceTool.new()
	tool.create_from(mesh, 0)
	tool.generate_normals()
	return tool.commit()
