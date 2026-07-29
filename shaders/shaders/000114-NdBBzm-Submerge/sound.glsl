// Sound (sound) — Submerge by Xor
// https://www.shadertoy.com/view/NdBBzm

//Rumble
float value(float p)
{
    float f = floor(p);
    float s = p-f;
    s *= s * (3.0 - 2.0 * s);
    vec2 o = vec2(0, 1);
    
    return texture(iChannel0,vec2(f+s+0.5,0.5)/1024.).r-0.5;
}
vec2 mainSound( int samp, float time )
{
    return vec2(sin(time*280.0)*0.5+value(time*199.0))*0.4;
}