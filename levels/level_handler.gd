extends Node2D

const room_radius = 408
const room_start = 1
const room_end = 14
const o_t = 2 #obstacle thickness, how wide/high a block of obstacle there is
const o_2 = 3
#obstacle placements, first data dictates behaviour of placement, point = treat each vector separately, range - treat pair by pair as range
#obstacle description
# 2 and 3 corridors need to check for door existence
const room_templates = [["blank"],
	["point",Vector2(8,8)],
	["range",Vector2(room_start,room_start),Vector2(room_end,room_start+o_t),Vector2(room_start,room_end-o_t),Vector2(room_end,room_end)],
	["range",Vector2(room_start,room_start),Vector2(room_start+o_t,room_end),Vector2(room_end-o_t,room_start),Vector2(room_end,room_end)],
	["range",Vector2(room_start,room_start),Vector2(room_start+o_t,room_start+o_t),Vector2(room_end-o_t,room_end-o_t),Vector2(room_end,room_end)
	,Vector2(room_end-o_t,room_start),Vector2(room_end,room_start+o_t),Vector2(room_start,room_end-o_t),Vector2(room_start+o_t,room_end)],
	["point",Vector2(room_start+(o_t*2),room_start+(o_t*2)),Vector2(room_end-(o_t*2),room_start+(o_t*2))],
	["range",Vector2(room_start+o_2,room_start+o_2),Vector2(room_end-o_2,room_start+o_2),Vector2(room_start+o_2,room_end-o_2),Vector2(room_end-o_2,room_end-o_2)],
	["range",Vector2(room_start+o_2,room_start+o_2),Vector2(room_start+o_2,room_end-o_2),Vector2(room_end-o_2,room_start+o_2),Vector2(room_end-o_2,room_end-o_2)]
	] 
const room_path = "res://levels/room_graveyard.tscn"

var room = "" # room type like graveyard
var path = [] # array of objects {id:int, left:int, right:int, up:int, down:int, cleared:bool, r_seed:int, coord: vector2} 
var level = 1
var room_count
var max_level_size
var enemy_budget
var level_seed = 0
var active_room_val = 0 # 0 by default, used for easy index getting from path
var active_room = null	# holds actual room 
var door_dir = ""		#for player character entering room, based on prev room exit used
var character = null
var char2 = null
var char3 = null
var char_data = [null, null, null]		#for changing rooms/levels
var door_list = []
var minimap = null

var prev_char
var prev_char2
var prev_char3

var char_base = preload("res://player/132_Noel.tscn")
var char2_base
var char3_base

var room_base = preload(room_path)
var door_base = preload("res://levels/door.tscn")
var minimap_base = preload("res://ui/minimap.tscn")
var recruit_base = preload("res://obj/char_recruit.tscn")
var sfx_base = preload("res://obj/buff_effect.tscn")
var level_up_base = preload("res://obj/levelUp_UI.tscn")
var paused = false

var dialogue_playing = false
var recruiting = false
var recruit_obj
var levelUp_UI = null

func _ready():
	var data_check = GameHandler.get_char_data()
	if data_check != null:
		char_data = data_check
	
	level_seed = GameHandler.get_rng()
	seed(level_seed)
	
	char_base = GameHandler.get_char_path(GameHandler.main_char)
	if GameHandler.co_1_active:
		char2_base = GameHandler.get_char_path(GameHandler.co_char_1)
	if GameHandler.co_2_active:
		char3_base = GameHandler.get_char_path(GameHandler.co_char_2)
	set_process(false)
	compute_stats()
	if path == []:
		generate_path(room_count, max_level_size)
	GameHandler.set_world_id(self)
	
	set_process(true)

func _process(delta):
	if (active_room_val == 0): #auto clear
		path[0]["cleared"] = true
	#constantly check room if enemy cleared, then create doors when clear
	if active_room == null:
		generate_room()
		
	if character == null:
		generate_character()
		ItemHandler.process_passive_proc()
		
	if active_room.cleared and door_list.size() == 0:
		path[active_room_val]["cleared"] = true
		generate_doors()
	
	var clear_doors = false
	if door_list.size() > 0:
		for i in range(0, door_list.size()):
			var temp_door = door_list[i]
			if temp_door.entered:
				door_dir = temp_door.dir
				clear_doors = true
				change_room()
				break
		if clear_doors:
			for i in range(0, door_list.size()):
				door_list[i].queue_free()
			door_list.clear()
			
	if Input.is_action_just_pressed("ui_accept"):
		if paused:
			unpause()
		else:
			pause()
			
	if dialogue_playing:
		if !active_room.dialogue_playing:
			unpause()
			dialogue_playing = false

	if levelUp_UI != null:
		if levelUp_UI.skill_selected:
			var temp_skill_data = levelUp_UI.selected_data
			BuffHandler.add_buff({"name": temp_skill_data["name"], "buffs":temp_skill_data["effects"]})
			levelUp_UI.queue_free()
			levelUp_UI = null
			#return current camera to player
			var temp = GameHandler.get_active_char()
			if temp == character.CODE:
				character.setCamera(true)
			elif temp == char2.CODE:
				char2.setCamera(true)
			else:
				char3.setCamera(true)
			unpause()

func generate_room():
	active_room = room_base.instance()
	active_room.enemy_cost = enemy_budget
	active_room.room_seed = level_seed - room_count + active_room_val
	active_room.cleared = path[active_room_val]["cleared"]
	active_room.char_ids = [character, char2, char3]
	
	if path[active_room_val]["boss_room"] and !path[active_room_val]["cleared"]:
			active_room.boss_room = true
			
	if !active_room.boss_room:
		active_room.generate_obstacles(room_templates[path[active_room_val]["template"]])
	else:
		active_room.boss_room_setup()
	
	add_child(active_room)

func gen_template(data):
	var valid = false
	var i = 0
	while !valid:
		i = randi()%room_templates.size()
		if i == 2:
			if data["up"] == -1 and data["down"] == -1:
				valid = true
		elif i == 3:
			if data["right"] == -1 and data["left"] == -1:
				valid = true
		else:
			valid = true
	return i

func change_room():
	if door_dir != "":
		BuffHandler.clear_list()
		active_room.queue_free()
		active_room_val = path[active_room_val][door_dir]
		generate_room()
	
		char_data[0] = character.send_data()
		prev_char = character
		character.queue_free()
		if char2 != null:
			char_data[1] = char2.send_data()
			prev_char2 = char2
			char2.queue_free()
		if char3 != null:
			char_data[2] = char3.send_data()
			prev_char3 = char3
			char3.queue_free()
		generate_character()
		
		active_room.char_ids = [character, char2, char3]
		active_room.update_enemy_char_list()
		
		character.generate_minimap(path, active_room_val)
		
		BuffHandler.save_sprites()
		BuffHandler.change_room(prev_char, character)
		if char2 != null:
			BuffHandler.change_room(prev_char2, char2)
		if char3 != null:
			BuffHandler.change_room(prev_char3, char3)
		BuffHandler.load_sprites()
		BuffHandler.room_update()
		
		SkillHandler.change_room()
		
		if path[active_room_val]["boss_room"] and !path[active_room_val]["cleared"]:
			#dialogue()
			active_room.boss_hp_ui = character.generate_boss_hp()
			
			if char3 != null:
				active_room.update_bhp_link([char2.generate_boss_hp(), char3.generate_boss_hp()])
			elif char2 != null:
				active_room.update_bhp_link([char2.generate_boss_hp(), null])
	else:
		next_level()
		
func next_level():
	BuffHandler.clear_list()
	active_room.queue_free()
	char_data[0] = character.send_data()
	character.queue_free()
	if char2 != null:
		char_data[1] = char2.send_data()
		char2.queue_free()
	if char3 != null:
		char_data[2] = char3.send_data()
		char3.queue_free()
	GameHandler.set_char_data(char_data)
	GameHandler.change_handler(self,"route")
		
func generate_doors():
	if path[active_room_val]["up"] != -1:
		var temp_door = door_base.instance()
		temp_door.dir = "up"
		temp_door.position = Vector2(0, -room_radius)
		add_child(temp_door)
		door_list.append(temp_door)
	if path[active_room_val]["down"] != -1:
		var temp_door = door_base.instance()
		temp_door.dir = "down"
		temp_door.position = Vector2(0, room_radius)
		add_child(temp_door)
		door_list.append(temp_door)
	if path[active_room_val]["right"] != -1:
		var temp_door = door_base.instance()
		temp_door.dir = "right"
		temp_door.position = Vector2(room_radius, 0)
		add_child(temp_door)
		door_list.append(temp_door)
	if path[active_room_val]["left"] != -1:
		var temp_door = door_base.instance()
		temp_door.dir = "left"
		temp_door.position = Vector2(-room_radius, 0)
		add_child(temp_door)
		door_list.append(temp_door)
	if path[active_room_val]["boss_room"]:
		var temp_door = door_base.instance()
		temp_door.dir = ""
		temp_door.position = Vector2.ZERO
		add_child(temp_door)
		door_list.append(temp_door)

func char_pos_set():
	var coord = Vector2.ZERO
	match door_dir:
		"":
			coord = Vector2.ZERO
		"up":
			coord = Vector2(0, room_radius-64)
		"down":
			coord = Vector2(0, -room_radius+64)
		"right":
			coord = Vector2(-room_radius+64, 0)
		"left":
			coord = Vector2(room_radius-64, 0)
	return coord

func generate_character():
	character = char_base.instance()
	character.position = char_pos_set()
	add_child(character)
	character.generate_minimap(path, active_room_val)
	if char_data[0] != null:
		character.update_data(char_data[0])
	else:
		character.activate(true)	
	BuffHandler.add_character(character)
	
	if char_data[1] != null:
		char2 = char2_base.instance()
		char2.position = char_pos_set()
		add_child(char2)
		char2.generate_minimap(path, active_room_val)
		char2.update_data(char_data[1])
		BuffHandler.add_character(char2)
	if char_data[2] != null:
		char3 = char3_base.instance()
		char3.position = char_pos_set()
		add_child(char3)
		char3.generate_minimap(path, active_room_val)
		char3.update_data(char_data[2])
		BuffHandler.add_character(char3)
		
	ItemHandler.update_items()
	
func compute_stats():
	room_count = floor(pow(level,1.5)) + 5
	max_level_size = ceil(room_count/2)+1
	enemy_budget = 5*floor(pow(level,1.5))

func generate_path(r_count, max_size): #room count and max size of map (nxn)
	var temp_path = []
	var coord = Vector2.ZERO
	while(temp_path.size() < r_count):
		if !(coord in temp_path):
			temp_path.append(coord)
		match (randi()%4+1):
			1: #up
				if coord.y > 0:
					coord.y -= 1
			2: # down
				if coord.y < max_size:
					coord.y += 1
			3: #left
				if coord.x > 0:
					coord.x -= 1
			4: # right
				if coord.x < max_size:
					coord.x += 1
	for i in range(0, temp_path.size()):
		var cell = temp_path[i]
		var temp_cell = {"value":i, 
		"left":temp_path.find(Vector2(cell.x-1, cell.y)), 
		"right":temp_path.find(Vector2(cell.x+1, cell.y)), 
		"up":temp_path.find(Vector2(cell.x, cell.y-1)), 
		"down":temp_path.find(Vector2(cell.x, cell.y+1)), 
		"cleared":false, "r_seed":randi(), "coord":cell, "template":0}
		temp_cell["template"] = gen_template(temp_cell)
		if i == temp_path.size()-1:
			temp_cell["boss_room"] = true
		else:
			temp_cell["boss_room"] = false
		path.append(temp_cell)

func dialogue():
	pause()
	active_room.dialogue_playing = true
	active_room.play_dialogue()
	active_room.textbox.rect_position = character.position + Vector2(-200, 200)
	dialogue_playing = true

func pause():
	var active_char = GameHandler.get_active_char()
	active_room.pause()
	if character.CODE == active_char:
		character.ACTIVE = false
		character.toggle_ui(false)
	if char2 != null:
		if char2.CODE == active_char:
			char2.ACTIVE = false
			char2.toggle_ui(false)
	if char3 != null:
		if char3.CODE == active_char:
			char3.ACTIVE = false
			char3.toggle_ui(false)
	paused = true
	ItemHandler.set_process(false)
	print("paused")

func unpause():
	var active_char = GameHandler.get_active_char()
	active_room.unpause()
	if character.CODE == active_char:
		character.ACTIVE = true
		character.toggle_ui(true)
	if char2 != null:
		if char2.CODE == active_char:
			char2.ACTIVE = true
			char2.toggle_ui(true)
	if char3 != null:
		if char3.CODE == active_char:
			char3.ACTIVE = true
			char3.toggle_ui(true)
	paused = false
	ItemHandler.set_process(true)
	print("resumed")

func update_player_items(x,y,l1,l2):
	character.ui_item_update_anim(x,y,l1,l2)
	if char2 != null:
		char2.ui_item_update_anim(x,y,l1,l2)
	if char3 != null:
		char3.ui_item_update_anim(x,y,l1,l2)

func recruit_ui():
	if char2 == null or char3 == null:
		pause()
		recruit_obj = recruit_base.instance()
		recruiting = true
		var temp_codes = active_room.recruit_char_codes
		var temp_paths = active_room.recruit_char_paths
		
		if character.CODE in temp_codes:
			var i = temp_codes.find(character.CODE,0)
			temp_codes.remove(i)
			temp_paths.remove(i)
		
		if char2 != null:
			if char2.CODE in temp_codes:
				var i = temp_codes.find(character.CODE,0)
				temp_codes.remove(i)
				temp_paths.remove(i)
		
		recruit_obj.card_paths = temp_paths
		recruit_obj.card_vals = temp_codes
		recruit_obj.scale = Vector2(0.4,0.4)
		add_child(recruit_obj)

func load_unit(dest, obj):	#For getting preloaded data
	#mainly used for recruiting characters mid room, so needing to preload midway
	if dest == 0:#this case shouldnt happen
		char_base = obj
	if dest == 1:
		char2_base = obj
		char2 = char2_base.instance()
		add_child(char2)
		char2.generate_minimap(path, active_room_val)
		BuffHandler.add_character(char2)
	if dest == 2:
		char3_base = obj
		char3 = char3_base.instance()
		add_child(char3)
		char3.generate_minimap(path, active_room_val)
		BuffHandler.add_character(char3)
	active_room.char_ids = [character, char2, char3]
	active_room.update_enemy_char_list()
	unpause()

func change_active_unit(x,y): #x - new unit, y - old unit
	var pos
	if y == 0:
		pos = character.position
	if y == 1:
		pos = char2.position
	if y == 2:
		pos = char3.position
	
	character.activate(false)
	if char2 != null:
		char2.activate(false)
	if char3 != null:
		char3.activate(false)
		
	if x == 0:
		character.activate(true)
		character.position = pos
	if x == 1:
		char2.activate(true)
		char2.position = pos
	if x == 2:
		char3.activate(true)
		char3.position = pos
		
	active_room.character_switch()

func generate_sfx(sfx_name, source):
	var sfx_obj = sfx_base.instance()
	sfx_obj.play(sfx_name)
	sfx_obj.position = source.position
	sfx_obj.free_after = true
	get_tree().get_root().add_child(sfx_obj)

func get_char_skill_list(code):
	if code == character.CODE:
		return character.SKILL_LIST
	if code == char2.CODE:
		return char2.SKILL_LIST
	if code == char3.CODE:
		return char3.SKILL_LIST

func level_up_ui(code, level):
	levelUp_UI = level_up_base.instance()
	levelUp_UI.code = code
	#levelUp_UI.preloaded_textures = textures
	levelUp_UI.curr_skills = get_char_skill_list(code)
	levelUp_UI.level = level
	pause()
	get_tree().get_root().add_child(levelUp_UI)
	levelUp_UI.setCamera(true)
