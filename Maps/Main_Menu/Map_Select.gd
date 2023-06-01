extends MarginContainer


var level_buttons := []

# Called when the node enters the scene tree for the first time.
func _ready():
	for button in $CenterContainer/VBoxContainer/GridContainer.get_children():
		if !("Back" in button.name):
			button.connect("pressed", self, "load_map",[button])
	pass # Replace with function body.
	
func load_map(map_button):
	SceneSwitcher.change_map(map_button.name)

