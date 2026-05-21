class_name Vehicle_Effects
extends Node

@export var effect: VehicleEffects
@export_group("Friction")
@export var frictionScenes_wheel1: Array[GPUParticles2D]
@export var frictionScenes_wheel2: Array[GPUParticles2D]
@export_group("Slip")
@export var slipScenes_wheel1: Array[GPUParticles2D]
@export var slipScenes_wheel2: Array[GPUParticles2D]
@export_group("Grind")
@export var grindScenes_wheel1: Array[GPUParticles2D]
@export var grindScenes_wheel2: Array[GPUParticles2D]
@export_group("Chassis")
@export var chassisScenes: Array[GPUParticles2D]
@export_group("World")
@export var worldEffectScenes: Array[GPUParticles2D]
@export_group("Wheel")
@export var wheelSprites: Array[Sprite2D]

var frictionScenes: Array
var slipScenes: Array
var grindScenes: Array

func _ready() -> void:
	initalize()

func _physics_process(_delta: float) -> void:
	pass

func _process(_delta: float) -> void:
	if Engine.get_process_frames() % Global.Priority.HIGH == 0:	
		for i in Global.WheelsRB.size():
			effect.friction(abs(Global.ChassisRB.wheels_angular_kph[i]), frictionScenes[i], Global.ChassisRB.wheels_angular_magnitude[i], Global.ChassisRB.slip_ratios[i])
			effect.slip(abs(Global.ChassisRB.wheels_angular_kph[i]), Global.ChassisRB.wheels_mps[i], slipScenes[i], Global.ChassisRB.wheels_angular_magnitude[i], Global.ChassisRB.slip_ratios[i])
			effect.grind(abs(Global.ChassisRB.wheels_angular_kph[i]), Global.ChassisRB.wheels_mps[i], grindScenes[i], Global.ChassisRB.wheels_angular_magnitude[i], Global.ChassisRB.slip_ratios[i])
			effect.dust(Global.ChassisRB.kph, chassisScenes)
			effect.process_texture(wheelSprites[i], Global.ChassisRB.wheels_angular_mps[i], 10, Global.ChassisRB.tire.visual_radius)
		for i in worldEffectScenes.size():
			effect.speed(Global.ChassisRB.kph, worldEffectScenes[i], worldEffectScenes[i].property.speed_min, worldEffectScenes[i].property.final_amount_ratio)

func initalize():
	frictionScenes = [frictionScenes_wheel1, frictionScenes_wheel2]
	slipScenes = [slipScenes_wheel1, slipScenes_wheel2]
	grindScenes = [grindScenes_wheel1, grindScenes_wheel2]
	###
	for i in Global.WheelsRB.size():
		for frictionScene in frictionScenes[i]:
			frictionScene.global_position = Global.WheelsColl[i].global_position
		for slipScene in slipScenes[i]:
			slipScene.global_position = Global.WheelsColl[i].global_position
		for grindScene in grindScenes[i]:
			grindScene.global_position = Global.WheelsColl[i].global_position + Vector2(0, Global.ChassisRB.tire.radius)
		for scene in chassisScenes:
			scene.global_position = Global.ChassisRB.global_position
	###
	for i in worldEffectScenes.size():
		worldEffectScenes[i].position = worldEffectScenes[i].property.position
		worldEffectScenes[i].position.y -= Global.ChassisRB.global_position.y - Global.CameraChassis.global_position.y
	
	effect.dust_color_power.set_point_offset(0, effect.speed_dust[0])
