extends Node
## Handles walking, pickups, and the rescue capsule on the planet surface.
var game: Node3D
const ROVER_OFFSET := 1.7

func _ready() -> void:
	game = get_parent()

func update_movement(delta: float) -> void:
	var input: Vector2 = (game.controls.direction() + game.pad).limit_length()
	var moving := input.length() > 0.05
	var old: Vector3 = game.normal
	var forward: Vector3 = (-game.camera.global_basis.z).slide(game.normal).normalized()
	if forward.length() < 0.1: forward = game.north
	var right: Vector3 = game.camera.global_basis.x.slide(game.normal).normalized()
	var direction: Vector3 = right * input.x + forward * input.y
	if moving:
		var candidate: Vector3 = (game.normal + direction * game._move_speed() / game.R * delta).normalized()
		var floor_before: float = game.terrain.height_at(game.normal)
		var floor_after: float = game.terrain.height_at(candidate)
		if floor_after <= floor_before + 0.10 or game.altitude >= floor_after - 0.025:
			game.normal = candidate
		var transport := Quaternion(old, game.normal)
		game.north = (transport * game.north).slide(game.normal).normalized()
		game._align(game.avatar, game.normal, direction)
		game.walk += delta * 8.0
	else:
		game._align(game.avatar, game.normal, -game.avatar.basis.z)
	var ground: float = game.terrain.height_at(game.normal)
	if game.altitude > ground + 0.001 or game.hop_velocity > 0:
		game.hop_velocity -= game.HOP_GRAVITY * delta
		game.altitude += game.hop_velocity * delta
		if game.altitude <= ground and game.hop_velocity <= 0:
			game.altitude = ground
			game.hop_velocity = 0
	else:
		game.altitude = ground
		game.hop_velocity = 0
	game.hop = maxf(0, game.altitude - ground)
	game.avatar.position = game.normal * (game.R + game.altitude)
	game.astronaut.position.y = absf(sin(game.walk)) * input.length() * 0.055
	game.astronaut.rotation.z = sin(game.walk) * input.length() * 0.045
	update_rover(delta)
	game._update_third_person_camera(true, delta)

func item_available(item: Dictionary) -> bool:
	return kind_available(item.kind)

func kind_available(kind: int) -> bool:
	if kind == game.ItemKind.PART: return true
	if kind == game.ItemKind.PHOTO and not game._rover_unlocked(): return false
	return game.signal_transmitted and game.communications_online

func update_rover(delta: float, snap := false) -> void:
	if not game._rover_unlocked() or game.inside: return
	var surface_position: Vector3 = game.normal * game.R
	var side: Vector3 = game.avatar.basis.x * ROVER_OFFSET + game.avatar.basis.z * 0.65
	var target := (surface_position + side).normalized()
	var previous: Vector3 = game.rover.position.normalized()
	var up := target if snap else previous.slerp(target, 1.0 - exp(-6.5 * delta)).normalized()
	game.rover.position = up * (game.R + game.terrain.height_at(up))
	game._align(game.rover, up, -game.avatar.basis.z)

func sync_resource_visibility() -> void:
	for item in game.items:
		item.node.visible = not game.inside and not item.taken and item_available(item)

func can_reach(item: Dictionary) -> bool:
	return game.normal.dot(item.normal) > cos(1.25 / game.R) and absf(game.altitude - game.terrain.height_at(item.normal)) < 0.24

func nearest() -> int:
	var index := -1
	var best := -2.0
	for i in range(game.items.size()):
		if game.items[i].taken or not item_available(game.items[i]): continue
		var dot: float = game.normal.dot(game.items[i].normal)
		if dot > best:
			best = dot
			index = i
	return index

func update_items(delta: float) -> void:
	for i in range(game.items.size()):
		var item: Dictionary = game.items[i]
		if item.taken or not item_available(item): continue
		item.visual.position.y = 0.08 + sin(game.elapsed * 2.0 + i) * 0.055
		item.marker.position.y = 1.0 + sin(game.elapsed * 2 + i) * 0.1
		item.visual.rotation.y += delta * 0.25

func collect(index: int) -> void:
	if index < 0 or index >= game.items.size() or game.items[index].taken or not item_available(game.items[index]): return
	var item: Dictionary = game.items[index]
	item.taken = true
	item.node.visible = false
	game.found[item.kind] += 1
	game.collected += 1
	game.event_audio.play("photo" if item.kind == game.ItemKind.PHOTO else "collect")
	if item.kind == game.ItemKind.PHOTO:
		game.photo_archive.collect(item.photo)
	elif item.kind == game.ItemKind.FUEL and game._rover_unlocked():
		game.rover.reparent(game)
		update_rover(0.0, true)
		sync_resource_visibility()
		game.feedback.notice_message("rover_unlocked", tr("Rover ativo. Velocidade +%d%%. Pontos de foto liberados!") % game._rover_speed_bonus(), false)
		game._ask_task(game.task_question.ROVER_TASK)
	try_rescue()

func try_rescue() -> void:
	if game.collected == game.TOTAL and game.signal_transmitted and game.communications_online and game.ship == null:
		_begin_rescue()

func _begin_rescue() -> void:
	game.ship_normal = (game.normal + game.north * 0.14).normalized()
	game.ship = game._surface(game.ship_normal)
	game.ship.visible = not game.inside
	game.ship_timer = 0.0
	var body: MeshInstance3D = game._cylinder(game.ship, 0.7, 1.8, Color("e6dfcc"), Vector3(0, 1.3, 0))
	body.name = "RescueCapsule"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.7
	cone.height = 0.9
	game._mesh(game.ship, cone, game.PEACH, Vector3(0, 2.65, 0))
	game._ball(game.ship, 0.31, Color("789fb2"), Vector3(0, 1.75, -0.63)).scale = Vector3(1, 1, 0.4)
	for i in range(3):
		var a := i * TAU / 3
		var leg: MeshInstance3D = game._box(game.ship, Vector3(0.18, 0.8, 0.3), Color("a1b1ac"), Vector3(sin(a) * 0.75, 0.4, cos(a) * 0.75))
		leg.rotation.z = -sin(a) * 0.4

func update_ship(delta: float) -> void:
	if game.ship == null: return
	game.ship_timer += delta
	var height := pow(maxf(0, 1.0 - game.ship_timer / 9.0), 2.0) * 20.0
	game.ship.position = game.ship_normal * (game.R + game.terrain.height_at(game.ship_normal) + height)
	if game.ship_timer >= 9.0 and not game.ship_landed:
		game.ship_landed = true
		game.feedback.transmit("landed", "Pousamos. Venha à nave.", true)
		game._chime(880)

func interact() -> void:
	if game.dead or game.won or game.transitioning or game.minigames.visible or game.audio_settings.visible or game.task_question.visible or game.photo_archive.is_open() or game.portrait_hint.visible: return
	if game.inside:
		var station: String = game.base_room.station_at(game.avatar.position)
		if station == "exit": game._transition_to(false)
		elif station == "energy": game.minigames.open_power(game.energy_ready and game.energy_charge > 30)
		elif station == "signal" and not (game.signal_transmitted and game.communications_online):
			game.minigames.open_signal(game.energy_ready, game.found[1], game.signal_transmitted, game.signal_failures)
		game._update_controls()
		return
	if game.ship_landed and game.normal.dot(game.ship_normal) > 0.975:
		game._finish()
		return
	if game._at_camp():
		game._transition_to(true)
		return
	if game._at_garden() and game.food < game.MAX_RESERVE - 1.0:
		game.food = game.MAX_RESERVE
		game.food_empty_time = 0.0
		game._chime(550)
		game._ask_task("food")
		return
	var near := nearest()
	if near >= 0 and can_reach(game.items[near]):
		collect(near)
