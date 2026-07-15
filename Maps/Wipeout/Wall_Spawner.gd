extends Node2D

@export var Wall = preload("res://Maps/Wipeout/Wall.tscn")
@export var minimum_spawn_time := 3.6
@export var maximum_spawn_time := 5.0
@export var max_gap_size := 650.0
@export var min_gap_size := 300.0
@export var gap_shrink_speed := 32.0
@export var starting_speed := 150.0
@export var speed_gain_per_second := 10.0
@export var playable_top := -1450.0
@export var playable_bottom := 180.0

var time_until_next_wall := 1.8
var num_walls_spawned := 0
var speed := 150.0


func _ready() -> void:
	speed = starting_speed


func _physics_process(delta: float) -> void:
	time_until_next_wall -= delta
	speed += speed_gain_per_second * delta
	if time_until_next_wall <= 0.0:
		time_until_next_wall = randf_range(minimum_spawn_time, maximum_spawn_time)
		spawn_wall()


func current_gap_size() -> float:
	return maxf(max_gap_size - gap_shrink_speed * num_walls_spawned, min_gap_size)


func spawn_wall() -> void:
	var wall = Wall.instantiate()
	var gap_size := current_gap_size()
	var half_gap := gap_size * 0.5
	wall.gap = gap_size
	wall.speed = speed
	# Keep every opening fully inside the playable vertical corridor. The old
	# offset range frequently placed the entire gap under the floor.
	wall.offset = randf_range(playable_top + half_gap, playable_bottom - half_gap)
	add_child(wall)
	wall.position = Vector2(get_viewport().size.x * 1.7, 0.0)
	wall.adjust()
	wall.reset_physics_interpolation()
	num_walls_spawned += 1
