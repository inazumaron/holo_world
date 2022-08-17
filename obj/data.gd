extends Node

#Main purpose is to simply house variables for easy access

#Character upgrades/ Skill Tree
#Format: { name: string, level: int, req: [string], alt: [string], desc: string, effects: [buffs] }
#req are prerequisites to access this certain skill
#character will have a skill list, which this will need to access
	#In case of skill upgrades, character skill is automatically added as a skill
#alt are for alternative skills, when an alt is already acquired, this skill wont be available

const c_130_ST = [
	{"name": "Burning passion", "desc":"attacks has chance to burn enemy", "level":1, "req":[], "alt":[], "effects":[]},
	{"name": "Pinpoint accuracy", "desc":"increse crit chance", "level":1, "req":[], "alt":[], "effects":[]},
	{"name": "Arsonist", "desc":"skill now runs on duration", "level":1, "req":["c130_flameArrow"], "alt":[], "effects":[]},
	{"name": "Explosion", "desc":"burn effect now has chance to explode", "level":1, "req":["Burning passion"], "alt":[], "effects":[]},
	{"name": "Quick burn", "desc":"increased damage and burn at start of room", "level":1, "req":[], "alt":["Slow burn"], "effects":[]},
	{"name": "Explosive arrow", "desc":"skill now runs on duration", "level":1, "req":["c130_flameArrow"], "alt":[], "effects":[]},
	{"name": "Multi shot", "desc":"2nd tier now does mult shot", "level":1, "req":[], "alt":[], "effects":[]},
	{"name": "Homing shot", "desc":"skill is now homing", "level":1, "req":["c130_piercingShot"], "alt":[], "effects":[]},
	{"name": "Chain reaction", "desc":"killing enemies cause a burst of arrows", "level":1, "req":[], "alt":[], "effects":[]},
	{"name": "Slow burn", "desc":"incresed damage and burn over time", "level":1, "req":[], "alt":["Quick burn"], "effects":[]},
]

const c_131_ST = [
]

const c_132_ST = [
	{"name": "Knights armor", "desc":"passive Def up", "level":1, "req":[], "alt":[], "effects":[]},
	{"name": "Enhanced shield", "desc":"Skill also grants defense", "level":1, "req":["c132_shield"], "alt":[], "effects":[]},
	{"name": "Mace slam", "desc":"3rd tier attack deals AoE and scales with def", "level":1, "req":[], "alt":[], "effects":[]},
	{"name": "Guardian knight", "desc":"passive Def to party, scales with own def", "level":1, "req":[], "alt":[], "effects":[]},
	{"name": "Knights milk", "desc":"heal at start of room", "level":1, "req":[], "alt":[], "effects":[]},
	{"name": "Bottomless", "desc":"Increase max HP per level", "level":1, "req":[], "alt":[], "effects":[]},
	{"name": "Gyuudon bowl", "desc":"heal party at start of room", "level":1, "req":[], "alt":[], "effects":[]},
	{"name": "Itadakimasu!", "desc":"Chance to heal upon defeating enemy", "level":1, "req":[], "alt":[], "effects":[]},
	{"name": "Hunger strike", "desc":"Increased damage based on missing hp", "level":1, "req":[], "alt":[], "effects":[]},
	{"name": "Healing shield", "desc":"breaking shield has chance to heal", "level":1, "req":["c132_shield"], "alt":[], "effects":[]},
	{"name": "Stronger", "desc":"Increase skill range and damage", "level":1, "req":["c132_groundSlam"], "alt":[], "effects":[]},
	{"name": "Shockwave", "desc":"Skill stuns enemy and lowers defense. Increases cooldown", "level":1, "req":["c132_groundSlam"], "alt":[], "effects":[]},
]

const c_133_ST = [
	{"name": "Bigger bombs", "desc":"bigger AoE and damage", "level":1, "req":[], "alt":[], "effects":[]},
	{"name": "Tactical bombs", "desc":"TNT explosion reduces enemy defenses", "level":1, "req":["c133_tntBarrel"], "alt":[], "effects":[]},
	{"name": "Remote bombs", "desc":"TNT only explode on attack", "level":1, "req":["c133_tntBarrel"], "alt":[], "effects":[]},
	{"name": "RPG", "desc":"replaces 3rd tier attack, explosive projectile that travels in a line", "level":1, "req":[], "alt":["Bombard"], "effects":[]},
	{"name": "Bombs in bombs", "desc":"explosives has chance to drop another bomb", "level":1, "req":[], "alt":[], "effects":[]},
	{"name": "Shared luck", "desc":"skill applies to rest of party", "level":1, "req":["c133_lucky"], "alt":[], "effects":[]},
	{"name": "Bombard", "desc":"replaces 3rd tier attack to bombard an area", "level":1, "req":[], "alt":["RPG"], "effects":[]},
	{"name": "Smug rabbit", "desc":"increased damage till damaged", "level":1, "req":[], "alt":[], "effects":[]},
	{"name": "Orrra", "desc":"skill also increases damage and range", "level":1, "req":["c133_lucky"], "alt":[], "effects":[]},
	{"name": "Uncatchable", "desc":"Drops mines that damage and slow enemies", "level":1, "req":[], "alt":[], "effects":[]},
]

const c_134_ST = [
]

func get_data(code):
	if code == 130:
		return c_130_ST
	if code == 131:
		return c_131_ST
	if code == 132:
		return c_132_ST
	if code == 133:
		return c_133_ST
	if code == 134:
		return c_134_ST

func get_skill(s_name, code):
	var res = get_data(code)
	var data
	for skill in res:
		if skill["name"] == s_name:
			data = skill.duplicate()
			break
	return data

func get_random_skills(count, code, curr_skills, level):
	var skill_list = []
	var data = [] + get_data(code)
	var req_list = []
	var alt_list = []
	var possible_skills = []
	for skill in curr_skills:
		req_list.append(skill["req"])
		alt_list.append(skill["alt"])
	for skill in data:
		var reqs_have = true
		var alt_have = false
		var level_correct = true
		if skill["level"] > level:
			level_correct = false
			break
		if skill["req"].size() > 0:
			for req in skill["req"]:
				if !(req in req_list):
					reqs_have = false
					break
		if skill["alt"].size() > 0:
			for alt in skill["alt"]:
				if alt in alt_list:
					alt_have = true
					break
		if level_correct and reqs_have and !alt_have:
			possible_skills.append(skill)
	if possible_skills.size() <= count:
		return possible_skills
	var temp_skill_list = {}
	while(temp_skill_list.size() < count):
		var i = randi()%possible_skills.size()
		if !(possible_skills[i]["name"] in skill_list):
			temp_skill_list[possible_skills[i]["name"]] = possible_skills[i]
	for skill in temp_skill_list:
		skill_list.append(temp_skill_list[skill].duplicate())
	return skill_list
