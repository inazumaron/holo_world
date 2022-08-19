extends KinematicBody2D

#--------------------stats related
var MAX_SPEED = 300
var ACCELERATION = 1000
var MAX_HP = 25
var HP = 25
var DEF = 0 #0 by default, reduces damage by a flat amount. 

var ATTACK_DAMAGE = 1
var ATTACK_EFFECTS = []
var ATTACK_MELEE = ["c134_scream"]
var ATTACK_RANGED = ["c134_hexBlast", "c134_hexBeam"]
var ATTACK_COOLDOWN = 4

var MOVE_DURATION = 1
var MOVE_COOLDOWN = 3
const IS_BOSS = true
const ACTIVE = true
var buffs = {}
var XP = 100
#-------------------------------
var BODY_TYPE = "enemy_boss"
var move_counter = 1
var move_state = false
var attack_counter = 1
var melee_range = []
var direction = 0
var movement = Vector2.ZERO
var dead = false

var can_move = true
var can_attack = true
var anim_dir = 1 #1-right, -1 left
var hp_ui

onready var sprite = $RushiaSprite

func _ready():
	add_to_group("enemy")

func _process(delta):
	timers(delta)
	
	if move_counter <= 0:
		direction = deg2rad(randi()%360)
		if !move_state:
			move_counter = MOVE_DURATION
			play("move")
		else:
			move_counter = MOVE_COOLDOWN
			play("idle")
		move_state = !move_state
	
	if move_state and can_move:
		move(delta)
	
	if attack_counter <= 0:
		attack()
		attack_counter = ATTACK_COOLDOWN

func timers(delta):
	if move_counter > 0:
		move_counter -= delta
	
	if attack_counter > 0:
		attack_counter -= delta

func move(delta):
	apply_movement(ACCELERATION*delta)
	anim_dir = sgn(movement.x)
	movement = move_and_slide(movement)

func apply_friction(amount):
	movement *= amount

func apply_movement(acceleration):
	movement += Vector2(acceleration,0).rotated(direction)
	movement = movement.clamped(MAX_SPEED)

func attack():
	var skills
	if melee_range.size() > 0:
		skills = ATTACK_MELEE + ATTACK_RANGED
	else:
		skills = ATTACK_RANGED
	play("attack")
	var i = randi()%skills.size()
	SkillHandler.activate_skill(self, buffs, skills[i])

func play(anim):
	var temp_direction
	if rad2deg(direction) > 270 or rad2deg(direction)<90:
		temp_direction = "_right"
	else:
		temp_direction = "_left"
	sprite.play(anim+temp_direction)

func update_ui():
	if typeof(hp_ui) == 4:
		hp_ui = GameHandler.get_boss_hp_ui()
	hp_ui.set_val((100 * HP)/ MAX_HP)

func take_damage(damage, effect):
	BuffHandler.damage_handler(damage, effect, buffs, self)

func damage(v):
	if v > 0:
		HP -= v
		update_ui()
		if HP <= 0:
			dead = true

func sgn(x):
	if x>0:
		return 1
	return -1

func _on_Melee_range_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		melee_range.append(body)

func _on_Melee_range_body_exited(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		melee_range.erase(body)
