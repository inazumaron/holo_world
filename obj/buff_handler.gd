extends Node

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

const room_delayed_buffs = ["heal_pr"] #just update this
#sec timer deals with buffs that is applied every second, i.e. poison, DoT stuff, HoT

var timers = {'sec':0}

const buff_spr_base = preload("res://obj/buff_effect.tscn")

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
		stat_update(src)

func realtime_handler(delta): # For buffs that need to be applied realtime
	for i in realtime_buffs:
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
	
func temp_buff_handler(delta):
	for i in temp_buffs:
		if !is_instance_valid(i['node']):
			temp_buffs.erase(i)
			continue
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
			buff_sprite.play(i['details']['stat'])
			i['node'].add_child(buff_sprite)
			i['sprite'] = buff_sprite

func damage_handler(damage, effects, buffs, source):
	if !effects.empty():
		update_buffs(effects, source)
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
		var i = get_p_index(source)
		char_nodes[i]['buffs'][effects["name"]] = effects["buffs"]
		var x = char_nodes[i]['node']
		x.buffs = char_nodes[i]['buffs']
	else:
		var i = get_e_index(source)
		enemy_nodes[i]['buffs'][effects["name"]] = effects["buffs"]
		var x = enemy_nodes[i]['node']
		x.buffs = enemy_nodes[i]['buffs']
		
	#================================================================================================
	#passing buffs to realtime handler
	var temp = find_buff(effects, "knockback")
	if temp.size() > 0:
		for i in temp:
			var temp2 = {"node":source, "type":"knockback", "details":effects[i]["knockback"], "source_buff":effects["name"]}
			realtime_buffs.append(temp2)
	
	#================================================================================================
	#passing buffs to temp buffs handler
	temp = find_buff(effects, "fast")	#"fast": ["speed", "duration", "party", "behaviour"],
	if temp.size() > 0:
		for i in temp:
			var temp2 = {"node":source, "details":{"stat":"MAX_SPEED", "offsets":0, "multiplier":effects[i]["fast"][0]},
				"timer":effects[i]["fast"][1], "applied":false, "party":effects[i]["fast"][2], "behaviour":effects[i]["fast"][3]}
			temp_buffs.append(temp2)
	
	temp = find_buff(effects, "tough")	#"tough": ["def", "duration", "party", "behaviour"],
	if temp.size() > 0:
		for i in temp:
			var temp2 = {"node":source, "details":{"stat":"DEF", "offsets":effects[i]["tough"][0], "multiplier":1},
				"timer":effects[i]["tough"][1], "applied":false, "party":effects[i]["tough"][2], "behaviour":effects[i]["tough"][3]}
			temp_buffs.append(temp2)
	
	temp = find_buff(effects, "strong")	#"strong": ["damage", "duration", "party", "behaviour"]
	if temp.size() > 0:
		for i in temp:
			var temp2 = {"node":source, "details":{"stat":"ATTACK_DAMAGE", "offsets":0, "multiplier":effects[i]["strong"][0]},
				"timer":effects[i]["strong"][1], "applied":false, "party":effects[i]["strong"][2], "behaviour":effects[i]["strong"][3]}
			temp_buffs.append(temp2)
	
	temp = find_buff(effects, "quick")	#"quick": ["aspd", "duration", "party", "behaviour"]
	if temp.size() > 0:
		for i in temp:
			var temp2 = {"node":source, "details":{"stat":"ATTACK_COOLDOWN", "offsets":0, "multiplier":effects[i]["quick"][0]},
				"timer":effects[i]["quick"][1], "applied":false, "party":effects[i]["quick"][2], "behaviour":effects[i]["quick"][3]}
			temp_buffs.append(temp2)
	
	stat_update(source)
	
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
	var present = false
	for i in char_nodes:
		if i['node'] == source:
			present = true
	if !present:
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
			update_buffs(buff, i["node"])

func knockback_handler(source, knockback, weight):	#if returns true, knockback done, else ongoing
	source.direction = knockback[1]
	if (str(source)+"_knockback") in timers:
		source.apply_movement(timers[str(source)+"_knockback"])
		source.anim_dir = -source.sgn(source.movement.x)
		source.movement = source.move_and_slide(source.movement)
		timers[str(source)+"_knockback"]  *= pow(0.95, weight)
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
