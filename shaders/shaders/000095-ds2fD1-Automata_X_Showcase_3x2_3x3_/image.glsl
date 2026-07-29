// Image (image) — Automata X Showcase 3x2 (3x3) by misol101
// https://www.shadertoy.com/view/ds2fD1

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float ix = texelFetch(iChannel1, ivec2(0,0), 0 ).x;
    int mono = int(texelFetch(iChannel1, ivec2(3,0), 0 ).x);
    int aa = 1-int(texelFetch(iChannel1, ivec2(5,0), 0 ).x);
    vec2 ppos = texelFetch(iChannel1, ivec2(10,0), 0 ).xy;

    float mx= iMouse.x / iResolution.x;
    vec2 mid = iResolution.xy / 2.;
    float mmul = 1.-mx;
    fragCoord = mid - (mid*mmul-fragCoord*mmul) + ppos;

    vec4 val = vec4(0.);
    int am=0, ap=aa, j=0;
    for (int j = -am; j <= ap; j++)
        for (int i = -am; i <= ap; i++)
            val += texelFetch( iChannel0, ivec2(int(fragCoord.x)+i,int(fragCoord.y)+j), 0 );
    float n=float((am+ap+1));
    if (am+ap > 0) val /= n*n-2.;
    
    if (aa == 0) val/=0.6;
    
    if (mono == 0) {
        fragColor = val;
    } else {
        float v=(1./liveval)*val.w;
        fragColor = vec4( v*0.9, v*0.95, v, 1.0 );
    }
}
