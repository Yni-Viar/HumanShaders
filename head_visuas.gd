extends Node3D

@onready var infinite_level_02: MeshInstance3D = $"Infinite-level02"
#@onready var emily_21: MeshInstance3D = $Emily21
@onready var emily_21: MeshInstance3D = $Emili_Head_Optimized/Armature/Skeleton3D/Emily_Head

@onready var parent: Node3D = get_parent_node_3d()
@onready var skin_color_picker: ColorPicker = %SkinColorPicker
@onready var roughness_slider: HSlider = %RoughnessSlider
@onready var subsurface_scattering: CheckButton = %"SubsurfaceScattering"
@onready var subsurf_slider: HSlider = %SubSurfSlider
@onready var sss_noise: CheckButton = %SSSNoise
@onready var tinted_shadow: CheckButton = %TintedShadow
@onready var lightwarp: CheckButton = %Lightwarp
@onready var translucency: CheckButton = %Translucency

var default_rot : Vector3
var skin_material : ShaderMaterial

func skin_parameter(p: String) -> Variant:
	return skin_material.get_shader_parameter(p)

func _ready() -> void:
	#for i in get_children():
	#	var shader_mat = i.get_surface_override_material(0)
	#	if shader_mat is ShaderMaterial:
	#		skin_material = shader_mat
	
	var shader_mat = emily_21.mesh.surface_get_material(0)
	if shader_mat is ShaderMaterial:
		skin_material = shader_mat
	
	default_rot = parent.rotation
	skin_color_picker.visible = false
	
	roughness_slider.value_changed.connect(on_roughness_slider_changed)
	roughness_slider.value = skin_parameter("roughness")
	
	subsurface_scattering.toggled.connect(on_sss_toggle)
	subsurface_scattering.button_pressed = skin_parameter("subsurface_scattering")
	
	sss_noise.toggled.connect(on_sss_noise_toggle)
	sss_noise.button_pressed = skin_parameter("use_noise")
	
	subsurf_slider.value_changed.connect(on_sss_slider_changed)
	subsurf_slider.value = skin_parameter("subsurface_scattering_strength")
	
	tinted_shadow.toggled.connect(on_tinted_shadow_toggle)
	tinted_shadow.button_pressed = skin_parameter("tinted_shadow_penumbra")
	
	lightwarp.toggled.connect(on_lightwarp_toggle)
	lightwarp.button_pressed = skin_parameter("old_lightwarp_fallof")
	
	translucency.toggled.connect(on_translucency_toggle)
	translucency.button_pressed = skin_parameter("translucency")
	
func _on_reset_model_pressed() -> void:
	parent.rotation = default_rot
	
	Autoload.log_message("Reset Model Rotation Applied")
	
func _on_skin_color_toggled(toggled_on: bool) -> void:
	skin_color_picker.visible = toggled_on

func _on_skin_color_picker_color_changed(color: Color) -> void:
	skin_material.set_shader_parameter("albedo", color)
	
	if color == Color.WHITE:
		Autoload.log_message("Skin color changed to Default")
	else:
		Autoload.log_message("Skin color changed to " + str(color.to_html()))

func on_roughness_slider_changed(value: float) -> void:
	skin_material.set_shader_parameter("roughness", value)
	
	Autoload.log_message("Roughness changed to " + str(value))
	
func on_sss_toggle(value: float) -> void:
	skin_material.set_shader_parameter("subsurface_scattering", value)
	
	if value:
		Autoload.log_message("SSS toggled ON")
	else:
		Autoload.log_message("SSS toggled OFF")
	
func on_sss_noise_toggle(value: float) -> void:
	skin_material.set_shader_parameter("use_noise", value)
	
	if value:
		Autoload.log_message("SSS Noise toggled ON")
	else:
		Autoload.log_message("SSS Noise toggled OFF")
	
func on_sss_slider_changed(value: float) -> void:
	skin_material.set_shader_parameter("subsurface_scattering_strength", value)
	
	Autoload.log_message("SSS changed to " + str(value))
	
func on_tinted_shadow_toggle(value: float) -> void:
	skin_material.set_shader_parameter("tinted_shadow_penumbra", value)
	
	if value:
		Autoload.log_message("Tinted Shadow Penumbra toggled ON")
	else:
		Autoload.log_message("Tinted Shadow Penumbra toggled OFF")
	
func on_lightwarp_toggle(value: float) -> void:
	skin_material.set_shader_parameter("old_lightwarp_fallof", value)
	
	if value:
		Autoload.log_message("Lightwarp toggled ON")
	else:
		Autoload.log_message("Lightwarp toggled OFF")
	
func on_translucency_toggle(value: float) -> void:
	skin_material.set_shader_parameter("translucency", value)
	
	if value:
		Autoload.log_message("Translucency toggled ON")
	else:
		Autoload.log_message("Translucency toggled OFF")
