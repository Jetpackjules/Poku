extends Area2D

# Node paths
onready var rigidbody = $RigidBody2D
onready var tween = $Tween

# Bobbing properties
var bobbing_speed := 2
var bobbing_height := 15
var bobbing_pos = Vector2.ZERO

# Powerup properties
var target_body
var being_ingested := false

# Tween properties
var max_tween_duration := 3.0  # Duration when the powerup is far
var min_tween_duration := 0.01  # Duration when the powerup is near

# Shrink properties
var max_scale = Vector2(1, 1)  # Scale when the powerup is far
var min_scale = Vector2(0, 0)  # Scale when the powerup is near

func _ready():
	# Initialize bobbing position
	bobbing_pos = rigidbody.global_position

func _process(delta):
	if not being_ingested:
		# Make the powerup bob up and down
		var bobbing_offset = Vector2(0, sin(bobbing_speed * OS.get_ticks_msec() / 1000.0) * bobbing_height)
		rigidbody.global_position = bobbing_pos + bobbing_offset
	elif target_body:
		# Compute the tween's duration based on the distance to the target body
		var distance = rigidbody.global_position.distance_to(target_body.global_position)
		var tween_duration = lerp(max_tween_duration, min_tween_duration, 1 - distance / 500)  # Replace 500 with the maximum expected distance
		# Update the tween's final value to follow the body
		tween.interpolate_property(rigidbody, "global_position", rigidbody.global_position, target_body.global_position, tween_duration, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
		tween.interpolate_property(rigidbody, "scale", rigidbody.scale, lerp(max_scale, min_scale, 1 - distance / 500), tween_duration, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
		tween.start()
		if distance < 15:
			get_node("Pickup_Area").disabled = true
			get_node("Timer").start()
			ingested()
			being_ingested = false

func _on_Powerup_body_entered(body):
	# If a body enters the Area2D, stop bobbing and start moving the powerup towards it
	being_ingested = true
	target_body = body
	var distance = rigidbody.global_position.distance_to(target_body.global_position)
	var tween_duration = lerp(max_tween_duration, min_tween_duration, 1 - distance / 500)  # Replace 500 with the maximum expected distance
	tween.interpolate_property(rigidbody, "global_position", rigidbody.global_position, body.global_position, tween_duration, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	tween.interpolate_property(rigidbody, "scale", rigidbody.scale, lerp(max_scale, min_scale, 1 - distance / 500), tween_duration, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	tween.start()

func ingested():
	print("Powerup has been ingested!")  # replace with your own logic
	queue_free()
