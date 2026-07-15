extends Node2D

const OPTION_FONT = preload("res://fonts/Menu_Fonts/Option_font.tres")
const TITLE_FONT = preload("res://fonts/Menu_Fonts/Title_Font.tres")
const BODY_FONT = preload("res://fonts/kirifont/KiriFont.otf")

## Shared presentation and round flow for Poku's game modes. Individual maps
## keep their strange physics; this only gives them a consistent objective,
## status display, and reliable ending.
@export var mode_title := "POKU"
@export_multiline var objective := ""
@export var uses_poku_players := true
@export var return_delay := 3.0
@export var countdown_enabled := true
@export var countdown_step_time := 0.58

var round_over := false
var round_active := false
var elapsed_time := 0.0
var countdown_running := false
var countdown_sequence_log: Array[String] = []
var _countdown_owns_pause := false
var _status_label: Label
var _announcement_label: Label
var _countdown_overlay: Control
var _countdown_backdrop: ColorRect
var _countdown_card: Panel
var _countdown_label: Label
var _countdown_tween: Tween
var _title_label: Label
var _top_bar: ColorRect
var _hud_accent: ColorRect
var _announcement_tween: Tween
var results_overlay: Control
var results_title_label: Label
var results_detail_label: Label
var rematch_button: Button
var game_select_button: Button
var results_main_menu_button: Button
var _results_panel: PanelContainer
var _results_dim: ColorRect
var _results_heading_label: Label
var _results_focus_tweens := {}


func _ready() -> void:
	_build_hud()
	if not GameSettings.preference_changed.is_connected(_on_preference_changed):
		GameSettings.preference_changed.connect(_on_preference_changed)
	_apply_visual_style()
	if not countdown_enabled or OS.get_environment("POKU_POLISH_TEST") == "1":
		round_active = true
	else:
		_arm_countdown()


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
	if round_over or not round_active:
		return
	round_over = true
	round_active = false
	for player in SceneSwitcher.get_players():
		player.controllable = false
		player.stop()
	if is_instance_valid(winner):
		winner.win(true)
	ControllerSupport.rumble_for_action(&"wasd_spin", 0.10, 0.26, 0.16)
	ControllerSupport.rumble_for_action(&"arrow_spin", 0.10, 0.26, 0.16)
	CameraFeedback.impact(CameraFeedback.Impact.HEAVY, self)
	if message.is_empty():
		message = "ROUND COMPLETE!" if not is_instance_valid(winner) else "%s WINS!" % winner.name
	announce(message, 0.85)
	_show_results(message)


func on_last_player_standing(winner: Node) -> void:
	if round_active:
		finish_round(winner, "LAST POKU STANDING!")


func start_countdown(step_time := -1.0) -> void:
	if countdown_running or round_over or not countdown_enabled:
		return
	countdown_running = true
	round_active = false
	SceneSwitcher.start = false
	_set_players_controllable(false)
	_acquire_countdown_pause()
	var duration := countdown_step_time if step_time < 0.0 else step_time
	for step in ["3", "2", "1", "POKU!"]:
		countdown_sequence_log.append(step)
		_show_countdown_step(step)
		await get_tree().create_timer(duration, true, false, true).timeout
		if not is_inside_tree() or round_over:
			return
	countdown_running = false
	elapsed_time = 0.0
	round_active = true
	SceneSwitcher.start = true
	_set_players_controllable(true)
	_release_countdown_pause()
	_hide_countdown_overlay()


func _arm_countdown() -> void:
	# Freeze the entire mode as soon as it enters the tree. SceneSwitcher's
	# player-arrival tweens explicitly continue while paused, so balls, walls,
	# timers, fuel, and score zones all begin from a clean 3-2-1 state.
	_acquire_countdown_pause()
	_show_countdown_step("GET READY")
	if uses_poku_players:
		if not SceneSwitcher.players_moved.is_connected(_on_players_moved):
			SceneSwitcher.players_moved.connect(_on_players_moved)
	else:
		start_countdown()


func _on_players_moved() -> void:
	if SceneSwitcher.current_map == self:
		start_countdown()


func _set_players_controllable(enabled: bool) -> void:
	if not uses_poku_players:
		return
	for player in SceneSwitcher.get_players():
		player.controllable = enabled
		if not enabled:
			player.stop()


func _show_countdown_step(value: String) -> void:
	if _countdown_tween and _countdown_tween.is_valid():
		_countdown_tween.kill()
	_countdown_overlay.visible = true
	_countdown_overlay.modulate = Color.WHITE
	_countdown_label.text = value
	_countdown_label.add_theme_font_size_override("font_size", 196 if value in ["GET READY", "POKU!"] else 270)
	_countdown_label.modulate = Color.WHITE
	_countdown_label.scale = Vector2(0.48, 0.48)
	_countdown_label.rotation = deg_to_rad(randf_range(-2.0, 2.0))
	_countdown_tween = create_tween().set_parallel(true)
	_countdown_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_countdown_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_countdown_tween.tween_property(_countdown_label, "scale", Vector2.ONE, 0.24)
	_countdown_tween.tween_property(_countdown_label, "rotation", 0.0, 0.18)
	_countdown_tween.chain().tween_property(_countdown_label, "modulate:a", 0.16, 0.16)


func _hide_countdown_overlay() -> void:
	if _countdown_tween and _countdown_tween.is_valid():
		_countdown_tween.kill()
	_countdown_tween = create_tween()
	_countdown_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_countdown_tween.tween_property(_countdown_overlay, "modulate:a", 0.0, 0.18)
	_countdown_tween.finished.connect(_finish_countdown_hide)


func _finish_countdown_hide() -> void:
	if is_instance_valid(_countdown_overlay):
		_countdown_overlay.visible = false
		_countdown_overlay.modulate = Color.WHITE


func _release_countdown_pause() -> void:
	if _countdown_owns_pause:
		_countdown_owns_pause = false
		get_tree().paused = false


func _acquire_countdown_pause() -> void:
	if not get_tree().paused:
		get_tree().paused = true
		_countdown_owns_pause = true


func _exit_tree() -> void:
	_release_countdown_pause()


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

	_top_bar = ColorRect.new()
	_top_bar.name = "TopBar"
	_top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_top_bar.offset_bottom = 64.0
	_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_top_bar)

	_hud_accent = ColorRect.new()
	_hud_accent.name = "PokuAccent"
	_hud_accent.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hud_accent.offset_top = -6.0
	_hud_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_bar.add_child(_hud_accent)

	_title_label = Label.new()
	_title_label.offset_left = 26.0
	_title_label.offset_top = 10.0
	_title_label.offset_right = 580.0
	_title_label.offset_bottom = 54.0
	_title_label.add_theme_font_size_override("font_size", 26)
	_title_label.text = mode_title
	_top_bar.add_child(_title_label)

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
	_top_bar.add_child(_status_label)

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

	_build_countdown(layer)
	_build_results(layer)


func _build_countdown(layer: CanvasLayer) -> void:
	_countdown_overlay = Control.new()
	_countdown_overlay.name = "CountdownOverlay"
	_countdown_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_countdown_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_countdown_overlay.visible = false
	layer.add_child(_countdown_overlay)

	_countdown_backdrop = ColorRect.new()
	_countdown_backdrop.name = "Backdrop"
	_countdown_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_countdown_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_countdown_overlay.add_child(_countdown_backdrop)

	_countdown_card = Panel.new()
	_countdown_card.name = "SoftCenter"
	_countdown_card.anchor_left = 0.15
	_countdown_card.anchor_top = 0.24
	_countdown_card.anchor_right = 0.85
	_countdown_card.anchor_bottom = 0.76
	_countdown_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_countdown_overlay.add_child(_countdown_card)

	_countdown_label = Label.new()
	_countdown_label.name = "CountdownText"
	_countdown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_countdown_label.pivot_offset = Vector2(960.0, 540.0)
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown_label.add_theme_font_override("font", TITLE_FONT)
	_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.97, 0.91))
	_countdown_label.add_theme_color_override("font_shadow_color", Color(0.13, 0.39, 0.41, 0.72))
	_countdown_label.add_theme_constant_override("shadow_offset_x", 12)
	_countdown_label.add_theme_constant_override("shadow_offset_y", 14)
	_countdown_overlay.add_child(_countdown_label)


func _build_results(layer: CanvasLayer) -> void:
	results_overlay = Control.new()
	results_overlay.name = "ResultsOverlay"
	results_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	results_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	results_overlay.visible = false
	layer.add_child(results_overlay)

	_results_dim = ColorRect.new()
	_results_dim.name = "Dim"
	_results_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_results_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	results_overlay.add_child(_results_dim)

	_results_panel = PanelContainer.new()
	_results_panel.name = "ResultsPanel"
	_results_panel.anchor_left = 0.15
	_results_panel.anchor_top = 0.16
	_results_panel.anchor_right = 0.85
	_results_panel.anchor_bottom = 0.84
	results_overlay.add_child(_results_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 72)
	margin.add_theme_constant_override("margin_right", 72)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 36)
	_results_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	_results_heading_label = Label.new()
	_results_heading_label.text = "POKU!"
	_results_heading_label.custom_minimum_size.y = 126.0
	_results_heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_results_heading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_results_heading_label.add_theme_font_override("font", TITLE_FONT)
	_results_heading_label.add_theme_font_size_override("font_size", 104)
	_results_heading_label.add_theme_color_override("font_color", Color(1.0, 0.66, 0.70))
	layout.add_child(_results_heading_label)

	results_title_label = Label.new()
	results_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	results_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	results_title_label.add_theme_font_override("font", OPTION_FONT)
	results_title_label.custom_minimum_size.y = 106.0
	results_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	results_title_label.add_theme_font_size_override("font_size", 68)
	results_title_label.add_theme_color_override("font_color", Color(0.94, 0.20, 0.55))
	layout.add_child(results_title_label)

	results_detail_label = Label.new()
	results_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	results_detail_label.add_theme_font_override("font", BODY_FONT)
	results_detail_label.add_theme_font_size_override("font_size", 28)
	results_detail_label.add_theme_color_override("font_color", Color(0.08, 0.26, 0.28))
	layout.add_child(results_detail_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 26)
	layout.add_child(actions)

	rematch_button = _results_button("REMATCH", Color(0.18, 0.74, 0.30))
	rematch_button.pressed.connect(_on_rematch_pressed)
	actions.add_child(rematch_button)
	game_select_button = _results_button("GAME SELECT", Color(0.56, 0.31, 0.92))
	game_select_button.pressed.connect(_on_game_select_pressed)
	actions.add_child(game_select_button)
	results_main_menu_button = _results_button("MAIN MENU", Color(0.94, 0.25, 0.52))
	results_main_menu_button.pressed.connect(_on_results_main_menu_pressed)
	actions.add_child(results_main_menu_button)


func _results_button(text: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(290.0, 90.0)
	button.flat = true
	button.add_theme_font_override("font", OPTION_FONT)
	button.add_theme_font_size_override("font_size", 36)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color.lightened(0.12))
	button.add_theme_color_override("font_focus_color", color)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.focus_entered.connect(_animate_results_focus.bind(button, true))
	button.focus_exited.connect(_animate_results_focus.bind(button, false))
	return button


func _animate_results_focus(button: Button, focused: bool) -> void:
	button.pivot_offset = button.size * 0.5
	if _results_focus_tweens.has(button) and _results_focus_tweens[button].is_valid():
		_results_focus_tweens[button].kill()
	if focused:
		button.add_theme_color_override("font_shadow_color", Color(0.08, 0.25, 0.27, 0.36))
		button.add_theme_constant_override("shadow_offset_x", 4)
		button.add_theme_constant_override("shadow_offset_y", 5)
	else:
		button.remove_theme_color_override("font_shadow_color")
		button.remove_theme_constant_override("shadow_offset_x")
		button.remove_theme_constant_override("shadow_offset_y")
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK if focused else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.05, 1.05) if focused else Vector2.ONE, 0.14)
	_results_focus_tweens[button] = tween


func _show_results(message: String) -> void:
	results_title_label.text = message
	if message.begins_with("P1"):
		results_title_label.add_theme_color_override("font_color", Color(0.16, 0.72, 0.28))
	elif message.begins_with("P2"):
		results_title_label.add_theme_color_override("font_color", Color(0.94, 0.20, 0.55))
	else:
		results_title_label.add_theme_color_override("font_color", Color(0.58, 0.31, 0.92))
	results_detail_label.text = "%s  ·  %.1f SECONDS" % [mode_title, elapsed_time]
	results_overlay.visible = true
	results_overlay.modulate.a = 0.0
	_results_panel.scale = Vector2(0.88, 0.88)
	_results_panel.rotation = deg_to_rad(0.8)
	_results_panel.pivot_offset = _results_panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(results_overlay, "modulate:a", 1.0, 0.22)
	tween.tween_property(_results_panel, "scale", Vector2.ONE, 0.28)
	tween.tween_property(_results_panel, "rotation", 0.0, 0.24)
	rematch_button.call_deferred("grab_focus")


func _on_rematch_pressed() -> void:
	SceneSwitcher.change_map(_scene_key())


func _on_game_select_pressed() -> void:
	SceneSwitcher.change_to_game_select()


func _on_results_main_menu_pressed() -> void:
	SceneSwitcher.change_map("Main_Menu")


func _scene_key() -> String:
	var basename := scene_file_path.get_file().trim_suffix(".tscn")
	return basename.trim_suffix("_Map")


func _on_preference_changed(preference: StringName, _value: Variant) -> void:
	if preference == &"poku_polish":
		_apply_visual_style()


func _apply_visual_style() -> void:
	if not is_instance_valid(_top_bar):
		return
	var polished := GameSettings.is_poku_polish_enabled()
	_top_bar.color = Color(0.55, 0.90, 0.92, 0.88) if polished else Color(0.04, 0.06, 0.09, 0.56)
	_hud_accent.visible = polished
	_hud_accent.color = Color(1.0, 0.66, 0.70, 0.82)
	_countdown_backdrop.color = Color(0.035, 0.18, 0.20, 0.74) if polished else Color(0.02, 0.03, 0.04, 0.72)
	var countdown_card_style := StyleBoxFlat.new()
	countdown_card_style.bg_color = Color(0.62, 0.90, 0.92, 0.20) if polished else Color(1.0, 1.0, 1.0, 0.06)
	countdown_card_style.set_corner_radius_all(110)
	countdown_card_style.shadow_color = Color(0.02, 0.11, 0.13, 0.20)
	countdown_card_style.shadow_size = 24
	_countdown_card.add_theme_stylebox_override("panel", countdown_card_style)
	_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.97, 0.91))
	_countdown_label.add_theme_color_override("font_shadow_color", Color(0.20, 0.48, 0.50, 0.74) if polished else Color(0.0, 0.0, 0.0, 0.72))
	if polished:
		_title_label.add_theme_font_override("font", OPTION_FONT)
		_status_label.add_theme_font_override("font", OPTION_FONT)
		_title_label.add_theme_color_override("font_color", Color(0.93, 0.20, 0.49))
		_status_label.add_theme_color_override("font_color", Color(0.10, 0.49, 0.22))
		_title_label.add_theme_color_override("font_shadow_color", Color(0.08, 0.30, 0.31, 0.32))
		_title_label.add_theme_constant_override("shadow_offset_x", 3)
		_title_label.add_theme_constant_override("shadow_offset_y", 4)
	else:
		_title_label.remove_theme_font_override("font")
		_status_label.remove_theme_font_override("font")
		_title_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.78))
		_status_label.add_theme_color_override("font_color", Color(0.62, 0.95, 0.78))
		_title_label.remove_theme_color_override("font_shadow_color")
		_title_label.remove_theme_constant_override("shadow_offset_x")
		_title_label.remove_theme_constant_override("shadow_offset_y")

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.615686, 0.901961, 0.921569, 0.97) if polished else Color(0.05, 0.08, 0.13, 0.97)
	panel_style.border_color = Color.TRANSPARENT if polished else Color(0.22, 0.30, 0.38, 1.0)
	panel_style.set_border_width_all(0 if polished else 2)
	panel_style.set_corner_radius_all(62 if polished else 10)
	panel_style.shadow_color = Color(0.04, 0.15, 0.17, 0.46)
	panel_style.shadow_size = 20 if polished else 8
	panel_style.shadow_offset = Vector2(10.0, 14.0) if polished else Vector2(4.0, 5.0)
	_results_panel.add_theme_stylebox_override("panel", panel_style)
	_results_dim.color = Color(0.025, 0.16, 0.18, 0.58) if polished else Color(0.02, 0.10, 0.12, 0.62)
	if polished:
		_results_heading_label.add_theme_color_override("font_shadow_color", Color(0.31, 0.52, 0.54, 0.76))
		_results_heading_label.add_theme_constant_override("shadow_offset_x", 8)
		_results_heading_label.add_theme_constant_override("shadow_offset_y", 9)
		results_title_label.add_theme_color_override("font_shadow_color", Color(0.12, 0.37, 0.39, 0.25))
		results_title_label.add_theme_constant_override("shadow_offset_x", 5)
		results_title_label.add_theme_constant_override("shadow_offset_y", 6)
		results_detail_label.add_theme_color_override("font_color", Color(0.07, 0.25, 0.27))
	else:
		_results_heading_label.remove_theme_color_override("font_shadow_color")
		_results_heading_label.remove_theme_constant_override("shadow_offset_x")
		_results_heading_label.remove_theme_constant_override("shadow_offset_y")
		results_title_label.remove_theme_color_override("font_shadow_color")
		results_title_label.remove_theme_constant_override("shadow_offset_x")
		results_title_label.remove_theme_constant_override("shadow_offset_y")
		results_detail_label.add_theme_color_override("font_color", Color(0.90, 0.94, 0.95))
