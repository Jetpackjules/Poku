extends Node2D

var tick = 0
var spear
var shuriken
var spear_body
var shuriken_body
var player_spear
var player_shuriken
var player_spear_item
var player_shuriken_item

func _ready():
	spear_body = make_body(Vector2(400, -100))
	shuriken_body = make_body(Vector2(400, 100))
	spear = make_item("res://Items/Spear.tscn", Vector2(0, -100))
	shuriken = make_item("res://Items/Shuriken.tscn", Vector2(0, 100))
	player_spear = make_player(Vector2(400, 300), "SpearVictim")
	player_shuriken = make_player(Vector2(400, 550), "ShurikenVictim")
	player_spear_item = make_item("res://Items/Spear.tscn", Vector2(0, 300))
	player_shuriken_item = make_item("res://Items/Shuriken.tscn", Vector2(0, 550))

func make_player(at, player_name):
	var player = load("res://Player/Player.tscn").instance()
	player.name = player_name
	add_child(player)
	player.global_position = at
	player.controllable = false
	freeze_ragdoll(player)
	return player

func freeze_ragdoll(node):
	if node is RigidBody2D:
		node.gravity_scale = 0
		node.mode = RigidBody2D.MODE_STATIC
	for child in node.get_children():
		freeze_ragdoll(child)

func pin_count(item):
	var count = 0
	for child in item.get_children():
		if child is PinJoint2D:
			count += 1
	return count

func make_body(at):
	var body = preload("res://ParityHarness/FakeStabbable.gd").new()
	body.name = "Body"
	body.mode = RigidBody2D.MODE_STATIC
	body.collision_layer = 2
	body.collision_mask = 16
	body.add_to_group("stabb-able")
	body.position = at
	var shape_node = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.extents = Vector2(50, 50)
	shape_node.shape = shape
	body.add_child(shape_node)
	add_child(body)
	return body

func make_item(path, at):
	var thrower = Node2D.new()
	thrower.name = "Thrower"
	add_child(thrower)
	thrower.owner = self
	var hand = Node2D.new()
	hand.name = "Hand"
	thrower.add_child(hand)
	hand.owner = thrower
	var item = load(path).instance()
	item.position = at
	item.gravity_scale = 0
	item.target_node = hand
	item.cooldown = true
	item.cooltime_wait = 0.06
	item.held = false
	add_child(item)
	item.linear_velocity = Vector2(1200, 0)
	return item

func emit_result():
	print("PARITY_JSON:", JSON.print({
		"kind":"embedding",
		"spear_impaled":spear.impaled,
		"spear_done":spear.done,
		"spear_stab_count":spear_body.stab_count,
		"shuriken_impaled":shuriken.impaled,
		"shuriken_done":shuriken.done,
		"shuriken_stab_count":shuriken_body.stab_count
	}))
	print("PARITY_JSON:", JSON.print({
		"kind":"embedding", "name":"actual_player",
		"spear_impaled":player_spear_item.impaled,
		"spear_done":player_spear_item.done,
		"spear_victim_stabs":player_spear.stabbed_bodies.size(),
		"spear_victim_ragdolled":player_spear.ragdolled,
		"spear_has_two_embed_pins":pin_count(player_spear_item) >= 3,
		"spear_received_legacy_weight":player_spear_item.mass > 50.0,
		"shuriken_impaled":player_shuriken_item.impaled,
		"shuriken_done":player_shuriken_item.done,
		"shuriken_victim_stabs":player_shuriken.stabbed_bodies.size(),
		"shuriken_victim_ragdolled":player_shuriken.ragdolled,
		"shuriken_has_two_embed_pins":pin_count(player_shuriken_item) >= 3,
		"shuriken_received_legacy_weight":player_shuriken_item.mass > 50.0
	}))

func _physics_process(_delta):
	tick += 1
	if tick == 120:
		emit_result()
		get_tree().quit()
