extends Node2D

onready var tools = load("res://Items/Tools.tscn").instance().get_children()

var loaded_tools = []

var ball_count := 0

func _ready():
	_spawn_new_tool()
	_spawn_new_tool()
	_spawn_new_tool()
	_spawn_new_tool()


func _spawn_new_tool(item = null):
	if item:
		var name = item.name
		if "Ball" in item.name:
			ball_count -= 1

	var new_tool = tools[randi() % tools.size()].duplicate() 
	if "Ball" in new_tool.name:
		ball_count += 1
		if ball_count > 2:
			new_tool.queue_free()
			_spawn_new_tool()
			ball_count -= 1
			return
		
	new_tool.connect("done", self, "_spawn_new_tool") 
	
	var x_range_start = -1000 
	var x_range_end = 1000 
	var y_height = -1000
	
	var random_x = rand_range(x_range_start, x_range_end) 

	
	add_child(new_tool)
#	new_tool.owner = self
	
	new_tool.global_position = Vector2(random_x, y_height) 
	
	if get_children().size() >= 7:
		for curr_tool in get_children():
			if curr_tool.done == true:
				curr_tool.queue_free()
				break
