extends Control

var menu_origin_position := Vector2.ZERO
var menu_origin_size := Vector2.ZERO

var menu_transition_time := 0.5
var menu_max_travel := 30

var center_of_screen := Vector2.ZERO

var current_menu
var menu_stack := []

onready var menu_1 = $Main
onready var menu_2 = $Map_Select
onready var tween = $Tween

func _ready():
	var rect = get_viewport_rect()
	center_of_screen = rect_position + (rect.size/2)
	
	menu_origin_position = Vector2(0,0)
	menu_origin_size = rect.size
	current_menu = menu_1
	
func _process(delta):
	var dist_to_mouse = ((get_global_mouse_position() - center_of_screen) * -41).clamped(menu_max_travel)
	rect_global_position = lerp(rect_global_position, dist_to_mouse, delta*2)
	
func move_to_next_menu(next_menu_id: String):
	var next_menu = get_menu_from_menu_id(next_menu_id)
#	current_menu.rect_global_position = Vector2(-menu_origin_size.x, 0)
#	next_menu.rect_global_position = menu_origin_position
	tween.interpolate_property(current_menu, "rect_global_position", current_menu.rect_global_position, Vector2(-menu_origin_size.x, 0), menu_transition_time)
	tween.interpolate_property(next_menu, "rect_global_position", next_menu.rect_global_position, menu_origin_position, menu_transition_time)
	tween.start()
	menu_stack.append(current_menu)
	current_menu = next_menu

func move_to_previous_menu():
	var previous_menu = menu_stack.pop_back()
	if previous_menu != null:
#		previous_menu.rect_global_position = menu_origin_position
#		current_menu.rect_global_position = Vector2(menu_origin_size.x, 0)
		tween.interpolate_property(previous_menu, "rect_global_position", previous_menu.rect_global_position, menu_origin_position, menu_transition_time)
		tween.interpolate_property(current_menu, "rect_global_position", current_menu.rect_global_position, Vector2(menu_origin_size.x, 0), menu_transition_time)
		tween.start()
		
		current_menu = previous_menu

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
