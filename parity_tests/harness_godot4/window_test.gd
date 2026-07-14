extends Node

var tick := 0

func _physics_process(_delta: float) -> void:
	tick += 1
	if tick == 10:
		var viewport_size := get_viewport().get_visible_rect().size
		# The headless display driver has no OS window and correctly reports 0x0.
		# Compare the authored run-window override instead; a visible manual run
		# separately confirmed this becomes the real 1024x576 macOS game window.
		var window_size := Vector2(
			ProjectSettings.get_setting("display/window/size/window_width_override"),
			ProjectSettings.get_setting("display/window/size/window_height_override")
		)
		print("PARITY_JSON:", JSON.stringify({
			"kind":"window", "name":"runtime",
			"viewport_width":viewport_size.x, "viewport_height":viewport_size.y,
			"window_width":window_size.x, "window_height":window_size.y
		}))
		get_tree().quit()
