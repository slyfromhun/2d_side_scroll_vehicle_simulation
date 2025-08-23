class_name TransmissionStats
extends Resource

## Set of Gears. Including Neutral. Reverse is -n.
@export var gears := [-2.78, 0, 2.78, 1.93, 1.36, 1.0]
## Rear axle ratio.
@export var final_drive := 3.2
## Transmission Efficiency.
@export_range(0.0, 1.0, 0.01, "suffix:x") var efficiency := 1.0
