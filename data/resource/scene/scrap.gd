## Properties of procedurally generated nodes
class_name ScrapStats
extends Resource

## How much distance has to be travelled to spawn node
@export var trigger_distance := Vector2(2000.0, 4000.0)
## Distance from the Vehicle after spawning
@export var trigger_distance_after := Vector2(250.0, 500.0)
## Count of nodes spawned
@export var count := Vector2i(1, 5)
## Spacing between each node
@export var spacing := Vector2(2.0, 8.0)