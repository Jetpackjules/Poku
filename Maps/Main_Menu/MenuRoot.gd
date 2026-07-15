extends Control

const CONTROLLER_INDICATOR = preload("res://Maps/Main_Menu/ControllerIndicator.gd")

var menu_origin_position := Vector2.ZERO
var menu_origin_size := Vector2.ZERO

var menu_transition_time := 0.5
var menu_max_travel := 30

var center_of_screen := Vector2.ZERO

var current_menu
var menu_stack := []
var focus_tweens := {}
var polish_decorations: Array[CanvasItem] = []
var controller_indicator_grid: GridContainer

@onready var menu_1 = $Main
@onready var menu_2 = $Map_Select
var menu_tween: Tween

func _ready():
	var rect = get_viewport_rect()
	center_of_screen = position + (rect.size/2)
	
	menu_origin_position = Vector2(0,0)
	menu_origin_size = rect.size
	current_menu = menu_1
	_build_controller_indicators()
	if not ControllerSupport.controllers_changed.is_connected(_on_controllers_changed):
		ControllerSupport.controllers_changed.connect(_on_controllers_changed)
	_refresh_controller_indicators(ControllerSupport.connected_controller_count())
	_build_polish_decorations()
	_apply_focus_style(self)
	if not GameSettings.preference_changed.is_connected(_on_preference_changed):
		GameSettings.preference_changed.connect(_on_preference_changed)
	_apply_poku_polish()
	var requested_page := SceneSwitcher.take_requested_main_menu_page()
	if requested_page == "menu_2":
		call_deferred("move_to_next_menu", requested_page)
	else:
		call_deferred("_focus_current_menu")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and current_menu == menu_2:
		get_viewport().set_input_as_handled()
		move_to_previous_menu()
	
func _process(delta):
	var dist_to_mouse = ((get_global_mouse_position() - center_of_screen) * -41).limit_length(menu_max_travel)
	global_position = lerp(global_position, dist_to_mouse, delta*2)
	
func move_to_next_menu(next_menu_id: String):
	var next_menu = get_menu_from_menu_id(next_menu_id)
#	current_menu.rect_global_position = Vector2(-menu_origin_size.x, 0)
#	next_menu.rect_global_position = menu_origin_position
	if menu_tween and menu_tween.is_valid():
		menu_tween.kill()
	menu_tween = create_tween().set_parallel(true)
	menu_tween.tween_property(current_menu, "global_position", Vector2(-menu_origin_size.x, 0), menu_transition_time)
	menu_tween.tween_property(next_menu, "global_position", menu_origin_position, menu_transition_time)
	menu_stack.append(current_menu)
	current_menu = next_menu
	call_deferred("_focus_current_menu")

func move_to_previous_menu():
	var previous_menu = menu_stack.pop_back()
	if previous_menu != null:
#		previous_menu.rect_global_position = menu_origin_position
#		current_menu.rect_global_position = Vector2(menu_origin_size.x, 0)
		if menu_tween and menu_tween.is_valid():
			menu_tween.kill()
		menu_tween = create_tween().set_parallel(true)
		menu_tween.tween_property(previous_menu, "global_position", menu_origin_position, menu_transition_time)
		menu_tween.tween_property(current_menu, "global_position", Vector2(menu_origin_size.x, 0), menu_transition_time)
		
		current_menu = previous_menu
		call_deferred("_focus_current_menu")

func get_menu_from_menu_id(menu_id: String) -> Control:
	match menu_id:
		"menu_1":
			return menu_1
		"menu_2":
			return menu_2
		_:
			return menu_1


func _on_Games_pressed():
	move_to_next_menu("menu_2")
	pass # Replace with function body.


func _on_Back_Button_pressed():
	move_to_previous_menu()
	pass # Replace with function body.


func _on_Start_pressed():
	SceneSwitcher.random_map()


func _on_Options_pressed() -> void:
	PauseMenu.open_options()


func _focus_current_menu() -> void:
	if current_menu == menu_1:
		$Main/CenterContainer/VBoxContainer/Start.grab_focus()
	elif current_menu == menu_2:
		menu_2.focus_first_level()


func _apply_focus_style(node: Node) -> void:
	if node is BaseButton:
		node.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		if node is Button:
			var original_color: Color = node.get_theme_color("font_color")
			node.add_theme_color_override("font_focus_color", original_color)
			node.add_theme_color_override("font_pressed_color", original_color.lightened(0.12))
			node.add_theme_color_override("font_hover_pressed_color", original_color.lightened(0.18))
		node.focus_entered.connect(_on_button_focus_entered.bind(node))
		node.focus_exited.connect(_on_button_focus_exited.bind(node))
	for child in node.get_children():
		_apply_focus_style(child)


func _build_controller_indicators() -> void:
	controller_indicator_grid = GridContainer.new()
	controller_indicator_grid.name = "ControllerIndicators"
	controller_indicator_grid.columns = 2
	controller_indicator_grid.z_index = 40
	controller_indicator_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controller_indicator_grid.anchor_top = 1.0
	controller_indicator_grid.anchor_bottom = 1.0
	controller_indicator_grid.offset_left = 30.0
	controller_indicator_grid.offset_top = -190.0
	controller_indicator_grid.offset_right = 252.0
	controller_indicator_grid.offset_bottom = -24.0
	controller_indicator_grid.add_theme_constant_override("h_separation", 14)
	controller_indicator_grid.add_theme_constant_override("v_separation", 4)
	add_child(controller_indicator_grid)


func _refresh_controller_indicators(connected_count: int) -> void:
	if not is_instance_valid(controller_indicator_grid):
		return
	for child in controller_indicator_grid.get_children():
		child.queue_free()

	var device_ids := Input.get_connected_joypads()
	for index in range(connected_count):
		var device_id: int = device_ids[index] if index < device_ids.size() else index
		var slot := device_id + 1 if device_id in [0, 1] else index + 1
		var icon := CONTROLLER_INDICATOR.new()
		var device_name := Input.get_joy_name(device_id) if device_id in device_ids else ""
		icon.configure(slot, device_id, device_name)
		controller_indicator_grid.add_child(icon)
		icon.scale = Vector2(0.72, 0.72)
		icon.pivot_offset = icon.custom_minimum_size * 0.5
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(icon, "scale", Vector2.ONE, 0.18 + index * 0.03)
	controller_indicator_grid.visible = connected_count > 0


func _on_controllers_changed(connected_count: int) -> void:
	_refresh_controller_indicators(connected_count)


func _on_button_focus_entered(button: BaseButton) -> void:
	button.pivot_offset = button.size * 0.5
	if button is Button:
		button.add_theme_color_override("font_shadow_color", Color(0.08, 0.18, 0.20, 0.42))
		button.add_theme_constant_override("shadow_offset_x", 5)
		button.add_theme_constant_override("shadow_offset_y", 6)
	if focus_tweens.has(button) and focus_tweens[button].is_valid():
		focus_tweens[button].kill()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.045, 1.045), 0.16)
	tween.tween_property(button, "rotation", deg_to_rad(-1.2), 0.08)
	tween.chain().tween_property(button, "rotation", deg_to_rad(0.65), 0.07)
	tween.chain().tween_property(button, "rotation", 0.0, 0.07)
	focus_tweens[button] = tween


func _on_button_focus_exited(button: BaseButton) -> void:
	if button is Button:
		button.remove_theme_color_override("font_shadow_color")
		button.remove_theme_constant_override("shadow_offset_x")
		button.remove_theme_constant_override("shadow_offset_y")
	if focus_tweens.has(button) and focus_tweens[button].is_valid():
		focus_tweens[button].kill()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, 0.12)
	tween.tween_property(button, "rotation", 0.0, 0.12)
	focus_tweens[button] = tween


func _build_polish_decorations() -> void:
	var grid := $Map_Select/CenterContainer/VBoxContainer/GridContainer
	for button in grid.get_children():
		if not button is BaseButton or (button.name.begins_with("Back") and button.name != "Back"):
			continue
		if button is TextureButton:
			var caption := Label.new()
			caption.name = "PolishCaption"
			caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
			caption.anchor_top = 1.0
			caption.anchor_right = 1.0
			caption.anchor_bottom = 1.0
			caption.offset_top = -52.0
			caption.text = "BACK" if button.name == "Back" else button.name.replace("_", " ").to_upper()
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			caption.add_theme_font_override("font", preload("res://fonts/Menu_Fonts/Option_font.tres"))
			caption.add_theme_font_size_override("font_size", 26)
			caption.add_theme_color_override("font_color", Color(1.0, 0.97, 0.91))
			caption.add_theme_color_override("font_shadow_color", Color(0.03, 0.14, 0.16, 0.92))
			caption.add_theme_constant_override("shadow_offset_x", 3)
			caption.add_theme_constant_override("shadow_offset_y", 4)
			caption.add_theme_constant_override("outline_size", 5)
			caption.add_theme_color_override("font_outline_color", Color(0.03, 0.14, 0.16, 0.62))
			button.add_child(caption)
			polish_decorations.append(caption)


func _on_preference_changed(preference: StringName, _value: Variant) -> void:
	if preference == &"poku_polish":
		_apply_poku_polish()


func _apply_poku_polish() -> void:
	var polished := GameSettings.is_poku_polish_enabled()
	for decoration in polish_decorations:
		decoration.visible = polished
	var games_heading: Label = $Map_Select/CenterContainer/VBoxContainer/Label
	if polished:
		games_heading.add_theme_color_override("font_color", Color(0.64, 0.34, 0.94))
		games_heading.add_theme_color_override("font_shadow_color", Color(0.15, 0.42, 0.44, 0.35))
		games_heading.add_theme_constant_override("shadow_offset_x", 6)
		games_heading.add_theme_constant_override("shadow_offset_y", 7)
	else:
		games_heading.remove_theme_color_override("font_color")
		games_heading.remove_theme_color_override("font_shadow_color")
		games_heading.remove_theme_constant_override("shadow_offset_x")
		games_heading.remove_theme_constant_override("shadow_offset_y")
