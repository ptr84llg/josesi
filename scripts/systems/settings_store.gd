extends RefCounted

const SETTINGS_PATH := "user://josesi_settings.cfg"
const SECTION_ACCESSIBILITY := "accessibility"
const KEY_REDUCE_MOTION := "reduce_motion"

static func load_reduce_motion() -> bool:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		return false
	return bool(config.get_value(SECTION_ACCESSIBILITY, KEY_REDUCE_MOTION, false))

static func save_reduce_motion(enabled: bool) -> Error:
	var config := ConfigFile.new()
	var load_err := config.load(SETTINGS_PATH)
	if load_err != OK and load_err != ERR_FILE_NOT_FOUND:
		return load_err
	config.set_value(SECTION_ACCESSIBILITY, KEY_REDUCE_MOTION, enabled)
	return config.save(SETTINGS_PATH)
