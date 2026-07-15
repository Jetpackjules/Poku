extends Node2D

var failures: Array[String] = []
var observations := {}


func _ready() -> void:
	await get_tree().process_frame
	_test_mapping_contract()
	await _test_device_isolation()
	await _test_keyboard_spin_reaches_player()
	await _test_menu_navigation()
	_release_everything()
	print("POLISH_JSON:", JSON.stringify({
		"suite": "controller_input",
		"passed": failures.is_empty(),
		"failures": failures,
		"observations": observations
	}))
	get_tree().quit(0 if failures.is_empty() else 1)


func _test_mapping_contract() -> void:
	_expect(_has_button(&"wasd_up", 0, JOY_BUTTON_A), "Controller 1 A is not mapped to P1 jump")
	_expect(_has_button(&"arrow_up", 1, JOY_BUTTON_A), "Controller 2 A is not mapped to P2 jump")
	_expect(_has_axis(&"wasd_right", 0, JOY_AXIS_LEFT_X, 1.0), "Controller 1 left stick is not mapped to P1 movement")
	_expect(_has_axis(&"arrow_left", 1, JOY_AXIS_LEFT_X, -1.0), "Controller 2 left stick is not mapped to P2 movement")
	_expect(_has_axis(&"wasd_spin", 0, JOY_AXIS_TRIGGER_RIGHT, 1.0), "Controller 1 right trigger is not mapped to P1 spin/throw")
	_expect(_has_axis(&"arrow_spin", 1, JOY_AXIS_TRIGGER_RIGHT, 1.0), "Controller 2 right trigger is not mapped to P2 spin/throw")
	_expect(_has_key(&"arrow_spin", KEY_SHIFT), "Shift is not mapped to P2 spin/throw")
	_expect(_has_button(&"ui_accept", -1, JOY_BUTTON_A), "A on either controller is not mapped to menu confirm")
	_expect(_has_button(&"ui_cancel", -1, JOY_BUTTON_B), "B on either controller is not mapped to menu back")
	_expect(_has_button(&"escape", -1, JOY_BUTTON_START), "Start on either controller is not mapped to exit a mode")
	var p1_keyboard_events := 0
	for event in InputMap.action_get_events(&"wasd_left"):
		if event is InputEventKey:
			p1_keyboard_events += 1
	_expect(p1_keyboard_events > 0, "Adding controllers removed P1's keyboard controls")


func _test_device_isolation() -> void:
	_send_axis(0, JOY_AXIS_LEFT_X, 1.0)
	await get_tree().process_frame
	observations["p1_right_strength"] = Input.get_action_strength(&"wasd_right")
	_expect(Input.get_action_strength(&"wasd_right") > 0.9, "Controller 1 right stick motion did not drive P1")
	_expect(Input.get_action_strength(&"arrow_right") < 0.01, "Controller 1 incorrectly drove P2")
	_send_axis(0, JOY_AXIS_LEFT_X, 0.0)

	_send_axis(1, JOY_AXIS_LEFT_X, -1.0)
	await get_tree().process_frame
	observations["p2_left_strength"] = Input.get_action_strength(&"arrow_left")
	_expect(Input.get_action_strength(&"arrow_left") > 0.9, "Controller 2 left stick motion did not drive P2")
	_expect(Input.get_action_strength(&"wasd_left") < 0.01, "Controller 2 incorrectly drove P1")
	_send_axis(1, JOY_AXIS_LEFT_X, 0.0)

	_send_button(0, JOY_BUTTON_A, true)
	await get_tree().process_frame
	_expect(Input.is_action_pressed(&"wasd_up"), "Controller 1 A did not press P1 jump")
	_expect(not Input.is_action_pressed(&"arrow_up"), "Controller 1 A incorrectly pressed P2 jump")
	_send_button(0, JOY_BUTTON_A, false)

	_send_axis(1, JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await get_tree().process_frame
	observations["p2_trigger_strength"] = Input.get_action_strength(&"arrow_spin")
	_expect(Input.get_action_strength(&"arrow_spin") > 0.9, "Controller 2 right trigger did not press P2 spin/throw")
	_expect(Input.get_action_strength(&"wasd_spin") < 0.01, "Controller 2 trigger incorrectly pressed P1 spin/throw")
	_send_axis(1, JOY_AXIS_TRIGGER_RIGHT, 0.0)

	var shift_event := _send_key(KEY_SHIFT, true)
	_expect(shift_event.is_action_pressed(&"arrow_spin"), "A Shift event does not identify itself as P2 spin/throw")
	await get_tree().process_frame
	observations["p2_shift_strength"] = Input.get_action_strength(&"arrow_spin")
	_expect(Input.get_action_strength(&"arrow_spin") > 0.9, "Pressing Shift did not activate P2 spin/throw")
	_expect(Input.get_action_strength(&"wasd_spin") < 0.01, "P2 Shift incorrectly activated P1 spin/throw")
	_send_key(KEY_SHIFT, false)


func _test_menu_navigation() -> void:
	var menu = (load("res://Maps/Main_Menu/Main_Menu_Map.tscn") as PackedScene).instantiate()
	$MenuSlot.add_child(menu)
	await get_tree().process_frame
	await get_tree().process_frame
	var menu_root = menu.get_node("MenuRoot")
	var focus_owner := get_viewport().gui_get_focus_owner()
	_expect(is_instance_valid(focus_owner) and focus_owner.name == "Start", "The main menu did not focus Start for controller navigation")
	menu_root.move_to_next_menu("menu_2")
	await get_tree().process_frame
	await get_tree().process_frame
	focus_owner = get_viewport().gui_get_focus_owner()
	_expect(is_instance_valid(focus_owner) and focus_owner.name == "Basketball", "The game grid did not focus its first playable mode")
	_send_button(0, JOY_BUTTON_B, true)
	await get_tree().process_frame
	_send_button(0, JOY_BUTTON_B, false)
	await get_tree().process_frame
	_expect(menu_root.current_menu == menu_root.menu_1, "Controller B did not return from game select")
	focus_owner = get_viewport().gui_get_focus_owner()
	_expect(is_instance_valid(focus_owner) and focus_owner.name == "Start", "Focus did not return to the main menu after controller back")
	var placeholder = menu.get_node("MenuRoot/Map_Select/CenterContainer/VBoxContainer/GridContainer/Back5")
	_expect(placeholder.focus_mode == Control.FOCUS_NONE, "A placeholder tile can still trap controller focus")
	menu.queue_free()
	await get_tree().process_frame


func _test_keyboard_spin_reaches_player() -> void:
	var p2 = (load("res://Player/Player.tscn") as PackedScene).instantiate()
	$Players.add_child(p2)
	await get_tree().physics_frame
	_expect(p2.spin == "arrow_spin", "The default P2 body is not listening to the P2 spin action")
	observations["p2_process_input"] = p2.is_processing_input()
	_expect(p2.is_processing_input(), "The P2 body is not receiving _input callbacks")
	_send_key(KEY_SHIFT, true)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(not p2.locked, "Shift reached the InputMap but did not unlock P2's spinning arm")
	_send_key(KEY_SHIFT, false)
	await get_tree().process_frame
	_expect(p2.locked, "Releasing Shift did not finish P2's spin/throw action")
	p2.queue_free()
	await get_tree().process_frame


func _has_button(action: StringName, device: int, button: JoyButton) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.device == device and event.button_index == button:
			return true
	return false


func _has_axis(action: StringName, device: int, axis: JoyAxis, direction: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.device == device and event.axis == axis and is_equal_approx(event.axis_value, direction):
			return true
	return false


func _has_key(action: StringName, physical_key: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == physical_key:
			return true
	return false


func _send_button(device: int, button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	event.pressed = pressed
	event.pressure = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _send_axis(device: int, axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


func _send_key(physical_key: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical_key
	event.pressed = pressed
	Input.parse_input_event(event)
	return event


func _release_everything() -> void:
	_send_key(KEY_SHIFT, false)
	for device in [0, 1]:
		_send_axis(device, JOY_AXIS_LEFT_X, 0.0)
		_send_axis(device, JOY_AXIS_LEFT_Y, 0.0)
		_send_axis(device, JOY_AXIS_TRIGGER_RIGHT, 0.0)
		for button in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_RIGHT_SHOULDER]:
			_send_button(device, button, false)


func _expect(condition: bool, message: String) -> void:
	if not condition and message not in failures:
		failures.append(message)
