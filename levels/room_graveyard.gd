extends Node2D

#===============================================================================
#==== Creating new rooms will only require you to change this part =============
#===============================================================================
#		*unless of course adding new features

#Variables
const wall = true # for tiles extending 2 tiles
const variation = 2 #amount of variation of same tiles 1-no variety
const tile = {
	"path":0, "up":2, "wall":4, "blank":6, "left":8, "right":10, "down":12, "uleft": 14, "uright":16, "wleft":18,
	"wright":20, "lleft":22, "lright":24}
const enemy_data = [
	{"name":"zombie_basic","level":1,"cost":1}
	]
const hazard_data = [
	{"name":"gy_vines_","level":1, "cost":1, "vars":2, "data":{
		"onEntry":true, "damage":1
	}},
	{"name":"gy_swamp_", "level":1, "cost":1, "vars":2, "data":{
		"onEntry":true, "continious":true, "effects":{"name":"swampSlow", "buffs":{"slow":[0.5, 1, 1, "bg"]}}
	}}
]
const obs_base = preload("res://levels/obstacle_small.tscn")
const e_1_1 = preload("res://enemies/gy_zombie_basic.tscn")
const boss_base = preload("res://enemies/boss.tscn")

const chp_1 = preload("res://resc/cards/char_card_flare.png")
const chp_2 = preload("res://resc/cards/char_card_noel.png")
const chp_3 = preload("res://resc/cards/char_card_pekora.png")
const recruit_char_codes = [130,132,133]
const recruit_char_paths = [chp_1,chp_2,chp_3]

var boss_room = false
const boss_dialogue = [["Nee...", "What do you think you're doing here", "You wanna die?"]]
const boss_main = ["I see", "You want to take everything away from me huh", "Id like to see you try"]
var boss_hp_ui = "temp"

#Function/s
func create_enemies():
	if !boss_room:
		while enemy_cost > 0:
			var i = rng.randi()%enemy_bases.size()
			match enemy_bases[i]["name"]:
				"zombie_basic":
					var temp = e_1_1.instance()
					temp.position = (enemy_pos[rng.randi()%enemy_pos.size()] - screen_offset) * 64
					temp.SEED = rng.randi()
					add_child(temp)
					enemy_list.append(temp)
					enemy_cost -= enemy_bases[i]["cost"]

#===============================================================================
#======== Dont edit past this unless you know what you're doing ================
#===============================================================================

const screen_size = 24 #size range of blank blocks
const room_size = 13 # size of walkable room
const border = floor((screen_size-room_size)/2)
const screen_offset = Vector2((screen_size/2)-border,(screen_size/2)-border)
const obs_offset = Vector2(32, 32)
const hazard_base = preload("res://obj/level_hazards.tscn")

var dialogue_playing = false
var dialogue_page = 0
var dialogue_text_len = 0
var dialogue_text_max = 0
var dialogue_script = boss_dialogue[0]
var next_dialogue_click = false				#enable clicking to go to next dialogue page

var cleared = false
var enemy_cost = 0
var room_seed = 0
var hazard_cost = 3
var enemy_bases = []
var enemy_list = []
var hazard_list = []
var obs_list = []
var level = 1
var rng = RandomNumberGenerator.new()
var enemy_pos = null

onready var tilemap = $TileMap
onready var textbox = $TextBox/data

func _ready():
	set_process(false)
	rng.seed  = room_seed
	create_room()
	preload_items()
	generate_hazards()
	if !cleared:
		create_enemies()
		set_process(true)
	tilemap.z_index = 0
	$TextBox.z_index = 2
	$TextBox/Sprite.visible = false
	
func _process(delta):
	var all_dead = true
	for i in range(0, enemy_list.size()):
		if enemy_list[i].dead:
			BuffHandler.enemy_dead(enemy_list[i])
			GameHandler.add_xp(enemy_list[i].XP)
			enemy_list[i].queue_free()
			enemy_list.remove(i)
			break
	if enemy_list.size() == 0:
		cleared = true
	if cleared:
		set_process(false)
		
	if next_dialogue_click and dialogue_playing:
		if Input.is_action_just_pressed("mouse_click"):
			next_dialogue_click = false
			dialogue_page += 1
			play_dialogue()

func boss_room_setup():
	enemy_cost = 0
	var temp_boss = boss_base.instance()
	temp_boss.position = Vector2.ZERO
	temp_boss.hp_ui = boss_hp_ui
	add_child(temp_boss)
	enemy_list.append(temp_boss)

func create_room():
	for y in range(0, screen_size):
		for x in range(0, screen_size):
			if (y < border or y > (screen_size-border) or x < border or x > (screen_size-border)):
				if ((y+1) == border) and wall and (x>border and x < screen_size-border):
					tilemap.set_cellv(Vector2(x-(screen_size/2),y-(screen_size/2)),tile["wall"] + randi()%variation)
				else:
					tilemap.set_cellv(Vector2(x-(screen_size/2),y-(screen_size/2)),tile["blank"] + randi()%variation)
			if (y == (screen_size-border) and x > border and x < (screen_size-border)):
				tilemap.set_cellv(Vector2(x-(screen_size/2),y-(screen_size/2)),tile["down"] + randi()%variation)
			if (y == border and x > border and x < (screen_size-border)):
				tilemap.set_cellv(Vector2(x-(screen_size/2),y-(screen_size/2)),tile["up"] + randi()%variation)
			if (x == (screen_size-border) and y > border and y < (screen_size-border)):
				tilemap.set_cellv(Vector2(x-(screen_size/2),y-(screen_size/2)),tile["right"] + randi()%variation)
			if (x == border and y > border and y < (screen_size-border)):
				tilemap.set_cellv(Vector2(x-(screen_size/2),y-(screen_size/2)),tile["left"] + randi()%variation)
			if (x == border and y == border):
				tilemap.set_cellv(Vector2(x-(screen_size/2),y-(screen_size/2)),tile["uleft"] + randi()%variation)
				if wall:
					tilemap.set_cellv(Vector2(x-(screen_size/2),y-(screen_size/2)-1),tile["wleft"] + randi()%variation)
			if (x == (screen_size-border) and y == border):
				tilemap.set_cellv(Vector2(x-(screen_size/2),y-(screen_size/2)),tile["uright"] + randi()%variation)
				if wall:
					tilemap.set_cellv(Vector2(x-(screen_size/2),y-(screen_size/2)-1),tile["wright"] + randi()%variation)
			if (x == (screen_size-border) and y == (screen_size-border)):
				tilemap.set_cellv(Vector2(x-(screen_size/2),y-(screen_size/2)),tile["lright"] + randi()%variation)
			if (x == border and y == (screen_size-border)):
				tilemap.set_cellv(Vector2(x-(screen_size/2),y-(screen_size/2)),tile["lleft"] + randi()%variation)
			if(x > border and x < (screen_size-border) and y > border and y < (screen_size-border)):
				tilemap.set_cellv(Vector2(x-(screen_size/2),y-(screen_size/2)),tile["path"] + randi()%variation)

func preload_items():
	for i in enemy_data:
		if i["level"] <= level:
			enemy_bases.append(i)
		
func generate_obstacles(data):
	var temp_obs
	match data[0]:
		"point":
			for i in range(1,data.size()):
				temp_obs = obs_base.instance()
				temp_obs.position = (data[i]-screen_offset)*64
				temp_obs.z_index = 1
				add_child(temp_obs)
				obs_list.append(temp_obs)
		"range":
			for i in range(1,data.size()):
				if i%2 == 1:
					var a = data[i]
					var b = data[i+1]
					for x in range(a.x, b.x):
						for y in range(a.y, b.y):
							temp_obs = obs_base.instance()
							temp_obs.position = (Vector2(x,y)-screen_offset)*64 + obs_offset
							temp_obs.z_index = 1
							add_child(temp_obs)
							obs_list.append(temp_obs)
	gen_enemy_pos(data)

func generate_hazards():
	while hazard_cost > 0:
		var pos = Vector2((randi()%room_size-3)+2,(randi()%room_size-3)+2)
		var hazard = hazard_base.instance()
		var h_data = hazard_data[randi()%hazard_data.size()]
		var variant = ""
		if "vars" in h_data:
			variant = str((randi()%h_data["vars"])+1)
		hazard.position = pos * 32
		hazard.play(h_data["name"]+variant)
		hazard_list.append(hazard)
		hazard.set_data(h_data["data"])
		add_child(hazard)
		hazard_cost -= h_data["cost"]

func gen_enemy_pos(data):
	enemy_pos = []
	for x in range(2,room_size-1):
		for y in range(2, room_size-1):
			if data[0] == "blank":
				enemy_pos.append(Vector2(x,y))
			if data[0] == "point":
				if !(Vector2(x,y) in data):
					enemy_pos.append(Vector2(x,y))
			if data[0] == "range":
				var clear = true
				var i = 1
				while i < data.size():
					var r1 = data[i]
					var r2 = data[i+1]
					if x >= r1.x and x <= r2.x and y >= r1.y and y <= r2.y:
						clear = false
						break
					i+= 2
				if clear:
					enemy_pos.append(Vector2(x,y))

func pause():
	BuffHandler.set_process(false)
	for e in enemy_list:
		e.set_process(false)

func unpause():
	BuffHandler.set_process(true)
	for e in enemy_list:
		e.set_process(true)

func play_dialogue():
	if dialogue_page < dialogue_script.size():
		textbox.set_bbcode(dialogue_script[dialogue_page])
		textbox.set_visible_characters(0)
		dialogue_text_max = dialogue_script[dialogue_page].length()
		dialogue_text_len = 1
		$Timer.start(0)
	else:
		$TextBox/Sprite.visible = false
		textbox.set_bbcode("")
		dialogue_playing = false

func play_dialogue_text():
	$TextBox/Sprite.visible = true
	textbox.set_visible_characters(dialogue_text_len)
	dialogue_text_len += 1
	if dialogue_text_len > dialogue_text_max:
		$Timer.stop()
		next_dialogue_click = true

func _on_Timer_timeout():
	play_dialogue_text()
