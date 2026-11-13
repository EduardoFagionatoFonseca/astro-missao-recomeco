extends Node
## Advances the power and communications cycles and handles their repair results.
var game: Node3D

func _ready() -> void:
	game = get_parent()

func advance(delta: float) -> void:
	if game.energy_ready:
		game.energy_clock += delta * game._pressure()
		game.energy_charge = maxf(0, 100.0 * (1.0 - game.energy_clock / game.ENERGY_INTERVAL))
		if game.energy_charge <= 30 and not game.energy_low_announced and game.communications_online:
			game.energy_low_announced = true
			game.feedback.transmit("power_low_%d" % game.energy_failures, "Energia em 30%. Repare a base.", true, game.feedback.AXIOS)
		if game.energy_clock >= game.ENERGY_INTERVAL:
			game.energy_ready = false
			game.energy_charge = 0
			game.energy_failures += 1
			game.event_audio.play("energy")
			game.feedback.transmit("power_tutorial", "Energia baixa. Produção de O₂ interrompida.", true, game.feedback.AXIOS)
			if game.minigames.visible and game.minigames.mode == "signal":
				game.minigames.open_signal(false, game.found[1], game.signal_transmitted, game.signal_failures)
	if game.communications_online and game.ship == null:
		game.signal_clock += delta * game._pressure()
		if game.signal_clock >= game.SIGNAL_INTERVAL:
			game.communications_online = false
			game.signal_transmitted = false
			game._sync_resource_visibility()
			game.signal_failures += 1
			game.feedback.set_link(false)
			game.event_audio.play("disconnect")
			game.feedback.notice_message("comm_tutorial", "Sem sinal. Recursos e avisos ocultos.", false)

func power_repaired() -> void:
	game.energy_ready = true
	game.energy_charge = 100
	game.energy_clock = 0
	game.energy_low_announced = false
	game.base_room.set_power(true, game.energy_charge)
	game._chime(660)
	game._update_controls()

func signal_sent() -> void:
	game.communications_online = true
	game.feedback.set_link(true)
	game.signal_transmitted = game.found[1] >= 6
	game.signal_clock = 0
	game._chime(880)
	if game.signal_transmitted:
		game.feedback.transmit("signal", "Sinal recebido. Recursos localizados.")
	game._sync_resource_visibility()
	game._try_rescue()
	game._update_controls()
