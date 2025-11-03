class_name Camera
extends Camera2D

@export var camera: CameraStats

var kph: float
var wheel_rpm: float
var red_line_rpm: float
var red_line_power: float
var rpm_limit: float
var top_gear_speed: float
var accel: float
var camZoom: float

var ChassisRB: RigidBody2D


func _ready() -> void:
	initalize()


func _process(_delta: float) -> void:
	kph = ChassisRB.kph
	wheel_rpm = ChassisRB.wheel_rpm
	accel = ChassisRB.acceleration
	top_gear_speed = ChassisRB.top_gear_speed

	var tween := create_tween()
	#var tween2 := create_tween()
	var tween3 := create_tween()
	var tween4 := create_tween()

	tween.tween_property(self, "offset", Vector2(0, camera.camshake(camera.offset_max, kph, top_gear_speed, camera.camera_shake)), 0.041)
	#tween2.tween_property(self, "offset", Vector2(camera.camoffset(accel), 0), 0.6)
	tween3.tween_property(self, "zoom", camera.camzoom(camera.zoom_max, wheel_rpm, red_line_rpm, camera.camera_zoom), 0.041)
	tween4.tween_property(self, "position_smoothing_speed", camera.camfollow(accel), 0.6)

func initalize():
	ChassisRB = get_tree().get_first_node_in_group("chassis")
	red_line_rpm = ChassisRB.engine.red_line_rpm
	red_line_power = ChassisRB.engine.red_line_power

	camera.camera_zoom.set_point_offset(0, red_line_power)
