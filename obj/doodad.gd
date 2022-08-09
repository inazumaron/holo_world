extends Node2D

var HP = 1
var BODY_TYPE = "doodad"
var DEF = 0

var anim_on_death = ""
var timer = -1
var free_after = false
var destructible = false
var damage_on_death = false
var damage_timer = -1			#in case apply damage/effect every sec
var group = ""
var grows = false
var animation_growth_rate = 0
var animation_to_grow = ""	#set this to the animation where dodad will increse/decrease
var freeing = false				#will be freed after animation, used to avoid applying damage repeatedly

var damage = 0
var buffs = {}
var effects = []
var bodies = []

signal DoodadHit(damage, effect)

onready var anim_obj = $AnimatedSprite

func _ready():
	if timer != -1:
		set_process(true)

func _process(delta):
	if timer > 0 and timer != -1:
		timer -= delta
	else:
		if !freeing:
			freeing = true
			free_self()
		
	if grows:
		var temp_grow = animation_growth_rate * delta
		anim_obj.scale += Vector2(temp_grow, temp_grow)

func play(anim):
	anim_obj.play(anim)
	if animation_to_grow != "" and anim == animation_to_grow:
		grows = true
		set_process(true)
	else:
		grows = false
	

func take_damage(damage, effect):
	if destructible:
		BuffHandler.damage_handler(damage, effect, buffs, self)
	
func damage(v):
	HP -= v
	if HP <= 0:
		free_self()

func free_self():
	if damage_on_death:
		apply_damage()
	if anim_on_death != "":
		free_after = true
		play(anim_on_death)
	else:
		queue_free()

func apply_damage():
	for b in bodies:
		self.connect("DoodadHit", b, "take_damage")
		emit_signal("DoodadHit", damage, effects)

func _on_AnimatedSprite_animation_finished():
	if free_after:
		queue_free()

func _on_CircleArea_body_entered(body):
	if body != self:
		if group == "player" and (body.is_in_group("enemy") or body.is_in_group("neutral")):
			bodies.append(body)
		if group == "enemy" and (body.is_in_group("player") or body.is_in_group("neutral")):
			bodies.append(body)

func _on_CircleArea_body_exited(body):
	if body in bodies:
		bodies.erase(body)
