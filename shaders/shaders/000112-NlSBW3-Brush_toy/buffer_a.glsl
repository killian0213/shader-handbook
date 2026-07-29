// Buffer A (buffer) — Brush toy by leon
// https://www.shadertoy.com/view/NlSBW3


// Brush toy by Leon Denise 2022-05-17

// The painting pass is using FBM noise to simulate brush strokes
// The curve was generated with a discrete Fourier Transform,
// from https://www.shadertoy.com/view/3ljXWK

// Frame buffer sampling get offset from brush motion,
// and the mouse also interact with the buffer.

const float speed = .01;
const float scale = 0.8;
const float falloff = 2.;

vec2 mouse;

// fractal brownian motion (layers of multi scale noise)
vec3 fbm(vec3 p)
{
    vec3 result = vec3(0);
    float amplitude = 0.5;
    for (float index = 0.; index < 3.; ++index)
    {
        result += (texture(iChannel0, p/amplitude).xyz) * amplitude;
        amplitude /= falloff;
    }
    return result;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

    // coordinates
    vec2 uv = (fragCoord.xy - iResolution.xy / 2.)/iResolution.y;
    mouse = (iMouse.xy - iResolution.xy / 2.)/iResolution.y;
    
    // dithering
    vec3 dither = texture(iChannel2, fragCoord.xy / 1024.).rgb;
    
    // sample curve position
    float speed = 1.;
    float t = -iTime*speed+dither.x*.01;
    vec2 current = cookie(t);
    
    // velocity from current and next curve position
    vec2 next = cookie(t+.01);
    vec2 velocity = normalize(next-current);
    
    // move brush cursor along curve
    vec2 pos = uv-current*1.6;
    
    float paint = fbm(vec3(pos, 0.) * scale).x;
    
    // brush range
    float brush = smoothstep(.3,.0,length(pos));
    paint *= brush;
    
    // add circle shape to buffer
    paint += smoothstep(.05, .0, length(pos));
    
    // motion mask
    float push = smoothstep(.3, .5, paint);
    push *= smoothstep(.4, 1., brush);
    
    // direction and strength
    vec2 offset = 10.*push*velocity/iResolution.xy;
    
    // mouse interaction
    vec4 data = texture(iChannel1, vec2(0,0));
    bool wasNotPressing = data.w < 0.5;
    if (wasNotPressing && iMouse.z > .5) data.z = 0.;
    else data.z += iTimeDelta;
    data.z = clamp(data.z, 0., 1.);
    vec2 mousePrevious = data.xy;
    float erase = 0.;
    if (iMouse.z > 0.5)
    {
        uv = (fragCoord.xy - iResolution.xy / 2.)/iResolution.y;
        float mask = fbm(vec3(uv-mouse, 0.) * scale * .5).x;
        mask = smoothstep(.3,.6,mask);
        push = smoothstep(.2,.0,length(uv-mouse));
        push *= mask;
        vec2 dir = normalize(mousePrevious-mouse+.001);
        float fadeIn = smoothstep(.0, .5, data.z);
        float fadeInAndOut = sin(fadeIn*3.1415);
        offset += 10.*push*normalize(mouse-uv)/iResolution.xy*fadeInAndOut;
        erase = (.001 + .01*(1.-fadeIn)) * push;
        push *= 500.*length(mousePrevious-mouse)*fadeIn;
        offset += push*dir/iResolution.xy;
    }
    
    // sample frame buffer with motion
    uv = fragCoord.xy / iResolution.xy;
    vec4 frame = texture(iChannel1, uv + offset);
    
    // temporal fading buffer
    paint = max(paint, frame.x - .0005 - erase);
    
    // print result
    fragColor = vec4(clamp(paint, 0., 1.));
    
    // save mouse position for next frame
    if (fragCoord.x < 1. && fragCoord.y < 1.) fragColor = vec4(mouse, data.z, iMouse.z);
}