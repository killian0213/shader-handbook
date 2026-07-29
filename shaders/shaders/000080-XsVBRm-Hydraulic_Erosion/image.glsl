// Image (image) — Hydraulic Erosion by davidar
// https://www.shadertoy.com/view/XsVBRm

#define PI 3.14159265359

void mainImage( out vec4 r, in vec2 p ) {
    float y = buf(p).r;
    vec2 grad = vec2(buf(p+E).r - buf(p+W).r, buf(p+N).r - buf(p+S).r);
    r = vec4(0.34, 0.52, 0.29, 1);
    r = mix(r, vec4(0.88, 0.85, 0.63, 1), smoothstep(0.500, 0.625, y));
	r = mix(r, vec4(0.93, 0.72, 0.40, 1), smoothstep(0.625, 0.750, y));
	r = mix(r, vec4(0.70, 0.60, 0.53, 1), smoothstep(0.750, 0.875, y));
	r = mix(r, vec4(1,1,1,1), smoothstep(0.875, 1., y));
    r.rgb *= 0.75 + 0.25 * cos(atan(grad.y, grad.x) + 0.25*PI);
    if (y < 0.5) r = mix(r, vec4(0.73, 0.80, 0.97, 1), 0.5);
}
