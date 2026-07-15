extends Node

signal controllers_changed(connected_count: int)

const PLAYER_ONE_DEVICE := 0
const PLAYER_TWO_DEVICE := 1

var last_rumble_request := {}


func _enter_tree() -> void:
	configure_input_map()


func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func configure_input_map() -> void:
	# Keyboard menu navigation was absent from the converted project too.
	_add_key(&"ui_up", KEY_UP)
	_add_key(&"ui_up", KEY_W)
	_add_key(&"ui_down", KEY_DOWN)
	_add_key(&"ui_down", KEY_S)
	_add_key(&"ui_left", KEY_LEFT)
	_add_key(&"ui_left", KEY_A)
	_add_key(&"ui_right", KEY_RIGHT)
	_add_key(&"ui_right", KEY_D)
	_add_key(&"ui_accept", KEY_ENTER)
	_add_key(&"ui_accept", KEY_SPACE)
	_add_key(&"ui_cancel", KEY_ESCAPE)
	# The 2023 project used Control for P2 spin. Keep that legacy input, while
	# making the displayed and more comfortable Shift binding real.
	_add_key(&"arrow_spin", KEY_SHIFT)
	_add_key(&"arrow_spin", KEY_CTRL)

	_configure_player("wasd", PLAYER_ONE_DEVICE)
	_configure_player("arrow", PLAYER_TWO_DEVICE)
	_configure_menu_controllers()


func _configure_player(prefix: String, device: int) -> void:
	var left := StringName("%s_left" % prefix)
	var right := StringName("%s_right" % prefix)
	var up := StringName("%s_up" % prefix)
	var down := StringName("%s_down" % prefix)
	var spin := StringName("%s_spin" % prefix)

	for action in [left, right, up, down, spin]:
		_ensure_action(action, 0.22)
	_add_axis(left, device, JOY_AXIS_LEFT_X, -1.0)
	_add_axis(right, device, JOY_AXIS_LEFT_X, 1.0)
	_add_button(left, device, JOY_BUTTON_DPAD_LEFT)
	_add_button(right, device, JOY_BUTTON_DPAD_RIGHT)
	_add_button(up, device, JOY_BUTTON_A)
	_add_button(up, device, JOY_BUTTON_DPAD_UP)
	_add_button(down, device, JOY_BUTTON_B)
	_add_button(down, device, JOY_BUTTON_DPAD_DOWN)
	# Spin is the grab/charge/throw action. Trigger is primary, with X and the
	# right shoulder as comfortable digital fallbacks across controller types.
	_add_axis(spin, device, JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_add_button(spin, device, JOY_BUTTON_X)
	_add_button(spin, device, JOY_BUTTON_RIGHT_SHOULDER)


func _configure_menu_controllers() -> void:
	for device in [-1]:
		_add_axis(&"ui_left", device, JOY_AXIS_LEFT_X, -1.0)
		_add_axis(&"ui_right", device, JOY_AXIS_LEFT_X, 1.0)
		_add_axis(&"ui_up", device, JOY_AXIS_LEFT_Y, -1.0)
		_add_axis(&"ui_down", device, JOY_AXIS_LEFT_Y, 1.0)
		_add_button(&"ui_left", device, JOY_BUTTON_DPAD_LEFT)
		_add_button(&"ui_right", device, JOY_BUTTON_DPAD_RIGHT)
		_add_button(&"ui_up", device, JOY_BUTTON_DPAD_UP)
		_add_button(&"ui_down", device, JOY_BUTTON_DPAD_DOWN)
		_add_button(&"ui_accept", device, JOY_BUTTON_A)
		_add_button(&"ui_cancel", device, JOY_BUTTON_B)
		# Start exits a running mode. B remains crouch in gameplay and therefore
		# deliberately does not map to the global escape action.
		_add_button(&"escape", device, JOY_BUTTON_START)


func connected_controller_count() -> int:
	return Input.get_connected_joypads().size()


func status_text() -> String:
	var count := connected_controller_count()
	if count <= 0:
		return "KEYBOARD: P1 WASD + SPACE    P2 ARROWS + RIGHT SHIFT"
	if count == 1:
		return "CONTROLLER 1 READY    P2 CAN USE ARROW KEYS"
	return "CONTROLLERS 1 + 2 READY"


func rumble_for_action(action: StringName, weak: float, strong: float, duration: float) -> void:
	if not GameSettings.is_rumble_enabled():
		return
	var device := PLAYER_ONE_DEVICE if String(action).begins_with("wasd") else PLAYER_TWO_DEVICE
	last_rumble_request = {
		"device": device,
		"weak": clampf(weak, 0.0, 1.0),
		"strong": clampf(strong, 0.0, 1.0),
		"duration": maxf(0.0, duration)
	}
	if device in Input.get_connected_joypads():
		Input.start_joy_vibration(
			device,
			last_rumble_request["weak"],
			last_rumble_request["strong"],
			last_rumble_request["duration"]
		)


func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	controllers_changed.emit(connected_controller_count())


func _ensure_action(action: StringName, deadzone := 0.22) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, deadzone)
	else:
		InputMap.action_set_deadzone(action, deadzone)


func _add_button(action: StringName, device: int, button: JoyButton) -> void:
	_ensure_action(action)
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)


func _add_axis(action: StringName, device: int, axis: JoyAxis, direction: float) -> void:
	_ensure_action(action)
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = axis
	event.axis_value = direction
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)


func _add_key(action: StringName, physical_key: Key) -> void:
	_ensure_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = physical_key
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
