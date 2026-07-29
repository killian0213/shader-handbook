// Image (image) — Cube House by mhnewman
// https://www.shadertoy.com/view/3XSXDm

// Monte carlo ambient occlusion, depth of field, anti aliasing,
// and reflection using accumulation buffer.
//
// Based on www.shadertoy.com/view/llccD2

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = 1.3 * pow(texture(iChannel0, fragCoord / iResolution.xy), vec4(0.65));
    
#if SCENE_TIME > 0 && !defined SCREENSHOT
    float t = fract(iTime / float(SCENE_TIME));
    fragColor *= (1.0 - exp(-80.0 * t)) * (1.0 - exp(-80.0 * (1.0 - t)));
#endif
} 