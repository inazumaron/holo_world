extends Node

#To handle all skill calls
#For character skills, itll be arranged by c_unit number_skill
#Will return another buff array generally

const buff_sprite = preload("res://obj/buff_effect.tscn") 
const area_effect = preload("res://obj/sfx_effect.tscn")
const proj_sprite = preload("res://obj/projectile.tscn")

var states = {}		#For skills with multiple stages, use this as reference

func _process(delta):
	if states.empty():
		set_process(false)
	else:
		for skill in states:
			if "run" in states[skill]:
				if states[skill]["run"]:
					if skill == "134_hb":
						hexBlast_spin(delta)
			if "timer" in states[skill]:
				if states[skill]["timer"] > 0:
					states[skill]["timer"] -= delta
				else:
					if skill == "134_hb":
						c134_hexBlast(states[skill]["source"], states[skill]["buffs"])

func activate_skill(source, buff, skill_code):
	if skill_code == "c132_shield":
		c132_shield(source, buff)
	if skill_code == "c134_scream":
		c134_scream(source, buff)
	if skill_code == "c134_hexBlast":
		c134_hexBlast(source, buff)

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

func c134_hexBlast(source, buffs):
	if not("134_hb" in states):
		states["134_hb"] = {"state":0, "dir":[0,60,120,180,240,300], "timer":0.3, "obj":[], "ammo":4, "source":source, "buffs":buffs, "run":false}
		set_process(true)
		#states: 0 - creating props, 1 - spinning and blasting, 2 - end
	var vars = states["134_hb"]
	if vars["state"] == 0:
		if vars["dir"].size() > vars["obj"].size():
			var temp_prop = proj_sprite.instance()
			temp_prop.isProp = true
			temp_prop.play("Rushia_orb_create")
			temp_prop.play_next("Rushia_orb_idle")
			source.add_child(temp_prop)
			temp_prop.position += 64 * Vector2(cos(deg2rad(vars["dir"][vars["obj"].size()])), sin(deg2rad(vars["dir"][vars["obj"].size()])))
			vars["timer"] = 0.3
			vars["obj"].append(temp_prop)
		else:
			vars["state"] = 1
			vars["run"] = true
			vars["timer"] = 0.5
	elif vars["state"] == 1 and vars["ammo"]>0:
		for i in range(0, vars["obj"].size()):
			var temp_proj = proj_sprite.instance()
			temp_proj.damage = source.ATTACK_DAMAGE
			temp_proj.posStart = vars["obj"][i].global_position
			temp_proj.global_position = vars["obj"][i].global_position
			temp_proj.velocity = 100 * Vector2(cos(deg2rad(vars["dir"][i])),sin(deg2rad(vars["dir"][i])))
			temp_proj.acceleration = 100 * Vector2(cos(deg2rad(vars["dir"][i])),sin(deg2rad(vars["dir"][i])))
			temp_proj.maxVelocity = 200 * Vector2(cos(deg2rad(vars["dir"][i])),sin(deg2rad(vars["dir"][i])))
			if source.is_in_group("player"):
				temp_proj.add_to_group("player")
				temp_proj.group = "player"
			else:
				temp_proj.add_to_group("enemy")
				temp_proj.group = "enemy"
			temp_proj.play("Rushia_orb_launch")
			temp_proj.death_anim = "Rushia_orb_end"
			temp_proj.rotation_degrees = vars["dir"][i]
			temp_proj.scale = Vector2(2,2)
			get_tree().get_root().add_child(temp_proj)
		vars["timer"] = 0.5
		vars["ammo"] -= 1
	elif vars["state"] == 1:
		for i in range(0, vars["obj"].size()):
			vars["obj"][i].play("Rushia_orb_end")
			vars["obj"][i].queue_next = true
		vars["state"] = 2
		vars["timer"] = 0.5
	else:
		states.erase("134_hb")

func hexBlast_spin(delta):
	var vars = states["134_hb"]
	for i in range(0, vars["dir"].size()):
		vars["dir"][i] += 60*delta
		if vars["dir"][i] > 360:
			vars["dir"][i] -= 360
	for i in range(0, vars["obj"].size()):
		vars["obj"][i].position = 64 * Vector2(cos(deg2rad(vars["dir"][i])), sin(deg2rad(vars["dir"][i])))
