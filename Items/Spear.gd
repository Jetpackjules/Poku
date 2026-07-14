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
