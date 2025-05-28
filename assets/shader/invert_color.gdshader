shader_type canvas_item;

uniform sampler2D sct : hint_screen_texture;

vec4 difference(vec4 base, vec4 blend){
	return abs(base - blend);
}

void fragment(){
	COLOR.rgb = difference(texture(TEXTURE, UV), texture(sct, SCREEN_UV)).rgb;
}