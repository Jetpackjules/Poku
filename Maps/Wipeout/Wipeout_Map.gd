extends "res://Maps/ModeController.gd"


func _init() -> void:
	mode_title = "WIPEOUT"
	objective = "Thread the moving gaps. The walls accelerate and the openings shrink. Last Poku standing wins."


func _ready() -> void:
	super._ready()


func _process(delta: float) -> void:
	super._process(delta)
	if not round_over:
		set_status("SURVIVED  %.1fs    GAP  %d" % [elapsed_time, int($Wall_Spawner.current_gap_size())])
