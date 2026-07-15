extends "res://Maps/ModeController.gd"

## The Ostritch is its own experimental controllable ragdoll, so the standard
## two Poku players are parked while this playground is active.
var finish_x := 1120.0
var completed := false
var experimental_controller: Node
@onready var ostritch_controller: RigidBody2D = $Ostritch/Spine1


func _init() -> void:
	uses_poku_players = false
	mode_title = "OSTRITCH EXPERIMENT"
	objective = "Run and jump the physics ostritch to the gold finish marker."


func _ready() -> void:
	super._ready()
	set_status("FINISH  →")
	if not GameSettings.experiment_changed.is_connected(_on_experiment_changed):
		GameSettings.experiment_changed.connect(_on_experiment_changed)
	_apply_active_controller(GameSettings.is_enabled(&"ostritch_active_ragdoll"))


func _physics_process(_delta: float) -> void:
	if completed or not round_active:
		return
	var remaining := maxi(0, int(finish_x - ostritch_controller.global_position.x))
	set_status("%d px TO FINISH  →" % remaining)
	if ostritch_controller.global_position.x >= finish_x:
		completed = true
		finish_round(null, "OSTRITCH COURSE COMPLETE!")


func _exit_tree() -> void:
	super._exit_tree()
	if GameSettings.experiment_changed.is_connected(_on_experiment_changed):
		GameSettings.experiment_changed.disconnect(_on_experiment_changed)


func _on_experiment_changed(experiment: StringName, enabled: bool) -> void:
	if experiment == &"ostritch_active_ragdoll":
		_apply_active_controller(enabled)


func _apply_active_controller(enabled: bool) -> void:
	if enabled and not is_instance_valid(experimental_controller):
		experimental_controller = preload("res://Ostritch/ExperimentalActiveController.gd").new()
		experimental_controller.name = "ExperimentalActiveController"
		$Ostritch.add_child(experimental_controller)
		experimental_controller.setup($Ostritch)
		set_status("ACTIVE MOTOR  ·  FINISH →")
	elif not enabled and is_instance_valid(experimental_controller):
		experimental_controller.shutdown()
		experimental_controller = null
		set_status("CLASSIC  ·  FINISH →")
