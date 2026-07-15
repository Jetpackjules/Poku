extends RigidBody2D

const FURNACE_ATMOSPHERE = preload("res://Effects/FurnaceAtmosphere.gd")

@export var base_float_height := 100.0
@export var height_per_coal := 400.0
@export var maximum_motor_speed := 800.0
@export var motor_response := 5.0
@export var maximum_motor_acceleration := 2100.0

var float_height := 100.0
var total_fuel := 0.0
var coal_objects: Array = []
var max_thrusters := 5
var OG_X := 0.0
var thrusters_left: Array = []
var thrusters_right: Array = []
var furnace_visuals: Node2D

@onready var thruster_left: GPUParticles2D = $Thruster_Left
@onready var thruster_right: GPUParticles2D = $Thruster_Right


func _ready() -> void:
	OG_X = global_position.x
	thrusters_left = [thruster_left]
	thrusters_right = [thruster_right]
	furnace_visuals = FURNACE_ATMOSPHERE.new()
	furnace_visuals.name = "FurnaceAtmosphere"
	$Furnace.add_child(furnace_visuals)
	furnace_visuals.setup($Furnace)


func _physics_process(delta: float) -> void:
	_burn_loaded_coal(delta)
	_update_thrusters()


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# A bounded spring motor lets the ship feel physical when players and coal
	# land on it, instead of replacing its velocity every frame.
	var target := Vector2(OG_X, -float_height)
	var position_error := target - state.transform.origin
	var desired_velocity := position_error * 1.8
	if desired_velocity.length() > maximum_motor_speed:
		desired_velocity = desired_velocity.normalized() * maximum_motor_speed
	var acceleration := (desired_velocity - state.linear_velocity) * motor_response
	if acceleration.length() > maximum_motor_acceleration:
		acceleration = acceleration.normalized() * maximum_motor_acceleration
	state.linear_velocity += acceleration * state.step

	var angle_error := wrapf(-state.transform.get_rotation(), -PI, PI)
	var angular_acceleration := angle_error * 28.0 - state.angular_velocity * 9.0
	state.angular_velocity += clampf(angular_acceleration, -45.0, 45.0) * state.step


func _burn_loaded_coal(delta: float) -> void:
	total_fuel = 0.0
	for coal in coal_objects.duplicate():
		if not is_instance_valid(coal) or coal.is_done:
			coal_objects.erase(coal)
			continue
		if coal.held:
			coal.release()
		coal.available = false
		coal.cooldown = true
		coal.burn_time = maxf(0.0, coal.burn_time - delta)
		var fuel_fraction: float = coal.burn_time / coal.burn_time_for_scale
		total_fuel += fuel_fraction
		var coal_scale := sqrt(maxf(fuel_fraction, 0.0))
		coal.scale = Vector2.ONE * coal_scale
		if coal.burn_time <= 0.0:
			coal_objects.erase(coal)
			coal.is_done = true
			coal.done.emit(coal)
			coal.queue_free()

	float_height = base_float_height + total_fuel * height_per_coal
	if is_instance_valid(furnace_visuals):
		furnace_visuals.set_fuel(total_fuel)


func _update_thrusters() -> void:
	var desired_count := clampi(maxi(1, int(ceil(total_fuel))), 1, max_thrusters)
	_resize_thruster_side(thrusters_left, thruster_left, desired_count)
	_resize_thruster_side(thrusters_right, thruster_right, desired_count)
	var intensity := 1.0 + total_fuel * 0.8
	for thruster in thrusters_left + thrusters_right:
		if is_instance_valid(thruster):
			thruster.speed_scale = intensity
			thruster.emitting = total_fuel > 0.02


func _resize_thruster_side(thrusters: Array, source: GPUParticles2D, desired_count: int) -> void:
	while thrusters.size() > desired_count:
		var extra = thrusters.pop_back()
		if extra != source:
			extra.queue_free()
	while thrusters.size() < desired_count:
		var duplicate := source.duplicate() as GPUParticles2D
		add_child(duplicate)
		thrusters.append(duplicate)


func _on_Furnace_body_entered(body: Node) -> void:
	if body.is_in_group("flammable") and body not in coal_objects and not body.is_done:
		coal_objects.append(body)


func _on_Furnace_body_exited(body: Node) -> void:
	if body in coal_objects:
		coal_objects.erase(body)
