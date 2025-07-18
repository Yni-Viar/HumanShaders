/*
Sub-Surface Scattering Approximation
Copyright (c) 2024 Ivan Reshetnikov

Permission is hereby granted, free of charge, to any person obtaining a copy of
this shader and associated documentation files (the "Shader"), to deal in the
Shader without restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
Shader, and to permit persons to whom the Shader is furnished to do so, subject
to the following conditions:

THE SHADER IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SHADER OR THE USE OR OTHER DEALINGS IN THE SHADER.
*/
/*
Godot Standard Light Shader (Replica) by RustyRoboticsBV
https://github.com/RustyRoboticsBV/GodotStandardLightShader
*/

/*
Parts of this shader were automatically converted
from Godot Engine 4.2.stable's StandardMaterial3D.
*/

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

uniform vec4 metallic_texture_channel;
uniform float metallic;
uniform sampler2D texture_metallic : hint_default_white,filter_linear_mipmap,repeat_enable;

uniform float roughness : hint_range(0, 1);
uniform sampler2D texture_roughness : hint_roughness_g,filter_linear_mipmap,repeat_enable;

uniform float specular;
uniform float normal_scale : hint_range(-16,16);
uniform sampler2D texture_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;

uniform float subsurface_scattering_factor = 4.0;
uniform sampler2D subsurface_scattering_map : filter_linear_mipmap, repeat_enable;


void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	float metallic_tex = dot(texture(texture_metallic,base_uv),metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	vec4 roughness_texture_channel = vec4(0.0,1.0,0.0,0.0);
	float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	SPECULAR = specular;
	NORMAL_MAP = texture(texture_normal,base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
}

/* Start of:
Godot Standard Light Shader (Replica) by RustyRoboticsBV
https://github.com/RustyRoboticsBV/GodotStandardLightShader
*/
float DistributionGGX(float cos_theta_m, float alpha)
{
	float alpha2 = alpha * alpha;
	float d = 1.0 + (alpha2 - 1.0) * cos_theta_m * cos_theta_m;
	return alpha2 / (PI * d * d);
}

float GeometryGGX(float NdotL, float NdotV, float alpha)
{
	return 0.5 / mix(2.0 * NdotL * NdotV, NdotL + NdotV, alpha);
}

vec3 SchlickBaseReflectivity(float metallic_, float specular_, vec3 albedo_)
{
	float dielectric = 0.04 * specular_ * specular;
	return mix(vec3(dielectric), albedo_, vec3(metallic_));
}

float SchlickFresnel(float u)
{
	float m = 1.0 - u;
	float m2 = m * m;
	return m2 * m2 * m;
}
/* End of:
* Godot Standard Light Shader (Replica) by RustyRoboticsBV
* https://github.com/RustyRoboticsBV/GodotStandardLightShader
*/

void light() {
	// Diffuse light
	DIFFUSE_LIGHT += max(dot(NORMAL, LIGHT), 0.0) * LIGHT_COLOR;

	// Sub-surface scattering
	float sss_map_factor = texture(subsurface_scattering_map, UV).r;

	SPECULAR_LIGHT +=
		max(abs(dot(-NORMAL, LIGHT)), 0.0) // Directional light factor
		* LIGHT_COLOR / PI // Normalized light color
		* ALBEDO
		* sss_map_factor * sss_map_factor // Channel transmission with SSS map
		* subsurface_scattering_factor;

/* Start of:
Godot Standard Light Shader (Replica) by RustyRoboticsBV
https://github.com/RustyRoboticsBV/GodotStandardLightShader
*/
	// Calculate some vectors.
	vec3 lightColor = LIGHT_COLOR / PI;

	vec3 half = normalize(VIEW + LIGHT);

	float NdotL = max(dot(NORMAL, LIGHT), 0.0);
	float NdotV = max(dot(NORMAL, VIEW), 0.0);
	float NdotH = max(dot(NORMAL, half), 0.0);
	float LdotH = max(dot(LIGHT, half), 0.0);

	// Specular light (Schlick-GGX).
	float ggxAlpha = ROUGHNESS * ROUGHNESS;
	float D = DistributionGGX(NdotH, ggxAlpha);
	float G = GeometryGGX(NdotL, NdotV, ggxAlpha);

	vec3 f0 = SchlickBaseReflectivity(METALLIC, SPECULAR_AMOUNT, ALBEDO);
	float LdotH5 = SchlickFresnel(LdotH);
	float f90 = clamp(50.0 * f0.g, 0.0, 1.0);
	vec3 F = f0 + (f90 - f0) * LdotH5;

	vec3 specularBRDF = max(NdotL * D * G * F, 0.0);
	SPECULAR_LIGHT += specularBRDF * LIGHT_COLOR * ATTENUATION;
/* End of:
* Godot Standard Light Shader (Replica) by RustyRoboticsBV
* https://github.com/RustyRoboticsBV/GodotStandardLightShader
*/
}