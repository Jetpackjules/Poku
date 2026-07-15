extends Node

var actor: Node2D
var legacy_controller: RigidBody2D
var waist: RigidBody2D
var head: RigidBody2D
var spine: Array[RigidBody2D] = []
var legs: Array[RigidBody2D] = []
var stride := 0.0
var run_direction := 1.0


func setup(ostritch: Node2D) -> void:
	actor = ostritch
	legacy_controller = actor.get_node("Spine1")
	waist = actor.get_node("Body")
	head = actor.get_node("Head")
	for node_name in ["Spine1", "Spine2", "Spine3", "Spine4", "Spine5", "Spine6"]:
		spine.append(actor.get_node(node_name))
	for node_name in ["Leg_L_up", "Leg_L_down", "Leg_R_up", "Leg_R_down"]:
		legs.append(actor.get_node(node_name))
	legacy_controller.set_process_input(false)
	legacy_controller.set_physics_process(false)
	for part in spine + legs + [head]:
		if part.get("locked") != null:
			part.locked = true


func shutdown() -> void:
	if is_instance_valid(legacy_controller):
		legacy_controller.set_process_input(true)
		legacy_controller.set_physics_process(true)
	queue_free()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(actor):
		return
	var input_direction := Input.get_axis("ui_left", "ui_right")
	if not is_zero_approx(input_direction):
		run_direction = -signf(input_direction)
		stride += delta * 2.15
	_drive_horizontal(input_direction, delta)
	_drive_pose(input_direction)
	_stabilize_waist(delta)

	var grounded: bool = waist.get_node("RayCast2D").is_colliding()
	if grounded and Input.is_action_just_pressed("ui_up"):
		for part in spine + [waist]:
			part.apply_central_impulse(Vector2.UP * 160.0 * maxf(part.mass, 0.1))

	if Input.is_action_pressed("ui_down"):
		waist.gravity_scale = 4.0
		head.gravity_scale = 3.0
		for part in spine:
			if part.get("locked") != null:
				part.locked = false
	else:
		waist.gravity_scale = 1.0
		head.gravity_scale = 1.0
		for part in spine:
			if part.get("locked") != null:
				part.locked = true


func _drive_horizontal(direction: float, delta: float) -> void:
	var desired_velocity := direction * 420.0
	for part in spine + [waist]:
		var velocity_error: float = desired_velocity - part.linear_velocity.x
		var acceleration: float = clampf(velocity_error * 7.0, -1700.0, 1700.0)
		part.apply_central_force(Vector2(acceleration * maxf(part.mass, 0.1), 0.0))
		part.linear_velocity.x = move_toward(part.linear_velocity.x, desired_velocity, 900.0 * delta)


func _drive_pose(input_direction: float) -> void:
	if is_zero_approx(input_direction):
		for leg in legs:
			leg.new_desired_angle = 0.0
		return
	var upper_right := _sample_gait([-1.0, 0.0, 2.4, 0.0], stride) * run_direction
	var upper_left := _sample_gait([-1.0, 0.0, 2.4, 0.0], stride + 0.5) * run_direction
	var lower_right := -_sample_gait([2.0, 1.0, 2.0, -1.0], stride) * run_direction
	var lower_left := -_sample_gait([2.0, 1.0, 2.0, -1.0], stride + 0.5) * run_direction
	actor.get_node("Leg_R_up").new_desired_angle = upper_right
	actor.get_node("Leg_L_up").new_desired_angle = upper_left
	actor.get_node("Leg_R_down").new_desired_angle = lower_right
	actor.get_node("Leg_L_down").new_desired_angle = lower_left


func _stabilize_waist(delta: float) -> void:
	var angle_error := wrapf(-waist.global_rotation, -PI, PI)
	var desired_angular_velocity := clampf(angle_error * 8.0, -8.0, 8.0)
	waist.angular_velocity = move_toward(waist.angular_velocity, desired_angular_velocity, 22.0 * delta)


func _sample_gait(keyframes: Array, progress: float) -> float:
	var index := int(progress * keyframes.size())
	var interpolation := progress * keyframes.size() - index
	return lerp_angle(
		float(keyframes[index % keyframes.size()]),
		float(keyframes[(index + 1) % keyframes.size()]),
		interpolation
	)
