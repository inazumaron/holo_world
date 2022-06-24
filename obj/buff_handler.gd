extends Node

var char_nodes = []		#points to character ids
var enemy_nodes = []	#when enemy gets buff_debuff, add here then remove when done
# data format: { 'node': string, 'buffs': [ {'buff name': val}] }

var realtime_buffs = []
#data format: {'node':string, 'type':string, 'details':{}}
#type: "knockback", etc #to add

var timers = {'sec':0}

func _ready():
	set_process(false)

func _process(delta):
	if timers["sec"] > 0:
		timers["sec"] -= delta
	else:
		timers["sec"] = 1
		sec_timer()
	if realtime_buffs.size() > 0:
		realtime_handler()

func sec_timer():
	var src
	var buffs
	for i in (char_nodes + enemy_nodes):
		src = i['node']
		buffs = i['buffs']
		#if "poison" in buffs:
		#	src.damage(buffs["poison"][0])
		#	buffs["poison"][1] -= 1
		#	if buffs["poison"][1] <= 0:
		#		buffs.erase("poison")
		#		src.buffs = buffs
		stat_update(src)

func realtime_handler(): # For buffs that need to be applied realtime
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
					print(enemy_nodes[source]["buffs"])
				realtime_buffs.erase(i)

func damage_handler(damage, effects, buffs, source):
	if !effects.empty():
		update_buffs(effects, source)
	var dam = damage
	if "defense" in buffs:
		dam = damage - buffs["defense"]
		
	if dam > 0:
		if "shield" in buffs:#"shield": ["stack", "duration", "party", "behaviour"],
			buffs["shield"][0] -= 1
			if buffs["shield"][0] <= 0:
				buffs.erase("shield")
				if "shield_sprite" in buffs:
					buffs["shield_sprite"].queue_free()
					buffs.erase("shield_sprite")
			elif "shield_sprite" in buffs:
				var temp = buffs["shield_sprite"]
				if temp.skill_origin == "c132_shield":
					if buffs["shield"][0] >= 3:
						buffs["shield_sprite"].play("n_shield_0")
					elif buffs["shield"][0] == 2:
						buffs["shield_sprite"].play("n_shield_1")
					elif buffs["shield"][0] == 1:
						buffs["shield_sprite"].play("n_shield_2")
		else:
			source.damage(dam)
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
		
	#passing buffs to realtime handler
	var temp = find_buff(effects, "knockback")
	if temp.size() > 0:
		for i in temp:
			var temp2 = {"node":source, "type":"knockback", "details":effects[i]["knockback"], "source_buff":effects["name"]}
			realtime_buffs.append(temp2)
	
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

func find_buff(buff_list, buff_name):
	var res = []
	for i in buff_list:
		if buff_name in buff_list[i]:
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
			i["buffs"][buff["name"]] = buff["buffs"]
			print("p-node - ",char_nodes)

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
