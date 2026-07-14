extends Node2D

var tick := 0
var cadence_seen := 0
@onready var map := (load("res://Maps/Wipeout/Wipeout_Map.tscn") as PackedScene).instantiate()

func _ready() -> void:
	randomize()
	add_child(map)
	SceneSwitcher.current_map = map
	var spawner := map.get_node("Wall_Spawner")
	spawner.set_physics_process(false)
	for index in range(8):
		spawner.spawn_wall()
		emit_wall("wipeout_spawn", index, spawner.get_child(spawner.get_child_count() - 1), tick)
	for child in spawner.get_children():
		child.free()
	spawner.num_walls_spawned = 0
	spawner.time_until_next_wall = 4.0
	spawner.speed = 100
	spawner.set_physics_process(true)

func emit_wall(kind: String, index: int, wall: RigidBody2D, at_tick: int) -> void:
	var shape_size: Vector2 = wall.get_node("Wall_Top").shape.size
	print("PARITY_JSON:", JSON.stringify({
		"kind":kind, "name":str(index), "tick":at_tick,
		"gap":wall.gap, "offset":wall.offset, "speed":wall.speed,
		"viewport_width":get_viewport().size.x,
		"x":wall.position.x, "y":wall.position.y,
		"vx":wall.velocity.x, "vy":wall.velocity.y,
		"shape_x":shape_size.x, "shape_y":shape_size.y,
		"character_like":wall.lock_rotation
	}))

func _physics_process(_delta: float) -> void:
	tick += 1
	var spawner := map.get_node("Wall_Spawner")
	if spawner.get_child_count() > cadence_seen:
		for index in range(cadence_seen, spawner.get_child_count()):
			emit_wall("wipeout_cadence", index, spawner.get_child(index), tick)
		cadence_seen = spawner.get_child_count()
	if cadence_seen >= 2 or tick >= 1200:
		get_tree().quit()
