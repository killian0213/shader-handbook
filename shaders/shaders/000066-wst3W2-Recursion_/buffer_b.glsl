// Buffer B (buffer) — Recursion! by AntoineC
// https://www.shadertoy.com/view/wst3W2

float sdBox(vec2 p, vec2 s)
{
    vec2 d = abs(p-s)-s;
    return length(max(d,vec2(0))) + min(max(d.x,d.y),0.0);
}

void mainImage( out vec4 o, in vec2 v )
{
    float dv = 1072. / iResolution.x;
    v *= dv;

    vec2 s = vec2(1072.0, 603.);
    vec3 c = texture(iChannel0, v/s).rgb;
    float f = 2.0;
    c *= 0.5 +0.5*smoothstep(0.0, f+dv, abs(sdBox(v, 0.5*s)));
    
    float ratio = 501.0/s.x;
    v -= vec2(35., 263.);
    for(float r=0.; r<floor(4.0*(1.0+cos(3.14159+0.5*iTime))); r++)
    {
        s *= ratio;
        if(v.x>=0.0 && v.x<s.x && v.y>=0.0 && v.y<s.y)
        {
            c = texture(iChannel0, v/s).rgb;
            c *= 0.5 +0.5*smoothstep(0.0, f+dv, abs(sdBox(v, 0.5*s)));
        }
        v -= vec2(35., 263.)*pow(ratio, r+1.0);
        f *= ratio;
    }

    o = vec4(c,1.0);
}