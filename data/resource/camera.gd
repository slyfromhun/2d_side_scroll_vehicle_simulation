class_name CameraStats
extends Resource

@export var camera_shake: Curve
@export var camera_zoom: Curve
@export var camera_follow := 36.0
@export var offset_max := 4.0
@export var zoom_max := 0.016

func camshake(offset:float, kph:float, top_gear_speed:float, shake_curve:Curve) -> float:
	return randf_range(-offset, offset) * shake_curve.sample(kph / top_gear_speed)

func camzoom(zoom:float, wheel_rpm:float, red_line_rpm:float, zoom_curve:Curve) -> Vector2:
	var camZoom = 1 + randf_range(-zoom, zoom) * zoom_curve.sample(wheel_rpm / (red_line_rpm))
	return Vector2(camZoom, camZoom)

func camoffset(accel:float) -> float:
	return 36.0 * -accel


func camfollow(accel:float) -> float:
	return 36.0 - accel * 3.6