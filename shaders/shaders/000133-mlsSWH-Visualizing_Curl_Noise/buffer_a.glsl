// Buffer A (buffer) — Visualizing Curl Noise by Shane
// https://www.shadertoy.com/view/mlsSWH


// Integrate more frames and increase the swirl length.
//#define LONGER

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Cheap vec3 to vec3 hash. I wrote this one. It's much faster than others, but I don't trust
// it over large values.
vec3 hash33(vec3 p){ 
    
    float n = sin(dot(p, vec3(27, 57, 111)));   
    return fract(vec3(2097152, 262144, 32768)*n)*2. - 1.; 
 
}

/*
// Hastily modified "uint" based hash function. It's a mixture of
// IQ and Fabrice's versions. It should be more reliable, but I
// haven't tested it for speed inside a raymarching loop, so I'll
// leave the old function (above) in place for now.
//
// IQ's hash function here: https://www.shadertoy.com/view/XlXcW4 
//
// IQ's uvec3 to vec3 hash.
vec3 hash33(vec3 f){

    //const uint k = 1664525U; // Numerical Recipes.
    const uint k = 20170906U; // Today's date -- Use three days ago's date if you want a prime.

    uvec3 x = floatBitsToUint(f);
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    
    return vec3(x)*(2./float(0xffffffffU)) - 1.;
}
*/

// Cheap, streamlined 3D Simplex noise... of sorts. I cut a few corners, so it's not perfect, but it's
// artifact free and does the job. I gave it a different name, so that it wouldn't be mistaken for
// the real thing -- I'll rewrite it at some stage. By the way, Stefan Gustavson has an account on
// Shadertoy, if you feel like tracking that down.
// 
// Credits: Ken Perlin, the inventor of Simplex noise, of course. Stefan Gustavson's paper - 
// "Simplex Noise Demystified," IQ, other "ShaderToy.com" people, etc.
float tetraNoise(in vec3 p){

    // Skewing the cubic grid, then determining the first vertex and fractional position.
    vec3 i = floor(p + dot(p, vec3(1./3.)) );  p -= i - dot(i, vec3(1./6.));
    
    // Breaking the skewed cube into tetrahedra with partitioning planes, then determining which side of 
    // the intersecting planes the skewed point is on. Ie: Determining which tetrahedron the point is in.
    vec3 i1 = step(p.yzx, p), i2 = max(i1, 1. - i1.zxy); i1 = min(i1, 1. - i1.zxy);    
    
    // Using the above to calculate the other three vertices -- Now we have all four tetrahedral vertices.
    // Technically, these are the vectors from "p" to the vertices, but you know what I mean. :)
    vec3 p1 = p - i1 + 1./6., p2 = p - i2 + 1./3., p3 = p - .5;
  

    // 3D simplex falloff - based on the squared distance from the fractional position "p" within the 
    // tetrahedron to the four vertex points of the tetrahedron. 
    vec4 v = max(.5 - vec4(dot(p, p), dot(p1, p1), dot(p2, p2), dot(p3, p3)), 0.);
     
    // Dotting the fractional position with a random vector, generated for each corner, in order to 
    // determine the weighted contribution distribution... Kind of. Just for the record, you can do a 
    // non-gradient, value version that works almost as well.
    vec4 d = vec4(dot(p, hash33(i)), dot(p1, hash33(i + i1)), 
                  dot(p2, hash33(i + i2)), dot(p3, hash33(i + 1.)));
    
     
    // Simplex noise... Not really, but close enough. :)
    return clamp(dot(d, v*v*v*8.)*1.732 + .5, 0., 1.); // Not sure if clamping is necessary.
 
}


// Layered noise function.
float fBm(in vec3 p){
    
    // Rewriting the fBm function to lower compile times.
    float n = 0., sum = 0., a = 1.;
    vec3 offs = vec3(0, .23, .07);
    for(int i = min(0, iFrame); i<3; i++){
    
        n += tetraNoise(p*exp2(float(i)) + offs.x)*a;
        sum += a;
        a *= .5;
        offs = offs.yzx;
    
    }
    
    return n/sum;
    
    //return (tetraNoise(p)*4. + tetraNoise(p*2. + .23)*2. + tetraNoise(p*4. + .07))/7.;
    //return (tetraNoise(p)*2. + tetraNoise(p*2. + .23)*1.)/3.;
}
 
 
// Flow function.
float flow(vec3 p){

   // Emulating moving toward the surface of a sphere, or landing on 
   // planet Cartoon Jupiter, if you prefer. :)
 
   p.z -= dot(p, p)*.5; 
   p.xy *= rot2(iTime/16.);
   #ifdef LONGER
   // Longer swirl strands get too tight if you slice through
   // Z too quickly, so it needs slowing down.
   p.z += .1*iTime;
   #else
   p.z += .15*iTime;
   #endif
   
   // You can put whatever function you want here, but simplex noise has nice
   // animation qualities, so I've used that. At some stage, I'll try other 
   // things. By the way, if you have any suggestions, feel free to let me know.
   return fBm(p*1.5);
   
   
   /*
   // Failed angular noise experiment.
   p += vec3(.0, .0, .2)*iTime/3.;
   return fBm(p*1.5*2.)*2. - 1.;
   */
  
}

 
 

void mainImage(out vec4 fragColor, in vec2 fragCoord){

   
    // Coordinates.
    vec2 iR = iResolution.xy;
    vec2 uv = fragCoord/iR; // Window coordinates.      
    vec2 uva = (fragCoord - iR/2.)/iR.y; // Centered, aspect correct coordinates.
  
    // Taking the curl of the flow function. Intuitively, the perpendicular
    // vector to the tangent vector "v" is simply, "vec2(v.y, -v.x)", and the
    // curl is analogous to the gradient equivalent, "vec2(df/dy, -df/dx)".
    vec2 e = vec2(.005, 0);
    vec3 p = vec3(uva, 0);//vec3(p, length(p)*.5);
    float dx = (flow(p + e.xyy) - flow(p - e.xyy))/(2.*e.x);
    float dy = (flow(p + e.yxy) - flow(p - e.yxy))/(2.*e.x);
    vec2 curl = vec2(dy, -dx);
     
    // 3D curl. Not used here.
    //float dz = (noise(p + e.yyx) - noise(p - e.yyx))/(2.*e.x);
    //vec3 curl = vec3(dz - dy, dx - dz, dy - dx);
 
/*
    // Angular offsetting... Not right for this example.
    vec2 e = vec2(.001, 0);
    vec3 pos = vec3(p, 0);/
    float a = (flow(pos))*6.2831*1.5;
    vec2 curl = vec2(cos(a), -sin(a))*2.;
*/
      
 
    // Update the field coordinates.
    uv += curl*.006*vec2(iR.y/iR.x, 1); // Move to the new position.
    
    
    // Buffer sample from the new position.
    vec3 val = texture(iChannel0, uv).rgb;
 
    
    //col = texture(iChannel2, uv, 3.).xyz; col *= col;
    //col = smoothstep(.0, .5, col);

    // Create a transcental color pattern using the warped coordinates.
    float snNs = dot(sin(uv*8. - cos(uv.yx*12.)), vec2(.25)) + .5;
    vec3 col = .5 + .45*cos(6.2831*snNs/6. + vec3(0, 1.2, 2)*.8);
    //vec3 col = mix(vec3(1, .8, .6).zyx, vec3(.6, .3, .2), snNs);
   
    // Color shading.
    // Just the original function without the curl, which gives the
    // impression of cast shadows.
    col *= flow(p)*2. - .5;
    // This is more correct, but I like the uncurled shading more.
    //col *= flow(vec3(uv, 0))*2. - .5;
    
  
    // Ridges -- Probably a little too much, but it'd be an interesting
    // addition if you wanted to raymarch the surface.
    //col *= abs(fract(col.x*16.) - .5)*2.*.04 + .96;
     
    
    // Mix the curent warped color texture in with the previous one.
    // Some people like to inject pixels from the sides and add those, but
    // for this example, I'm performing a simple blend... However you mix
    // frames is entirely up to you.
    //
    // More frames generally result in longer spirals. However, the speed at 
    // which we cut through the Z-planes (p.z += a*iTime), might need to 
    // be lowered.
    #ifdef LONGER
    const float nFrames = 32.;
    #else
    const float nFrames = 16.;
    #endif
    if(iFrame>0) col = mix(val, col, 1./nFrames);
    
  
    fragColor = vec4(max(col, 0.), 1);
}


