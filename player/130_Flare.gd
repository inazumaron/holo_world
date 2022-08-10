extends KinematicBody2D

#--------------------stats related
var MAX_SPEED = 300
var ACCELERATION = 1000
var POS_UPDATE_TIMER = .1
var MAX_HP = 6
var HP = 6
var DEF = 0 #0 by default, reduces damage by a flat amount. 

var ATTACK_COOLDOWN = 0.5
var ATTACK_STACK_COUNT = 1
var ATTACK_DAMAGE = 1
var ATTACK_EFFECTS = []

var SPECIAL_CODE = "c130_piercingShot"
var SPECIAL_COOLDOWN = 1
var SPECIAL_REGEN_TYPE = 0 #0 - auto, 1 - offensive, 2 - defensive
var SPECIAL_EFFECTS = []

var DAMAGE_ANIM_DUR = 0.2
var ACTIVE = true			#for collab on field
const WEAPON_PATH = "res://weapons/r_flare_bow.tscn"
const CODE = 130

var can_move = true
var can_attack = true
#---------------------------------
var movement = Vector2.ZERO
var anim_dir = 1 #1-right, -1 left
var last_anim_dir = 0 #0 - left, 1 - right
var IS_BOSS = false		#for checking skill usage between player and boss
var BODY_TYPE = "player_character"

#------------------------ Timers
var pos_timer = 0	#update position for game
var damage_anim_timer = 0 # damage invulnerability time
var attack_timer = 0
var buffs = {}		#contains debuffs and buffs
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
	"MAX_SPEED":0,
	"MAX_HP":0,
	"HP":0,
	"DEF":0,
	"ATTACK_COOLDOWN":0,
	"ATTACK_STACK_COUNT":0,
	"ATTACK_DAMAGE":0,
	"SPECIAL_COOLDOWN":0
}	#For buffs adding flat increase

var minimap_base = preload("res://ui/minimap.tscn")
var minimap = null
var ui_base = preload("res://ui/char_ui.tscn")
var ui = null
var item_base = preload("res://ui/item_ui.tscn")
var item = null
var bhp_base = preload("res://ui/boss_hp.tscn")
var bhp = null

var weapon_base = preload(WEAPON_PATH)
var weapon = weapon_base.instance()

func _ready():
	add_to_group("player")
	add_child(weapon)
	weapon.multipliers = multipliers
	weapon.offsets = offsets
	generate_ui()
	
	#var temp = generate_boss_hp()
	
	ui_manipulation(0)

func _physics_process(delta):
	if ACTIVE:
		if can_attack:
			general_action()
		
		if can_move:
			general_move(delta)
		
		general_timer_update(delta)
		
		ui_manipulation(1)
		ui_manipulation(11)

func general_move(delta):
	var axis = get_input_axis()
	
	if axis == Vector2.ZERO:
		apply_friction(ACCELERATION*delta)
	else:
		apply_movement(axis*ACCELERATION*delta)
	movement = move_and_slide(movement)

func general_timer_update(delta):
	if damage_anim_timer > 0:
		damage_anim_timer -= delta
		
	if pos_timer > 0 :
		pos_timer = POS_UPDATE_TIMER
		
	if attack_timer < ATTACK_STACK_COUNT:
		attack_timer += delta/(ATTACK_COOLDOWN * multipliers["ATTACK_COOLDOWN"])

func general_action():
	if Input.is_action_just_pressed("mouse_click"):
		attack()
		
	if Input.is_action_just_pressed("mouse_click_r"):
		SkillHandler.activate_skill(self, buffs, SPECIAL_CODE)

func get_input_axis():
	var axis = Vector2.ZERO
	axis.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	axis.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	anim_update(axis)
	return axis.normalized()

func apply_friction(amount):
	if movement.length() > amount:
		movement -= movement.normalized() * amount
	else:
		movement = Vector2.ZERO
	return movement

func apply_movement(acceleration):
	movement += acceleration
	movement = movement.clamped((MAX_SPEED + offsets["MAX_SPEED"])*multipliers["MAX_SPEED"])
	return movement

func attack():
	if attack_timer >= 1:
		attack_timer -= 1
		weapon.attack()

func anim_update(axis):
	if damage_anim_timer > 0:
		if last_anim_dir == 0:
			$AnimatedSprite.play("damage_left")
		else:
			$AnimatedSprite.play("damage_right")
	elif axis.x != 0 || axis.y != 0:
		if axis.x > 0:
			$AnimatedSprite.play("walk_right")
			last_anim_dir = 1
		elif axis.x < 0:
			$AnimatedSprite.play("walk_left")
			last_anim_dir = 0
		elif last_anim_dir == 0:
			$AnimatedSprite.play("walk_left")
		else:
			$AnimatedSprite.play("walk_right")
	else:
		if last_anim_dir == 0:
			$AnimatedSprite.play("idle_left")
		else:
			$AnimatedSprite.play("idle_right")

func take_damage(damage, effect):
	BuffHandler.damage_handler(damage, effect, buffs, self)

func ui_manipulation(n):
	#	0 - update life
	#	1 - normal click
	#	2 - special click
	var data = {"param":"stat", "val":0, "val2":0}
	match n:
		0:
			data["param"]="hp"
			data["val"]=HP
			data["val2"]=MAX_HP
		1:
			data["param"]="atk"
			data["val"]=fmod(attack_timer,1)
			data["val2"]=ATTACK_COOLDOWN
		11:
			data["param"]="atk_s"
			data["val"]=floor(attack_timer)
	ui.change(data)

func send_data():
	var data = {"CHAR_CODE":CODE, "HP": HP, "BUFFS": buffs, "ACTIVE":ACTIVE}
	
	return data

func update_data(data):
	HP = data["HP"]
	buffs = data["BUFFS"]
	activate(data["ACTIVE"])
	ui_manipulation(0)

func activate(x):
	if x:
		ACTIVE = true
		$Camera2D.current = true
		self.visible = true
		$CollisionShape2D.disabled = false
		ui.visible = true
	else:
		ACTIVE = false
		$Camera2D.current = false
		self.visible = false
		$CollisionShape2D.disabled = true
		ui.visible = false
		movement = Vector2.ZERO

func setCamera(x):
	$Camera2D.current = x

func generate_ui():
	ui = ui_base.instance()
	ui.position = Vector2(-380,-260)
	ui.z_index = 1
	add_child(ui)
	item = item_base.instance()
	item.position = Vector2(-420,260)
	item.z_index = 1
	add_child(item)
	ui_manipulation(0)

func generate_minimap(path, active_room_val):
	minimap = minimap_base.instance()
	minimap.map = path
	minimap.loc = active_room_val
	minimap.z_index = 1
	add_child(minimap)
	minimap.generate_minimap()

func damage(v):
	if v > 0:
		damage_anim_timer = DAMAGE_ANIM_DUR
		HP -= v
		anim_update(Vector2.ZERO)
		ui_manipulation(0)

func ui_item_update_anim(x,y,l1,l2):
	item.change(x,y)
	item.changeLabel(l1,l2)

func sgn(x):
	if x>0:
		return 1
	return -1

func get_dir():	#for skill handler to get mouse direction
	return get_angle_to(get_global_mouse_position())

func generate_boss_hp():
	if bhp == null:
		bhp = bhp_base.instance()
		bhp.z_index = 1
		add_child(bhp)
		bhp.position = Vector2(0, 250)
	return bhp
