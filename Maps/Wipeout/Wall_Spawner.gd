extends Node2D

export var Wall = preload("res://Maps/Wipeout/Wall.tscn")
export var time_until_next_wall = 4.0
export var max_gap_size = 600
export var min_gap_size = 100
export var num_walls_spawned = 0  # Use this to shrink the gap size
export var gap_shrink_speed = 80  # How fast the gap shrinks
var speed = 100

func _physics_process(delta):
	time_until_next_wall -= delta

	if time_until_next_wall <= 0:
		time_until_next_wall = 5  # Randomize time until next wall
		spawn_wall()
		
	speed += 0.1
#	print(speed)

func spawn_wall():
	var wall = Wall.instance()
	var spawn_position = Vector2.ZERO
	var rand_side = randi() % 1 + 1

	# Determine spawn position based on random side
	
	
	match rand_side:
		0:  # Top
			spawn_position = Vector2(0, -get_viewport().size.y) # arbitrary offscreen value
			wall.rotation_degrees = 90
		1:  # Right
			spawn_position = Vector2(get_viewport().size.x/2 + 500, 0)  # arbitrary offscreen value
		2:  # Left
			spawn_position = Vector2(-get_viewport().size.x/2 - 500, 0)  # arbitrary offscreen value
			
#	wall.global_position = spawn_position
	# Determine the gap size
	var gap_size = max(max_gap_size - gap_shrink_speed * num_walls_spawned, min_gap_size)
	
	print(gap_shrink_speed * num_walls_spawned)
	
	
	print(gap_size)
	wall.gap = gap_size  # Set the gap size of the wall
	
	wall.speed = speed
	# Set a random offset for the wall
	var wall_offset = rand_range(-550, 1000)  # Set a random offset for the wall
	wall.offset = wall_offset
	
	add_child(wall)
	
	wall.position = Vector2(2*(get_viewport().size.x/2 * 1.7), 0)
	
	
	wall.adjust()
	
#	print(gap_size)
	
	num_walls_spawned += 1
