extends RigidBody2D

var float_height : float = 0.0
var coal_objects : Array = []
var max_thrusters : int = 5


var thrusters_left : Array = []
var thrusters_right : Array = []

onready var thruster_left = get_node("Thruster_Left")
onready var thruster_right = get_node("Thruster_Right")

var new_desired_angle := 0.0
	
func _physics_process(_delta):
	
	var current_angle = get_global_transform().get_rotation()
	var angle_difference = abs(fmod((current_angle - new_desired_angle + PI), (2*PI)) - PI)
#	print(rad2deg(angle_difference))
	if angle_difference > deg2rad(100):  # Adjust this value to change the size of the dead zone
		angular_velocity = lerp_angle(current_angle, new_desired_angle, (10)* _delta)
	else:
		angular_velocity = 0

	
	# Calculate the target position
	var target_position = Vector2(global_position.x, -float_height)

	# Calculate the direction to the target position
	var direction = (target_position - global_position).normalized()

	# Calculate the distance to the target position
	var distance = global_position.distance_to(target_position)

	# Calculate the speed based on the distance
	var speed = clamp(distance * 0.5, 0, 800)  # Adjust the maximum speed as needed

	# Set the velocity to move towards the target position
	linear_velocity = direction * speed

	# Remove burned coal
	var total_fuel := 0.0
	for coal in coal_objects:
		total_fuel += coal.burn_time/coal.burn_time_for_scale
		
		if coal.held:
			coal.release()
		
		coal.available = false
		coal.cooldown = true
		coal.cooltime_wait -= _delta
		coal.burn_time -= _delta
		
		# Calculate the coal_size using a square root function
		var coal_size = sqrt(coal.burn_time/coal.burn_time_for_scale)
		coal.scale = Vector2(coal_size, coal_size)
		
		if coal.burn_time <= 0:
			coal_objects.erase(coal)
			coal.emit_signal("done", coal)
			coal.queue_free()
		
#	Make ship float based off of fuel:
	float_height = 100 + total_fuel * 400.0  # Adjust the multiplier as needed
	
#	Change thruster power based off of fuel:
#	thruster.process_material.set("speed_scale", 1 * total_fuel/10 + 1)


#	20 * total_fuel +20
#	thruster.speed_scale = 1 * total_fuel/1.25 + 1

	# Change the speed_scale of all current thrusters
	var speed_scale = 1 * total_fuel/1.25 + 1
	for thruster in thrusters_left:
		thruster.speed_scale = speed_scale
	for thruster in thrusters_right:
		thruster.speed_scale = speed_scale

	# Determine the number of thrusters to create
	var num_thrusters = max(1, int(total_fuel))

	# Delete extra thrusters
	while thrusters_left.size() > num_thrusters:
		var thruster_to_delete = thrusters_left.pop_back()
		thruster_to_delete.queue_free()
	while thrusters_right.size() > num_thrusters:
		var thruster_to_delete = thrusters_right.pop_back()
		thruster_to_delete.queue_free()

	# Create new thrusters
	while thrusters_left.size() < num_thrusters:
		var new_thruster = thruster_left.duplicate()
		add_child(new_thruster)
		thrusters_left.append(new_thruster)
	while thrusters_right.size() < num_thrusters:
		var new_thruster = thruster_right.duplicate()
		add_child(new_thruster)
		thrusters_right.append(new_thruster)

func _on_Furnace_body_entered(body):
	if body.is_in_group("flammable"):
		coal_objects.append(body)


func _on_Furnace_body_exited(body):
	if body.is_in_group("flammable"):
		coal_objects.erase(body)
		
