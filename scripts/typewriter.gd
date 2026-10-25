extends RefCounted
signal typing_tick
const CHARACTERS_PER_SECOND := 70.0
var label: Label
var progress := 0.0
var sound_clock := 0.0
var length := 0

func begin(target: Label, text: String) -> void:
	label = target
	var parts := text.split("\n")
	for i in range(parts.size()): parts[i] = str(TranslationServer.translate(parts[i]))
	var translated := "\n".join(parts)
	label.text = translated
	label.visible_characters = 0
	length = translated.length()
	progress = 0
	sound_clock = 0

func advance(delta: float) -> void:
	if not is_instance_valid(label) or label.visible_characters >= length: return
	var previous := label.visible_characters
	progress += delta * CHARACTERS_PER_SECOND
	sound_clock += delta
	label.visible_characters = mini(length, floori(progress))
	if label.visible_characters > previous and sound_clock >= 0.055:
		var character := label.text.substr(label.visible_characters - 1, 1)
		if not character.strip_edges().is_empty(): typing_tick.emit()
		sound_clock = 0

func cancel() -> void:
	label = null
	length = 0
