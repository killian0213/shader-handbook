// Buffer A (buffer) — Radioactive [466 Chars] by Xor
// https://www.shadertoy.com/view/mdG3Wy

/*
    "Radioactive" by @XorDev

    A little raymarch loop that switches to a random direction after 100 iterations
    The distance traveled in this direction determines if the pixel is lit or not.
    This is a simple way of simulates AO in one pass. I use the backbuffer for TAA.
*/

M,
    //Transformed vector for fractal
    v,
    //Camera position (approximately 0,0,1)
    p = 1./r,
    //Camera ray direction (+z forward, +y up)
    d = vec3(I+I-r.xy, r);
    
    //Clear fragColor
    O *= 0.;
    
    //Initialize raymarch step distance, fractal and raymarcher iterators
    float s, i, l=0.,
    //Reset timer every 4 seconds
    t = modf(iTime/4., s);
    //Rotate pitch down 0.5 radians
    d.yz *= R-.5));
    
    //Scroll camera forward and raymarch loop
    for(p *= s/.2; l++<2e2; p += d/length(d)*s)
    //Fractal loop
    for(v=p, s=v.y, i=7.; i>.001; i*=.5)
        //Rotate approximately 45 degrees
        v.xz *= R+.8)),
        //Subtract cubes SDFs
        s = max(s,min(min(v=i*.8-abs(mod(v,i+i)-i), v.y).x, v.z)),
        //After 100 iterations (AO pass) add raymarch bias
        l>1e2 ? s += 1e-5,
        //Randomize ray direction for AO 
        d = texture(iChannel1, t*r.xy + I/1e3).rgb-.5,
        //Add color
        O.bgr += s * (d+.3)/1e7 : d;
    
    //Blend current frame with backbuffer
    O = mix(T, clamp(O,0.,3.), .1/++t);
}