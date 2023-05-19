extends Label

var right_score := 0
var left_score := 0

var left_score_text := "0"
var right_score_text := "0"

var max_score := 2


func update_score(left, right):
	left_score += left
	right_score += right
	
	update_visual_score()

	if (left_score >= max_score):
		SceneSwitcher.change_map("Main_Menu")

	elif (right_score >= max_score):
		SceneSwitcher.change_map("Main_Menu")
	
	
	
	
func update_visual_score():
	if left_score == 0:
		left_score_text = "0 "
	else:
		left_score_text = str(left_score)

	if right_score == 0:
		right_score_text = " 0"
	else:
		right_score_text = str(right_score)
	
	text =  right_score_text + " -" + left_score_text
