extends Node2D

## Shared presentation and round flow for Poku's game modes. Individual maps
## keep their strange physics; this only gives them a consistent objective,
## status display, and reliable ending.
@export var mode_title := "POKU"
@export_multiline var objective := ""
@export var uses_poku_players := true
@export var return_delay := 3.0

var round_over := false
var elapsed_time := 0.0
var _status_label: Label
var _announcement_label: Label
var _announcement_tween: Tween


func _ready() -> void:
	_build_hud()


func _process(delta: float) -> void:
	elapsed_time += delta


func set_status(value: String) -> void:
	if is_instance_valid(_status_label):
		_status_label.text = value


func announce(value: String, hold_seconds := 1.0) -> void:
	if not is_instance_valid(_announcement_label):
		return
	if _announcement_tween and _announcement_tween.is_valid():
		_announcement_tween.kill()
	_announcement_label.text = value
	_announcement_label.modulate = Color.WHITE
	_announcement_label.scale = Vector2(0.88, 0.88)
	_announcement_tween = create_tween().set_parallel(true)
	_announcement_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_announcement_tween.tween_property(_announcement_label, "scale", Vector2.ONE, 0.22)
	_announcement_tween.chain().tween_interval(hold_seconds)
	_announcement_tween.chain().tween_property(_announcement_label, "modulate:a", 0.0, 0.35)


func finish_side(side: int, message := "") -> void:
	finish_round(_player_on_side(side), message)


func finish_round(winner: Node, message := "") -> void:
	if round_over:
		return
	round_over = true
	for player in SceneSwitcher.get_players():
		player.controllable = false
		player.stop()
	if is_instance_valid(winner):
		winner.win(true)
	if message.is_empty():
		message = "ROUND COMPLETE!" if not is_instance_valid(winner) else "%s WINS!" % winner.name
	announce(message, maxf(1.2, return_delay - 0.5))
	if OS.get_environment("POKU_POLISH_TEST") == "1":
		return
	await get_tree().create_timer(return_delay).timeout
	if is_inside_tree() and SceneSwitcher.current_map == self:
		SceneSwitcher.change_map("Main_Menu")


func on_last_player_standing(winner: Node) -> void:
	finish_round(winner, "LAST POKU STANDING!")


func _player_on_side(side: int) -> Node:
	var players: Array = SceneSwitcher.get_players()
	if players.is_empty():
		return null
	var preferred: Node = null
	for player in players:
		if side < 0 and player.global_position.x < 0.0:
			preferred = player
		elif side > 0 and player.global_position.x >= 0.0:
			preferred = player
	if preferred == null:
		preferred = players[0 if side < 0 else mini(1, players.size() - 1)]
	return preferred


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ModeHUD"
	layer.layer = 20
	add_child(layer)

	var bar := ColorRect.new()
	bar.name = "TopBar"
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 64.0
	bar.color = Color(0.04, 0.06, 0.09, 0.56)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(bar)

	var title := Label.new()
	title.offset_left = 26.0
	title.offset_top = 10.0
	title.offset_right = 580.0
	title.offset_bottom = 54.0
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.78))
	title.text = mode_title
	bar.add_child(title)

	_status_label = Label.new()
	_status_label.name = "Status"
	_status_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_status_label.offset_left = -720.0
	_status_label.offset_top = 10.0
	_status_label.offset_right = -28.0
	_status_label.offset_bottom = 54.0
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.add_theme_font_size_override("font_size", 24)
	_status_label.add_theme_color_override("font_color", Color(0.62, 0.95, 0.78))
	bar.add_child(_status_label)

	_announcement_label = Label.new()
	_announcement_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_announcement_label.offset_left = -650.0
	_announcement_label.offset_top = 130.0
	_announcement_label.offset_right = 650.0
	_announcement_label.offset_bottom = 245.0
	_announcement_label.pivot_offset = Vector2(650.0, 57.5)
	_announcement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_announcement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_announcement_label.add_theme_font_size_override("font_size", 54)
	_announcement_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.35))
	_announcement_label.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.12))
	_announcement_label.add_theme_constant_override("outline_size", 12)
	_announcement_label.modulate.a = 0.0
	layer.add_child(_announcement_label)
