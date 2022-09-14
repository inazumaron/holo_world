extends RayCast2D

const WARNING_DURATION := 1.0
var warning_timer := 0.0

var is_casting := false setget set_is_casting
var laser_duration := 1.5
var timer := 1.5	#for handling laser duration
var cooldown_duration := 1.0
var cooldown := 1.0	#for cooldown in attacks
var damage_cooldown := 0.5
var damage_timer := 0.1 #damage cooldown for dps
var group := "enemy"
var dps := true		#true - deals constant damage, false - deals damage once

var buffs = {}
var multipliers
var offsets
var damage := 1
var dir

signal laser_damage(damage, effect)

func _ready() -> void:
	set_physics_process(false)
	$Line2D.points[1] = Vector2.ZERO
	$WarningLine.points[1] = Vector2.ZERO

func target_lock(pos) -> void: 
	#Look at target position
	look_at(pos)
	warning_timer = WARNING_DURATION
	warning_appear()

func cancel_laser() -> void:
	set_is_casting(false)

func attack() -> void:
	self.is_casting = true
	timer = laser_duration
	cooldown = cooldown_duration

func target_hit(delta):
	#Apply damage to body hit
	var target_body = get_collider()
	
	if target_body.has_method("take_damage") and target_body.is_in_group("player"):
		if dps:
			if damage_timer <= 0:
				damage_timer = damage_cooldown
				self.connect("laser_damage",target_body, "take_damage")
				emit_signal("laser_damage",damage,buffs)
				self.disconnect("laser_damage",target_body,"take_damage")
			else:
				damage_timer -= delta

func _process(delta):
	if cooldown > 0:
		cooldown -= delta
	
	if warning_timer > 0:
		warning_timer -= delta
		var cast_point := cast_to
		force_raycast_update()
		
		if is_colliding():
			cast_point = to_local(get_collision_point())
			$WarningParticle.position = cast_point
		
		$WarningLine.points[1] = cast_point

func _physics_process(delta):
	var cast_point := cast_to
	force_raycast_update()
	
	if is_casting and timer > 0:
		timer -= delta
		if timer <= 0 and is_casting:
			set_is_casting(false)
	
	if is_colliding():
		cast_point = to_local(get_collision_point())
		target_hit(delta)
		$TargetParticle.position = cast_point
		
	$Line2D.points[1] = cast_point
	$BeamParticle.position = cast_point * 0.5
	$BeamParticle.process_material.emission_box_extents.x = cast_point.length() * 0.5
	
func set_is_casting(cast: bool) -> void:
	is_casting = cast
	
	if is_casting:
		appear()
	else:
		disappear()
	
	set_physics_process(is_casting)

func warning_appear() -> void:
	$Tween.stop_all()
	$Tween.interpolate_property($WarningLine, "width", 0, 5.0, 0.2)
	$Tween.start()
	$WarningParticle.emitting = true

func appear() -> void:
	$Tween.stop_all()
	$Tween.interpolate_property($Line2D, "width",0, 5.0, 0.2)
	$Tween.interpolate_property($WarningLine, "width", 5.0, 0, 0.2)
	$Tween.start()
	$TargetParticle.emitting = true
	$BeamParticle.emitting = true
	$WarningParticle.emitting = false

func disappear() -> void:
	$Tween.stop_all()
	$Tween.interpolate_property($Line2D, "width", 5.0, 0, 0.2)
	$Tween.start()
	$TargetParticle.emitting = false
	$BeamParticle.emitting = false
