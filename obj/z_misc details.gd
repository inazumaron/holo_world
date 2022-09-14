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

const buffList = { 
	#main reference for buff format
	
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
	
	#some more obscure buffs
	"burnChance": ["buffDuration", "burnDamage", "burnDuration", "burnChance", "party", "behaviour"]
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
#	hazards placement to avoid obstacles
#	object z indexes may be checked
#	code more of flares skill tree

#Current bugs
#	FDC state not setting to dead when killed or gets overwritten when killed midlaser
#	Level up buffs will be given to ACTIVE character. So for future implementation for shared xp, deal with this one first
#		Affected scripts are: Game handler and level handler

#Done today


#	randomize obstacles
#	minimap offset added to fit in screen
#	obstacles not appearing except big
#	added big and medium obstacle
#	rename gd files (which is expected to be duplicated) to be based on their folder placement (besides player folder)
#	hazard positions and type not consistent based on room seed
#	Enemy tracking does not shift to active characters
#	Rng now inherited from game handler
