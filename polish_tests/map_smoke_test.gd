extends Node2D

const MAPS := [
	"Main_Menu",
	"Basketball",
	"Ostritch",
	"Planes",
	"Player_test",
	"Spaceship",
	"Test_Lab",
	"Targets",
	"Vertical_Parkour",
	"Volleyball",
	"Wipeout"
]

var failures: Array[String] = []
var loaded_maps := 0


func _ready() -> void:
	await _run_tests()
	print("POLISH_JSON:", JSON.stringify({
		"suite": "map_smoke",
		"passed": failures.is_empty(),
		"failures": failures,
		"loaded_maps": loaded_maps
	}))
	get_tree().quit(0 if failures.is_empty() else 1)


func _run_tests() -> void:
	for map_name in MAPS:
		var path := "res://Maps/%s/%s_Map.tscn" % [map_name, map_name]
		var resource := load(path) as PackedScene
		if resource == null:
			_fail("%s could not be loaded" % path)
			continue
		var map := resource.instantiate()
		$MapSlot.add_child(map)
		SceneSwitcher.current_map = map
		await _wait_ticks(8)
		var physics_nodes: Array = []
		_collect_physics_nodes(map, physics_nodes)
		for body in physics_nodes:
			if not _finite_vector(body.global_position) or not is_finite(body.global_rotation):
				_fail("%s created a non-finite physics transform" % map_name)
			if body is RigidBody2D:
				if not _finite_vector(body.linear_velocity) or not is_finite(body.angular_velocity):
					_fail("%s created a non-finite rigid-body state" % map_name)
		loaded_maps += 1
		map.queue_free()
		await get_tree().physics_frame

	var ostrich := (load("res://Ostritch/Ostritch.tscn") as PackedScene).instantiate()
	$MapSlot.add_child(ostrich)
	await _wait_ticks(30)
	var ostrich_controller = ostrich.get_node("Spine1")
	_expect(
		ostrich_controller.get_script().resource_path == "res://Player/Torso.gd",
		"The Ostritch scene is not wired to its parity controller"
	)
	Input.action_press("ui_right")
	await _wait_ticks(40)
	Input.action_release("ui_right")
	_expect(
		ostrich_controller.velocity.x > 300.0,
		"The Ostritch parity controller did not preserve rightward intent"
	)
	var ostrich_bodies: Array = []
	_collect_physics_nodes(ostrich, ostrich_bodies)
	for body in ostrich_bodies:
		if body is RigidBody2D and (not _finite_vector(body.linear_velocity) or not is_finite(body.angular_velocity)):
			_fail("The Ostritch produced a non-finite body state")
	ostrich.queue_free()
	await get_tree().physics_frame


func _collect_physics_nodes(node: Node, output: Array) -> void:
	if node is PhysicsBody2D:
		output.append(node)
	for child in node.get_children():
		_collect_physics_nodes(child, output)


func _wait_ticks(count: int) -> void:
	for _tick in count:
		await get_tree().physics_frame


func _fail(message: String) -> void:
	if message not in failures:
		failures.append(message)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _finite_vector(value: Vector2) -> bool:
	return is_finite(value.x) and is_finite(value.y)
