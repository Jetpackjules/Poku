extends Node

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var player := (load("res://Player/Player.tscn") as PackedScene).instantiate()
	$Players.add_child(player)
	var menu := (load("res://Maps/Main_Menu/Main_Menu_Map.tscn") as PackedScene).instantiate()
	add_child(menu)
	SceneSwitcher.current_map = menu
	await get_tree().physics_frame

	var button: Button = menu.get_node("MenuRoot/Map_Select/CenterContainer/VBoxContainer/GridContainer/Ostritch")
	_expect(button != null, "The game-select Ostritch tile is missing")
	if button:
		button.emit_signal("pressed")

	var reached_ostritch := false
	for _tick in 480:
		await get_tree().physics_frame
		if is_instance_valid(SceneSwitcher.current_map) and SceneSwitcher.current_map.name == "Ostritch_Map" and SceneSwitcher.current_map.is_inside_tree():
			reached_ostritch = true
			break

	_expect(reached_ostritch, "Pressing the Ostritch tile did not complete the real map transition")
	if reached_ostritch:
		_expect(SceneSwitcher.current_map.has_node("Ostritch"), "The routed map does not contain the Ostritch scene")
	_expect(not player.visible, "A normal Poku player remained visible in the single-character Ostritch playground")
	_expect(player.freeze, "A parked Poku player remained active behind the Ostritch playground")

	print("POLISH_JSON:", JSON.stringify({
		"suite": "ostritch_route",
		"passed": failures.is_empty(),
		"failures": failures
	}))
	get_tree().quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition and message not in failures:
		failures.append(message)
