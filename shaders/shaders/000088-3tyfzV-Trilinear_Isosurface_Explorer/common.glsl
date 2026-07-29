// Common (common) — Trilinear Isosurface Explorer by oneshade
// https://www.shadertoy.com/view/3tyfzV

// Offset of the 3D render
#define renderOffs vec2(0.3, 0.0)

// Mouse selection radius
#define selectRadius 0.05

// Slider range
#define sliderMin -5.0
#define sliderMax 5.0

// Slider length
#define sliderLen 0.5

// Slider positions (top to bottom)
const vec2[] sliders = vec2[8](vec2(-0.55,  0.35),
                               vec2(-0.55,  0.25),
                               vec2(-0.55,  0.15),
                               vec2(-0.55,  0.05),
                               vec2(-0.55, -0.05),
                               vec2(-0.55, -0.15),
                               vec2(-0.55, -0.25),
                               vec2(-0.55, -0.35));