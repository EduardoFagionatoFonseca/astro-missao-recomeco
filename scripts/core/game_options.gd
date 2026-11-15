extends Node
signal language_changed
var difficulty := 1
var language := DEFAULT_LANGUAGE
const DEFAULT_LANGUAGE := "en"
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
	language = _supported_language(str(config.get_value("game", "language", DEFAULT_LANGUAGE)))
	TranslationServer.set_locale(language)

func set_language(value: String) -> void:
	language = _supported_language(value)
	TranslationServer.set_locale(language)
	_save()
	language_changed.emit()

func set_difficulty(value: int) -> void:
	difficulty = clampi(value, 0, 2)
	_save()

func _supported_language(value: String) -> String:
	return value if value in ["pt_BR", "en"] else DEFAULT_LANGUAGE

func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "language", language)
	config.set_value("game", "difficulty", difficulty)
	config.save("user://game.cfg")

func pressure(progress: float) -> float:
	return LEVELS[difficulty] * (1.0 + clampf(progress, 0, 1) * 0.35)
