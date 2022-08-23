extends Node2D

func set_val(val):
	$Node2D/TextureProgress.value = val
	if val == 0:
		queue_free()
