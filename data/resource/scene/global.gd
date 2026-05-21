extends Node

enum Priority {REALTIME = 1, HIGH = 2, MEDIUM = 4, LOW = 8, VERYLOW = 16}

var ChassisRB : RigidBody2D
var ChassisColl : CollisionShape2D
var WheelsRB : Array[Node]
var WheelsColl : Array[Node]
var CameraChassis : Camera
var Hud : CanvasLayer

func _ready() -> void:
    ChassisRB = get_tree().get_first_node_in_group("chassis")
    ChassisColl = get_tree().get_first_node_in_group("chassis_coll")
    WheelsRB = get_tree().get_nodes_in_group("wheels")
    WheelsColl = get_tree().get_nodes_in_group("wheels_coll")
    CameraChassis = get_tree().get_first_node_in_group("camera")
    Hud = get_tree().get_first_node_in_group("hud")