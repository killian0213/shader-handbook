// Buffer A (buffer) — Minimal Fluidish Simulacre by leon
// https://www.shadertoy.com/view/7dGfWw


// Dave Hoskins https://www.shadertoy.com/view/4djSRW
float hash13(vec3 p3)
{
	p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

#define T(uv) texture(iChannel0,uv).a

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // the salt of life
    float noise = hash13(vec3(fragCoord, iFrame));
    
    // coordinates
    vec2 uv = fragCoord/iResolution.xy;

    // random spawn
    float height = clamp(.001/noise,0.,1.);
    
    // mouse interaction
    if (iMouse.z > 0.)
        height += clamp(.02/length(uv-iMouse.xy/iResolution.xy), 0., 1.);
    
    // move uv toward slope direction
    vec2 e = vec2(.2*noise,0);
    vec2 normal = normalize(vec2(T(uv+e.xy)-T(uv-e.xy),T(uv+e.yx)-T(uv-e.yx)));
    uv += 5. * normal * noise / iResolution.xy;

    // accumulate and fade away
    height = max(height, texture(iChannel0, uv).a - .005*noise);
    
    // lighting
    e = vec2(2./iResolution.y, 0);
    normal = normalize(vec2(T(uv+e.xy)-T(uv-e.xy),T(uv+e.yx)-T(uv-e.yx)));
    float light = dot(normal, vec2(0,-1))*.5+.5;
    
    fragColor = vec4(vec3(light*height), height);
}