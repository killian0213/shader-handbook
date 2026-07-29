// Image (image) — Gemmarium [commented] by Jaenam
// https://www.shadertoy.com/view/WftcWs

/*================================
=           Gemmarium            =
=         Author: Jaenam         =
================================*/
// Date:    2025-11-28
// License: Creative Commons (CC BY-NC-SA 4.0)

//Twigl (golfed) version --> https://x.com/Jaenam97/status/1994387530024718563?s=20
void mainImage( out vec4 O, vec2 I )
{   
    //Raymarch iterator
    float i,
    //Depth
    d,
    //Raymarch step distance
    s,
    // SDF
    sd,
    // Noise iterator
    n,
    // Time
    t = iTime,
    // Brightness
    m = 1.,
    //Orb
    l;

    // 3D sample point
    vec3 p,
    k, r = iResolution;

    // Rotation matrix by pi/4
    mat2 R = mat2(cos(sin(t/2.)*.785 +vec4(0,33,11,0)));

    // Raymarch loop. Clear fragColor and raymarch 100 steps
    for(O*=i; i++<1e2;){

        //Raymarch sample point --> scaled uvs + camera depth
        p = vec3((I+I-r.xy)/r.y, d-10.);    
        
        //Orb
        l = length(p.xy-vec2(.2+sin(t)/4.,.3+sin(t+t)/6.));
        
        p.xy*=d;
        
        //Improving performance
        if(abs(p.x)>6.) break;

        //Rotate about y-axis
        p.xz *= R;

        //Mirrored floor hack
        if(p.y < -6.3) {
            //Flip about y and shift
            p.y = -p.y-9.;
            //Use half the brightness
            m = .5;
        }

        //Save sample point
        k=p;
        //Scale
        p*=.5;
        //Turbulence loop (3D noise)
        for(n = .01; n < 1.; n += n){

            //Accumulate noise on p.y 
            p.y += .9+abs(dot(sin(p.x + 2.*t+p/n),  .2+p-p )) * n;
        }
        //SDF mix
        sd = mix(
                 //Bottom half texture
                 sin(length(ceil(k*8.).x+k)), 
                 //Upper half water/clouds noise + orb
                 mix(sin(length(p)-.2),l,.3-l),
                 //Blend
                 smoothstep(5.5, 6., p.y));

        //Step distance to object
        d += s =.012+.08*abs(max(sd,length(k)-5.)-i/150.);
        
        // Uncomment section for ocean variant
        //vec4 ir = sin(vec4(1,2,3,1)+i*.5)*1.5/s + vec4(1,2,3,1)*.04/l; //iridescence + orb
        //vec4 c = vec4(1,2,3,1) * .12/s; //water 

        //O += max(mix(ir,mix(c, ir, smoothstep(7.5, 8.5, p.y)),smoothstep(5.2, 6.5, p.y)), -length(k*k));
        
        //Color accumulation, using i iterator for iridescence. Attenuating with distance s and shading.
        O += max(sin(vec4(1,2,3,1)+i*.5)*1.5/s+vec4(1,2,3,1)*.04/l,-length(k*k));

    }
    //Tanh tonemap and brightness multiplier
    O = tanh(O*O/8e5)*m;  
}
