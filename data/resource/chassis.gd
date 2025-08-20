class_name ChassisStats
extends Resource

@export_range(0.0, 10000.0, 0.01, "suffix:Kg") var mass := 1261.0
@export_range(0.0, 1.0, 0.01, "suffix:Cd") var drag_coefficiency := 0.48
@export_range(0.0, 5.0, 0.01, "suffix:x") var lon_aero_torque := 1.5
@export_range(0.0, 10.0, 0.01, "suffix:m^2") var frontal_area := 2.14
@export_range(0.0, 1000.0, 0.01, "suffix:cm") var lenght := 463.0
@export_range(0.0, 1000.0, 0.01, "suffix:cm") var height := 118.0
@export_range(0.0, 5000.0, 0.01, "suffix:Nm") var brake_front := 2800.0
@export_range(0.0, 5000.0, 0.01, "suffix:Nm") var brake_rear := 1700.0
@export_range(1.0, 4.0, 0.01, "suffix:x") var handbrake_power := 2.0