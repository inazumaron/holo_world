extends Node2D

var options = []
var code
var curr_skills
var level
var title = ""
var desc = ""
const bbHead = "<center><b>"
const bbfoot = "</b></center>"
var selected = 0		#-1 - none selected, 0 - 1, 1 - 2, 3 - 3 selected

const sprite_locs = [	#Format is start vector, end vector x 3
	Vector2(-271,-140), Vector2(-145,-10),
	Vector2(-64, -140), Vector2(63, -10),
	Vector2(137, -140), Vector2(265, -10)]

func _ready():
	options = Database.get_random_skills(3,code, curr_skills, level)

func _process(delta):
	var posCheck = is_hovering()
	if posCheck != -1 and posCheck != null:
		title = options[posCheck]["name"]
		desc = options[posCheck]["desc"]
		set_text()

func set_text():
	$"Title Text".set_bbcode(bbHead + title + bbfoot)
	$"Desc Text".set_bbcode(bbHead + desc + bbfoot)

func is_hovering():
	var mouse = get_global_mouse_position()
	if mouse.y < -140 or mouse.y > -10:
		return -1
	for i in range(0, 3):
		if mouse.x > sprite_locs[i*2].x and mouse.x < sprite_locs[(i*2)+1].x:
			return i

func set_data(data):
	options = data
	$S1.texture = "res://resc/skills" + options[0]["name"] + ".png"
	$S2.texture = "res://resc/skills" + options[1]["name"] + ".png"
	$S3.texture = "res://resc/skills" + options[2]["name"] + ".png"

func setCamera(x):
	$Camera2D.current = x
