shader_type canvas_item;

uniform float blend :hint_range(0.0, 1.0, 0.1)= 0;

void fragment() {
	COLOR.a = mix(UV.x, 1.-UV.y, blend);
}
