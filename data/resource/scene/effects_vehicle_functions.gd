## Vehicle effects of the current Vehicle in the scene
class_name VehicleEffects
extends Resource

@export_group("Friction")
@export var _friction := true
@export var friction_emit_power: Curve
@export var speed_friction := [70, 666]
@export_group("Slip")
@export var _slip := true
@export var slip_emit_power: Curve
@export var speed_slip := [0, 666]
@export var range_slip := 2
@export_group("Grind")
@export var _grind := true
@export var grind_emit_power: Curve
@export var speed_grind := [0, 666]
@export var range_grind := 10
@export_group("Dust")
@export var _dust := true
@export var dust_color_power: Curve
@export var speed_dust := [90, 666]

## Particle emitting function based on speed traits
func speed(speed_kph:float, effectScene:GPUParticles2D, speed_min:int, final_amount_ratio:int):	
	if speed_kph > speed_min:
		effectScene.amount_ratio = final_amount_ratio
	else:
		if final_amount_ratio == 1:
			effectScene.amount_ratio = 0
		else:
			effectScene.amount_ratio = 1

## Particle emitting function based on friction traits
func friction(speed_kph:float, frictionScenes:Array[GPUParticles2D], wheel_magnitude:float, slip_ratio:float):
	if _friction:
		if int(wheel_magnitude) == 0: wheel_magnitude = 1
		if (speed_friction[0] < speed_kph and speed_kph < speed_friction[1]):
			for scene in frictionScenes:
				scene.process_material.direction.x = -wheel_magnitude
				scene.amount_ratio = friction_emit_power.sample(abs(slip_ratio))
				scene.emitting = true
		else:
			for scene in frictionScenes:
				scene.amount_ratio = 0
	else:
		for scene in frictionScenes:
				scene.emitting = false

## Particle emitting function based on slip traits
func slip(speed_kph:float, speed_mps:float, slipScenes:Array[GPUParticles2D], wheel_magnitude:float, slip_ratio:float):
	if _slip:
		#if int(wheel_magnitude) == 0: wheel_magnitude = 1
		if (speed_slip[0] < speed_kph and speed_kph < speed_slip[1]) and (speed_mps > range_slip or speed_kph > range_slip):
			for scene in slipScenes:
				scene.process_material.direction.x = int(-wheel_magnitude)
				scene.amount_ratio = slip_emit_power.sample(abs(slip_ratio))
				scene.emitting = true
		else:
			for scene in slipScenes:
				scene.amount_ratio = 0
	else:
		for scene in slipScenes:
				scene.emitting = false

## Particle emitting function based on grind traits
func grind(speed_kph:float, speed_mps:float, grindScenes:Array[GPUParticles2D], wheel_magnitude:float, slip_ratio:float):
	if _grind:
		if int(wheel_magnitude) == 0: wheel_magnitude = 1
		if (speed_grind[0] < speed_kph and speed_kph < speed_grind[1]) and (speed_mps > range_grind or speed_kph > range_grind):
			#grind_emit_power.set_point_offset(0, clampf(lerpf(0.04, 0.0, speed_kph / 20.0), 0.0, 0.04))
			for scene in grindScenes:
				scene.process_material.direction.x = int(-wheel_magnitude)
				scene.amount_ratio = grind_emit_power.sample(abs(slip_ratio))
				scene.emitting = true
		else:
			for scene in grindScenes:
				scene.amount_ratio = 0
	else:
		for scene in grindScenes:
				scene.emitting = false

## Particle emitting function based on dust traits
func dust(speed_kph:float, chassisScenes:Array[GPUParticles2D]):
	if _dust:
		dust_color_power.set_point_offset(0, speed_dust[0])
		dust_color_power.set_point_offset(1, speed_dust[1])
		if speed_dust[0] < speed_kph and speed_kph < speed_dust[1]:
			for scene in chassisScenes:
				scene.amount_ratio = 1
				scene.modulate = Color(255, 255, 255, dust_color_power.sample(speed_kph))
				scene.emitting = true
		else:
			for scene in chassisScenes:
				scene.amount_ratio = 0
	else:
		for scene in chassisScenes:
				scene.amount_ratio = 0
				#scene.modulate = Color(255, 255, 255, 0)
				scene.emitting = false

## Changes Wheel sprite based on the angular velocity of the Wheel
func process_texture(sprite:Sprite2D, angular_speed:float, threshold:float, visual_tire_radius:float) -> void:	
	if abs(angular_speed) > threshold:
		sprite.texture.region.position.x = visual_tire_radius * 2
	else:
		sprite.texture.region.position.x = 0
