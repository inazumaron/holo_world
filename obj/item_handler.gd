extends Node

const blank = {"name":"Blank","type":"none"}
var item1 = {"name":"Nakirium", "type":"Stack", "effect":"Buff", "stack_count":3, "effect_details":{"heal": [5, 0]}}
var item2 = {"name":"Blank", "type":"none", "effect":"none"}

var item_r_cooldown = [1,1]	#for room type cooldowns, turns to 1 on next not cleared room, 0 when used
var item_cooldowns = [0,0]	#for cooldowns not room type, process will handle this part

var can_use = true		#item cooldown
var cooldown = 0

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
		"effect_details":{"quick": [.6, 20, 0, "temp"], "fast": [1.5, 20, 0, "temp"]}},
	"Asacoco":
		{"name":"Asacoco", "type":"Stack", "effect":"Buff", "stack_count":3, 
		"effect_details":{"strong": [2, 15, 0, "bg"],"tough": [1, 15, 0, "bg"]}},
	"Bloop":
		{"name":"Bloop", "type":"Passive", "effect":"Passive", "effect_details":""},
	"Kiara's feather":
		{"name":"Kiara's feather", "type":"Passive", "effect":"Buff", 
		"effect_details":{"revive": [1, 1, 1]}},
	"Ame's Watch":
		{"name":"Ame's Watch", "type":"Unlimited", "effect":"Skill", "cooldown":"room", "skill_name":""},
	"Ao chan":
		{"name":"Ao chan", "type":"Unlimited", "effect":"Skill", "cooldown":"room", "skill_name":""},
#-------------------------------------Character portraits portion
	"130":
		{"name":"130", "type":"switch"},
	"131":
		{"name":"131", "type":"switch"},
	"132":
		{"name":"132", "type":"switch"},
	"133":
		{"name":"133", "type":"switch"},
	"134":
		{"name":"134", "type":"switch"},
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

func t_single_use(x):
	activate_item(x)
	if x:
		item2 = null
	else:
		item1 = null
	
func t_stack(x):
	activate_item(x)
	if x:
		item2["stack_count"] -= 1
		if item2["stack_count"] <= 0:
			item2 = blank
	else:
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
	var temp = {"name":str(GameHandler.get_active_char()), "type":"switch"}
	#do something here
	if x:
		item2 = temp
	else:
		item1 = temp

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
		var temp_buff = {"name": item2["name"], "buffs": item2["effect_details"]}
		BuffHandler.add_buff(temp_buff)
	else:
		var temp_buff = {"name": item1["name"], "buffs": item1["effect_details"]}
		BuffHandler.add_buff(temp_buff)
	
func e_recruit(x):
	pass
	
func e_skill(x):
	pass

func update_items():
	var labels = ["",""]
	if item1["type"] == "Stack":
		labels[0] = "x"+str(item1["stack_count"])
	if item2["type"] == "Stack":
		labels[1] = "x"+str(item2["stack_count"])
	GameHandler.update_item(item1["name"], item2["name"], labels[0], labels[1])

#Item idea dump
#	Mic					-	passive, doubles voice related attacks/skills effects and range
#	Rabbits foot		-	passive, improves move speed, increases luck
