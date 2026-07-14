extends Node

var living_players = 2
var current_map = null
var start = true

func check_living():
	pass

func random_map():
	pass

func change_map(_map_name):
	pass

func get_players():
	var players = get_tree().get_root().get_node_or_null("Scene_Manager/Players")
	return players.get_children() if players else []
