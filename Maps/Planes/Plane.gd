extends RigidBody2D

@export var normal_gravity_force := -4.0
@export var updraft_force := 20.8
@export var steering_strength := 0.1

@onready var plane: RigidBody2D = $Plane

var gravity_force := -4.0
var stand_zone_bodies: Array = []
var desired_visual_tilt := 0.0


func _ready() -> void:
	gravity_force = normal_gravity_force


func _process(delta: float) -> void:
	var blend := 1.0 - exp(-8.0 * delta)
	plane.rotation_degrees = lerpf(plane.rotation_degrees, desired_visual_tilt, blend)


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
		horizontal_force += signf(x_difference) * pow(absf(x_difference), 2.0) * steering_strength * mass
		valid_bodies += 1
	if valid_bodies > 0:
		desired_visual_tilt = clampf((weighted_offset / valid_bodies) * 0.08, -18.0, 18.0)
	else:
		desired_visual_tilt = 0.0

	state.apply_central_force(Vector2(horizontal_force, -gravity_force * mass * 100.0))
	state.linear_velocity.x = clampf(state.linear_velocity.x, -600.0, 600.0)
	state.linear_velocity.y = clampf(state.linear_velocity.y, -520.0, 420.0)


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
