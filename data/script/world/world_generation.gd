## Procedural Generation
class_name Generation
extends Node2D

@export_group("Scrap")
@export var scrap: ScrapStats
@export var scrapScene: PackedScene

var rand_trigger_distance: float
var rand_trigger_distance_after: float
var rand_count: int
var rand_spacing: float
var trigger_distance_sum = 0
var instances := []


func _ready() -> void:
	initalize()

func _process(_delta: float) -> void:
	generate(Global.ChassisRB, scrapScene, scrap.trigger_distance, scrap.trigger_distance_after, scrap.count, scrap.spacing)


## Generates Common nodes
func generate(chassis:RigidBody2D, node:PackedScene, trigger_distance:Vector2, trigger_distance_after:Vector2, count:Vector2i, spacing:Vector2):
	trigger_distance_sum += chassis.distance * 0.01
	if trigger_distance_sum > rand_trigger_distance:
		rand_count = randi_range(count[0], count[1])
		rand_trigger_distance_after = randf_range(trigger_distance_after[0], trigger_distance_after[1])
		for i in rand_count:
			rand_spacing = randf_range(spacing[0], spacing[1])
			var instance := node.instantiate() as Node2D
			instance.position = Vector2(chassis.position.x + rand_trigger_distance_after * 100 + rand_spacing * 100.0, chassis.position.y)

			if instances.size() < 15:
				instances.append(instance)
				add_child(instance)
			else:
				instances[0].queue_free()
				instances.remove_at(0)
				add_child(instance)
				instances.append(instance)

			print(instance.position, i)
		print(instances.size())
		rand_trigger_distance = randf_range(trigger_distance[0], trigger_distance[1])
		trigger_distance_sum = 0


func initalize():
	rand_trigger_distance = randf_range(scrap.trigger_distance[0], scrap.trigger_distance[1])
