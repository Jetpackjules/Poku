extends Node2D

var scenario := "idle"
var tick := 0
@onready var player = $Players/Body
@onready var chain := [
	player,
	player.get_node("Spine6"),
	player.get_node("Spine6/Spine5"),
	player.get_node("Spine6/Spine5/Spine4"),
	player.get_node("Spine6/Spine5/Spine4/Spine3"),
	player.get_node("Spine6/Spine5/Spine4/Spine3/Spine2"),
	player.get_node("Spine6/Spine5/Spine4/Spine3/Spine2/Spine1")
]
@onready var legs := [
	player.get_node("Leg_L_up"),
	player.get_node("Leg_L_down"),
	player.get_node("Leg_R_up"),
	player.get_node("Leg_R_down")
]

func _ready() -> void:
	scenario = OS.get_environment("POKU_PARITY_SCENARIO")
	if scenario.is_empty():
		scenario = "idle"
	player.jump = "arrow_up"
	player.crouch = "arrow_down"
	player.move_right = "arrow_right"
	player.move_left = "arrow_left"
	player.spin = "arrow_spin"
	print_json({"kind":"meta", "scenario":scenario, "fps":Engine.physics_ticks_per_second})

func set_action(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)
	Input.parse_input_event(event)

func body_state(body: RigidBody2D) -> Dictionary:
	var state := PhysicsServer2D.body_get_direct_state(body.get_rid())
	return {
		"x":body.global_position.x, "y":body.global_position.y,
		"vx":body.linear_velocity.x, "vy":body.linear_velocity.y,
		"r":body.global_rotation, "av":body.angular_velocity,
		"inverse_mass":state.inverse_mass, "inverse_inertia":state.inverse_inertia,
		"center_of_mass_local_x":state.center_of_mass_local.x,
		"center_of_mass_local_y":state.center_of_mass_local.y
	}

func emit_trace() -> void:
	var parts := []
	for part in chain + legs:
		parts.append(body_state(part))
	print_json({
		"kind":"player_trace", "scenario":scenario, "tick":tick,
		"parts":parts,
		"float_height":player.float_height,
		"auto_balance_timeout":player.auto_balance_timeout,
		"left_hinge":legs[0].global_position.distance_to(legs[1].global_position),
		"right_hinge":legs[2].global_position.distance_to(legs[3].global_position),
		"ray_colliding":player.get_node("RayCast2D").is_colliding()
	})

func print_json(value: Dictionary) -> void:
	print("PARITY_JSON:", JSON.stringify(value))

func _physics_process(_delta: float) -> void:
	tick += 1
	if tick == 180 and scenario in ["run", "run_jump", "run_jump_long"]:
		set_action(&"arrow_right", true)
	if tick == 240:
		if scenario in ["jump", "jump_long", "run_jump", "run_jump_long"]:
			set_action(&"arrow_up", true)
		elif scenario == "crouch":
			set_action(&"arrow_down", true)
		elif scenario == "spin":
			set_action(&"arrow_spin", true)
	if tick == 270 and scenario in ["jump", "run_jump"]:
		set_action(&"arrow_up", false)
	if tick == 300 and scenario == "crouch":
		set_action(&"arrow_down", false)
	if tick == 360:
		if scenario in ["jump_long", "run_jump_long"]:
			set_action(&"arrow_up", false)
		if scenario == "spin":
			set_action(&"arrow_spin", false)
		if scenario in ["run", "run_jump", "run_jump_long"]:
			set_action(&"arrow_right", false)
	if tick >= 160 and tick <= 600 and tick % 5 == 0:
		emit_trace()
	if tick >= 600:
		for action in [&"arrow_up", &"arrow_down", &"arrow_left", &"arrow_right", &"arrow_spin"]:
			Input.action_release(action)
		get_tree().quit()
