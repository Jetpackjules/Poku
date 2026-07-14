extends Node2D

var tick := 0
var basketball: Node2D
var ball_done_count := 0
var speed_player: RigidBody2D
var speed_saw_doubled := false
var death_result := {}

func _ready() -> void:
	setup_basketball()
	setup_speed_powerup()
	setup_death_zone()

func freeze_ragdoll(node: Node) -> void:
	if node is RigidBody2D:
		var body := node as RigidBody2D
		body.gravity_scale = 0
		body.freeze = true
		body.freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	for child in node.get_children():
		freeze_ragdoll(child)

func make_player(at: Vector2, player_name: String) -> RigidBody2D:
	var player := (load("res://Player/Player.tscn") as PackedScene).instantiate() as RigidBody2D
	player.name = player_name
	$Players.add_child(player)
	player.global_position = at
	freeze_ragdoll(player)
	return player

func setup_basketball() -> void:
	basketball = (load("res://Maps/Basketball/Basketball_Map.tscn") as PackedScene).instantiate()
	add_child(basketball)
	SceneSwitcher.current_map = basketball
	var ball := (load("res://Items/Ball.tscn") as PackedScene).instantiate() as RigidBody2D
	add_child(ball)
	ball.gravity_scale = 0
	ball.done.connect(_on_ball_done)
	var hoop := basketball.get_node("Hoop_left")
	hoop.get_node("Timer").wait_time = 0.05
	hoop._on_Hoop_Goal_body_entered(ball)

func _on_ball_done(_ball: RigidBody2D) -> void:
	ball_done_count += 1
	basketball.get_node("Hoop_left/Timer").stop()

func setup_speed_powerup() -> void:
	speed_player = make_player(Vector2(3000, 0), "SpeedPlayer")
	var powerup := (load("res://Powerup/Speed.tscn") as PackedScene).instantiate()
	add_child(powerup)
	powerup.global_position = speed_player.global_position
	powerup.get_node("RigidBody2D").global_position = speed_player.global_position
	powerup.get_node("Timer").wait_time = 0.1
	powerup._on_Powerup_body_entered(speed_player)

func setup_death_zone() -> void:
	var victim := make_player(Vector2(4000, 0), "BodyDeathVictim")
	var death_zone := (load("res://Prefabs/Death_Zone.tscn") as PackedScene).instantiate()
	add_child(death_zone)
	SceneSwitcher.living_players = 1
	death_zone._on_Death_Zone_body_entered(victim)
	var tool := (load("res://Items/Shuriken.tscn") as PackedScene).instantiate() as RigidBody2D
	add_child(tool)
	var tool_done_count := [0]
	tool.done.connect(func(_item): tool_done_count[0] += 1)
	death_zone._on_Death_Zone_body_entered(tool)
	death_result = {
		"player_dead":victim.dead, "player_uncontrollable":not victim.controllable,
		"player_ragdolled":victim.ragdolled, "living_players":SceneSwitcher.living_players,
		"tool_done":tool.is_done, "tool_done_count":tool_done_count[0],
		"tool_queued":tool.is_queued_for_deletion()
	}

func _physics_process(_delta: float) -> void:
	tick += 1
	if is_equal_approx(speed_player.speed, 800.0):
		speed_saw_doubled = true
	if tick == 120:
		var score := basketball.get_node("Score")
		print("PARITY_JSON:", JSON.stringify({
			"kind":"mechanics", "name":"basketball",
			"left_score":score.left_score, "right_score":score.right_score,
			"ball_done_count":ball_done_count
		}))
		print("PARITY_JSON:", JSON.stringify({
			"kind":"mechanics", "name":"speed_powerup",
			"saw_doubled":speed_saw_doubled, "restored":is_equal_approx(speed_player.speed, 400.0)
		}))
		death_result["kind"] = "mechanics"
		death_result["name"] = "death_zone"
		print("PARITY_JSON:", JSON.stringify(death_result))
		get_tree().quit()
