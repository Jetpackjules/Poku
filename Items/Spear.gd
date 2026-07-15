extends "res://Items/item.gd"

const LEGACY_HELD_INERTIA := 3.568917
var rest_frames := 0

func grab() -> void:
	rest_frames = 0
	sleeping = false
	super.grab()
	inertia = LEGACY_HELD_INERTIA

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if GameSettings.is_enabled(&"spear_aerodynamics") and !held and !snap and !impaled and linear_velocity.length() > 180.0:
		var angle_error := wrapf(linear_velocity.angle() - global_rotation, -PI, PI)
		var desired_angular_velocity := clampf(angle_error * 7.0, -16.0, 16.0)
		angular_velocity = lerpf(angular_velocity, desired_angular_velocity, clampf(delta * 9.0, 0.0, 1.0))
	if cooldown and !impaled and linear_velocity.length() < 1.0 and abs(angular_velocity) < 0.1:
		rest_frames += 1
		if rest_frames >= 5:
			sleeping = true
	else:
		rest_frames = 0

func release() -> void:
	rest_frames = 0
	sleeping = false
	pin.set_node_b("")
	cooldown = true
	locked = true
	set_item_physics(1.0, 0.0)
	mass = 1
	inertia = 0.0
	held = false
	apply_central_impulse(Vector2(linear_velocity.x/275,linear_velocity.x/1000))
	_apply_experimental_throw_velocity()
