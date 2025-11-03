class_name TireStats
extends Resource

## This determines the radius of the wheel in cm.
@export_range(1.0, 99, 0.01, "suffix:cm") var radius := 30.5
## Rolling Resistance coefficient, the bigger the number, the higher the resistance gets when the vehicle moves.
@export_range(0.008, 0.039, 0.0001, "suffix:Crr") var rolling_resistance := 0.013
## Static and Slip longitudinal friction.
@export var lon_friction := [1.46, 1.06]
## Friction Static Peak Grip
@export_range(0.01, 100.0, 0.01, "suffix:%") var peak_friction_grip := 10.0
## Friciton Slide Low Peak Grip
@export_range(0.01, 100.0, 0.01, "suffix:%") var slide_friciton_grip := 100.0
## Friction multiplier curve depending on tire load.
@export var lon_load_sensitivity := [-0.1, 10300]