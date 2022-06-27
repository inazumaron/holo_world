extends Node

#To handle all skill calls
#For character skills, itll be arranged by c_unit number_skill
#Will return another buff array generally

const buff_sprite = preload("res://obj/buff_effect.tscn") 

func c132_shield(source, preBuff):
	var buff_spr = buff_sprite.instance()
	buff_spr.play("n_shield_0")
	buff_spr.skill_origin = "c132_shield"
	source.add_child(buff_spr)
	var temp = {"shield": [3, -1, 1, "none"], "sprite": buff_spr}
	BuffHandler.add_buff({"name": "noel shield", "buffs":temp})
