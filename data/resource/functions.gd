class_name Functions
extends Resource

@export_range(0.0, 1.0, 0.01) var _traction_control_ = 0.5
@export_range(0.0, 1.0, 0.01) var _anti_braking_ = 0.5
@export var _mps = true
@export var _kph = true
@export var _magnitude = true
@export var _wheel_magnitude_ = true
@export var _acceleration = true
@export var _rpm = true
@export var _torque_at_rpm = true
@export var _drive_torque = true
@export var _slip_ratio = true
@export var _process_drag = true
@export var _process_rolling_resistance = true
@export var _process_engine_brake_ = true
@export var _process_weight_transfer = true
@export var _input_gear_ratios_ = true
@export var _input_throttle_ = true
@export var _input_brake_ = true
@export var _input_handbrake_ = true

var previous_velocity: float

func mps(rigidbody:RigidBody2D) -> float:
	if _mps:
		return rigidbody.linear_velocity.x * 0.01
	else:
		return 0.0

func kph(rigidbody:RigidBody2D) -> float:
	if _kph:
		return (rigidbody.linear_velocity.x * 0.01) * 3.6
	else:
		return 0.0

func magnitude(speed_kph:float) -> float:
	if _magnitude:
		return clampf(speed_kph, -1, 1)
	else:
		return 0.0

func wheel_magnitude(wheel:RigidBody2D) -> float:
	if _wheel_magnitude_:
		return clampf(wheel.angular_velocity, -1, 1)
	else:
		return 0.0

func acceleration(physics_process_delta:float, speed_mps:float) -> float:
	if _acceleration:
		var current_velocity = speed_mps
		var a = (current_velocity - previous_velocity) / physics_process_delta
		previous_velocity = current_velocity
		return a
	else:
		return 0.0

func rpm(wheel:RigidBody2D, gears:Array, gear_i:int, final_drive:float, idle_rpm:float, throttle:float, clutch_target_rpm:float) -> float:
	if _rpm:
		var rpm_wheel = ((wheel.angular_velocity * gears[gear_i] * final_drive) * 60) / (2*PI)
		var min_rpm = clampf(lerpf(idle_rpm, 0.0, rpm_wheel / idle_rpm), 0.0, idle_rpm)
		var clutch_release = clampf(lerpf(clutch_target_rpm - idle_rpm, 0.0, (rpm_wheel - min_rpm) / (idle_rpm + (clutch_target_rpm - idle_rpm))), 0.0, clutch_target_rpm - idle_rpm) * throttle
		if gear_i == 1:
			return idle_rpm
		else:
			return abs(rpm_wheel) + min_rpm + clutch_release
	else:
		return 0.0

func torque_at_rpm(power:Curve, torque:Curve, wheel_rpm:float) -> float:
	if _torque_at_rpm:
		return torque.sample(wheel_rpm) + power.sample(wheel_rpm)
	else:
		return 0.0

func drive_torque(torque_at_rpm_:float, gears:Array, gear_i:int, final_drive:float, wheel_radius:float, throttle:float, traction_control_:float) -> float:
	if _drive_torque:
		return (((torque_at_rpm_ * gears[gear_i] * final_drive) / (wheel_radius * 0.01)) * throttle) * traction_control_
	else:
		return 0.0

func slip_ratio(speed_mps:float, wheel:RigidBody2D, wheel_radius:float) -> float:
	if _slip_ratio:
		return clampf(((wheel.angular_velocity * (wheel_radius * 0.01)) - speed_mps) / abs(speed_mps), -1.0, 1.0)
	else:
		return 0.0

func traction_control(slip_ratio_rear:float) -> float:
	if _traction_control_:
		if abs(slip_ratio_rear) > 0.1:
			return (lerpf(1, 0, clampf(abs(slip_ratio_rear) + _traction_control_, 0.0, 1.0)))
		return 1.0
	else:
		return 1.0

func anti_braking(slip_ratio_rear:float) -> float:
	if _anti_braking_:
		if abs(slip_ratio_rear) > 0.1:
			return (lerpf(1, 0, clampf(abs(slip_ratio_rear) + _anti_braking_, 0.0, 1.0)))
		return 1.0
	else:
		return 1.0

func process_drag(chassis:RigidBody2D, speed_mps:float, drag_coef:float, aero_torque:float ,frontal_area:float, air_density:float, magnitude_:float):
	if _process_drag:
		var Fdrag = -(drag_coef * pow(speed_mps / aero_torque, 2) * air_density * frontal_area / 2.0) * magnitude_
		chassis.constant_force.x = Fdrag
	else:
		chassis.constant_force.x = 0

func process_rolling_resistance(wheels:Array[Node], rr_coef:float, speed_mps:float, chassis_weight:float):
	if _process_rolling_resistance:
		var Frr = (-(rr_coef * chassis_weight) * speed_mps) * 2
		for wheel in wheels:
			wheel.constant_force.x = Frr
	else:
		for wheel in wheels:
			wheel.constant_force.x = 0

func process_friction(slip_ratio_curve:Curve, slip_ratio_rear:float, slip_ratio_front, wheels:Array[Node], friction_coef:float):
	wheels[0].physics_material_override.friction = abs(friction_coef * slip_ratio_curve.sample(slip_ratio_rear))
	wheels[1].physics_material_override.friction = abs(friction_coef * slip_ratio_curve.sample(slip_ratio_front))


func process_brakes(wheels:Array[Node],brake_base:float, brake_peak:float, brake_exponent:float, wheel_rpm:float, redline_rpm:float, rpm_limit:float,
		brake_peak_rpm:float ,brake:float, handbrake:float, front_brake:float, rear_brake:float, wheel_magnitude_front:float, wheel_magnitude_rear:float, gear_i:float, 
		gears:Array, throttle:float, anti_braking_rear:float, anti_braking_front: float):
	if _process_engine_brake_:
		var Fbrake = -pow(lerpf(brake_base, brake_peak, wheel_rpm / brake_peak_rpm), brake_exponent) * wheel_magnitude_rear
		# Engine braking
		if gear_i == 1:
			wheels[0].constant_torque = 0
		elif wheel_rpm > redline_rpm + rpm_limit:
			wheels[0].constant_torque = Fbrake * 350.0
		else:
			if is_zero_approx(throttle):
				wheels[0].constant_torque = Fbrake * abs(gears[gear_i]) * 100.0
			else:
				wheels[0].constant_torque = Fbrake * abs(gears[gear_i])
		# braking
		if handbrake:
			wheels[0].constant_torque = (rear_brake * handbrake * -wheel_magnitude_rear) * 100 * 2 + (Fbrake * abs(gears[gear_i]) * 25)
		elif brake:
			wheels[0].constant_torque = (rear_brake * brake * -wheel_magnitude_rear * anti_braking_rear) * 100 * 2 + (Fbrake * abs(gears[gear_i]) * 25)
		wheels[1].constant_torque = (front_brake * brake * -wheel_magnitude_front * anti_braking_front) * 100 * 2

func process_weight_transfer(wheels:Array[Node], acceleration_: float, cL:float, hL:float, bL:float, gravity: float):
	if _process_weight_transfer:
		var wf = (((cL) * gravity) - ((hL) * 1.0 * acceleration_)) # Wf = (c/L)*9.8 - (h/L)*1*a
		var wr = (((bL) * gravity) + ((hL) * 1.0 * acceleration_)) # Wr = (b/L)*9.8 + (h/L)*1*a,
		if wf < 0.0: wheels[1].mass = 1.0
		else: wheels[1].mass = wf * 2
		if wr < 0.0: wheels[0].mass = 1.0
		else: wheels[0].mass = wr * 2
	else:
		for wheel in wheels:
			wheel.mass = 1

func input_gear_ratios(gear_i:int, gears:Array) -> int:
	if _input_gear_ratios_:
		if Input.is_action_just_pressed("ui_up") and gear_i < gears.size() - 1:
				gear_i += 1
		if Input.is_action_just_pressed("ui_down") and gear_i > 0:
				gear_i -= 1
		return gear_i
	return 0

func input_throttle() -> float:
	if _input_throttle_:
		if Input.is_action_pressed("ui_right"):
			return 1.0
	return 0.0

func input_brake() -> float:
	if _input_brake_:
		if Input.is_action_pressed("ui_left"):
			return 1.0
	return 0.0

func input_handbrake(handbrake_power:float) -> float:
	if _input_handbrake_:
		if Input.is_action_pressed("space"):
			return handbrake_power
	return 0.0
