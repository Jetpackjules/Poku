extends Node2D

# Variables to control platform generation
var platform_scene = preload("res://Maps/Vertical_Parkour/Platform.tscn") # Preload your platform scene
var last_platform_position = Vector2(0, 0) # Keep track of the last platform's position
var x_range = Vector2(-1500, 1500) # The range on the x-axis where platforms can be generated
var y_gap = Vector2(200, 400) # The range of possible gaps between platforms on the y-axis
var cam_speed := 1.0

onready var camera = get_node("../Camera2D") 
onready var players = get_tree().get_root().get_node("Scene_Manager/Players").get_children()


func _ready():
	# Generate the first platform
	generate_platform(Vector2(0, 100))

func _process(delta):
	# Check if we need to generate a new platform
	if last_platform_position.y < get_viewport().size.y:
		generate_platform(last_platform_position)
		
		get_node("../Camera2D").position.y -= cam_speed
		cam_speed += delta/45
	
	if !players:
		players = get_tree().get_root().get_node("Scene_Manager/Players").get_children()
	
	for player in players:
		print(camera.global_position.y, " || ", player.global_position.y)
		if player.global_position.y >= camera.global_position.y-540:
			pass
#			print("DEAD")

func generate_platform(position):
	# Create a new instance of the platform scene
	var new_platform = platform_scene.instance()

	# Calculate a new position for the platform
	var new_x = rand_range(x_range.x, x_range.y)
	var new_y = position.y - rand_range(y_gap.x, y_gap.y)
	new_platform.position = Vector2(new_x, new_y)
#	print(new_platform.position)
	# Add the platform to the scene
	add_child(new_platform)

	# Update the last platform's position
	last_platform_position = new_platform.position
