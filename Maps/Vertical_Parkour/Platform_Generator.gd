extends Node2D

# Variables to control platform generation
var platform_scenes = [
	{ "scene": preload("res://Maps/Vertical_Parkour/Platforms/Platform.tscn"), "probability": 0.5, "type": "normal" },
	{ "scene": preload("res://Maps/Vertical_Parkour/Platforms/Platform_Small.tscn"), "probability": 0.3, "type": "small" },
	{ "scene": preload("res://Maps/Vertical_Parkour/Platforms/Platform_Moving.tscn"), "probability": 0.2, "type": "moving" }
#    { "scene": preload("res://Maps/Vertical_Parkour/Platform_Spikes.tscn"), "probability": 0.05, "type": "spikes" }
]


var last_platform_position = Vector2(0, 0) # Keep track of the last platform's position
var x_range = Vector2(-1500, 1500) # The range on the x-axis where platforms can be generated
var y_gap = Vector2(200, 400) # The range of possible gaps between platforms on the y-axis
var cam_speed := 1.0
var last_platform_type = "normal" # Initialize with the type of the first platform


onready var camera = get_node("../Camera2D") 
onready var players = get_tree().get_root().get_node("Scene_Manager/Players").get_children()


func _ready():
	randomize()
	generate_platform(Vector2(0, 100))
	
	

func _process(delta):
	
	if !players:
		players = get_tree().get_root().get_node("Scene_Manager/Players").get_children()
	
	if last_platform_position.y > camera.position.y-1000:
		generate_platform(last_platform_position)

#	camera.position.y -= cam_speed
#	cam_speed += delta/45
	

	for player in players:
		if player.global_position.y > camera.position.y+get_viewport().size.y+300:
			
			player.ragdoll(1)
			player.apply_central_impulse(Vector2(0,-2000))


func generate_platform(position):
	
	# Adjust the platform probabilities based on the type of the last platform
#	var total_probability := 0.0
#	for platform in platform_scenes:
#		if last_platform_type == "small" and platform["type"] == "normal":
#			platform["probability"] *= 2.0
#		elif last_platform_type == "normal" and platform["type"] == "small":
#			platform["probability"] *= 2.0
#		elif last_platform_type == "moving":
#			platform["probability"] *= 2.5
#		total_probability += platform["probability"]

	for platform in get_children():
		if platform.position.y > camera.position.y+get_viewport().size.y+500:
			platform.queue_free()
	
	
	# Randomly select a platform scene based on the adjusted probabilities
	var random_value := randf() # * total_probability
	var cumulative_probability := 0.0
	var platform_scene = null
	var platform_type = null
	for platform in platform_scenes:
		cumulative_probability += platform["probability"]
		if random_value <= cumulative_probability:
			platform_scene = platform["scene"]
			platform_type = platform["type"]
			break

	# Adjust the y-gap based on the type of the last platform
	var adjusted_y_gap = y_gap
	if last_platform_type == "moving":
		adjusted_y_gap.y += 100


	# Create a new instance of the platform scene
	var new_platform = platform_scene.instance()
	# Add the platform to the scene
	add_child(new_platform)
	
	
	# Calculate a new position for the platform
	var new_x = rand_range(x_range.x, x_range.y)
	
	if platform_type == "moving":
		new_x = clamp(new_x, -300, 300)  # Keep moving platforms 200 units away from the edges

		new_platform.get_node("PathFollow2D").unit_offset = randf()

		
	
	var new_y = position.y - rand_range(adjusted_y_gap.x, adjusted_y_gap.y)
	new_platform.position = Vector2(new_x, new_y)



	# Update the last platform's position and type
	last_platform_position = new_platform.position
	for platform in platform_scenes:
		if platform["scene"] == platform_scene:
			last_platform_type = platform["type"]
			break
