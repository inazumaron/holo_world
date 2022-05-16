extends KinematicBody2D

const MOVE_TIMER = 5
const FIRE_TIMER = 2 #delay before 
const ACCELERATION = 1000
const MAX_SPEED = 100
const COST = 0.5
const TO_PLAYER = true
const ATTACK_COOLDOWN = 1
const ATTACK_DURATION = 0.5
const ATTACK_DELAY = 0.5	#delay for attack damage application once attack animation starts
const DAMAGE = 1
const DAMAGE_ANIM_DUR = 0.2
const WANDER_DURATION = 1
const APPEAR_DURATION = 1.2
const CHASER = 1			# 1 - chases player, -1 - movement not affected by player, 0 - runs away from player

var buffs = {"defense":0, "weight":1}		#place all active buffs/debuffs here, should not be directly altered, as values are shared between all
var buff_timers = {}
var EFFECTS = {}			#for offensive statuses, damage bonus, inflict poison, etc
var SEED = 0
var HP = 3
var anim_dir = 1 #1-right, -1 left
var direction = 0
var targets = []
var move_timer = 0 #for wandering
var damage_anim_timer = 0
var attack_anim_timer = 0
var attack_timer = 0
var attack_delay_timer = -1		#-1 if not attacking, 0-check target, apply damage. 0+ 
var attack_target = null 
var appear_timer = APPEAR_DURATION #starting animation duration
var movement = Vector2.ZERO
var npc_can_move = true
var dead = false

var can_move = true
var can_attack = true

var rng = RandomNumberGenerator.new()
var dvar = true
# Called when the node enters the scene tree for the first time.
func _ready():
	rng.seed = SEED
	add_to_group("enemy")
	play_animation("appear")

func _process(delta):
	timer_handler(delta)
	if appear_timer <= 0:
		if attack_target == null:
			if damage_anim_timer <= 0 and attack_anim_timer <= 0:		#wont move if damaged or attacking
				if can_move:
					move(delta)
		else:
			if can_attack:
				attack()
		buff_handler(delta)

func buff_handler(delta):	#for buffs too complex for buff handler to deal with i.e. making them move
	if "knockback" in buffs:
		direction = buffs["knockback"][1]
		if "knockback" in buff_timers:
			apply_movement(buff_timers["knockback"])
			anim_dir = -sgn(movement.x)
			movement = move_and_slide(movement)
			buff_timers["knockback"]  *= pow(0.95, buffs["weight"])
			if buff_timers["knockback"] <= 1:
				buffs.erase("knockback")
				buff_timers.erase("knockback")
		else:
			buff_timers["knockback"] = buffs["knockback"][0]

func timer_handler(delta):
	if appear_timer>0:
		appear_timer -= delta
	if attack_anim_timer>0:
		attack_anim_timer -= delta
	if damage_anim_timer>0:
		damage_anim_timer -= delta
	if attack_timer>0:
		attack_timer -= delta
	if move_timer>0:
		move_timer -= delta
	if move_timer <= 0:
		move_timer = WANDER_DURATION
		npc_can_move = !npc_can_move
	if attack_delay_timer > 0 and attack_delay_timer != -1:
		attack_delay_timer -= delta
		if attack_delay_timer <= 0:
			if attack_target != null:
				attack_target.take_damage(DAMAGE,EFFECTS)
			attack_delay_timer = -1

func move(delta):
	if targets.size() > 0:
		chase()
		play_animation("walk")
	elif npc_can_move:
		wander()
		play_animation("walk")
	else:
		apply_friction(0.5)
		play_animation("idle")
	apply_movement(ACCELERATION*delta)
	anim_dir = sgn(movement.x)
	movement = move_and_slide(movement)

func wander():
	direction = deg2rad(rng.randi_range(0, 360))
	move_timer = WANDER_DURATION

func chase():
	if CHASER >= 0:
		var chase_target = get_target()
		direction = global_position.angle_to_point(chase_target.position)
		direction += deg2rad(180) * CHASER
	else:
		direction = deg2rad(randi()%360)
	
func get_target():
	#aggro handling
	var max_aggro_index = 0
	for i in range(0, targets.size()):
		if targets[i]["aggro"] > targets[max_aggro_index]["aggro"]:
			max_aggro_index = i
	return targets[max_aggro_index]["id"]

func attack():
	if attack_target != null and attack_timer <= 0:
		attack_timer = ATTACK_COOLDOWN
		attack_anim_timer = ATTACK_DURATION
		attack_delay_timer = ATTACK_DELAY
		play_animation("attack")

func take_damage(damage, effect):
	BuffHandler.damage_handler(damage, effect, buffs, self)

func damage(v):
	if v > 0:
		damage_anim_timer = DAMAGE_ANIM_DUR
		HP -= v
		play_animation("damage")
		if HP <= 0:
			dead = true

func play_animation(x):
	#priority: attack - damaged - walk
	if attack_anim_timer > 0:
		$AnimatedSprite.play("attack")
	elif damage_anim_timer > 0:
		$AnimatedSprite.play("damage")
	else:
		$AnimatedSprite.play(x)
	$AnimatedSprite.scale.x = anim_dir

func apply_friction(amount):
	movement *= amount

func apply_movement(acceleration):
	movement += Vector2(acceleration,0).rotated(direction)
	movement = movement.clamped(MAX_SPEED)

func sgn(x):
	if x>0:
		return 1
	return -1

func _on_DetectRange_body_entered(body):
	if body.is_in_group("player"):
		var temp = {"id":body,"aggro":100}
		targets.append(temp)

func _on_DetectRange_body_exited(body):
	if body.is_in_group("player"):
		for i in range(0,targets.size()):
			if targets[i]["id"] == body:
				targets[i]["aggro"] /= 2

func _on_AttackRange_body_entered(body): #does not account for multiple targets entering range at same time
	if body.is_in_group("player"):
		attack_target = body

func _on_AttackRange_body_exited(body):
	if body == attack_target:
		attack_target = null
