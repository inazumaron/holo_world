extends AnimatedSprite

var skill_origin
var effect_val
var free_after = false

func _on_AnimatedSprite_animation_finished():
	if free_after:
		queue_free()
