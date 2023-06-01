extends "res://Powerup/Powerup.gd"

func ingested():
	print("Powerup has been ingested 2!")  # replace with your own logic
	target_body.speed *= 2
	
#	queue_free()


func _on_Timer_timeout():
	target_body.speed *= 0.5
	queue_free()
