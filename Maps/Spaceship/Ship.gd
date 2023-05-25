extends RigidBody2D

var float_height : float = 0.0
var coal_objects : Array = []

func _physics_process(_delta):
	# Adjust the float height based on the number of coal objects
	float_height = 100 + coal_objects.size() * 200.0  # Adjust the multiplier as needed

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
	for coal in coal_objects:
		coal.burn_time -= _delta
		if coal.burn_time <= 0:
			coal_objects.erase(coal)
			coal.queue_free()


func _on_Furnace_body_entered(body):
	if body.is_in_group("flammable"):
		coal_objects.append(body)

func _on_Furnace_body_exited(body):
	if body.is_in_group("flammable"):
		coal_objects.erase(body)
