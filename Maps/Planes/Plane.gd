extends RigidBody2D

@export var normal_gravity_force := -4.0
@export var updraft_force := 20.8
@export var steering_strength := 0.1
@export var maximum_tilt_degrees := 16.0
@export var tilt_spring_strength := 85.0
@export var tilt_damping := 13.0
@export var maximum_angular_speed := 1.8
@export var maximum_rise_speed := 360.0
@export var maximum_fall_speed := 280.0
@export var wing_flex_pixels := 18.0

@onready var plane: Node2D = $Plane
@onready var plane_visual: Polygon2D = $Plane/Polygon2D
@onready var center_panel: Control = $Plane/Panel

var gravity_force := -4.0
var stand_zone_bodies: Array = []
var desired_tilt_degrees := 0.0
var _visual_base_polygon := PackedVector2Array()
var _panel_base_scale := Vector2.ONE
var _left_tip_flex := 0.0
var _right_tip_flex := 0.0
var _left_tip_velocity := 0.0
var _right_tip_velocity := 0.0
var _flutter_time := 0.0
var _flutter_phase := 0.0


func _ready() -> void:
	gravity_force = normal_gravity_force
	# The visual is rigidly attached to this physics body. Tilting a child by
	# itself was the source of the visible-wing/collision mismatch.
	plane.rotation = 0.0
	_visual_base_polygon = plane_visual.polygon.duplicate()
	_panel_base_scale = center_panel.scale
	_flutter_phase = float(get_instance_id() % 997) * 0.017


func _process(delta: float) -> void:
	_update_jelly_deformation(delta)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var horizontal_force := 0.0
	var weighted_offset := 0.0
	var valid_bodies := 0
	for body in stand_zone_bodies.duplicate():
		if not is_instance_valid(body):
			stand_zone_bodies.erase(body)
			continue
		var x_difference: float = body.global_position.x - global_position.x
		weighted_offset += x_difference
		horizontal_force += steering_force_for_offset(x_difference)
		valid_bodies += 1
	if valid_bodies > 0:
		desired_tilt_degrees = tilt_for_offset(weighted_offset / valid_bodies)
	else:
		desired_tilt_degrees = 0.0

	state.apply_central_force(Vector2(horizontal_force, -gravity_force * mass * 100.0))
	_apply_tilt_spring(state)
	state.linear_velocity.x = clampf(state.linear_velocity.x, -600.0, 600.0)
	state.linear_velocity.y = clampf(state.linear_velocity.y, -maximum_rise_speed, maximum_fall_speed)


func steering_force_for_offset(x_offset: float) -> float:
	return signf(x_offset) * pow(absf(x_offset), 2.0) * steering_strength * mass


func tilt_for_offset(x_offset: float) -> float:
	# Preserve the original quadratic weight response, but bound it before it
	# can flip the platform or launch its rider.
	return clampf(signf(x_offset) * pow(absf(x_offset), 2.0) / 1000.0, -maximum_tilt_degrees, maximum_tilt_degrees)


func _apply_tilt_spring(state: PhysicsDirectBodyState2D) -> void:
	var current_angle := wrapf(state.transform.get_rotation(), -PI, PI)
	var target_angle := deg_to_rad(desired_tilt_degrees)
	var angle_error := wrapf(target_angle - current_angle, -PI, PI)
	var angular_acceleration := angle_error * tilt_spring_strength - state.angular_velocity * tilt_damping
	if state.inverse_inertia > 0.0:
		state.apply_torque(angular_acceleration / state.inverse_inertia)
	state.angular_velocity = clampf(state.angular_velocity, -maximum_angular_speed, maximum_angular_speed)

	# Collisions can kick a rigid body beyond its intended playful tilt. This
	# safety stop keeps it physical without allowing a full flip.
	var safety_limit := deg_to_rad(maximum_tilt_degrees + 4.0)
	if absf(current_angle) > safety_limit:
		var corrected_angle := clampf(current_angle, -safety_limit, safety_limit)
		state.transform = Transform2D(corrected_angle, state.transform.origin)
		if signf(state.angular_velocity) == signf(current_angle):
			state.angular_velocity = 0.0


func _update_jelly_deformation(delta: float) -> void:
	if _visual_base_polygon.is_empty():
		return
	_flutter_time += delta
	var weight_ratio := clampf(desired_tilt_degrees / maximum_tilt_degrees, -1.0, 1.0)
	var lift_ratio := clampf(-linear_velocity.y / maximum_rise_speed, -1.0, 1.0)
	var shared_lag := lift_ratio * wing_flex_pixels * 0.55
	var left_target := shared_lag
	var right_target := shared_lag
	left_target += maxf(0.0, -weight_ratio) * wing_flex_pixels
	left_target -= maxf(0.0, weight_ratio) * wing_flex_pixels * 0.34
	right_target += maxf(0.0, weight_ratio) * wing_flex_pixels
	right_target -= maxf(0.0, -weight_ratio) * wing_flex_pixels * 0.34
	var movement_load := clampf((absf(linear_velocity.x) + absf(linear_velocity.y)) / 650.0, 0.0, 1.0)
	var flutter := sin(_flutter_time * 6.2 + _flutter_phase) * 1.8 * movement_load
	left_target += flutter
	right_target -= flutter

	var left_spring := _spring_tip(_left_tip_flex, _left_tip_velocity, left_target, delta)
	_left_tip_flex = left_spring.x
	_left_tip_velocity = left_spring.y
	var right_spring := _spring_tip(_right_tip_flex, _right_tip_velocity, right_target, delta)
	_right_tip_flex = right_spring.x
	_right_tip_velocity = right_spring.y

	var deformed := _visual_base_polygon.duplicate()
	for index in deformed.size():
		var base_point := _visual_base_polygon[index]
		var normalized_x := clampf(base_point.x / 280.0, -1.0, 1.0)
		var edge_weight := pow(absf(normalized_x), 1.7)
		var tip_flex := _left_tip_flex if normalized_x < 0.0 else _right_tip_flex
		deformed[index] = base_point + Vector2(0.0, tip_flex * edge_weight)
	plane_visual.polygon = deformed

	var compression := clampf((absf(_left_tip_flex) + absf(_right_tip_flex)) / (wing_flex_pixels * 2.0), 0.0, 1.0)
	var target_panel_scale := _panel_base_scale * Vector2(1.0 + compression * 0.025, 1.0 - compression * 0.055)
	center_panel.scale = center_panel.scale.lerp(target_panel_scale, 1.0 - exp(-10.0 * delta))


func _spring_tip(value: float, velocity: float, target: float, delta: float) -> Vector2:
	var acceleration := (target - value) * 72.0 - velocity * 13.0
	velocity += acceleration * delta
	value += velocity * delta
	return Vector2(value, velocity)


func _on_Updraft_body_entered(body: Node) -> void:
	if body == self:
		gravity_force = updraft_force


func _on_Updraft_body_exited(body: Node) -> void:
	if body == self:
		gravity_force = normal_gravity_force


func _on_Stand_Zone_body_entered(body: Node) -> void:
	if body not in stand_zone_bodies:
		stand_zone_bodies.append(body)


func _on_Stand_Zone_body_exited(body: Node) -> void:
	stand_zone_bodies.erase(body)
