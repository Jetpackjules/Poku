extends MarginContainer


var level_buttons := []

# Called when the node enters the scene tree for the first time.
func _ready():
	for button in $CenterContainer/VBoxContainer/GridContainer.get_children():
		if button.name.begins_with("Back") and button.name != "Back":
			button.focus_mode = Control.FOCUS_NONE
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		elif button.name != "Back":
			level_buttons.append(button)
			button.connect("pressed", Callable(self, "load_map").bind(button))


func focus_first_level() -> void:
	if not level_buttons.is_empty():
		level_buttons[0].grab_focus()
	
func load_map(map_button):
	SceneSwitcher.change_map(map_button.name)
