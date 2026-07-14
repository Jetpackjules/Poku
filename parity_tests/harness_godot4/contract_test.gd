extends Node2D

const ACTIONS := [&"wasd_up", &"wasd_down", &"wasd_left", &"wasd_right", &"wasd_spin", &"arrow_up", &"arrow_down", &"arrow_left", &"arrow_right", &"arrow_spin", &"escape", &"random_map"]

func _ready() -> void:
	var gravity_vector: Vector2 = ProjectSettings.get_setting("physics/2d/default_gravity_vector")
	var space := get_world_2d().space
	print("PARITY_JSON:", JSON.stringify({
		"kind":"contract", "name":"physics",
		"physics_ticks":Engine.physics_ticks_per_second,
		"interpolation":ProjectSettings.get_setting("physics/common/physics_interpolation"),
		"gravity":ProjectSettings.get_setting("physics/2d/default_gravity"),
		"gravity_x":gravity_vector.normalized().x, "gravity_y":gravity_vector.normalized().y,
		"linear_damp":ProjectSettings.get_setting("physics/2d/default_linear_damp"),
		"angular_damp":ProjectSettings.get_setting("physics/2d/default_angular_damp"),
		"sleep_linear":PhysicsServer2D.space_get_param(space, PhysicsServer2D.SPACE_PARAM_BODY_LINEAR_VELOCITY_SLEEP_THRESHOLD),
		"sleep_angular":PhysicsServer2D.space_get_param(space, PhysicsServer2D.SPACE_PARAM_BODY_ANGULAR_VELOCITY_SLEEP_THRESHOLD),
		"sleep_time":PhysicsServer2D.space_get_param(space, PhysicsServer2D.SPACE_PARAM_BODY_TIME_TO_SLEEP),
		"constraint_bias":PhysicsServer2D.space_get_param(space, PhysicsServer2D.SPACE_PARAM_CONSTRAINT_DEFAULT_BIAS),
		"contact_bias":PhysicsServer2D.space_get_param(space, PhysicsServer2D.SPACE_PARAM_CONTACT_DEFAULT_BIAS),
		"solver_iterations":PhysicsServer2D.space_get_param(space, PhysicsServer2D.SPACE_PARAM_SOLVER_ITERATIONS)
	}))
	for action in ACTIONS:
		var codes := []
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				codes.append(event.physical_keycode)
		codes.sort()
		print("PARITY_JSON:", JSON.stringify({
			"kind":"input", "name":String(action),
			"deadzone":InputMap.action_get_deadzone(action), "physical_keycodes":codes
		}))
	get_tree().quit()
