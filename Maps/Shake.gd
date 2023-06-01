extends Camera2D

var shaking = false
var shake_duration = 0.0
var shake_timer = 0.0
var shake_strength = 0.0

onready var tween = $Tween

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
			tween.interpolate_property(self, "offset", offset, Vector2(), 0.2, Tween.TRANS_BACK)
			tween.start()
		else:
			var target_offset = Vector2(rand_range(-shake_strength, shake_strength), rand_range(-shake_strength, shake_strength))
			tween.interpolate_property(self, "offset", offset, target_offset, 0.1, Tween.TRANS_LINEAR)
			tween.start()
