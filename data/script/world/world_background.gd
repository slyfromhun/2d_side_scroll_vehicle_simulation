class_name Background
extends ParallaxBackground

@export var background: BackgroundFunctions
@export_group("Blur")
@export var blurShader: ShaderMaterial
@export var blurQuality := 4


func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if Engine.get_process_frames() % Global.Priority.VERYLOW == 0:
		background.blur(blurShader, Global.ChassisRB.kph, blurQuality)
