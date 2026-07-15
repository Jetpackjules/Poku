extends "res://Items/item.gd"

const LEGACY_HELD_INERTIA := 0.258504407

func grab() -> void:
	super.grab()
	inertia = LEGACY_HELD_INERTIA

func release() -> void:
	super.release()
	inertia = 0.0
	if GameSettings.is_enabled(&"shuriken_spin"):
		var spin_direction := signf(linear_velocity.x)
		if is_zero_approx(spin_direction):
			spin_direction = 1.0
		angular_velocity = 18.0 * spin_direction
