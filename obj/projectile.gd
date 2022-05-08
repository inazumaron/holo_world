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
	# player
	# enemy
	# neutral
	# border
signal EntityHit(damage, effect)

func _ready():
	set_process(false)

func setData(data):
	if "sprPath" in data:
		sprPath = data["sprPath"]
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
	move(delta)
	timer(delta)
	
func move(delta):
	position = transform.x * velocity * delta
	if velocity < maxVelocity:
		velocity = min(velocity + acceleration * delta, maxVelocity)

func timer(delta):
	duration -= delta
	if duration <= 0:
		queue_free()

func getMidRange():
	return Vector2(posStart.x + .5 * (posFinal.x - posStart.x), posStart.y + .5 * (posFinal.y - posStart.y))

func _on_CollisionShape_body_entered(body):
	var damage = false
	if group == "player":
		if body.is_in_group("enemy") or body.is_in_body("neutral"):
			damage = true
	if group == "enemy":
		if body.is_in_group("player") or body.is_in_body("neutral"):
			damage = true
	if body.is_in_group("border"):
		queue_free()
	if body.has_method("take_damage") and damage:
		self.connect("EntityHit",body,"take_damage")
		emit_signal("EntityHit",damage, effects)
