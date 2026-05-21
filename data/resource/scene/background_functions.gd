class_name BackgroundFunctions
extends Resource

@export var backgroundBlur := true

func blur(shader:ShaderMaterial, kph:float, blur_quality:int) -> void:
	if backgroundBlur:
		if int(kph) > 50:
			shader.set_shader_parameter("quality", blur_quality)
		else:
			shader.set_shader_parameter("quality", 0)
