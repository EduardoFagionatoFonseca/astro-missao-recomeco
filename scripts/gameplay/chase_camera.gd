extends RefCounted
## Keeps steering stable while the camera catches up to the astronaut.
var heading := Vector3.ZERO
var steering := Vector3.ZERO
var previous_up := Vector3.ZERO

func steering_forward(up: Vector3, camera_forward: Vector3, moving: bool) -> Vector3:
	if not moving:
		steering = Vector3.ZERO
		return camera_forward
	if steering.is_zero_approx():
		steering = camera_forward
	return steering.slide(up).normalized()

func transport(old_up: Vector3, up: Vector3) -> void:
	steering = Quaternion(old_up, up) * steering

func update(game: Node3D, delta: float) -> void:
	var up: Vector3 = game.normal
	var facing: Vector3 = (-game.avatar.global_basis.z).slide(up).normalized()
	if heading.is_zero_approx():
		heading = (-game.camera.global_basis.z).slide(up).normalized()
		if heading.is_zero_approx(): heading = facing
	else:
		heading = (Quaternion(previous_up, up) * heading).slide(up).normalized()
	previous_up = up
	var angle := heading.signed_angle_to(facing, up)
	var turn := clampf(angle * (1.0 - exp(-4.0 * delta)), -2.4 * delta, 2.4 * delta)
	heading = heading.rotated(up, turn)
	var target: Vector3 = game.avatar.global_position + up * 1.1
	var desired: Vector3 = game.avatar.global_position + up * 4.7 - heading * 7.3
	game._update_camera_transform(desired, target, up, true, delta)
	# Looking at the astronaut from the actual camera position keeps it in frame through a U-turn.
	game.camera.look_at(target, up)

func reset() -> void:
	heading = Vector3.ZERO
	steering = Vector3.ZERO
