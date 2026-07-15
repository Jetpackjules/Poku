extends "res://Maps/ModeController.gd"

@export var winning_score := 5

var left_score := 0
var right_score := 0
var resetting_ball := false
@onready var ball: RigidBody2D = $Ball


func _init() -> void:
	mode_title = "VOLLEYBALL"
	objective = "Keep the ball off your floor and send it over the floppy net. First to 5 points."


func _ready() -> void:
	super._ready()
	_create_score_zone("LeftScoreZone", -900.0, -1)
	_create_score_zone("RightScoreZone", 900.0, 1)
	_update_score()


func _create_score_zone(zone_name: String, x_position: float, landed_side: int) -> void:
	var area := Area2D.new()
	area.name = zone_name
	area.position = Vector2(x_position, 185.0)
	area.collision_layer = 0
	area.collision_mask = 16
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1750.0, 130.0)
	collision.shape = shape
	area.add_child(collision)
	add_child(area)
	area.body_entered.connect(_on_score_zone_entered.bind(landed_side))


func _on_score_zone_entered(body: Node, landed_side: int) -> void:
	if body != ball or resetting_ball or round_over:
		return
	resetting_ball = true
	if landed_side < 0:
		right_score += 1
		announce("P2 POINT!", 0.65)
	else:
		left_score += 1
		announce("P1 POINT!", 0.65)
	_update_score()
	if left_score >= winning_score:
		finish_side(-1, "P1 WINS THE RALLY!")
		return
	if right_score >= winning_score:
		finish_side(1, "P2 WINS THE RALLY!")
		return
	_reset_ball()


func _reset_ball() -> void:
	ball.freeze = true
	await get_tree().create_timer(0.8).timeout
	if not is_instance_valid(ball) or round_over:
		return
	ball.global_position = Vector2(0.0, -640.0)
	ball.linear_velocity = Vector2(randf_range(-80.0, 80.0), -40.0)
	ball.angular_velocity = randf_range(-1.5, 1.5)
	ball.reset_physics_interpolation()
	ball.freeze = false
	resetting_ball = false


func _update_score() -> void:
	set_status("P1   %d — %d   P2" % [left_score, right_score])
