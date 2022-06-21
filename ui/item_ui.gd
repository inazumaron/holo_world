extends Node2D

var item1
var item2

func _ready():
	$I1.play("Nakirium")
	$I2.play("Ao chan")

func change(x,y):
	$I1.play(x)
	$I2.play(y)

func changeLabel(x,y):
	$I1Label.set_bbcode(x)
	$I2Label.set_bbcode(y)
