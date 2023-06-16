extends "res://Prefabs/Score_Counter.gd"

func scan_players():
	for player in SceneSwitcher.get_players():
		if player.global_position.x < 0:
			player.connect("increase_score", self, "increase")
