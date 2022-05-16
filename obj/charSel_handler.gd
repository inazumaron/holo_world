extends Node2D

const card_size = Vector2(40,100)
const start_pos = Vector2(0,0)		#offset to vector 0 which will be used in code
const max_r_width = 10				#max number of cards in a row

const c_130 = preload("res://resc/cards/char_card_flare.png")
const c_131 = preload("res://resc/cards/char_card_marine.png")
const c_132 = preload("res://resc/cards/char_card_noel.png")
const c_133 = preload("res://resc/cards/char_card_pekora.png")
const c_134 = preload("res://resc/cards/char_card_rushia.png")

var card_list = [c_130, c_131, c_132, c_133, c_134]

func _ready():
	pass # Replace with function body.

func display_cards():
	pass
