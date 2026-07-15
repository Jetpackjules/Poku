extends Label

@export var max_score := 2

var p1_score := 0
var p2_score := 0
var finished := false


func update_score(left_hoop_points: int, right_hoop_points: int) -> void:
	if finished:
		return
	# P1 lives on the left and attacks the right hoop; P2 does the inverse.
	p1_score += right_hoop_points
	p2_score += left_hoop_points
	text = "%d - %d" % [p1_score, p2_score]
	var map := get_parent()
	if map.has_method("score_changed"):
		map.score_changed(p1_score, p2_score)
	if p1_score >= max_score:
		finished = true
		if map.has_method("finish_side"):
			map.finish_side(-1, "P1 WINS BASKETBALL!")
	elif p2_score >= max_score:
		finished = true
		if map.has_method("finish_side"):
			map.finish_side(1, "P2 WINS BASKETBALL!")
