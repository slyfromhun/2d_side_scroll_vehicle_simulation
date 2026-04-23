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

var chassis: RigidBody2D
var camera: Camera2D
var rpm: float
var rpm_limit: float
var true_red_line: float
var red_line: float
var gears := ['R', 'N', '1', '2', '3', '4', '5', '6', '7', '8', '9']


func _ready() -> void:
	initalize()

func _process(_delta: float) -> void:
	hudShake(tacho, camera.zoom)

	rpmProgress()
	calculate.rpmLimiter(chassis.wheel_rpm, red_line, true_red_line, rpm_limit_anim, "rpm_limiter", rpm_progress, Color(1.0, 0.275, 0.275))
	calculate.odoHud(odo_meter, chassis.distance_overall)
	calculate.gearHud(gear, gears, chassis.input_gear_i)
	calculate.speedHud(speed, chassis.kph)

	curve_needle.position.x = power_line.position.x + (chassis.wheel_rpm * 0.05)

func initalize():
	chassis = get_tree().get_first_node_in_group("chassis")
	camera =  get_tree().get_first_node_in_group("camera")
	true_red_line = chassis.engine.red_line_rpm + chassis.engine.rpm_limit
	red_line = chassis.engine.red_line_rpm
	rpm_limit_progress.value = (8000.0 - true_red_line)
	rpm_red_line_progress.value = (8000.0 - red_line)

	calculate.dyno(chassis.engine.aux_line_rpm, power_line, torque_line, chassis.curve.power_curve, chassis.curve.torque_curve)


func rpmProgress():
	var tween := create_tween()
	var tween2 := create_tween()
	tween.tween_property(rpm_needle,"rotation_degrees",clampf((chassis.wheel_rpm / 8000.0) * 239, 0.0, 239.0), 0.066)
	tween2.tween_property(rpm_progress,"value",chassis.wheel_rpm, 0.066)

func hudShake(control:Control, zoom:Vector2):
	var tween := create_tween()
	tween.tween_property(control, "scale", zoom, 0.041)
