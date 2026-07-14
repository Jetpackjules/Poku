extends "res://Items/item.gd"

const LEGACY_HELD_INERTIA := 0.258504407

func grab() -> void:
	super.grab()
	inertia = LEGACY_HELD_INERTIA

func release() -> void:
	super.release()
	inertia = 0.0
