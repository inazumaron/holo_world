extends Node2D

const card_size = Vector2(150,100)
const start_pos = Vector2(100,120)		#offset to vector 0 which will be used in code
const max_r_width = 10				#max number of cards in a row

const c_130 = preload("res://resc/cards/char_card_flare.png")
const c_131 = preload("res://resc/cards/char_card_marine.png")
const c_132 = preload("res://resc/cards/char_card_noel.png")
const c_133 = preload("res://resc/cards/char_card_pekora.png")
const c_134 = preload("res://resc/cards/char_card_rushia.png")

const card = preload("res://obj/card.tscn")
const portrait_base = preload("res://obj/charSel_portrait.tscn")

var card_path = [c_130, c_131, c_132, c_133, c_134]
var card_list = []
var portrait
var selected = null
var prev_selected = null

func _ready():
	generate_cards()
	generate_portrait()

func _process(delta):
	for x in card_list:
		if x.selected:
			char_portrait(x.value)
			if prev_selected != x:
				selected = x
	if selected != prev_selected:
		if prev_selected != null:
			prev_selected.selected = false
		prev_selected = selected
		
	if Input.is_action_just_pressed("ui_accept"):
		if selected != null:
			GameHandler.set_main_char(selected.value)
			GameHandler.change_handler(self,"route")

func generate_cards():
	for i in range(0, card_path.size()):
		var card_inst = card.instance()
		card_inst.position = Vector2((i%max_r_width) * card_size.x, floor(i/max_r_width) * card_size.y) + start_pos
		card_inst.ORIG_SIZE = 0.4
		card_inst.active = true
		card_inst.value = get_char_code(i);
		card_inst.card_texture(card_path[i])
		card_list.append(card_inst)
		add_child(card_inst)

func get_char_code(i):
	if i == 0:
		return 130
	if i == 1:
		return 131
	if i == 2:
		return 132
	if i == 3:
		return 133
	if i == 4:
		return 134

func generate_portrait():
	portrait = portrait_base.instance()
	portrait.position = Vector2(900,400)
	add_child(portrait)

func char_portrait(i):
	portrait.play(i)
