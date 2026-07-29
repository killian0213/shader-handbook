// Image (image) — Corridor [334] by Xor
// https://www.shadertoy.com/view/tf33Wf

/*
    "Corridor" by @XorDev
    
    https://x.com/XorDev/status/1923882930834751520
*/
void mainImage(out vec4 O, vec2 I)
{
    //Time for scrolling
    float t = iTime,
    //Raymarch iterator
    i,
    //Raymarch step distance
    d,
    //Raymarch depth
    z;
    //Clear fragColor and raymarch 30 steps
    for(O *= i; i++<3e1;)
    {
        //Compute ray direction 
        vec3 r = normalize(vec3(I+I,0)-iResolution.xyy),
        //Raymarch sample position
        p = z*r,
        //Raytraced wall coordinates
        w = abs(r);
        //Compute distance to walls
        w /= max(w.x,w.y);
        //Scroll forward
        w.z += t;
        p.z -= t;
        
        //Shift camera
        r = ++p;
        //Step forward
        z += d = length(
        //Reflected coordinates
            (p.xy=abs(mod(p.xy-2.,4.)-2.))-1.
            //Line position
            +cos(p.z/vec2(3.1,2))) +
            //Reflection fall off
            .1 * length(p-r) *
            //Reflectivity blocks
            exp(dot(cos(ceil(w/=.3)),sin(w/.6).yzx));
        
        //Add coloring
        O.rgb += (cos(p)+1.4) / d / z;
    }
    //Tanh tonemapping
    O = tanh(O/4e1);
}