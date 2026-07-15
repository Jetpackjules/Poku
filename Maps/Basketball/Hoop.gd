extends Node2D

@onready var timer: Timer = $Timer
@onready var goal: Area2D = $Hoop_Goal
@onready var backboard = $Backboard/Panel
@onready var score = get_node("../Score")

var scoring_ball: Node = null
var confetti_scene = preload("res://Items/Effects/Confetti.tscn")


func _ready() -> void:
	backboard.material = load("res://Maps/Basketball/Progress_Goal.tres").duplicate()
	timer.one_shot = true


func _physics_process(_delta: float) -> void:
	var progress := 0.0
	if not timer.is_stopped():
		progress = 1.0 - timer.time_left / timer.wait_time
	backboard.material.set_shader_parameter("progress", progress)


func _on_Hoop_Goal_body_entered(body: Node) -> void:
	if scoring_ball == null and body.is_in_group("score-able"):
		scoring_ball = body
		timer.start()


func _on_Hoop_Goal_body_exited(body: Node) -> void:
	if body == scoring_ball:
		timer.stop()
		scoring_ball = null


func _on_Timer_timeout() -> void:
	if not is_instance_valid(scoring_ball) or scoring_ball not in goal.get_overlapping_bodies():
		scoring_ball = null
		return
	var scored_ball := scoring_ball
	scoring_ball = null
	if scored_ball.has_signal("done"):
		scored_ball.done.emit(scored_ball)
	var confetti = confetti_scene.instantiate()
	add_child(confetti)
	confetti.global_position = scored_ball.global_position
	confetti.pop()
	scored_ball.queue_free()
	if "right" in name.to_lower():
		score.update_score(0, 1)
	else:
		score.update_score(1, 0)
