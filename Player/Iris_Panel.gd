extends Panel

onready var counterweight := get_node("../Counterweight")

func _physics_process(_delta):
#	print(counterweight.linear_velocity)
##	print("d")
#	if counterweight.linear_velocity >= Vector2(100, 100):
#		counterweight.linear_velocity = Vector2(-500,-500)
	rect_position = (-counterweight.position) - Vector2(7.5, 5)
