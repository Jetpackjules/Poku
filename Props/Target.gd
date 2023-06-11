extends RigidBody2D

var impaled = false
var original_color
var bobbing_y

# Assuming these are the particles for the smoke and are children of the target.
onready var smoke_particles = $SmokeParticles2D 

# Assuming you have a timer named "BobbingTimer" to control the bobbing effect.
onready var bobbing_timer = $BobbingTimer

func _ready():
	original_color = self.modulate # Assuming the original color is the one set in the editor.
	smoke_particles.emitting = false
	bobbing_timer.start()
	self.gravity_scale = 0.0 # Float in place by disabling gravity
	bobbing_y = self.position.y


func stabbed(body):
	print("STABBED")
	self.modulate = Color(0.5, 0.5, 0.5) # Change color to grey
	self.gravity_scale = 0.5 # Fall down
	smoke_particles.emitting = true # Start smoking


func _on_BobbingTimer_timeout():
	# Restart the timer to keep the bobbing effect.
	bobbing_timer.start()
