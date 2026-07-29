// Image (image) — Submerge 3 by Xor
// https://www.shadertoy.com/view/flBcD3

//Bokeh pass

#define T texture(iChannel0, I/r
void mainImage(out vec4 O, vec2 I)
{
    vec2 r = iResolution.xy,
    p = vec2(T).a*r.y/8e2,O-=O);
    for(float i=1.; i<16.; i+=1./i)
    {
        p *= -mat2(.7374, .6755, -.6755, .7374);
        O += exp(vec4(1, T+p*i/r))/.1);
    }
    O = log(O.gbar*.1);O /= O.a;
    O += T,.5-ceil(log(.5/r.y)))-.1;
}