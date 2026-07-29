// Buffer A (buffer) — Dust [417 Chars] by Xor
// https://www.shadertoy.com/view/cdG3Wd

/*
    "Dust" by @XorDev

    The concept here is similar to "Radioactive":
    https://shadertoy.com/view/mdG3Wy

    The difference is, after 100 raymarch iterations, the ray gets
    set to a random point between the intersection and the camera.
    Then the ray direction is set to vec3(1,1,1).
    The finally raymarched depth determines where to shade.

    -7 Thanks to FabriceNeyret2
    -8 Thanks coyote
*/

M,

    //Camera ray direction (+z forward, +y up)
    d = vec3(I+I,r)-r,
    //Raymarch position, camera position, transformation vector, and step size
    p = iTime/r/.3-6., c=p, v, s;
    
    //Initialize fractal, loop number, and raymarcher iterators
    float i, n=1e2, l=-n;
    //Rotate pitch down 0.3 radians and raymarch loop
    for(d.yz*=R-.3)); l++<n; )
    //Fractal loop
    for(s=v=p+=d/length(d)*s.y, i=n; i>.1; i*=.4)
        //Rotate octave 2 radians
        v.xz*=R+2.)),
        //Subtract cube SDFs
        s = max(s,min(min(v=i*.8-abs(mod(v,i+i)-i),v.x),v.z)),
        //After 100 iterations
        l==0.? 
        //Pick a random point between the camera intersection
        //p += (c-p)/exp(texture(iChannel1,I/1024.).r*2e1),
        //Alternative animated variant:
        p += (c-p)/exp(texture(iChannel1,I/1024.+iTime).r*2e1),
        //Raymarch in vec3(1,1,1) direction
        d /= d,
        //Clear color
        O *= l :
        //Add raymarch step distance
        O += s.y;
    
    
    //Basic aberration effect
    O.rg = T.gb;
    //Alternative variant
    //O = T*.5+clamp(O,0.,.5);
}