// Image (image) — Paradise 3 [325] by Xor
// https://www.shadertoy.com/view/WcsyDM

/*
    "Paradise 3" by @XorDev

    https://x.com/XorDev/status/1958193141573353887
    
    <512 playlist:
    https://www.shadertoy.com/playlist/N3SyzR


    Twigl code:
    vec3 c,p;for(float i,z,f;i++<5e1;p+=c,z+=f=length(cos(p/p.y)/8.+sin(p.y/7.)*.4),
    o+=(cos(c.y/14.-vec4(7,2,3,0))+1.)*z*z/(.9+p.y*f)/max(length(c.xy/z-.6)-.1,.1))
    for(p=z*(FC.rgb/.4-r.xyy)/r.y,p.y=abs(p.y+2.),c=p,p.x*=f=.2;f++<9.;
    p+=cos(p.yzx*f-t/4.)/f);o=tanh(o/1e4);

*/

void mainImage(out vec4 O, vec2 I)
{
    //Raymarch depth
    float z,
    //Cloud distance
    f,
    //Raymarch iterator
    i;
    
    //Resolution for scaling
    vec3 r = iResolution,
    //Original coordinates
    c,
    //Turbulent coordinates
    p;
    
    //Clear fragcolor and raymarch 50 steps
    for(O*=i; i++<5e1;
        //Add original coordinates for smoothness
        p += c,
        //Step forward with waves for clouds/water
        z += f = length(cos(p/p.y)/8. + sin(p.y/7.)*.4),
        //Horizon coloring
        O += (cos(c.y/14.-vec4(7,2,3,0))+1.)
        //Shade clouds and add sun
        *z*z/(.9+p.y*f) / max(length(c.xy/z-.6)-.1,.1))
        //Turbulence distortion loop
        //https://mini.gmshaders.com/p/turbulence
        for(
            //Compute raymarch sample point
            p=z*(vec3(I,0)/.4-r.xyy)/r.y,
            //Mirror vertically
            p.y=abs(p.y+2.),
            //Save unaltered coordinates
            c=p,
            //Stretch and loop through frequencies
            p.x*=f=.2;f++<9.;
                //Add turbulence waves
                p+=cos(p.yzx*f-iTime/4.)/f);
    //Tanh tonemapping
    //https://mini.gmshaders.com/p/tonemaps
    O = tanh(O/1e4);
}