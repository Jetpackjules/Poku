extends Node


var current_map

var player_count := 2
var spawned_players := 0
var living_players := 0

var players_moved_count := 0
var start := false
var _requested_main_menu_page := ""

signal players_moved

@onready var scene_manager = get_tree().get_current_scene()

#onready var tween = scene_manager.get_node("Tween")

@onready var transition = load("res://Menus/Transitions/Diamond_Transition.tscn")

var gamemodes := [
	"Basketball",
	"Volleyball",
	"Vertical_Parkour",
	"Spaceship",
	"Wipeout",
	"Planes",
	"Targets"
]

func _input(event):
	if event.is_action_pressed("random_map"):
		random_map()


func _ready():
	if OS.get_environment("POKU_POLISH_TEST") == "1":
		return
	randomize()
	
	change_map("Main_Menu")
#	current_map = load("res://Maps/Main_Menu/Main_Menu_Map.tscn").instance()
#	scene_manager.add_child(current_map)
	
#	for mode in current_map.get_node("MenuRoot/Map_Select/CenterContainer/VBoxContainer/GridContainer").get_children():
#		if !("Back" in mode.name):
##			gamemodes.append(mode.name)
#			pass



func _process(_delta) -> void:
	if OS.get_environment("POKU_POLISH_TEST") == "1":
		return
	if start == false:
		for curr_player in get_players():
			if curr_player.controllable == true:
				curr_player.stop()
	pass




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
	var obscurer = transition.instantiate()
	scene_manager.add_child(obscurer)
	await obscurer.switch
	
	var next_map = load("res://Maps/" + next_map_name + "/" + next_map_name + "_Map.tscn").instantiate()
	if current_map:
		current_map.queue_free()
	current_map = next_map

	if _map_uses_poku_players(next_map):
		move_players()
	else:
		park_players()
		
		
	scene_manager.add_child(next_map)


func change_to_game_select() -> void:
	_requested_main_menu_page = "menu_2"
	change_map("Main_Menu")


func take_requested_main_menu_page() -> String:
	var requested := _requested_main_menu_page
	_requested_main_menu_page = ""
	return requested

	



func move_players() -> void:
	start = false
	players_moved_count = 0  # reset count every time we start to move players

	while spawned_players < player_count:
		spawned_players += 1
		living_players += 1
		make_player(spawned_players)


	for curr_player in get_players():
		curr_player.visible = true
		for part in curr_player.body:
			part.freeze = false
			part.set_collision_layer_value(2, false)
			part.set_collision_mask_value(1, false)
			part.set_collision_mask_value(10, false)
		
		
		
		curr_player.ragdoll(0)
		curr_player.win(false)
		var spawn_location = current_map.get_node("Spawns/P" + str(curr_player.get_index()+1) + "_Spawn")
		if spawn_location.scale.x == -1:
			curr_player.flip_orientation()
		
		curr_player.controllable = false
		var target_position = spawn_location.global_position
		
		var player_tween = scene_manager.create_tween()
		player_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		player_tween.tween_property(curr_player, "global_position", target_position, 1.0).from(curr_player.global_position)
		player_tween.finished.connect(player_move_done.bind(curr_player))


func park_players() -> void:
	start = false
	for curr_player in get_players():
		curr_player.win(false)
		curr_player.controllable = false
		curr_player.visible = false
		curr_player.stop()
		for part in curr_player.body:
			part.freeze = true


func _map_uses_poku_players(map: Node) -> bool:
	var configured_value = map.get("uses_poku_players")
	return true if configured_value == null else bool(configured_value)



func player_move_done(curr_player) -> void:
	print("Finished Moving:  ", curr_player)
#	for curr_player in scene_manager.get_node("Players").get_children():
	curr_player.controllable = true

#	Enable this to make players freeze in place for a second before dropping:
#	curr_player.stop()

	for part in curr_player.body:
		if !("Body" in part.name):
				part.set_collision_layer_value(2, true)
				part.set_collision_mask_value(1, true)
				part.set_collision_mask_value(10, true)
		
	players_moved_count += 1
	if players_moved_count == player_count:
		start = true
		emit_signal("players_moved")
		print("all_moved")

func make_player(player_number: int) -> void:
	var new_player = load("res://Player/Player.tscn").instantiate()
	
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
		var survivor = null
		for curr_player in get_players():
			if !curr_player.dead:
				survivor = curr_player
				break
		if current_map and current_map.has_method("on_last_player_standing"):
			current_map.on_last_player_standing(survivor)
			return
		if survivor:
			print(survivor.name, " WINS!")
			survivor.win(true)
			await get_tree().create_timer(5.0).timeout
			random_map()

func get_players():
	var test = scene_manager.get_node("Players").get_children()
	return scene_manager.get_node("Players").get_children()
