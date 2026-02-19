class_name Vehicle
extends RigidBody2D

@export var curve: Curves
@export var engine: EngineStats
@export var gearbox: GearboxStats
@export var transmission: TransmissionStats
@export var chassis: ChassisStats
@export var brake: BrakeStats
@export var tire: TireStats
@export var drive: DrivePhysicsStats
@export var calculate: Functions

var ChassisRB: RigidBody2D
var WheelsRB: Array[Node]
var WheelsColl: Array[Node]
var ChassisColl: CollisionShape2D

var peakTorquePower: float
var peakPowerTorque: float
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
var drive_force: float
var engine_brake_force: float
var total_brake_torque: float
var actual_brake_balance: float
var rotational_inertia: float
var distance: float
var distance_overall: float

var wheel_weight: Array[float]
var brake_force: Array[float]
var wheels_mps: Array[float]
var wheels_angular_kph: Array[float]
var wheels_magnitude: Array[float]
var wheels_angular_mps: Array[float]
var wheels_angular_magnitude: Array[float]
var slip_ratios: Array[float]
var anti_brakings: Array[float]
var actual_brake_torques: Array[float]
var load_sensitivities: Array[float]
var rolling_resistances: Array[float]
var frictions: Array[float]

var drag_force: Vector2

func _ready() -> void:
	initalize()

func _input(_event:InputEvent) -> void:
	input_gear_i = calculate.input_gear_ratios(input_gear_i, gearbox.gears)
	input_throttle = calculate.input_throttle()
	input_clutch = calculate.input_clutch()
	input_brake = calculate.input_brake()
	input_handbrake = calculate.input_handbrake(brake.handbrake_power)

func _process(_delta:float) -> void:
	$Label.text = "Power Distribution: %s\nSpeed: %.1fkph %.1fmph %.1fmps\nAccel: %.3f\nTire Angular Velocity: %.1fkph\nRPM: %.1f\nGear: %.f\nPower: %.1fkW\nTorque: %.1fNm\nDrive Force: %.1fNm\nEngine Brake Force: %.1fNm\nBrake Force: %sNm\nSlip Ratio: %.3f\nLoad Sensitivity: %.3f\nFriction: %.3f\nDrag: %vN\nRolling Resistance: %sN\n" % [transmission.power_distribution, kph, kph * 0.621371, mps, acceleration, calculate.angular_kph(WheelsRB[transmission.power_distribution], tire.radius), wheel_rpm, input_gear_i - 1, curve.power_curve.sample(wheel_rpm), curve.torque_curve.sample(wheel_rpm), drive_force, engine_brake_force, [int(brake_force[0] * anti_brakings[0]), int(brake_force[1] * anti_brakings[1])], slip_ratios[transmission.power_distribution], load_sensitivities[transmission.power_distribution], WheelsRB[transmission.power_distribution].physics_material_override.friction, drag_force, [int(rolling_resistances[0]), int(rolling_resistances[1])]]
	$Label2.text = "Weight Transfer: %.1f kg, %.1f kg\nGlobal Pos: %.3f\nPos: %.3f\nDistance: %.3f m\nthrottle: %.1f\nbrake: %.1f\nhandbrake: %.f" % [wheel_weight[0], wheel_weight[1], ChassisRB.global_position.x, ChassisRB.position.x, distance_overall * 0.01, input_throttle * traction_control, input_brake, input_handbrake]

func _physics_process(delta:float) -> void:
	# Chassis
	kph = calculate.kph(ChassisRB)
	mps = calculate.mps(ChassisRB)
	magnitude = calculate.magnitude(ChassisRB)
	acceleration = calculate.acceleration(delta, mps, magnitude)
	distance = calculate.distance_travelled(ChassisRB)
	distance_overall += distance

	# Wheels
	wheel_weight = calculate.process_weight_transfer(acceleration, cL, hL, bL, drive.GRAVITY, rotational_inertia)
	for i in WheelsRB.size():
		WheelsRB[i].mass = wheel_weight[i]
		wheels_angular_kph[i] = calculate.angular_kph(WheelsRB[i], tire.radius)
		wheels_mps[i] = calculate.mps(WheelsRB[i])
		wheels_angular_mps[i] = calculate.angular_mps(WheelsRB[i], tire.radius)
		wheels_magnitude[i] = calculate.magnitude(WheelsRB[i])
		wheels_angular_magnitude[i] = calculate.wheel_magnitude(WheelsRB[i])
		load_sensitivities[i] = calculate.load_sensitivity(tire.radius, tire.lon_load_sensitivity, drive_force, brake_force[i], engine_brake_force, wheel_weight[i] * drive.GRAVITY)
		rolling_resistances[i] = calculate.process_rolling_resistance(tire.rolling_resistance, wheels_mps[i], chassis.mass, wheels_magnitude[i])
		slip_ratios[i] = calculate.slip_ratio(wheels_mps[i], WheelsRB[i], tire.radius)
		anti_brakings[i] = calculate.anti_braking(slip_ratios[i])
		frictions[i] = calculate.process_friction(curve.slip_ratio_curve, slip_ratios[i], load_sensitivities[i])
		WheelsRB[i].physics_material_override.friction = frictions[i]
	traction_control = calculate.traction_control(slip_ratios[transmission.power_distribution])
	wheel_rpm = calculate.rpm(WheelsRB[transmission.power_distribution], gearbox.gears, input_gear_i, gearbox.final_drive, engine.idle_rpm, input_throttle, engine.auto_clutch_rpm)

	# Forces
	engine_brake_force = calculate.process_engine_brake(engine.engine_brake_base, engine.engine_brake_peak, wheel_rpm, engine.idle_rpm, engine.engine_brake_peak_rpm, engine.engine_brake_exponent,
			wheels_angular_magnitude[transmission.power_distribution], engine.red_line_rpm, engine.rpm_limit, gearbox.gears, gearbox.final_drive, input_gear_i, tire.radius, rotational_inertia, input_throttle)
	brake_force = calculate.process_brake(actual_brake_torques, input_handbrake, input_brake, wheels_angular_magnitude, rotational_inertia)
	drag_force = calculate.process_drag(mps, chassis.frontal_area, chassis.drag_coefficiency, chassis.lon_aero_torque, chassis.lift, drive.AIR_DENSITY, magnitude)


	torque_at = calculate.torque_at_rpm(curve.power_curve, curve.torque_curve, wheel_rpm)
	if wheel_rpm < engine.red_line_rpm + engine.rpm_limit:
		drive_force = calculate.drive_torque(torque_at, gearbox.gears, input_gear_i, gearbox.final_drive, tire.radius, input_throttle, traction_control)
	else:
		drive_force = 0.0

	if transmission.power_distribution:
		WheelsRB[0].apply_torque_impulse(brake_force[0] * anti_brakings[0] + rolling_resistances[0])
		WheelsRB[1].apply_torque_impulse(drive_force + engine_brake_force + brake_force[1] * anti_brakings[1] + rolling_resistances[1])
	else:
		WheelsRB[0].apply_torque_impulse(drive_force + engine_brake_force + brake_force[0] * anti_brakings[0] + rolling_resistances[0])
		WheelsRB[1].apply_torque_impulse(brake_force[1] * anti_brakings[1] + rolling_resistances[1])

	ChassisRB.apply_central_force(drag_force)

func initalize():
	ChassisRB = get_tree().get_first_node_in_group("chassis")
	WheelsRB = get_tree().get_nodes_in_group("wheels")
	WheelsColl = get_tree().get_nodes_in_group("wheels_coll")
	ChassisColl = get_tree().get_first_node_in_group("chassis_coll")
	var size = WheelsRB.size()

	wheels_mps.resize(size)
	wheels_angular_kph.resize(size)
	wheels_magnitude.resize(size)
	wheels_angular_mps.resize(size)
	wheels_angular_magnitude.resize(size)
	wheel_weight.resize(size)
	slip_ratios.resize(size)
	anti_brakings.resize(size)
	brake_force.resize(size)
	actual_brake_torques.resize(size)
	load_sensitivities.resize(size)
	rolling_resistances.resize(size)
	frictions.resize(size)

	### Set Curves
	peakTorquePower = calculate.power_at(engine.peak_torque, drive.MAGIC_CROSS_RPM, engine.peak_torque_rpm)
	peakPowerTorque =  calculate.torque_at(engine.peak_power, drive.MAGIC_CROSS_RPM, engine.peak_power_rpm)

	var slope1 = ((0.0 - peakTorquePower) / (engine.zero_power_rpm - engine.peak_torque_rpm))
	var slope2 = ((peakTorquePower - (engine.peak_power * engine.upgrade)) / (engine.peak_torque_rpm - engine.peak_power_rpm))
	var slope3 = (((engine.peak_power * engine.upgrade) - ((engine.peak_power * engine.upgrade) * engine.red_line_power)) / (engine.peak_power_rpm - engine.red_line_rpm))
	var slope4 = (((engine.peak_power * engine.upgrade) * engine.red_line_power - engine.aux_line_power) / (engine.red_line_rpm - engine.aux_line_rpm))

	curve.power_curve.max_domain = engine.aux_line_rpm
	curve.power_curve.max_value = engine.peak_power * engine.upgrade
	
	curve.torque_curve.max_domain = engine.aux_line_rpm
	curve.torque_curve.max_value = engine.peak_torque * engine.upgrade
	
	curve.slip_ratio_curve.max_value = tire.lon_friction[0]
	curve.slip_ratio_curve.min_value = -tire.lon_friction[0]

	## Power Curve
	curve.power_curve.clear_points()
	# Zero Power RPM
	curve.power_curve.add_point(Vector2(engine.zero_power_rpm, 0),
			0, slope1)
	# Peak Power RPM
	curve.power_curve.add_point(Vector2(engine.peak_power_rpm, engine.peak_power * engine.upgrade), 
			0, 0)
	# Red Line RPM
	curve.power_curve.add_point(Vector2(engine.red_line_rpm, (engine.peak_power * engine.red_line_power) * engine.upgrade),
			slope3, 0,
			Curve.TANGENT_FREE, Curve.TANGENT_LINEAR)
	# Aux Line RPM
	curve.power_curve.add_point(Vector2(engine.aux_line_rpm, engine.peak_power * engine.red_line_power * engine.aux_line_power * engine.upgrade),
			0, 0)

	## Torque Curve
	curve.torque_curve.clear_points()
	# Zero Power RPM
	curve.torque_curve.add_point(Vector2(engine.zero_power_rpm, 0),
			0, slope2)
	# Peak Torque RPM
	curve.torque_curve.add_point(Vector2(engine.peak_torque_rpm, engine.peak_torque * engine.upgrade),
			0, 0)
	# Red Line RPM
	curve.torque_curve.add_point(Vector2(engine.red_line_rpm, calculate.torque_at(engine.peak_power * engine.red_line_power * engine.upgrade, drive.MAGIC_CROSS_RPM, engine.red_line_rpm)),
			slope4, 0,
			Curve.TANGENT_FREE, Curve.TANGENT_LINEAR)
	# Aux Line RPM
	curve.torque_curve.add_point(Vector2(engine.aux_line_rpm, engine.peak_torque * engine.red_line_power * engine.aux_line_power * engine.upgrade),
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

	### Set collision dimensions
	ChassisColl.shape.size = Vector2(chassis.lenght, chassis.height)
	for coll in WheelsColl:
		coll.shape.radius = tire.radius
		
	### Weight transfer
	c = abs(WheelsRB[0].global_position.x - ChassisColl.global_position.x) * 0.01
	b = abs(WheelsRB[1].global_position.x - ChassisColl.global_position.x) * 0.01
	L = c + b
	CGh = abs(ChassisColl.position.y - WheelsRB[0].position.y - tire.radius) * 0.01
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
	top_gear_speed = ((engine.red_line_rpm + engine.rpm_limit) * ((tire.radius * 2) * 0.01) * PI) / (gearbox.final_drive * gearbox.gears[-1])
	top_gear_speed = (top_gear_speed * 0.06) * (1 - tire.radius * 0.001) # to account for slip ratio
	top_power_speed = pow((2 * ((engine.peak_power) * engine.upgrade) / (chassis.drag_coefficiency * (drive.AIR_DENSITY * chassis.frontal_area))), 1.0 / 3.0) * 10.0 * 3.6

	### Overall mass
	chassis.mass += (size * 2) * tire.mass

	### Debug
	print("%.f hp @ %.f" % [engine.peak_power * 1.34102209 * engine.upgrade, engine.peak_power_rpm])
	print("%.f Nm @ %.f" % [engine.peak_torque * engine.upgrade, engine.peak_torque_rpm])

	print("Gearing-limited Top Speed: %.2f km/h" % [top_gear_speed])
	print("Power-limited Top Speed: %.2f km/h" % [top_power_speed])

	print("Power Curve slope 1: ",curve.power_curve.get_point_right_tangent(0))
	print("Torque Curve slope 2: ",curve.torque_curve.get_point_right_tangent(0))
	print("Power Curve slope 3: ",curve.power_curve.get_point_left_tangent(2))
	print("Torque Curve slope 4: ",curve.torque_curve.get_point_left_tangent(2))

	print("Rotational Inertia: ", rotational_inertia)

	print("Performance Points: %.f" % [(engine.peak_power * engine.upgrade * 1.34102209) / chassis.mass * 1000])
