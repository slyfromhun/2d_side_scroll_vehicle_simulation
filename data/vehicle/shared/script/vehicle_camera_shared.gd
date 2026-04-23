class_name Camera
extends Camera2D

@export var camera: CameraStats

var kph: float
var wheel_rpm: float
var red_line_rpm: float
var red_line_power: float
var top_power_speed: float
var accel: float

var ChassisRB: RigidBody2D


func _ready() -> void:
	initalize()

func _process(_delta: float) -> void:
	kph = ChassisRB.kph
	wheel_rpm = ChassisRB.wheel_rpm
	accel = ChassisRB.acceleration
	top_power_speed = ChassisRB.top_power_speed

	camShake()
	camOffset()
	camZoom()
	camFollow()

func initalize():
	ChassisRB = get_tree().get_first_node_in_group("chassis")
	red_line_rpm = ChassisRB.engine.red_line_rpm
	red_line_power = ChassisRB.engine.red_line_power

	camera.camera_zoom.set_point_offset(0, red_line_power)


func camShake():
	var tween := create_tween()
	tween.tween_property(self, "offset", Vector2(0, camera.camshake(camera.offset_max, kph, top_power_speed, camera.camera_shake)), 0.041)

func camOffset():
	var tween := create_tween()
	tween.tween_property(self, "offset", Vector2(camera.camoffset(accel), 0), 2.6)

func camZoom():
	var tween := create_tween()
	tween.tween_property(self, "zoom", camera.camzoom(camera.zoom_max, wheel_rpm, red_line_rpm, camera.camera_zoom), 0.041)

func camFollow():
	var tween := create_tween()
	tween.tween_property(self, "position_smoothing_speed", camera.camfollow(accel), 0.6)