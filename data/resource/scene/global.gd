## Autoloaded Script for global variables
extends Node

## Update Priority to lighten loads on certain functions
enum Priority {REALTIME = 1, HIGH = 2, MEDIUM = 4, LOW = 8, VERYLOW = 16}

## Gravity used in calculations
const GRAVITY = 9.807
## Air Density used in calculations
const AIR_DENSITY = 1.225
## Magic Cross RPM used in engine curve calculations (DO NOT CHANGE)
const MAGIC_CROSS_RPM = 9549
## Multiplier to convert kW to hp
const HORSEPOWER = 1.34102209

## Rigidbody of the Vehicle in the current scene
var ChassisRB : RigidBody2D
## CollisionShape of the Vehicle in the current scene
var ChassisColl : CollisionShape2D
## Rigidbodies of the Wheels in the current scene
var WheelsRB : Array[Node]
## CollisionShapes of the Wheels in the current scene
var WheelsColl : Array[Node]
## Camera of the Vehicle in the current scene
var CameraChassis : Camera
## Hud in the current scene
var Hud : CanvasLayer

func _ready() -> void:
	ChassisRB = get_tree().get_first_node_in_group("chassis")
	ChassisColl = get_tree().get_first_node_in_group("chassis_coll")
	WheelsRB = get_tree().get_nodes_in_group("wheels")
	WheelsColl = get_tree().get_nodes_in_group("wheels_coll")
	CameraChassis = get_tree().get_first_node_in_group("camera")
	Hud = get_tree().get_first_node_in_group("hud")