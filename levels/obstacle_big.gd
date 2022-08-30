extends KinematicBody2D

const var_list = {
	"graveyard" : 3
}

func _ready():
	z_index = 3

func play(x):
	$spr_bot.play(x)
	$spr_mid.play(x)
	$spr_top.play(x)
	var temp = randi()%var_list[x]
	$spr_bot.frame = temp
	$spr_mid.frame = temp
	$spr_top.frame = temp
