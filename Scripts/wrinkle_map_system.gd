@tool
extends Node3D

@export var mesh : MeshInstance3D
@export var run_wrinkle_maps : bool = true;

func _process(delta: float) -> void:
	if run_wrinkle_maps:
		wrinkle_value("brow_down_L", two_shapes("browDownLeft", "noseSneerLeft"))#wrinkle("brow_down_L", "browDownLeft")
		wrinkle_value("brow_down_R", two_shapes("browDownRight", "noseSneerRight"))#wrinkle("brow_down_R", "browDownRight")
		wrinkle("nose_sneer_L", "noseSneerLeft")
		wrinkle("nose_sneer_R", "noseSneerRight")
		wrinkle_value("eye_squint_L", two_shapes("cheekSquintLeft", "eyeSquintLeft", 1,.5) * 2.)#wrinkle_value("eye_squint_L", shape_value("cheekSquintLeft", 1.))
		wrinkle_value("eye_squint_R", two_shapes("cheekSquintRight", "eyeSquintRight", 1,.5) * 2.)#wrinkle_value("eye_squint_R", shape_value("cheekSquintRight", 1.))
		wrinkle_value("mouth_stretch_L", two_shapes("mouthStretchLeft", "jawOpen", 1,1) * 2.)
		wrinkle_value("mouth_stretch_R", two_shapes("mouthStretchRight", "jawOpen", 1,1) * 2.)
		wrinkle_value("mouth_smile_L", two_shapes("mouthSmileLeft", "mouthLeft", 1,1) * 2.)#wrinkle("mouth_smile_L", "mouthSmileLeft")
		wrinkle_value("mouth_smile_R", two_shapes("mouthSmileRight", "mouthRight", 1,1) * 2.)#wrinkle("mouth_smile_R", "mouthSmileRight")
		
func wrinkle(parameter: String, blendshape: String):
	mesh.mesh.surface_get_material(0).set_shader_parameter(
		parameter,
		mesh.get_blend_shape_value(mesh.find_blend_shape_by_name(blendshape))
		)

func wrinkle_value(parameter: String, value: float):
	mesh.mesh.surface_get_material(0).set_shader_parameter(parameter, value)
		
func two_shapes(shape1: String, shape2: String, multiplier1: float = 1.0, multiplier2: float = 1.0) -> float:
	var s1 = mesh.get_blend_shape_value(mesh.find_blend_shape_by_name(shape1))
	s1 *= multiplier1
	var s2 = mesh.get_blend_shape_value(mesh.find_blend_shape_by_name(shape2))
	s2 *= multiplier2
	
	return (s1 + s2) * 0.5

func shape_value(blendshape: String, multiplier: float) -> float:
	return mesh.get_blend_shape_value(mesh.find_blend_shape_by_name(blendshape)) * multiplier
