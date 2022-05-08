extends AnimatedSprite

# Called when the node enters the scene tree for the first time.
func _ready():
	self.modulate.a = 0.5

func fog():
	self.play("fog")
	
func active(x):
	if x:
		self.play("active")
	else:
		self.play("cleared")
