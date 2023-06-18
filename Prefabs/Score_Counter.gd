extends Label

var score := 0

var win_score := 0

var child_players := []


func _ready():
	SceneSwitcher.connect("players_moved", self, "scan_players") 
	text = str(score) + " "


func scan_players():
	print("NO CODE HERE!!! EROORRRRRRR !!!!!!!!!!!!!")


func increase(amount):
	score += amount
	text = str(score)
	if score >= win_score:
		for player in child_players:
			player.win(true)
	
