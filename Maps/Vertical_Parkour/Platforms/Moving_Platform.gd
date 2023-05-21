extends Path2D


onready var pathing = get_node("PathFollow2D")

func _physics_process(_delta):
	pathing.unit_offset += _delta/14

