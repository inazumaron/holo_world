extends AnimatedSprite

var SCALE = Vector2(1,1)
var GROW = false
var GROW_RATE = 0
var GROW_DURATION = 0
var DURATION = 1
var DPS = false				#if false, damage once, else damage per second
var DAMAGE = 0
var EFFECTS = {}
var DAMAGE_DELAY = 0		#if 0, no delay, -1 when duration reached, positive numbers = seconds
var GROUP = "player"
var SHAPE_TYPE = 0				#if 0, use square, if 1 use circle

var square_entered = []
var circle_entered = []

var damage_list = []

var damaged = false				#for DoT stuff
var dotTimer = 1

signal damage(damage, effects)

func _ready():
	scale = SCALE

func _process(delta):
	if GROW:
		if GROW_DURATION > 0:
			GROW_DURATION -= delta
			scale.x += delta * GROW_RATE
			scale.y += delta * GROW_RATE
	
	if DAMAGE_DELAY > 0:
		DAMAGE_DELAY -= delta
	
	if DAMAGE_DELAY > -1 and DAMAGE_DELAY <= 0:
		if DPS:
			deal_damage()
			DAMAGE_DELAY = 1
			damage_list.clear()
		else:
			deal_damage()
	
	if DURATION > 0:
		DURATION -= delta
	else:
		if DAMAGE_DELAY == -1:
			deal_damage()
		queue_free()

func deal_damage():
	if SHAPE_TYPE:
		damage_circle()
	else:
		damage_square()

func damage_square():
	for i in square_entered:
		if i.has_method("take_damage") and !i.is_in_group(GROUP) and !(i in damage_list):
			i.take_damage(DAMAGE, EFFECTS)
			damage_list.append(i)
	
func damage_circle():
	for i in square_entered:
		if i.has_method("take_damage") and !i.is_in_group(GROUP) and !(i in damage_list):
			i.take_damage(DAMAGE, EFFECTS)
			damage_list.append(i)

func _on_Area_Circle_body_entered(body):
	circle_entered.append(body)

func _on_Area_Circle_body_exited(body):
	circle_entered.erase(body)

func _on_Area_Square_body_entered(body):
	square_entered.append(body)

func _on_Area_Square_body_exited(body):
	square_entered.erase(body)
