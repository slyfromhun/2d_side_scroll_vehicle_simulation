class_name HudFunctions
extends Resource

@export var _rpmLimiter := true
@export var _dyno := true
@export var _odoHud := true
@export var _gearHud := true
@export var _speedHud :=true

func rpmLimiter(wheel_rpm:float, redline_rpm:float, true_redline_rpm:float, animation_player:AnimationPlayer, animation_name:String, progress_bar:TextureProgressBar, color:Color) -> void:
	if _rpmLimiter:
		if wheel_rpm > true_redline_rpm * 1.02:
			animation_player.stop()
			progress_bar.modulate = color
		elif wheel_rpm > redline_rpm:
			animation_player.play(animation_name)
		else:
			animation_player.stop()

func dyno(max_rpm:float, power_line:Line2D, torque_line:Line2D, power_curve:Curve, torque_curve:Curve) -> void:
	if _dyno:
		for i in max_rpm:
			power_line.add_point(Vector2(i * 0.05, -power_curve.sample(i) * 1.34102209), 0)
			torque_line.add_point(Vector2(i * 0.05, -torque_curve.sample(i)), 0)

func odoHud(label:RichTextLabel, distance_travelled:float) -> void:
	if _odoHud:
		distance_travelled *= 0.0001
		label.text = "%07d" % distance_travelled
		var last_char = "[color=orange]%s[/color]" % label.text[-1]
		label.text[-1] = ""
		label.text += last_char

func gearHud(label:RichTextLabel, gears:Array, gear_i:int) -> void:
	if _gearHud:
		label.text = str(gears[gear_i])

func speedHud(label:RichTextLabel, kph:float) -> void:
	if _speedHud:
		label.text = str("%d\n[i]km/h[/i]" % kph)