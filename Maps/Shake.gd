extends Camera2D

## Compatibility entry point for the original target-launcher camera. The
## CameraFeedback autoload now owns the motion so every map, including maps
## with a plain Camera2D, uses the same restrained implementation and toggle.
func shake(duration: float, strength: float) -> void:
	CameraFeedback.shake_camera(self, duration, strength)
