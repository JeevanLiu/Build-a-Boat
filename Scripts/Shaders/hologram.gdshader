shader_type spatial;

uniform vec3 holocolor = vec3(0.1, 0.4, 0.6);
varying float ypos;

void vertex() {
	// Called for every vertex the material is visible on.
	vec4 pos = (MODEL_MATRIX * vec4(VERTEX, 1.0));
	ypos = pos.y + pos.x;
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = holocolor + vec3(0.4f);
	ALPHA = (sin(ypos * 20.0 + TIME * 8.0) + 1.0f) * 0.4f + 0.2f;
}

void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
	DIFFUSE_LIGHT = holocolor * 2.0;
}
