extends Node

var failures: Array[String] = []


func _ready() -> void:
	var menu := (load("res://Maps/Main_Menu/Main_Menu_Map.tscn") as PackedScene).instantiate()
	$Slot.add_child(menu)
	await get_tree().process_frame
	var lab_button = menu.get_node_or_null("MenuRoot/Map_Select/CenterContainer/VBoxContainer/GridContainer/Test_Lab")
	_expect(lab_button is Button, "Chaos Lab is not exposed as a playable game-select tile")
	var map_select = menu.get_node("MenuRoot/Map_Select")
	_expect(lab_button in map_select.level_buttons, "Chaos Lab tile is visible but not connected to map loading")
	menu.queue_free()
	await get_tree().process_frame

	var lab := (load("res://Maps/Test_Lab/Test_Lab_Map.tscn") as PackedScene).instantiate()
	$Slot.add_child(lab)
	SceneSwitcher.current_map = lab
	await get_tree().process_frame
	var initial_count: int = lab.active_items.size()
	_expect(initial_count == 12, "Chaos Lab did not begin with its authored item burst")
	for _tick in 150:
		await get_tree().physics_frame
	_expect(lab.active_items.size() > initial_count, "Chaos Lab's endless timer stopped spawning")

	var item_names := {}
	for item in lab.active_items:
		item_names[item.name] = true
	_expect(item_names.has("Ball"), "Chaos Lab never spawned balls")
	_expect(item_names.has("Spear"), "Chaos Lab never spawned spears")
	_expect(item_names.has("Shuriken"), "Chaos Lab never spawned shuriken")
	_expect(item_names.has("Coal"), "Chaos Lab never spawned coal")
	_expect(item_names.has("Target"), "Chaos Lab never spawned targets")

	for _extra in 60:
		lab._spawn_item()
	_expect(lab.active_items.size() <= lab.maximum_active_items, "Endless spawning has no safety cap")
	_expect(lab.active_items.size() >= lab.maximum_active_items - 2, "Chaos Lab removes items too aggressively")

	print("POLISH_JSON:", JSON.stringify({
		"suite": "test_lab",
		"passed": failures.is_empty(),
		"failures": failures,
		"active_items": lab.active_items.size()
	}))
	get_tree().quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition and message not in failures:
		failures.append(message)
