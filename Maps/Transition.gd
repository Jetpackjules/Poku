extends CanvasLayer


var time := 0.4
var flip := 1

signal switch

func _process(delta):
	
	time += delta*flip*2
	$ColorRect.material.set_shader_param("progress", clamp(1-time, 0, 1))
	if time >= 1.1:
#		time = 0.0
		emit_signal("switch")
		flip = -1
#		get_tree().change_scene("res://new_scene.tscn")
	elif time < 0.4:
#		breakpoint 
		queue_free()
