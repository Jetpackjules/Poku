extends Node2D

const SAMPLE_COUNT := 200

var tick := 0
var moving_follow: PathFollow2D
var moving_start := 0.25
var sample := {
	"normal": 0, "small": 0, "moving": 0,
	"gap_violations": 0, "x_violations": 0, "moving_progress_violations": 0,
}
var generator: Node2D

func _ready() -> void:
	var map := (load("res://Maps/Vertical_Parkour/Vertical_Parkour_Map.tscn") as PackedScene).instantiate()
	add_child(map)
	generator = map.get_node("Platform_Generator")
	generator.set_process(false)
	run_samples()
	var moving := (load("res://Maps/Vertical_Parkour/Platforms/Platform_Moving.tscn") as PackedScene).instantiate()
	add_child(moving)
	moving_follow = moving.get_node("PathFollow2D")
	moving_follow.progress_ratio = moving_start

func run_samples() -> void:
	var previous_position: Vector2 = generator.last_platform_position
	var previous_type: String = generator.last_platform_type
	for _index in range(SAMPLE_COUNT):
		generator.generate_platform(previous_position)
		var platform := generator.get_child(generator.get_child_count() - 1) as Node2D
		var platform_type: String = generator.last_platform_type
		sample[platform_type] += 1
		var gap := previous_position.y - platform.position.y
		var maximum_gap := 500.0 if previous_type == "moving" else 400.0
		if gap < 200.0 or gap > maximum_gap:
			sample.gap_violations += 1
		if platform.position.x < -1500.0 or platform.position.x > 1500.0:
			sample.x_violations += 1
		if platform_type == "moving":
			if platform.position.x < -300.0 or platform.position.x > 300.0:
				sample.x_violations += 1
			var progress: float = platform.get_node("PathFollow2D").progress_ratio
			if progress < 0.0 or progress > 1.0:
				sample.moving_progress_violations += 1
		previous_position = platform.position
		previous_type = platform_type

func _physics_process(_delta: float) -> void:
	tick += 1
	if tick == 120:
		var probabilities := {}
		for entry in generator.platform_scenes:
			probabilities[entry.type] = entry.probability
		print("PARITY_JSON:", JSON.stringify({
			"kind":"vertical", "name":"config", "probabilities":probabilities,
			"x_min":generator.x_range.x, "x_max":generator.x_range.y,
			"gap_min":generator.y_gap.x, "gap_max":generator.y_gap.y,
			"physics_ticks":Engine.physics_ticks_per_second
		}))
		print("PARITY_JSON:", JSON.stringify({
			"kind":"vertical", "name":"sample", "sample_count":SAMPLE_COUNT,
			"normal":sample.normal, "small":sample.small, "moving":sample.moving,
			"gap_violations":sample.gap_violations,
			"x_violations":sample.x_violations,
			"moving_progress_violations":sample.moving_progress_violations
		}))
		print("PARITY_JSON:", JSON.stringify({
			"kind":"vertical", "name":"moving_motion",
			"progress_delta":fposmod(moving_follow.progress_ratio - moving_start, 1.0)
		}))
		get_tree().quit()
