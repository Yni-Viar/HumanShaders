// NOTE: Shader automatically converted from Godot Engine 4.3.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, sss_mode_skin;

uniform sampler2D depth_texture : hint_depth_texture;

group_uniforms albedo;
uniform vec4 albedo : source_color = vec4(1.);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
//uniform float point_size : hint_range(0.1, 128.0, 0.1);

group_uniforms roughness;
uniform float roughness : hint_range(0.0, 1.0);
uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform bool double_specularity = true;

uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

group_uniforms metallic;
uniform float metallic : hint_range(0.0, 1.0, 0.01);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;

group_uniforms normal;
uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_strength : hint_range(-16.0, 16.0) = 1.;

group_uniforms micro_detail;
uniform float micro_detail_scale : hint_range(0.0, 200.0) = 25.;
uniform float micro_normal_strength : hint_range(-1.0, 1.0) = 0.5;
uniform float micro_ao_strength : hint_range(-1.0, 1.0) = 0.6;
uniform sampler2D texture_micro_detail : hint_roughness_normal, filter_linear_mipmap_anisotropic, repeat_enable;
//uniform float soften_normal : hint_range(0.0, 1.0);

group_uniforms ambient_occlusion;
uniform sampler2D ambient_occlusion_texture : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float ao_strength : hint_range(0.0, 2.0) = 0.7;
uniform float ao_block_light : hint_range(0.0, 2.0) = 0.5;

group_uniforms subsurface_scattering;
uniform bool subsurface_scattering = true;
uniform bool use_noise = false;
uniform float subsurface_scattering_strength : hint_range(0.0, 1.0, 0.01) = 0.4;
uniform float skin_fallof_smoothness : hint_range(0.7, 2.0, 0.01) = 1.0;
uniform bool tinted_shadow_penumbra = false;
uniform bool old_lightwarp_fallof = false;
uniform sampler2D lightwarp : source_color, filter_linear, repeat_disable;
uniform sampler2D texture_sss_noise : filter_linear, repeat_enable, source_color;


group_uniforms translucency;
uniform bool translucency = false;
uniform float translucency_strength : hint_range(0.0, 2.0, 0.01) = 0.75;
uniform sampler2D texture_translucency : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_translucency_color : source_color, filter_linear, repeat_disable;


group_uniforms u_v;
uniform vec3 uv1_scale = vec3(1.);
uniform vec3 uv1_offset = vec3(0.);
uniform vec3 uv2_scale = vec3(1.);
uniform vec3 uv2_offset = vec3(0.);

varying mat3 TBN;
varying vec3 DIFFUSE_NORMAL;
varying vec3 RAW_NORMAL;
varying vec4 micro_detail;
varying vec3 final_albedo;
varying float ao;
varying float linear_depth;
varying float smooth_depth;
varying float sss_tex;

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
	// Detail UV Layer: UV2
	UV2 = UV2 * uv2_scale.xy + uv2_offset.xy;
}

vec3 normal_blending(vec3 b, vec3 d) {
	return vec3(b.xy + d.xy - 0.5, b.z);
}

vec3 overlay(vec3 base, vec3 blend){
	vec3 limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}

vec3 custom_normal(vec3 normal_map){
	normal_map = mix(vec3(0.5,0.5,1.0), normal_map, normal_strength);
	vec3 normal_tangent = vec3(
		normal_map.r * 2.0 - 1.0,  // X-axis (unchanged)
		(1.0 - normal_map.g) * 2.0 - 1.0,  // Y-axis (inverted)
		1   // Z-axis (solid blue)
		);
	return normalize(TBN * normal_tangent);
}

void fragment() {
	vec2 base_uv = UV;
	TBN = mat3(TANGENT, -BINORMAL, NORMAL);
	//Raw depth value:
	float depth_raw = FRAGCOORD.z;
	//Convert to linear:
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	// reverse
	linear_depth = clamp(1. + (view.z / 1.0), 0., 1.);
	smooth_depth = linear_depth * linear_depth;

	sss_tex = texture(texture_translucency, base_uv).b;

	float fresnel = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0 );

	micro_detail = texture(texture_micro_detail, base_uv * micro_detail_scale);
	ao = texture(texture_normal, base_uv).b;
	ao *= texture(ambient_occlusion_texture, base_uv).r;

	float micro_overlay = mix(0.5, micro_detail.b, micro_ao_strength * 2.);
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	albedo_tex = vec4(overlay(albedo_tex.rgb, vec3(micro_overlay)), albedo_tex.w);

	final_albedo = albedo.rgb * albedo_tex.rgb;
	ALBEDO = final_albedo * (1. - metallic);


	//ALBEDO = vec3(fresnel);

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	//METALLIC = metallic_tex * metallic;

	//float spec = max(dot(NORMAL, LIGHT_VERTEX * LIGHT_VERTEX), 0.0);

	//ALBEDO = vec3(1.);
	SPECULAR = clamp(specular * ao, 0.,1.);

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = clamp(roughness_tex * roughness, 0.,1.);

	// Normal Map: Enabled
	vec3 micro_normal = mix(vec3(.5,.5,1.), vec3(micro_detail.xy, 1.), micro_normal_strength);

	//dn stands for Diffuse Normal:

	//DIFFUSE_NORMAL = custom_normal(diff_normal_map);
	RAW_NORMAL = NORMAL;
	//ALBEDO = vec3(dn_r.r, dn_g.g, dn_b.b);

	NORMAL_MAP = normal_blending(texture(texture_normal, base_uv).rgb, micro_normal);
	NORMAL_MAP_DEPTH = normal_strength;

	// Ambient Occlusion: Enabled
	AO = ao * ao_strength + (1.-ao_strength);// * smoothstep(0.,1., micro_detail.z * 1.6);
	AO_LIGHT_AFFECT = 0.0;

	// Subsurface Scattering: Enabled
	if (subsurface_scattering){
		if (smooth_depth > 0.){
			float sss_strength_value = subsurface_scattering_strength * 2.0 + (sss_tex * 2.);
			if (use_noise){
				vec2 tiling_screen_uv = FRAGCOORD.xy / (0.64 * -1.);
				float noise = 3.* texture(texture_sss_noise, tiling_screen_uv).r;// + vec2(1000. * TIME)).r;
				sss_strength_value *= noise;
				//ALBEDO = vec3(noise);
			}
		SSS_STRENGTH = sss_strength_value * texture(ambient_occlusion_texture, base_uv).r * smooth_depth;
		}
		//float sss_depth = 1. - pow(clamp(world_camera.z,0.,1.), 0.5);
	}
}
float DistributionGGX(float cos_theta_m, float alpha){
	float alpha2 = alpha * alpha;
	float d = 1.0 + (alpha2 - 1.0) * cos_theta_m * cos_theta_m;
	return alpha2 / (PI * d * d);
}

float GeometryGGX(float NdotL, float NdotV, float alpha){
	return 0.5 / mix(2.0 * NdotL * NdotV, NdotL + NdotV, alpha);
}

vec3 SchlickBaseReflectivity(){
	float dielectric = 0.04 * specular * specular;
	return mix(vec3(dielectric), final_albedo, vec3(metallic));
}

float SchlickFresnel(float u){
	float m = 1.0 - u;
	float m2 = m * m;
	return m2 * m2 * m;
}

void light()
{
	// Calculate some vectors.
	vec3 lightColor = LIGHT_COLOR / PI;

	vec3 half = normalize(VIEW + LIGHT);

	float NdotL = max(dot(NORMAL, LIGHT), 0.0);
	float NdotV = max(dot(NORMAL, VIEW), 0.0);
	float NdotH = max(dot(NORMAL, half), 0.0);
	float LdotH = max(dot(LIGHT, half), 0.0);

	// Diffuse light (Lambert):
	//DIFFUSE_LIGHT += clamp(dot(mix(DIFFUSE_NORMAL, NORMAL, 0.3), LIGHT),0.,1.) * ATTENUATION * lightColor;

	//Custom wrapped diffuse:
	float wrap = 0.5;
	vec3 diff_light;
	float normal_depth = max((1.5-linear_depth), 1.);
	//normal_depth = 1.;

	if (!old_lightwarp_fallof){ //Better SSS aproximation:
		//Calculate custom normal:

		vec3 dn_r = custom_normal(textureLod(texture_normal, UV, 5. * normal_depth).rgb);
		vec3 dn_g = custom_normal(textureLod(texture_normal, UV, 4. * normal_depth).rgb);
		vec3 dn_b = custom_normal(textureLod(texture_normal, UV, 3.5 * normal_depth).rgb);

		float s = skin_fallof_smoothness;

		float wrapped_r = smoothstep(0.4 /s, 1.2 *s, dot(dn_r, LIGHT) * wrap + (1.0-wrap));
		float wrapped_g = smoothstep(0.42 /s, 1.2 *s, dot(dn_g, LIGHT) * wrap + (1.0-wrap));
		float wrapped_b = smoothstep(0.44 /s, 1.2 *s, dot(dn_b, LIGHT) * wrap + (1.0-wrap));
		vec3 wrapped_rgb = vec3(wrapped_r, wrapped_g, wrapped_b)  * (ao * ao_block_light + (1.-ao_block_light));

		diff_light = wrapped_rgb;
	}
	else{ //Lightwarp technique:
		vec3 diff_normal_map = mix(
			textureLod(texture_normal, UV, 6. * normal_depth).rgb,
			textureLod(texture_normal, UV, 3. * normal_depth).rgb,
			.2);
		vec3 diff_normal = custom_normal(diff_normal_map);

		float wrapped = pow(dot(diff_normal, LIGHT) * wrap + (1.0-wrap), 2.0);
		vec3 lw = texture(lightwarp, vec2(wrapped * (ao * ao_block_light + (1.-ao_block_light)), 0.0)).rgb;
		diff_light = lw;
	}

	//Tint shadow penumbra:
	vec3 att = overlay(min(vec3(ATTENUATION), 1.), vec3(1.2,.8,.6)) * max(ATTENUATION, 0.5);
	if (tinted_shadow_penumbra){att = att;} else{att = vec3(ATTENUATION);}

	DIFFUSE_LIGHT += diff_light * att * lightColor;

	if (translucency){
		float translucency_dot = dot(VIEW,-(LIGHT + NORMAL * .4));
		vec2 t_col_coord = vec2(sss_tex * translucency_dot * translucency_strength, 0.0);
		vec3 t_color = texture(texture_translucency_color, t_col_coord).rgb;
		vec3 translucent = max(translucency_dot * t_color, 0.0) * lightColor;
		//translucency *= max(translucency_strength, 1.);

		DIFFUSE_LIGHT += translucent;
	}

	vec3 f0 = SchlickBaseReflectivity();
	float LdotH5 = SchlickFresnel(LdotH);
	float f90 = clamp(50.0 * f0.g, 0.0, 1.0);
	vec3 F = f0 + (f90 - f0) * LdotH5;

	// Specular light (Schlick-GGX).
	float ggxAlpha = ROUGHNESS * ROUGHNESS;
	float D = DistributionGGX(NdotH, ggxAlpha);
	float G = GeometryGGX(NdotL, NdotV, ggxAlpha);

	vec3 specularBRDF = max(NdotL * D * G * F, 0.0);
	if (double_specularity){
		float D2 = DistributionGGX(NdotH, ggxAlpha + .3);
		float G2 = GeometryGGX(NdotL, NdotV, ggxAlpha + .3);

		vec3 specularBRDF2 = max(NdotL * D2 * G2 * F, 0.0);
		specularBRDF = mix(specularBRDF2, specularBRDF, .6) * 2.;
	}
	SPECULAR_LIGHT += specularBRDF * LIGHT_COLOR * ATTENUATION * ao;
}
