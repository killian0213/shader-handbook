// Image (image) — Smooth Mouse Drawing by fad
// https://www.shadertoy.com/view/dldXR7

// A recreation of https://lazybrush.dulnan.net/

// Controls:
// - Mouse to draw
// - L: toggle between quadratic bezier curves and line segments
// - S: toggle SDF visualisation
// - P: toggle mouse points

// Settings in Buffer B

// Modified sdBezier() function originally from
// Quadratic Bezier SDF With L2 - Envy24
// https://www.shadertoy.com/view/7sGyWd

#define LINE_WIDTH (iResolution.y * 0.01)
#define POINT_RADIUS (iResolution.y * 0.007)

const int KEY_L = 76;
const int KEY_S = 83;
const int KEY_P = 80;

bool keyToggled(int keyCode) {
    return texelFetch(iChannel1, ivec2(keyCode, 2), 0).r > 0.0;
}

vec4 blendOver(vec4 front, vec4 back) {
    float a = front.a + back.a * (1.0 - front.a);
    return a > 0.0
        ? vec4((front.rgb * front.a + back.rgb * back.a * (1.0 - front.a)) / a , a)
        : vec4(0.0);
}

void blendInto(inout vec4 dst, vec4 src) {
    dst = blendOver(src, dst);
}

void mainImage(out vec4 fragColor, vec2 fragCoord) {
    fragColor = vec4(1.0);

    float qd = texture(iChannel0, fragCoord / iResolution.xy).x;
    float ld = texture(iChannel0, fragCoord / iResolution.xy).y;
    float pd = texture(iChannel0, fragCoord / iResolution.xy).z;
    float sd = (keyToggled(KEY_L) ? ld : qd) - LINE_WIDTH / 2.0;
    
    blendInto(fragColor, vec4(0.0, 0.0, 0.0, clamp(0.5 - sd, 0.0, 1.0)));
    
    if (!keyToggled(KEY_S)) {
        float spacing = iResolution.y * 0.02;
        float thickness = max(iResolution.y * 0.002, 1.0);
        float opacity = clamp(
            0.5 + 0.5 * thickness - 
            abs(mod(sd - (spacing - thickness) * 0.5, spacing) - spacing * 0.5), 
            0.0, 1.0
        ) * 0.5 * exp(-sd / iResolution.y * 8.0);
        blendInto(fragColor, vec4(0.0, 0.0, 0.0, opacity));
    }
    
    if (keyToggled(KEY_P)) {
        blendInto(fragColor, vec4(1.0, 0.0, 0.0, clamp(POINT_RADIUS - pd + 0.5, 0.0, 1.0)));
    }
}