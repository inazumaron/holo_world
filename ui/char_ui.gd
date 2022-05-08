extends Node2D

var max_hp = 0
var hp = 0
var h1 = 0
var h2 = 0
var atk = 0
var atk_c = 0
var atk2 = 0
var atk2_c = 0
var atk_stack = 0
var atk2_stack = 0
var h1_visible = false
var h2_visible = false

func _ready():
	$HP_s1.visible = h1_visible
	$HP_s2.visible = h2_visible

func change(data):
	match data["param"]:
		"hp":
			hp = data["val"]
			max_hp = data["val2"]
			$HP_Bar.value = (100*hp/max_hp)
			$HP_label.text = str(hp) + "/" + str(max_hp)
		"h1":
			h1 = data["val"]
			$HP_s1.value = h1*100
		"h2":
			h2 = data["val"]
			$HP_s2.value = h2*100
		"atk":
			atk = data["val"]
			atk_c = data["val2"]
			$atk.value = (100*atk/atk_c)
		"atk2":
			atk2 = data["val"]
			$atk2.value = atk2*100
		"atk_s":
			atk_stack = data["val"]
			$atk_label.text = str(atk_stack)
		"atk2_s":
			atk2_stack = data["val"]
			$atk2_label.text = str(atk2_stack)
