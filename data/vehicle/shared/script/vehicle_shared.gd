class_name Vehicle
extends RigidBody2D

@export var curve: Curves
@export var engine: EngineStats
@export var transmission: TransmissionStats
@export var chassis: ChassisStats
@export var tire: TireStats
@export var drive: DrivePhysicsStats
@export var calculate: Functions

var peakTorquePower: float
var peakPowerTorque: float

var ChassisRB: RigidBody2D
var WheelsRB: Array[Node]
var WheelsColl: Array[Node]
var ChassisColl: CollisionShape2D

var gear_i := 1
var throttle: float
var brake: float
var handbrake: float

var drag: float
var rr: float

var kph: float
var wheel_angular_kph: float
var mps: float
var acceleration: float
var magnitude: float
var wheel_rear_mps: float
var wheel_front_mps: float
var wheel_rear_angular_mps: float
var wheel_front_angular_mps: float
var wheel_magnitude_rear: float
var wheel_magnitude_front: float
var wheel_rpm: float
var torque_at: float
var slip_ratio_rear: float
var slip_ratio_front: float
var traction_control: float
var anti_braking_rear: float
var anti_braking_front: float

var c: float
var b: float
var L: float
var CGh: float
var bL: float
var hL: float
var cL: float

func _ready() -> void:
	initalize()

func _input(_event: InputEvent) -> void:
	gear_i = calculate.input_gear_ratios(gear_i, transmission.gears)
	throttle = calculate.input_throttle()
	brake = calculate.input_brake()
	handbrake = calculate.input_handbrake(chassis.handbrake_power)

func _process(_delta: float) -> void:
	$Label.text = "Speed: %.fkph %.fmph %.fmps\nAccel: %f\nTire Angular Velocity: %.fkph\nRPM: %.f\nGear: %.f\nPower: %.fkW\nTorque: %.fNm\nSlip Ratio rear: %f\nFriction rear: %f\nDrag: %v\nRolling Resistance: %f\nEngine Brake: %f" % [kph, kph * 0.621371, mps, acceleration, calculate.angular_kph(WheelsRB[0], tire.radius), wheel_rpm, gear_i - 1, curve.power_curve.sample(wheel_rpm), curve.torque_curve.sample(wheel_rpm), slip_ratio_rear, WheelsRB[0].physics_material_override.friction, ChassisRB.constant_force, WheelsRB[0].constant_force.x * 0.25, WheelsRB[0].constant_torque]
	$Label2.text = "Wr: %f\nWf: %f\n Pos: %f\nthrottle: %f\nbrake: %f\nhandbrake: %f" % [WheelsRB[0].mass, WheelsRB[1].mass, ChassisRB.position.x * 0.01, throttle, brake, handbrake]

func _physics_process(delta: float) -> void:
	kph = calculate.kph(ChassisRB)
	wheel_angular_kph = calculate.angular_kph(WheelsRB[0], tire.radius)
	mps = calculate.mps(ChassisRB)
	wheel_rear_mps = calculate.mps(WheelsRB[0])
	wheel_front_mps = calculate.mps(WheelsRB[1])
	wheel_rear_angular_mps = calculate.angular_mps(WheelsRB[0], tire.radius)
	wheel_front_angular_mps = calculate.angular_mps(WheelsRB[1], tire.radius)
	acceleration = calculate.acceleration(delta, mps, magnitude)
	magnitude = calculate.magnitude(ChassisRB)
	wheel_magnitude_rear = calculate.wheel_magnitude(WheelsRB[0])
	wheel_magnitude_front = calculate.wheel_magnitude(WheelsRB[1])
	wheel_rpm = calculate.rpm(WheelsRB[0], transmission.gears, gear_i, transmission.final_drive, engine.idle_rpm, throttle, engine.auto_clutch_rpm)
	torque_at = calculate.torque_at_rpm(curve.power_curve, curve.torque_curve, wheel_rpm)
	slip_ratio_rear = calculate.slip_ratio(wheel_rear_mps, WheelsRB[0], tire.radius)
	slip_ratio_front = calculate.slip_ratio(wheel_front_mps, WheelsRB[1], tire.radius)
	traction_control = calculate.traction_control(slip_ratio_rear)
	anti_braking_rear = calculate.anti_braking(slip_ratio_rear)
	anti_braking_front = calculate.anti_braking(slip_ratio_front)

	calculate.process_drag(ChassisRB, mps, chassis.drag_coefficiency, chassis.lon_aero_torque, chassis.lift, drive.AIR_DENSITY, magnitude)
	calculate.process_rolling_resistance(WheelsRB, tire.rolling_resistance, wheel_rear_angular_mps, wheel_front_angular_mps,chassis.mass)
	calculate.process_brakes(WheelsRB, engine.engine_brake_base, engine.engine_brake_peak, engine.engine_brake_exponent, wheel_rpm, engine.red_line_rpm, 
			engine.rpm_limit,engine.engine_brake_peak_rpm, brake, handbrake, chassis.brake_front, chassis.brake_rear, wheel_magnitude_front, wheel_magnitude_rear, gear_i, 
			transmission.gears, throttle, anti_braking_rear, anti_braking_front)
	calculate.process_weight_transfer(WheelsRB, acceleration, cL, hL, bL, drive.GRAVITY)
	calculate.process_friction(curve.slip_ratio_curve, slip_ratio_rear, slip_ratio_front, WheelsRB, tire.lon_friction)

	if wheel_rpm < engine.red_line_rpm + engine.rpm_limit:
		WheelsRB[0].apply_torque_impulse(calculate.drive_torque(torque_at, transmission.gears, gear_i, transmission.final_drive, tire.radius, throttle, traction_control))

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
	# Zero Power RPM
	curve.power_curve.add_point(Vector2(engine.zero_power_rpm, 0),
			0, ((0.0 - peakTorquePower) / (engine.zero_power_rpm - engine.peak_torque_rpm)))
	# Peak Power RPM
	curve.power_curve.add_point(Vector2(engine.peak_power_rpm, engine.peak_power * engine.upgrade * transmission.efficiency), 
			0, 0)
	# Red Line RPM
	curve.power_curve.add_point(Vector2(engine.red_line_rpm, (engine.peak_power * engine.red_line_power) * engine.upgrade * transmission.efficiency),
			0, 0)
	# Aux Line RPM
	curve.power_curve.add_point(Vector2(engine.aux_line_rpm, engine.peak_power * engine.red_line_power * engine.aux_line_power * engine.upgrade * transmission.efficiency),
			0, 0)


	## Torque Curve
	# Zero Power RPM
	curve.torque_curve.add_point(Vector2(engine.zero_power_rpm, 0),
			0, ((0.0 - peakTorquePower) / (engine.zero_power_rpm - engine.peak_torque_rpm)))
	# Peak Torque RPM
	curve.torque_curve.add_point(Vector2(engine.peak_torque_rpm, engine.peak_torque * engine.upgrade * transmission.efficiency),
			0, 0)
	# Red Line RPM
	curve.torque_curve.add_point(Vector2(engine.red_line_rpm, calculate.torque_at(engine.peak_power * engine.red_line_power, drive.MAGIC_CROSS_RPM, engine.red_line_rpm) * engine.upgrade * transmission.efficiency),
			0, 0)
	# Aux Line RPM
	curve.torque_curve.add_point(Vector2(engine.aux_line_rpm, engine.peak_torque * engine.red_line_power * engine.aux_line_power * engine.upgrade * transmission.efficiency),
			0, 0)

	print(int(engine.peak_power * 1.34102209 * engine.upgrade), " hp @ ", int(engine.peak_power_rpm))
	print(int(engine.peak_torque * engine.upgrade), " Nm @ ", int(engine.peak_torque_rpm))

	# slope 1 ((0.0 - peakTorquePower) / (engine.zero_power_rpm - engine.peak_torque_rpm))
	# slope 2 ((peakTorquePower - engine.peak_power) / (engine.peak_torque_rpm - engine.peak_power_rpm))
	# slope 3 ((engine.peak_power - (engine.peak_power * engine.red_line_power)) / (engine.peak_power_rpm - engine.red_line_rpm))
	# slope 4 ((engine.peak_power * engine.red_line_power - engine.aux_line_power) / (engine.red_line_rpm - engine.aux_line_rpm))

	print(curve.torque_curve.get_point_right_tangent(0))
	print(curve.torque_curve.get_point_left_tangent(1))
	print(curve.torque_curve.get_point_right_tangent(1))
	print(curve.torque_curve.get_point_left_tangent(2))
	print(curve.torque_curve.get_point_right_tangent(2))
	print(curve.torque_curve.get_point_left_tangent(3))

	#print(peakTorquePower)
	#print(peakPowerTorque)

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
