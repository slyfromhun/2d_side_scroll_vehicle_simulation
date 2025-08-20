class_name VehicleEffects
extends Resource

@export_group("Friction")
@export var _friction := true
@export var friction_emit_power: Curve
@export var speed_friction := [0, 666]
@export_group("Slip")
@export var _slip := true
@export var slip_emit_power: Curve
@export var speed_slip := [0, 666]
@export_group("Grind")
@export var _grind := true
@export var grind_emit_power: Curve
@export var speed_grind := [0, 666]
@export_group("Dust")
@export var _dust := true
@export var dust_color_power: Curve
@export var speed_dust := [0, 666]

func friction(speed_kph: float, frictionScenes: Array[GPUParticles2D], wheel_magnitude: float, slip_ratio: float):
	if _friction:
		if int(wheel_magnitude) == 0: wheel_magnitude = 1
		if speed_friction[0] < speed_kph and speed_kph < speed_friction[1]:
			for scene in frictionScenes:
				scene.process_material.direction.x = -wheel_magnitude
				scene.amount_ratio = friction_emit_power.sample(slip_ratio)
		else:
			for scene in frictionScenes:
				scene.amount_ratio = 0
	else:
		for scene in frictionScenes:
				scene.amount_ratio = 0

func slip(speed_kph: float, slipScenes: Array[GPUParticles2D], wheel_magnitude: float, slip_ratio: float):
	if _slip:
		if int(wheel_magnitude) == 0: wheel_magnitude = 1
		if (speed_slip[0] < speed_kph and speed_kph < speed_slip[1]):
			for scene in slipScenes:
				scene.process_material.direction.x = -wheel_magnitude
				scene.amount_ratio = slip_emit_power.sample(slip_ratio)
		else:
			for scene in slipScenes:
				scene.amount_ratio = 0
	else:
		for scene in slipScenes:
				scene.amount_ratio = 0

func grind(speed_kph: float, grindScenes: Array[GPUParticles2D], wheel_magnitude: float, slip_ratio: float):
	if _grind:
		if int(wheel_magnitude) == 0: wheel_magnitude = 1
		if speed_grind[0] < speed_kph and speed_kph < speed_grind[1]:
			grind_emit_power.set_point_offset(0, clampf(lerpf(0.04, 0.0, speed_kph / 20.0), 0.0, 0.04))
			for scene in grindScenes:
				scene.process_material.direction.x = -wheel_magnitude
				scene.amount_ratio = grind_emit_power.sample(slip_ratio)
		else:
			for scene in grindScenes:
				scene.amount_ratio = 0
	else:
		for scene in grindScenes:
				scene.amount_ratio = 0

func dust(speed_kph: float, chassisScenes: Array[GPUParticles2D]):
	if _dust:
		dust_color_power.set_point_offset(0, speed_dust[0])
		dust_color_power.set_point_offset(1, speed_dust[1])
		if speed_dust[0] < speed_kph and speed_kph < speed_dust[1]:
			for scene in chassisScenes:
				scene.amount_ratio = 1
				scene.modulate = Color(255, 255, 255, dust_color_power.sample(speed_kph))
	else:
		for scene in chassisScenes:
				scene.amount_ratio = 0
				scene.modulate = Color(255, 255, 255, 0)