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

var char_base = preload("res://player/J305_Noel.tscn")
var room_base = preload(room_path)
var door_base = preload("res://levels/door.tscn")
var minimap_base = preload("res://ui/minimap.tscn")

func _ready():
	seed(0)
	set_process(false)
	if level_seed == 0:
		level_seed = randi()
	compute_stats()
	if path == []:
		generate_path(room_count, max_level_size, level_seed)
	
	set_process(true)

func _process(delta):
	if (active_room_val == 0): #auto clear
		path[0]["cleared"] = true
	#constantly check room if enemy cleared, then create doors when clear
	if active_room == null:
		generate_room()
		
	if character == null:
		generate_character()
		character.generate_minimap(path, active_room_val)
		
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

func generate_room():
	active_room = room_base.instance()
	active_room.enemy_cost = enemy_budget
	active_room.room_seed = level_seed - room_count + active_room_val
	active_room.cleared = path[active_room_val]["cleared"]
	active_room.generate_obstacles(room_templates[path[active_room_val]["template"]])
	print("template: ",path[active_room_val]["template"])
	add_child(active_room)

func gen_template(data):
	var valid = false
	var i = 0
	while !valid:
		i = randi()%room_templates.size()
		if i == 2:
			print("template 2 ", data)
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
		character.queue_free()
		if char2 != null:
			char_data[1] = char2.send_data()
			char2.queue_free()
		if char3 != null:
			char_data[2] = char3.send_data()
			char3.queue_free()
		generate_character()
		character.generate_minimap(path, active_room_val)
	else:
		next_level()
		
func next_level():
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
	if char_data[0] != null:
		character.update_data(char_data[0])
	else:
		character.activate(true)	
	BuffHandler.add_character(character)
	
	if char_data[1] != null:
		char2 = char_base.instance()
		char2.position = char_pos_set()
		add_child(char2)
		char2.update_data(char_data[1])
		BuffHandler.add_character(char2)
	if char_data[2] != null:
		char3 = char_base.instance()
		char3.position = char_pos_set()
		add_child(char3)
		char3.update_data(char_data[2])
		BuffHandler.add_character(char3)
	
func compute_stats():
	room_count = floor(pow(level,1.5)) + 5
	max_level_size = ceil(room_count/2)+1
	enemy_budget = 2*floor(pow(level,1.5))

func generate_path(r_count, max_size, l_seed): #room count and max size of map (nxn)
	rand_seed(l_seed)
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
