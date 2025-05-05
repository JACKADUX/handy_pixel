shader_type canvas_item;

instance uniform vec3 c1 : source_color;
instance uniform vec3 c2 : source_color;

vec3 blend(vec3 color1, vec3 color2, float factor) {
	return color1 + (color2-color1)*factor;
}

void fragment() {
	vec3 color = blend(c1, c2, UV.x);
	COLOR.rgb = color;
}
