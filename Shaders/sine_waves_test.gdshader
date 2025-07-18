shader_type spatial;

uniform vec4 albedo_color : source_color;
uniform float roughness = .5;
uniform float sineWave_size = 10.;
uniform float sineWave_strength = 1.00;

float sineWave(vec2 uv){
	return ((sin(uv.x * sineWave_size + (TIME*2.)) + 1.) * cos(uv.y * 10. + -TIME) *.5) * sineWave_strength;
}

//Normal map from Height map
//Credits to Pixezy on YouTube who adapted the original Unity implementation to Godot
vec3 height_to_normal(float height, float strength, vec3 vertex, vec3 normal) {
	vec3 world_derivative_x = dFdx(vertex);
	vec3 world_derivative_y = dFdy(vertex);

	vec3 cross_x = cross(normal, world_derivative_x);
	vec3 cross_y = cross(world_derivative_y, normal);
	float d = dot(world_derivative_x, cross_y);
	float sgn = d < 0.0 ? -1.0 : 1.0;
	float surface = sgn / max(0.000000000000001192093, abs(d));

	float d_hdx = dFdx(height);
	float d_hdy = dFdy(height);
	vec3 surf_grad = surface * (d_hdx * cross_y + d_hdy * cross_x);

	return normalize(normal - (strength * surf_grad));
}

void vertex() {
	// Called for every vertex the material is visible on.
	VERTEX += vec3(sineWave(UV) * NORMAL);

	float height_scale = 0.2;

	vec2 e = vec2(0.1,0.0);
	//vec3 normal = normalize(vec3(sineWave(VERTEX.xz - e) - sineWave(VERTEX.xz + e), 2.0 * e.x, sineWave(VERTEX.xz - e.yx) - sineWave(VERTEX.xz + e.yx)));
	vec3 normal = normalize(vec3(sineWave(VERTEX.xz- e) * height_scale - sineWave(VERTEX.xz+ e) * height_scale, 1.0 * e.x, sineWave(VERTEX.xz- e.yx) * height_scale - sineWave(VERTEX.xz+ e.yx) * height_scale));
	//NORMAL = normal;

	COLOR.xyz = vec3(.2, .2, .4);
}

void fragment() {
	// Called for every pixel the material is visible on.
	float height = sineWave(UV);
	vec3 normal = height_to_normal(height, 1.0, VERTEX, NORMAL);

	float sine = (sin(UV.x * sineWave_size) + 1.) *.5;

	ALBEDO = albedo_color.rgb;
	ROUGHNESS = roughness;

	NORMAL = normal;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
