shader_type fog;

uniform sampler2D noise_text:repeat_enable;
uniform sampler2D grad_text;
uniform float noise_scale = 1.0;
uniform float flatness = 1.0;
uniform float density = 1.0;

uniform float box_limit_y = 2.5;
uniform float box_limit_x = 2.5;

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

void fog() {
	vec2 move_uv = vec2(0.1, 0.1)*TIME;
	float height_limit = step(WORLD_POSITION.y, box_limit_y) * step(-1.0, WORLD_POSITION.y);
	float x_limit = step(box_limit_x, WORLD_POSITION.x) + pow(smoothstep(box_limit_x-100.0,box_limit_x, WORLD_POSITION.x),2);
	float noise = texture(noise_text, WORLD_POSITION.xz * noise_scale + move_uv).r;
	DENSITY = mix(1.0, noise, (WORLD_POSITION.y)/box_limit_y * flatness );
	DENSITY *= x_limit * height_limit * density;
	vec3 col = texture(grad_text, vec2(map(DENSITY,0,density,0,box_limit_y), 0.5)).rgb;
	ALBEDO = vec3(col);
}
