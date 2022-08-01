extends Node2D

#
var HP = 1				#if destructible
var ACTIVE = true

var shape = "circle"
var effects = []
var damage = 0
var continious = false	#apply effect every sec
var onEntry = false		#apply effect on entry
var onExit = false		#apply effect on exit
var destructible = false	#can be destroyed

var RectBodies = []
var CircleBodies = []
var timer = 1

signal damageBodies(damage, effects)

func _ready():
	if continious:
		set_process(true)
	else:
		set_process(false)

func _process(delta):
	if timer > 0:
		timer -= delta
	else:
		if shape == "circle":
			damageCircle()
		else:
			damageRect()
		timer = 1

func set_data(data):
	pass

func play(anim):
	$AnimatedSprite.play(anim)

func damageRect():
	if ACTIVE:
		for body in RectBodies:
			self.connect("damageBodies",body,"take_damage")
			emit_signal("damageBodies",damage, effects)

func damageCircle():
	if ACTIVE:
		for body in CircleBodies:
			self.connect("damageBodies",body,"take_damage")
			emit_signal("damageBodies",damage, effects)

func damageBody(body):
	if ACTIVE:
		self.connect("damageBodies",body,"take_damage")
		emit_signal("damageBodies")

func _on_AreaRect_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		RectBodies.append(body)
	if shape == "rect" and onEntry:
		damageBody(body)

func _on_AreaRect_body_exited(body):
	if body in RectBodies:
		RectBodies.erase(body)
	if shape == "rect" and onExit:
		damageBody(body)

func _on_AreaCircle_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		CircleBodies.append(body)
	if shape == "circle" and onEntry:
		damageBody(body)

func _on_AreaCircle_body_exited(body):
	if body in CircleBodies:
		CircleBodies.erase(body)
	if shape == "circle" and onExit:
		damageBody(body)
