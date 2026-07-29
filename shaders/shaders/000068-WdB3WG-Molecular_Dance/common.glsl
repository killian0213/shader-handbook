// Common (common) — Molecular Dance by wyatt
// https://www.shadertoy.com/view/WdB3WG

// charge force range, collision force range ,0,0 does nothing
#define FORCE_RANGE vec4(   25, 2.5,     0,0)

// how many blur iterations
#define BLUR_DEPTH 40.
// multiplies the force per frame
#define SPEED 2.
// restart after changing. Smaller number -> more particles
#define SEPARATION 13.