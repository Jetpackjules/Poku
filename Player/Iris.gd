extends Node2D

onready var counterweight := get_node("../Counterweight")

onready var normal_iris := get_node("Iris")
onready var dead_iris1 := get_node("Dead_Iris1")
onready var dead_iris2 := get_node("Dead_Iris2")

var dead := false


func dead_iris(status: bool) -> void:
	dead = status 
	normal_iris.visible = !status
	dead_iris1.visible = status
	dead_iris2.visible = status

#func _physics_process(_delta):
##	print(counterweight.linear_velocity)
###	print("d")
##	if counterweight.linear_velocity >= Vector2(100, 100):
##		counterweight.linear_velocity = Vector2(-500,-500)
#	rect_position = (-counterweight.position) - Vector2(7.5, 5)

func _physics_process(_delta):
	# Apply linear dampening
	counterweight.linear_damp = 1.0

	# Get the desired position
	
	if !dead:
		var desired_position: Vector2 = -counterweight.position

		var clamp_y := 6  + 5
		var clamp_x := 2 + 7.5

		# Check if the position is inside the ellipse
		if pow((desired_position.x / clamp_x),2) + pow((desired_position.y / clamp_y),2) > 1:
			# If not, find the nearest point on the ellipse
			var angle = atan2(desired_position.y, desired_position.x)
			desired_position.x = clamp_x * cos(angle)
			desired_position.y = clamp_y * sin(angle)

		# Set the position
		position = desired_position - Vector2(7.5, 5)
	else:
		position = -Vector2(7.5, 5)
