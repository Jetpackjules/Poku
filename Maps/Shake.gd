extends Camera2D

var shaking = false
var shake_duration = 0.0
var shake_timer = 0.0
var shake_strength = 0.0

var shake_tween: Tween

func tween_offset(target_offset: Vector2, duration: float, transition: Tween.TransitionType):
	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()
	shake_tween = create_tween().set_trans(transition)
	shake_tween.tween_property(self, "offset", target_offset, duration)

func shake(duration, strength):
	shaking = true
	shake_duration = duration
	shake_timer = duration
	shake_strength = strength

func _process(delta):
	if shaking:
		shake_timer -= delta
		if shake_timer <= 0:
			shaking = false
			tween_offset(Vector2(), 0.2, Tween.TRANS_BACK)
		else:
			var target_offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
			tween_offset(target_offset, 0.1, Tween.TRANS_LINEAR)
