extends Node

const blank = {"name":"Blank","type":"none"}
var item1 = {"name":"Watson concoction", "type":"Stack", "effect":"Buff", "stack_count":5, 
		"effect_details":{"quick": [.6, 20, 0, "temp"], "fast": [1.5, 20, 1, "temp"]}}
var item2 = {"name":"Ticket", "type":"Single_use", "effect":"Recruit"}

var item_r_cooldown = [1,1]	#for room type cooldowns, turns to 1 on next not cleared room, 0 when used
var item_cooldowns = [0,0]	#for cooldowns not room type, process will handle this part

var can_use = true		#item cooldown
var cooldown = 0

var passive_processed = false

const item_list = {
	"Ticket":
		{"name":"Ticket", "type":"Single_use", "effect":"Recruit"},
	"Universal ticket":
		{"name":"Universal ticket", "type":"Single_use", "effect":"Recruit"},
	"Nakirium":
		{"name":"Nakirium", "type":"Stack", "effect":"Buff", "stack_count":3, 
		"effect_details":{"heal": [5, 0]}},
	"Watson concoction":
		{"name":"Watson concoction", "type":"Stack", "effect":"Buff", "stack_count":5, 
		"effect_details":{"quick": [.6, 20, 0, "temp"], "fast": [1.5, 20, 1, "temp"]}},
	"Asacoco":
		{"name":"Asacoco", "type":"Stack", "effect":"Buff", "stack_count":3, 
		"effect_details":{"strong": [2, 15, 0, "bg"],"tough": [1, 15, 0, "bg"]}},
	"Bloop":
		{"name":"Bloop", "type":"Passive", "effect":"Buff", "effect_details":{"heal_pr":[2,0, false]}, "cooldown":"room"},
	"Kiara's feather":
		{"name":"Kiara's feather", "type":"Passive", "effect":"Buff", 
		"effect_details":{"revive": [1, 1, 1], "source":"item", "source_details":"Kiara's feather"}},
	"Ame's Watch":
		{"name":"Ame's Watch", "type":"Unlimited", "effect":"Skill", "cooldown":"room", "skill_name":""},
	"Ao chan":
		{"name":"Ao chan", "type":"Unlimited", "effect":"Skill", "cooldown":"room", "skill_name":""},
	#-------------------------------------Character portraits portion
	"130":
		{"name":"130", "type":"Switch"},
	"131":
		{"name":"131", "type":"Switch"},
	"132":
		{"name":"132", "type":"Switch"},
	"133":
		{"name":"133", "type":"Switch"},
	"134":
		{"name":"134", "type":"Switch"},
}

func item_details():
	#Types
	#	Single_use
	#	Passive
	#	Stack		-	will have 'stack_count'
	#	Unlimited	-	WIll have 'cooldown' and 'cooldown_val' (if not room)
	#					- cooldown types: room, auto, attack, defend
	#	Switch		-	For switching characters
	#Effects
	#	Buff		-	will include 'effect_details'
	#	Recruit
	#	Switch		-	For switching characters
	#	Skill		-	For casting some kind of skill not buff related, must have 'skill_name'
	#Cooldown
	#	Room		-	Replenishes at the start of a non cleared room
	#	Auto		-	Replenishes after a interval
	#	Offense		-	Replenishes when hitting an enemy
	#	Defense		-	Replenishes when hit
	#				-	Non room will have an extra field 'cooldown_duration'
	pass

func _ready():
	set_process(false)

func _process(delta):
	if Input.is_action_just_pressed("ui_item_1") and can_use:
		use_item(0)
		can_use = false
		cooldown = 1
	if Input.is_action_just_pressed("ui_item_2") and can_use:
		use_item(1)
		can_use = false
		cooldown = 1
	
	if cooldown > 0:
		cooldown -= delta
	else:
		can_use = true

func use_item(x):
	if x:
		if(item2["type"] == "Single_use"):
			t_single_use(x)
		if(item2["type"] == "Stack"):
			t_stack(x)
		if(item2["type"] == "Unlimited"):
			t_unlimited(x)
		if(item2["type"] == "Switch"):
			t_switch(x)
	else:
		if(item1["type"] == "Single_use"):
			t_single_use(x)
		if(item1["type"] == "Stack"):
			t_stack(x)
		if(item1["type"] == "Unlimited"):
			t_unlimited(x)
		if(item1["type"] == "Switch"):
			t_switch(x)

func process_passive_proc():
	if item1["type"] == "Passive":
		process_passives(item1)
	if item2["type"] == "Passive":
		process_passives(item2)

func process_passives(item):
	if item["effect"] == "Buff":
		var temp_buff = {"name":item["name"], "buffs": item["effect_details"].duplicate()}
		BuffHandler.add_buff(temp_buff)

func play_intro(item_name):
	var sfx_name = item_name + "_intro"
	GameHandler.generate_char_sfx(sfx_name)

func t_single_use(x):
	var temp
	if x:
		temp = item2.duplicate(true)
	else:
		temp = item1.duplicate(true)
	
	activate_item(x)
	
	if x:
		if item2["name"] == temp["name"]:
			item2 = blank
	else:
		if item1["name"] == temp["name"]:
			item1 = blank
	update_items()

func t_stack(x):
	activate_item(x)
	if x:
		play_intro(item2["name"])
		item2["stack_count"] -= 1
		if item2["stack_count"] <= 0:
			item2 = blank
	else:
		play_intro(item1["name"])
		item1["stack_count"] -= 1
		if item1["stack_count"] <= 0:
			item1 = blank
	update_items()

func t_unlimited(x):
	if x:
		if item2["cooldown"] == "room":
			if item_r_cooldown[x] == 1:
				activate_item(x)
				item_r_cooldown[x] = 0
		else:
			if item_cooldowns[x] <= 0:
				activate_item(x)
				item_cooldowns[x] = item2["cooldown_duration"]
	
func t_switch(x):
	var temp = {"name":str(GameHandler.get_active_char()), "type":"Switch"}
	var code
	#do something here
	if x:
		GameHandler.switch_character(int(item2["name"]))
		item2 = temp
	else:
		GameHandler.switch_character(int(item1["name"]))
		item1 = temp
	
	update_items()

func activate_item(x):
	if x:
		if item2["effect"] == "Buff":
			e_buff(x)
		if item2["effect"] == "Recruit":
			e_recruit(x)
		if item2["effect"] == "Skill":
			e_skill(x)
	else:
		if item1["effect"] == "Buff":
			e_buff(x)
		if item1["effect"] == "Recruit":
			e_recruit(x)
		if item1["effect"] == "Skill":
			e_skill(x)

func e_buff(x):
	if x:
		var temp_buff = {item2["name"] : item2["effect_details"].duplicate()}
		BuffHandler.add_buff(temp_buff)
	else:
		var temp_buff = {item1["name"]: item1["effect_details"].duplicate()}
		BuffHandler.add_buff(temp_buff)
	
func e_recruit(x):
	GameHandler.recruit()
	
func e_skill(x):
	pass

func add_item(name):
	var temp = 2
	
	if item1["name"] == "Blank":
		item1 = item_list[name].duplicate(true)
		temp = 0
	elif item2["name"] == "Blank":
		item2 = item_list[name].duplicate(true)
		temp = 1
	update_items()
	
	if !temp:
		if item1["type"] == "Switch":
			use_item(0)
	else:
		if item2["type"] == "Switch":
			use_item(1)

func update_items():
	var labels = ["",""]
	if item1["type"] == "Stack":
		labels[0] = "x"+str(item1["stack_count"])
	if item2["type"] == "Stack":
		labels[1] = "x"+str(item2["stack_count"])
	GameHandler.update_item(item1["name"], item2["name"], labels[0], labels[1])

func remove_item(name):
	if item1.name == name:
		item1 = blank
	elif item2.name == name:
		item2 = blank
	update_items()

#Item idea dump
#	Mic					-	passive, doubles voice related attacks/skills effects and range
#	Rabbits foot		-	passive, improves move speed, increases luck
