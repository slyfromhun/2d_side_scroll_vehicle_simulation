extends CanvasLayer

@export var rpm_progress: TextureProgressBar
@export var rpm_limit_progress: TextureProgressBar
@export var rpm_needle: Control

var chassis: RigidBody2D
var rpm: float
var rpm_limit: float
var redline: float


func _ready() -> void:
	chassis = get_tree().get_first_node_in_group("chassis")
	rpm_limit_progress.value = (8000.0 - chassis.engine.redline_rpm)
	redline = chassis.engine.redline_rpm

func _process(_delta: float) -> void:
	var tween = get_tree().create_tween()
	var tween2 = get_tree().create_tween()
	
	tween.tween_property(rpm_needle,"rotation_degrees",clampf((chassis.wheel_rpm / 8000.0) * 239, 0.0, 239.0), 0.14)
	tween2.tween_property(rpm_progress,"value",chassis.wheel_rpm, 0.14)

	rpm_limiter()


func rpm_limiter():
	if chassis.wheel_rpm > redline + chassis.engine.rpm_limit * chassis.engine.redline_power:
		$Tacho/AnimationPlayer.stop()
		rpm_progress.modulate = Color(1.0, 0.27, 0.27, 1.0)
	elif chassis.wheel_rpm > redline:
		$Tacho/AnimationPlayer.play("rpm_limiter")
	else:
		$Tacho/AnimationPlayer.stop()
