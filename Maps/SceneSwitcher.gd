extends Node


var current_map

var player_count := 2
var spawned_players := 0
var living_players := 0

var players_moved := 0

signal players_moved

onready var scene_manager = get_tree().get_current_scene()

#onready var tween = scene_manager.get_node("Tween")

onready var transition = load("res://Menus/Transitions/Diamond_Transition.tscn")

var gamemodes := ["Wipeout", "Basketball", "Vertical_Parkour"]

func _input(event):
	if event.is_action_pressed("escape"):
		change_map("Main_Menu")



func _ready():
	randomize()
	
	change_map("Main_Menu")
#	current_map = load("res://Maps/Main_Menu/Main_Menu_Map.tscn").instance()
#	scene_manager.add_child(current_map)
	
#	for mode in current_map.get_node("MenuRoot/Map_Select/CenterContainer/VBoxContainer/GridContainer").get_children():
#		if !("Back" in mode.name):
##			gamemodes.append(mode.name)
#			pass

func random_map() -> void:
	var new_map: String = gamemodes[randi() % gamemodes.size()]
	print(gamemodes)
	print(new_map)
	change_map(new_map)
	

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
	
	var next_map = load("res://Maps/" + next_map_name + "/" + next_map_name + "_Map.tscn").instance()
	if current_map:
		current_map.queue_free()
	current_map = next_map
	
#	if not "Menu" in next_map_name:
	move_players()
		
		
	scene_manager.add_child(next_map)

	



func move_players() -> void:
	players_moved = 0  # reset count every time we start to move players

	while spawned_players < player_count:
		spawned_players += 1
		living_players += 1
		make_player(spawned_players)


	for curr_player in get_players():
		for part in curr_player.body:
			part.set_collision_layer_bit(1, false)
			part.set_collision_mask_bit(0, false)
			part.set_collision_mask_bit(9, false)
		
		
		
		curr_player.ragdoll(0)
		curr_player.win(false)
		var spawn_location = current_map.get_node("Spawns/P" + str(curr_player.get_index()+1) + "_Spawn")
		if spawn_location.scale.x == -1:
			curr_player.flip()
		
		curr_player.controllable = false
		var target_position = spawn_location.global_position
		
		var player_tween = Tween.new()  # create a new tween
		scene_manager.add_child(player_tween)  # add it as a child of the part

		player_tween.interpolate_property(curr_player, "global_position", curr_player.global_position, target_position, 1)
		player_tween.start()
		player_tween.connect("tween_completed", self, "player_move_done", [curr_player])  # pass the player and part as arguments
		



func player_move_done(obj: Object, key: String, curr_player) -> void:
	print("Finished Moving:  ", curr_player)
#	for curr_player in scene_manager.get_node("Players").get_children():
	curr_player.controllable = true

#	Enable this to make players freeze in place for a second before dropping:
#	curr_player.stop()

	for part in curr_player.body:
		if !("Body" in part.name):
			part.set_collision_layer_bit(1, true)
			part.set_collision_mask_bit(0, true)
			part.set_collision_mask_bit(9, true)
		
	players_moved += 1
	if players_moved == player_count:
		emit_signal("players_moved")
		print("all_moved")

func make_player(player_number: int) -> void:
	var new_player = load("res://Player/Player.tscn").instance()
	
	# Fetch spawn location from the map
	var spawn_location = current_map.get_node("Spawns/P" + str(player_number) + "_Spawn")

	# Set the new player's position to the spawn location
	new_player.global_position = spawn_location.global_position
	
	scene_manager.get_node("Players").add_child(new_player)
	new_player.set_name("Body_" + str(player_number))
	
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

func check_living():
	print("ALIVE: ", living_players)
	if living_players <= 1:
		print("ALL DEAD")
		for curr_player in get_players():
			if !curr_player.dead:
				print(curr_player.name, " WINS!")
				curr_player.win(true)
				print("WAITING")
				yield(get_tree().create_timer(5.0), "timeout")
				print("NEEEXT")
				random_map()

func get_players():
	var test = scene_manager.get_node("Players").get_children()
	return scene_manager.get_node("Players").get_children()
