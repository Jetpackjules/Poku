extends Control

const PLAYER_COLORS := [
	Color(0.25, 0.80, 0.17),
	Color(0.94, 0.18, 0.61),
	Color(0.10, 0.66, 0.91),
	Color(0.97, 0.62, 0.12)
]

var player_slot := 1
var device_id := 0


func _ready() -> void:
	custom_minimum_size = Vector2(104.0, 78.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(slot: int, connected_device: int, device_name := "") -> void:
	player_slot = slot
	device_id = connected_device
	name = "Controller%d" % slot
	tooltip_text = "%s detected" % (device_name if not device_name.is_empty() else "Controller %d" % slot)
	queue_redraw()


func _draw() -> void:
	var accent: Color = PLAYER_COLORS[(player_slot - 1) % PLAYER_COLORS.size()]
	var ink := Color(0.06, 0.20, 0.22)
	var warm_white := Color(1.0, 0.97, 0.91)
	var body := PackedVector2Array([
		Vector2(20, 15), Vector2(84, 15), Vector2(96, 43),
		Vector2(87, 55), Vector2(72, 44), Vector2(32, 44),
		Vector2(17, 55), Vector2(8, 43)
	])
	var shadow := PackedVector2Array()
	for point in body:
		shadow.append(point + Vector2(3, 4))
	draw_colored_polygon(shadow, Color(0.08, 0.28, 0.30, 0.28))
	draw_colored_polygon(body, accent)
	draw_polyline(PackedVector2Array(Array(body) + [body[0]]), ink, 3.0, true)

	# D-pad and face buttons keep the silhouette readable even at window scale.
	draw_rect(Rect2(25, 25, 18, 6), ink, true)
	draw_rect(Rect2(31, 19, 6, 18), ink, true)
	draw_circle(Vector2(72, 25), 4.0, warm_white)
	draw_circle(Vector2(82, 33), 4.0, warm_white)
	draw_circle(Vector2(72, 25), 4.0, ink, false, 2.0, true)
	draw_circle(Vector2(82, 33), 4.0, ink, false, 2.0, true)
	draw_circle(Vector2(90, 12), 5.0, Color(0.26, 0.90, 0.42))
	draw_circle(Vector2(90, 12), 5.0, ink, false, 2.0, true)

	var label := "P%d" % player_slot if player_slot <= 2 else "PAD %d" % player_slot
	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, 75),
		label,
		HORIZONTAL_ALIGNMENT_CENTER,
		104.0,
		19,
		ink
	)
