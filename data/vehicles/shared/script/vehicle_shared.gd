class_name Vehicle
extends RigidBody2D

@export var curve: Curves
@export var engine: EngineStats
@export var transmission: TransmissionStats
@export var chassis: ChassisStats
@export var tire: TireStats
@export var calculate: Functions

const gravity = 9.807
const air_density = 1.225
const magic_cross_rpm = 9549

var peakTorquePower: float
var peakPowerTorque: float

var chassisRB: RigidBody2D
var wheelsRB: Array[Node]
var wheelsColl: Array[Node]
var chassisColl: CollisionShape2D

var gear_i := 1
var throttle: float
var brake: float
var handbrake: float

var drag: float
var rr: float

var kph: float
var mps: float
var acceleration: float
var magnitude: float
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
	$Label.text = "Speed: %.fkph %.fmph\nAccel: %f\nRPM: %.f\nGear: %.f\nPower: %.fkW\nTorque: %.fNm\nSlip Ratio: %f\nFriction: %f\nTraction Control: %f\nDrag: %f\nRolling Resistance: %f\nEngine Brake: %f" % [kph, kph * 0.621371,acceleration, wheel_rpm, gear_i - 1, curve.power_curve.sample(wheel_rpm), curve.torque_curve.sample(wheel_rpm), slip_ratio_rear, wheelsRB[0].physics_material_override.friction, traction_control, chassisRB.constant_force.x, wheelsRB[0].constant_force.x, wheelsRB[0].constant_torque]
	$Label2.text = "Wr: %f  Wf: %f\n Pos: %f\nthrottle: %f\nbrake: %f\nhandbrake: %f" % [wheelsRB[0].mass, wheelsRB[1].mass, chassisRB.position.x * 0.01, throttle, brake, handbrake]

func _physics_process(delta: float) -> void:
	kph = calculate.kph(chassisRB)
	mps = calculate.mps(chassisRB)
	acceleration = calculate.acceleration(delta, mps)
	magnitude = calculate.magnitude(kph)
	wheel_magnitude_rear = calculate.wheel_magnitude(wheelsRB[0])
	wheel_magnitude_front = calculate.wheel_magnitude(wheelsRB[1])
	wheel_rpm = calculate.rpm(wheelsRB[0], transmission.gears, gear_i, transmission.final_drive, engine.idle_rpm, throttle, engine.auto_clutch_rpm)
	torque_at = calculate.torque_at_rpm(curve.power_curve, curve.torque_curve, wheel_rpm)
	slip_ratio_rear = calculate.slip_ratio(mps, wheelsRB[0], tire.radius)
	slip_ratio_front = calculate.slip_ratio(mps, wheelsRB[1], tire.radius)
	traction_control = calculate.traction_control(slip_ratio_rear)
	anti_braking_rear = calculate.anti_braking(slip_ratio_rear)
	anti_braking_front = calculate.anti_braking(slip_ratio_front)

	calculate.process_drag(chassisRB, kph, chassis.drag_coefficiency, chassis.frontal_area, air_density, gravity, magnitude)
	calculate.process_rolling_resistance(wheelsRB, tire.rollingResistance, kph, gravity, chassis.mass)
	calculate.process_brakes(wheelsRB, engine.engine_brake_base, engine.engine_brake_peak, engine.engine_brake_exponent, engine.inertia, wheel_rpm, engine.redline_rpm, engine.rpm_limit,engine.engine_brake_peak_rpm, brake, handbrake, chassis.brake_front, chassis.brake_rear, wheel_magnitude_front, wheel_magnitude_rear, gear_i, transmission.gears, throttle, anti_braking_rear, anti_braking_front)
	calculate.process_weight_transfer(wheelsRB, acceleration, cL, hL, bL, gravity)
	calculate.process_friction(curve.slip_ratio_curve, slip_ratio_rear, slip_ratio_front, wheelsRB, tire.lon_friction)

	if wheel_rpm < engine.redline_rpm + engine.rpm_limit:
		wheelsRB[0].apply_torque_impulse(calculate.drive_torque(torque_at, transmission.gears, gear_i, transmission.final_drive, tire.radius, throttle, traction_control))

func initalize():
	chassisRB = get_tree().get_first_node_in_group("chassis")
	wheelsRB = get_tree().get_nodes_in_group("wheels")
	wheelsColl = get_tree().get_nodes_in_group("wheels_coll")
	chassisColl = get_tree().get_first_node_in_group("chassis_coll")

	### set curves
	curve.power_curve.max_domain = 20000.0
	curve.power_curve.max_value = engine.peak_power * engine.upgrade
	
	curve.torque_curve.max_domain = 20000.0
	curve.torque_curve.max_value = engine.peak_torque * engine.upgrade
	
	curve.power_curve.set_point_offset(0, engine.zero_power_rpm)
	curve.power_curve.set_point_value(0, 0)
	curve.power_curve.set_point_offset(1, engine.peak_power_rpm)
	curve.power_curve.set_point_value(1, engine.peak_power * engine.upgrade * transmission.efficiency)
	curve.power_curve.set_point_offset(2, engine.redline_rpm)
	curve.power_curve.set_point_value(2, engine.peak_power * engine.redline_power * engine.upgrade * transmission.efficiency)
	curve.power_curve.set_point_offset(3, engine.aux_line_rpm)
	curve.power_curve.set_point_value(3, engine.peak_power * engine.aux_line_power * engine.upgrade * transmission.efficiency)
	
	curve.torque_curve.set_point_offset(0, engine.zero_power_rpm)
	curve.torque_curve.set_point_value(0, 0)
	curve.torque_curve.set_point_offset(1, engine.peak_torque_rpm)
	curve.torque_curve.set_point_value(1, engine.peak_torque * engine.upgrade * transmission.efficiency)
	curve.torque_curve.set_point_offset(2, engine.redline_rpm)
	curve.torque_curve.set_point_value(2, engine.peak_torque * engine.redline_power * engine.upgrade * transmission.efficiency)
	curve.torque_curve.set_point_offset(3, engine.aux_line_rpm)
	curve.torque_curve.set_point_value(3, engine.peak_torque * engine.aux_line_power * engine.upgrade * transmission.efficiency)
	
	peakTorquePower = engine.peak_torque * engine.peak_torque_rpm / magic_cross_rpm
	peakPowerTorque = engine.peak_power * magic_cross_rpm / engine.peak_power_rpm

	curve.power_curve.set_point_right_tangent(0, (0.0 - peakTorquePower) / (engine.zero_power_rpm - engine.peak_torque_rpm))
	curve.power_curve.set_point_right_tangent(1, (peakTorquePower - engine.peak_power) / (engine.peak_torque_rpm - engine.peak_power_rpm))
	curve.power_curve.set_point_right_tangent(2, (engine.peak_power - (engine.peak_power * engine.redline_power)) / (engine.peak_power_rpm - engine.redline_rpm))
	curve.power_curve.set_point_left_tangent(2, (engine.peak_power - (engine.peak_power * engine.redline_power)) / (engine.peak_power_rpm - engine.redline_rpm))
	curve.power_curve.set_point_left_tangent(3, (engine.redline_power - engine.aux_line_power) / (engine.redline_rpm - engine.aux_line_rpm))

	curve.torque_curve.set_point_right_tangent(0, (0.0 - peakTorquePower) / (engine.zero_power_rpm - engine.peak_torque_rpm))
	curve.torque_curve.set_point_right_tangent(1, (peakTorquePower - engine.peak_power) / (engine.peak_torque_rpm - engine.peak_power_rpm))
	curve.torque_curve.set_point_right_tangent(2, (engine.peak_power - (engine.peak_power * engine.redline_power)) / (engine.peak_power_rpm - engine.redline_rpm))
	curve.torque_curve.set_point_left_tangent(2, (engine.peak_power - (engine.peak_power * engine.redline_power)) / (engine.peak_power_rpm - engine.redline_rpm))
	curve.torque_curve.set_point_left_tangent(3, (engine.redline_power - engine.aux_line_power) / (engine.redline_rpm - engine.aux_line_rpm))

#	print(curve.torque_curve.get_point_right_tangent(0))
#	print(curve.torque_curve.get_point_right_tangent(1))
#	print(curve.torque_curve.get_point_right_tangent(2))
#	print(curve.torque_curve.get_point_left_tangent(2))
#	print(curve.torque_curve.get_point_left_tangent(3))

#	curve.power_curve.set_point_value(0, curve.power_curve.sample(engine.idle_rpm) * transmission.efficiency)
#	curve.torque_curve.set_point_value(0, curve.torque_curve.sample(engine.idle_rpm) * transmission.efficiency)

	### set collision dimensions and friction
	chassisColl.shape.size = Vector2(chassis.lenght, chassis.height)
	for coll in wheelsColl:
		coll.shape.radius = tire.radius
	for rb in wheelsRB:
		rb.physics_material_override.friction = tire.lon_friction
		
	### weight transfer
	c = abs(wheelsRB[0].global_position.x - chassisColl.global_position.x) * 0.01
	b = abs(wheelsRB[1].global_position.x - chassisColl.global_position.x) * 0.01
	L = c + b
	CGh = abs(chassisColl.global_position.y - wheelsRB[0].global_position.y - tire.radius) * 0.01
	bL = b / L
	hL = CGh / L
	cL = c / L
