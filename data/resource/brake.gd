class_name BrakeStats
extends Resource

## This determines the power of the front brake.
@export_range(0.0, 5000.0, 0.01, "suffix:Nm") var brake_front := 2800.0
## This determines the power of the rear brake.
@export_range(0.0, 5000.0, 0.01, "suffix:Nm") var brake_rear := 1200.0
## Adjust the rear/front brake balance
@export_range(0.0, 1.0, 0.01) var brake_balance := 0.5
## This determines the power of the handbrake on the rear brake.
@export_range(-4.0, 4.0, 0.01, "suffix:x") var handbrake_power := 2.0
