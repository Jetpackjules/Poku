extends Node

signal experiment_changed(experiment: StringName, enabled: bool)
signal preference_changed(preference: StringName, value: Variant)

const SETTINGS_PATH := "user://poku_settings.cfg"
const TEST_SETTINGS_PATH := "user://poku_settings_test.cfg"
const SETTINGS_SECTION := "preferences"
const WINDOWED_SIZE := Vector2i(1024, 576)
const PREFERENCES := [
	{
		"id": &"poku_polish",
		"label": "Poku visual polish",
		"detail": "Dust, furnace atmosphere, and the cohesive Poku presentation layer.",
		"default": true
	},
	{
		"id": &"controller_rumble",
		"label": "Controller rumble",
		"detail": "Short, restrained feedback for meaningful physical impacts.",
		"default": true
	},
	{
		"id": &"camera_feedback",
		"label": "Camera impact feedback",
		"detail": "Mild centralized camera movement for scores, target hits, and round-winning impacts.",
		"default": true
	},
	{
		"id": &"fullscreen",
		"label": "Display mode",
		"detail": "Switch between the original 1024 × 576 window and fullscreen.",
		"default": false
	},
	{
		"id": &"fps_cap",
		"label": "FPS cap",
		"detail": "Limit rendered frames without changing the 120 Hz physics clock.",
		"default": 0
	}
]

const EXPERIMENTS := [
	{
		"id": &"throw_momentum",
		"label": "Throw momentum sampling",
		"detail": "Blend measured hand motion into released items."
	},
	{
		"id": &"spear_aerodynamics",
		"label": "Spear flight alignment",
		"detail": "Gently turn a flying spear point-first."
	},
	{
		"id": &"shuriken_spin",
		"label": "Shuriken release spin",
		"detail": "Guarantee a readable spin when a shuriken is thrown."
	},
	{
		"id": &"weapon_tip_casting",
		"label": "Weapon-tip ShapeCast",
		"detail": "Sweep sharp tips between physics frames to catch fast hits."
	},
	{
		"id": &"jump_grounding",
		"label": "ShapeCast jump grace",
		"detail": "Use a wider foot probe, coyote time, and a short jump buffer."
	},
	{
		"id": &"ball_impacts",
		"label": "Ball impact bursts",
		"detail": "Add purely visual squash and impact rings to hard bounces."
	},
	{
		"id": &"ostritch_active_ragdoll",
		"label": "Ostritch active motor",
		"detail": "Try a bounded active-ragdoll controller in the Ostritch mode."
	}
]

var _enabled := {}
var _preferences := {}


func _ready() -> void:
	reset_experiments(false)
	_load_preferences()
	_apply_all_preferences()


func definitions() -> Array:
	return EXPERIMENTS.duplicate(true)


func preference_definitions() -> Array:
	return PREFERENCES.duplicate(true)


func is_enabled(experiment: StringName) -> bool:
	return bool(_enabled.get(experiment, false))


func set_enabled(experiment: StringName, enabled: bool) -> void:
	if not _is_known(experiment):
		push_warning("Unknown Poku experiment: %s" % experiment)
		return
	if is_enabled(experiment) == enabled:
		return
	_enabled[experiment] = enabled
	experiment_changed.emit(experiment, enabled)


func reset_experiments(emit_changes := true) -> void:
	for definition in EXPERIMENTS:
		var experiment: StringName = definition["id"]
		var changed := is_enabled(experiment)
		_enabled[experiment] = false
		if emit_changes and changed:
			experiment_changed.emit(experiment, false)


func get_preference(preference: StringName) -> Variant:
	if _preferences.has(preference):
		return _preferences[preference]
	var definition := _preference_definition(preference)
	return definition.get("default") if not definition.is_empty() else null


func set_preference(preference: StringName, value: Variant, persist := true) -> void:
	var definition := _preference_definition(preference)
	if definition.is_empty():
		push_warning("Unknown Poku preference: %s" % preference)
		return
	var normalized: Variant = _normalize_preference(preference, value)
	if get_preference(preference) == normalized:
		return
	_preferences[preference] = normalized
	_apply_preference(preference, normalized)
	if persist:
		_save_preferences()
	preference_changed.emit(preference, normalized)


func reset_preferences(persist := true, emit_changes := true) -> void:
	for definition in PREFERENCES:
		var preference: StringName = definition["id"]
		var old_value = get_preference(preference)
		var default_value = definition["default"]
		_preferences[preference] = default_value
		_apply_preference(preference, default_value)
		if emit_changes and old_value != default_value:
			preference_changed.emit(preference, default_value)
	if persist:
		_save_preferences()


func is_poku_polish_enabled() -> bool:
	return bool(get_preference(&"poku_polish"))


func is_rumble_enabled() -> bool:
	return bool(get_preference(&"controller_rumble"))


func is_camera_feedback_enabled() -> bool:
	return bool(get_preference(&"camera_feedback"))


func all_experiments_state() -> StringName:
	var enabled_count := 0
	for definition in EXPERIMENTS:
		if is_enabled(definition["id"]):
			enabled_count += 1
	if enabled_count == 0:
		return &"off"
	if enabled_count == EXPERIMENTS.size():
		return &"on"
	return &"mixed"


func set_all_experiments_enabled(enabled: bool) -> void:
	for definition in EXPERIMENTS:
		set_enabled(definition["id"], enabled)


func fps_cap_label() -> String:
	var cap := int(get_preference(&"fps_cap"))
	return "UNLIMITED" if cap <= 0 else "%d FPS" % cap


func settings_path() -> String:
	return TEST_SETTINGS_PATH if OS.get_environment("POKU_POLISH_TEST") == "1" else SETTINGS_PATH


func _load_preferences() -> void:
	for definition in PREFERENCES:
		_preferences[definition["id"]] = definition["default"]
	var config := ConfigFile.new()
	if config.load(settings_path()) != OK:
		return
	for definition in PREFERENCES:
		var preference: StringName = definition["id"]
		var stored_value = config.get_value(SETTINGS_SECTION, String(preference), definition["default"])
		_preferences[preference] = _normalize_preference(preference, stored_value)


func _save_preferences() -> void:
	var config := ConfigFile.new()
	for definition in PREFERENCES:
		var preference: StringName = definition["id"]
		config.set_value(SETTINGS_SECTION, String(preference), get_preference(preference))
	var error := config.save(settings_path())
	if error != OK:
		push_warning("Could not save Poku settings: %s" % error_string(error))


func _apply_all_preferences() -> void:
	for definition in PREFERENCES:
		var preference: StringName = definition["id"]
		_apply_preference(preference, get_preference(preference))


func _apply_preference(preference: StringName, value: Variant) -> void:
	match preference:
		&"fullscreen":
			if DisplayServer.get_name() == "headless":
				return
			if bool(value):
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				DisplayServer.window_set_size(WINDOWED_SIZE)
		&"fps_cap":
			Engine.max_fps = int(value)


func _normalize_preference(preference: StringName, value: Variant) -> Variant:
	match preference:
		&"poku_polish", &"controller_rumble", &"camera_feedback", &"fullscreen":
			return bool(value)
		&"fps_cap":
			var cap := int(value)
			return cap if cap in [0, 60, 120, 144] else 0
	return value


func _preference_definition(preference: StringName) -> Dictionary:
	for definition in PREFERENCES:
		if definition["id"] == preference:
			return definition
	return {}


func _is_known(experiment: StringName) -> bool:
	for definition in EXPERIMENTS:
		if definition["id"] == experiment:
			return true
	return false
