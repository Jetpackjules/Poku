extends Node2D

var failures: Array[String] = []
var observations := {}


func _ready() -> void:
	_remove_test_settings_file()
	GameSettings.reset_preferences(false, false)
	await _test_saved_preferences()
	await _test_physics_master_and_camera_feedback()
	await _test_landing_feedback()
	await _test_furnace_atmosphere()
	await _test_countdown_and_results()
	GameSettings.reset_preferences(false, false)
	Engine.max_fps = 0
	_remove_test_settings_file()
	print("POLISH_JSON:", JSON.stringify({
		"suite": "presentation_flow",
		"passed": failures.is_empty(),
		"failures": failures,
		"observations": observations
	}))
	get_tree().quit(0 if failures.is_empty() else 1)


func _test_saved_preferences() -> void:
	GameSettings.set_preference(&"fps_cap", 60)
	var config := ConfigFile.new()
	var load_error := config.load(GameSettings.settings_path())
	_expect(load_error == OK, "Persistent settings were not written to disk")
	_expect(config.get_value("preferences", "fps_cap", -1) == 60, "The saved FPS cap did not round-trip")
	_expect(Engine.max_fps == 60, "The FPS cap preference was not applied to the engine")
	GameSettings.set_preference(&"fps_cap", 0, false)
	var transition = (load("res://Menus/Transitions/Diamond_Transition.tscn") as PackedScene).instantiate()
	add_child(transition)
	await get_tree().process_frame
	_expect(transition.process_mode == Node.PROCESS_MODE_ALWAYS, "The map transition can still be stranded by the paused countdown")
	transition.queue_free()
	observations["settings_path"] = GameSettings.settings_path()


func _test_physics_master_and_camera_feedback() -> void:
	GameSettings.reset_experiments(false)
	GameSettings.reset_preferences(false, false)
	GameSettings.set_preference(&"fps_cap", 120, false)
	GameSettings.set_all_experiments_enabled(true)
	_expect(GameSettings.all_experiments_state() == &"on", "The Physics Lab master switch did not enable every experiment")
	_expect(GameSettings.get_preference(&"fps_cap") == 120, "The Physics Lab master switch changed the FPS cap")
	_expect(not bool(GameSettings.get_preference(&"fullscreen")), "The Physics Lab master switch changed display mode")
	GameSettings.set_all_experiments_enabled(false)
	_expect(GameSettings.all_experiments_state() == &"off", "The Physics Lab master switch did not disable every experiment")

	var camera := Camera2D.new()
	camera.name = "PlainCameraForFeedbackTest"
	add_child(camera)
	GameSettings.set_preference(&"camera_feedback", true, false)
	var accepted := CameraFeedback.shake_camera(camera, 0.12, 4.0)
	_expect(accepted and CameraFeedback.is_shaking(), "Central camera feedback rejected a plain Camera2D")
	CameraFeedback.stop()
	_expect(camera.offset == Vector2.ZERO, "Central camera feedback did not restore the camera offset")
	GameSettings.set_preference(&"camera_feedback", false, false)
	accepted = CameraFeedback.shake_camera(camera, 0.12, 4.0)
	_expect(not accepted and not CameraFeedback.is_shaking(), "The camera feedback toggle did not suppress shake")
	observations["camera_feedback_toggle"] = CameraFeedback.last_request.get("accepted", true)
	camera.queue_free()
	await get_tree().process_frame
	GameSettings.reset_experiments(false)
	GameSettings.reset_preferences(false, false)


func _test_landing_feedback() -> void:
	var player = (load("res://Player/Player.tscn") as PackedScene).instantiate()
	$Players.add_child(player)
	SceneSwitcher.current_map = self
	await get_tree().process_frame
	for part in player.body:
		part.freeze = true

	GameSettings.set_preference(&"poku_polish", true, false)
	GameSettings.set_preference(&"controller_rumble", true, false)
	var before := _landing_dust_count()
	player._emit_landing_feedback(620.0)
	_expect(_landing_dust_count() == before + 1, "A hard landing did not create a dust puff")
	_expect(not ControllerSupport.last_rumble_request.is_empty(), "A hard landing did not request restrained controller feedback")

	GameSettings.set_preference(&"poku_polish", false, false)
	before = _landing_dust_count()
	player._emit_landing_feedback(620.0)
	_expect(_landing_dust_count() == before, "The master visual switch did not disable landing dust")
	observations["landing_rumble"] = ControllerSupport.last_rumble_request.duplicate()
	player.queue_free()
	await get_tree().process_frame


func _test_furnace_atmosphere() -> void:
	var map = (load("res://Maps/Spaceship/Spaceship_Map.tscn") as PackedScene).instantiate()
	$MapSlot.add_child(map)
	SceneSwitcher.current_map = map
	await get_tree().process_frame
	var ship = map.get_node("Spaceship_Left")
	GameSettings.set_preference(&"poku_polish", true, false)
	ship.furnace_visuals.set_fuel(1.2)
	_expect(ship.furnace_visuals.visible, "Furnace atmosphere did not enable with Poku polish")
	_expect(is_equal_approx(ship.furnace_visuals.visual_intensity, 0.5), "Furnace glow intensity does not track actual fuel")
	GameSettings.set_preference(&"poku_polish", false, false)
	_expect(not ship.furnace_visuals.visible, "The master visual switch did not disable furnace atmosphere")
	observations["furnace_intensity_at_1_2_fuel"] = ship.furnace_visuals.visual_intensity
	map.queue_free()
	await get_tree().process_frame


func _test_countdown_and_results() -> void:
	GameSettings.set_preference(&"poku_polish", true, false)
	var map = (load("res://Maps/Basketball/Basketball_Map.tscn") as PackedScene).instantiate()
	map.countdown_step_time = 0.01
	SceneSwitcher.current_map = map
	SceneSwitcher.spawned_players = 0
	SceneSwitcher.living_players = 0
	SceneSwitcher.move_players()
	$MapSlot.add_child(map)
	await get_tree().process_frame
	map.round_active = false
	map.elapsed_time = 9.0
	map._arm_countdown()
	_expect(get_tree().paused, "The round intro did not freeze pre-round mode physics")
	_expect(map._countdown_overlay.visible, "The frozen round intro has no background screen")
	_expect(map._countdown_label.text == "GET READY", "The countdown background does not cover player arrival")
	_expect(map._countdown_label.get_theme_font_size("font_size") >= 190, "Countdown type is still tiny")
	var countdown_color: Color = map._countdown_label.get_theme_color("font_color")
	_expect(countdown_color.r > 0.9 and countdown_color.g > 0.9 and countdown_color.b > 0.8, "Countdown type is not warm white")
	await get_tree().create_timer(0.45, true).timeout
	_expect(is_equal_approx(map.elapsed_time, 9.0), "Gameplay time advanced while the round intro was frozen")
	await get_tree().create_timer(0.68, true).timeout
	_expect(map.countdown_sequence_log == ["3", "2", "1", "POKU!"], "Countdown did not run the exact 3-2-1-POKU sequence")
	_expect(map.round_active, "Controls/scoring did not activate after the countdown")
	_expect(not get_tree().paused, "The countdown left the game tree paused")
	_expect(map.elapsed_time < 0.25, "Round time did not reset when POKU began")
	await get_tree().create_timer(0.2, true).timeout
	_expect(not map._countdown_overlay.visible, "The countdown background did not clear after POKU")
	map.finish_round(null, "TEST ROUND COMPLETE")
	await get_tree().process_frame
	_expect(map.round_over, "Finishing a round did not lock the round")
	_expect(map.results_overlay.visible, "Finishing a round did not show the results screen")
	_expect(map.results_title_label.text == "TEST ROUND COMPLETE", "The results screen lost the round result")
	_expect(map.rematch_button != null and map.game_select_button != null and map.results_main_menu_button != null, "Results navigation is incomplete")
	var result_style := map._results_panel.get_theme_stylebox("panel") as StyleBoxFlat
	_expect(result_style != null and result_style.border_width_left == 0, "The polished results screen still uses a generic colored border")
	_expect(map._results_heading_label.text == "POKU!", "The results screen does not use the Poku title language")
	_expect(_inside_viewport(map._results_panel), "The results panel clips outside the Poku viewport")
	_expect(_inside_viewport(map.rematch_button) and _inside_viewport(map.game_select_button) and _inside_viewport(map.results_main_menu_button), "A results action clips outside the Poku viewport")
	_expect(map._scene_key() == "Basketball", "Rematch cannot resolve the current mode scene")

	GameSettings.set_preference(&"poku_polish", false, false)
	var top_bar: ColorRect = map.get_node("ModeHUD/TopBar")
	_expect(top_bar.color == Color(0.04, 0.06, 0.09, 0.56), "Disabling Poku polish did not restore the previous HUD color exactly")
	observations["countdown"] = map.countdown_sequence_log.duplicate()
	map.queue_free()
	await get_tree().process_frame


func _landing_dust_count() -> int:
	var count := 0
	for child in get_children():
		if child.name == "LandingDust":
			count += 1
	return count


func _remove_test_settings_file() -> void:
	var absolute_path := ProjectSettings.globalize_path(GameSettings.settings_path())
	if FileAccess.file_exists(GameSettings.settings_path()):
		DirAccess.remove_absolute(absolute_path)


func _inside_viewport(control: Control) -> bool:
	var rect := control.get_global_rect()
	var viewport_size := get_viewport().get_visible_rect().size
	return rect.position.x >= -0.5 and rect.position.y >= -0.5 and rect.end.x <= viewport_size.x + 0.5 and rect.end.y <= viewport_size.y + 0.5


func _expect(condition: bool, message: String) -> void:
	if not condition and message not in failures:
		failures.append(message)
