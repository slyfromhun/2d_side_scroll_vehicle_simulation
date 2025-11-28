extends CanvasLayer

@export var rpm_progress: TextureProgressBar
@export var rpm_limit_progress: TextureProgressBar
@export var rpm_needle: Control

var chassis: RigidBody2D
var camera: Camera2D
var rpm: float
var rpm_limit: float
var redline: float
var hudzoom: Vector2
var dyno_end = false


func _ready() -> void:
	chassis = get_tree().get_first_node_in_group("chassis")
	camera =  get_tree().get_first_node_in_group("camera")
	rpm_limit_progress.value = (8000.0 - chassis.engine.red_line_rpm)
	redline = chassis.engine.red_line_rpm

func _process(_delta: float) -> void:
	hudzoom = camera.zoom
	
	var tween := create_tween()
	var tween2 := create_tween()
	tween.tween_property(rpm_needle,"rotation_degrees",clampf((chassis.wheel_rpm / 8000.0) * 239, 0.0, 239.0), 0.066)
	tween2.tween_property(rpm_progress,"value",chassis.wheel_rpm, 0.066)

	rpm_limiter()
	hudshake()
	line()


func rpm_limiter():
	if chassis.wheel_rpm > redline + chassis.engine.rpm_limit * chassis.engine.red_line_power:
		$Tacho/AnimationPlayer.stop()
		rpm_progress.modulate = Color(1.0, 0.27, 0.27, 1.0)
	elif chassis.wheel_rpm > redline:
		$Tacho/AnimationPlayer.play("rpm_limiter")
	else:
		$Tacho/AnimationPlayer.stop()

func hudshake():
	var tween := create_tween()
	tween.tween_property($Tacho, "scale", hudzoom, 0.041)


func line():
	if dyno_end != true:
		if chassis.wheel_rpm > chassis.engine.rpm_limit + redline:
			dyno_end = true
		else:
			$Power.add_point(Vector2(chassis.wheel_rpm * 0.05, -chassis.curve.power_curve.sample(chassis.wheel_rpm)), 0)
			$Torque.add_point(Vector2(chassis.wheel_rpm * 0.05, -chassis.curve.torque_curve.sample(chassis.wheel_rpm)), 0)
		
