extends Area2D

onready var deathzone = get_node("Death_Zone")



func _on_AnimationPlayer_animation_finished(anim_name):
	deathzone.get_node("CollisionShape2D").disabled = false
