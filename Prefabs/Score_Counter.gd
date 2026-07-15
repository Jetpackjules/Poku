extends Label

var score := 0

var win_score := 0

var child_players := []
var completed := false


func _ready():
	SceneSwitcher.connect("players_moved", Callable(self, "scan_players"))
	text = str(score) + " "


func scan_players():
	pass


func increase(amount):
	if completed:
		return
	if SceneSwitcher.current_map and SceneSwitcher.current_map.get("round_active") == false:
		return
	score += amount
	text = str(score)
	if score >= win_score:
		completed = true
		var winner = child_players[0] if not child_players.is_empty() else null
		for player in child_players:
			player.win(true)
		if SceneSwitcher.current_map and SceneSwitcher.current_map.has_method("finish_round"):
			SceneSwitcher.current_map.finish_round(winner, "%s HITS %d TARGETS!" % [winner.name if winner else "POKU", win_score])
