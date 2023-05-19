extends Node2D


onready var timer := get_node("Timer")
onready var score := get_node("../Score")

var body_inside



func _on_Hoop_Goal_body_entered(body):
	if body.is_in_group("score-able"):
		body_inside = body
		timer.start() 

func _on_Hoop_Goal_body_exited(body):
	if body.is_in_group("score-able"):
		timer.stop()
		timer.wait_time = 2
	
func _on_Timer_timeout():
	body_inside.emit_signal("done", body_inside)
	body_inside.queue_free()


	if "right" in name:
		get_node("../Score").update_score(0, 1)
	else:
		get_node("../Score").update_score(1, 0)
	

