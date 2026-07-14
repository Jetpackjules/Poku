extends Node2D

var tick = 0
var scenario = "Basketball"
var players = []

func _ready():
	scenario = OS.get_environment("POKU_PARITY_SCENARIO")
	if scenario == "":
		scenario = "Basketball"
	var map_path = "res://Maps/%s/%s_Map.tscn" % [scenario, scenario]
	var current_map = load(map_path).instance()
	add_child(current_map)
	SceneSwitcher.current_map = current_map
	if current_map.has_node("Spawns/P1_Spawn"):
		for index in range(2):
			var player = load("res://Player/Player.tscn").instance()
			$Players.add_child(player)
			player.global_position = current_map.get_node("Spawns/P%d_Spawn" % (index + 1)).global_position
			players.append(player)
		players[0].jump = "wasd_up"
		players[0].move_right = "wasd_right"
		players[0].move_left = "wasd_left"
		players[0].crouch = "wasd_down"
		players[0].spin = "wasd_spin"
		players[1].jump = "arrow_up"
		players[1].move_right = "arrow_right"
		players[1].move_left = "arrow_left"
		players[1].crouch = "arrow_down"
		players[1].spin = "arrow_spin"
	SceneSwitcher.living_players = players.size()

func set_action(action, pressed):
	var event = InputEventKey.new()
	if action == "wasd_up":
		event.physical_scancode = KEY_W
	else:
		event.physical_scancode = KEY_D
	event.pressed = pressed
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)
	Input.parse_input_event(event)

func collect_bodies(node, output):
	if node is RigidBody2D:
		output.append(node)
	for child in node.get_children():
		collect_bodies(child, output)

func finite_value(value):
	return not is_nan(value) and not is_inf(value)

func emit_result():
	var bodies = []
	collect_bodies(self, bodies)
	var finite = true
	for body in bodies:
		finite = finite and finite_value(body.global_position.x) and finite_value(body.global_position.y)
		finite = finite and finite_value(body.linear_velocity.x) and finite_value(body.linear_velocity.y)
		finite = finite and finite_value(body.global_rotation) and finite_value(body.angular_velocity)
	print("PARITY_JSON:", JSON.print({
		"kind":"map_smoke", "name":scenario,
		"finite":finite, "player_count":players.size(), "rigid_body_count":bodies.size()
	}))

func _physics_process(_delta):
	tick += 1
	if tick == 180 and not players.empty():
		set_action("wasd_right", true)
	if tick == 240 and not players.empty():
		set_action("wasd_right", false)
		set_action("wasd_up", true)
	if tick == 270 and not players.empty():
		set_action("wasd_up", false)
	if tick == 420:
		emit_result()
		for action in ["wasd_right", "wasd_up"]:
			Input.action_release(action)
		get_tree().quit()
