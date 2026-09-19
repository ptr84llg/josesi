extends RefCounted

const SAVE_PATH := "user://josesi_progress.json"
const STAGES := ["SEE", "EXPLORE", "SOLVE", "INTEGRATE"]
const STAGE_VALUES := ["LOCKED", "AVAILABLE", "CURRENT", "COMPLETE"]

static func first_launch_model() -> Dictionary:
	return {
		"has_valid_save": false,
		"journey_complete": false,
		"save_load_error": false,
		"current_stage": null,
		"current_area": null,
		"destination_label": null,
		"resume_scene": null,
		"resume_spawn": null,
		"portfolio_count": 0,
		"portfolio_unread": false,
		"final_showcase_unlocked": false,
		"stage_states": {
			"SEE": "AVAILABLE",
			"EXPLORE": "LOCKED",
			"SOLVE": "LOCKED",
			"INTEGRATE": "LOCKED",
		},
	}

static func load_view_model() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return first_launch_model()

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return _error_model()

	var json := JSON.new()
	var parse_err := json.parse(file.get_as_text())
	if parse_err != OK or not (json.data is Dictionary):
		return _error_model()

	var data: Dictionary = json.data
	if not _is_valid_model(data):
		return _error_model()
	return _normalize_model(data)

static func write_model(model: Dictionary) -> Error:
	if not _is_valid_model(model):
		return ERR_INVALID_DATA
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(_normalize_model(model), "\t"))
	return OK

static func create_new_journey(resume_scene: String, resume_spawn: String, destination_label: String) -> Dictionary:
	if resume_scene.is_empty() or not ResourceLoader.exists(resume_scene):
		return {"ok": false, "error": "JOURNEY_START_TARGET_UNAVAILABLE"}

	var model := first_launch_model()
	model["has_valid_save"] = true
	model["current_stage"] = "SEE"
	model["current_area"] = "Visual Orientation"
	model["destination_label"] = destination_label
	model["resume_scene"] = resume_scene
	model["resume_spawn"] = resume_spawn
	model["stage_states"] = {
		"SEE": "CURRENT",
		"EXPLORE": "LOCKED",
		"SOLVE": "LOCKED",
		"INTEGRATE": "LOCKED",
	}
	var err := write_model(model)
	return {"ok": err == OK, "error": "" if err == OK else error_string(err), "model": model}

static func mark_portfolio_read() -> Error:
	var model := load_view_model()
	if bool(model.get("save_load_error", false)) or not bool(model.get("has_valid_save", false)):
		return ERR_DOES_NOT_EXIST
	model["portfolio_unread"] = false
	return write_model(model)

static func _error_model() -> Dictionary:
	var model := first_launch_model()
	model["save_load_error"] = true
	return model

static func _normalize_model(source: Dictionary) -> Dictionary:
	var result := first_launch_model()
	for key in result.keys():
		if source.has(key):
			result[key] = source[key]
	return result

static func _is_valid_model(model: Dictionary) -> bool:
	for key in ["has_valid_save", "journey_complete", "portfolio_count", "stage_states"]:
		if not model.has(key):
			return false
	if not (model["has_valid_save"] is bool) or not (model["journey_complete"] is bool):
		return false
	if not (model["portfolio_count"] is int):
		return false
	var portfolio_count := int(model["portfolio_count"])
	if portfolio_count < 0 or portfolio_count > 4:
		return false
	if not (model["stage_states"] is Dictionary):
		return false
	var states: Dictionary = model["stage_states"]
	for stage in STAGES:
		if not states.has(stage) or str(states[stage]) not in STAGE_VALUES:
			return false
	var current_stage = model.get("current_stage", null)
	if current_stage != null and str(current_stage) not in STAGES:
		return false
	return true
