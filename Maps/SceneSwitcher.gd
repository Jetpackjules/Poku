extends Node


var current_map

var player_count := 2
var spawned_players := 0

onready var scene_manager = get_tree().get_current_scene()

onready var tween = scene_manager.get_node("Tween")

onready var transition = load("res://Menus/Transitions/Diamond_Transition.tscn")

func _input(event):
	if event.is_action_pressed("escape"):
		change_map("Main_Menu")



func _ready():
	tween.connect("tween_all_completed", self, "player_move_done")
	
	current_map = load("res://Maps/Main_Menu/Main_Menu_Map.tscn").instance()
	scene_manager.add_child(current_map)

func change_map(next_map_name: String) -> void:
#	var next_map: Resource
	
#	match next_map_name:
#		"main_menu":
#			next_map = load("res://Menus/Start/Main_Menu.tscn")
#		"basketball":
#			next_map = load("res://Maps/Basketball/Basketball_Stadium.tscn")
#		_:
#			print("INVALID LEVEL NAME!")
#			breakpoint 
	
	
#	Transition:
	var obscurer = transition.instance()
	scene_manager.add_child(obscurer)
	yield(obscurer, "switch")
	
	var next_map = load("res://Maps/" + next_map_name + "/" + next_map_name + "_map.tscn").instance()
	scene_manager.add_child(next_map)
	if current_map:
		current_map.queue_free()
	current_map = next_map
	
	if not "Menu" in next_map_name:
		move_players()
		


func move_players() -> void:
	while spawned_players < player_count:
		spawned_players += 1
		make_player(spawned_players)
		
	

	
	for curr_player in scene_manager.get_node("Players").get_children():
		var spawn_location = current_map.get_node("Spawns/P" + str(curr_player.get_index()+1) + "_Spawn")
		if spawn_location.scale.x == -1:
			curr_player.flip()
		
		curr_player.controllable = false
#		curr_player.global_position = spawn_location.global_position
		tween.interpolate_property(curr_player, "global_position", curr_player.global_position, spawn_location.global_position, 1)
#		tween.interpolate_property(next_menu, "rect_global_position", next_menu.rect_global_position, menu_origin_position, menu_transition_time)
		tween.start()
		

func player_move_done():
	for curr_player in scene_manager.get_node("Players").get_children():
		curr_player.controllable = true


func make_player(player_number: int) -> void:
	var new_player = load("res://Player/Player.tscn").instance()
	new_player.global_position = Vector2(0,0)
	scene_manager.get_node("Players").add_child(new_player)
	
	match player_number:
		1:
			new_player.jump = "wasd_up"
			new_player.crouch = "wasd_down"
			new_player.move_right = "wasd_right"
			new_player.move_left = "wasd_left"
			new_player.spin = "wasd_spin"
			
			# Green and Orange:
			new_player.set_color(Color(0.184314, 0.792157, 0.101961), Color(0.988235, 0.580392, 0.023529))
		2:
			new_player.jump = "arrow_up"
			new_player.crouch = "arrow_down"
			new_player.move_right = "arrow_right"
			new_player.move_left = "arrow_left"
			new_player.spin = "arrow_spin"
			
			# Green and Orange:
			new_player.set_color(Color(0.901961, 0.184314, 0.682353), Color(0.94902, 0.886275, 0))
		_:
			breakpoint
