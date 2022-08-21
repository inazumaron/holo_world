extends Node2D

var arrow_speed = 600
var state = "load"
var anim_finished = false
var buffs
var multipliers
var offsets
var damage = 1

const proj_base = preload("res://obj/projectile.tscn")
onready var bow_tip = $Bow_tip

func _ready():
	state = "idle"
	play("")

func _process(delta):
	if anim_finished and state == "fire":
		state = "load"
		play("")
	if anim_finished and state == "load":
		state = "idle"
		play("")
	look_at(get_global_mouse_position())

func attack():
	if state == "idle":
		state = "fire"
		play("")
		shoot()

func shoot():
	print("bow buff",buffs)
	var projectile_inst = proj_base.instance()
	projectile_inst.position = $Bow_tip.get_global_position()
	projectile_inst.rotation = rotation
	projectile_inst.velocity = Vector2(arrow_speed,0).rotated(rotation)
	projectile_inst.play("Flare_arrow")
	projectile_inst.group = "player"
	projectile_inst.effects = BuffHandler.get_weapon_buff(buffs)
	projectile_inst.damage = (damage + offsets["ATTACK_DAMAGE"]) * multipliers["ATTACK_DAMAGE"]
	get_tree().get_root().add_child(projectile_inst)

func play(x):
	if x != "":
		$AnimatedSprite.play(x)
	else:
		$AnimatedSprite.play(state)
	anim_finished = false

func _on_AnimatedSprite_animation_finished():
	anim_finished = true
