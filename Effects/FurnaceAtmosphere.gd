extends Node2D

## Fuel-driven furnace glow and hand-drawn smoke. This follows the furnace in
## global space so smoke always rises upward even while the softbody ship tilts.

var visual_intensity := 0.0
var smoke_puffs: Array[Dictionary] = []
var smoke_clock := 0.0
var source: Node2D


func setup(furnace: Node2D) -> void:
	source = furnace
	top_level = true
	_apply_polish_setting()
	if not GameSettings.preference_changed.is_connected(_on_preference_changed):
		GameSettings.preference_changed.connect(_on_preference_changed)


func set_fuel(fuel: float) -> void:
	visual_intensity = clampf(fuel / 2.4, 0.0, 1.0)
	queue_redraw()


func _process(delta: float) -> void:
	if not is_instance_valid(source):
		queue_free()
		return
	global_position = source.global_position
	global_rotation = 0.0
	if not visible:
		return

	if visual_intensity > 0.03:
		smoke_clock += delta
		var interval := lerpf(0.34, 0.09, visual_intensity)
		while smoke_clock >= interval:
			smoke_clock -= interval
			_spawn_smoke()

	for index in range(smoke_puffs.size() - 1, -1, -1):
		var puff := smoke_puffs[index]
		puff["age"] += delta
		if puff["age"] >= puff["life"]:
			smoke_puffs.remove_at(index)
			continue
		var velocity: Vector2 = puff["velocity"]
		velocity.x += sin(float(puff["age"]) * float(puff["wobble"])) * 5.0 * delta
		puff["velocity"] = velocity
		puff["position"] += velocity * delta
		smoke_puffs[index] = puff
	queue_redraw()


func _spawn_smoke() -> void:
	smoke_puffs.append({
		"position": Vector2(randf_range(-92.0, 92.0), -48.0),
		"velocity": Vector2(randf_range(-15.0, 15.0), randf_range(-58.0, -36.0) * lerpf(0.75, 1.35, visual_intensity)),
		"radius": randf_range(12.0, 22.0) * lerpf(0.8, 1.2, visual_intensity),
		"age": 0.0,
		"life": randf_range(1.15, 1.75),
		"wobble": randf_range(3.0, 6.0)
	})
	if smoke_puffs.size() > 26:
		smoke_puffs.pop_front()


func _draw() -> void:
	if visual_intensity > 0.01:
		_draw_ellipse(Vector2.ZERO, Vector2(205.0, 82.0) * lerpf(0.82, 1.08, visual_intensity), Color(1.0, 0.28, 0.06, 0.10 + visual_intensity * 0.18))
		_draw_ellipse(Vector2(0.0, -4.0), Vector2(145.0, 54.0), Color(1.0, 0.73, 0.10, 0.12 + visual_intensity * 0.24))
		for flame_index in 5:
			var x := lerpf(-100.0, 100.0, float(flame_index) / 4.0)
			var flicker := sin(Time.get_ticks_msec() * 0.009 + flame_index * 1.7) * 5.0
			draw_circle(Vector2(x, -37.0 + flicker), 8.0 + visual_intensity * 6.0, Color(1.0, 0.82, 0.18, 0.34 + visual_intensity * 0.35), true, -1.0, true)

	for puff in smoke_puffs:
		var progress: float = puff["age"] / puff["life"]
		var smoke_color := Color(0.20, 0.25, 0.27, (1.0 - progress) * (0.16 + visual_intensity * 0.24))
		var radius: float = puff["radius"] * lerpf(0.65, 1.55, progress)
		draw_circle(puff["position"], radius, smoke_color, true, -1.0, true)


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 32:
		var angle := TAU * float(index) / 32.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _on_preference_changed(preference: StringName, _value: Variant) -> void:
	if preference == &"poku_polish":
		_apply_polish_setting()


func _apply_polish_setting() -> void:
	visible = GameSettings.is_poku_polish_enabled()
	if not visible:
		smoke_puffs.clear()
		smoke_clock = 0.0
	queue_redraw()
