extends Area2D



func _on_Death_Zone_body_entered(body) -> void:
	if "Body" in body.name:
		if !body.dead and body.controllable:
			body.die()
	#		get_node("CollisionShape2D").disabled = true
			print("DEAD!")
