extends Node2D

const SCALE_OFFSET = 1.2
var ORIG_SIZE = 1

var value = ""
var next_step = ""		#when used as world card
var active = false
var selected = false

func _ready():
	set_process(false)

func _process(delta):
	if Input.is_action_pressed("mouse_click"):
		selected = true

func _on_Area2D_mouse_entered():
	if active:
		self.scale = Vector2(ORIG_SIZE * SCALE_OFFSET, ORIG_SIZE * SCALE_OFFSET)
		set_process(true)

func _on_Area2D_mouse_exited():
	if active:
		self.scale = Vector2(ORIG_SIZE, ORIG_SIZE)
		set_process(false)

func card_texture(path):
	$Sprite.set_texture(path)
