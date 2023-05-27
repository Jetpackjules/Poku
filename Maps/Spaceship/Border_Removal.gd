extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.




func _on_Border_Removal_body_entered(body):
	if body.is_in_group("tool"):
		body.emit_signal("done")
		body.queue_free()
	if body.is_in_group("ship"):
		print("DEATH")
		body.queue_free()
	if body.is_in_group("player"):
		pass
