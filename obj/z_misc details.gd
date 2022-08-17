extends Node
#This script will contain miscellaneous information, or complex computations

#================================================================================
#==========			Read this part before adding new buffs   ====================
#================================================================================

#For buffs that refresh per room, save the 3rd index for 'applied bool'

#buff new structure to accomodate multiple buffs with same effect stacking
#buff = {name: string, buffs: {  buffs place here  }

#Debuff reference
const debuff = { 
	#stun, sleep, freeze, stuck keeps player from switching
	#poison and burn can still apply in background
	#knockback and slow gets passed when switching
	"knockback": ["power","direction", "party", "behaviour"], #power can be interpreted as speed but also decays over time so also counts as duration 
	"poison": ["damage", "duration", "party", "behaviour"],
	"burn": ["damage", "duration", "party", "behaviour"],
	"slow": ["slow", "duration", "party", "behaviour"], #slow value is between  0 - 1, act as multiplier to actual speed
	"stun": ["duration", "party", "behaviour"],
	"sleep": ["duration", "party", "behaviour"],
	"stuck": ["duration", "party", "behaviour"],
	"freeze": ["damage", "duration", "party", "behaviour"],
}

const buff = { 
	# party means buff applies to whole party  (0 - not apply, 1 - applies to all)
	#behaviour is string, applies for those with duration: 
	#	'pause' - duration pauses when inactive, 
	#	'temp' - buff disappears when inactive, 
	#	'bg' - buff duration continues in bg
	#	'perm' - permanent
	
	"fast": ["speed", "duration", "party", "behaviour"],		#multiplier
	"tough": ["def", "duration", "party", "behaviour"],			#direct add to def
	"fly": ["duration", "party", "behaviour"],
	"strong": ["damage", "duration", "party", "behaviour"],		#multiplier
	"quick": ["aspd", "duration", "party", "behaviour"],		#aspd = cooldown multiplier
	"regen": ["amount", "duration", "party", "behaviour"],
	"heal": ["amount", "party"],
	"heal_pr":["amount", "party", "activated"],
	"shield": ["stack", "duration", "party", "behaviour"],
	"critRate": ["value", "duration", "party", "behaviour"],
	"critDmg": ["value", "duration", "party", "behaviour"],
	"revive": ["hp %", "stack", "party"],
}

#naming conventions for character codes:
#Codes are 3 digits ex noel = 132
#1st digit is branch 1-JP, 2-ID, 3-EN
#2nd digit is gen	 gen9 - 0 ... gamers - 9, irys - 0
#3rd digit is position alphabetically starting with 0
# ex Flare - 130, Marine - 131, Noel - 132, Pekora - 133, Rushia - 134

const boss_level = {
	#1		-	Basic, has ~3 skills to use
	#2		-	1 + 0.25 enemy budget for mobs
	#3		-	2 + improved/buffed skills
	#4		-	Basic, has 5 buffed skills to use
	#5		-	4 + 0.25 enemy budget
	#6		-	4 + 0.5 enemy budget
	#7		-	New form, 6 buffed skills, can use 2 at a time
	#8		-	7 + 0.25 enemy budget
	#9		-	7 + 0.5 enemy budget
	#10		-	same as main character, 7 + 2 enemy budget 
	"end":0
}

const BODY_TYPE = [ #for kinematic bodies, to help identify
	"player_character",
	"projectile",
	"enemy_boss",
	"enemy_mob"
]

#to do
#randomize obstacles

#Current bugs
#	Level up buffs will be given to ACTIVE character. So for future implementation for shared xp, deal with this one first
#		Affected scripts are: Game handler and level handler
#	Level up textures will need to preload, as of writing, godot.org is down so leaving this later
#		Goal, recursively preload skill folder for ease in adding files in the future
