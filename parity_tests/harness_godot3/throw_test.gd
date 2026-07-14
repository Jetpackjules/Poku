extends Node2D

var tick = 0
var item = null
var scenario = "spear_negative_120"
var release_tick = 360
var end_tick = 600
onready var player = $Players/Body

func _ready():
	scenario = OS.get_environment("POKU_PARITY_SCENARIO")
	if scenario == "" or scenario == "throw":
		scenario = "spear_negative_120"
	var fields = scenario.split("_")
	release_tick = 240 + int(fields[2])
	end_tick = max(600, release_tick + 240)
	player.run_dir = -1 if fields[1] == "positive" else 1
	player.spin = "arrow_spin"
	var space = get_world_2d().space
	print("PARITY_JSON:", JSON.print({
		"kind":"solver", "name":"settings",
		"constraint_bias":Physics2DServer.space_get_param(space, Physics2DServer.SPACE_PARAM_CONSTRAINT_DEFAULT_BIAS),
		"scenario":scenario, "release_tick":release_tick
	}))

func set_spin(pressed):
	var event = InputEventKey.new()
	event.physical_scancode = KEY_CONTROL
	event.pressed = pressed
	if pressed:
		Input.action_press("arrow_spin")
	else:
		Input.action_release("arrow_spin")
	Input.parse_input_event(event)

func spawn_item():
	var path = "res://Items/Shuriken.tscn" if scenario.begins_with("shuriken") else "res://Items/Spear.tscn"
	item = load(path).instance()
	item.global_position = Vector2(400, 180)
	item.linear_velocity = Vector2.ZERO
	add_child(item)

func emit_trace():
	var state = Physics2DServer.body_get_direct_state(item.get_rid())
	print("PARITY_JSON:", JSON.print({
		"kind":"throw_trace", "scenario":scenario, "tick":tick,
		"player_holding":player.holding_something,
		"item_held":item.held, "item_impaled":item.impaled,
		"item_available":item.available, "item_snap":item.snap,
		"item_cooldown":item.cooldown, "item_sleeping":item.sleeping,
		"contact_count":state.get_contact_count(),
		"hand_distance":item.global_position.distance_to(player.grabber.global_position),
		"arm_reach":player.grabber.global_position.distance_to(player.global_position),
		"x":item.global_position.x, "y":item.global_position.y,
		"vx":item.linear_velocity.x, "vy":item.linear_velocity.y,
		"r":item.global_rotation, "av":item.angular_velocity,
		"inverse_mass":state.inverse_mass, "inverse_inertia":state.inverse_inertia,
		"root_x":player.global_position.x, "root_y":player.global_position.y,
		"hand_x":player.grabber.global_position.x, "hand_y":player.grabber.global_position.y,
		"hand_vx":player.grabber.linear_velocity.x, "hand_vy":player.grabber.linear_velocity.y
	}))

func _physics_process(_delta):
	tick += 1
	if tick == 180:
		spawn_item()
	if tick == 220:
		var target_transform = Transform2D(item.global_rotation, player.grabber.global_position)
		Physics2DServer.body_set_state(item.get_rid(), Physics2DServer.BODY_STATE_TRANSFORM, target_transform)
		item.linear_velocity = Vector2.ZERO
		item.angular_velocity = 0
	if tick == 240:
		set_spin(true)
	if tick == release_tick:
		set_spin(false)
	if item and tick >= 200 and tick <= end_tick and tick % 5 == 0:
		emit_trace()
	if tick >= end_tick:
		Input.action_release("arrow_spin")
		get_tree().quit()
