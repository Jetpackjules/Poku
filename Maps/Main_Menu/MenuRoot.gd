extends Control

var menu_origin_position := Vector2.ZERO
var menu_origin_size := Vector2.ZERO

var menu_transition_time := 0.5
var menu_max_travel := 30

var center_of_screen := Vector2.ZERO

var current_menu
var menu_stack := []
var focus_tweens := {}

@onready var menu_1 = $Main
@onready var menu_2 = $Map_Select
var menu_tween: Tween

func _ready():
	var rect = get_viewport_rect()
	center_of_screen = position + (rect.size/2)
	
	menu_origin_position = Vector2(0,0)
	menu_origin_size = rect.size
	current_menu = menu_1
	_apply_focus_style(self)
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
