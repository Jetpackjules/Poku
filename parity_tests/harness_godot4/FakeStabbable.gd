extends RigidBody2D

var stab_count := 0

func stabbed(_item) -> void:
	stab_count += 1
