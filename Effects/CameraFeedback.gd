extends Node

enum Impact {
	LIGHT,
	MEDIUM,
	HEAVY
}

const PROFILES := {
	Impact.LIGHT: {"duration": 0.12, "strength": 3.0},
	Impact.MEDIUM: {"duration": 0.18, "strength": 5.0},
	Impact.HEAVY: {"duration": 0.25, "strength": 7.5}
}

var last_request := {}
var _camera: Camera2D
var _base_offset := Vector2.ZERO
var _duration := 0.0
var _remaining := 0.0
var _strength := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func impact(kind := Impact.MEDIUM, source: Node = null) -> bool:
	var profile: Dictionary = PROFILES.get(kind, PROFILES[Impact.MEDIUM])
	return request(float(profile["duration"]), float(profile["strength"]), source)


func request(duration: float, strength: float, source: Node = null) -> bool:
	var camera := _find_active_camera(source)
	return shake_camera(camera, duration, strength)


func shake_camera(camera: Camera2D, duration: float, strength: float) -> bool:
	var accepted := (
		GameSettings.is_camera_feedback_enabled()
		and is_instance_valid(camera)
		and duration > 0.0
		and strength > 0.0
	)
	last_request = {
		"accepted": accepted,
		"camera": camera,
		"duration": maxf(duration, 0.0),
		"strength": maxf(strength, 0.0)
	}
	if not accepted:
		return false

	if camera != _camera:
		_restore_camera()
		_camera = camera
		_base_offset = camera.offset
	_duration = maxf(_duration, duration)
	_remaining = maxf(_remaining, duration)
	_strength = maxf(_strength, strength)
	set_process(true)
	return true


func stop() -> void:
	_restore_camera()
	_duration = 0.0
	_remaining = 0.0
	_strength = 0.0
	set_process(false)


func is_shaking() -> bool:
	return _remaining > 0.0 and is_instance_valid(_camera)


func _process(delta: float) -> void:
	if not is_instance_valid(_camera):
		stop()
		return
	if not GameSettings.is_camera_feedback_enabled():
		stop()
		return

	_remaining = maxf(0.0, _remaining - delta)
	if _remaining <= 0.0:
		stop()
		return
	var decay := clampf(_remaining / maxf(_duration, 0.001), 0.0, 1.0)
	var current_strength := _strength * decay * decay
	_camera.offset = _base_offset + Vector2(
		randf_range(-current_strength, current_strength),
		randf_range(-current_strength, current_strength)
	)


func _find_active_camera(source: Node = null) -> Camera2D:
	var viewport: Viewport = source.get_viewport() if is_instance_valid(source) and source.is_inside_tree() else get_viewport()
	if is_instance_valid(viewport):
		var active := viewport.get_camera_2d()
		if is_instance_valid(active):
			return active
	if is_instance_valid(SceneSwitcher.current_map):
		return _find_camera_recursive(SceneSwitcher.current_map)
	return null


func _find_camera_recursive(node: Node) -> Camera2D:
	if node is Camera2D and node.enabled:
		return node
	for child in node.get_children():
		var found := _find_camera_recursive(child)
		if is_instance_valid(found):
			return found
	return null


func _restore_camera() -> void:
	if is_instance_valid(_camera):
		_camera.offset = _base_offset
	_camera = null
