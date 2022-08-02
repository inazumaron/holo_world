extends Node2D

var text = ""
var properties = {
	"bold":false,
	"italic":false,
	"underline":false,
	"align":"center",
	"color":"black"
}
const color = {
	"red": Color(255,0,0,1),
	"blue": Color(0,0,255,1),
	"green": Color(0,255,0,1),
	"violet": Color(255,0,255,1),
	"yellow": Color(255,255,0,1),
	"orange": Color(255,170,0,1),
	"black": Color(0,0,0,1),
	"white": Color(255,255,255,1),
}
var timer = -1

onready var text_obj = $RichTextLabel

func _ready():
	text_obj.bbcode_enabled = true

func _process(delta):
	if timer != -1 and timer > 0:
		timer -= delta
		if timer <= 0:
			queue_free()

func set_text(x):
	text = x

func set_properties(data):
	for i in properties:
		if i in data:
			properties[i] = data[i]

func display():
	var tag_stack = ""
	if properties["align"] != "left":
		tag_stack += "["+properties["align"]+"]"
	if properties["bold"]:
		tag_stack += "[b]"
	if properties["italic"]:
		tag_stack += "[i]"
	if properties["underline"]:
		tag_stack += "[u]"
	tag_stack += "[color="+properties["color"]+"]"
	tag_stack += text
	tag_stack += "[/color]"
	if properties["underline"]:
		tag_stack += "[/u]"
	if properties["italic"]:
		tag_stack += "[/i]"
	if properties["bold"]:
		tag_stack += "[/b]"
	if properties["align"] != "left":
		tag_stack += "[/"+properties["align"]+"]"
	text_obj.set_bbcode(tag_stack)
