extends "res://Items/item.gd"


func release() -> void:
	pin.set_node_b("")
	cooldown = true
	locked = true
	friction = 1
	bounce = 0.0
	mass = 1
	weight = 9.8
	held = false
	apply_central_impulse(Vector2(linear_velocity.x/275,linear_velocity.x/1000))
