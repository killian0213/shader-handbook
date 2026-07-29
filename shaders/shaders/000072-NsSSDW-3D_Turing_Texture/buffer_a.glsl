// Buffer A (buffer) — 3D Turing Texture by Shane
// https://www.shadertoy.com/view/NsSSDW



// Max ray distance.
#define FAR 50. 

// Surface delta.
#define DELTA .001

// Just the two passes. If your computer doesn't enjoy running the program,
// change the number of passes to 1.
#define PASSES 2



// Camera path. Arranged to coincide with the frequency of the lattice.
vec3 path(float t){
  
    //return vec3(0, 0, t); // Straight path.
    //return vec3(-sin(t/2.), sin(t/2.)*.5 + 1.57, t); // Windy path.
    
    //float s = sin(t/24.)*cos(t/12.);
    //return vec3(s*12., 0., t);
    
    float a = sin(t*.11);
    float b = cos(t*.14);
    return vec3(a*4. - b*1.5, b*1.2 + a*1., t);
    
}



// Tri-Planar blending function. Based on an old Nvidia tutorial by Ryan Geiss.
vec3 tex3D(sampler2D t, in vec3 p, in vec3 n){ 
    
    n = max(abs(n) - .2, .001); // max(n*n, .001), etc.
    n /= dot(n, vec3(1)); 
    //n /= length(n);
    
	vec3 tx = texture(t, p.yz).xyz;
    vec3 ty = texture(t, p.zx).xyz;
    vec3 tz = texture(t, p.xy).xyz;
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return (tx*tx*n.x + ty*ty*n.y + tz*tz*n.z);
}


// The 3D surface function. This one converts the 3D position to a 3D voxel 
// position in the cubemap, then reads the isovalue. Actually, one option does
// that, and the other is forced to read out eight neighboring values to 
// produce a smooth interpolated value. As in real life, it looks nicer, but 
// costs more. :)
float txFace0(in vec3 p){
    
    #if 0
    
    // One sample... Ouch. :D It's a shame this doesn't work, because it's 
    // clearly faster. Unfortunately, it's virtually pointless from an aesthetic
    // aspect, as you can see, but there'd be times when you could get away with it.
    vec3 col = texMapCh(iChannel0, p).xyz;
    
    #else
    
    // Eight samples, for smooth interpolation. Still not as good as the real 
    // thing -- and by that, I mean, calculating on the fly. However, it's 
    // good enough. I'd need to think about it, but I'm wondering whether a
    // four or five point tetrahedral interpolation would work? It makes my
    // head hurt thinking about it right now, but it might. :)
    vec3 col = texMapSmoothCh(iChannel0, p).xyz;
    
    #endif
    
    return col.x;
    
}



// 3D surface function.
float surfFunc3D(in vec3 p){ 

    return txFace0(p/3.)*.5 + .5;
    
}//

 
// A simple transcendental distance function upon which to apply 
// the Turing pattern.
float map(vec3 p){
   
    // 3D Turing pattern.
    //float sf = surfFunc3D(p);
    //sf = smoothstep(-.3, .3, sf - .5);
 
    
    p.xy -= path(p.z).xy;
 
    // Twist along Z.
    //float  ang = -p.z*.1;
    //p.xy *= rot2(ang);
    // Perturbation.
    //p += cos(p*1.57 + sin(p.yzx*3.14159)*3.14159)*.05;
    //p.xz += cos(p.xy*1.57*6. + sin(p.yz*3.14159*6.)*3.14159)*.01;
    
    
    // Mixing layers of transcendental functions. Only three are
    // used here, but higher numbers can look interesting.
    
    float d = 1e5;
    const int n = 3;
    const float fn = float(n);
    
    for(int i = 0; i<n; i++){
        
        vec3 q = p;
        float a = float(i)*fn*2.422; //*6.283/fn
        a *= a;
        q.z += float(i)*float(i)*1.67; //*3./fn
        q.xy *= rot2(a);
        d = smin(d, (length(length(sin(q.xy) + cos(q.yz))) - .15), 1.);
        
    }
    
    // Applying the Turing pattern.
    //d += (.5 - sf)*.025;
    //d = abs(d) + (.5 - sf)*.0125;
    
    return d;
	
}

/*
// A fake, noisy looking field - cheaply constructed from a spherized sinusoidal
// combination. I came up with it when I was bored one day. :) Lousy to hone in
// on, but it has the benefit of being able to guide a camera through it.
float map(vec3 p){

     // 3D Turing pattern.
    //float sf = surfFunc3D(p);
    //sf = smoothstep(-.3, .3, sf - .5);
 
    p.xy -= path(p.z).xy; 
     
	p = cos(p*.315*1.25 + sin(p.zxy*.875*1.25)); // 3D sinusoidal mutation.
    
    
    float n = length(p); // Spherize. The result is some mutated, spherical blob-like shapes.

    
    // It's an easy field to create, but not so great to hone in one. The "1.4" fudge factor
    // is there to get a little extra distance... Obtained by trial and error.
    n = (n - 1.025)*1.5;
    
    // Applying the Turing pattern.
    //n = abs(n) + (.5-sf)*.0125;
    //n += (.5 - sf)*.025;
    
    return n;
    
}
*/


// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    float t = 0., d;
    
    for(int i=0; i<96; i++){
    
        d = map(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(d)<DELTA*(t*.05 + 1.) || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.
        
        // Ray shortening.
        t += d*.75;
    }

    // Cap to the far distance plane.
    return min(t, FAR);
}


// Surface bump function..
float bumpSurf3D( in vec3 p){
 
    // The Turing pattern.
    float sf = surfFunc3D(p);
      
    // Shaping the pattern a bit.
    return smoothstep(-.35, .35, sf - .5);

}

// Standard function-based bump mapping routine: This is the cheaper four tap version. There's
// a six tap version (samples taken from either side of each axis), but this works well enough.
vec3 doBumpMap(in vec3 p, in vec3 nor, float bumpfactor){
    
    // Larger sample distances give a less defined bump, but can sometimes lessen the aliasing.
    const vec2 e = vec2(.003, 0); 
    
    // Gradient vector: vec3(df/dx, df/dy, df/dz);
    float ref = bumpSurf3D(p);
   
    vec3 grad = (vec3(bumpSurf3D(p - e.xyy),
                      bumpSurf3D(p - e.yxy),
                      bumpSurf3D(p - e.yyx)) - ref)/e.x; 
    
    /*
    // Six tap version, for comparisson. No discernible visual difference, in a lot of cases.
    vec3 grad = vec3(bumpSurf3D(p - e.xyy) - bumpSurf3D(p + e.xyy),
                     bumpSurf3D(p - e.yxy) - bumpSurf3D(p + e.yxy),
                     bumpSurf3D(p - e.yyx) - bumpSurf3D(p + e.yyx))/e.x*.5;
    */ 
  
    // Adjusting the tangent vector so that it's perpendicular to the normal. It's some kind 
    // of orthogonal space fix using the Gram-Schmidt process, or something to that effect.
    grad -= nor*dot(nor, grad);          
         
    // Applying the gradient vector to the normal. Larger bump factors make things more bumpy.
    return normalize(nor + grad*bumpfactor);
	
}


// Standard normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p) {
	const vec2 e = vec2(.001, 0);
	return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), map(p + e.yxy) - map(p - e.yxy),	
                          map(p + e.yyx) - map(p - e.yyx)));
}

// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with limited 
// iterations is impossible... However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not really affordable... Not on my slow test machine, 
    // anyway.
    const int iter = 24; 
    
    ro += n*.0015; // Bumping the shadow off the hit point.
    
    vec3 rd = lp - ro; // Unnormalized direction ray.

    float shade = 1.;
    float t = 0.; 
    float end = max(length(rd), .0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;
    
    //rd = normalize(rd + (hash33R(ro + n) - .5)*.03);
    

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i = 0; i<iter; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Subtle difference. Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), dist += clamp(h, .01, stepDist), etc.
        t += clamp(d, .01, .25); 
        
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>end) break; 
    }

    // Sometimes, I'll add a constant to the final shade value, which lightens the shadow a bit --
    // It's a preference thing. Really dark shadows look too brutal to me. Sometimes, I'll add 
    // AO also just for kicks. :)
    return max(shade, 0.); 
}


// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n){

	float sca = 2., occ = 0.;
    for( int i = min(iFrame, 0); i<5; i++ ){
    
        float hr = float(i + 1)*.15/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
        
        // Deliberately redundant line that may or may not stop the 
        // compiler from unrolling.
        if(sca>1e5) break;
    }
    
    return clamp(1. - occ, 0., 1.);
}


void mainImage(out vec4 e, in vec2 v){


    // When precalculating on the cube map tab, return a black screen.
    if (iFrame - frame0<=300) {
        e = vec4(0);
        return;
    }
    
    
    // Aspect correct UV coordinates. Only translation and scaling is required.
    vec2 uv = (v - iResolution.xy*.5)/iResolution.y;
    
	// Camera Setup.
    float speed = 2.;
    vec3 ro = path(iTime*speed); // Camera position, doubling as the ray origin.
    vec3 lk = path(iTime*speed + .25);  // "Look At" position.
    vec3 lp = path(iTime*speed + 5.); // Light position, somewhere near the moving camera.
	
    // Light postion offset. Since the lattice structure is rotated about the XY plane, the light
    // has to be rotated to match. See the "map" equation.
    vec3 loffs =  vec3(0, 0, 0);
    //vec2 a = sin(vec2(1.57, 0) - lp.z*1.57/10.);
    //loffs.xy = mat2(a, -a.y, a.x)*loffs.xy; 
    lp += loffs;

    // Using the above to produce the unit ray-direction vector.
    float FOV = 1.;//3./3.14159; ///3. FOV - Field of view.
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x )); 
    vec3 up = cross(fwd, rgt);

    // Unit direction ray.
    vec3 rd = normalize(fwd/FOV + uv.x*rgt + uv.y*up);
    // Lens distortion.
    //vec3 r = fwd + FOV*(u.x*rgt + u.y*up);
    //r = normalize(vec3(r.xy, (r.z - length(r.xy)*.25)));
    
    // Swiveling the camera from left to right when turning corners.
    rd.xy = rot2(-path(lk.z).x/16. )*rd.xy;

    // Set the initial position to the camera position.
    vec3 sp = ro;
    vec3 oRd;
    
    
    
    // Overall scene color.
    vec3 col = vec3(0);
    
   
    // Alpha, reflective factor, and fog distance.
    float alpha = 1.;
    float refFact = 1.;
    float fogDist = 1e5;
    
    // Bouncing the ray around and collecting color along the way.
    for(int j = min(0, iFrame); j<PASSES; j++){
    
        
        // Color for this particular pass.
        vec3 colL = vec3(0); 
        
        float distanceFactor = 1.;

        float freS = 1., fre2 = 1.;

        // Raymarching.
        float t = trace(sp, rd);
         
        // Fog distance.
        if(j==0) fogDist = t;

        // Advance the ray to the surface hit postion.
        sp += rd*t;
        
        // Unit direction vector copy.
        oRd = rd;

        if(t<FAR){

            // Surface normal.
            vec3 sn = getNormal(sp)*distanceFactor;
            
            // Function based bump mapping.
            sn = doBumpMap(sp, sn, .5/(1. + fogDist*fogDist*.03));///
            
            vec3 reflection = reflect(rd, sn);

            // Light direction, vector.
            vec3 ld = lp - sp;
            float lDist = length(ld); // Light distance.
            ld /= max(lDist, .0001);

            // Light attenuation.
            float att = 2./(1. + lDist*lDist*.03);
            
            
            // Very, very cheap shadows -- Not used here.
            //float sh = min(min(map(sp + ld*.08), map(sp + ld*.16)), 
            //           min(map(sp + ld*.24), map(sp + ld*.32)))/.08*1.5;
            //sh = clamp(sh, 0., 1.);
            float sh = softShadow(sp, lp, sn, 12.); // Shadows.
            float ao = calcAO(sp, sn); // Ambient occlusion.

            float dif = max(dot(ld, sn), 0.); // Diffuse value.
            float spe = pow(max(dot(reflection, ld), 0.), 16.);
            float fre = clamp(1. + dot(rd, sn), 0., 1.); // Fresnel reflection term.
            fre2 = clamp(1. - abs(dot(rd, sn))*.5, 0., 1.); // Fresnel reflection term.
            
            // Ramping up the diffuse component for more of a metallic look.
            dif = pow(dif, 4.)*2.;

            //float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
            //freS = mix(.25, 1., Schlick);  //F0 = .2 - Glass... or close enough.

            // Surface texture.
            vec3 tx = tex3D(iChannel1, sp/2., sn);
            tx = smoothstep(0., .5, tx);
            vec3 oCol = tx;
            
            // The Turing pattern.
            float sf = surfFunc3D(sp);
            
            // Applying the Turing pattern.
            oCol *= mix(vec3(.45, .5, .55), vec3(.15), 1. - smoothstep(-.03, .03, (sf - .5)));
            // Edge highlighting or sorts.
            oCol = mix(oCol, oCol*4., 1. - smoothstep(-.03, .03, abs(sf - .5) - .1));
           
            // Reflective factor: The idea is to reflect the darker part of the pattern less. 
            refFact = mix(1., .5, 1. - smoothstep(-.03, .03, (sf - .5)));
            //refFact *= mix(1., 4., 1. - smoothstep(-.03, .03, abs(sf - .5) - .1));
           
           
 
             
            // Applying the above to color the suface.
            colL = oCol*(dif*sh + .15 + vec3(1, .6, .3)*spe*sh*refFact*4.);
            
            // Attenuation and ambient occlusion.
            colL *= att*ao;
            
            // Reflect off the surface.
            rd = reflection; 
            
            // Move just off the surface to avoid self collisions.
            sp += sn*DELTA*1.1; 

        }

        // Applying fog.
        vec3 fogCol = mix( vec3(1.2, .7, .4).zyx, vec3(1), oRd.y*.5 + .5)*2.;
        float td = min(length(sp - ro), FAR);
        colL = mix(colL, fogCol, smoothstep(0., .99, td/FAR));

        // Adding the color for this pass.
        col += colL/float(PASSES)*alpha;
        //col = mix(col, colL, alpha/float(j + 1));//*freS;
        
        // Overall reflective reduction.
        alpha -= .25/float(PASSES);
        // Individual reflective reduction.
        alpha *= refFact;
        
    }
    
    
    
    e = vec4((max(col, 0.)), fogDist);
}