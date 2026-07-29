// Image (image) — Faux Hand Painted Voronoi by Shane
// https://www.shadertoy.com/view/tfd3Wf

/*

	Faux Hand Painted Voronoi
	-------------------------

	I like that contrasty, dark-edged hand painted look. I'm not sure what 
    it's technically called, but I come across a lot of it when perusing 
    stock images that feature Voronoi, stone backgrounds, etc. I don't believe 
    I've encountered it on Shadertoy or various realtime graphics sites though... 
    There might be some hidden away on page 953 on Shadetoy, or something, but 
    this kind of imagery doesn't appear to be a common thing to code up.
    
    Anyway, I thought I'd hack away using some common techniques I'm familiar
    with to at least approximate the look on a geometric surface. The real 
    ones used to be created with a mixture of graphics engines, post processing 
    software and artists. These days, the average Blender or Substance Designer
    user could achieve the same with a bit of effort, but the algorithmic 
    process is obscured, so that's not of much help.
    
    I'm hoping, at some stage, to post some examples that approximate various 
    rendering styles using techniques that the average coder can employ.
    
    I had originally intended to post the rocky background alone, but then I
    peer-pressured myself into adding a top layer to give it more depth -- I'm 
    not sure whether that was a good aesthetic choice, or not, but it blew
    the code out more. Even so, I wouldn't call this a complicated example.
    


	Other examples:
    
    // I love shaders that focus on rendering style.
	up in the cloud sea -- mdb 
	https://www.shadertoy.com/view/Ndc3zl

*/

#define TAU 6.2831853 

//#define STATIC

#define NET_OVERLAY


// Web type -- Yellow: 0, Metal: 1.
#define WEBTYPE 0

// Time global.
float tm = 0.;

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Commutative smooth minimum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smin(float a, float b, float k){

   float f = max(0., 1. - abs(b - a)/k);
   return min(a, b) - k*.25*f*f;
}

// Four hash values.
vec4 hash4(vec4 p){

    return fract(sin(mod(p, TAU))*43758.5453);
}

// More concise, self contained version of IQ's original 3D noise function.
float n3D(in vec3 p){
    
    // Just some random figures, analogous to stride. You can change this, if you want.
	const vec3 s = vec3(113, 157, 1);
	
	vec3 ip = floor(p); // Unique unit cell ID.
    
    // Setting up the stride vector for randomization and interpolation, kind of. 
    // All kinds of shortcuts are taken here. Refer to IQ's original formula.
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    
	p -= ip; // Cell's fractional component.
	
    // A bit of cubic smoothing, to give the noise that rounded look.
    p = p*p*(3. - 2.*p);
    
    // Standard 3D noise stuff. Retrieving 8 random scalar values for each cube corner,
    // then interpolating along X. There are countless ways to randomize, but this is
    // the way most are familar with: fract(sin(x)*largeNumber).
    //h = mix(fract(sin(mod(h, TAU))*43758.5453), 
    //        fract(sin(mod(h + s.x, TAU))*43758.5453), p.x);
    h = mix(hash4(h), hash4(h + s.x), p.x);
	
    // Interpolating along Y.
    h.xy = mix(h.xz, h.yw, p.y);
    
    // Interpolating along Z, and returning the 3D noise value.
    return mix(h.x, h.y, p.z); // Range: [0, 1].
	
}

// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){
 
    // The first line relates to ensuring that icosahedron vertex identification
    // points snap to the exact same position in order to avoid hash inaccuracies.
    uvec2 p = floatBitsToUint(f + 16384.);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}
 
// A slight variation on a function from Nimitz's hash collection, here: 
// Quality hashes collection WebGL2 - https://www.shadertoy.com/view/Xt3cDn
vec2 hash22(vec2 f){

     
    // Fabrice Neyret's vec2 to unsigned uvec2 conversion. I hear that it's not
    // that great with smaller numbers, so I'm fudging an increase.
    uvec2 p = floatBitsToUint(f + 16384.);
    
    // Modified from: iq's "Integer Hash - III" (https://www.shadertoy.com/view/4tXyWN)
    // Faster than "full" xxHash and good quality.
    p = 1103515245U*((p>>1U)^(p.yx));
    uint h32 = 1103515245U*((p.x)^(p.y>>3U));
    uint n = h32^(h32>>16);
    
    uvec2 rz = uvec2(n, n*48271U);
    #ifdef STATIC
    // Standard uvec2 to vec2 conversion with wrapping and normalizing.
    return (vec2((rz>>1)&uvec2(0x7fffffffU))/float(0x7fffffff) - .5)*.64;
    #else
    f = vec2((rz>>1)&uvec2(0x7fffffffU))/float(0x7fffffff);
    return sin(f*TAU + tm)*.32;
    #endif
}
 
// Standard straight edge distance Voronoi routine: This was coded in a hurry
// from scratch, but like all others, it was based on IQ's original, which
// can be found, here:
//
// Voronoi - distances -- iq
// https://www.shadertoy.com/view/ldl3W8
//
vec4 Voronoi(vec2 p, float smF){
    
    float sc = 4.;
    p *= sc;
    
    // Square grid. ID and local coordinates. 
    vec2 ip = floor(p) + .5;
    p -= ip;
    
    
    // Perform the usual Worley stuff. Place randomly offset points in each cell,
    // then determine which point is closest to the current pixel, etc.
    // Voronoi F1 and F2 values. Geometry-wise, these aren't necessary, but we'll
    // keep them for a bit of shading later.
    float vor = 1e5, vor2 = 1e5;
    
    // Find the nearest cell and mark the ID. This, we will need.
    vec2 offsID = vec2(0);
    
    for(int i = min(0, iFrame); i<9; i++){
            
        // Offset ID and corresponding offset point.
        vec2 offs = vec2(i%3, i/3) - float(3/2);
        vec2 offsP = offs + hash22(ip + offs); // Origin -- Top left.
        // Pixel distance to the point.
        float d = length(p - offsP);

        if(d<vor){

            vor2 = vor; // Second closest distance.
            vor = d; // Nearest distance.
            offsID = offs; // Nearest ID.
        }
        else if(d<vor2) {
            // Not needed for the geometry, but we'll use it for some shading later.
            vor2 = d; // Second closest distance.
        }
        
    }

    //////////////////////////////   
    //////////////////////////////
 
    const int N = 3; // Search grid size. Larger random offsets require larger grids.

    // Closest distance markes.
    float minDist = 1e8;//
    //float minDist2 = 1e8; // Second closest.
    
    // Closest cell center.
    vec2 pointCenter = (offsID + hash22(ip + offsID)); // Origin.
    
    // Find the nearest neighboring point to the nearest cell center, then mark the
    // cell ID to that. So far, the process is very similar to IQ's algorithm for 
    // finding the closest edge.

    for(int i = min(0, iFrame); i<N*N; i++){
    
        // Surrounding point IDs and points.
        vec2 offs = vec2(i%N, i/N) - float(N/2);
        if(offs == vec2(0)) continue;
        
        vec2 idI = offsID + offs; // Offset cell point ID.
        vec2 pI = (idI + hash22(ip + idI)); // Offset cell point.
      
        ////
        vec2 p2p = normalize(pI - pointCenter); // Edge line normal.
        vec2 edgeMid = mix(pointCenter, pI, .5); // Mid edge line point.
        float d = -dot(p - edgeMid, p2p); // Minimum distance to the line.
        ////
        
        
        // Minimum distance with smoothing factor.
        minDist = smin(minDist, d, smF);
        
        // Distance between the point center and the surrounding point.
        //float d = length(pointCenter - pI);
       
        // Minimum distance from the point center to the surrounding cell points. 
        // The minimum offset ID is noted -- since the halfway point 
        // (mix(pointCenter, pI, .5)) will be on the boundary of the closest edge.
        /*if(d<minDist){

            //minDist2 = minDist;
            //minID2 = minID;
            minDist = d;
            minID = k;


        }
        else if(d<minDist2){
            minDist2 = d;
            minID2 = k;

        }*/
    }
    
    
    //vec2 id = offsID + neighbor[minID];
    vec2 id = ip + offsID;
   
    // Minimum edge distance, F2 - F1 distance, and ID.
    return vec4(minDist/sc, (vor2 - vor)/sc, id);
    
}

//////////////////////////////
//////////////////////////////

// Bump pattern.
vec3 pattern(vec2 p, vec2 ip){
    
    #if 1
    // Rocky Voronoi.
    
    float smF = .1;
    
    #ifdef NET_OVERLAY
    // Randomly rotating the individual cell coordinates, for that
    // weird multi-portal effect, or just to confuse the viewer a bit. :)
    p *= rot2(hash21(ip)*TAU);
    #endif
    
    // Adding slight random waves, for more of a natural look.
    p.y += cos(p.x*TAU*2. + ip.y*.5 + ip.x*.5)/32.;

     
    vec4 v4 = Voronoi(p*1.5 + 71., smF);
    
    float v = -v4.x/1.5;
   
    // Natural perturbation, for a more rocky look.
    p.y += cos(p.x*TAU*2. + ip.y)/64.;
  
    /*
    // Voronoi cracks. These ones are a bit hacky. I'll post a proper
    // cracked earth related example later.
    vec4 v4B = Voronoi(p*3.4 + 11., smF);
    v4B.x = min(-v4B.x, ((1. - abs(v))*n3D(vec3(p*24., 8)) - .4));//v*12.
    v = max(v, v4B.x*8.); // Crack thickness.
    */
   
    // Adding noise over the surface.
    v *= smoothstep(0., .03, n3D(vec3(p*24., v)) - .5)*.5 + .75;
    
    
    return vec3(v, v4.zw);
   
    #else
    // Simple wavy surface background.
    float sc = 1./6.;
     
    float iy = floor(p.y/sc);
    
    p *= rot2(hash21(ip)*TAU);
    p.y += cos(p.x*TAU*2. + ip.y)*sc/4.;
    
    iy = floor(p.y/sc);
    p.y -= (iy + .5)*sc;
    
    float c = abs(p.y) - sc*.5;
    
    //c += abs(fract(-p.y/sc) - .5)*.1;
    c *= smoothstep(0., .03, n3D(vec3(p*24., c)) - .5)*.5 + .75;
    
    return vec3(c, vec2(0, iy));
    #endif
    
}

vec3 gID = vec3(0);
vec2 gIP;

// Bump mapping function. Put whatever you want here. In this case, 
// we're returning the length of the sinusoidal warp function.
float bumpFunc(vec2 p){ 

    // Call the Voronoi edge function.
    float smF = .2;
    #ifdef NET_OVERLAY
    tm = iTime;
    #else
    tm = 0.;
    #endif
    
    #ifdef NET_OVERLAY
    vec4 v4 = Voronoi(p, smF); // Range: [0, 1]
    #else
	vec4 v4 = vec4(1e5, 0, 0, 0);
    #endif
    // Voronoi distance field. 
    float v = v4.x;
    
    // ID.
    gIP = v4.zw;
    
    #ifdef NET_OVERLAY
    float ew = .015;
    #else
    float ew = -1e5;    
    #endif
    
    
    if(v<ew){
        // Top webbing.
        
        // Web.
        v = abs(v - ew)/(ew)*.1;
        v = min(v, .15);

        // Mild perturbation.
        p.y += cos(p.x*TAU*2.)/64.;
        v *= smoothstep(-.02, .02, n3D(vec3(p*24., v)) - .5)*.25 + .875;
        
        
        gID.x = 0.;
        gID.y = 0.;
        gID.z = v; // Save the distance.
    }    
    else{
        
        // Rocky background pattern.
        #ifdef NET_OVERLAY
        v = (v - ew)/(1. - ew);
        #endif
        gID.z = v;

        // No movement on the background.
        tm = 0.;
        // The pattern.
        vec3 p4 = pattern(p, gIP);
        v = .5 + min(-p4.x*6., .05) + min(-p4.x*6., .2);
        gID.x = -v;
        gID.y = 1.;
        
        //gIP = p4.yz; // Update the ID to the smaller stones.
    } 

    
    // Bump value.
    return max(v, 0.);

}

 

/*
// Standard ray-plane intersection.
vec3 rayPlane(vec3 p, vec3 o, vec3 n, vec3 rd) {
    
    float dn = dot(rd, n);

    float s = 1e8;
    
    if (abs(dn) > 0.0001) {
        s = dot(p-o, n) / dn;
        s += float(s < 0.0) * 1e8;
    }
    
    return o + s*rd;
}
*/

// 2D curvature.
//
// spr: sample spread, amp: amplitude, offs: offset.
float curve(in vec2 p, in float spr, in float amp, in float offs){

    
    spr /= 450.;
    
    float d = bumpFunc(p);
    
    // Cubic.
    vec2 e = vec2(spr, 0); // Example: ef = .5;
	float d1 = bumpFunc(p + e.xy), d2 = bumpFunc(p - e.xy);
	float d3 = bumpFunc(p + e.yx), d4 = bumpFunc(p - e.yx);

    return 1. - clamp((d1 + d2 + d3 + d4 - d*4.)/e.x/2.*amp + offs + .5, 0., .5);
    //return smoothstep(-.5, 1.5, (d1 + d2 + d3 + d4 - d*4.)/e.x/2.*amp + .5 + offs);
    
}


/*
// Simple environment mapping. Pass the reflected vector in and create some
// colored noise with it. The normal is redundant here, but it can be used
// to pass into a 3D texture mapping function to produce some interesting
// environmental reflections.
//
// More sophisticated environment mapping:
// UI easy to integrate - XT95    
// https://www.shadertoy.com/view/ldKSDm
vec3 eMap(vec3 rd, vec3 sn){
    
    vec3 sRd = rd; // Save rd, just for some mixing at the end.
    
    // Add a time component, scale, then pass into the noise function.
    rd.xy *= rot2(iTime/4.);
    rd *= 4.;
    
    //vec3 tx = tex3D(iChannel0, rd/3., sn);
    //float c = dot(tx*tx+.6, vec3(.299, .587, .114));
    
    float c = n3D(rd)*.57 + n3D(rd*2.)*.28 + n3D(rd*4.)*.15; // Noise value.
    c = smoothstep(.4, .8, c); // Darken and add contast for more of a spotlight look.
    
    //vec3 col = vec3(c, c*sqrt(c), c*c); // Simple, warm coloring.
    vec3 col = pow(min(vec3(1.4, 1, 1)*c, 1.), vec3(1, 2, 8)); // More color.
    
    // Mix in some more red to tone it down and return.
    return mix(col, col.zyx, smoothstep(.0, 1., n3D(rd*1.))); //vec3(c);//
    
}
*/
 

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    // Screen coordinates.
    vec2 iR = iResolution.xy;
	vec2 uv = (fragCoord - iR*.5)/iR.y;
   
    // VECTOR SETUP - surface postion, ray origin, unit direction vector, and light postion.
    //
    // Setup: I find 2D bump mapping more intuitive to pretend I'm raytracing, then lighting a bump mapped plane 
    // situated at the origin. Others may disagree. :)  
    vec3 sp = vec3(uv, 0); // Surface posion. Hit point, if you prefer. Essentially, a screen at the origin.
    vec3 rd = normalize(vec3(uv, 1.)); // Unit direction vector. From the origin to the screen plane.
    vec3 lp = vec3(cos(iTime/2.)*.5, sin(iTime/2.)*.2 + .5, -2.); // Light position - Back from the screen.
	vec3 sn = vec3(0., 0., -1); // Plane normal. Z pointing toward the viewer.
    
    // Camera.
    vec2 cam = vec2(2, 1)*iTime/32.;
    sp.xy += cam;
    lp.xy += cam;
/*
	// I deliberately left this block in to show that the above is a simplified version
	// of a raytraced plane. The "rayPlane" equation is commented out above.
	vec3 rd = normalize(vec3(uv, 1.));
	vec3 ro = vec3(0., 0., -1);

	// Plane normal.
	vec3 sn = normalize(vec3(cos(iTime)*0.25, sin(iTime)*0.25, -1));
    //vec3 sn = normalize(vec3(0., 0., -1));
	
	vec3 sp = rayPlane(vec3(0., 0., 0.), ro, sn, rd);
    vec3 lp = vec3(cos(iTime)*0.5, sin(iTime)*0.25, -1.); 
*/    
    
    // Background web shadow.
    tm = iTime;
    vec4 v4Sh = Voronoi(sp.xy + normalize(lp - sp).xy*.1, .2);
    float vSh = v4Sh.x;
    
    // BUMP MAPPING - PERTURBING THE NORMAL
    //
    // Setting up the bump mapping variables. Normally, you'd amalgamate a lot of the following,
    // and roll it into a single function, but I wanted to show the workings.
    //
    // f - Function value
    // fx - Change in "f" in in the X-direction.
    // fy - Change in "f" in in the Y-direction.
    vec2 eps = vec2(1.5/iResolution.y, 0.);
    
    float f = bumpFunc(sp.xy); // Sample value multiplied by the amplitude.
    vec3 svGID = gID;
    vec2 svGIP = gIP;
    float fx = bumpFunc(sp.xy + eps.xy); // Same for the nearby sample in the X-direction.
    float fy = bumpFunc(sp.xy + eps.yx); // Same for the nearby sample in the Y-direction.
  
    float fx2 = bumpFunc(sp.xy - eps.xy); // Same for the nearby sample in the X-direction.
    float fy2 = bumpFunc(sp.xy - eps.yx); // Same for the nearby sample in the Y-direction.
    //float edge = abs(fx + fx2 - f*2.) + abs(fy + fy2 - f*2.);
    float edge = abs(fx + fy+ fx2 + fy2 - 4.*f);//
    edge = smoothstep(-.05, .05, -.5 + edge/eps.x/2.);//sqrt(edge/eps.x*8.)
   
 	// Controls how much the bump is accentuated.
	const float bumpFactor = .2;
    
    // Using the above to determine the dx and dy function gradients.
    fx = (fx2-fx)/eps.x/2.; // Change in X
    fy = (fy2-fy)/eps.x/2.; // Change in Y.
    // Using the gradient vector, "vec3(fx, fy, 0)," to perturb the XY plane normal ",
    // vec3(0, 0, -1)."
    // By the way, there's a redundant step I'm skipping in this particular case, on account
    // of the normal only having a Z-component. Normally, though, you'd need the commented 
    // stuff below.
    //vec3 grad = vec3(fx, fy, 0);
    //grad -= sn*dot(sn, grad);
    //sn = normalize(sn + grad*bumpFactor); 
    sn = normalize(sn + vec3(fx, fy, 0)*bumpFactor);           
    
  
    // Scene curvature.
    float spr = 3., amp = 1., offs = 0.;
    float crv = curve(sp.xy, spr, amp, offs);

    
    
    // LIGHTING
    //
	// Determine the light direction vector, calculate its distance, then normalize it.
	vec3 ld = lp - sp;
	float lDist = max(length(ld), 0.001);
	ld /= lDist;

    // Light attenuation.    
    float atten = 1./(1. + lDist*lDist*.15);
	//float atten = min(1./(lDist*lDist*1.), 1.);


	// Diffuse value.
	float diff = max(dot(sn, ld), 0.);  
    // Enhancing the diffuse value a bit. Made up.
    //diff = pow(diff, 2.)*.5 + pow(diff, 4.); 
   
    // Specular highlighting.
    float spec = pow(max(dot( reflect(-ld, sn), -rd), 0.), 16.); 
    
    //float fre = pow(max(1. - max(-dot(reflect(-rd, sn), ld) , 0.), 0.), 5.);
    float fre = pow(max(1. - max(dot(-rd, sn), 0.), 0.), 5.); // Fresnel reflection term.
    
    // Backfill light.
	//float backFill = max(dot(vec3(-ld.xy, 0.), sn), 0.);
    
    // TEXTURE COLOR
    //
	// Combining the surface postion with a fraction of the warped surface position to index 
    // into the texture. The result is a slightly warped texture, as a opposed to a completely 
    // warped one. By the way, the warp function is called above in the "bumpFunc" function,
    // so it's kind of wasteful doing it again here, but the function is kind of cheap, and
    // it's more readable this way.
    //vec3 nsn = max(abs(sn), .001);
    vec3 texCol;
    
    float sf = 1./iResolution.y;
    
    float ew = .004;
    
    if(svGID.y==0.){ 
       
        // Web overlay coloring.
        
        #if WEBTYPE == 0
        texCol = vec3(1, .8, .125)*1.25;
        #else
        texCol = vec3(.4, 1, 1.5)*.25;
        diff *= diff*2.;
        #endif
        
        // Extra normal based coloring.
        //texCol *= 1. + sn.xzy*.25;
    }
    else{
        
        // Rocky background coloring.
        
        // Blueish.
        vec3 pCol = vec3(.15, .4, .7);
        
        // Pattern.
        tm = 0.; // No background movement.
        vec3 pat = pattern(sp.xy, svGIP);
        //vec3 pat = vec3(svGID.x, svGIP);
        
        // Random coloring.
        float rnd = hash21(svGIP + pat.yz)*.5 + .25;
        float rnd2 = hash21(svGIP + pat.yz + .1)*.5 + .25;
        float rnd3 = hash21(svGIP + pat.yz + .2)*.5 + .25;
        //pCol = .5 + .45*cos(TAU*rnd/4. + vec3(0, 1, 2).yyy*1. - 0.);
        //pCol = mix(vec3(.1, .7, 1), vec3(.25, .8, .5), rnd);
        pCol = pCol*(rnd + .5) + vec3(0, rnd2*.3, rnd3*.1);
       
        // Applying the Voronoi pattern to match the bump mapping..
        texCol = mix(texCol, pCol*.5, 1. - smoothstep(0., sf, pat.x + ew));
     
        // Desaturating.
        //texCol = mix(texCol, vec3(.7)*dot(texCol, vec3(.299, .587, .114)), .2);
    
        // Extra layer noise.
        float ns = mix(n3D(sp*24.), n3D(sp*48.), 1./3.);
        ns = mix(ns, n3D(sp*96.), 1./3.);
        //diff = pow(diff, ns + .5);
        texCol *= ns*1.5;
        
        #ifdef NET_OVERLAY
        // Background shadow and AO,if the netting is applied.
        texCol = mix(texCol, texCol*.35, 1. - smoothstep(0., .035, svGID.z));
        texCol = mix(texCol, texCol*.35, 1. - smoothstep(0., .035, vSh));
        #endif
        
        
    }
    
    
    // Extra diffuse coloring. 
    texCol = mix(texCol*vec3(1, .05, .3)*1.5, texCol*1.5, diff*diff);
    
    // Making the rocks a little more metallic.   
    if(svGID.y==1.) diff *= diff; 
   
 
     
    // Using pseudo science to apply a bit of faux back scatter. :)
    float bl = max(dot(normalize(vec3(-ld.xy, 0)), sn), 0.);
    //texCol = mix(texCol, texCol*vec3(1, 0, .1)*8., bl);
    texCol = texCol*.9 + texCol*vec3(1, .1, .3)*bl*12.;
    
   // Faux AO.    
    texCol = mix(texCol, texCol*.25, 1. - smoothstep(0., sf, abs(svGID.z) - ew));
     
    /*
    // Cheap specular reflections.
    float speR = pow(max(dot(normalize(ld - rd), sn), 0.), 5.);
    vec3 rf = reflect(rd, sn); // Surface reflection.
    //vec3 rTx = texture(iChannel1, rf).zyx; rTx *= rTx;
    vec3 rTx = eMap(rf, sn);
    texCol = texCol + (texCol)*speR*rTx*4.;
    */
    
    // Curvature.
    texCol *= crv*.85 + .65;  
    //texCol *= 1. - abs(crv - .5)*2.*.65;
    

   
    // FINAL COLOR
    // Using the values above to produce the final color.   
    vec3 col = texCol*(diff*1.5 + .5 + spec*4.)*atten;

   
    col *= 1. - edge*.7;
    //col *= 1. - abs(crv - .5)*2.*.5; // Dark lines.
    //col *= max(1. - crv*1., 0.)*1.5 + .25; // Plain curvature.
    
    
    // Mild toning. 
    //col /= (1.5 + col)/2.;
    
     
    // Subtle vignette -- Making use of IQ's box formula.
    uv = abs(uv) - vec2(iR.x/iR.y, 1)/2. + .15;
    float vig = min(max(uv.x, uv.y), 0.) + length(max(uv, 0.)) - .075;
    col = mix(col, col*.65,  smoothstep(0., .1, vig));
     

    // Gamma correction.
	fragColor = vec4(pow(max(col, 0.), vec3(1)/2.2), 1.);
}