extends Node

#To handle all skill calls
#For character skills, itll be arranged by c_unit number_skill
#Will return another buff array generally

const buff_sprite = preload("res://obj/buff_effect.tscn") 
const area_effect = preload("res://obj/sfx_effect.tscn")

func activate_skill(source, buff, skill_code):
	if skill_code == "c132_shield":
		c132_shield(source, buff)
	if skill_code == "c134_scream":
		c134_scream(source, buff)

func c132_shield(source, preBuff):
	var buff_spr = buff_sprite.instance()
	buff_spr.play("n_shield_0")
	buff_spr.skill_origin = "c132_shield"
	source.add_child(buff_spr)
	var temp = {"shield": [3, -1, 1, "none"], "sprite": buff_spr}
	BuffHandler.add_buff({"name": "noel shield", "buffs":temp})

func c134_scream(source, preBuff):
	var temp = area_effect.instance()
	if source.is_in_group("player"):
		temp.GROUP = "player"
	else:
		temp.GROUP = "enemy"
	temp.play("rushia_scream")
	#temp.position = source.position
	temp.GROW = true
	temp.GROW_RATE = 1
	temp.GROW_DURATION = 0.5
	temp.DURATION = 0.5
	temp.DAMAGE = source.ATTACK_DAMAGE
	temp.SHAPE_TYPE = 1
	temp.DAMAGE_DELAY = -1
	temp.SCALE = Vector2(3,3)
	source.add_child(temp)
