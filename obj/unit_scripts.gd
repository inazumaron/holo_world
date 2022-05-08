extends Node
#This script will contain miscellaneous information, or complex computations

#Debuff reference
const debuff = { 
	#stun, sleep, freeze, stuck keeps player from switching
	#poison and burn can still apply in background
	#knockback and slow gets passed when switching
	"knockback": ["power","direction"], #power can be interpreted as speed but also decays over time so also counts as duration 
	"poison": ["damage", "duration"],
	"burn": ["damage", "duration"],
	"slow": ["slow", "duration"], #slow value is between  0 - 1, act as multiplier to actual speed
	"stun": ["duration"],
	"sleep": ["duration"],
	"stuck": ["duration"],
	"freeze": ["damage", "duration"],
}

const buff = { 
	# party means buff applies to whole party
	#behaviour is string: 
	#'pause' - duration pauses when inactive, 'temp' - buff disappears when inactive, 'bg' - buff duration continues in bg
	"fast": ["speed", "duration", "party", "behaviour"],	#multiplier
	"tough": ["def", "duration", "party", "behaviour"],	#direct add to def
	"fly": ["duration", "party", "behaviour"],
	"strong": ["damage", "duration", "party", "behaviour"],	#direct val
	"quick": ["aspd", "duration", "party", "behaviour"],		#aspd = cooldown multiplier
	"regen": ["amount", "duration", "party", "behaviour"],
	"heal": ["amount", "party", "behaviour"],
	"shield": ["stack", "duration", "party", "behaviour"],
	"critRate": ["value", "duration", "party", "behaviour"],
	"critDmg": ["value", "duration", "party", "behaviour"],
}
