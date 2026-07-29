// Common (common) — Ohanami Stipple by fizzer
// https://www.shadertoy.com/view/4tVcWR

float hash(float n)
{
    return fract(sin(n)*43758.5453);
}

float noise(vec2 p)
{
    return hash(p.x + p.y*57.0);
}

float valnoise(vec2 p)
{
    vec2 c=floor(p);
    vec2 f=smoothstep(0.,1.,fract(p));
    return mix (mix(noise(c+vec2(0,0)), noise(c+vec2(1,0)), f.x),
                mix(noise(c+vec2(0,1)), noise(c+vec2(1,1)), f.x), f.y);
}