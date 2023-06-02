extends RigidBody2D


export var gap = 100.0
export var speed = 100.0
export var offset = 0.0
var velocity = Vector2.ZERO

func _ready():
	var top_wall = get_node("Wall_Top")
	var bottom_wall = get_node("Wall_Bottom")
	
	top_wall.position.y -= gap/2 
	top_wall.position.y += offset
	
	bottom_wall.position.y += gap/2
	bottom_wall.position.y += offset
	
	print(offset)
	velocity = -position.normalized() * speed

func _physics_process(delta):
	linear_velocity = velocity
