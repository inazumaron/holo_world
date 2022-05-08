extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var data = [{"name": "alpha", "stat": 12}, {"name":"b", "stat":13}]
	save(data)
	var res = loadF()
	print(res[0]["name"])
	pass # Replace with function body.

func save(content):
	var file = File.new()
	file.open("res://save_game.dat", File.WRITE)
	file.store_var(content)
	file.close()

func loadF():
	var file = File.new()
	file.open("res://save_game.dat", File.READ)
	var content = file.get_var()
	file.close()
	return content
