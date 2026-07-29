// Buffer A (buffer) — Packed Mobius Strip by Shane
// https://www.shadertoy.com/view/Xf2czW

/*

    Mobius Packed Strip
    -------------------
    
    I've been busy travelling this year, so haven't been on Shadertoy much. A 
    couple of weeks ago, by pure chance, I went past the convention center in 
    Helsinki where they're hosting this year's Assembly demo party. This 
    reminded me that I haven't posted anything in ages, so I fired up my laptop 
    and repurposed an old example.
    
    Anyway, forward facing Mobius rings are commonplace in the geometric design 
    world. Hitting a scene with strategically positioned warm and cool lights is 
    another cliche, so this is not exactly interesting or original, but it was 
    fun and simple to make.
    
    There's not a lot to this: Create a square torus then twist it around the
    long toroidal axis to produce a Mobius ring. Once you've done that, break 
    the toroidal axis into repeat squares. In turn, break the individual square 
    axes into repeat cell segments in order to render tiny beaded objects. The
    details are contained in the "map" function.
    
    I'm not travelling from city to city now, so the plan is to code more. I'll 
    try to post something more interesting next.
    
    

	Related examples:
    
    // Dr2 has a heap of Mobius related material that's worth the look.
    Moebius Gears 2 - Dr2
    https://www.shadertoy.com/view/wsXyW2
    
    // Flockaroo has a lot of great geometric examples. Like myself, I 
    // wish he'd post more often. :)
    moebius gears 2 - flockaroo
    https://www.shadertoy.com/view/ls2BDc
    
    
*/


// Attempting not to unroll loops.
#define ZERO min(0, iFrame)

// Max ray distance.
#define FAR 10.



// Scene object ID to separate the mesh object from the terrain.
int objID;
vec4 vID;


/*
// Tri-Planar blending function. Based on an old Nvidia tutorial by Ryan Geiss.
vec3 tex3D(sampler2D t, in vec3 p, in vec3 n){ 
    
    n = max(abs(n) - .1, .001); // max(abs(n), 0.001), etc.
    n /= dot(n, vec3(1)); 
    //n /= length(n);
    
	vec3 tx = texture(t, p.yz).xyz;
    vec3 ty = texture(t, p.zx).xyz;
    vec3 tz = texture(t, p.xy).xyz;
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like 
    // that. :) Once the final color value is gamma corrected, you should see correct 
    // looking colors.
    return mat3(tx*tx, ty*ty, tz*tz)*n;
}
*/

// Texture sample.
vec3 getTex(sampler2D iCh, vec2 p){

    vec3 tx = texture(iCh, p).xyz;
    return tx*tx; // Rough sRGB to linear conversion.
}


// IQ's box routine.
float sBoxS(in vec2 p, in vec2 b, float r){

  vec2 d = abs(p) - b + r;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - r;
}

// IQ's box routine.
float sBoxS(in vec3 p, in vec3 b, float r){

  vec3 d = abs(p) - b + r;
  return min(max(max(d.x, d.y), d.z), 0.) + length(max(d, 0.)) - r;
}

// Object rotation, with some optional mouse movement.
vec3 objRot(vec3 p){

    // Mouse movement.
    if(iMouse.z>1.){
        p.yz *= rot2(-(iMouse.y - iResolution.y*.5)/iResolution.y*3.1459);  
        p.xz *= rot2(-(iMouse.x - iResolution.x*.5)/iResolution.x*3.1459);  
    } 

    // The object originally sat in the XZ plane, so rather than rearrange
    // the coordinate system, I've lazily applied some quick rotation.
    p.yz = rot2(-PI/2.)*p.yz;
    p.xz = rot2(iTime/2.)*p.xz; 
    return p;

}

 
// Create multiple copies of an object - https://iquilezles.org/articles/sdfrepetition/
vec2 opRepLim( in vec2 p, in float s, in vec2 lima, in vec2 limb ){
   
    return p - s*clamp(floor(p/s + .5), lima, limb);
}



 
// Texture coordinates. It's easier to save them in the distance field and
// reuse them later, rather than recalculate them all over again. The downside
// is expense, but it's not really noticeable here.
vec2 txCoord;
 

// Scene distance function.
float map(vec3 p){
    

    /*
    // Raised background to match the pattern. Interesting,
    // but not suited to this example.
    float sf = bgPat2(p.xy, 0.);
    sf = smoothstep(-.125, .125, sf);// + sf;
    float fl = -p.z + 2.;// - sf*.05;
    */
    
    float fl = -p.z + 2.;// - sf*.05;
    
    
    // Rotate the object.
    vec3 rP = objRot(p);
    
    // Number of toroidal twists. Smaller half number multiples will work.
    float twists = 1.5;
 
    
    // Toroidal strip dimensions.
    vec2 dim = vec2(.1, .1);
    float r = .35; // Toroidal radius.
    
    // Disc coordinates.
    vec3 q = rP; 
    vec2 tc = vec2(length(q.xz) - r, rP.y);
    
    
    // Disc repeat.
    vec3 q2 = rP;
    float aN = 48.; // 48 repeat square planes.
    float a = mod(atan(q2.z, q2.x), TAU);
    float na = (floor(a*aN/TAU) + .5)/aN;
    float sR = r*TAU/aN;
    
    // Construct repeat cells about the larger toroidal axis.
    q2.xz *= rot2(-na*TAU);
    q2.x -= r; // Move out from the center by the large radial distance.
    
    // Twist each repeat plane about the smaller poloidal axis. Comment
    // this line out to see what it does, if you're not sure.
    q2.xy *= rot2(-na*TAU*twists/2. + iTime*.5);  

    // Split each repeat plane into 5-by-5 repeat cells sing IQ's clamped
    // repeat object formula.
    q2.xy = opRepLim(q2.xy, sR, vec2(-2), vec2(2));
   
 
    // Construct a tiny spherical object in each cell.
    float bead = length(q2) - r*TAU/aN*.65;
    // Option rouded cubes.
    //float dimR = r*TAU/aN*.6;
    //float bead = sBoxS(q2, vec3(dimR), dimR*.65);
       
    // Creating a solid toroidal object, mostly for debug purposes, by
    // is used for texturing as well.
    tc *= rot2(-a*twists/2. + iTime*.5); // Twisting the toroidal plane itself.
    
    
    // Saving some polar coordinates to use for texturing.
    float ux = abs(tc.x) - dim.x<abs(tc.y) - dim.y? tc.x : tc.y; 
    txCoord = vec2(ux, a/TAU);
    
    
    // Used for debugging.
    
    // Solid toroidal object. Uzed for texture debugging.
    float tor = 1e5;
    //float tor = sBoxS(tc, dim + .01, .03); // Creating the solid central strip.
    
    // Debugging. Take the beads out of the scene.
    //bead = 1e5;
    
   
     // Overall object ID -- There are two rundundant slots there.
    vID = vec4(fl, bead, tor, 1e5);
    
    // Shortest distance.
    return  min(min(fl, bead), tor);
 
}
 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float t = 0., d;
    
   
    for(int i = ZERO; i<96; i++){
    
        d = map(ro + rd*t);
        
        if(abs(d)<.001 || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.

        t += d*.8; 
    }

    return min(t, FAR);
}


// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p, float t){
	
    //return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), 
    //                      map(p + e.yxy) - map(p - e.yxy),	
    //                      map(p + e.yyx) - map(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    vec3 e = vec3(.001, 0, 0), mp = e.zzz; // Spalmer's clever zeroing.
    for(int i = ZERO; i<6; i++){
		mp.x += map(p + sgn*e)*sgn;
        sgn = -sgn;
        if((i&1)==1){ mp = mp.yzx; e = e.zxy; }
    }
    
    return normalize(mp);
}
 

// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with 
// limited iterations is impossible... However, I'd be very grateful if someone could 
// prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not always affordable.
    const int maxIter = 32; 
    
    // Bumping the ray off the surface to avoid self collisions.
    // The constant coincides with the hit condition in the "trace" function. 
    ro += n*.0015; 
    
    vec3 rd = lp - ro; // Unnormalized direction ray.
    

    float shade = 1.; // Initial shadow value.
    float t = 0.; // Initial distance.
    float end = max(length(rd), 0.0001); // Distance from the jump point to the light.
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down.
    // Obviously, the lowest number to give a decent shadow is the best one to choose. 
    for (int i = ZERO; i<maxIter; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Thanks to IQ for this.
        // So many options here, and none are perfect: 
        // dist += min(h, .2), dist += clamp(h, .01, stepDist), etc.
        t += clamp(d, .01, .25); 
        
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>end) break; 
    }

    // Return the shadow.
    return max(shade, 0.); 
}


// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n)
{
	float sca = 2., occ = 0.;
    for( int i = ZERO; i<5; i++ ){
    
        float hr = float(i + 1)*.15/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
        //if(occ>1e5) break; // Faux exit.
    }
    
    return clamp(1. - occ, 0., 1.);  
    
}

/////
// Code block to produce some layers of fine mist. Not sophisticated at all.
// If you'd like to see a much more sophisticated version, refer to Nitmitz's
// Xyptonjtroz example. Incidently, I wrote this off the top of my head, but
// I did have that example in mind when writing this.
float trig3(in vec3 p){

    p = cos(p*2. + (sin(p.yzx) + 1. + vec3(-.15, 1, .5)*iTime*2.)*1.57);
    return dot(p, vec3(.1666)) + .5;
}

// Basic low quality noise consisting of three layers of rotated, mutated 
// trigonometric functions. Needs work, but it's OK for this example.
float trigNoise3D(in vec3 p){

    // 3D transformation matrix.
    const mat3 m3RotTheta = mat3(0.25, -0.866, 0.433, 0.9665, 0.25, -0.2455127, 
                                 -0.058, 0.433, 0.899519 )*1.5;
  
	float res = 0.;
    
    float t = trig3(p*PI);
	p += (t - iTime*.25);
    p = m3RotTheta*p;
    //p = (p+0.7071)*1.5;
    res += t;
    
    t = trig3(p*PI); 
	p += (t - iTime*.25)*.7071;
    p = m3RotTheta*p;
     //p = (p+0.7071)*1.5;
    res += t*.7071;

    t = trig3(p*PI);
	res += t*.5;
	 
	return res/2.2071;
}

// Some layers of cheap trigonometric noise to produce some subtle mist.
// Start at the ray origin, then take some samples of noise between it and 
// the surface hit point. Apply some very simplistic lighting along the way.  
// It's not particularly well thought out, but it doesn't have to be.
vec3 getMist(in vec3 ro, in vec3 rd, in vec3 lp, in vec3 lp2, in float t){

    vec3 mist = vec3(0);
    
    //vec3 lCol1 = vec3(1, .1, .05);
    //vec3 lCol2 = vec3(.2, .4, 1);
    
    for (int i = 0; i<8; i++){
        // Lighting. Technically, a lot of these points would be
        // shadowed, but we're ignoring that.
        float sDi = length(lp - ro)/1.; 
	    vec3 sAtt = .5/(1. + sDi*.25 + sDi*sDi*.15)*vec3(1);
        
        sDi = length(lp2 - ro)/1.; 
        vec3 sAtt2 = .5/(1. + sDi*.25 + sDi*sDi*.15)*vec3(1);
        
	    // Noise layer.
        mist += trigNoise3D(ro)*(sAtt + sAtt2)/8.;
        // Advance the starting point towards the hit point.
        ro += rd*t/8.;
        
        // A bit of vortex action.
        //rd.xy *= rot2(rd.z*.05);
    }
    
    // Add a little noise, then clamp, and we're done.
    return max(mist + hash31(ro)*.1 - .05, 0.);

} 



void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    
    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
	
	// Camera Setup.
	vec3 lk = vec3(0, 0, 0); // "Look At" position.
    vec3 ro = lk + vec3(cos(iTime/2.)*.05, .2, -1.5); // Camera position.
 	vec3 lp = lk + vec3(2, 1, 1); // Light position. // Red.
 	vec3 lp2 = lk + vec3(-2, 1, -.35); // Light position. // Blue.
	

    // Using the above to produce the unit ray-direction vector.
    float FOV = 1.; // FOV - Field of view.
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x)); 
    vec3 up = cross(fwd, rgt); 

    // rd - Ray direction.
    vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);
    
   
    // Raymarch to the scene.
    float t = trace(ro, rd);
    
    // Save the texture coordinates.
    vec2 svTxCoord = txCoord;
    

    // Obtain the object ID.
    objID = 0;
    float obD = vID[0];
    
    for(int i = 0; i<4; i++){ 
        if(vID[i]<obD){ obD = vID[i]; objID = i; }
    }
  
	
    // Initiate the scene color to black.
	vec3 col = vec3(0);
	
	// The ray has effectively hit the surface, so light it up.
	if(t < FAR){
        
  	
    	// Surface position and surface normal.
	    vec3 sp = ro + rd*t;
	    //vec3 sn = getNormal(sp, edge, crv, ef, t);
        vec3 sn = getNormal(sp, t);
        
        
        // Light direction vector.
	    vec3 ld = lp - sp;
	    vec3 ld2 = lp2 - sp;

        // Distance from respective light to the surface point.
	    float lDist = max(length(ld), .001);
	    float lDist2 = max(length(ld2), .001);
    	
    	// Normalize the light direction vector.
	    ld /= lDist;
 	    ld2 /= lDist2;
        
        
        // Shadows and ambient self shadowing.
    	float sh = softShadow(sp, lp, sn, 8.);
        float sh2 = softShadow(sp, lp2, sn, 8.);
    	float ao = calcAO(sp, sn); // Ambient occlusion.
        
	    // Light attenuation, based on the distances above.
	    float atten = 4./(1. + lDist*.25);
	    float atten2 = 4./(1. + lDist2*.25);

        /*
    	// Regular lighting.
    	// Diffuse lighting.
	    float diff = max( dot(sn, ld), 0.);
	    float diff2 = max( dot(sn, ld2), 0.);

        // Specular lighting.
	    float spec = pow(max(dot(reflect(ld, sn), rd ), 0.), 32.); 
	    float spec2 = pow(max(dot(reflect(ld2, sn), rd ), 0.), 32.); 
        */
        
        // Obtaining the texel color. 
	    vec3 texCol;   

        // Object coloring. 
        
        if(objID==0){ // Background wall.
            
            // Background coloring and texturing.
            
            //vec3 tx = texture(iChannel0, txP.xy/3. + vec2(.25, .5), 0.).xyz; tx *= tx;
            vec3 tx = getTex(iChannel0, sp.xy/3. + vec2(.25, .5));
             
            texCol = vec3(.8, 1, 1.2)*(tx*2. + .1)/8.;
            
            // Applying a simple wavy background pattern. The blurry background
            // almost makes it redundant, but it's there anyway.
            float pat = bgPat(sp.xy, 0.);
   
            // Applying the pattern to the backgrorund plane.
            texCol = mix(texCol, texCol*.85, 1. - smoothstep(0., .01, pat));
            
            // Regular lighting.
            //spec /= 64.;
            //spec2 /= 64.;
            
           
        }
        else if(objID==1){ //  Mobius beads.
        
            // Using the saved coordinates from the distance function 
            // to texture the mobius bands. The sides aren't technically
            // correct, but no one will notice.
            vec3 tx = getTex(iChannel0, svTxCoord*vec2(2, 4)); 
            
            // Graphite.
            texCol = vec3(.075)*(tx*2. + .05);
            
            // Regular lighting.
            //diff *= diff;
            //diff2 *= diff2;
            
            
        }
        else { // Solid Mobius strip, if not hidden.
         
            // Using the saved coordinates from the distance function 
            // to texture the mobius strip.
            vec3 tx = getTex(iChannel0, svTxCoord*vec2(2, 4));      
             
            // Coloring the individual blocks with the saved ID.
            texCol = tx/2. + .02;             
        }
        
        
        // I wanted to use a little more than a constant for ambient light this 
        // time around, but without having to resort to sophisticated methods, then I
        // remembered Blackle's example, here:
        // Quick Lighting Tech - blackle
        //// https://www.shadertoy.com/view/ttGfz1
        float am = pow(length(sin(sn*2.)*.5 + .5)/sqrt(3.), 2.)*.5; // Studio.

        // Red and blue lights. It's an industry cliche, but effective.
        vec3 lCol1 = vec3(1, .1, .05);
        vec3 lCol2 = vec3(.2, .4, 1);
       
        /*
        // Regular lighting.
        
        // Combining the above terms to produce the final color.
        vec3 col1 = texCol*(diff*sh + am + spec*16.*sh);
        // Shading.
        col1 *= atten;
        
        vec3 col2 = texCol*(diff2*sh2 + am + spec2*16.*sh2);
        // Shading.
        col2 *= atten2;
        */
        
        // BRDF.
        
        /////////
        // Greyscale texture value -- used for varying surface roughness.
        float gr = dot(texCol, vec3(.299, .587, .114));
 
        // Material type: Dielectics, with varying roughnesss and reflectance.
        float matType = 0., roughness = gr*2. + .105, reflectance = .725;
        if(objID==0){
           // Background use less reflectance and more roughness.
           reflectance = .125;
           roughness = gr*4. + .305;
        }
        

        // Cook-Torrance based lighting.
        vec3 ct = BRDF(texCol, sn, ld, -rd, matType, roughness, reflectance, vec3(4));

        // Combining the ambient and microfaceted terms to form the final color:
        // None of it is technically correct, but it does the job. Note the hacky 
        // ambient shadow term. Shadows on the microfaceted metal doesn't look 
        // right without it... If an expert out there knows of simple ways to 
        // improve this, feel free to let me know. :)
        vec3 col1 = (texCol*am*(sh*.5 + .5) + ct*(sh))*atten;


            // Cook-Torrance based lighting.
        vec3 ct2 = BRDF(texCol, sn, ld2, -rd, matType, roughness, reflectance, vec3(1));

        // Combining the ambient and microfaceted terms to form the final color:
        // None of it is technically correct, but it does the job. Note the hacky 
        // ambient shadow term. Shadows on the microfaceted metal doesn't look 
        // right without it... If an expert out there knows of simple ways to 
        // improve this, feel free to let me know. :)
        vec3 col2 = (texCol*am*(sh2*.5 + .5) + ct2*(sh2))*atten2;
        
        //////
        
        

        // Applying the colored lights to the respective lit materials.
        col = (lCol1*col1 + lCol2*col2)*ao;
        

	}
    
    // Blend the scene and the background with some very basic, 4-layered fog.
    vec3 mist = getMist(ro, rd, lp, lp2, t);
    vec3 fog = mist*(col*4. + vec3(1)*.05);//vec3(2.5, 1.75, .875)* mix(1., .72, mist)*(rd.y*.25 + 1.);
    col = mix(col, fog, smoothstep(0., 1., t/6.));
    
    // Simpler fog, sans mist.
    // Fog -- A bit redundant here, but it does have a minor effect.
    //vec3 fog = vec3(0);
    //col = mix(col, fog, smoothstep(0., .99, t/FAR));
    
    
    // Save to "Buffer A" for post processing and gamma correction.
    fragColor = vec4(clamp(col, 0., 1.), t);
    
    /*       
    // Temporal blur. Requires adding "Buffer A" to "iChannel1".
    vec4 preCol = texelFetch(iChannel1, ivec2(fragCoord), 0);
    float blend = (iFrame < 2) ? 1. : 1./4.; 
    fragColor = mix(preCol, vec4(max(col, 0.), t), blend);
    */
    
	
}
