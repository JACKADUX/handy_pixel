shader_type canvas_item;

instance uniform float v = 1.0;

void fragment() {
	float a = abs(v-UV.y);
	COLOR.a *= a*a;
}

