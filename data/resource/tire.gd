class_name TireStats
extends Resource

## This determines the radius of the wheel in cm.
@export_range(1.0, 99, 0.01, "suffix:cm") var radius := 30.8
## Rolling Resistance coefficient, the bigger the number, the higher the resistance gets when the vehicle moves.
@export_range(0.013, 0.039, 0.0001, "suffix:Crr") var rolling_resistance := 0.015
## Static longitudinal friction.
@export_range(0.1, 2.0, 0.01, "suffix:Cf") var lon_friction := 1.46