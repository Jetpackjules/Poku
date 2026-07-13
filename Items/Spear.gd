extends "res://Items/item.gd"


func release() -> void:
	pin.set_node_b("")
	cooldown = true
	locked = true
	set_item_physics(1.0, 0.0)
	mass = 1
	held = false
	apply_central_impulse(Vector2(linear_velocity.x/275,linear_velocity.x/1000))
