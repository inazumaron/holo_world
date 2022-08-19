extends Node2D
#For holding variable values

const char_paths = {
	"130": preload("res://player/130_Flare.tscn"),
	"132": preload("res://player/132_Noel.tscn"),
	"133": preload("res://player/133_Pekora.tscn")
}

const skill_textures = {
	
}

#Character related data
var active_character = 0 #0- main, 1,2 collab
var main_char = 132		#change later or not. by default noel will be main char rn
var main_char_stats = {"CHAR_CODE":0, "HP": 0, "BUFFS":{}, "SPECIAL_CODE":0}
var main_char_level = {"EXP":0, "LVL":1}
	#Special code will just simply correspond to ability ID, 0 means no skill
var co_1_active = false
var co_char_1 = 0
var co_char_1_stats = main_char_stats.duplicate(true)
var co_char_1_level = {"EXP":0, "LVL":1}
var co_2_active = false
var co_char_2 = 0
var co_char_2_stats = main_char_stats.duplicate(true)
var co_char_2_level = {"EXP":0, "LVL":1}

const xp_vals = [5, 150, 225, 325, 450, 575, 725, 900, 1100, 1350]	
	#needed amount of xp to level up, index indicate current level + 1
	#xp given by enemy scales with their costs, boss gives 100 + (level - 1) * 50

var item1 = "pekora_collab"
var item2 = "flare_collab"

#Game related data
var level = 1
var level_list = []

const MAX_LEVELS = 10		#how many levels 
const WORLD_NUM = 5		#amount of available worlds
const room_radius = 408
var curr_world_id = "none"		#refers to level handler id

var worlds = []
var pos = Vector2(0, MAX_LEVELS-1)
var next_step = "none"
var player_pos = Vector2.ZERO

var level_val = ""

func _ready():
	load_skill_icons()

func change_handler(x,y):
	x.queue_free()
	BuffHandler.set_process(false)
	if y == "charSel":
		get_tree().change_scene("res://obj/charSel_handler.tscn")
	if y == "route":
		get_tree().change_scene("res://obj/route_handler.tscn")
	if y == "level":
		BuffHandler.set_process(true)
		ItemHandler.set_process(true)
		get_tree().change_scene("res://levels/level_handler.tscn")

#============================================  route handling
func generate_worlds(base):
	if len(worlds) == 0:
		randomize()
		for j in range(0,MAX_LEVELS):
			var temp = []
			for i in range(0,MAX_LEVELS):
				if j == 0:
					temp.append(base)
				else:
					var n = randi() % WORLD_NUM
					while n == base:
						n = randi() % WORLD_NUM
					temp.append(n)
			worlds.append(temp)
	return worlds
	
func move():
	if next_step == "left":
		pos.y -= 1
		pos.x = (MAX_LEVELS + int(pos.x - 1)) % MAX_LEVELS
	if next_step == "up":
		pos.y -= 1
	if next_step == "right":
		pos.y -= 1
		pos.x = int(pos.x + 1) % MAX_LEVELS
	next_step = "none"
	level += 1
	return pos

#============================================  level/character handling
func is_char_blank(n):
	if n == main_char:
		if main_char_stats["CHAR_CODE"] == 0:
			return true
		return false
	if n == co_char_1:
		if co_char_1_stats["CHAR_CODE"] == 0:
			return true
		return false
	if n == co_char_2:
		if co_char_2_stats["CHAR_CODE"] == 0:
			return true
		return false

func update_char_stat(n, stats):
	if n == main_char:
		main_char_stats = stats
	if n == co_char_1:
		co_char_1_stats = stats
	if n == co_char_2:
		co_char_2_stats = stats

func save_data(data):
	var file = File.new()
	
	file.open("res://Data/save.sv", File.WRITE)
	file.store_string(var2str(data))
	file.close()
	
func load_data(path):
	var file = File.new()
	
	file.open(path, File.READ)
	var data = str2var(file.get_as_text())
	file.close()
	
	return data

func collab_recruit(stats,slot):
	var return_val = 0
	if slot == 1:
		if active_character == 0:
			return_val = main_char
		else:
			return_val = co_char_2
		active_character = 1
		co_1_active = true
		co_char_1_stats = stats
		co_char_1 = stats["CHAR_CODE"]
		curr_world_id.collab_recruit(slot,true)
		active_character = 1
	if slot == 2:
		if active_character == 0:
			return_val = main_char
		else:
			return_val = co_char_1
		active_character = 2
		co_2_active = true
		co_char_2_stats = stats
		co_char_2 = stats["CHAR_CODE"]
		curr_world_id.collab_recruit(slot,true)
		active_character = 2
	return return_val

func switch_char(code):
	var return_val = 0
	if active_character == 0:
		if code == co_char_1:
			active_character = 1
		if code == co_char_2:
			active_character = 2
		return_val = main_char
	elif active_character == 1:
		if code == main_char:
			active_character = 0
		if code == co_char_2:
			active_character = 2
		return_val = co_char_1
	else:
		if code == co_char_1:
			active_character = 1
		if code == main_char:
			active_character = 0
		return_val = co_char_2
	curr_world_id.switch_active_char(active_character)
	return return_val

func update_item(x,y,l1,l2):
	#x and y contains strings, with the name of the new item
	curr_world_id.update_player_items(x,y,l1,l2)

func pause_game():
	curr_world_id.pause()

func recruit(): #open recruit system in level
	if !co_2_active:	#check if can recruit
		curr_world_id.recruit_ui()

func recruit_char(code): #recruit character
	if co_1_active:
		co_2_active = true
		co_char_2 = code
		curr_world_id.load_unit(2, char_paths[str(code)])
	else:
		co_1_active = true
		co_char_1 = code
		curr_world_id.load_unit(1, char_paths[str(code)])
	ItemHandler.add_item(str(code))

func switch_character(code):
	var temp = active_character
	
	if main_char == code:
		active_character = 0
	if co_char_1 == code:
		active_character = 1
	if co_char_2 == code:
		active_character = 2
	
	curr_world_id.change_active_unit(active_character, temp)

func generate_char_sfx(sfx_name):
	var source
	if active_character == 0:
		source = curr_world_id.character
	if active_character == 1:
		source = curr_world_id.char2
	if active_character == 2:
		source = curr_world_id.char3
	curr_world_id.generate_sfx(sfx_name, source)

func add_xp(xp):
	var res
	var code
	if active_character == 0:
		res = calc_xp(main_char_level, xp)
		code = main_char
	if active_character == 1:
		res = calc_xp(co_char_1_level, xp)
		code = co_char_1
	if active_character == 2:
		res = calc_xp(co_char_2_level, xp)
		code = co_char_2
	if res[1] > 0:
		curr_world_id.level_up_ui(code, res[0]["LVL"])

func calc_xp(data, xp):
	data["EXP"] += xp
	var level_ups = 0
	while data["EXP"] >= xp_vals[data["LVL"] - 1]:
		data["EXP"] -= xp_vals[data["LVL"] - 1]
		data["LVL"] += 1
		level_ups += 1
	return [data, level_ups]
#============================================  get var funcitons
func get_char_stat(n):
	if n == main_char:
		return main_char_stats
	if n == co_char_1:
		return co_char_1_stats
	if n == co_char_2:
		return co_char_2_stats

func get_active_char(): #Returns active character code
	if active_character == 0:
		return main_char
	if active_character == 1:
		return co_char_1
	if active_character == 2:
		return co_char_2

func get_char_pos():
	if active_character == 0:
		return curr_world_id.character.global_position
	if active_character == 1:
		return curr_world_id.char2.global_position
	if active_character == 2:
		return curr_world_id.char3.global_position

func get_boss_hp_ui():
	if active_character == 0:
		return curr_world_id.character.generate_boss_hp()
	if active_character == 1:
		return curr_world_id.char2.generate_boss_hp()
	if active_character == 2:
		return curr_world_id.char3.generate_boss_hp()

func get_char_path(x):
	if typeof(x) ==  TYPE_STRING:
		return char_paths[x]
	else:
		return char_paths[str(x)]

#============================================  set var functions
func set_next_step(x):
	next_step = x

func set_level_val(val):
	level_val = val
	
func set_world_id(id):
	curr_world_id = id

func set_main_char(x):
	main_char = x

#==============================================  misc functions
var skill_icons = {}

func load_skill_icons():
	var path = "res://resc/skills/"
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file_name = dir.get_next()
		if file_name == "":
			#break the while loop when get_next() returns ""
			break
		elif !file_name.begins_with(".") and !file_name.ends_with(".import"):
			#if !file_name.ends_with(".import"):
			file_name.erase(file_name.length()-4,4)
			skill_icons[file_name] = load(path + "/" + file_name + ".png")
	dir.list_dir_end()

func get_skill_icon(x):
	return skill_icons[x]
