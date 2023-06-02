extends RigidBody2D


export var gap := 100.0
export var speed := 100.0
export var offset := 0.0

func _ready():
	var top_wall = get_node("Wall_Top")
	var bottom_wall = get_node("Wall_Bottom")
	
	top_wall.position.y -= gap/2 + offset
	bottom_wall.position.y += gap/2 + offset
	
	linear_velocity = -global_position.normalized() * speed