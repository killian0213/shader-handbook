// Common (common) — Jasz Universe by jaszunio15
// https://www.shadertoy.com/view/wsSGRd

//Generation settings
#define NOISE_ALPHA_MULTIPLIER 0.5
#define NOISE_SIZE_MULTIPLIER 1.8

//Uncomment to disable fog shape animation over time
#define MUTATE_SHAPE

//Rendering settings

//Uncoment to get high quality version (if you have good PC)
//#define HIGH_QUALITY

#ifdef HIGH_QUALITY
    #define RAYS_COUNT 150
    #define STEP_MODIFIER 1.007
    #define SHARPNESS 0.009
	#define NOISE_LAYERS_COUNT 5.0
	#define JITTERING 0.03
#else
    #define RAYS_COUNT 54
    #define STEP_MODIFIER 1.0175
    #define SHARPNESS 0.02
	#define NOISE_LAYERS_COUNT 4.0
	#define JITTERING 0.08
#endif

#define DITHER 0.3
#define NEAR_PLANE 0.6
#define RENDER_DISTANCE 2.0

//Colors
#define BRIGHTNESS 5.0
#define COLOR1 vec3(0.0, 1.0, 1.0)
#define COLOR2 vec3(1.0, 0.0, 0.9)

//Camera and time
#define TIME_SCALE 1.0
#define CAMERA_SPEED 0.04
#define CAMERA_ROTATION_SPEED 0.06
#define FOG_CHANGE_SPEED 0.02