extends "res://Maps/ModeController.gd"

@export var goal_y := -420.0
@export var hold_to_win := 2.5

var left_hold := 0.0
var right_hold := 0.0
@onready var left_ship: RigidBody2D = $Spaceship_Left
@onready var right_ship: RigidBody2D = $Spaceship_Right


func _init() -> void:
	mode_title = "COAL LIFT"
	objective = "Catch coal and load your ship's furnace. Burn enough fuel to hold your ship above the gold altitude for 2.5 seconds."


func _ready() -> void:
	super._ready()


func _physics_process(delta: float) -> void:
	if round_over or not round_active:
		return
	if not is_instance_valid(left_ship) or not is_instance_valid(right_ship):
		return
	left_hold = _updated_hold(left_ship, left_hold, delta)
	right_hold = _updated_hold(right_ship, right_hold, delta)
	set_status(
		"P1 FUEL %d%%  HOLD %.1f    |    P2 FUEL %d%%  HOLD %.1f" % [
			int(left_ship.total_fuel * 100.0),
			left_hold,
			int(right_ship.total_fuel * 100.0),
			right_hold
		]
	)
	if left_hold >= hold_to_win:
		finish_side(-1, "P1 ACHIEVES LIFT-OFF!")
	elif right_hold >= hold_to_win:
		finish_side(1, "P2 ACHIEVES LIFT-OFF!")


func _updated_hold(ship: RigidBody2D, current: float, delta: float) -> float:
	if ship.global_position.y <= goal_y and ship.total_fuel > 0.25:
		return minf(hold_to_win, current + delta)
	return maxf(0.0, current - delta * 1.5)


func ship_destroyed(ship: Node) -> void:
	if round_over:
		return
	if ship == left_ship:
		finish_side(1, "P2 KEEPS THEIR SHIP ALOFT!")
	elif ship == right_ship:
		finish_side(-1, "P1 KEEPS THEIR SHIP ALOFT!")
