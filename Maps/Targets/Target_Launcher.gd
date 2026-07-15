extends Node2D

@export var props := ["Target"]
@export var initial_spawn := 3
@export var x_range_start := 280.0
@export var x_range_end := 1180.0
@export var y_height_start := -1250.0
@export var y_height_end := -350.0
@export var spawn_interval := 0.7

@onready var camera = get_node("../Camera2D")

var loaded_props: Array[PackedScene] = []
var active_targets := 0
var maximum_targets := 6
var spawn_timer: Timer


func _ready() -> void:
	for prop_name in props:
		loaded_props.append(load("res://Props/%s.tscn" % prop_name) as PackedScene)
	maximum_targets = maxi(2, initial_spawn * 2)
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_maintain_targets)
	add_child(spawn_timer)
	_maintain_targets()


func _maintain_targets() -> void:
	if active_targets > maximum_targets - 2 or loaded_props.is_empty():
		return
	_spawn_target(-1)
	_spawn_target(1)


func _spawn_target(side: int) -> void:
	var target = loaded_props.pick_random().instantiate()
	add_child(target)
	var x := randf_range(x_range_start, x_range_end) * side
	var y := randf_range(y_height_start, y_height_end)
	target.global_position = Vector2(x, y)
	target.launch_force = randf_range(500.0, 1500.0)
	target.done.connect(_on_target_hit.bind(target))
	target.reset_physics_interpolation()
	active_targets += 1


func _on_target_hit(target: Node) -> void:
	active_targets = maxi(0, active_targets - 1)
	if is_instance_valid(camera) and camera.has_method("shake"):
		camera.shake(0.2, 8.0)
	if is_instance_valid(target):
		var replacement_delay := get_tree().create_timer(0.55)
		await replacement_delay.timeout
		_maintain_targets()
