shader_type canvas_item;

uniform float x_dir = 1.;
uniform float saturation = 1.;
uniform float value = 1.;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	float h = (UV.x*x_dir+(UV.y*(1.-x_dir)));
	vec3 color = hsv2rgb(vec3(h, saturation, value));
	COLOR = vec4(color, 1.) ;
}
