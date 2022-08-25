extends Node2D

const screen = Vector2(400,-260)
var map = []
var loc = 0
var room_list = []

var room = preload("res://ui/minimap_room.tscn")
# Called when the node enters the scene tree for the first time.
func generate_minimap():
	#compute offset for minimap placement
	var max_x = -1
	var offset = Vector2(0,0)
	for i in map:
		if i["coord"].x > max_x:
			max_x = i["coord"].x
	offset.x = 32 * (max_x - 2)
	for i in map:
		var room_inst = room.instance()
		room_inst.position = (i["coord"] * 32) + screen - offset
		if i["cleared"]:
			room_inst.active(false)
		else:
			room_inst.fog()
		add_child(room_inst)
		room_list.append(room_inst)
	room_list[loc].active(true)

func clear():
	for i in room_list:
		i.queue_free()
