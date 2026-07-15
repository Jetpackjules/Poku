extends "res://Powerup/Powerup.gd"

func ingested():
	target_body.speed *= 2
	
#	queue_free()


func _on_Timer_timeout():
	target_body.speed *= 0.5
	queue_free()
