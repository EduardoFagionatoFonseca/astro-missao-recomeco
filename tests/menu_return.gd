extends Node
## Outlives the scene being reloaded so victory tests cover the real menu transition.
func watch() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var game := get_tree().current_scene
	assert(game.start_menu.visible and not game.playing and not game.won)
	assert(game.collected == 0 and game.found == [0, 0, 0])
	assert(game.oxygen == game.MAX_RESERVE and game.food == game.MAX_RESERVE)
	assert(not game.controls.enabled)
	print("PASS: boarding, departure film and automatic return to a fresh main menu")
	game.event_audio.stop_all()
	game.music.stop()
	game.base_music.stop()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()
