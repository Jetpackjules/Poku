extends RigidBody2D

onready var plane := get_node("Plane")

var gravity := -4.0
var reg_gravity := gravity

var updraft_gravity := 20.8


# Array to keep track of bodies in the "Stand Zone"
var stand_zone_bodies = []

func _ready():
	pass

func _physics_process(delta):
	
#	updraft_gravity = 20.8
	applied_force.y = -gravity*mass*100
	
	 
	
	
	# Apply force based on the position of bodies in the "Stand Zone"
	if stand_zone_bodies:
		for body in stand_zone_bodies:
	#		print(plane.global_position.x - body.global_position.x)
			var x_diff = body.global_position.x - plane.global_position.x
			applied_force.x = (sign(x_diff) * pow(abs(x_diff), 2) / 10) * mass
			print(sign(x_diff) * pow(abs(x_diff), 1.5) / 600)
			plane.rotation_degrees = lerp(plane.rotation_degrees, sign(x_diff) * pow(abs(x_diff), 2) / 1000, 0.3)
	else:
		plane.rotation_degrees = lerp(plane.rotation_degrees, 0, 0.03)
		
	

	linear_velocity.x = clamp(linear_velocity.x, -600, 600)
	linear_velocity.y = clamp(linear_velocity.y, -300, 300)
	
#	linear_velocity.y = 0
#	plane.linear_velocity.y = 0

func _on_Updraft_body_entered(body):
	if body == self:
		gravity = updraft_gravity
		print("Plane entered updraft")

func _on_Updraft_body_exited(body):
	if body == self:
		gravity = reg_gravity
		print("Plane left updraft")

# Add body to the array when it enters the "Stand Zone"
func _on_Stand_Zone_body_entered(body):
	stand_zone_bodies.append(body)

# Remove body from the array when it exits the "Stand Zone"
func _on_Stand_Zone_body_exited(body):
	stand_zone_bodies.erase(body)

