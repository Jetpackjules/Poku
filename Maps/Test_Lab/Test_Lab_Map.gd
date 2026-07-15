extends "res://Maps/ModeController.gd"

const ITEM_SCENES: Array[PackedScene] = [
	preload("res://Items/Ball.tscn"),
	preload("res://Items/Spear.tscn"),
	preload("res://Items/Shuriken.tscn"),
	preload("res://Items/Ball.tscn"),
	preload("res://Items/Coal.tscn"),
	preload("res://Props/Target.tscn")
]

@export var spawn_interval := 0.38
@export var maximum_active_items := 44

var active_items: Array[Node] = []
var spawn_index := 0
var random := RandomNumberGenerator.new()


func _init() -> void:
	mode_title = "CHAOS LAB"
	objective = "An endless rain of balls, weapons, coal, and targets for testing every Physics Lab toggle."
	countdown_enabled = false


func _ready() -> void:
	super._ready()
	random.randomize()
	var timer := Timer.new()
	timer.name = "EndlessSpawnTimer"
	timer.wait_time = spawn_interval
	timer.timeout.connect(_spawn_item)
	add_child(timer)
	timer.start()
	for _initial_item in 12:
		_spawn_item()


func _spawn_item() -> void:
	_clean_item_list()
	var packed_scene := ITEM_SCENES[spawn_index % ITEM_SCENES.size()]
	spawn_index += 1
	var item := packed_scene.instantiate()
	$SpawnedItems.add_child(item)
	item.position = Vector2(random.randf_range(-1400.0, 1400.0), random.randf_range(-1580.0, -1380.0))
	if item is RigidBody2D:
		item.linear_velocity = Vector2(random.randf_range(-260.0, 260.0), random.randf_range(40.0, 210.0))
		item.angular_velocity = random.randf_range(-8.0, 8.0)
	active_items.append(item)
	_trim_old_items()
	set_status("ITEM RAIN  ∞     ACTIVE  %d / %d" % [active_items.size(), maximum_active_items])


func _clean_item_list() -> void:
	active_items = active_items.filter(func(item): return is_instance_valid(item) and not item.is_queued_for_deletion())


func _trim_old_items() -> void:
	var attempts := active_items.size()
	while active_items.size() > maximum_active_items and attempts > 0:
		attempts -= 1
		var candidate = active_items.pop_front()
		var held: bool = candidate.get("held") == true
		var impaled: bool = candidate.get("impaled") == true
		if held or impaled:
			active_items.append(candidate)
		else:
			candidate.queue_free()
