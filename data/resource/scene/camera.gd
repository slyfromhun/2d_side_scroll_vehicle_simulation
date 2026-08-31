## Camera Properties and Functions of the Vehicle Camera
class_name CameraStats
extends Resource

@export_group("Shake")
@export var _shake := true
@export var camera_shake: Curve
@export_group("Zoom")
@export var _zoom := true
@export var camera_zoom: Curve
@export var zoom_max := 0.016
@export_group("Offset")
@export var _offset := true
@export var offset_max := 6.0
@export_group("Follow")
@export var _follow := true
@export var camera_follow := 36.0

## Shakes the Camera on the Y axis giving a false sense of speed on the car
func camshake(offset:float, kph:float, top_power_speed:float, shake_curve:Curve) -> float:
	if _shake:
		return randf_range(-offset, offset) * shake_curve.sample(kph / top_power_speed)
	else:
		return 0.0

## Zooms in and out of the scene when nearing redline rpm
func camzoom(zoom:float, wheel_rpm:float, red_line_rpm:float, zoom_curve:Curve) -> Vector2:
	if _zoom:
		var camZoom = 1 + randf_range(-zoom, zoom) * zoom_curve.sample(wheel_rpm / (red_line_rpm))
		return Vector2(camZoom, camZoom)
	else:
		return Vector2.ZERO

## Offsets the Camera based on acceleration
func camoffset(accel:float) -> float:
	if _offset:
		return 36.0 * -accel
	else:
		return 0.0

## Changes the Camera position smoothing speed based on acceleration
func camfollow(accel:float) -> float:
	if _follow:
		return clampf(36.0 - accel * 3.6, 4.0, 36.0)
	else:
		return 0.0
