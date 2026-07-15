extends "res://Items/item.gd"

var _impact_cooldown := 0.0
var _base_scale := Vector2.ONE


func _ready() -> void:
	super._ready()
	_base_scale = scale
	contact_monitor = true
	max_contacts_reported = maxi(max_contacts_reported, 4)
	if not body_entered.is_connected(_on_ball_body_entered):
		body_entered.connect(_on_ball_body_entered)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_impact_cooldown = maxf(0.0, _impact_cooldown - delta)


func _on_ball_body_entered(_body: Node) -> void:
	if not GameSettings.is_enabled(&"ball_impacts") or _impact_cooldown > 0.0:
		return
	var impact_speed := linear_velocity.length()
	if impact_speed < 320.0:
		return
	_impact_cooldown = 0.12
	var burst := preload("res://Effects/ImpactBurst.gd").new()
	burst.global_position = global_position
	burst.intensity = clampf(impact_speed / 900.0, 0.55, 1.6)
	get_tree().current_scene.add_child(burst)
	var squash := Vector2(1.16, 0.84)
	if absf(linear_velocity.y) < absf(linear_velocity.x):
		squash = Vector2(0.84, 1.16)
	scale = _base_scale * squash
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", _base_scale, 0.22)
