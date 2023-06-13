extends Label

var score := 0

func _ready():
	text = str(score) + " "
	print(SceneSwitcher.get_players())
	for player in SceneSwitcher.get_players():
		if player.global_position.x >= 0:
			player.connect("increase_score", self, "increase")
			print("CONNECTED ", player)


func increase(amount):
	score += amount
	text = str(score)
