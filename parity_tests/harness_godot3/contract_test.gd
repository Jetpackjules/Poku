extends Node2D

const ACTIONS = ["wasd_up", "wasd_down", "wasd_left", "wasd_right", "wasd_spin", "arrow_up", "arrow_down", "arrow_left", "arrow_right", "arrow_spin", "escape", "random_map"]

func _ready():
	var gravity_vector = ProjectSettings.get_setting("physics/2d/default_gravity_vector")
	var space = get_world_2d().space
	print("PARITY_JSON:", JSON.print({
		"kind":"contract", "name":"physics",
		"physics_ticks":Engine.iterations_per_second,
		"interpolation":ProjectSettings.get_setting("physics/common/physics_interpolation"),
		"gravity":ProjectSettings.get_setting("physics/2d/default_gravity"),
		"gravity_x":gravity_vector.normalized().x, "gravity_y":gravity_vector.normalized().y,
		"linear_damp":ProjectSettings.get_setting("physics/2d/default_linear_damp"),
		"angular_damp":ProjectSettings.get_setting("physics/2d/default_angular_damp"),
		"sleep_linear":Physics2DServer.space_get_param(space, Physics2DServer.SPACE_PARAM_BODY_LINEAR_VELOCITY_SLEEP_THRESHOLD),
		"sleep_angular":Physics2DServer.space_get_param(space, Physics2DServer.SPACE_PARAM_BODY_ANGULAR_VELOCITY_SLEEP_THRESHOLD),
		"sleep_time":Physics2DServer.space_get_param(space, Physics2DServer.SPACE_PARAM_BODY_TIME_TO_SLEEP),
		"constraint_bias":Physics2DServer.space_get_param(space, Physics2DServer.SPACE_PARAM_CONSTRAINT_DEFAULT_BIAS),
		"contact_bias":0.3, "solver_iterations":8
	}))
	for action in ACTIONS:
		var codes = []
		for event in InputMap.get_action_list(action):
			if event is InputEventKey:
				codes.append(event.physical_scancode)
		codes.sort()
		print("PARITY_JSON:", JSON.print({
			"kind":"input", "name":action,
			"deadzone":InputMap.action_get_deadzone(action), "physical_keycodes":codes
		}))
	get_tree().quit()
