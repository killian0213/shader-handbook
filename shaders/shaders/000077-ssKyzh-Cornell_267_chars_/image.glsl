// Image (image) — Cornell [267 chars] by Xor
// https://www.shadertoy.com/view/ssKyzh

/*
    "Cornell [267 chars]" by @XorDev
    
    Just a little handwritten cornell box

    Tweet: twitter.com/XorDev/status/1533484050345869312
    Twigl: t.co/cyZANgnYay
    
    <300 chars playlist: https://www.shadertoy.com/playlist/fXlGDN
*/

void mainImage(out vec4 O, vec2 I)
{
    //Resolution for scaling
    vec3 r = iResolution,
    //Camera Position (approximately vec3(0,0,2.5))
    p = 2.5/r,
    //Absolute position
    a;
    
    //Iterate 40 times and set color
    for(;r.z++<4e1; O = 2.+vec4(p.x,-p.x,a))
        //Raymarch with box and sphere SDF
        p += vec3(I+I-r.xy,-r)/r.x * min(1.-max(a=abs(p),max(a.y,-p.z)).x, length(p+.5)-.5);
        
    //Fun mode:
    //O = 2.+p.x*sign(sin(iTime+vec4(0,2,4,0)));
    //Top light
    O = .01/length(max(a.xz/.2-p.y,0.))+
    //Bounce lighting
    .8/O+
    //Wall coloring
    3e1* min(3.-O, .01);
    //AO and shading
    O /= dot(p,p)+.4/dot(p+.5,p+.8);
}