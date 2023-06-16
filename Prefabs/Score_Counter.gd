extends Label

var score := 0

func _ready():
	SceneSwitcher.connect("players_moved", self, "scan_players") 
	text = str(score) + " "


func scan_players():
	print("NO CODE HERE!!! EROORRRRRRR !!!!!!!!!!!!!")


func increase(amount):
	score += amount
	text = str(score)
	
