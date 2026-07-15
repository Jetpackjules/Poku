extends "res://Maps/ModeController.gd"


func _init() -> void:
	mode_title = "PHYSICS LAB"
	objective = "A no-score sandbox for testing movement, power-ups, ragdolls, throwing, and embedding."


func _ready() -> void:
	super._ready()
	set_status("SANDBOX — ESC TO EXIT")
