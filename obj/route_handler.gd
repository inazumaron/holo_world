extends Node2D

const MAX_VISIBLE_WIDTH = 5
const MAX_VISIBLE_HEIGHT = 4

var visible_cards = []
var active_cards = []
var all_cards = []

var c01T = preload("res://resc/cards/world_card_field.png")
var c02T = preload("res://resc/cards/world_card_forest.png")
var c03T = preload("res://resc/cards/world_card_graveyard.png")
var c04T = preload("res://resc/cards/world_card_port.png")
var c05T = preload("res://resc/cards/world_card_town.png")

var card = preload("res://obj/card.tscn")

func _ready():
	set_process(false)
	var base = GameHandler.main_char
	var map = GameHandler.generate_worlds(getMainCharMap(base))
	var pos = GameHandler.move()
	for row in range(max(0, pos.y-MAX_VISIBLE_HEIGHT), pos.y+1): #
		var cell_index_start = pos.x-2
		var row_list = []
		var map_row = map[row]
		for cell in range(0, MAX_VISIBLE_WIDTH):
			row_list.append(map_row[int(cell_index_start+cell) % GameHandler.MAX_LEVELS])
		visible_cards.append(row_list)
	display_cards()
	set_process(true)
	
func _process(delta):
	for i in active_cards:
		if i.selected:
			GameHandler.set_next_step(i.next_step)
			for card in all_cards:
				card.queue_free()
			all_cards.clear()
			active_cards.clear()
			GameHandler.set_level_val(i.value)
			GameHandler.change_handler(self, "level")

func switch_texture(n):
	if n == 0:
		return c01T
	if n == 1:
		return c02T
	if n == 2:
		return c03T
	if n == 3:
		return c04T
	if n == 4:
		return c05T
	
func display_cards():
	for i in range(0, len(visible_cards)):
		var temp_row = visible_cards[i]
		for j in range (0, MAX_VISIBLE_WIDTH):
			if i != len(visible_cards)-1 or j == 2:
				var card_inst = card.instance()
				var x = len(visible_cards) - i
				card_inst.position = Vector2(j*(160 - x*16) + 200 + x*32, i*(206 - x*16) + x*16)
				card_inst.scale = Vector2(0.5 - x * 0.05, 0.5 - x * 0.05)
				card_inst.ORIG_SIZE = 0.5 - x * 0.05
				card_inst.value = temp_row[j]
				all_cards.append(card_inst)
				card_inst.card_texture(switch_texture(temp_row[j]))
				if i == len(visible_cards)-2 and (j == 1 or j == 2 or j == 3):
					card_inst.active = true
					active_cards.append(card_inst)
					if j == 1:
						card_inst.next_step = "left"
					if j == 2:
						card_inst.next_step = "up"
					if j == 3:
						card_inst.next_step = "right"
				add_child(card_inst)

func getMainCharMap(x):
	if x == 130: #flare
		return 1
	if x == 131: # marine
		return 3
	if x == 132: # noel
		return 4
	if x == 133: # pekora
		return 0
	if x == 134: #rushia
		return 2
