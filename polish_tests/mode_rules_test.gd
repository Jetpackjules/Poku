extends Node2D

var failures: Array[String] = []
var observations := {}


func _ready() -> void:
	await _test_volleyball_scoring()
	await _test_basketball_round()
	await _test_wipeout_openings()
	await _test_vertical_reachability()
	await _test_planes_updraft()
	await _test_mode_configuration()
	print("POLISH_JSON:", JSON.stringify({
		"suite": "mode_rules",
		"passed": failures.is_empty(),
		"failures": failures,
		"observations": observations
	}))
	get_tree().quit(0 if failures.is_empty() else 1)


func _test_volleyball_scoring() -> void:
	var map = _add_map("Volleyball")
	var ball: RigidBody2D = map.get_node("Ball")
	ball.freeze = true
	ball.global_position = Vector2(900.0, 185.0)
	ball.reset_physics_interpolation()
	await _wait_ticks(4)
	_expect(map.left_score == 1, "A physical ball landing on P2's floor did not award P1 a volleyball point")
	observations["volleyball_score"] = [map.left_score, map.right_score]
	await _wait_ticks(110)
	map.queue_free()
	await get_tree().physics_frame


func _test_basketball_round() -> void:
	var map = _add_map("Basketball")
	var score = map.get_node("Score")
	score.update_score(0, 1)
	score.update_score(0, 1)
	_expect(score.p1_score == 2, "Two right-hoop baskets did not award P1 two points")
	_expect(map.round_over, "Basketball did not finish at its authored two-point win score")
	map.queue_free()
	await get_tree().physics_frame


func _test_wipeout_openings() -> void:
	var map = _add_map("Wipeout")
	var spawner = map.get_node("Wall_Spawner")
	for _index in 8:
		spawner.spawn_wall()
	for wall in spawner.get_children():
		if not wall.has_method("adjust"):
			continue
		var upper_edge: float = wall.position.y - wall.gap * 0.5
		var lower_edge: float = wall.position.y + wall.gap * 0.5
		_expect(upper_edge >= spawner.playable_top - 0.1, "A Wipeout gap spawned above the playable corridor")
		_expect(lower_edge <= spawner.playable_bottom + 0.1, "A Wipeout gap spawned under the floor")
	observations["wipeout_gap_after_8"] = spawner.current_gap_size()
	map.queue_free()
	await get_tree().physics_frame


func _test_vertical_reachability() -> void:
	var map = _add_map("Vertical_Parkour")
	await _wait_ticks(12)
	var platforms: Array = map.get_node("Platform_Generator").get_children()
	var previous := Vector2.ZERO
	var maximum_horizontal_jump := 0.0
	for platform in platforms:
		maximum_horizontal_jump = maxf(maximum_horizontal_jump, absf(platform.position.x - previous.x))
		previous = platform.position
	_expect(maximum_horizontal_jump <= 855.0, "Vertical Parkour generated an unreachable horizontal jump: %.1f" % maximum_horizontal_jump)
	observations["maximum_platform_jump"] = maximum_horizontal_jump
	map.queue_free()
	await get_tree().physics_frame


func _test_mode_configuration() -> void:
	var targets = _add_map("Targets")
	_expect("Ball" not in targets.get_node("Tool_Spawner").tool_names, "Targets can still strand a player with a non-scoring ball")
	targets.queue_free()
	await get_tree().physics_frame
	var planes = _add_map("Planes")
	_expect(planes.get_node("Spawns/P1_Spawn").position.x < -1000.0, "P1 is not placed on the left plane")
	_expect(planes.get_node("Spawns/P2_Spawn").position.x > 1000.0, "P2 is not placed on the right plane")
	planes.queue_free()
	await get_tree().physics_frame
	var ostritch = _add_map("Ostritch")
	_expect(ostritch.has_node("FinishMarker"), "The Ostritch course has no finish marker")
	ostritch.queue_free()
	await get_tree().physics_frame


func _test_planes_updraft() -> void:
	var map = _add_map("Planes")
	var plane: RigidBody2D = map.get_node("Turn_Brace2")
	_test_planes_steering_contract(plane)
	_test_planes_polish_and_jelly(map, plane)
	plane.global_position = Vector2(0.0, -200.0)
	plane.linear_velocity = Vector2.ZERO
	plane.reset_physics_interpolation()
	await _wait_ticks(8)
	_expect(is_equal_approx(plane.gravity_force, plane.updraft_force), "A plane physically inside the center updraft did not receive lift")
	var start_y: float = plane.global_position.y
	await _wait_ticks(35)
	_expect(plane.global_position.y < start_y - 20.0, "The updraft force did not produce useful upward plane motion")
	observations["plane_updraft_rise"] = start_y - plane.global_position.y
	map.queue_free()
	await get_tree().physics_frame


func _test_planes_steering_contract(plane: RigidBody2D) -> void:
	var right_force: float = plane.steering_force_for_offset(100.0)
	var left_force: float = plane.steering_force_for_offset(-100.0)
	_expect(right_force > 0.0, "Standing right of a plane's center does not drive it right")
	_expect(left_force < 0.0, "Standing left of a plane's center does not drive it left")
	_expect(is_equal_approx(right_force, -left_force), "Plane steering is not symmetric across its center")
	_expect(is_zero_approx(plane.steering_force_for_offset(0.0)), "Standing at the plane center still creates steering force")
	var right_tilt: float = plane.tilt_for_offset(100.0)
	var left_tilt: float = plane.tilt_for_offset(-100.0)
	_expect(right_tilt > 0.0 and is_equal_approx(right_tilt, -left_tilt), "Physical plane tilt is not symmetric with rider weight")
	_expect(absf(plane.tilt_for_offset(1000.0)) <= plane.maximum_tilt_degrees, "Plane tilt can exceed its physical safety limit")
	observations["plane_steering_acceleration_at_100px"] = right_force / plane.mass
	observations["plane_tilt_target_at_100px"] = right_tilt


func _test_planes_polish_and_jelly(map: Node, plane: RigidBody2D) -> void:
	GameSettings.set_preference(&"poku_polish", true, false)
	_expect(is_instance_valid(map.atmosphere) and map.atmosphere.visible, "Planes polish has no sky/updraft atmosphere")
	_expect(map.atmosphere.CLOUDS.size() >= 4, "The polished Planes sky has too little cloud depth")
	_expect(map.updraft_particles.amount > map._original_particle_amount, "Planes polish did not strengthen the updraft particles")
	_expect(map.left_plane_visual.color != map.right_plane_visual.color, "P1 and P2 planes are still visually identical")
	var collision: CollisionPolygon2D = plane.get_node("CollisionPolygon2D")
	var collision_polygon := collision.polygon.duplicate()
	var visual: Polygon2D = plane.get_node("Plane/Polygon2D")
	var visual_base: PackedVector2Array = plane._visual_base_polygon.duplicate()
	plane.linear_velocity = Vector2(500.0, -420.0)
	plane.desired_tilt_degrees = plane.maximum_tilt_degrees
	for _step in 30:
		plane._update_jelly_deformation(1.0 / 120.0)
	var tip_travel: float = maxf(absf(plane._left_tip_flex), absf(plane._right_tip_flex))
	_expect(visual.polygon != visual_base, "Fast plane movement did not create springy wing deformation")
	_expect(tip_travel > 8.0 and tip_travel < 32.0, "Jelly wing travel is imperceptible or unbounded: %.2f" % tip_travel)
	_expect(collision.polygon == collision_polygon, "Jelly wing visuals changed the stable physical collision polygon")
	_expect(map.atmosphere.wind_intensity_for(plane) > 0.8, "A rapidly rising plane did not produce strong wind streaks")
	observations["plane_jelly_tip_travel"] = tip_travel

	GameSettings.set_preference(&"poku_polish", false, false)
	_expect(not map.atmosphere.visible, "Disabling Poku polish left the Planes atmosphere visible")
	_expect(visual.polygon != visual_base, "Core jelly-plane response incorrectly depends on the presentation toggle")
	_expect(map.left_plane_visual.color == map._original_left_color, "Disabling Poku polish did not restore the original plane color")
	_expect(map.updraft_particles.amount == map._original_particle_amount, "Disabling Poku polish did not restore the original updraft")
	GameSettings.set_preference(&"poku_polish", true, false)


func _add_map(map_name: String) -> Node:
	var map = (load("res://Maps/%s/%s_Map.tscn" % [map_name, map_name]) as PackedScene).instantiate()
	$MapSlot.add_child(map)
	SceneSwitcher.current_map = map
	return map


func _wait_ticks(count: int) -> void:
	for _tick in count:
		await get_tree().physics_frame


func _expect(condition: bool, message: String) -> void:
	if not condition and message not in failures:
		failures.append(message)
