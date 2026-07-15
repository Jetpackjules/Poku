extends Node2D

var color := Color(0.45, 1.0, 0.62)
var intensity := 1.0
var age := 0.0
var lifetime := 0.32


func _ready() -> void:
	z_index = 50
	queue_redraw()


func _process(delta: float) -> void:
	age += delta
	var progress := clampf(age / lifetime, 0.0, 1.0)
	scale = Vector2.ONE * lerpf(0.55, 1.5 + intensity * 0.35, progress)
	modulate.a = 1.0 - progress
	queue_redraw()
	if age >= lifetime:
		queue_free()


func _draw() -> void:
	var radius := 24.0 + intensity * 13.0
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, color, 5.0, true)
	for index in 8:
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / 8.0)
		draw_line(direction * (radius + 5.0), direction * (radius + 20.0), color, 4.0, true)
