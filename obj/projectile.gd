extends Node2D

#Default variable values
# --------------------------------------------------------------------------------------------
var sprPath = "res://resc/icon.png"
var sprSize = 1
var sprShape = 0
	#0 - rect
	#1 - round
var damage = 0
var posStart = Vector2.ZERO
var velocity = Vector2.ZERO
var acceleration = Vector2.ZERO
var maxVelocity = Vector2.ZERO
var effects = []
var type = 0
	#0 - linear path with initial velocity and accelereation
	#1 - parabolic
var duration = 10
	# how long projectile will stay in memory
# ----------- other options
var parabolic = false
var parabolic_half_duration = 0
var parabolic_scale_rate = 2
var posFinal = Vector2.ZERO

#spin projectile
var spin = false
var spin_rate = 0

var ignore_collision = false

var AoeBubble = false
var AoeBubbleSize = 32
var AoeBodies = []
# ---------------------------------------------------------------------------------------------
# Misc variables
var BODY_TYPE = "projectile"
var dataLoaded = false
var group = "" #will react to opposite group + neutral
	
var animation_finished = false
var curr_animation
var next_animation = ""
var death_anim = ""

var isProp = false
var queue_next = false		#mainly in ending animation, queue when finished
	
signal EntityHit(damage, effect)

func _ready():
	if posFinal != Vector2.ZERO:
		var d = posFinal - global_position
		velocity = (d/duration) - (0.5 * acceleration * duration)
	
	if maxVelocity == Vector2.ZERO:
		maxVelocity = velocity

	if AoeBubble:
		$AoeBubble/CollisionShape2D.shape.radius = AoeBubbleSize
	else:
		$AoeBubble/CollisionShape2D.shape.radius = 0
	
	if parabolic:
		parabolic_half_duration = float(duration)/2

func setData(data):
	if "sprSize" in data:
		sprSize = data["sprSize"]
	if "sprShape" in data:
		sprShape = data["sprShape"]
	if "damage" in data:
		damage = data["damage"]
	if "posStart" in data:
		posStart = data["posStart"]
	if "velocity" in data:
		velocity = data["velocity"]
	if "maxVelocity" in data:
		maxVelocity = data["maxVelocity"]
	if "acceleration" in data:
		acceleration = data["acceleration"]
	if "effects" in data:
		effects = data["effects"]
	if "type" in data:
		type = data["type"]
	if "posFinal" in data:
		posFinal = data["posFinal"]
	set_process(true)

func _process(delta):
	if !isProp:
		move(delta)
		timer(delta)
	
	if next_animation != "" and animation_finished:
		play(next_animation)
		next_animation = ""
		
	if spin:
		$AnimatedSprite.rotation_degrees += delta*spin_rate
		
	if parabolic:
		if duration > parabolic_half_duration:
			$AnimatedSprite.scale += delta * Vector2(parabolic_scale_rate, parabolic_scale_rate)
		else:
			$AnimatedSprite.scale -= delta * Vector2(parabolic_scale_rate, parabolic_scale_rate)
	
func move(delta):
	position += velocity * delta
	if velocity < maxVelocity:
		velocity += acceleration * delta
	else:
		velocity = maxVelocity

func timer(delta):
	duration -= delta
	if duration <= 0:
		if self in SkillHandler.projectiles:
			SkillHandler.projectiles.erase(self)
		if death_anim != "":
			set_process(false)
			play(death_anim)
			queue_next = true
		if AoeBubble:
			for body in AoeBodies:
				self.connect("EntityHit",body,"take_damage")
			emit_signal("EntityHit",damage, effects)

func getMidRange():
	return Vector2(posStart.x + .5 * (posFinal.x - posStart.x), posStart.y + .5 * (posFinal.y - posStart.y))

func play(anim):
	$AnimatedSprite.play(anim)
	animation_finished = false
	
	if AoeBubble:
		$AnimatedSprite.scale = Vector2(AoeBubbleSize/8,AoeBubbleSize/8)

func play_next(anim):
	next_animation = anim

func _on_CollisionShape_body_entered(body):
	if !isProp and !ignore_collision:
		var connected = true
		
		if body.has_method("take_damage"):
			var can_damage = false
			if group == "player":
				if body.is_in_group("enemy") or body.is_in_group("neutral"):
					can_damage = true
				else:
					connected = false
					
			if group == "enemy":
				if body.is_in_group("player") or body.is_in_group("neutral"):
					can_damage = true
				else:
					connected = false
					
			if can_damage:
				self.connect("EntityHit",body,"take_damage")
				emit_signal("EntityHit",damage, effects)
			
		if connected:
			if death_anim != "":
				set_process(false)
				play(death_anim)
				queue_next = true
			else:
				if self in SkillHandler.projectiles:
					SkillHandler.projectiles.erase(self)
				queue_free()

func _on_AnimatedSprite_animation_finished():
	animation_finished = true
	if queue_next:
		if self in SkillHandler.projectiles:
			SkillHandler.projectiles.erase(self)
		queue_free()

func _on_AoeBubble_body_entered(body):
	if AoeBubble:
		if group == "player" and !body.is_in_group("player"):
			AoeBodies.append(body)
		if group == "enemy" and !body.is_in_group("enemy"):
			AoeBodies.append(body)

func _on_AoeBubble_body_exited(body):
	if body in AoeBodies:
		AoeBodies.erase(body)
