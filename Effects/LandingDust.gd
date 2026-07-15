extends Node2D

## A tiny hand-drawn dust burst. It never participates in physics: the circles
## simply swell, drift, and fade at the point where a Poku finds the floor.

const LIFE := 0.48

var age := 0.0
var puffs: Array[Dictionary] = []


func setup(impact_speed: float, tint := Color(0.96, 0.91, 0.78)) -> void:
	var intensity := clampf(inverse_lerp(180.0, 900.0, impact_speed), 0.0, 1.0)
	var puff_count := 5 + int(round(intensity * 4.0))
	for index in puff_count:
		var side := -1.0 if index % 2 == 0 else 1.0
		puffs.append({
			"position": Vector2(randf_range(3.0, 22.0) * side, randf_range(-3.0, 3.0)),
			"velocity": Vector2(randf_range(55.0, 145.0) * side, randf_range(-78.0, -30.0)) * lerpf(0.75, 1.25, intensity),
			"radius": randf_range(8.0, 15.0) * lerpf(0.82, 1.22, intensity),
			"delay": randf_range(0.0, 0.055),
			"tint": tint.lightened(randf_range(0.0, 0.09))
		})
	queue_redraw()


func _process(delta: float) -> void:
	age += delta
	for index in puffs.size():
		var puff := puffs[index]
		if age >= float(puff["delay"]):
			puff["position"] += puff["velocity"] * delta
			puff["velocity"] *= pow(0.07, delta)
			puff["velocity"].y -= 9.0 * delta
		puffs[index] = puff
	queue_redraw()
	if age >= LIFE:
		queue_free()


func _draw() -> void:
	for puff in puffs:
		var local_age := maxf(0.0, age - float(puff["delay"]))
		if local_age <= 0.0:
			continue
		var progress := clampf(local_age / LIFE, 0.0, 1.0)
		var color: Color = puff["tint"]
		color.a = (1.0 - progress) * 0.72
		var radius: float = puff["radius"] * lerpf(0.55, 1.35, ease(progress, -1.8))
		draw_circle(puff["position"], radius, color, true, -1.0, true)
