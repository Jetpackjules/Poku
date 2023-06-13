extends RigidBody2D

var impaled = false
var original_color
var bobbing_y

var dead := false

var value := 1


onready var rotor_top = get_node("Rotor_Top")
onready var body = get_node("Target_Body")

# Assuming these are the particles for the smoke and are children of the target.
onready var smoke_particles = $SmokeParticles2D 

# Assuming you have a timer named "BobbingTimer" to control the bobbing effect.
onready var bobbing_timer = $BobbingTimer

var launch_force = 1500

func _ready():

#	linear_velocity.y = 1000
	apply_central_impulse(Vector2(0, -launch_force))
	rotor_top.angular_velocity = 100
	original_color = self.modulate # Assuming the original color is the one set in the editor.
	smoke_particles.emitting = false
	bobbing_timer.start()
	self.gravity_scale = 0.0 # Float in place by disabling gravity
	bobbing_y = self.position.y


func stabbed(body):
	if !dead:
		print("STABBED BY: ", body.target_node.owner)
		body.target_node.owner.emit_signal("increase_score", value)
		
		dead = true
		rotor_top.angular_damp = 2
		print("STABBED")
		self.modulate = Color(0.5, 0.5, 0.5) # Change color to grey
		self.gravity_scale = 0.5 # Fall down
		smoke_particles.emitting = true # Start smoking
		



func _on_BobbingTimer_timeout():
	# Restart the timer to keep the bobbing effect.
	bobbing_timer.start()
