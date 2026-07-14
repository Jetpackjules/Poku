extends Node

var living_players := 2
var current_map: Node
var start := true

func check_living() -> void:
	pass

func random_map() -> void:
	pass

func change_map(_map_name: String) -> void:
	pass

func get_players() -> Array:
	var players := get_tree().root.get_node_or_null("Scene_Manager/Players")
	return players.get_children() if players else []
