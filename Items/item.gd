extends RigidBody2D
#head script
var new_desired_angle := 0.0
#what you want as the desired angle of your rigid body.
#here its 0 to keep the head straight
var locked := false
var snap := false
var held := false
export var usable := true

export var indicator := true

export var sharp := false

var power := 600
signal done(item)

var done := false

var force := 1.0
var cooltime_wait := 0.0
var cooldown := false
var cooltime := 1.3

var impaled := false

var speed := 500 
onready var target_node: Node2D 


onready var pin = get_node("PinJoint2D")
onready var visual = get_node("Polygon2D")

	
var available := false

func _ready():
	if sharp:
		connect("body_entered", self, "_on_body_entered")
#
#func _input(event):
#	if event.is_action_pressed("snap"):
#		snap = true


func _physics_process(_delta):
	
	pin.position = Vector2(0,0)
	
	
	if cooldown == true and !impaled:
		cooltime_wait += _delta
		
		if cooltime_wait >= cooltime:
			cooldown = false
			cooltime_wait = 0
		
		elif cooltime_wait >= 0.05:
			set_collision_mask_bit(1, true)
#			visual.color = Color.black
	
	if locked:
		var current_angle = get_global_transform().get_rotation()
		var angle_difference = abs(fmod((current_angle - new_desired_angle + PI), (2*PI)) - PI)
		if angle_difference > deg2rad(2.5):  # Adjust this value to change the size of the dead zone
			angular_velocity = lerp_angle(current_angle, new_desired_angle, (power)* _delta)
		else:
			angular_velocity = 0


	if is_stationary() and pin.get_node_b()=="" and !cooldown and !impaled:
		available = true
		set_collision_mask_bit(1, false)
		mass = 0.01
		weight = 0.01
		
		if indicator:
			visual.color = Color.green
		
	elif indicator:
		visual.color = Color.red
			

	if snap and indicator:
		visual.color = Color.blue
#	if locked == true:
#		visual.color = Color.purple
		
	if snap and usable:
		if target_node:
			target_node.owner.grabbed_item = self
			available = false
			
			force += (0.1)
			# Calculate the target position
			var target_position = target_node.global_position

			# Calculate the direction to the target
			var direction = (target_position - pin.global_position).normalized()

			# Move towards the target
			print(force)
			linear_velocity = ((direction * speed) * force)
#			print(linear_velocity)
			
			print((pin.global_position - target_position).abs())
			var diff = (pin.global_position - target_position).abs()
			if diff.x < 6 and diff.y < 6:
#				pin.global_position = target_position

				global_position = target_position-pin.position
				pin.set_node_b((target_node.get_path()))
				
				
				snap = false
				
				force = 1
				grab()


				
				
		else:
			snap = false
			breakpoint
			linear_velocity = Vector2.ZERO





func grab():
	locked = true
	held = true
#	available = false
	friction = 1
	bounce = 0.0
	
func release():
	target_node.owner.grabbed_item = null
	target_node.owner.holding_something = false
	pin.set_node_b("")
	cooldown = true
	locked = false
	held = false
	friction = 1
	bounce = 0.3
	mass = 1
	weight = 9.8
	apply_central_impulse(Vector2(linear_velocity.x/800,0))
	
func is_stationary() -> bool:
#	print(linear_velocity.length())
	var linear_threshold = 500
	var angular_threshold = deg2rad(50)

	if linear_velocity.length() <= linear_threshold and angular_velocity <= angular_threshold:
		return true
	else:
		return false

func impale(body, colliding_point, direction):
	impaled = true
	locked = false
	
#	var penetration_vector = -self.linear_velocity.normalized() * 10
#	self.position -= direction*10

	var joint = PinJoint2D.new()
	joint.scale = Vector2(3,3)
	joint.disable_collision = true
	add_child(joint)
	joint.global_position = colliding_point
	joint.node_a = self.get_path()
	joint.node_b = body.get_path()
	joint.softness = 1
	
	
	var joint2 = PinJoint2D.new()
	joint2.scale = Vector2(3,3)
	joint2.disable_collision = true
	add_child(joint2)
	joint2.global_position = colliding_point-direction*40
	joint2.node_a = self.get_path()
	joint2.node_b = body.get_path()
	joint2.softness = 0


func _on_body_entered(body):
	if sharp and !available and !snap and !held:
		locked = false
		if body.is_in_group("stabb-able") and (target_node.owner != body.owner) and (target_node.owner != body):
			if !impaled:
				var result = Physics2DTestMotionResult.new()

				
				
				if !(body is StaticBody2D):
					set_collision_mask_bit(0, false)
				else:
					set_collision_mask_bit(0, true)
					
#					set_collision_layer_bit(0, true)
						
				
#				linear_velocity.x = linear_velocity.x/2


#				global_position -= offset
				
				var dist = 0
	
				if self.test_motion(Vector2(0,0), false, 0.01, result):
					impale(body, result.collision_point, result.collision_normal)
					emit_signal("done", self)
					done = true
					
				elif self.test_motion(Vector2(0,0), false, 10, result):
					impale(body, result.collision_point, result.collision_normal)
					emit_signal("done", self)
					done = true
					
				else:
					var offset = linear_velocity.normalized()
					var found = false
					while offset.length() <= 100 and found == false:
						offset *= 1.1
						if self.test_motion(-offset, false, 0.08, result):
							global_position -= offset
							impale(body, result.collision_point, result.collision_normal)
							emit_signal("done", self)
							found = true
							done = true
						elif self.test_motion(offset, false, 0.08, result):
							global_position += offset
							impale(body, result.collision_point, result.collision_normal)
							emit_signal("done", self)
							found = true
							done = true


				
				if (body is StaticBody2D):
#					set_collision_mask_bit(1, true)
					set_collision_layer_bit(1, true)
				else:
					if "Body" in body.name:
						body.stabbed(self)
					elif body.owner:
						if "Body" in body.owner.name:
							body.owner.stabbed(self)
					else:
						body.stabbed(self)
						
					set_collision_mask_bit(1, false)
					set_collision_layer_bit(1, false)
					
				
				set_collision_mask_bit(0, true)

#						set_collision_mask_bit(1, false)
				
				
#				if body.get_node("Panel"):
#					body.get_node("Panel").modulate = Color.red
#				elif body.get_node("Polygon2D"):
#					body.get_node("Polygon2D").modulate = Color.red
					
				
					
				
						


