extends CanvasLayer


var time := 0.4
var flip := 1

signal switch


func _ready() -> void:
	# Round intros pause gameplay as soon as the new map enters the tree. The
	# transition must finish uncovering that map even while everything behind it
	# is frozen, otherwise its pink shader remains stranded over the countdown.
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta):
	
	time += delta*flip*2
	$ColorRect.material.set_shader_parameter("progress", clamp(1-time, 0, 1))
	if time >= 1.1:
#		time = 0.0
		emit_signal("switch")
		flip = -1
#		get_tree().change_scene("res://new_scene.tscn")
	elif time < 0.4:
#		breakpoint 
		queue_free()
