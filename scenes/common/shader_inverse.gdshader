shader_type canvas_item;

// Inverse video: paper where the screen is dark, ink where it is light.
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
const vec3 INK = vec3(0.105882, 0.101961, 0.090196);
const vec3 PAPER = vec3(0.937255, 0.901961, 0.811765);

void fragment() {
	vec3 under = texture(screen_tex, SCREEN_UV).rgb;
	float luma = dot(under, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(luma > 0.5 ? INK : PAPER, 1.0);
}