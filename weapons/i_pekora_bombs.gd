extends Node2D

var PROJ_SPEED = 600
var DAMAGE = 1
var MIN_DIST = 100
var MAX_DIST = 200
var BUFFS = []
var multipliers
var offsets

var projectile = preload("res://obj/projectile.tscn")
onready var guide = $Guide

func _ready():
	pass # Replace with function body.

func _process(delta):
	look_at(get_global_mouse_position())
	guide_handler()

func distance(parent_pos):
	return parent_pos.distance_to(get_global_mouse_position())

func guide_handler():
	var parent_pos = global_position
	
	if distance(parent_pos) < MIN_DIST:
		guide.global_position = parent_pos + Vector2(MIN_DIST,0).rotated(rotation)
	if distance(parent_pos) >= MIN_DIST and distance(parent_pos) <= MAX_DIST:
		guide.global_position = get_global_mouse_position()
	if distance(parent_pos) > MAX_DIST:
		guide.global_position = parent_pos + Vector2(MAX_DIST,0).rotated(rotation)

func attack():
	var projectile_inst = projectile.instance()
	projectile_inst.position = get_global_position()
	projectile_inst.rotation = rotation
	projectile_inst.play("Pekora_bomb")
	projectile_inst.death_anim = "Pekora_bomb_explode"
	projectile_inst.spin = true
	projectile_inst.spin_rate = 360
	projectile_inst.parabolic = true
	projectile_inst.group = "player"
	projectile_inst.duration = 1
	projectile_inst.posFinal = guide.global_position
	projectile_inst.AoeBubble = true
	projectile_inst.damage = 1
	get_tree().get_root().add_child(projectile_inst)
