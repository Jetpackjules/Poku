extends Area2D

# Node paths
@onready var rigidbody = $RigidBody2D
var follow_tween: Tween

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
		var bobbing_offset = Vector2(0, sin(bobbing_speed * Time.get_ticks_msec() / 1000.0) * bobbing_height)
		rigidbody.global_position = bobbing_pos + bobbing_offset
	elif target_body:
		# Compute the tween's duration based on the distance to the target body
		var distance = rigidbody.global_position.distance_to(target_body.global_position)
		var tween_duration = lerp(max_tween_duration, min_tween_duration, 1 - distance / 500)  # Replace 500 with the maximum expected distance
		# Update the tween's final value to follow the body
		follow_target(target_body.global_position, lerp(max_scale, min_scale, 1 - distance / 500), tween_duration)
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
	follow_target(body.global_position, lerp(max_scale, min_scale, 1 - distance / 500), tween_duration)

func follow_target(target_position: Vector2, target_scale: Vector2, duration: float):
	if follow_tween and follow_tween.is_valid():
		follow_tween.kill()
	follow_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	follow_tween.tween_property(rigidbody, "global_position", target_position, duration)
	follow_tween.tween_property(rigidbody, "scale", target_scale, duration)

func ingested():
	print("Powerup has been ingested!")  # replace with your own logic
	queue_free()
