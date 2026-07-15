extends Node2D

var failures: Array[String] = []
var observations := {}


func _ready() -> void:
	var map := (load("res://Maps/Spaceship/Spaceship_Map.tscn") as PackedScene).instantiate()
	add_child(map)
	var ship: RigidBody2D = map.get_node("Spaceship_Left")
	var furnace: Area2D = ship.get_node("Furnace")
	var coal := (load("res://Items/Coal.tscn") as PackedScene).instantiate()
	map.add_child(coal)
	coal.gravity_scale = 0.0
	coal.linear_velocity = Vector2.ZERO
	coal.angular_velocity = 0.0
	coal.global_position = furnace.global_position
	coal.reset_physics_interpolation()

	for _tick in 20:
		await get_tree().physics_frame

	var detected: bool = ship.coal_objects.has(coal)
	observations["furnace_layer"] = furnace.collision_layer
	observations["furnace_mask"] = furnace.collision_mask
	observations["coal_layer"] = coal.collision_layer
	observations["coal_detected"] = detected
	_expect(detected, "A physical coal body overlapping the furnace was not detected")

	if detected:
		var before_height: float = ship.float_height
		for _tick in 20:
			await get_tree().physics_frame
		observations["float_height_before"] = before_height
		observations["float_height_after"] = ship.float_height
		_expect(ship.float_height > 450.0, "Burning coal did not raise the ship's target height")
		_expect(coal.burn_time < coal.burn_time_for_scale, "Coal in the furnace did not burn down")

	print("POLISH_JSON:", JSON.stringify({
		"suite": "spaceship_coal",
		"passed": failures.is_empty(),
		"failures": failures,
		"observations": observations
	}))
	get_tree().quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition and message not in failures:
		failures.append(message)
