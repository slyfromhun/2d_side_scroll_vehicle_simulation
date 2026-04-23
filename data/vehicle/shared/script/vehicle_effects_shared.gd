class_name Vehicle_Effects
extends Node

@export var effect: VehicleEffects
@export var frictionScenes_wheel1: Array[GPUParticles2D]
@export var frictionScenes_wheel2: Array[GPUParticles2D]
@export var slipScenes_wheel1: Array[GPUParticles2D]
@export var slipScenes_wheel2: Array[GPUParticles2D]
@export var grindScenes_wheel1: Array[GPUParticles2D]
@export var grindScenes_wheel2: Array[GPUParticles2D]
@export var chassisScenes: Array[GPUParticles2D]
@export var wheelSprites: Array[Sprite2D]

var frictionScenes: Array
var slipScenes: Array
var grindScenes: Array

var wheelCol: Array[Node]
var wheelRB: Array[Node]
var chassis: Node

func _ready() -> void:
	initalize()

func _physics_process(_delta: float) -> void:
	pass

func _process(_delta: float) -> void:
	for i in wheelRB.size():
		effect.friction(abs(chassis.wheels_angular_kph[i]), frictionScenes[i], chassis.wheels_angular_magnitude[i], chassis.slip_ratios[i])
		effect.slip(abs(chassis.wheels_angular_kph[i]), chassis.wheels_mps[i], slipScenes[i], chassis.wheels_angular_magnitude[i], chassis.slip_ratios[i])
		effect.grind(abs(chassis.wheels_angular_kph[i]), chassis.wheels_mps[i], grindScenes[i], chassis.wheels_angular_magnitude[i], chassis.slip_ratios[i])
		effect.dust(chassis.kph, chassisScenes)
		effect.process_texture(wheelSprites[i], chassis.wheels_angular_mps[i], 10, chassis.tire.visual_radius)

func initalize():
	wheelCol = get_tree().get_nodes_in_group("wheels_coll")
	wheelRB = get_tree().get_nodes_in_group("wheels")
	chassis = get_tree().get_first_node_in_group("chassis")

	frictionScenes = [frictionScenes_wheel1, frictionScenes_wheel2]
	slipScenes = [slipScenes_wheel1, slipScenes_wheel2]
	grindScenes = [grindScenes_wheel1, grindScenes_wheel2]
	###
	for i in wheelRB.size():
		for frictionScene in frictionScenes[i]:
			frictionScene.global_position = wheelCol[i].global_position
		for slipScene in slipScenes[i]:
			slipScene.global_position = wheelCol[i].global_position
		for grindScene in grindScenes[i]:
			grindScene.global_position = wheelCol[i].global_position + Vector2(0, chassis.tire.radius)
		for scene in chassisScenes:
			scene.global_position = chassis.global_position
	###
	effect.dust_color_power.set_point_offset(0, effect.speed_dust[0])
