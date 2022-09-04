#This will serve as a basic template for weapon functions format

#Variables
var buffs
var multipliers
var offsets
var damage := 1
var dir #for when its an enemy weapon, else direction will be based on mouse location

#Functions
func attack() -> void:
	#To be called when character attempts to attack
	#may not attack if cooldown still not done
	pass

func play(x) -> void:
	#Optional for weapons with animations
	pass
