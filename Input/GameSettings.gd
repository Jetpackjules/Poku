extends Node

signal experiment_changed(experiment: StringName, enabled: bool)

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


func _ready() -> void:
	reset_experiments(false)


func definitions() -> Array:
	return EXPERIMENTS.duplicate(true)


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


func _is_known(experiment: StringName) -> bool:
	for definition in EXPERIMENTS:
		if definition["id"] == experiment:
			return true
	return false
