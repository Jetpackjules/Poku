extends Node2D

var tick = 0
var basketball
var ball_done_count = 0
var speed_player
var speed_saw_doubled = false
var death_result = {}

func _ready():
	setup_basketball()
	setup_speed_powerup()
	setup_death_zone()

func freeze_ragdoll(node):
	if node is RigidBody2D:
		node.gravity_scale = 0
		node.mode = RigidBody2D.MODE_STATIC
	for child in node.get_children():
		freeze_ragdoll(child)

func make_player(at, player_name):
	var player = load("res://Player/Player.tscn").instance()
	player.name = player_name
	$Players.add_child(player)
	player.global_position = at
	freeze_ragdoll(player)
	return player

func setup_basketball():
	basketball = load("res://Maps/Basketball/Basketball_Map.tscn").instance()
	add_child(basketball)
	SceneSwitcher.current_map = basketball
	var ball = load("res://Items/Ball.tscn").instance()
	add_child(ball)
	ball.gravity_scale = 0
	ball.connect("done", self, "_on_ball_done")
	var hoop = basketball.get_node("Hoop_left")
	hoop.get_node("Timer").wait_time = 0.05
	hoop._on_Hoop_Goal_body_entered(ball)

func _on_ball_done(_ball):
	ball_done_count += 1
	basketball.get_node("Hoop_left/Timer").stop()

func setup_speed_powerup():
	speed_player = make_player(Vector2(3000, 0), "SpeedPlayer")
	var powerup = load("res://Powerup/Speed.tscn").instance()
	add_child(powerup)
	powerup.global_position = speed_player.global_position
	powerup.get_node("RigidBody2D").global_position = speed_player.global_position
	powerup.get_node("Timer").wait_time = 0.1
	powerup._on_Powerup_body_entered(speed_player)

func setup_death_zone():
	var victim = make_player(Vector2(4000, 0), "BodyDeathVictim")
	var death_zone = load("res://Prefabs/Death_Zone.tscn").instance()
	add_child(death_zone)
	SceneSwitcher.living_players = 1
	death_zone._on_Death_Zone_body_entered(victim)
	var tool = load("res://Items/Shuriken.tscn").instance()
	add_child(tool)
	tool.connect("done", self, "_on_tool_done")
	death_zone._on_Death_Zone_body_entered(tool)
	death_result = {
		"player_dead":victim.dead, "player_uncontrollable":not victim.controllable,
		"player_ragdolled":victim.ragdolled, "living_players":SceneSwitcher.living_players,
		"tool_done":tool.done, "tool_done_count":tool_done_count,
		"tool_queued":tool.is_queued_for_deletion()
	}

var tool_done_count = 0
func _on_tool_done(_tool):
	tool_done_count += 1

func _physics_process(_delta):
	tick += 1
	if is_equal_approx(speed_player.speed, 800.0):
		speed_saw_doubled = true
	if tick == 120:
		var score = basketball.get_node("Score")
		print("PARITY_JSON:", JSON.print({
			"kind":"mechanics", "name":"basketball",
			"left_score":score.left_score, "right_score":score.right_score,
			"ball_done_count":ball_done_count
		}))
		print("PARITY_JSON:", JSON.print({
			"kind":"mechanics", "name":"speed_powerup",
			"saw_doubled":speed_saw_doubled, "restored":is_equal_approx(speed_player.speed, 400.0)
		}))
		death_result["kind"] = "mechanics"
		death_result["name"] = "death_zone"
		print("PARITY_JSON:", JSON.print(death_result))
		get_tree().quit()
