extends KinematicBody2D

const var_list = {	#number of variations per map
	"graveyard" : 5
}
# Called when the node enters the scene tree for the first time.
func play(x):
	$AnimatedSprite.play(x)
	$AnimatedSprite.frame = randi()%var_list[x]
