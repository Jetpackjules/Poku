extends Node2D

export var winning_score := 3

func _ready():
	for score in get_children():
		score.win_score = winning_score
