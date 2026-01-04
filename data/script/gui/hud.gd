extends CanvasLayer


@export_group("Tacho")
@export var tacho: Control
@export var rpm_progress: TextureProgressBar
@export var rpm_redline_progress: TextureProgressBar
@export var rpm_limit_progress: TextureProgressBar
@export var rpm_needle: Control
@export var rpm_limit_anim: AnimationPlayer
@export_group("Tacho Numbers")
@export var odo_meter: RichTextLabel
@export var gear: RichTextLabel
@export var speed: RichTextLabel

var chassis: RigidBody2D
var camera: Camera2D
var rpm: float
var rpm_limit: float
var true_redline: float
var redline: float
var hudzoom: Vector2
var dyno_end = false
var gears := ["R", "N", "1", "2", "3", "4", "5", "6", "7", "8", "9"]


func _ready() -> void:
	chassis = get_tree().get_first_node_in_group("chassis")
	camera =  get_tree().get_first_node_in_group("camera")
	true_redline = chassis.engine.red_line_rpm + chassis.engine.rpm_limit
	redline = chassis.engine.red_line_rpm
	rpm_limit_progress.value = (8000.0 - true_redline)
	rpm_redline_progress.value = (8000.0 - redline)

func _process(_delta: float) -> void:
	hudzoom = camera.zoom
	
	var tween := create_tween()
	var tween2 := create_tween()
	tween.tween_property(rpm_needle,"rotation_degrees",clampf((chassis.wheel_rpm / 8000.0) * 239, 0.0, 239.0), 0.066)
	tween2.tween_property(rpm_progress,"value",chassis.wheel_rpm, 0.066)

	odo_meter_hud(chassis.global_position.x * 0.0001)
	gear_hud(chassis.input_gear_i)
	speed_hud(chassis.kph)


	rpm_limiter()
	hudshake()
	torque_curve()

func rpm_limiter():
	if chassis.wheel_rpm > true_redline * 1.02:
		rpm_limit_anim.stop()
		rpm_progress.modulate = Color(1.0, 0.27, 0.27, 1.0)
	elif chassis.wheel_rpm > redline:
		rpm_limit_anim.play("rpm_limiter")
	else:
		rpm_limit_anim.stop()

func hudshake():
	var tween := create_tween()
	tween.tween_property(tacho, "scale", hudzoom, 0.041)

func torque_curve():
	if dyno_end != true:
		if chassis.wheel_rpm > true_redline:
			dyno_end = true
		else:
			$Power.add_point(Vector2(chassis.wheel_rpm * 0.05, -chassis.curve.power_curve.sample(chassis.wheel_rpm) * 1.34102209), 0)
			$Torque.add_point(Vector2(chassis.wheel_rpm * 0.05, -chassis.curve.torque_curve.sample(chassis.wheel_rpm)), 0)
		
func odo_meter_hud(position):
	odo_meter.text = "%07d" % position
	var last_char = "[color=orange]%s[/color]" % odo_meter.text[-1]
	odo_meter.text[-1] = ""
	odo_meter.text += last_char

func gear_hud(gear_i):
	gear.text = str(gears[gear_i])

func speed_hud(kph):
	speed.text = str("%d\n[i]km/h[/i]" % kph)
