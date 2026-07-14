extends Node

var tick = 0

func _physics_process(_delta):
	tick += 1
	if tick == 10:
		var viewport_size = get_viewport().get_visible_rect().size
		var window_size = Vector2(
			ProjectSettings.get_setting("display/window/size/test_width"),
			ProjectSettings.get_setting("display/window/size/test_height")
		)
		print("PARITY_JSON:", JSON.print({
			"kind":"window", "name":"runtime",
			"viewport_width":viewport_size.x, "viewport_height":viewport_size.y,
			"window_width":window_size.x, "window_height":window_size.y
		}))
		get_tree().quit()
