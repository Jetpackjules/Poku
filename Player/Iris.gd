extends KinematicBody2D

var character_velocity = Vector2() # Assume this is the velocity of your character
var iris_speed = 100 # You can adjust this value to your liking

func _physics_process(delta):
	# Get the direction of the character's movement
#	var direction = character_velocity.normalized()
	var direction = get_node("../Whites").get_linear_velocity().normalized()
	direction = global_transform.basis_xform_inv(direction)
#	.normalized()
	# Move the iris in the direction of the character's movement
#	print(direction)
	move_and_slide(direction/1000 * iris_speed)


	pass
