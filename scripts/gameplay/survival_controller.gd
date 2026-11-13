extends Node
## Owns resource drain, solar exposure, warnings, and survival grace timers.
var game: Node3D

func _ready() -> void:
	game = get_parent()

func update_survival(delta: float) -> void:
	if game._at_camp() and game.energy_ready:
		game.oxygen = minf(game.MAX_RESERVE, game.oxygen + delta * 25.0)
	else:
		game.oxygen = maxf(0.0, game.oxygen - delta * game.OXYGEN_RATE * game._pressure())
	game.food = maxf(0.0, game.food - delta * game.FOOD_RATE * game._pressure())
	update_radiation(delta)
	update_last_chance(delta)
	game._update_solar_notices()
	game.base_room.set_solar(game.solar_phase)
	game._update_distant_light()
	update_resource_warnings(delta)

func update_radiation(delta: float) -> void:
	var remaining := delta
	while remaining > 0.00001 and not game.dead:
		var phase_duration: float = {"calm": game.SOLAR_INTERVAL / game._pressure(), "warning": game.SOLAR_WARNING, "active": game.SOLAR_DURATION}[game.solar_phase]
		var step := minf(remaining, maxf(0.0, phase_duration - game.solar_clock))
		if game.solar_phase == "active" and not game.inside:
			game.exposure += step
			if game.exposure >= game.EXPOSURE_LIMIT: game._die()
		else:
			game.exposure = 0.0
		game.solar_clock += step
		remaining -= step
		if game.solar_clock >= phase_duration:
			game.solar_clock = 0.0
			match game.solar_phase:
				"calm":
					game.solar_phase = "warning"
				"warning":
					game.solar_phase = "active"
					game.event_audio.play("solar")
					game.event_audio.play("fog")
				"active":
					game.solar_phase = "calm"
					game.solar_cycle += 1
					game.exposure = 0.0
					game.fog_audio.stop()
					game.alert_audio.stop()
	var duration: float = {"calm": game.SOLAR_INTERVAL / game._pressure(), "warning": game.SOLAR_WARNING, "active": game.SOLAR_DURATION}[game.solar_phase]
	game.solar_remaining = duration - game.solar_clock
	game.solar_fog.visible = game.solar_phase == "active" and not game.inside

func update_resource_warnings(delta := 0.0) -> void:
	game.health_alarm_cooldown = maxf(0, game.health_alarm_cooldown - delta)
	var crossed := false
	var oxygen_crossed := false
	var food_crossed := false
	if game._percent(game.oxygen) <= 25.0 and not game.oxygen_low:
		game.oxygen_low = true
		oxygen_crossed = true
		crossed = true
	if game._percent(game.food) <= 25.0 and not game.food_low:
		game.food_low = true
		food_crossed = true
		crossed = true
	if game._percent(game.oxygen) <= 12.0 and not game.oxygen_critical:
		game.oxygen_critical = true
		oxygen_crossed = true
		crossed = true
	if game._percent(game.food) <= 12.0 and not game.food_critical:
		game.food_critical = true
		food_crossed = true
		crossed = true
	if game._percent(game.oxygen) > 35.0:
		game.oxygen_low = false
		game.oxygen_critical = false
	if game._percent(game.food) > 35.0:
		game.food_low = false
		game.food_critical = false
	if crossed:
		game.health_notice_serial += 1
		var warnings: Array[String] = []
		if oxygen_crossed: warnings.append("O₂ crítico. Vá ao abrigo!" if game.oxygen_critical else "O₂ baixo. Volte ao abrigo.")
		if food_crossed: warnings.append("Comida crítica. Vá à estufa!" if game.food_critical else "Comida baixa. Vá à estufa.")
		game.feedback.notice_message("vitals_%d" % game.health_notice_serial, "\n".join(warnings), false)
	if crossed or (game._percent(minf(game.oxygen, game.food)) <= 12.0 and game.health_alarm_cooldown <= 0):
		game.event_audio.play("vitals")
		game.health_alarm_cooldown = 8.0

func update_last_chance(delta: float) -> void:
	game.oxygen_empty_time = game.oxygen_empty_time + delta if game.oxygen <= 0 else 0.0
	game.food_empty_time = game.food_empty_time + delta if game.food <= 0 else 0.0
	if game.oxygen_empty_time >= game.VITAL_GRACE or game.food_empty_time >= game.VITAL_GRACE:
		game._die()

