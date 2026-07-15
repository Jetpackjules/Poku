extends "res://Maps/ModeController.gd"


func _init() -> void:
	mode_title = "BASKETBALL"
	objective = "Stay on your side. Spin-throw a ball into the opposite hoop and hold it there for 2 seconds. First to 2."


func _ready() -> void:
	super._ready()
	set_status("P1   0 — 0   P2")


func score_changed(left_player_score: int, right_player_score: int) -> void:
	set_status("P1   %d — %d   P2" % [left_player_score, right_player_score])
	announce("BUCKET!", 0.65)
