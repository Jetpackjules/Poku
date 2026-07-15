extends Node2D

const SKY_TOP := Color(0.36, 0.72, 0.88)
const SKY_BOTTOM := Color(0.76, 0.94, 0.94)
const WORLD_LEFT := -2050.0
const WORLD_RIGHT := 2050.0
const WORLD_TOP := -1620.0
const WORLD_BOTTOM := 460.0
const CLOUDS := [
	{"position": Vector2(-1370, -1210), "size": Vector2(340, 105)},
	{"position": Vector2(1120, -1030), "size": Vector2(430, 125)},
	{"position": Vector2(-850, -590), "size": Vector2(250, 76)},
	{"position": Vector2(1420, -360), "size": Vector2(300, 90)},
	{"position": Vector2(410, -1375), "size": Vector2(230, 70)}
]

var tracked_planes: Array[RigidBody2D] = []
var animation_time := 0.0
var last_wind_intensities: Array[float] = []


func configure(planes: Array[RigidBody2D]) -> void:
	tracked_planes = planes


func _ready() -> void:
	name = "PlanesAtmosphere"
	z_index = -20
	_apply_visibility()
	if not GameSettings.preference_changed.is_connected(_on_preference_changed):
		GameSettings.preference_changed.connect(_on_preference_changed)
	queue_redraw()


func _process(delta: float) -> void:
	animation_time += delta
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	_draw_sky()
	_draw_clouds()
	_draw_updraft()
	_draw_plane_wind()


func _draw_sky() -> void:
	const BANDS := 24
	var band_height := (WORLD_BOTTOM - WORLD_TOP) / float(BANDS)
	for band in range(BANDS):
		var amount := float(band) / float(BANDS - 1)
		draw_rect(
			Rect2(WORLD_LEFT, WORLD_TOP + band * band_height, WORLD_RIGHT - WORLD_LEFT, band_height + 1.0),
			SKY_TOP.lerp(SKY_BOTTOM, amount),
			true
		)


func _draw_clouds() -> void:
	for cloud in CLOUDS:
		var center: Vector2 = cloud["position"]
		var size: Vector2 = cloud["size"]
		_draw_ellipse(center + Vector2(8, 11), size, Color(0.18, 0.48, 0.58, 0.10))
		_draw_ellipse(center, size, Color(1.0, 0.98, 0.94, 0.52))
		_draw_ellipse(center + Vector2(-size.x * 0.19, -size.y * 0.26), size * Vector2(0.45, 0.92), Color(1.0, 0.99, 0.96, 0.58))
		_draw_ellipse(center + Vector2(size.x * 0.17, -size.y * 0.20), size * Vector2(0.38, 0.78), Color(1.0, 0.99, 0.96, 0.54))


func _draw_updraft() -> void:
	_draw_ribbon(-48.0, 92.0, 0.0, Color(0.88, 0.98, 1.0, 0.12))
	_draw_ribbon(45.0, 74.0, 1.8, Color(0.72, 0.94, 1.0, 0.13))
	_draw_ribbon(0.0, 46.0, 3.4, Color(1.0, 1.0, 0.96, 0.17))
	for lane in range(5):
		var points := PackedVector2Array()
		for step in range(22):
			var progress := float(step) / 21.0
			var y := lerpf(230.0, -1500.0, progress)
			var sway := sin(animation_time * (1.1 + lane * 0.08) + progress * 8.0 + lane * 1.7) * (22.0 + lane * 5.0)
			points.append(Vector2((lane - 2) * 39.0 + sway, y))
		draw_polyline(points, Color(0.94, 0.99, 1.0, 0.22), 3.0, true)


func _draw_ribbon(center_x: float, width: float, phase: float, color: Color) -> void:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for step in range(25):
		var progress := float(step) / 24.0
		var y := lerpf(245.0, -1510.0, progress)
		var sway := sin(animation_time * 0.85 + progress * 7.5 + phase) * 34.0
		left.append(Vector2(center_x + sway - width * 0.5, y))
		right.append(Vector2(center_x + sway + width * 0.5, y))
	var polygon := PackedVector2Array(left)
	for index in range(right.size() - 1, -1, -1):
		polygon.append(right[index])
	draw_colored_polygon(polygon, color)


func _draw_plane_wind() -> void:
	last_wind_intensities.clear()
	for plane_index in range(tracked_planes.size()):
		var tracked := tracked_planes[plane_index]
		if not is_instance_valid(tracked):
			last_wind_intensities.append(0.0)
			continue
		var intensity := wind_intensity_for(tracked)
		last_wind_intensities.append(intensity)
		if intensity <= 0.01:
			continue
		for streak in range(8):
			var travel := fposmod(animation_time * (1.4 + intensity) + streak * 0.137 + plane_index * 0.31, 1.0)
			var x_offset := -270.0 + float((streak * 83 + plane_index * 41) % 540)
			var y_offset := -210.0 + travel * 420.0
			var length := 34.0 + intensity * 70.0 + float(streak % 3) * 8.0
			var start := tracked.global_position + Vector2(x_offset, y_offset)
			draw_line(start, start + Vector2(-tracked.linear_velocity.x * 0.035, length), Color(0.96, 1.0, 1.0, 0.16 + intensity * 0.36), 2.0 + intensity * 1.5, true)


func wind_intensity_for(plane: RigidBody2D) -> float:
	return clampf((-plane.linear_velocity.y - 45.0) / 380.0, 0.0, 1.0)


func _draw_ellipse(center: Vector2, size: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * size.x * 0.5, sin(angle) * size.y * 0.5))
	draw_colored_polygon(points, color)


func _apply_visibility() -> void:
	visible = GameSettings.is_poku_polish_enabled()
	set_process(visible)
	queue_redraw()


func _on_preference_changed(preference: StringName, _value: Variant) -> void:
	if preference == &"poku_polish":
		_apply_visibility()
