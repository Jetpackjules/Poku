extends Node2D

var failures: Array[String] = []
var observations := {}

@onready var player = $Players/Body


func _ready() -> void:
	GameSettings.reset_experiments(false)
	player.jump = "arrow_up"
	player.crouch = "arrow_down"
	player.move_right = "arrow_right"
	player.move_left = "arrow_left"
	player.spin = "arrow_spin"
	await get_tree().process_frame
	_test_authored_physics_contract()
	_test_leg_motion_contract()
	await _test_free_arm_spin_contract()
	await _test_snap_and_release_contract()
	_release_actions()
	print("POLISH_JSON:", JSON.stringify({
		"suite": "classic_physics_contract",
		"passed": failures.is_empty(),
		"failures": failures,
		"observations": observations
	}))
	get_tree().quit(0 if failures.is_empty() else 1)


func _test_authored_physics_contract() -> void:
	_expect(player.lock_rotation, "The parity player body no longer has rotation locking authored in Player.tscn")
	var material: PhysicsMaterial = player.Leg_L_down.physics_material_override
	_expect(material != null, "The lower legs lost their authored parity physics material")
	if material:
		_expect(material.rough, "The lower-leg physics material lost rough mode")
		_expect(is_equal_approx(material.bounce, 10.0), "The lower-leg physics material bounce changed from the parity value")
		_expect(material.absorbent, "The lower-leg physics material lost absorbent mode")

	var leg_source := FileAccess.get_file_as_string("res://Player/Leg.gd")
	var spine_source := FileAccess.get_file_as_string("res://Player/Spine.gd")
	var body_source := FileAccess.get_file_as_string("res://Player/Body.gd")
	var item_source := FileAccess.get_file_as_string("res://Items/item.gd")
	_expect("ActiveRagdollBody2D" not in leg_source, "Legs were put back on the rejected active-ragdoll motor")
	_expect("ActiveRagdollBody2D" not in spine_source, "The arm was put back on the rejected active-ragdoll motor")
	_expect("_update_spin_arm_pose" not in body_source, "Spin is once again forcing an authored arm pose")
	_expect(
		"GameSettings.is_enabled(&\"throw_momentum\")" in item_source,
		"Experimental throw sampling is not protected by its default-off toggle"
	)
	_expect(not GameSettings.is_enabled(&"throw_momentum"), "Experimental throw sampling was enabled by default")
	_expect("force += (0.1)" in item_source, "The accelerating classic pickup snap was removed")


func _test_leg_motion_contract() -> void:
	_expect(player.upper_leg_keyframes == [-1.0, 0, 2.4, 0], "Upper-leg keyframes no longer match the parity gait")
	_expect(player.lower_leg_keyframes == [2.0, 1.0, 2.0, -1], "Lower-leg keyframes no longer match the parity gait")
	player.velocity.x = player.speed
	player._physics_process(1.0 / 60.0)
	var target_span: float = absf(player.Leg_R_up.new_desired_angle - player.Leg_L_up.new_desired_angle)
	observations["leg_target_span_radians"] = target_span
	_expect(player.running, "Horizontal intent did not activate the leg gait")
	_expect(target_span > 0.5, "The running gait no longer creates visibly distinct leg targets")


func _test_free_arm_spin_contract() -> void:
	Input.action_press(&"arrow_spin")
	player._input(_action_event(&"arrow_spin", true))
	player._physics_process(1.0 / 120.0)
	_expect(not player.locked, "Spin did not unlock the body")
	for segment in player.spine:
		_expect(not segment.locked, "Spin did not leave every arm segment physically free")
	_expect(absf(player.angular_velocity) >= 9.5, "Spin did not apply the classic body angular velocity")
	observations["spin_angular_velocity"] = player.angular_velocity

	Input.action_release(&"arrow_spin")
	player._input(_action_event(&"arrow_spin", false))
	_expect(player.locked, "Releasing spin did not relock the body")
	for segment in player.spine:
		_expect(segment.locked, "Releasing spin did not relock every arm segment")
	await get_tree().physics_frame


func _test_snap_and_release_contract() -> void:
	var item = (load("res://Items/Ball.tscn") as PackedScene).instantiate()
	item.set_script(load("res://Items/item.gd"))
	$Tools.add_child(item)
	await get_tree().physics_frame
	item.gravity_scale = 0.0
	item.global_position = player.grabber.global_position + Vector2(100.0, 0.0)
	item.target_node = player.grabber
	item.available = false
	item.snap = true
	item.force = 1.0
	item.linear_velocity = Vector2.ZERO
	item._physics_process(1.0 / 120.0)
	var first_speed: float = item.linear_velocity.length()
	item._physics_process(1.0 / 120.0)
	var second_speed: float = item.linear_velocity.length()
	observations["snap_speed_first"] = first_speed
	observations["snap_speed_second"] = second_speed
	_expect(is_equal_approx(item.force, 1.2), "Classic snap force did not grow by 0.1 per physics tick")
	_expect(second_speed > first_speed + 40.0, "Pickup no longer accelerates decisively toward the hand")

	item.global_position = player.grabber.global_position + Vector2(2.0, 2.0)
	item.linear_velocity = Vector2.ZERO
	item._physics_process(1.0 / 120.0)
	_expect(item.held, "Pickup did not hard-snap into the held state near the hand")
	_expect(not item.snap, "Pickup remained in magnetic-snap mode after reaching the hand")
	_expect(not item.pin.get_node_b().is_empty(), "Pickup did not pin directly to the hand")

	item.linear_velocity = Vector2(800.0, 120.0)
	player.grabbed_item = item
	player.holding_something = true
	item.release()
	_expect(not item.held, "Release left the item marked as held")
	_expect(item.cooldown, "Release did not begin the classic re-grab cooldown")
	_expect(not item.locked, "Release left the item's angle motor locked")
	_expect(item.pin.get_node_b().is_empty(), "Release did not detach the hand pin")
	_expect(is_equal_approx(item.mass, 1.0), "Release did not restore item mass")
	item.queue_free()
	await get_tree().physics_frame


func _action_event(action: StringName, pressed: bool) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	return event


func _release_actions() -> void:
	for action in [&"arrow_up", &"arrow_down", &"arrow_left", &"arrow_right", &"arrow_spin"]:
		Input.action_release(action)


func _expect(condition: bool, message: String) -> void:
	if not condition and message not in failures:
		failures.append(message)
