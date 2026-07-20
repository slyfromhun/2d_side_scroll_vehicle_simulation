## Properties of the Chassis
class_name ChassisStats
extends Resource

## This determines how much the chassis weights in kilograms (Kg).
@export_range(0.0, 10000.0, 0.01, "suffix:Kg") var mass := 1080.0
## Drag coefficient, the bigger the number, the higher the drag gets when the vehicle moves.
@export_range(0.0, 1.0, 0.01, "suffix:Cd") var drag_coefficiency := 0.48
## Multiplier for the drag on the longitudinal (X) axis.
@export_range(0.0, 5.0, 0.01, "suffix:x") var lon_aero_torque := 1.0
## Frontal area of the vehicle
@export_range(0.0, 10.0, 0.01, "suffix:m^2") var frontal_area := 2.14
## Lift coefficient, positive value is down force and negative value is lift force.
@export_range(-1.0, 1.0, 0.01, "suffix:x") var lift := -0.03
## This determines how long the chassis is in cm.
@export_range(0.0, 1000.0, 0.01, "suffix:cm") var lenght := 463.0
## This determines how tall the chassis is in cm.
@export_range(0.0, 1000.0, 0.01, "suffix:cm") var height := 118.0
