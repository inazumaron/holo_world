extends Node

#For reference in creating buff:
#{name:unique_buff_name, buffs: [ buff details ]}
#WARNING: make sure the unique_buff_name does not contain buff names (i.e "slow", "quick", etc as it will be detected in find_buff)
#when using buff names, add '_' after first letter for consistency

var char_party_buffs = [ #Party buffs that characters give when inactive
	{ "name" : "133_3", "buffs" : [{"critRate": [10, -1, 1, "perm"]}]}
]
#Format: { name: code_tier, buffs : [ {buff : val} ] }

var char_nodes = []		#points to character ids
var enemy_nodes = []	#when enemy gets buff_debuff, add here then remove when done
# data format: { 'node': string, 'buffs': [ {'buff name': val}] }

var realtime_buffs = []
#data format: {'node':string, 'type':string, 'details':{}}
#type: "knockback", etc #to add

var temp_buffs = []
#data format: {'node':string, 'details':{'stat': string, 'offsets': float, 'multiplier': float}, 'applied': bool, 'timer': float
#				'party': bool, 'behaviour': string}
#these are for buffs that affect multipliers and offsets, aka applied once and then removed when done

var reapply = []
#data format: {node: string, buff_path: [string, string ...], sprite_animation: string}
#for data with sprites thats not temp buff, mainly for reapplying sprites

var party_buffs = []
#data format: {node: string (who has the buff), details: {}, type: string (sec, realtime, temp_buff, etc) which handler deals with it
#			depending on type:, applied: bool, timer: 
#for buffs affecting whole party

const room_delayed_buffs = ["heal_pr"] 
#just update this, this contains list of buffs to apply at start of room. 

#sec timer deals with buffs that is applied every second, i.e. poison, DoT stuff, HoT

var timers = {'sec':0}

const buff_spr_base = preload("res://obj/buff_effect.tscn")
const text_base = preload("res://obj/text_obj.tscn")

func _ready():
	set_process(false)

func _process(delta):
	if timers["sec"] > 0:
		timers["sec"] -= delta
	else:
		timers["sec"] = 1
		sec_timer()
	
	if realtime_buffs.size() > 0:
		realtime_handler(delta)
	
	if temp_buffs.size() > 0:
		temp_buff_handler(delta)

func sec_timer():
	var src
	var buffs
	for i in (char_nodes + enemy_nodes):
		src = i['node']
		buffs = i['buffs']
		var temp = find_buff(buffs,"poison")
		if temp.size() > 0:
			for j in temp:
				src.damage(buffs[j]["poison"][0])
				buffs[j]["poison"][1] -= 1
				if buffs[j]["poison"][1] <= 0:
					buffs[j].erase("poison")
					src.buffs = buffs
		temp = find_buff(buffs,"burn")
		if temp.size() > 0:
			for j in temp:
				src.damage(buffs[j]["burn"][0])
				buffs[j]["burn"][1] -= 1
				if buffs[j]["burn"][1] <= 0:
					buffs[j].erase("burn")
					src.buffs = buffs
				if !("b_urnSprite" in buffs):
					var temp_sprite = buff_spr_base.instance()
					temp_sprite.play("burn")
					i['node'].add_child(temp_sprite)
					buffs["b_urnSprite"] = temp_sprite
		else:
			if "b_urnSprite" in buffs:
				buffs["b_urnSprite"].queue_free()
				buffs.erase("b_urnSprite")
		stat_update(src)

func realtime_handler(delta): # For buffs that need to be applied realtime
	for i in realtime_buffs:
		if source_exist(i["node"]):
			if i["type"] == "knockback":
				var temp_w
				if "weight" in i:
					temp_w = i["weight"]
				else:
					temp_w = 1
				var res = knockback_handler(i["node"],i["details"], temp_w)
				if res:
					var source
					if is_player(i["node"]):
						source = get_p_index(i["node"])
						char_nodes[source]["buffs"].erase(i["source_buff"])
						char_nodes[source]["node"].buffs = char_nodes[source]["buffs"]
					else:
						source = get_e_index(i["node"])
						enemy_nodes[source]["buffs"].erase(i["source_buff"])
						enemy_nodes[source]["node"].buffs = enemy_nodes[source]["buffs"]
					realtime_buffs.erase(i)
		else:
			realtime_buffs.erase(i)
	
func temp_buff_handler(delta):
	for i in temp_buffs:
		if !is_instance_valid(i['node']):
			temp_buffs.erase(i)
			continue
		if i['node'].ACTIVE or i['behaviour'] == "bg" or i['party']:
			if i['applied']:
				i['timer'] -= delta
				if i['timer'] <= 0:
					i['node'].multipliers[i['details']['stat']] /= i['details']['multiplier']
					i['node'].offsets[i['details']['stat']] -= i['details']['offsets']
					i['sprite'].queue_free()
					temp_buffs.erase(i)
			else:
				i['applied'] = true
				i['node'].multipliers[i['details']['stat']] *= i['details']['multiplier']
				i['node'].offsets[i['details']['stat']] += i['details']['offsets']
				var buff_sprite = buff_spr_base.instance()
				buff_sprite.play(i['details']['anim'])
				i['node'].add_child(buff_sprite)
				i['sprite'] = buff_sprite
		elif i['behaviour'] == "temp":
			i['node'].multipliers[i['details']['stat']] /= i['details']['multiplier']
			i['node'].offsets[i['details']['stat']] -= i['details']['offsets']
			i['sprite'].queue_free()
			temp_buffs.erase(i)

func display_damage(pos,dam):
	var text = text_base.instance()
	var data = {"bold":true, "color":"red", "align":"center"}
	var pos_offset = Vector2(0, -16)
	text.set_properties(data)
	text.set_text(str(dam))
	text.position = pos
	text.timer = 0.5
	get_tree().get_root().add_child(text)
	text.display()

func damage_handler(damage, effects, buffs, source):
	if !effects.empty():
		#Effect format 
		if effects.size() == 1:
			update_buffs(effects, source)
		elif effects.size() > 1:
			for effect in effects:
				update_buffs(effects[effect], source)
	var dam = damage
	dam = damage - source.DEF
	
	if dam > 0:
		var tempShield = find_buff(buffs, "shield")
		if tempShield.size() > 0:#"shield": ["stack", "duration", "party", "behaviour"],
			buffs[tempShield[0]]["shield"][0] -= 1
			if buffs[tempShield[0]]["shield"][0] <= 0:
				buffs[tempShield[0]].erase("shield")
				if "sprite" in buffs[tempShield[0]]:
					buffs[tempShield[0]]["sprite"].queue_free()
					buffs[tempShield[0]].erase("sprite")
				if buffs[tempShield[0]].empty():
					buffs.erase([tempShield[0]])
			elif "sprite" in buffs[tempShield[0]]:
				var temp = buffs[tempShield[0]]["sprite"]
				if temp.skill_origin == "c132_shield":
					if buffs[tempShield[0]]["shield"][0] >= 3:
						buffs[tempShield[0]]["sprite"].play("n_shield_0")
					elif buffs[tempShield[0]]["shield"][0] == 2:
						buffs[tempShield[0]]["sprite"].play("n_shield_1")
					elif buffs[tempShield[0]]["shield"][0] == 1:
						buffs[tempShield[0]]["sprite"].play("n_shield_2")
		else:
			source.damage(dam)
			display_damage(source.position, dam)
			if source.HP <= 0:
				var temp = find_buff(source.buffs, "revive")
				if temp.size() > 0:
					source.HP = source.buffs[temp[0]]["revive"][0] * source.MAX_HP
					source.buffs[temp[0]]["revive"][1] -= 1
					source.ui_manipulation(0)
					if source.buffs[temp[0]]["revive"][1] <= 0:
						if source.buffs[temp[0]]["source"] == "item":
							ItemHandler.remove_item(source.buffs[temp[0]]["source_details"])
						source.buffs.erase(temp[0])
	else:
		source.damage(0)

func update_buffs(effects, source):
	if is_player(source):
		print("update buff effects", effects)
		var i = get_p_index(source)
		var key = effects.keys()
		char_nodes[i]['buffs'][key[0]] = effects[key[0]]
		var x = char_nodes[i]['node']
		x.update_buffs(char_nodes[i]['buffs'])
		if !("_party" in key[0]):
			var temp_pb = buff_applies_to_party(effects)
			var key2 = temp_pb.keys()
			if !temp_pb[key2[0]].empty():
				apply_buff_to_party(temp_pb, source)
	else:
		var i = get_e_index(source)
		var key = effects.keys()
		enemy_nodes[i]['buffs'][key[0]] = effects[key[0]]
		var x = enemy_nodes[i]['node']
		x.buffs = enemy_nodes[i]['buffs']
		
	#================================================================================================
	#passing buffs to realtime handler
	var temp = find_buff(effects, "knockback")
	if temp.size() > 0:
		for i in temp:
			var temp2 = {"node":source, "type":"knockback", "details":effects[i]["knockback"], "source_buff":i}
			realtime_buffs.append(temp2)
	
	#================================================================================================
	#passing buffs to temp buffs handler
	temp = find_buff(effects, "fast")	#"fast": ["speed", "duration", "party", "behaviour"],
	if temp.size() > 0:
		for i in temp:
			var temp2 = {"node":source, "details":{"anim":"MAX_SPEED", "stat":"MAX_SPEED", "offsets":0, "multiplier":effects[i]["fast"][0]},
				"timer":effects[i]["fast"][1], "applied":false, "party":effects[i]["fast"][2], "behaviour":effects[i]["fast"][3]}
			temp_buffs.append(temp2)
	
	temp = find_buff(effects, "tough")	#"tough": ["def", "duration", "party", "behaviour"],
	if temp.size() > 0:
		for i in temp:
			var temp2 = {"node":source, "details":{"anim":"DEF", "stat":"DEF", "offsets":effects[i]["tough"][0], "multiplier":1},
				"timer":effects[i]["tough"][1], "applied":false, "party":effects[i]["tough"][2], "behaviour":effects[i]["tough"][3]}
			temp_buffs.append(temp2)
	
	temp = find_buff(effects, "strong")	#"strong": ["damage", "duration", "party", "behaviour"]
	if temp.size() > 0:
		for i in temp:
			var temp2 = {"node":source, "details":{"anim":"ATTACK_DAMAGE", "stat":"ATTACK_DAMAGE", "offsets":0, "multiplier":effects[i]["strong"][0]},
				"timer":effects[i]["strong"][1], "applied":false, "party":effects[i]["strong"][2], "behaviour":effects[i]["strong"][3]}
			temp_buffs.append(temp2)
	
	temp = find_buff(effects, "quick")	#"quick": ["aspd", "duration", "party", "behaviour"]
	if temp.size() > 0:
		for i in temp:
			var temp2 = {"node":source, "details":{"anim":"ATTACK_COOLDOWN", "stat":"ATTACK_COOLDOWN", "offsets":0, "multiplier":effects[i]["quick"][0]},
				"timer":effects[i]["quick"][1], "applied":false, "party":effects[i]["quick"][2], "behaviour":effects[i]["quick"][3]}
			temp_buffs.append(temp2)
	
	temp = find_buff(effects, "slow")	#"slow": ["slow", "duration", "party", "behaviour"]
	if temp.size() > 0:
		for i in temp:
			var temp2 = {"node":source, "details":{"anim":"slow", "stat":"MAX_SPEED", "offsets":0, "multiplier":effects[i]["slow"][0]},
				"timer":effects[i]["slow"][1], "applied":false, "party":effects[i]["slow"][2], "behaviour":effects[i]["slow"][3]}
			temp_buffs.append(temp2)
	
	stat_update(source)

func buff_applies_to_party(arg_buff):
	#finds and returns buffs that affect the whole party
	var key = arg_buff.keys()
	var temp_party_buff = {key[0]+"_party": {}}
	for buff_i in arg_buff[key[0]]:
		if buff_i in ["fast", "tough", "strong", "quick", "slow", "regen", "critRate", "critDmg"]:
			if arg_buff[key[0]][buff_i][2] == 1:
				temp_party_buff[key[0]+"_party"][buff_i] = arg_buff[key[0]][buff_i].duplicate()
	return temp_party_buff

func apply_buff_to_party(buff, source):
	if char_nodes.size() > 1:
		for char_n in char_nodes:
			if char_n["node"] != source:
				update_buffs(buff, char_n["node"])
	
func stat_update(source):
	var effects = source.buffs
	var temp_res
	#-------------------------------------------- immediate effect buffs
	temp_res = find_buff(effects, "stun") + find_buff(effects, "stuck")+ find_buff(effects, "freeze")+ find_buff(effects, "knockback")
	if temp_res.size() > 0:
		source.can_move = false
	else:
		source.can_move = true
	
	temp_res = find_buff(effects, "stun")+ find_buff(effects, "freeze")+ find_buff(effects, "knockback")
	if temp_res.size() > 0:
		source.can_attack = false
	else:
		source.can_attack = true
		
	temp_res = find_buff(effects, "heal")
	for i in temp_res:
		if effects[i]["heal"][1]:
			pass #party heal
		else:
			source.HP = min(source.HP+effects[i]["heal"][0], source.MAX_HP)
		source.ui_manipulation(0)
		effects[i].erase("heal")
		if effects[i].empty():
			effects.erase(i)
			
	temp_res = find_buff(effects, "heal_pr")
	for i in temp_res:
		if effects[i]["heal_pr"][2] == false:
			if effects[i]["heal_pr"][1]:
				pass #party
			else:
				source.HP = min(source.HP+effects[i]["heal_pr"][0], source.MAX_HP)
				source.ui_manipulation(0)
			effects[i]["heal_pr"][2] = true

func find_buff(buff_list, buff_name):
	var res = []
	for i in buff_list:
		if typeof(buff_list[i]) != TYPE_BOOL:
			if buff_name in buff_list[i]:
				res.append(i)
	return res

func find_buff_list(buff_list, buff_names):
	var res = []
	for i in buff_list:
		for j in buff_names:
			if j in buff_list[i]:
				res.append(i)
	return res

func is_player(id):
	for i in char_nodes:
		if id == i['node']:
			return true
	return false
	
func get_p_index(source):
	for i in range(0, char_nodes.size()):
		if char_nodes[i]['node'] == source:
			return i
	return -1

func get_e_index(source):
	for i in range(0, enemy_nodes.size()):
		if enemy_nodes[i]['node'] == source:
			return i
	var temp = {'node':source, 'buffs':source.buffs}
	enemy_nodes.append(temp)
	return enemy_nodes.size()-1

func add_character(source):
	char_nodes.append({'node':source, 'buffs':source.buffs})

func enemy_dead(src):
	for i in range(0,enemy_nodes.size()):
		if enemy_nodes[i]['node'] == src:
			enemy_nodes.remove(i)
			break
	for i in realtime_buffs:
		if i["node"] == src:
			realtime_buffs.erase(i)

func clear_list():
	char_nodes.clear()
	enemy_nodes.clear()

#Add buff to main character, usually from item usage
func add_buff(buff):
	#Get target character, will only add, effects will be applied with sec timer
	for i in char_nodes:
		if i["node"].CODE == GameHandler.get_active_char():
			var temp = {}
			if "name" in buff:
				print("add buff apply")
				temp[buff["name"]] = buff["buffs"]
			else:
				print("add buff skip")
				temp = buff
			update_buffs(temp, i["node"])

func knockback_handler(source, knockback, weight):	#if returns true, knockback done, else ongoing
	source.direction = knockback[1]
	if (str(source)+"_knockback") in timers:
		source.apply_movement(timers[str(source)+"_knockback"])
		source.anim_dir = -source.sgn(source.movement.x)
		source.movement = source.move_and_slide(source.movement)
		timers[str(source)+"_knockback"]  *= pow(0.5, weight)
		if timers[str(source)+"_knockback"] <= 1:
			timers.erase(str(source)+"_knockback")
			return true
	else:
		timers[str(source)+"_knockback"] = knockback[0]
	return false

func change_room(old_Id, new_Id):
	#for i in char_nodes: # char nodes are refreshed when changing rooms
		#if i['node'] == old_Id:
			#i['node'] = new_Id
	for i in realtime_buffs:
		if i['node'] == old_Id:
			i['node'] = new_Id
	for i in temp_buffs:
		if i['node'] == old_Id:
			i['node'] = new_Id
			i['applied'] = false #reapply
	for i in reapply:
		if i['node'] == old_Id:
			i['node'] = new_Id

func save_sprites():	#save buff sprites not in temp buffs=
	for i in char_nodes:
		for b in i['buffs']:
			if 'sprite' in i['buffs'][b]:
				reapply.append({"node":i['node'], "path":b, "sprite_animation":i['buffs'][b]['sprite'].get_animation(), "skill_origin":i['buffs'][b]['sprite'].skill_origin})

func load_sprites():	#reapply saved sprites
	for i in reapply:
		var temp = buff_spr_base.instance()
		temp.play(i["sprite_animation"])
		temp.skill_origin = i["skill_origin"]
		i['node'].add_child(temp)
		var index = get_p_index(i['node'])
		char_nodes[index]["buffs"][i['path']]['sprite'] = temp
	reapply.clear()

func room_update():		#when changing rooms, refreshes room delayed buffs
	for i in char_nodes:
		var temp = find_buff_list(i["buffs"],room_delayed_buffs)
		if temp.size() > 0:
			for j in temp:
				for k in room_delayed_buffs:
					if k in i["buffs"][j]:
						i["buffs"][j][k][2] = false

func source_exist(source):
	var res = weakref(source)
	if !res.get_ref():
		return false
	return true

func get_weapon_buff(buffs):
	var weapon_effects = {}
	for i in buffs:
		var temp_effects = {}
		for j in buffs[i]:
			var res = BuffHandler.buff2effect(j, buffs[i][j])
			if res.size() > 0:
				temp_effects[res[0]] = res[1]
		if temp_effects.size() > 0:
			weapon_effects[i] = temp_effects
	return weapon_effects

func buff2effect(buff, effects):	#converts buffs to effects, for weapon related buffs
	#buffs passed must be individual (expects single buff of format "buff" : [ effects ])
	#returns buff in [key, value] array format
	var weaponBuff = {}
	if buff == "burnChance":
		if randf() < effects[3]:
			return ["burn", [effects[1], effects[2], 0, "pause"]]
		else:
			return []
	return []

