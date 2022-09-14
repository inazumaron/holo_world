extends KinematicBody2D

const MOVE_TIMER = 5
const FIRE_TIMER = 2 #delay before 
const ACCELERATION = 1000
const MAX_SPEED = 100
const COST = 1
const XP = 2
const TO_PLAYER = true
const ATTACK_DAMAGE = 1
const ATTACK_COOLDOWN = 3
const ATTACK_DURATION = 1
const ATTACK_DELAY = 0.5	#delay for attack damage application once attack animation starts
const DAMAGE_ANIM_DUR = 0.2
const WANDER_DURATION = 1
const APPEAR_DURATION = 1.2
const CHASER = -1			# 1 - chases player, -1 - movement not affected by player, 0 - runs away from player
const MAX_HP = 3
const DEF = 0
const ACTIVE = true

var BODY_TYPE = "enemy_mob"
var buffs = {"passive":{"weight":1}}		#place all active buffs/debuffs here, should not be directly altered, as values are shared between all
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
var state := "idle"		#idle or attack

var can_move = true
var can_attack = true

var player_id = [null,null,null]	#for easy changing targets when player switches character. Provided by level hadnler
var connected_signals = {}

var rng = RandomNumberGenerator.new()
var dvar = true
var multipliers = {
	"MAX_SPEED":1,
	"MAX_HP":1,
	"HP":1,
	"DEF":1,
	"ATTACK_COOLDOWN":1,
	"ATTACK_STACK_COUNT":1,
	"ATTACK_DAMAGE":1,
	"SPECIAL_COOLDOWN":1
}	#For buffs effects, in the format "stat name": float multiplier
var offsets = {
	"MAX_SPEED":1,
	"MAX_HP":1,
	"HP":1,
	"DEF":1,
	"ATTACK_COOLDOWN":1,
	"ATTACK_STACK_COUNT":1,
	"ATTACK_DAMAGE":1,
	"SPECIAL_COOLDOWN":1
}	#For buffs adding flat increase

var weapon_base = preload("res://weapons/e_fandead_laser.tscn")
var weapon

func _ready():
	rng.seed = SEED
	add_to_group("enemy")
	$AnimatedSprite.speed_scale = 0
	play_animation("appear")
	weapon = weapon_base.instance()
	add_child(weapon)

func _process(delta):
	if $AnimatedSprite.speed_scale == 0:
		$AnimatedSprite.speed_scale = 1
	timer_handler(delta)
	if appear_timer <= 0:
		if attack_target == null:
			if damage_anim_timer <= 0 and attack_anim_timer <= 0:		#wont move if damaged or attacking
				if can_move and state == "idle":
					move(delta)
		else:
			if can_attack and damage_anim_timer <= 0:
				attack()

func sanity_check():		#for bug handling
	#Out of bounds
	var temp = GameHandler.room_radius
	if position.x < -temp or position.x > temp or position.y < -temp or position.y > temp:
		dead = true
	#Stuck in obstacle

func timer_handler(delta):
	if appear_timer>0:
		appear_timer -= delta
		
	if attack_anim_timer>0:
		attack_anim_timer -= delta
		if attack_anim_timer <= 0:
			play_animation("idle")
			if state != "dead":
				state = "idle"
		
	if damage_anim_timer>0:
		damage_anim_timer -= delta
		
	if attack_timer>0:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
		
	if move_timer>0:
		move_timer -= delta
		
	if move_timer <= 0:
		move_timer = WANDER_DURATION
		npc_can_move = !npc_can_move

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
	#start charging
	if attack_target != null and attack_timer <= 0 and state != "dead":
		attack_timer = ATTACK_COOLDOWN
		play_animation("charge")
		state = "charge"
		can_attack = false
		weapon.target_lock(attack_target.position)

func weap_attack():
	#fire laser
	attack_anim_timer = ATTACK_DURATION
	weapon.damage = ATTACK_DAMAGE
	weapon.buffs = EFFECTS
	weapon.attack()

func take_damage(damage, effect):
	BuffHandler.damage_handler(damage, effect, buffs, self)

func damage(v):
	if v > 0:
		damage_anim_timer = DAMAGE_ANIM_DUR
		HP -= v
		if HP <= 0:
			if state == "idle":
				dead = true
			else:
				play_animation("explode")
		else:
			play_animation("damaged")

func play_animation(x):
	#priority: attack - damaged - walk
	if x == "explode" or state == "dead":
		state = "dead"
		$AnimatedSprite.play("explode")
	elif damage_anim_timer > 0:
		if state == "idle" or state == "charge":
			$AnimatedSprite.play("damaged")
		else:
			weapon.cancel_laser()
			$AnimatedSprite.play("damaged_charged")
		state = "idle"
	else:
		$AnimatedSprite.play(x)
	$AnimatedSprite.scale.x = anim_dir * -1

func apply_friction(amount):
	movement *= amount

func apply_movement(acceleration):
	movement += Vector2(acceleration,0).rotated(direction)
	movement = movement.clamped(MAX_SPEED)

func sgn(x):
	if x>0:
		return 1
	return -1

func update_active_player():
	for i in targets:
		if i["id"].BODY_TYPE == "player_character":
			i["id"] = player_id[GameHandler.get_active_char_index()]

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

func _on_AnimatedSprite_animation_finished():
	if state == "charge":
		state = "attack"
		weap_attack()
		play_animation("attack")
	if state == "dead":
		dead = true
