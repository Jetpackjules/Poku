extends "res://Maps/ModeController.gd"

const PLANES_ATMOSPHERE = preload("res://Maps/Planes/PlanesAtmosphere.gd")

@export var goal_y := -1125.0
@export var hold_to_win := 1.25

var left_hold := 0.0
var right_hold := 0.0
@onready var left_plane: RigidBody2D = $Turn_Brace2
@onready var right_plane: RigidBody2D = $Turn_Brace
@onready var left_plane_visual: Polygon2D = $Turn_Brace2/Plane/Polygon2D
@onready var right_plane_visual: Polygon2D = $Turn_Brace/Plane/Polygon2D
@onready var left_plane_panel: Panel = $Turn_Brace2/Plane/Panel
@onready var right_plane_panel: Panel = $Turn_Brace/Plane/Panel
@onready var updraft_particles: GPUParticles2D = $Updraft/GPUParticles2D

var atmosphere: Node2D
var _original_left_color := Color.WHITE
var _original_right_color := Color.WHITE
var _original_particle_amount := 0
var _original_particle_modulate := Color.WHITE
var _left_panel_style: StyleBoxFlat
var _right_panel_style: StyleBoxFlat
var _original_left_panel_color := Color.WHITE
var _original_right_panel_color := Color.WHITE


func _init() -> void:
	mode_title = "UPDRAFT PLANES"
	objective = "Shift your weight to steer into the center updraft, then ride it to the gold altitude. First plane to hold there wins."


func _ready() -> void:
	super._ready()
	_prepare_plane_visuals()
	_build_atmosphere()
	if not GameSettings.preference_changed.is_connected(_on_planes_preference_changed):
		GameSettings.preference_changed.connect(_on_planes_preference_changed)
	_apply_planes_polish()


func _prepare_plane_visuals() -> void:
	_original_left_color = left_plane_visual.color
	_original_right_color = right_plane_visual.color
	_original_particle_amount = updraft_particles.amount
	_original_particle_modulate = updraft_particles.modulate
	_left_panel_style = (left_plane_panel.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	_right_panel_style = (right_plane_panel.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	_original_left_panel_color = _left_panel_style.bg_color
	_original_right_panel_color = _right_panel_style.bg_color
	left_plane_panel.add_theme_stylebox_override("panel", _left_panel_style)
	right_plane_panel.add_theme_stylebox_override("panel", _right_panel_style)


func _build_atmosphere() -> void:
	atmosphere = PLANES_ATMOSPHERE.new()
	var tracked_planes: Array[RigidBody2D] = [left_plane, right_plane]
	atmosphere.configure(tracked_planes)
	add_child(atmosphere)
	move_child(atmosphere, 0)


func _apply_planes_polish() -> void:
	var polished := GameSettings.is_poku_polish_enabled()
	left_plane_visual.color = Color(0.24, 0.76, 0.16) if polished else _original_left_color
	right_plane_visual.color = Color(0.91, 0.16, 0.55) if polished else _original_right_color
	_left_panel_style.bg_color = Color(0.56, 0.91, 0.34) if polished else _original_left_panel_color
	_right_panel_style.bg_color = Color(1.0, 0.40, 0.72) if polished else _original_right_panel_color
	updraft_particles.amount = 132 if polished else _original_particle_amount
	updraft_particles.modulate = Color(0.82, 0.97, 1.0, 0.88) if polished else _original_particle_modulate
	if is_instance_valid(atmosphere):
		atmosphere.visible = polished
		atmosphere.set_process(polished)
		atmosphere.queue_redraw()


func _on_planes_preference_changed(preference: StringName, _value: Variant) -> void:
	if preference == &"poku_polish":
		_apply_planes_polish()


func _physics_process(delta: float) -> void:
	if round_over or not round_active:
		return
	left_hold = _updated_hold(left_plane, left_hold, delta)
	right_hold = _updated_hold(right_plane, right_hold, delta)
	set_status("P1 ALT %d  HOLD %.1f    |    P2 ALT %d  HOLD %.1f" % [
		maxi(0, int(-left_plane.global_position.y)), left_hold,
		maxi(0, int(-right_plane.global_position.y)), right_hold
	])
	if left_hold >= hold_to_win:
		finish_side(-1, "P1 RIDES THE UPDRAFT!")
	elif right_hold >= hold_to_win:
		finish_side(1, "P2 RIDES THE UPDRAFT!")


func _updated_hold(plane: RigidBody2D, current: float, delta: float) -> float:
	if plane.global_position.y <= goal_y:
		return minf(hold_to_win, current + delta)
	return maxf(0.0, current - delta)
