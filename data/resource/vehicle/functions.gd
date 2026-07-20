## Physics functions of the Vehicle
class_name Functions
extends Resource

@export_range(0.0, 1.0, 0.01) var _traction_control_ = 0.33
@export_range(0.0, 1.0, 0.01) var _anti_braking_ = 0.1
@export var _mps = true
@export var _kph = true
@export var _angular_mps = true
@export var _angular_kph = true
@export var _magnitude = true
@export var _wheel_magnitude = true
@export var _acceleration = true
@export var _rpm = true
@export var _torque_at_rpm = true
@export var _drive_torque = true
@export var _slip_ratio = true
@export var _lon_load_sensitivity = true
@export var _process_drag = true
@export var _process_rolling_resistance = true
@export var _process_friction = true
@export var _process_engine_brake = true
@export var _process_brake = true
@export var _process_weight_transfer = true
@export var _input_gear_ratios = true
@export var _input_throttle = true
@export var _input_brake = true
@export var _input_clutch = true
@export var _input_handbrake = true

var previous_velocity: float
var previous_position: float

## Returns the torque at the given RPM based on power
func torque_at(power:float, MAGIC_CROSS_RPM:float, RPM:float) -> float:
	return power * MAGIC_CROSS_RPM / RPM

## Returns the power at the given RPM based on torque
func power_at(torque:float, MAGIC_CROSS_RPM:float, RPM:float) -> float:
	return torque * RPM / MAGIC_CROSS_RPM

## Returns the speed in mps
func mps(rigidbody:RigidBody2D) -> float:
	if _mps:
		return sqrt(((rigidbody.linear_velocity.x * 0.01) * (rigidbody.linear_velocity.x * 0.01)) + ((rigidbody.linear_velocity.y * 0.01) * (rigidbody.linear_velocity.y * 0.01)))
	else:
		return 0.0

## Returns the speed in kph
func kph(rigidbody:RigidBody2D) -> float:
	if _kph:
		return sqrt(((rigidbody.linear_velocity.x * 0.01) * (rigidbody.linear_velocity.x * 0.01)) + ((rigidbody.linear_velocity.y * 0.01) * (rigidbody.linear_velocity.y * 0.01))) * 3.6
	else:
		return 0.0

## Returns the angulart speed in mps
func angular_mps(rigidbody:RigidBody2D, wheel_radius: float) -> float:
	if _angular_mps:
		return (rigidbody.angular_velocity * (wheel_radius * 0.01))
	else:
		return 0.0

## Returns the angulart speed in kph
func angular_kph(rigidbody:RigidBody2D, wheel_radius: float) -> float:
	if _angular_kph:
		return (rigidbody.angular_velocity * (wheel_radius * 0.01)) * 3.6
	else:
		return 0.0

## Returns the overall distance travelled of the node
func distance_travelled(node:RigidBody2D):
	var current_position = node.position.x
	var distance = current_position - previous_position
	previous_position = current_position
	return abs(distance)

## Returns the magnitude of the node
func magnitude(rigidbody:RigidBody2D) -> float:
	if _magnitude:
		return clampf(rigidbody.linear_velocity.x, -1, 1)
	else:
		return 0.0

## Returns the magnitude of the node
func wheel_magnitude(wheel:RigidBody2D) -> float:
	if _wheel_magnitude:
		return clampf(wheel.angular_velocity, -1, 1)
	else:
		return 0.0

## Returns the acceleration in mps
func acceleration(physics_process_delta:float, speed_mps:float, magnitude_:float) -> float:
	if _acceleration:
		var current_velocity = speed_mps
		var a = (current_velocity - previous_velocity) / physics_process_delta
		previous_velocity = current_velocity
		return a * magnitude_
	else:
		return 0.0

## Returns the RPM of the Wheel
func rpm(wheel:RigidBody2D, gears:Array, gear_i:int, final_drive:float, idle_rpm:float, throttle:float, clutch_target_rpm:float) -> float:
	if _rpm:
		var rpm_wheel = abs(((wheel.angular_velocity * gears[gear_i] * final_drive) * 60) / (2 * PI))
		var min_rpm = clampf(lerpf(idle_rpm, 0.0, rpm_wheel / idle_rpm), 0.0, idle_rpm)
		var clutch_release = clampf(lerpf(clutch_target_rpm - idle_rpm, 0.0, (rpm_wheel - min_rpm) / clutch_target_rpm), 0.0, clutch_target_rpm - idle_rpm) * throttle
		#print("%.f minRPM  %.f clutchRPM" % [min_rpm, clutch_release])
		if gear_i == 1:
			return idle_rpm
		else:
			return rpm_wheel + min_rpm + clutch_release
	else:
		return 0.0

## Returns the torque at the given Wheel RPM
func torque_at_rpm(power:Curve, torque:Curve, wheel_rpm:float) -> float:
	if _torque_at_rpm:
		return torque.sample(wheel_rpm) + power.sample(wheel_rpm)
	else:
		return 0.0

## Returns the drive torque through the Wheels
func drive_torque(torque_at_rpm_:float, gears:Array, gear_i:int, final_drive:float, wheel_radius:float, throttle:float, traction_control_:float) -> float:
	if _drive_torque:
		return (((torque_at_rpm_ * gears[gear_i] * final_drive) / (wheel_radius * 0.01)) * throttle) * traction_control_
	else:
		return 0.0

## Returns the Slip ratio of the Wheel
func slip_ratio(speed_mps:float, wheel:RigidBody2D, wheel_radius:float) -> float:
	if _slip_ratio:
		return clampf(((abs(wheel.angular_velocity) * (wheel_radius * 0.01)) / speed_mps) - 1, -3.14, 3.14)
	else:
		return 0.0

## Traction control System
func traction_control(slip_ratio_:float) -> float:
	if _traction_control_:
		if abs(slip_ratio_) > 0.1:
			return (lerpf(1, 0, clampf(abs(slip_ratio_) + _traction_control_, 0.0, 1.0)))
		return 1.0
	else:
		return 1.0

## Anti Braking System
func anti_braking(slip_ratio__:float) -> float:
	if _anti_braking_:
		if abs(slip_ratio__) > 0.1:
			return (lerpf(1, 0, clampf(abs(slip_ratio__) + _anti_braking_, 0.0, 1.0)))
		return 1.0
	else:
		return 1.0

## Returns the normalized load sensitivity of the Wheel
func load_sensitivity(tire_radius:float, lon_load_sensitivity:Vector2, drive_force:float, engine_brake_force:float, brake_force:float, wheel_weight:float) -> float:
	if _lon_load_sensitivity:
		var meter = tire_radius * 0.01 
		var _load_sensitivity = pow(lon_load_sensitivity[1], lon_load_sensitivity[0])
		var normalized_load_sensitivity = pow(abs((drive_force / meter) + (engine_brake_force / meter) + (brake_force / meter) + wheel_weight) + lon_load_sensitivity[1], lon_load_sensitivity[0]) / _load_sensitivity
		return normalized_load_sensitivity
	else:
		return 1.0

## Returns the Force of the drag
func process_drag(speed_mps:float, frontal_area:float, drag_coef:float, aero_torque:float, lift:float, air_density:float, magnitude_:float) -> Vector2:
	if _process_drag:
		var lon_drag = -(drag_coef * pow(speed_mps / aero_torque, 2) * (air_density * frontal_area) / 2.0) * magnitude_
		var lift_force = (lift * (air_density * frontal_area) * pow(speed_mps / aero_torque, 2)) / 2.0
		return Vector2(lon_drag, lift_force)
	else:
		return Vector2.ZERO

## Returns the Force of the rolling resistance
func process_rolling_resistance(rr_coef:float, wheel_mps:float, chassis_weight:float, magnitude_:float) -> float:
	if _process_rolling_resistance:
		return -((rr_coef * chassis_weight) * (wheel_mps * magnitude_))
	else:
		return 0.0

## Returns the friction
func process_friction(slip_ratio_curve:Curve, slip_ratio_:float, _load_sensitivity:float):
	if _process_friction:
		return slip_ratio_curve.sample(slip_ratio_) * _load_sensitivity
	else:
		return 1.0

## Returns the engine braking
func process_engine_brake(brake_base:float, brake_peak:float, wheel_rpm:float, idle_rpm:float, brake_peak_rpm:float, brake_exponent, wheel_magnitude_:float, redline_rpm:float, rpm_limit:float,
		gears:Array, final_drive:float, gear_i:int, tire_radius:float, inertia_, throttle) -> float:
	if _process_engine_brake:
		var Fbrake = -pow(lerpf(brake_base, brake_peak, wheel_rpm / brake_peak_rpm), brake_exponent) * wheel_magnitude_
		if wheel_rpm > redline_rpm + rpm_limit:
			return Fbrake * abs(gears[2]) * final_drive * (tire_radius * 0.01) * inertia_
		elif wheel_rpm == idle_rpm:
			return 0.0
		else:
			if is_zero_approx(throttle):
				return Fbrake * abs(gears[gear_i]) * final_drive * (tire_radius * 0.01)
			else:
				return 0.0
	else:
		return 0.0

## Returns the power of the brakes
func process_brake(brake_power:Vector2, handbrake:float, brake:float, wheel_magnitudes:Vector2, rotational_inertia_:float) -> Vector2:
	if _process_brake:
		if handbrake:
			return Vector2(2 * rotational_inertia_ * brake_power[0] * handbrake * -wheel_magnitudes[0], 2 * brake_power[1] * brake * -wheel_magnitudes[1])
		else:
			return Vector2(2 * brake_power[0] * brake * -wheel_magnitudes[0], 2 * brake_power[1] * brake * -wheel_magnitudes[1])
	else:
		return Vector2.ZERO

## Returns the transferred weight between the Wheels
func process_weight_transfer(acceleration_:float, cL:float, hL:float, bL:float, gravity:float, inertia:float) -> Vector2:
	if _process_weight_transfer:
		var wf = (((cL) * gravity) - ((hL) * 1.0 * acceleration_)) # Wf = (c/L)*9.8 - (h/L)*1*a
		var wr = (((bL) * gravity) + ((hL) * 1.0 * acceleration_)) # Wr = (b/L)*9.8 + (h/L)*1*a,
		if wf < 1.0:
			wf = 1.0
		if wr < 1.0:
			wr = 1.0
		return Vector2(wr * inertia, wf * inertia)
	else:
		return Vector2i(1, 1)

func top_gear_speed(red_line_rpm:float, rpm_limit:float, tire_radius:float, final_drive:float, gears:Array) -> float:
	var top_gear = ((red_line_rpm + rpm_limit) * ((tire_radius * 2) * 0.01) * PI) / (final_drive * gears[-1])
	top_gear = (top_gear * 0.06) * (1 - tire_radius * 0.001)
	return top_gear

func top_power_speed(peak_power:float, drag_coef:float, air_density, frontal_area) -> float:
	return pow((2 * ((peak_power)) / (drag_coef * (air_density * frontal_area))), 1.0 / 3.0) * 10.0 * 3.6

func performance(peak_power, efficiency, chassis_mass):
	return (peak_power * efficiency * Global.HORSEPOWER) / chassis_mass * 1000

## Returns the current gear ratio
func input_gear_ratios(gear_i:int, gears:Array, event:InputEvent) -> int:
	if _input_gear_ratios:
		if event.is_action_pressed("ui_up") and gear_i < gears.size() - 1:
			gear_i += 1
		if event.is_action_pressed("ui_down") and gear_i > 0:
			gear_i -= 1
		return gear_i
	return 1

## Returns the state of the throttle
func input_throttle() -> float:
	if _input_throttle:
		if Input.is_action_pressed("ui_right"):
			return 1.0
	return 0.0

## Returns the state of the brake
func input_brake() -> float:
	if _input_brake:
		if Input.is_action_pressed("ui_left"):
			return 1.0
	return 0.0

## Returns the state of the clutch
func input_clutch() -> float:
	if _input_clutch:
		if Input.is_action_pressed("Clutch"):
			return 0.0
	return 1.0

## Returns the state of the handbrake
func input_handbrake(handbrake_power:float) -> float:
	if _input_handbrake:
		if Input.is_action_pressed("space"):
			return handbrake_power
	return 0.0

func input_efficiency(event:InputEvent):
	if event.is_action_released("scroll_up"):
		Global.ChassisRB.engine.efficiency += 0.025
		#Global.ChassisRB.gearbox.final_drive -= 0.015
		#Global.ChassisRB.top_gear_speed = Global.Hud.top_gear()
		Global.ChassisRB.performance_point = Global.Hud.pp()
		Global.Hud.dyno()
	if event.is_action_released("scroll_down"):
		Global.ChassisRB.engine.efficiency -= 0.025
		#Global.ChassisRB.gearbox.final_drive += 0.015
		#Global.ChassisRB.top_gear_speed = Global.Hud.top_gear()
		Global.ChassisRB.performance_point = Global.Hud.pp()
		Global.Hud.dyno()