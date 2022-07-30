extends Node2D

const cardX = 350
const cardY = 100
const card_base = preload("res://obj/card.tscn")
const card_pos = [Vector2(-cardX, cardY), Vector2(0, cardY), Vector2(cardX, cardY)]
var card_paths = []
var card_vals = []
var deck = []

func _ready():
	generate_cards()

func generate_cards():
	for i in range(0, card_paths.size()):
		var card = card_base.instance()
		card.position = card_pos[i]
		card.value = card_vals[i]
		card.active = true
		card.card_texture(card_paths[i])
		deck.append(card)
		add_child(card)

func _process(delta):
	for card in deck:
		if card.selected:
			GameHandler.recruit_char(card.value)
			clear()

func clear():
	for card in deck:
		card.queue_free()
	queue_free()
	pass
