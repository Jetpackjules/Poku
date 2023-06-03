extends RigidBody2D

# Assuming the Area2D node is a child of the current node and it's named "UpdraftArea".
onready var plane = get_node("Plane")

# Initial gravity value
var gravity = Vector2(0, 17.8)

# When in updraft, the gravity will become negative
var updraft_gravity = Vector2(0, -45.8)

func _ready():
	pass


func _physics_process(delta):
	# Apply constant downward force
#	apply_central_impulse(-gravity*1000)
	applied_force.y = -gravity.y
	print(gravity.y)
#	print("")
#	print("")
	# The horizontal motion remains the same
	linear_velocity.x = plane.rotation_degrees * 20


func _on_Updraft_body_entered(body):
	if body == self:
		gravity = updraft_gravity
		print("Plane entered updraft")
		print("ENTERED")


func _on_Updraft_body_exited(body):
	if body == self:
		gravity = Vector2(0, 90.8)
		print("Plane left updraft")
		print("EXITED")
pass # Replace with function body.
