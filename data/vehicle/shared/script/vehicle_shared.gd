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

var peakTorquePower: float
var peakPowerTorque: float

var ChassisRB: RigidBody2D
var WheelsRB: Array[Node]
var WheelsColl: Array[Node]
var ChassisColl: CollisionShape2D

var input_gear_i := 1
var input_throttle: float
var input_brake: float
var input_clutch: float
var input_handbrake: float

var drag_force: Vector2
var rr_force: Vector2

var kph: float
var mps: float
var acceleration: float
var magnitude: float
var wheels_mps := [0.0, 0.0]
var wheels_angular_kph := [0.0, 0.0]
var wheels_magnitude := [0.0, 0.0]
var wheels_angular_mps := [0.0, 0.0]
var wheels_angular_magnitude := [0.0, 0.0]
var wheel_rpm: float
var torque_at: float
var slip_ratios := [0.0, 0.0]
var anti_brakings := [0.0, 0.0]
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
var brake_force: Array

func _ready() -> void:
	initalize()

func _input(_event: InputEvent) -> void:
	input_gear_i = calculate.input_gear_ratios(input_gear_i, gearbox.gears)
	input_throttle = calculate.input_throttle()
	input_clutch = calculate.input_clutch()
	input_brake = calculate.input_brake()
	input_handbrake = calculate.input_handbrake(brake.handbrake_power)

func _process(_delta: float) -> void:
	$Label.text = "Power Distribution: %s\nSpeed: %.1fkph %.1fmph %.1fmps\nAccel: %.3f\nTire Angular Velocity: %.1fkph\nRPM: %.1f\nGear: %.f\nPower: %.1fkW\nTorque: %.1fNm\nDrive Force: %.1fN\nEngine Brake Force: %.1fN\nBrake Force: %s\nSlip Ratio: %.3f\nFriction: %.3f\nDrag: %v\nRolling Resistance: %.3f\n" % [transmission.power_distribution, kph, kph * 0.621371, mps, acceleration, calculate.angular_kph(WheelsRB[transmission.power_distribution], tire.radius), wheel_rpm, input_gear_i - 1, curve.power_curve.sample(wheel_rpm), curve.torque_curve.sample(wheel_rpm), drive_force, engine_brake_force, brake_force, slip_ratios[transmission.power_distribution], WheelsRB[transmission.power_distribution].physics_material_override.friction, drag_force, WheelsRB[transmission.power_distribution].constant_force.x * 0.25]
	$Label2.text = "Wr: %.3f\nWf: %.3f\nPos: %.3f\nthrottle: %.1f\nbrake: %.1f\nhandbrake: %.f" % [WheelsRB[0].mass, WheelsRB[1].mass, ChassisRB.position.x * 0.01, input_throttle, input_brake, input_handbrake]

func _physics_process(delta: float) -> void:
	kph = calculate.kph(ChassisRB)
	wheels_angular_kph[0] = calculate.angular_kph(WheelsRB[0], tire.radius)
	wheels_angular_kph[1] = calculate.angular_kph(WheelsRB[1], tire.radius)
	mps = calculate.mps(ChassisRB)
	wheels_mps[0] = calculate.mps(WheelsRB[0])
	wheels_mps[1] = calculate.mps(WheelsRB[1])
	wheels_angular_mps[0] = calculate.angular_mps(WheelsRB[0], tire.radius)
	wheels_angular_mps[1] = calculate.angular_mps(WheelsRB[1], tire.radius)
	magnitude = calculate.magnitude(ChassisRB)
	acceleration = calculate.acceleration(delta, mps, magnitude)
	wheels_angular_magnitude[0] = calculate.wheel_magnitude(WheelsRB[0])
	wheels_angular_magnitude[1] = calculate.wheel_magnitude(WheelsRB[1])
	wheel_rpm = calculate.rpm(WheelsRB[transmission.power_distribution], gearbox.gears, input_gear_i, gearbox.final_drive, engine.idle_rpm, input_throttle, engine.auto_clutch_rpm)
	torque_at = calculate.torque_at_rpm(curve.power_curve, curve.torque_curve, wheel_rpm)
	slip_ratios[0] = calculate.slip_ratio(wheels_mps[0], WheelsRB[0], tire.radius)
	slip_ratios[1] = calculate.slip_ratio(wheels_mps[1], WheelsRB[1], tire.radius)
	traction_control = calculate.traction_control(slip_ratios[transmission.power_distribution])
	anti_brakings[0] = calculate.anti_braking(slip_ratios[0])
	anti_brakings[1] = calculate.anti_braking(slip_ratios[1])

	if wheel_rpm < engine.red_line_rpm + engine.rpm_limit:
		drive_force = calculate.drive_torque(torque_at, gearbox.gears, input_gear_i, gearbox.final_drive, tire.radius, input_throttle, traction_control)
	else:
		drive_force = 0.0

	engine_brake_force = calculate.process_engine_brake(engine.engine_brake_base, engine.engine_brake_peak, wheel_rpm, engine.engine_brake_peak_rpm, engine.engine_brake_exponent,
			wheels_angular_magnitude[transmission.power_distribution], engine.red_line_rpm, engine.rpm_limit, gearbox.gears, gearbox.final_drive, input_gear_i, tire.radius, input_throttle)
	brake_force = calculate.process_brake([brake.brake_rear, brake.brake_front], input_handbrake, input_brake, brake.brake_balance, wheels_angular_magnitude)
	drag_force = calculate.process_drag(mps, chassis.drag_coefficiency, chassis.lon_aero_torque, chassis.lift, drive.AIR_DENSITY_DRAG, magnitude)

	ChassisRB.apply_central_force(drag_force)
	calculate.process_rolling_resistance(WheelsRB, tire.rolling_resistance, wheels_angular_mps, chassis.mass)
	calculate.process_weight_transfer(WheelsRB, acceleration, cL, hL, bL, drive.GRAVITY)
	calculate.process_friction(curve.slip_ratio_curve, slip_ratios, WheelsRB, tire.lon_friction)

	if transmission.power_distribution:
		WheelsRB[0].apply_torque_impulse(brake_force[0])
		WheelsRB[1].apply_torque_impulse(drive_force + engine_brake_force + brake_force[1])
	else:
		WheelsRB[0].apply_torque_impulse(drive_force + engine_brake_force + brake_force[0])
		WheelsRB[1].apply_torque_impulse(brake_force[1])

func initalize():
	ChassisRB = get_tree().get_first_node_in_group("chassis")
	WheelsRB = get_tree().get_nodes_in_group("wheels")
	WheelsColl = get_tree().get_nodes_in_group("wheels_coll")
	ChassisColl = get_tree().get_first_node_in_group("chassis_coll")

	### Set Curves
	curve.power_curve.max_domain = engine.aux_line_rpm
	curve.power_curve.max_value = engine.peak_power * engine.upgrade
	
	curve.torque_curve.max_domain = engine.aux_line_rpm
	curve.torque_curve.max_value = engine.peak_torque * engine.upgrade
	
	peakTorquePower = engine.peak_torque * engine.peak_torque_rpm / drive.MAGIC_CROSS_RPM
	peakPowerTorque = engine.peak_power * drive.MAGIC_CROSS_RPM / engine.peak_power_rpm

	## Power Curve
	curve.power_curve.clear_points()
	# Zero Power RPM
	curve.power_curve.add_point(Vector2(engine.zero_power_rpm, 0),
			0, ((0.0 - peakTorquePower) / (engine.zero_power_rpm - engine.peak_torque_rpm)))
	# Peak Power RPM
	curve.power_curve.add_point(Vector2(engine.peak_power_rpm, engine.peak_power * engine.upgrade), 
			0, 0)
	# Red Line RPM
	curve.power_curve.add_point(Vector2(engine.red_line_rpm, (engine.peak_power * engine.red_line_power) * engine.upgrade),
			(((engine.peak_power * engine.upgrade) - ((engine.peak_power * engine.upgrade) * engine.red_line_power)) / (engine.peak_power_rpm - engine.red_line_rpm)), 0,
			Curve.TANGENT_FREE, Curve.TANGENT_LINEAR)
	# Aux Line RPM
	curve.power_curve.add_point(Vector2(engine.aux_line_rpm, engine.peak_power * engine.red_line_power * engine.aux_line_power * engine.upgrade),
			0, 0)


	## Torque Curve
	curve.torque_curve.clear_points()
	# Zero Power RPM
	curve.torque_curve.add_point(Vector2(engine.zero_power_rpm, 0),
			0, ((peakTorquePower - (engine.peak_power * engine.upgrade)) / (engine.peak_torque_rpm - engine.peak_power_rpm)))
	# Peak Torque RPM
	curve.torque_curve.add_point(Vector2(engine.peak_torque_rpm, engine.peak_torque * engine.upgrade),
			0, 0)
	# Red Line RPM
	curve.torque_curve.add_point(Vector2(engine.red_line_rpm, calculate.torque_at(engine.peak_power * engine.red_line_power, drive.MAGIC_CROSS_RPM, engine.red_line_rpm) * engine.upgrade),
			(((engine.peak_power * engine.upgrade) * engine.red_line_power - engine.aux_line_power) / (engine.red_line_rpm - engine.aux_line_rpm)), 0,
			Curve.TANGENT_FREE, Curve.TANGENT_LINEAR)
	# Aux Line RPM
	curve.torque_curve.add_point(Vector2(engine.aux_line_rpm, engine.peak_torque * engine.red_line_power * engine.aux_line_power * engine.upgrade),
			0, 0)

	top_gear_speed = ((engine.red_line_rpm + engine.rpm_limit) * ((tire.radius * 2) * 0.01) * PI) / (gearbox.final_drive * gearbox.gears[-1])
	top_gear_speed = (top_gear_speed * 0.06) * (1 - tire.radius * 0.001) # to negate the slip ratio
	top_power_speed = pow((2 * (engine.peak_power * engine.upgrade) / (chassis.drag_coefficiency * drive.AIR_DENSITY * chassis.frontal_area)), 1.0 / 3.0) * 10.0 * 3.6

	print(int(engine.peak_power * 1.34102209 * engine.upgrade), " hp @ ", int(engine.peak_power_rpm))
	print(int(engine.peak_torque * engine.upgrade), " Nm @ ", int(engine.peak_torque_rpm))

	print("Gearing-limited Top Speed: ", int(top_gear_speed),"kph")
	print("Theoretical Power-limited Top Speed: ", int(top_power_speed),"kph")

	print("Power Curve slope 1: ",curve.power_curve.get_point_right_tangent(0))
	print("Torque Curve slope 2: ",curve.torque_curve.get_point_right_tangent(0))
	print("Power Curve slope 3: ",curve.power_curve.get_point_left_tangent(2))
	print("Torque Curve slope 4: ",curve.torque_curve.get_point_left_tangent(2))

	#print(peakTorquePower)
	#print(peakPowerTorque)

	# slope 1 ((0.0 - peakTorquePower) / (engine.zero_power_rpm - engine.peak_torque_rpm))
	# slope 2 ((peakTorquePower - engine.peak_power) / (engine.peak_torque_rpm - engine.peak_power_rpm))
	# slope 3 ((engine.peak_power - (engine.peak_power * engine.red_line_power)) / (engine.peak_power_rpm - engine.red_line_rpm))
	# slope 4 ((engine.peak_power * engine.red_line_power - engine.aux_line_power) / (engine.red_line_rpm - engine.aux_line_rpm))

	### set collision dimensions and friction
	ChassisColl.shape.size = Vector2(chassis.lenght, chassis.height)
	for coll in WheelsColl:
		coll.shape.radius = tire.radius
	for rb in WheelsRB:
		rb.physics_material_override.friction = tire.lon_friction
		
	### weight transfer
	c = abs(WheelsRB[0].global_position.x - ChassisColl.global_position.x) * 0.01
	b = abs(WheelsRB[1].global_position.x - ChassisColl.global_position.x) * 0.01
	L = c + b
	CGh = abs(ChassisColl.global_position.y - WheelsRB[0].global_position.y - tire.radius) * 0.01
	bL = b / L
	hL = CGh / L
	cL = c / L
