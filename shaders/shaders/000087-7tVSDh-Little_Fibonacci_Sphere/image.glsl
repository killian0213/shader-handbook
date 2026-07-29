// Image (image) — Little Fibonacci Sphere by Xor
// https://www.shadertoy.com/view/7tVSDh

//twigl: https://t.co/Eqa9WrS2Yg
//tweet: https://twitter.com/XorDev/status/1475524322785640455

//Thanks to Fabrice for some tricks and ideas.
void mainImage( out vec4 O, vec2 I)
{
    //Clear base color.
    O-=O;
    
    //Iterate though 400 points and add them to the output color.
    for(float i=-1.; i<1.; i+=6e-3)
    {
        vec2 r = iResolution.xy, //A shortened resolution variable, because we use it twice.
        p = cos(i*4e2+iTime+vec2(0,11))*sqrt(1.-i*i);  //Rotate and scale xy coordinates.
        O += (cos(i+vec4(0,2,4,6))+1.)*(1.-p.y) /      //Color and brightness.
        dot(p=(I+I-r)/r.y+vec2(p.x,i)/(p.y+2.),p)/3e4; //Project light point.
    }
}

// Original (230 chars):
/*
void mainImage( out vec4 O, vec2 I)
{
    vec2 r = iResolution.xy, //A shortened resolution variable, because we use it twice.
    u = I+I-r,               //Centered pixel coornates.
    p,c;                     //Rotated point and 2D point coordinates.
    
    O-=O; //Clear base color.
    //Iterate though 400 points and add them to the output color.
    for(float a,i;i++<4e2; O += (cos(i+vec4(0,2,4,0))+1.)/dot(c,c)*(1.-p.y)/3e4)
        a = i/2e2-1.,                                  //Signed value from -1 to 1.
        p = cos(i*2.4+iTime+vec2(0,11))*sqrt(1.-a*a),  //Rotate and scale xy coordinates.
        c = u/r.y+vec2(p.x,a)/(p.y+2.);                //Project into 3D.
}
*/