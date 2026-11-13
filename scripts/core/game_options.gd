extends Node
signal language_changed
var difficulty := 1
var language := "pt_BR"
const LEVELS := [0.8, 1.0, 1.2]

func _ready() -> void:
	var translation := Translation.new()
	translation.locale = "en"
	var portuguese := Translation.new()
	portuguese.locale = "pt_BR"
	var file := FileAccess.open("res://assets/i18n/en.json", FileAccess.READ)
	var messages: Dictionary = JSON.parse_string(file.get_as_text())
	for key in messages:
		translation.add_message(key, messages[key])
		portuguese.add_message(key, key)
	TranslationServer.add_translation(translation)
	TranslationServer.add_translation(portuguese)
	var config := ConfigFile.new()
	config.load("user://game.cfg")
	difficulty = clampi(int(config.get_value("game", "difficulty", 1)), 0, 2)
	set_language(str(config.get_value("game", "language", "pt_BR")))

func set_language(value: String) -> void:
	language = value if value in ["pt_BR", "en"] else "pt_BR"
	TranslationServer.set_locale(language)
	_save()
	language_changed.emit()

func set_difficulty(value: int) -> void:
	difficulty = clampi(value, 0, 2)
	_save()

func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "language", language)
	config.set_value("game", "difficulty", difficulty)
	config.save("user://game.cfg")

func pressure(progress: float) -> float:
	return LEVELS[difficulty] * (1.0 + clampf(progress, 0, 1) * 0.35)
