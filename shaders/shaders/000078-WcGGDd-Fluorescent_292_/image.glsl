// Image (image) — Fluorescent [292] by Xor
// https://www.shadertoy.com/view/WcGGDd

/*
    "Fluorescent" by @XorDev
    
    See the original
    https://x.com/XorDev/status/1928504290290635042

    -4 Thanks to FabriceNeyret2
*/

void mainImage(out vec4 O, vec2 I)
{
    //Time for animation
    float t = iTime,
    //Raymarch iterator
    i,
    //Raymarch depth
    z,
    //Light beams
    b,
    //Distance to center
    l;
    //Clear fragColor and raymarch 60 steps
    for(O *= i; i++ < 60.; )
    {
        //Compute raymarch sample position
        vec3 p = z* normalize( vec3(I+I,0) - iResolution.xyx );
        //Rotate pitch upward
        p.yz *= .1*mat2(8,-6,6,8);
        //Move camera back 80 units
        p.z += 80.;
        //Distance to origin
        l = length(p)*.1;
        //Step distance to hollow sphere
        z += 1. + abs(l-1.2);
        //Break into bars using projected, irregular gyroid
        b = dot( cos( p/++l - t ), sin(p/l/.4 + t ).yzx );
        //Color waves
        O += ( 1. + cos( tanh(l-6.)*6. - vec4(2,3,4,0) ) )
             *b*b*b*b / z;
    }
    //Tanh tonemapping
    //https://www.shadertoy.com/view/ms3BD7
    O = tanh(O/2.);
}
//Original [296]
/*
void mainImage(out vec4 O, vec2 I)
{
    //Time for animation
    float t = iTime,
    //Raymarch iterator
    i,
    //Raymarch depth
    z,
    //Light beams
    b,
    //Distance to center
    l;
    //Clear fragColor and raymarch 60 steps
    for(O *= i; i++<6e1; )
    {
        //Compute raymarch sample position
        vec3 p = z*normalize(vec3(I+I,0)-iResolution.xyx);
        //Rotate pitch upward
        p.yz *= .1*mat2(8,-6,6,8);
        //Move camera back 8 units
        p.z += 8.;
        //Distance to origin
        l = length(p);
        //Step distance to hollow sphere
        z += .1+.1*abs(l-1.2);
        
        //Break into bars using projected, irregular gyroid
        b = dot(cos(p/++l/.1-t), sin(p/l/.04+t).yzx);
        //Color waves
        O += (cos(tanh(l-6.)*6.-vec4(2,3,4,0))+1.)*b*b*b*b/z;
    }
    //Tanh tonemapping
    //https://www.shadertoy.com/view/ms3BD7
    O = tanh(O/2e1);
}
*/