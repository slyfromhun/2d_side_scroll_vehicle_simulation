class_name Vehicle_Effects
extends Node

@export var effect : VehicleEffects
@export var frictionScenes: Array[GPUParticles2D]
@export var slipScenes: Array[GPUParticles2D]
@export var grindScenes: Array[GPUParticles2D]
@export var chassisScenes: Array[GPUParticles2D]

var wheelCol: Node
var wheelRB: Node
var chassis: Node

var slip_ratio_rear: float
var speed_kph: float
var wheel_magnitude: float
var angular_speed_kph: float

func _ready() -> void:
	initalize()

func _physics_process(_delta: float) -> void:
	slip_ratio_rear = abs(chassis.slip_ratio_rear)
	speed_kph = abs(chassis.kph)
	angular_speed_kph = abs(chassis.wheel_angular_kph)
	wheel_magnitude = chassis.wheel_magnitude_rear

func _process(_delta: float) -> void:
	effect.friction(angular_speed_kph, frictionScenes, wheel_magnitude, slip_ratio_rear)
	effect.slip(angular_speed_kph, slipScenes, wheel_magnitude, slip_ratio_rear)
	effect.grind(angular_speed_kph, grindScenes, wheel_magnitude, slip_ratio_rear)
	effect.dust(speed_kph, chassisScenes)

func initalize():
	wheelCol = get_tree().get_first_node_in_group("wheels_coll")
	wheelRB = get_tree().get_first_node_in_group("wheels")
	chassis = get_tree().get_first_node_in_group("chassis")
	###
	for scene in frictionScenes:
		scene.global_position = wheelCol.global_position
	for scene in slipScenes:
		scene.global_position = wheelCol.global_position
	for scene in grindScenes:
		scene.global_position = wheelCol.global_position + Vector2(0, chassis.tire.radius)
	for scene in chassisScenes:
		scene.global_position = chassis.global_position
	###
	effect.dust_color_power.set_point_offset(0, effect.speed_dust[0])
