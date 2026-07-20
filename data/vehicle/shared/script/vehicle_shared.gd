class_name Vehicle
extends RigidBody2D

@export var vehicle_name: String
@export var curve: Curves
@export var engine: EngineStats
@export var gearbox: GearboxStats
@export var transmission: TransmissionStats
@export var chassis: ChassisStats
@export var brake: BrakeStats
@export var tire: TireStats
@export var calculate: Functions

var size: int

var peakTorquePower: float
var peakPowerTorque: float
var power0: float
var torque0: float
var input_gear_i := 1
var input_throttle: float
var input_brake: float
var input_clutch: float
var input_handbrake: float
var kph: float
var mps: float
var acceleration: float
var magnitude: float
var wheel_rpm: float
var torque_at: float
var traction_control: float
var c: float
var b: float
var L: float
var CGh: float
var bL: float
var hL: float
var cL: float
var top_gear_speed: float
var top_power_speed: float
var performance_point: float
var drive_force: float
var engine_brake_force: float
var total_brake_torque: float
var actual_brake_balance: float
var rotational_inertia: float
var distance: float
var distance_overall: float

var wheel_weight: Vector2
var brake_force: Vector2
var wheels_mps: Vector2
var wheels_angular_kph: Vector2
var wheels_magnitude: Vector2
var wheels_angular_mps: Vector2
var wheels_angular_magnitude: Vector2
var slip_ratios: Vector2
var anti_brakings: Vector2
var actual_brake_torques: Vector2
var load_sensitivities: Vector2
var rolling_resistances: Vector2
var frictions: Vector2
var drag_force: Vector2

func _ready() -> void:
	initalize()

func _input(event:InputEvent) -> void:
	input_gear_i = calculate.input_gear_ratios(input_gear_i, gearbox.gears, event)
	input_throttle = calculate.input_throttle()
	input_clutch = calculate.input_clutch()
	input_brake = calculate.input_brake()
	input_handbrake = calculate.input_handbrake(brake.handbrake_power)
	calculate.input_efficiency(event)

func _process(_delta:float) -> void:
	pass

func _physics_process(delta:float) -> void:
	if Engine.get_physics_frames() % Global.Priority.REALTIME == 0:
		# Chassis
		kph = calculate.kph(Global.ChassisRB)
		mps = calculate.mps(Global.ChassisRB)
		magnitude = calculate.magnitude(Global.ChassisRB)
		acceleration = calculate.acceleration(delta, mps, magnitude)
		distance = calculate.distance_travelled(Global.ChassisRB)
		distance_overall += distance

		# Wheels
		wheel_weight = calculate.process_weight_transfer(acceleration, cL, hL, bL, Global.GRAVITY, rotational_inertia)
		for i in size:
			Global.WheelsRB[i].mass = wheel_weight[i]
			wheels_angular_kph[i] = calculate.angular_kph(Global.WheelsRB[i], tire.radius)
			wheels_mps[i] = calculate.mps(Global.WheelsRB[i])
			wheels_angular_mps[i] = calculate.angular_mps(Global.WheelsRB[i], tire.radius)
			wheels_magnitude[i] = calculate.magnitude(Global.WheelsRB[i])
			wheels_angular_magnitude[i] = calculate.wheel_magnitude(Global.WheelsRB[i])
			load_sensitivities[i] = calculate.load_sensitivity(tire.radius, tire.lon_load_sensitivity, drive_force, brake_force[i], engine_brake_force, wheel_weight[i] * Global.GRAVITY)
			rolling_resistances[i] = calculate.process_rolling_resistance(tire.rolling_resistance, wheels_mps[i], chassis.mass, wheels_magnitude[i])
			slip_ratios[i] = calculate.slip_ratio(wheels_mps[i], Global.WheelsRB[i], tire.radius)
			anti_brakings[i] = calculate.anti_braking(slip_ratios[i])
			frictions[i] = calculate.process_friction(curve.slip_ratio_curve, slip_ratios[i], load_sensitivities[i])
			Global.WheelsRB[i].physics_material_override.friction = frictions[i]
		traction_control = calculate.traction_control(slip_ratios[transmission.power_distribution])
		wheel_rpm = calculate.rpm(Global.WheelsRB[transmission.power_distribution], gearbox.gears, input_gear_i, gearbox.final_drive, engine.idle_rpm, input_throttle, engine.auto_clutch_rpm)

		# Forces
		engine_brake_force = calculate.process_engine_brake(engine.engine_brake_base, engine.engine_brake_peak, wheel_rpm, engine.idle_rpm, engine.engine_brake_peak_rpm, engine.engine_brake_exponent,
				wheels_angular_magnitude[transmission.power_distribution], engine.red_line_rpm, engine.rpm_limit, gearbox.gears, gearbox.final_drive, input_gear_i, tire.radius, rotational_inertia, input_throttle)
		brake_force = calculate.process_brake(actual_brake_torques, input_handbrake, input_brake, wheels_angular_magnitude, rotational_inertia)
		drag_force = calculate.process_drag(mps, chassis.frontal_area, chassis.drag_coefficiency, chassis.lon_aero_torque, chassis.lift, Global.AIR_DENSITY, magnitude)


		torque_at = calculate.torque_at_rpm(curve.power_curve, curve.torque_curve, wheel_rpm)
		if wheel_rpm < engine.red_line_rpm + engine.rpm_limit:
			drive_force = calculate.drive_torque(torque_at, gearbox.gears, input_gear_i, gearbox.final_drive, tire.radius, input_throttle, traction_control) * engine.efficiency
		else:
			drive_force = 0.0

		if transmission.power_distribution:
			Global.WheelsRB[0].apply_torque_impulse((brake_force[0] * anti_brakings[0]) + rolling_resistances[0])
			Global.WheelsRB[1].apply_torque_impulse(drive_force + engine_brake_force + (brake_force[1] * anti_brakings[1]) + rolling_resistances[1])
		else:
			Global.WheelsRB[0].apply_torque_impulse(drive_force + engine_brake_force + brake_force[0] * anti_brakings[0] + rolling_resistances[0])
			Global.WheelsRB[1].apply_torque_impulse((brake_force[1] * anti_brakings[1]) + rolling_resistances[1])

		Global.ChassisRB.apply_central_force(drag_force)


func initalize():
	size = Global.WheelsRB.size()

	### Set Curves
	power0 = engine.peak_power
	torque0 = engine.peak_torque
	engine.peak_power *= engine.upgrade
	engine.peak_torque *= engine.upgrade

	peakTorquePower = calculate.power_at(engine.peak_torque, Global.MAGIC_CROSS_RPM, engine.peak_torque_rpm)
	peakPowerTorque =  calculate.torque_at(engine.peak_power, Global.MAGIC_CROSS_RPM, engine.peak_power_rpm)

	var slope1 = ((0.0 - peakTorquePower) / (engine.zero_power_rpm - engine.peak_torque_rpm))
	var slope2 = ((peakTorquePower - (engine.peak_power)) / (engine.peak_torque_rpm - engine.peak_power_rpm))
	var slope3 = (((engine.peak_power) - ((engine.peak_power) * engine.red_line_power)) / (engine.peak_power_rpm - engine.red_line_rpm))
	var slope4 = (((engine.peak_power) * engine.red_line_power - engine.aux_line_power) / (engine.red_line_rpm - engine.aux_line_rpm))

	curve.power_curve.max_domain = engine.aux_line_rpm
	curve.power_curve.max_value = engine.peak_power
	
	curve.torque_curve.max_domain = engine.aux_line_rpm
	curve.torque_curve.max_value = engine.peak_torque
	
	curve.slip_ratio_curve.max_value = tire.lon_friction[0]
	curve.slip_ratio_curve.min_value = -tire.lon_friction[0]

	## Power Curve
	curve.power_curve.clear_points()
	# Zero Power RPM
	curve.power_curve.add_point(Vector2(engine.zero_power_rpm, 0),
			0, slope1)
	# Peak Power RPM
	curve.power_curve.add_point(Vector2(engine.peak_power_rpm, engine.peak_power), 
			0, 0)
	# Red Line RPM
	curve.power_curve.add_point(Vector2(engine.red_line_rpm, (engine.peak_power * engine.red_line_power)),
			slope3, 0,
			Curve.TANGENT_FREE, Curve.TANGENT_LINEAR)
	# Aux Line RPM
	curve.power_curve.add_point(Vector2(engine.aux_line_rpm, engine.peak_power * engine.red_line_power * engine.aux_line_power),
			0, 0)

	## Torque Curve
	curve.torque_curve.clear_points()
	# Zero Power RPM
	curve.torque_curve.add_point(Vector2(engine.zero_power_rpm, 0),
			0, slope2)
	# Peak Torque RPM
	curve.torque_curve.add_point(Vector2(engine.peak_torque_rpm, engine.peak_torque),
			0, 0)
	# Red Line RPM
	curve.torque_curve.add_point(Vector2(engine.red_line_rpm, calculate.torque_at(engine.peak_power * engine.red_line_power, Global.MAGIC_CROSS_RPM, engine.red_line_rpm)),
			slope4, 0,
			Curve.TANGENT_FREE, Curve.TANGENT_LINEAR)
	# Aux Line RPM
	curve.torque_curve.add_point(Vector2(engine.aux_line_rpm, engine.peak_torque * engine.red_line_power * engine.aux_line_power),
			0, 0)

	## Slip Ratio Curve
	curve.slip_ratio_curve.clear_points()
	# - Slip Friction
	curve.slip_ratio_curve.add_point(Vector2(-(tire.slide_friciton_grip * 0.01) * curve.slip_ratio_curve.max_domain, -tire.lon_friction[1]))
	# - Static Friction
	curve.slip_ratio_curve.add_point(Vector2(-(tire.peak_friction_grip * 0.01), -tire.lon_friction[0]))
	# + Static Friction
	curve.slip_ratio_curve.add_point(Vector2(tire.peak_friction_grip * 0.01, tire.lon_friction[0]))
	# + Slip Friction
	curve.slip_ratio_curve.add_point(Vector2(tire.slide_friciton_grip * 0.01 * curve.slip_ratio_curve.max_domain, tire.lon_friction[1]))

	# draw torque curve
	Global.Hud.dyno()

	### Set collision dimensions and tire positions
	Global.ChassisColl.shape.size = Vector2(chassis.lenght, chassis.height)
	for coll in Global.WheelsColl:
		coll.shape.radius = tire.radius
		
	### Weight transfer
	c = abs(Global.WheelsRB[0].global_position.x - Global.ChassisColl.global_position.x) * 0.01
	b = abs(Global.WheelsRB[1].global_position.x - Global.ChassisColl.global_position.x) * 0.01
	L = c + b
	CGh = abs(Global.ChassisColl.position.y - Global.WheelsRB[0].position.y - tire.radius) * 0.01
	bL = b / L
	hL = CGh / L
	cL = c / L
	rotational_inertia = 0.5 * tire.mass * pow(tire.radius * 0.01, 2)

	### Set brake torques
	total_brake_torque = brake.brake_rear + brake.brake_front
	actual_brake_balance = brake.brake_front / total_brake_torque * (1 - (0.5 - brake.brake_balance) * 2)
	actual_brake_torques[0] = (1 - actual_brake_balance) * total_brake_torque
	actual_brake_torques[1] = actual_brake_balance * total_brake_torque

	### Calculate top speeds
	top_gear_speed = calculate.top_gear_speed(engine.red_line_rpm, engine.rpm_limit, tire.radius, gearbox.final_drive, gearbox.gears)
	top_power_speed = calculate.top_power_speed(engine.peak_power, chassis.drag_coefficiency, Global.AIR_DENSITY, chassis.frontal_area)

	### Overall mass
	chassis.mass += 4 * tire.mass
	performance_point = calculate.performance(engine.peak_power, engine.efficiency, chassis.mass)

	### Debug
	print("%.f kW @ %.f" % [engine.peak_power, engine.peak_power_rpm])
	print("%.f Nm @ %.f" % [engine.peak_torque, engine.peak_torque_rpm])

	print("Gearing-limited Top Speed: %.2f km/h" % [top_gear_speed])
	print("Power-limited Top Speed: %.2f km/h" % [top_power_speed])

	print("Power Curve slope 1: ",curve.power_curve.get_point_right_tangent(0))
	print("Torque Curve slope 2: ",curve.torque_curve.get_point_right_tangent(0))
	print("Power Curve slope 3: ",curve.power_curve.get_point_left_tangent(2))
	print("Torque Curve slope 4: ",curve.torque_curve.get_point_left_tangent(2))

	print("Rotational Inertia: ", rotational_inertia)

	print("Performance Points: %.f" % [performance_point])
	print("Upgrade -> %.2f hp, %.2f Nm" % [engine.peak_power - power0, engine.peak_torque - torque0])
