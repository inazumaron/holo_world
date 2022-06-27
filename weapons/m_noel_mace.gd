extends Node2D

var SWING_DURATION = .3
var SWING_SPEED = 2.5
var SWING_ANGLE = 180
var DAMAGE = 1
var EFFECTS = {"knockback":[0,0]}
var EFFECT_VAL = {"knockback":1000}
var ACTIVE = true

var swing_dir = 1 #left - right
var can_swing = true
var angle_offset = 90
var last_mouse_angle

var can_damage = false
var swing_dur_counter = 0

var multipliers
var offsets

signal EntityHit(damage,type, effect, evalue)

func _ready():
	visible = false

func _process(delta):
	if can_swing:
		rotation = global_position.angle_to_point(get_global_mouse_position()) + deg2rad(angle_offset)
	else:
		rotation = last_mouse_angle + deg2rad(angle_offset)
		
	if can_damage and swing_dur_counter < SWING_DURATION:
		swing_dur_counter += delta
		
	if can_damage and swing_dur_counter >= SWING_DURATION:
		visible = false
		can_swing = true
		can_damage = false
		swing_dir *= -1
		
	if !can_swing:
		angle_offset += SWING_ANGLE*swing_dir*delta*SWING_SPEED

func attack():
	last_mouse_angle = global_position.angle_to_point(get_global_mouse_position())
	visible = true
	can_swing = false
	can_damage = true
	swing_dur_counter = 0

func _on_Area2D_body_entered(body):
	if body.has_method("take_damage") and body.is_in_group("enemy") and can_damage and ACTIVE:
		EFFECTS["knockback"][0] = EFFECT_VAL["knockback"]
		EFFECTS["knockback"][1] = rotation
		var damage = (DAMAGE + offsets["ATTACK_DAMAGE"]) * multipliers["ATTACK_DAMAGE"]
		print("from weapon: Dealt ",damage," damage")
		self.connect("EntityHit",body,"take_damage")
		emit_signal("EntityHit",damage, {"name":"noel mace", "buffs":EFFECTS})
		self.disconnect("EntityHit",body,"take_damage")
