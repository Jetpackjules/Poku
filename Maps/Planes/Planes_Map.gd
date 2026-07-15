extends "res://Maps/ModeController.gd"

@export var goal_y := -1125.0
@export var hold_to_win := 1.25

var left_hold := 0.0
var right_hold := 0.0
@onready var left_plane: RigidBody2D = $Turn_Brace2
@onready var right_plane: RigidBody2D = $Turn_Brace


func _init() -> void:
	mode_title = "UPDRAFT PLANES"
	objective = "Shift your weight to steer into the center updraft, then ride it to the gold altitude. First plane to hold there wins."


func _ready() -> void:
	super._ready()


func _physics_process(delta: float) -> void:
	if round_over:
		return
	left_hold = _updated_hold(left_plane, left_hold, delta)
	right_hold = _updated_hold(right_plane, right_hold, delta)
	set_status("P1 ALT %d  HOLD %.1f    |    P2 ALT %d  HOLD %.1f" % [
		maxi(0, int(-left_plane.global_position.y)), left_hold,
		maxi(0, int(-right_plane.global_position.y)), right_hold
	])
	if left_hold >= hold_to_win:
		finish_side(-1, "P1 RIDES THE UPDRAFT!")
	elif right_hold >= hold_to_win:
		finish_side(1, "P2 RIDES THE UPDRAFT!")


func _updated_hold(plane: RigidBody2D, current: float, delta: float) -> float:
	if plane.global_position.y <= goal_y:
		return minf(hold_to_win, current + delta)
	return maxf(0.0, current - delta)
