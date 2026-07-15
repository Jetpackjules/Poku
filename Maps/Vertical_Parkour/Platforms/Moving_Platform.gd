extends Path2D

@onready var pathing = get_node("PathFollow2D")
@onready var platform: AnimatableBody2D = get_node("Platform_Small_Moving")

var platform_velocity := Vector2.ZERO
var _previous_platform_position := Vector2.ZERO


func _ready() -> void:
	platform.position = pathing.position
	_previous_platform_position = platform.global_position


func _physics_process(delta: float) -> void:
	pathing.progress_ratio = fposmod(pathing.progress_ratio + delta / 14.0, 1.0)
	platform.position = pathing.position
	var displacement := platform.global_position - _previous_platform_position
	if displacement.length() > 300.0:
		platform_velocity = Vector2.ZERO
		platform.reset_physics_interpolation()
	else:
		platform_velocity = displacement / maxf(delta, 0.0001)
	platform.constant_linear_velocity = platform_velocity
	_previous_platform_position = platform.global_position


func get_platform_velocity() -> Vector2:
	return platform_velocity
