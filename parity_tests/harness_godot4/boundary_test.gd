extends Node2D

var tick := 0
var cases := []

func _ready() -> void:
	var specs := [
		["basketball_center", "res://Maps/Basketball/Basketball_Map.tscn", "Seperator", "Vertical_Boundary", "x", 14, 525],
		["wipeout_right", "res://Maps/Wipeout/Wipeout_Map.tscn", "Seperator", "Boundary_Right", "x", 14, 525],
		["targets_right", "res://Maps/Targets/Targets_Map.tscn", "Seperator", "Vertical_Boundary", "x", 14, 525],
		["player_test_right", "res://Maps/Player_test/Player_test_Map.tscn", "Seperator", "Vertical_Boundary", "x", 14, 525],
		["volleyball_center", "res://Maps/Volleyball/Volleyball_Map.tscn", "Seperator", "Vertical_Boundary", "x", 14, 525],
		["volleyball_ceiling_player", "res://Maps/Volleyball/Volleyball_Map.tscn", "Seperator/Horizontal_Boundary4", "Horizontal_Boundary3", "y", 14, 525],
		["volleyball_ceiling_tool", "res://Maps/Volleyball/Volleyball_Map.tscn", "Seperator/Horizontal_Boundary4", "Horizontal_Boundary3", "y", 16, 17]
	]
	for index in range(specs.size()):
		make_case(specs[index], index)

func make_case(spec: Array, index: int) -> void:
	var source := (load(spec[1]) as PackedScene).instantiate()
	var source_body := source.get_node(spec[2]) as StaticBody2D
	var source_shape := source_body.get_node(spec[3]) as CollisionShape2D
	var origin := Vector2(0, index * 3000)
	var wall := StaticBody2D.new()
	wall.name = spec[0] + "_wall"
	wall.position = origin
	wall.collision_layer = source_body.collision_layer
	wall.collision_mask = source_body.collision_mask
	var wall_shape := CollisionShape2D.new()
	wall_shape.shape = source_shape.shape.duplicate()
	wall.add_child(wall_shape)
	add_child(wall)
	var mover := RigidBody2D.new()
	mover.name = spec[0] + "_mover"
	mover.collision_layer = spec[5]
	mover.collision_mask = spec[6]
	mover.gravity_scale = 0
	mover.can_sleep = false
	var mover_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(40, 40)
	mover_shape.shape = rectangle
	mover.add_child(mover_shape)
	add_child(mover)
	if spec[4] == "x":
		mover.position = origin + Vector2(-100, 0)
		mover.linear_velocity = Vector2(300, 0)
	else:
		mover.position = origin + Vector2(0, -100)
		mover.linear_velocity = Vector2(0, 300)
	cases.append({"name":spec[0], "axis":spec[4], "origin":origin, "wall":wall, "mover":mover, "shape_size":wall_shape.shape.size})
	source.free()

func emit_results() -> void:
	for item in cases:
		var coordinate: float = item.mover.position.x - item.origin.x if item.axis == "x" else item.mover.position.y - item.origin.y
		print("PARITY_JSON:", JSON.stringify({
			"kind":"boundary", "name":item.name,
			"coordinate":coordinate, "blocked":coordinate < 0,
			"wall_layer":item.wall.collision_layer, "wall_mask":item.wall.collision_mask,
			"shape_x":item.shape_size.x, "shape_y":item.shape_size.y
		}))

func _physics_process(_delta: float) -> void:
	tick += 1
	if tick == 120:
		emit_results()
		get_tree().quit()
