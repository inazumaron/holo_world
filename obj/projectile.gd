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
# ----------- parabolic extra vars
var posFinal = Vector2.ZERO

# ---------------------------------------------------------------------------------------------
# Misc variables
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
	pass
	#if !isProp:
		#set_process(false)

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !isProp:
		move(delta)
		timer(delta)
	
	if next_animation != "" and animation_finished:
		play(next_animation)
		next_animation = ""
	
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
		queue_free()

func getMidRange():
	return Vector2(posStart.x + .5 * (posFinal.x - posStart.x), posStart.y + .5 * (posFinal.y - posStart.y))

func play(anim):
	$AnimatedSprite.play(anim)
	animation_finished = false

func play_next(anim):
	next_animation = anim

func _on_CollisionShape_body_entered(body):
	if !isProp:
		if body.has_method("take_damage"):
			var can_damage = false
			if group == "player":
				if body.is_in_group("enemy") or body.is_in_group("neutral"):
					can_damage = true
			if group == "enemy":
				if body.is_in_group("player") or body.is_in_group("neutral"):
					can_damage = true
					
			if can_damage:
				self.connect("EntityHit",body,"take_damage")
				emit_signal("EntityHit",damage, effects)
			
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
