## World effects of the current scene
class_name WorldEffects
extends Resource

## Position of the effect based on the position of the Camera in the scene
@export var position: Vector2i
## Minimun speed to emit effect
@export var speed_min := 10
## Final state of the amount ratio of the effect
@export var final_amount_ratio := 0