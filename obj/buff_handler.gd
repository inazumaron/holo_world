extends Node

var char_nodes = []		#points to character ids
var enemy_nodes = []	#when enemy gets buff_debuff, add here then remove when done

# data format: { 'node': string, 'buffs': [ {'buff name': val}] }

var timers = {'sec':0}

func _ready():
	set_process(false)

func _process(delta):
	if timers["sec"] > 0:
		timers["sec"] -= delta
	else:
		timers["sec"] = 1
		sec_timer()

func sec_timer():
	var src
	var buffs
	for i in (char_nodes + enemy_nodes):
		src = i['node']
		buffs = i['buffs']
		if "poison" in buffs:
			src.damage(buffs["poison"][0])
			buffs["poison"][1] -= 1
			if buffs["poison"][1] <= 0:
				buffs.erase("poison")
				src.buffs = buffs
		stat_update(src)

func damage_handler(damage, effects, buffs, source):
	update_buffs(effects, source)
	var dam = damage
	if "defense" in buffs:
		dam = damage - buffs["defense"]
		
	if dam > 0:
		source.damage(dam)
	else:
		source.damage(0)

func update_buffs(effects, source):
	if is_player(source):
		var i = get_p_index(source)
		for e in effects:
			char_nodes[i]['buffs'][e] = effects[e]
		var x = char_nodes[i]['node']
		x.buffs = char_nodes[i]['buffs']
	else:
		var i = get_e_index(source)
		for e in effects:
			enemy_nodes[i]['buffs'][e] = effects[e]
		var x = enemy_nodes[i]['node']
		x.buffs = enemy_nodes[i]['buffs']
	stat_update(source)
	
func stat_update(source):
	var effects = source.buffs
	#-------------------------------------------- immediate effect buffs
	if "stun" in effects || "stuck" in effects || "freeze" in effects || "knockback" in effects:
		source.can_move = false
	else:
		source.can_move = true

	if "stun" in effects || "freeze" in effects || "knockback" in effects:
		source.can_attack = false
	else:
		source.can_attack = true

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

func clear_list():
	char_nodes.clear()
	enemy_nodes.clear()
