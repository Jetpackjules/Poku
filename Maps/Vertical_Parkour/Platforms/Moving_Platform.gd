extends Path2D


@onready var pathing = get_node("PathFollow2D")

func _physics_process(_delta):
	pathing.progress_ratio += _delta/14

