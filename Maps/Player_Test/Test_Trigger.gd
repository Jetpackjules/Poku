extends Area2D

onready var camera = get_node("../Camera2D")



func _on_Area2D_body_entered(body):
	camera.shake(0.25, 10)
	get_node("ColorRect").color = Color(randf(), randf(), randf(), 1.0)
