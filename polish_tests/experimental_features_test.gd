extends Node2D

var failures: Array[String] = []
var observations := {}

@onready var player = $Players/Body


func _ready() -> void:
	GameSettings.reset_experiments(false)
	await get_tree().process_frame
	await _test_throw_sampling()
	await _test_weapon_identity_experiments()
	await _test_tip_cast()
	await _test_jump_grace()
	await _test_ball_impact()
	await _test_ostritch_motor()
	GameSettings.reset_experiments(false)
	print("POLISH_JSON:", JSON.stringify({
		"suite": "experimental_features",
		"passed": failures.is_empty(),
		"failures": failures,
		"observations": observations
	}))
	get_tree().quit(0 if failures.is_empty() else 1)


func _test_throw_sampling() -> void:
	GameSettings.set_enabled(&"throw_momentum", true)
	var ball = (load("res://Items/Ball.tscn") as PackedScene).instantiate()
	$Tools.add_child(ball)
	await get_tree().physics_frame
	ball.target_node = player.grabber
	player.grabbed_item = ball
	player.holding_something = true
	ball.held = true
	ball._holder_sample_ready = true
	ball._sampled_holder_velocity = Vector2(900.0, -200.0)
	ball.release()
	observations["sampled_throw_velocity"] = [ball.linear_velocity.x, ball.linear_velocity.y]
	_expect(ball.linear_velocity.distance_to(Vector2(855.0, -190.0)) < 1.0, "Throw sampling toggle did not control release velocity")
	ball.queue_free()
	GameSettings.set_enabled(&"throw_momentum", false)
	await get_tree().physics_frame


func _test_weapon_identity_experiments() -> void:
	GameSettings.set_enabled(&"spear_aerodynamics", true)
	var spear = (load("res://Items/Spear.tscn") as PackedScene).instantiate()
	$Tools.add_child(spear)
	spear.gravity_scale = 0.0
	spear.collision_mask = 0
	spear.global_position = Vector2(-500.0, -300.0)
	spear.global_rotation = PI * 0.5
	spear.linear_velocity = Vector2(700.0, 0.0)
	var initial_error := absf(wrapf(spear.linear_velocity.angle() - spear.global_rotation, -PI, PI))
	for _tick in 45:
		await get_tree().physics_frame
	var final_error := absf(wrapf(spear.linear_velocity.angle() - spear.global_rotation, -PI, PI))
	observations["spear_error_degrees"] = rad_to_deg(final_error)
	_expect(final_error < initial_error * 0.72, "Spear aerodynamics did not visibly align its flight")
	spear.queue_free()
	GameSettings.set_enabled(&"spear_aerodynamics", false)

	GameSettings.set_enabled(&"shuriken_spin", true)
	var shuriken = (load("res://Items/Shuriken.tscn") as PackedScene).instantiate()
	$Tools.add_child(shuriken)
	await get_tree().physics_frame
	shuriken.target_node = player.grabber
	player.grabbed_item = shuriken
	player.holding_something = true
	shuriken.linear_velocity = Vector2(500.0, 0.0)
	shuriken.release()
	observations["shuriken_spin"] = shuriken.angular_velocity
	_expect(absf(shuriken.angular_velocity) >= 17.9, "Shuriken spin toggle did not add release spin")
	shuriken.queue_free()
	GameSettings.set_enabled(&"shuriken_spin", false)
	await get_tree().physics_frame


func _test_tip_cast() -> void:
	GameSettings.set_enabled(&"weapon_tip_casting", true)
	var dummy := StaticBody2D.new()
	dummy.name = "CastTarget"
	dummy.add_to_group("stabb-able")
	dummy.collision_layer = 2
	dummy.collision_mask = 0
	dummy.position = Vector2(220.0, -120.0)
	var dummy_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(50.0, 150.0)
	dummy_shape.shape = rectangle
	dummy.add_child(dummy_shape)
	add_child(dummy)

	var spear = (load("res://Items/Spear.tscn") as PackedScene).instantiate()
	$Tools.add_child(spear)
	await get_tree().physics_frame
	for child in spear.get_children():
		if child is CollisionShape2D:
			child.disabled = true
	spear.target_node = player.grabber
	spear.global_position = Vector2(60.0, -120.0)
	spear.gravity_scale = 0.0
	spear.collision_mask = 2
	spear.available = false
	spear.snap = false
	spear.held = false
	spear.linear_velocity = Vector2(3200.0, 0.0)
	spear._update_experimental_tip_cast(1.0 / 60.0)
	observations["tip_cast"] = {
		"position": [spear._experimental_tip_cast.global_position.x, spear._experimental_tip_cast.global_position.y],
		"target": [spear._experimental_tip_cast.target_position.x, spear._experimental_tip_cast.target_position.y],
		"collisions": spear._experimental_tip_cast.get_collision_count(),
		"mask": spear._experimental_tip_cast.collision_mask
	}
	_expect(spear.has_node("ExperimentalTipCast"), "Sharp weapon did not build its optional tip ShapeCast")
	_expect(spear.impaled, "Weapon-tip ShapeCast did not catch a swept high-speed target")
	spear.queue_free()
	dummy.queue_free()
	GameSettings.set_enabled(&"weapon_tip_casting", false)
	await get_tree().physics_frame


func _test_jump_grace() -> void:
	GameSettings.set_enabled(&"jump_grounding", true)
	_expect(player.has_node("ExperimentalGroundCast"), "Player did not build the optional foot ShapeCast")
	player._experimental_coyote_remaining = 0.05
	var event := InputEventAction.new()
	event.action = &"arrow_up"
	event.pressed = false
	player._input(event)
	_expect(is_equal_approx(player.auto_balance_timeout, 0.5), "Coyote-time jump did not fire after leaving ground")
	_expect(is_zero_approx(player._experimental_jump_buffer_remaining), "Coyote-time jump left a duplicate buffered jump")
	GameSettings.set_enabled(&"jump_grounding", false)


func _test_ball_impact() -> void:
	GameSettings.set_enabled(&"ball_impacts", true)
	var ball = (load("res://Items/Ball.tscn") as PackedScene).instantiate()
	$Tools.add_child(ball)
	await get_tree().physics_frame
	ball.linear_velocity = Vector2(0.0, 620.0)
	ball._on_ball_body_entered($Floor)
	var found_burst := false
	for child in get_tree().current_scene.get_children():
		if child.get_script() and child.get_script().resource_path == "res://Effects/ImpactBurst.gd":
			found_burst = true
			break
	_expect(found_burst, "Ball impact toggle did not create its visual burst")
	ball.queue_free()
	GameSettings.set_enabled(&"ball_impacts", false)
	await get_tree().physics_frame


func _test_ostritch_motor() -> void:
	GameSettings.set_enabled(&"ostritch_active_ragdoll", true)
	var map = (load("res://Maps/Ostritch/Ostritch_Map.tscn") as PackedScene).instantiate()
	$MapSlot.add_child(map)
	await get_tree().process_frame
	_expect(map.has_node("Ostritch/ExperimentalActiveController"), "Ostritch active-motor toggle did not install its controller")
	_expect(not map.get_node("Ostritch/Spine1").is_physics_processing(), "Ostritch legacy motor still fights the active motor")
	GameSettings.set_enabled(&"ostritch_active_ragdoll", false)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(map.get_node("Ostritch/Spine1").is_physics_processing(), "Disabling the Ostritch experiment did not restore Classic")
	map.queue_free()
	await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition and message not in failures:
		failures.append(message)
