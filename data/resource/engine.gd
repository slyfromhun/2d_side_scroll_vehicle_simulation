class_name EngineStats
extends Resource

@export var name := "200 I6"
@export var manufacturer := "Rocket"
## In rounds per minute (RPM). This should always be higher than Peak Torque RPM.
@export_range(400.0, 10000.0, 0.01, "suffix:RPM") var peak_power_rpm := 3800.0
## In kilo Watts (kW). This value should always be less than Peak Torque.
@export_range(0.0, 500.0, 0.01, "suffix:kW") var peak_power := 86.0
## In rounds per minute (RPM). This should always be the first one after the Zero Power RPM. 
@export_range(400.0, 10000.0, 0.01, "suffix:RPM") var peak_torque_rpm := 2200.0
## In Newton meters (Nm). This value should always be more than Peak Power. 
@export_range(0.0, 1000.0, 0.01, "suffix:Nm") var peak_torque := 258.0
## In rounds per minute (RPM). This should always be more than the Peak Power Rpm. 
@export_range(400.0, 10000.0, 0.01, "suffix:RPM") var redline_rpm := 5200.0
## This is a multiplier. It multiplies the Peak Power and makes it Red Line Power. It's recommended this being equal or less than 1. 
@export_range(0.0, 1.0, 0.01, "suffix:x") var redline_power := 0.94
## In rounds per minute (RPM). This should always be more than the RPM Limit.
@export_range(400.0, 20000.0, 0.01, "suffix:RPM") var aux_line_rpm := 7150.0
## This is a multiplier. It multiplies the Peak Power RPM and makes it Aux Line Power. It's recommended this being equal or less than 1. Often you see it as a 0.
@export_range(0.0, 1.0, 0.01, "suffix:x") var aux_line_power := 0.0
## In rounds per minute (RPM). Thi is the true redline (redline_rpm + rpm_limit)
@export_range(100.0, 10000.0, 0.01, "suffix:RPM") var rpm_limit := 600.0
## In rounds per minute (RPM). At what RPM the engine is idling.
@export_range(400.0, 10000.0, 0.01, "suffix:RPM") var idle_rpm := 800.0
## In rounds per minute (RPM). This is where the engine curve starts.
@export_range(0.0, 10000.0, 0.01, "suffix:RPM") var zero_power_rpm := 0.0
## Engine Brake In Newton meters (Nm)
@export_range(0.0, 500.0, 0.01, "suffix:Nm") var engine_brake_base := 50.04
## Engine Brake In Newton meters (Nm)
@export_range(0.0, 500.0, 0.01, "suffix:Nm") var engine_brake_peak := 104.92
## Engine Brake Exponent
@export_range(0.0, 2.0, 0.01, "suffix:x") var engine_brake_exponent := 1.5
## RPM point for Engine Brake Peak.
@export_range(400.0, 10000.0, 0.01, "suffix:RPM") var engine_brake_peak_rpm := 5200.0
#@export_range(0.0, 1.0, 0.01, "suffix:J") var inertia := 0.3
## Target RPM when taking off from standstill
@export_range(0.0, 10000.0, 1.0, "suffix:RPM") var auto_clutch_rpm := 1300.0
## Power and Torque curve multiplier
@export_range(0.1, 1.75, 0.01, "suffix:x") var upgrade := 1.0
