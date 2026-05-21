class_name Camera
extends Camera2D

@export var camera: CameraStats


func _ready() -> void:
	initalize()

func _process(_delta: float) -> void:
	camShake()
	camOffset()
	camZoom()
	camFollow()

func initalize():
	camera.camera_zoom.set_point_offset(0, Global.ChassisRB.engine.red_line_power)


func camShake():
	var tween := create_tween()
	tween.tween_property(self, "offset", Vector2(0, camera.camshake(camera.offset_max, Global.ChassisRB.kph, Global.ChassisRB.top_power_speed, camera.camera_shake)), 0.041)

func camOffset():
	var tween := create_tween()
	tween.tween_property(self, "offset", Vector2(camera.camoffset(Global.ChassisRB.acceleration), 0), 2.6)

func camZoom():
	var tween := create_tween()
	tween.tween_property(self, "zoom", camera.camzoom(camera.zoom_max, Global.ChassisRB.wheel_rpm, Global.ChassisRB.engine.red_line_rpm, camera.camera_zoom), 0.041)

func camFollow():
	var tween := create_tween()
	tween.tween_property(self, "position_smoothing_speed", camera.camfollow(Global.ChassisRB.acceleration), 0.6)
