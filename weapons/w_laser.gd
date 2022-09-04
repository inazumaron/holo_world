extends RayCast2D

#For usage, tweak unhandled input for when to use laser
#Target can be acquired thru get_collider() function

var is_casting := false setget set_is_casting
var laser_duration := 0.5
var timer := 0.5	#for handling laser duration
var cooldown_duration := 1
var cooldown := 1	#for cooldown in attacks

var buffs
var multipliers
var offsets
var damage := 1
var dir

func _ready() -> void:
	set_physics_process(false)
	$Line2D.points[1] = Vector2.ZERO

func attack(target = null) -> void:
	if cooldown <= 0:
		self.is_casting = true
		timer = laser_duration
		cooldown = cooldown_duration
		if target == null:
			self.look_at(get_global_mouse_position())
		else:
			self.look_at(target)

func _process(delta):
	if cooldown > 0:
		cooldown -= delta

func _physics_process(delta):
	var cast_point := cast_to
	force_raycast_update()
	
	if is_casting and timer > 0:
		timer -= delta
		if timer <= 0:
			set_is_casting(false)
	
	if is_colliding():
		cast_point = to_local(get_collision_point())
		
	$Line2D.points[1] = cast_point
	
func set_is_casting(cast: bool) -> void:
	is_casting = cast
	
	if is_casting:
		appear()
	else:
		disappear()
	
	set_physics_process(is_casting)
	
func appear() -> void:
	$Tween.stop_all()
	$Tween.interpolate_property($Line2D, "width",0, 10.0, 0.2)
	$Tween.start()

func disappear() -> void:
	$Tween.stop_all()
	$Tween.interpolate_property($Line2D, "width", 10.0, 0, 0.2)
	$Tween.start()
