extends RefCounted
## Keep the view steady during movement and recenter gently after the player stops.
const RECENTER_DELAY := 0.2
const MAX_TURN_RATE := 0.85
const HEADING_RESPONSE := 2.0

var heading := Vector3.ZERO
var previous_up := Vector3.ZERO
var idle_time := 0.0

func update(game: Node3D, delta: float, moving: bool) -> void:
	var up: Vector3 = game.normal
	var facing: Vector3 = (-game.avatar.global_basis.z).slide(up).normalized()
	if heading.is_zero_approx():
		heading = (-game.camera.global_basis.z).slide(up).normalized()
		if heading.is_zero_approx(): heading = facing
	else:
		heading = (Quaternion(previous_up, up) * heading).slide(up).normalized()
	previous_up = up

	idle_time = 0.0 if moving else idle_time + delta
	if idle_time >= RECENTER_DELAY:
		var angle := heading.signed_angle_to(facing, up)
		var turn := angle * (1.0 - exp(-HEADING_RESPONSE * delta))
		heading = heading.rotated(up, clampf(turn, -MAX_TURN_RATE * delta, MAX_TURN_RATE * delta))

	var ground: Vector3 = game.avatar.global_position - up * game.hop
	var target := ground + up * 1.1
	var desired := ground + up * 4.7 - heading * 7.3
	game._update_camera_transform(desired, target, up, true, delta)

func reset() -> void:
	heading = Vector3.ZERO
	idle_time = 0.0
