extends Node2D

var options = []
var code
var curr_skills
var level
var title = ""
var desc = ""
const bbHead = ""
const bbfoot = ""
var preloaded_textures
var selected = 0		#-1 - none selected, 0 - 1, 1 - 2, 3 - 3 selected
var skill_selected = false
var selected_data

const sprite_locs = [	#Format is start vector, end vector x 3
	Vector2(-271,-140), Vector2(-145,-10),
	Vector2(-64, -140), Vector2(63, -10),
	Vector2(137, -140), Vector2(265, -10)]

func _ready():
	z_index = 2
	options = Database.get_random_skills(3,code, curr_skills, level)
	set_data()		#- currently need to first preload textures, check bugs

func _process(delta):
	var posCheck = is_hovering()
	if posCheck != -1 and posCheck != null:
		title = options[posCheck]["name"]
		desc = options[posCheck]["desc"]
		set_text()
	
	if Input.is_action_pressed("mouse_click"):
		if posCheck == 0:
			selected = 0
			selected_data = options[0]
			skill_selected = true
		if posCheck == 1:
			selected = 1
			selected_data = options[1]
			skill_selected = true
		if posCheck == 2:
			selected = 2
			selected_data = options[2]
			skill_selected = true

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

func set_data():
	$S1.texture = GameHandler.get_skill_icon(options[0]["name"])
	$S2.texture = GameHandler.get_skill_icon(options[1]["name"])
	$S3.texture = GameHandler.get_skill_icon(options[2]["name"])

func setCamera(x):
	$Camera2D.current = x
