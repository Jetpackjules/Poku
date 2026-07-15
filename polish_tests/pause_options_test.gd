extends Node

var failures: Array[String] = []


func _ready() -> void:
	GameSettings.reset_experiments(false)
	GameSettings.reset_preferences(false, false)
	var menu := (load("res://Maps/Main_Menu/Main_Menu_Map.tscn") as PackedScene).instantiate()
	$MapSlot.add_child(menu)
	SceneSwitcher.current_map = menu
	await get_tree().process_frame
	await get_tree().process_frame

	var start: Button = menu.get_node("MenuRoot/Main/CenterContainer/VBoxContainer/Start")
	var options: Button = menu.get_node("MenuRoot/Main/CenterContainer/VBoxContainer/Options")
	var menu_root = menu.get_node("MenuRoot")
	_expect(is_instance_valid(menu_root.controller_indicator_grid), "The main menu has no controller indicator area")
	ControllerSupport.controllers_changed.emit(2)
	await get_tree().process_frame
	_expect(menu_root.controller_indicator_grid.visible, "Detected controllers did not reveal the main-menu indicator")
	_expect(menu_root.controller_indicator_grid.get_child_count() == 2, "The main menu did not show one icon per detected controller")
	_expect(menu_root.controller_indicator_grid.get_child(0).name == "Controller1", "The first detected controller is not labeled P1")
	_expect(menu_root.controller_indicator_grid.get_child(1).name == "Controller2", "The second detected controller is not labeled P2")
	_expect(_inside_viewport(menu_root.controller_indicator_grid), "The controller indicators clip outside the main-menu viewport")
	ControllerSupport.controllers_changed.emit(ControllerSupport.connected_controller_count())
	await get_tree().process_frame
	_expect(start.has_focus(), "Start did not receive initial controller focus")
	_expect(start.get_theme_stylebox("focus") is StyleBoxEmpty, "Start still uses a rectangular focus highlight")
	_expect(
		start.get_theme_color("font_focus_color") == start.get_theme_color("font_color"),
		"Focused Start still changes to the wrong color"
	)
	_expect(start.get_theme_constant("outline_size") == 0, "Focused Start still uses the rejected bold outline")
	_expect(start.scale.x > 1.0, "Focused Start is missing its lightweight animated selection")
	var basketball_tile: BaseButton = menu.get_node("MenuRoot/Map_Select/CenterContainer/VBoxContainer/GridContainer/Basketball")
	_expect(not basketball_tile.has_node("PolishFrame"), "Game selection still has the rejected tile border")
	_expect(basketball_tile.get_node("PolishCaption").visible, "Poku polish did not give the image tile a readable caption")
	GameSettings.set_preference(&"poku_polish", false, false)
	_expect(not basketball_tile.get_node("PolishCaption").visible, "The master visual switch left a game caption over the original art")
	GameSettings.set_preference(&"poku_polish", true, false)

	options.emit_signal("pressed")
	await get_tree().process_frame
	_expect(PauseMenu.is_open(), "Options did not open the shared options screen")
	_expect(get_tree().paused, "Options did not pause the background scene")
	_expect(PauseMenu.title_label.text == "OPTIONS", "Main-menu Options opened with the wrong heading")
	_expect(PauseMenu.experiment_buttons.size() == 7, "The Physics Lab is missing experiment toggles")
	_expect(PauseMenu.preference_buttons.size() == 5, "The persistent Settings page is missing preferences")
	_expect(is_instance_valid(PauseMenu.all_changes_button), "Physics Lab is missing its master experiment switch")
	_expect(is_instance_valid(PauseMenu.controls_label), "Controls were not moved into Options")
	var pause_panel: PanelContainer = PauseMenu.overlay.get_node("PausePanel")
	_expect(pause_panel.size.x > 1700.0, "Pause/Options is still too narrow for the Poku viewport")
	_expect(PauseMenu.title_label.get_theme_font_size("font_size") >= 68, "Pause/Options title is still undersized")
	_expect(
		PauseMenu.experiment_buttons[&"throw_momentum"].custom_minimum_size.y >= 58.0,
		"Physics Lab toggles are still cramped"
	)
	var panel_style := pause_panel.get_theme_stylebox("panel") as StyleBoxFlat
	_expect(panel_style != null and panel_style.bg_color.g > 0.8, "Pause/Options did not adopt the bright Poku palette")
	var toggle_focus := PauseMenu.experiment_buttons[&"throw_momentum"].get_theme_stylebox("focus") as StyleBoxFlat
	_expect(toggle_focus != null and toggle_focus.border_width_left <= 3, "Physics Lab selection still uses heavy bolding")
	_expect(PauseMenu.settings_page.visible and not PauseMenu.controls_page.visible and not PauseMenu.lab_page.visible, "Main-menu Options did not open on Settings")
	_expect(_inside_viewport(PauseMenu.controls_tab), "Controls section tab clips outside the viewport")
	_expect(_inside_viewport(PauseMenu.settings_tab), "Settings section tab clips outside the viewport")
	_expect(_inside_viewport(PauseMenu.lab_tab), "Physics Lab section tab clips outside the viewport")
	_expect(_inside_viewport(PauseMenu.settings_page), "Persistent settings page clips outside the viewport: %s" % PauseMenu.settings_page.get_global_rect())
	_expect(_inside_control(PauseMenu.settings_page.find_child("SettingsContent", true, false), PauseMenu.settings_page), "Settings content is larger than its visible page")
	_expect(not PauseMenu.settings_page.is_ancestor_of(PauseMenu.all_changes_button), "The experiment master switch is still in base Settings")
	_expect(PauseMenu.lab_page.is_ancestor_of(PauseMenu.all_changes_button), "The experiment master switch is not inside Physics Lab")
	for button in PauseMenu.preference_buttons.values():
		_expect(_inside_control(button, PauseMenu.settings_page), "Persistent setting %s clips outside Settings: %s" % [button.name, button.get_global_rect()])
	_expect(GameSettings.all_experiments_state() == &"off", "Physics experiments did not begin fully off")
	GameSettings.set_preference(&"fps_cap", 120, false)
	GameSettings.set_preference(&"poku_polish", false, false)
	PauseMenu._on_all_changes_pressed()
	_expect(GameSettings.all_experiments_state() == &"on", "The Physics Lab master switch did not enable every experiment")
	for definition in GameSettings.definitions():
		_expect(GameSettings.is_enabled(definition["id"]), "The master switch left a Physics Lab experiment disabled")
	_expect(GameSettings.get_preference(&"fps_cap") == 120, "The Physics Lab master switch changed the FPS cap")
	_expect(not bool(GameSettings.get_preference(&"poku_polish")), "The Physics Lab master switch changed visual polish")
	_expect(not bool(GameSettings.get_preference(&"fullscreen")), "The Physics Lab master switch changed display mode")
	PauseMenu._on_all_changes_pressed()
	_expect(GameSettings.all_experiments_state() == &"off", "The Physics Lab master switch did not disable every experiment")
	GameSettings.reset_experiments(false)
	GameSettings.reset_preferences(false, false)
	PauseMenu._sync_experiment_buttons()
	PauseMenu._sync_preference_buttons()

	PauseMenu._show_page(&"controls")
	await get_tree().process_frame
	_expect(PauseMenu.controls_page.visible and not PauseMenu.settings_page.visible, "Controls section did not replace Settings")
	_expect(_inside_viewport(PauseMenu.controls_page), "Controls settings page clips outside the viewport")
	_expect(_inside_control(PauseMenu.controls_page.find_child("ControlsContent", true, false), PauseMenu.controls_page), "Controls content is larger than its visible page")
	_expect(_inside_control(PauseMenu.p1_controls_label, PauseMenu.controls_page), "Player 1 control text overflows its settings page")
	_expect(_inside_control(PauseMenu.p2_controls_label, PauseMenu.controls_page), "Player 2 control text overflows its settings page")
	_expect(_inside_control(PauseMenu.controls_label, PauseMenu.controls_page), "Pause control text overflows its settings page")
	_expect(_multiline_text_fits(PauseMenu.p1_controls_label), "Player 1 control text is clipped inside its label")
	_expect(_multiline_text_fits(PauseMenu.p2_controls_label), "Player 2 control text is clipped inside its label")
	_expect(PauseMenu.p1_controls_label.get_theme_font("font") == PauseMenu.BODY_FONT, "Player 1 controls reused the vertically padded menu font")
	_expect(PauseMenu.p2_controls_label.get_theme_font("font") == PauseMenu.BODY_FONT, "Player 2 controls reused the vertically padded menu font")
	_expect(PauseMenu.p1_controls_label.text.count("\n") <= 7, "Player 1 controls grew too tall for its card")
	_expect(PauseMenu.p2_controls_label.text.count("\n") <= 7, "Player 2 controls grew too tall for its card")
	_expect(_inside_viewport(PauseMenu.resume_button), "Bottom action row clips outside the viewport")

	PauseMenu._show_page(&"lab")
	await get_tree().process_frame
	_expect(PauseMenu.lab_page.visible and not PauseMenu.controls_page.visible, "Physics Lab section did not replace Controls")
	_expect(_inside_viewport(PauseMenu.lab_page), "Physics Lab settings page clips outside the viewport")
	_expect(_inside_control(PauseMenu.lab_page.find_child("PhysicsLabContent", true, false), PauseMenu.lab_page), "Physics Lab content is larger than its visible page")
	_expect(_inside_control(PauseMenu.all_changes_button, PauseMenu.lab_page), "The Physics Lab master switch clips outside its page")
	_expect(PauseMenu.all_changes_button.get_global_rect().position.y < PauseMenu.experiment_buttons[&"throw_momentum"].get_global_rect().position.y, "The Physics Lab master switch is not at the top of the lab")
	PauseMenu.all_changes_button.grab_focus()
	await get_tree().process_frame
	_expect(PauseMenu.all_changes_button.scale.is_equal_approx(Vector2.ONE), "The Physics Lab master switch moves or scales when selected")
	for button in PauseMenu.experiment_buttons.values():
		_expect(_inside_control(button, PauseMenu.lab_page), "A Physics Lab setting clips outside its page")
	_expect(_inside_viewport(PauseMenu.reset_button), "Reset Lab clips outside the viewport")

	var throw_toggle: Button = PauseMenu.experiment_buttons[&"throw_momentum"]
	throw_toggle.toggled.emit(true)
	_expect(GameSettings.is_enabled(&"throw_momentum"), "A Physics Lab toggle did not update shared settings")
	PauseMenu._on_reset_pressed()
	_expect(not GameSettings.is_enabled(&"throw_momentum"), "Reset Lab did not return experiments to Classic")
	PauseMenu.close()
	_expect(not get_tree().paused, "Closing Options left the game tree paused")

	menu.queue_free()
	await get_tree().process_frame
	var map := (load("res://Maps/Basketball/Basketball_Map.tscn") as PackedScene).instantiate()
	$MapSlot.add_child(map)
	SceneSwitcher.current_map = map
	await get_tree().process_frame
	var hud := map.get_node("ModeHUD")
	_expect(not hud.has_node("Controls"), "Always-on gameplay control instructions still exist")
	_expect(not hud.get_node("TopBar").has_node("Objective"), "The objective is still occupying the gameplay HUD")
	_expect(hud.get_node("TopBar").size.y <= 65.0, "The compact status bar grew back into the old large text panel")

	PauseMenu.open_pause()
	_expect(PauseMenu.is_open() and get_tree().paused, "Pause did not stop gameplay")
	_expect("BASKETBALL" in PauseMenu.mode_context_label.text, "Pause did not show the current mode objective")
	PauseMenu.close()
	GameSettings.reset_experiments(false)
	GameSettings.reset_preferences(false, false)

	print("POLISH_JSON:", JSON.stringify({
		"suite": "pause_options",
		"passed": failures.is_empty(),
		"failures": failures
	}))
	get_tree().quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition and message not in failures:
		failures.append(message)


func _inside_viewport(control: Control) -> bool:
	var rect := control.get_global_rect()
	var viewport_size := get_viewport().get_visible_rect().size
	return (
		rect.position.x >= -0.5
		and rect.position.y >= -0.5
		and rect.end.x <= viewport_size.x + 0.5
		and rect.end.y <= viewport_size.y + 0.5
	)


func _inside_control(child: Control, parent: Control) -> bool:
	var child_rect := child.get_global_rect()
	var parent_rect := parent.get_global_rect()
	return (
		child_rect.position.x >= parent_rect.position.x - 0.5
		and child_rect.position.y >= parent_rect.position.y - 0.5
		and child_rect.end.x <= parent_rect.end.x + 0.5
		and child_rect.end.y <= parent_rect.end.y + 0.5
	)


func _multiline_text_fits(label: Label) -> bool:
	var font := label.get_theme_font("font")
	var line_count := label.text.count("\n") + 1
	return font.get_height(label.get_theme_font_size("font_size")) * line_count <= label.size.y + 0.5
