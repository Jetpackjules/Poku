extends AnimatableBody2D


@export var gap = 10.0


@export var speed = 100.0
@export var offset = 0.0
var velocity = Vector2.ZERO

@onready var top_wall = get_node("Wall_Top")
@onready var bottom_wall = get_node("Wall_Bottom")


func adjust() -> void:
	velocity = -position.normalized() * speed
	
	
	
	top_wall.position.y -= gap/2 
	bottom_wall.position.y += gap/2
	
#	top_wall.position.y += offset
	position.y += offset
	
#	print(offset)


func _physics_process(delta: float) -> void:
	constant_linear_velocity = velocity
	position += velocity * delta
	if position.x < -2600.0:
		queue_free()
