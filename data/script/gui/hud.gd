extends CanvasLayer


@export var calculate: HudFunctions
@export_group("Tacho")
@export var tacho: Control
@export var rpm_progress: TextureProgressBar
@export var rpm_red_line_progress: TextureProgressBar
@export var rpm_limit_progress: TextureProgressBar
@export var rpm_needle: Control
@export var rpm_limit_anim: AnimationPlayer
@export_group("Tacho Numbers")
@export var odo_meter: RichTextLabel
@export var gear: RichTextLabel
@export var speed: RichTextLabel
@export_group("debug")
@export var curve_needle: Sprite2D
@export var power_line: Line2D
@export var torque_line: Line2D

var gears := ['R', 'N', '1', '2', '3', '4', '5', '6', '7', '8', '9']

var dynoDone := true


func _ready() -> void:
	initalize()

func _process(_delta: float) -> void:
	hudShake(tacho, Global.CameraChassis.zoom)

	rpmProgress()
	calculate.rpmLimiter(Global.ChassisRB.wheel_rpm, Global.ChassisRB.engine.red_line_rpm, Global.ChassisRB.engine.red_line_rpm + Global.ChassisRB.engine.rpm_limit, rpm_limit_anim, "rpm_limiter", rpm_progress, Color(1.0, 0.275, 0.275))
	calculate.odoHud(odo_meter, Global.ChassisRB.distance_overall)
	calculate.gearHud(gear, gears, Global.ChassisRB.input_gear_i)
	calculate.speedHud(speed, Global.ChassisRB.kph)

	curve_needle.position.x = power_line.position.x + (Global.ChassisRB.wheel_rpm * 0.05)

	$Label3.text = "fps: %s" % [Engine.get_frames_per_second()]

	if Engine.get_process_frames() % Global.Priority.MEDIUM == 0:
		$Label.text = "Power Distribution: %s\nSpeed: %.1fkph %.1fmph %.1fmps\nAccel: %.3f\nTire Angular Velocity: %.1fkph\nRPM: %.1f\nGear: %.f\nPower: %.1fkW\nTorque: %.1fNm\nDrive Force: %.1fNm\nEngine Brake Force: %.1fNm\nBrake Force: %sNm\nSlip Ratio: %.3f\nLoad Sensitivity: %.3f\nFriction: %.3f\nDrag: %vN\nRolling Resistance: %sN\n" % [Global.ChassisRB.transmission.power_distribution, Global.ChassisRB.kph, Global.ChassisRB.kph * 0.621371, Global.ChassisRB.mps, Global.ChassisRB.acceleration, Global.ChassisRB.calculate.angular_kph(Global.WheelsRB[Global.ChassisRB.transmission.power_distribution], Global.ChassisRB.tire.radius), Global.ChassisRB.wheel_rpm, Global.ChassisRB.input_gear_i - 1, Global.ChassisRB.curve.power_curve.sample(Global.ChassisRB.wheel_rpm), Global.ChassisRB.curve.torque_curve.sample(Global.ChassisRB.wheel_rpm), Global.ChassisRB.drive_force, Global.ChassisRB.engine_brake_force, [int(Global.ChassisRB.brake_force[0] * Global.ChassisRB.anti_brakings[0]), int(Global.ChassisRB.brake_force[1] * Global.ChassisRB.anti_brakings[1])], Global.ChassisRB.slip_ratios[Global.ChassisRB.transmission.power_distribution], Global.ChassisRB.load_sensitivities[Global.ChassisRB.transmission.power_distribution], Global.WheelsRB[Global.ChassisRB.transmission.power_distribution].physics_material_override.friction, Global.ChassisRB.drag_force, [int(Global.ChassisRB.rolling_resistances[0]), int(Global.ChassisRB.rolling_resistances[1])]]
		$Label2.text = "Weight Transfer: %.1f kg, %.1f kg\nGlobal Pos: %.3f\nPos: %.3f\nDistance: %.3f m\nthrottle: %.1f\nbrake: %.1f\nhandbrake: %.f" % [Global.ChassisRB.wheel_weight[0], Global.ChassisRB.wheel_weight[1], Global.ChassisRB.global_position.x, Global.ChassisRB.position.x, Global.ChassisRB.distance_overall * 0.01, Global.ChassisRB.input_throttle * Global.ChassisRB.traction_control, Global.ChassisRB.input_brake, Global.ChassisRB.input_handbrake]

func initalize():
	rpm_limit_progress.value = (8000.0 - (Global.ChassisRB.engine.red_line_rpm + Global.ChassisRB.engine.rpm_limit))
	rpm_red_line_progress.value = (8000.0 - Global.ChassisRB.engine.red_line_rpm)

func rpmProgress():
	var tween := create_tween()
	var tween2 := create_tween()
	tween.tween_property(rpm_needle, "rotation_degrees", clampf((Global.ChassisRB.wheel_rpm / 8000.0) * 239, 0.0, 239.0), 0.066)
	tween2.tween_property(rpm_progress, "value", Global.ChassisRB.wheel_rpm, 0.066)

func hudShake(control:Control, zoom:Vector2):
	var tween := create_tween()
	tween.tween_property(control, "scale", zoom, 0.041)

func dyno():
	calculate.dyno(Global.ChassisRB.engine.aux_line_rpm, power_line, torque_line, Global.ChassisRB.curve.power_curve, Global.ChassisRB.curve.torque_curve)