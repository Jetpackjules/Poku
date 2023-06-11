extends Node2D

export var tools = ["Ball", "Shuriken", "Spear"]

var loaded_tools := []

var ball_count := 0

export var initial_spawn := 4

export var spawn_at_point := false

var x_range_start := -1000 
var x_range_end := 1000 
var y_height := -1000
	
func _ready():
	for index in range(tools.size()):

		tools[index] = load("res://Items/"+tools[index]+".tscn")

	for i in range(initial_spawn):
		_spawn_new_tool()


func _spawn_new_tool(item = null):
	if item:
		var name = item.name
		if "Ball" in item.name:
			ball_count -= 1

	var new_tool = tools[randi() % tools.size()].instance() 
	if "Ball" in new_tool.name:
		ball_count += 1
		if ball_count > 2:
			new_tool.queue_free()
			_spawn_new_tool()
			ball_count -= 1
			return
		
	new_tool.connect("done", self, "_spawn_new_tool") 
	
#	call_deferred("add_child", new_tool)
#	commented because it messes up position with spawn at point &^^ 
	add_child(new_tool)
	
	if spawn_at_point:
		new_tool.global_position = self.global_position
	else:
		var rand_x = rand_range(x_range_start, x_range_end) 
		new_tool.global_position = Vector2(rand_x, y_height) 
	
	if new_tool.global_position.x > 0:
		new_tool.rotation_degrees = 180



	
	if get_children().size() >= 7:
		for curr_tool in get_children():
			if curr_tool.done == true:
				curr_tool.queue_free()
				break
