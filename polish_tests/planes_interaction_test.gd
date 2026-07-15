extends Node2D

var failures: Array[String] = []
var observations := {}


func _ready() -> void:
	GameSettings.reset_experiments(false)
	GameSettings.set_preference(&"poku_polish", false, false)
	var map = (load("res://Maps/Planes/Planes_Map.tscn") as PackedScene).instantiate()
	map.countdown_enabled = false
	SceneSwitcher.current_map = map
	$MapSlot.add_child(map)
	var player = (load("res://Player/Player.tscn") as PackedScene).instantiate()
	$Players.add_child(player)
	player.jump = &"wasd_up"
	player.crouch = &"wasd_down"
	player.move_right = &"wasd_right"
	player.move_left = &"wasd_left"
	player.spin = &"wasd_spin"
	player.global_position = map.get_node("Spawns/P1_Spawn").global_position
	player.controllable = true
	var plane: RigidBody2D = map.get_node("Turn_Brace2")
	var plane_body: Node2D = plane.get_node("Plane")
	var stand_zone: Area2D = plane_body.get_node("Stand_Zone")
	var player_raycast: RayCast2D = player.get_node("RayCast2D")
	observations["softbody2d_available"] = ClassDB.class_exists(&"SoftBody2D")
	await _wait_ticks(8)

	observations["spawn"] = {
		"player": player.global_position,
		"brace": plane.global_position,
		"visible_plane": plane_body.global_position,
		"stand_zone": stand_zone.global_position,
		"stand_bodies": plane.stand_zone_bodies.map(func(body): return body.name),
		"grounded": player_raycast.is_colliding()
	}
	var start_x := plane.global_position.x
	Input.action_press(&"wasd_right")
	await _wait_ticks(36)
	Input.action_release(&"wasd_right")
	observations["after_right"] = {
		"player": player.global_position,
		"brace": plane.global_position,
		"visible_plane": plane_body.global_position,
		"brace_velocity": plane.linear_velocity,
		"physical_rotation_degrees": rad_to_deg(plane.rotation),
		"visual_local_rotation_degrees": rad_to_deg(plane_body.rotation),
		"left_tip_flex": plane._left_tip_flex,
		"right_tip_flex": plane._right_tip_flex,
		"stand_bodies": plane.stand_zone_bodies.map(func(body): return body.name),
		"grounded": player_raycast.is_colliding(),
		"ray_collider": player_raycast.get_collider().name if player_raycast.is_colliding() else "none"
	}
	_expect(plane.global_position.x > start_x + 1.0, "Walking right while aboard did not move the plane right")
	_expect(plane_body.global_position.distance_to(plane.global_position) < 150.0, "The visible plane separated dangerously far from its force brace")
	_expect(plane.rotation > deg_to_rad(1.5), "Weight on the right wing did not physically rotate the plane")
	_expect(absf(plane_body.rotation) < 0.001, "The plane is still faking tilt on a visual-only child")
	_expect(absf(plane_body.global_rotation - plane.global_rotation) < 0.001, "The visible plane and physical collision do not share rotation")
	_expect(player_raycast.is_colliding() and player_raycast.get_collider() == plane, "The rider lost the physically tilted plane surface")
	_expect(absf(plane._left_tip_flex) + absf(plane._right_tip_flex) > 1.0, "The plane wings did not produce a springy deformation response")

	Input.action_press(&"wasd_down")
	await _wait_ticks(24)
	Input.action_release(&"wasd_down")
	var crouch_rider_offset_y: float = player.global_position.y - plane.global_position.y
	observations["after_crouch"] = {
		"player": player.global_position,
		"plane": plane.global_position,
		"player_velocity": player.linear_velocity,
		"plane_velocity": plane.linear_velocity,
		"rider_offset_y": crouch_rider_offset_y,
		"grounded": player_raycast.is_colliding()
	}
	_expect(absf(player.linear_velocity.y) < 500.0, "Holding crouch accumulated plane velocity into a runaway vertical launch")
	_expect(crouch_rider_offset_y < 0.0 and crouch_rider_offset_y > -220.0, "Crouching sent the rider through or far away from the plane")
	await _wait_ticks(10)

	var lift_start_y := plane.global_position.y
	plane._on_Updraft_body_entered(plane)
	await _wait_ticks(55)
	var rider_offset_y: float = player.global_position.y - plane_body.global_position.y
	observations["after_lift"] = {
		"player": player.global_position,
		"brace": plane.global_position,
		"visible_plane": plane_body.global_position,
		"rider_offset_y": rider_offset_y,
		"grounded": player_raycast.is_colliding()
	}
	_expect(plane.global_position.y < lift_start_y - 20.0, "The updraft did not lift an occupied plane")
	_expect(rider_offset_y < 0.0 and rider_offset_y > -220.0, "The rider separated vertically from the rising plane")

	var floor_test_plane: RigidBody2D = map.get_node("Turn_Brace")
	floor_test_plane.global_position = Vector2(1167.0, 75.0)
	floor_test_plane.rotation = 0.0
	floor_test_plane.linear_velocity = Vector2(0.0, 420.0)
	floor_test_plane.angular_velocity = 0.0
	await _wait_ticks(90)
	observations["floor_collision"] = {
		"position": floor_test_plane.global_position,
		"velocity": floor_test_plane.linear_velocity,
		"floor_layer_enabled": bool(floor_test_plane.collision_mask & 1),
		"continuous_cd": floor_test_plane.continuous_cd
	}
	_expect(bool(floor_test_plane.collision_mask & 1), "Planes still exclude the map floor from their collision mask")
	_expect(floor_test_plane.global_position.y < 115.0, "A descending plane passed through the map floor")
	Input.action_release(&"wasd_right")
	print("POLISH_JSON:", JSON.stringify({
		"suite": "planes_interaction",
		"passed": failures.is_empty(),
		"failures": failures,
		"observations": observations
	}))
	get_tree().quit(0 if failures.is_empty() else 1)


func _wait_ticks(count: int) -> void:
	for _tick in count:
		await get_tree().physics_frame


func _expect(condition: bool, message: String) -> void:
	if not condition and message not in failures:
		failures.append(message)
