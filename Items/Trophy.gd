extends StaticBody2D

var winning_player

# Bobbing properties
var bobbing_speed := 2
var bobbing_height := 15

var bobbing_pos := Vector2(0,-140)

func _physics_process(delta):
#	bobbing_pos = winning_player.global_position
#	bobbing_pos = Vector2(0,-900)
#	print(bobbing_pos)

	# Make the powerup bob up and down
	var bobbing_offset = Vector2(0, sin(bobbing_speed * OS.get_ticks_msec() / 1000.0) * bobbing_height)
	position = bobbing_pos + bobbing_offset
 
