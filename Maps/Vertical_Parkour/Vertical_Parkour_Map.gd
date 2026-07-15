extends "res://Maps/ModeController.gd"

var starting_camera_y := 0.0


func _init() -> void:
	mode_title = "VERTICAL PARKOUR"
	objective = "Climb the generated platforms and stay above the rising camera. Last Poku standing wins."


func _ready() -> void:
	super._ready()
	starting_camera_y = $Camera2D.position.y


func _process(delta: float) -> void:
	super._process(delta)
	var height := maxi(0, int(starting_camera_y - $Camera2D.position.y))
	set_status("HEIGHT  %dm    CAMERA  %d px/s" % [height, int($Platform_Generator.cam_speed)])
