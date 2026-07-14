extends Node2D

var tick = 0
var cases = []

func _ready():
	make_floor()
	var specs = [
		["spear_slow_flat", "res://Items/Spear.tscn", 200.0, 0.0],
		["spear_fast_flat", "res://Items/Spear.tscn", 800.0, 0.0],
		["spear_fast_tilt", "res://Items/Spear.tscn", 800.0, 0.6],
		["spear_fast_steep", "res://Items/Spear.tscn", 800.0, 1.2],
		["ball_slow", "res://Items/Ball.tscn", 200.0, 0.0],
		["ball_fast", "res://Items/Ball.tscn", 800.0, 0.0]
	]
	for index in range(specs.size()):
		make_case(specs[index], index)

func make_floor():
	var floor_body = StaticBody2D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.extents = Vector2(10000, 50)
	collision.shape = shape
	collision.position = Vector2(2500, 350)
	floor_body.add_child(collision)
	add_child(floor_body)

func make_case(spec, index):
	var item = load(spec[1]).instance()
	var origin_x = index * 1000.0
	item.position = Vector2(origin_x, 0)
	item.rotation = spec[3]
	item.linear_velocity = Vector2(spec[2], 0)
	item.angular_velocity = 0
	item.cooldown = true
	item.cooltime = 999.0
	item.locked = "spear" in spec[0]
	item.friction = 1.0
	item.bounce = 0.0 if "spear" in spec[0] else 0.1
	add_child(item)
	cases.append({"name":spec[0], "body":item, "origin_x":origin_x, "min_y":item.position.y, "max_y":item.position.y})

func emit_results():
	for item in cases:
		var body = item.body
		print("PARITY_JSON:", JSON.print({
			"kind":"contact", "name":item.name,
			"dx":body.position.x - item.origin_x, "y":body.position.y,
			"min_y":item.min_y, "max_y":item.max_y,
			"vx":body.linear_velocity.x, "vy":body.linear_velocity.y,
			"r":body.rotation, "av":body.angular_velocity
		}))

func _physics_process(_delta):
	tick += 1
	for item in cases:
		item.min_y = min(item.min_y, item.body.position.y)
		item.max_y = max(item.max_y, item.body.position.y)
	if tick >= 900:
		emit_results()
		get_tree().quit()
