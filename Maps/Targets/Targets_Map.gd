extends "res://Maps/ModeController.gd"


func _init() -> void:
	mode_title = "TARGETS"
	objective = "Grab a spear or shuriken and impale the flying targets on your side. First to 3 hits."


func _ready() -> void:
	super._ready()
	set_status("FIRST TO 3")
