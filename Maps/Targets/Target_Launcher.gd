extends Node2D

onready var camera = get_node("../Camera2D")

export var props = ["Target"]

var loaded_props := []

export var initial_spawn := 2

export var spawn_at_point := false

export var x_range_start := -1000 
export var x_range_end := 1000 
export var y_height_start := -1000
export var y_height_end := 1000

var spawn_timer: Timer
var spawn_count := 0
var heights: Array

# In the game script
var player_scores = {1: 0, 2: 0, 3: 0, 4: 0} # or however you're keeping track of player scores



func _ready():
	var size = range(props.size())
	for index in size:
		print("INDEX: ",index)
		props[index] = load("res://Props/"+props[index]+".tscn")

	heights = generate_heights()
	heights.sort()
#	heights.reverse()

	spawn_timer = Timer.new()
	spawn_timer.wait_time = 1.0
	spawn_timer.one_shot = false
	spawn_timer.autostart = true
	spawn_timer.connect("timeout", self, "_spawn_new_prop")
	add_child(spawn_timer)

func _spawn_new_prop(item = null):
	camera.shake(0.25, 10)
	if spawn_count < initial_spawn:
		var new_prop1 = props[randi() % props.size()].instance() 
		var new_prop2 = props[randi() % props.size()].instance() 

		new_prop1.connect("done", self, "_spawn_new_prop")
		new_prop2.connect("done", self, "_spawn_new_prop") 

		new_prop1.launch_force = randi() % 1300 + 200
		new_prop2.launch_force = randi() % 1500 + 500
		add_child(new_prop1)
		add_child(new_prop2)

		var rand_x = rand_range(x_range_start, x_range_end) 
		var y_height = heights.pop_back() if heights.size() > 0 else y_height_end

		if spawn_at_point:
			new_prop1.global_position = self.global_position + Vector2(-rand_x, y_height)
			new_prop2.global_position = self.global_position + Vector2(rand_x, y_height)
		else:
			new_prop1.global_position = Vector2(-rand_x, y_height) 
			new_prop2.global_position = Vector2(rand_x, y_height) 

		spawn_count += 1
	else:
		spawn_timer.stop()

func generate_heights():
	var heights_array: Array = []
	for i in range(initial_spawn):
		heights_array.append(rand_range(y_height_start, y_height_end))
	return heights_array
