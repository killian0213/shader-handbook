// Image (image) — Vortex Swirl Heightmap by Shane
// https://www.shadertoy.com/view/WXt3Rn

/*

    Vortex Swirl Heightmap
    ----------------------
    
    Applying a vortex swirl to an extruded rectangular grid. I put it 
    together when I was bored, just to see what it'd look like. :)
    
    I adapted the following code from a metallicized Voronoi scene and 
    an old Mobius spiral template I had sitting around. The spiral flow 
    itself is pretty standard. I liked the spiral motion in Zcysky's 
    recent posting, so I've based it on that. The link is below, for 
    anyone interested.
 
    There's not much to say about this. It's just a grid array of metallic 
    boxes that have been transformed by an animated spriral function, then 
    mildly extruded to project the objects off of the canvas. The single 
    texture and basic environment texture this demonstration uses were 
    procedurally generated... Also due to boredom. :)
    
    The Mobius spiral version that I based this on might be interesting to
    people who like that kind of thing, so I plan to post that as well, at 
    some stage. Also, there are some defines below, if anyone would like 
    to see what the pattern looks like in silver, etc. :)
    

    
    Related examples:
    
    // I used a swirling motion similar to the motion
    // used here. Beautifully colored.
    //
    vortex-hw2 -- zcysky
    https://www.shadertoy.com/view/3cKXDc
    
    // Fabrice has too many vortex and swirl related examples to
    // list. This one is based on various op-art pieces that you may
    // or may not have encountered. I'd like to make my own one
    // at some stage.
    //
    drain vortex marching-less -- FabriceNeyret2 
    https://www.shadertoy.com/view/ws23D3
    // 
    Based on:
    drain vortex - skaplun
    https://www.shadertoy.com/view/3s2GW3

    
*/

// PI and 2 PI.
#define PI 3.14159265
#define TAU 6.2831853

// Global tile scale.
vec2 scale = vec2(1./8.);

// Field pattern -- Box: 0, Petal: 1.
#define PATTERN 1

// Color scheme -- Chrome: 0, Gold: 1.
#define COLOR 1

// Add a frame border to the objects. It's interesting, but a 
// little too busy for this example, so it's off by default.
//#define FRAME

// Max ray distance.
#define FAR 20.


// Scene object ID.
int objID;


// Standard 2D rotation formula.
//mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// IQ's vec2 to float hash.
//float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }


// Tri-Planar blending function: Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D tex, in vec3 p, in vec3 n){    
    
    // Abosolute normal with a bit of tightning.
    n = max(n*n - .2, .001); // max(abs(n), 0.001), etc.
    n /= dot(n, vec3(1)); 
    //n /= length(n); 
    
    // Texure samples. One for each plane.
    vec3 tx = texture(tex, p.zy).xyz;
    vec3 ty = texture(tex, p.xz).xyz;
    vec3 tz = texture(tex, p.xy).xyz;
    
    // Multiply each texture plane by its normal dominance factor.... or however you wish
    // to describe it. For instance, if the normal faces up or down, the "ty" texture 
    // sample, represnting the XZ plane, will be used, which makes sense.
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like
    // that. :) Once the final color value is gamma corrected, you should see correct 
    // looking colors.
    return mat3(tx*tx, ty*ty, tz*tz)*n;
}



// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h){
    /*
    vec2 w = vec2( sdf, abs(pz) - h);
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.));
    */
    
    // Slight rounding. A little nicer, but slower.
    const float sf = .015;
    vec2 w = vec2( sdf, abs(pz) - h - sf/2.);
  	return min(max(w.x, w.y), 0.) + length(max(w + sf, 0.)) - sf;
    
}
 
// IQ's box formula.
float sBoxS(in vec2 p, in vec2 b, in float rf){
  
  vec2 d = abs(p) - b + rf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rf;
    
}

 
// Global value and 2D ID containers.
vec3 gVal;
vec2 gIP;

// Overall scale.
vec2 sc = vec2(1, TAU/6.)/2.5; 
     

// Polar spiral.
vec2 spiral(vec2 p){

    // Spirals are almost trivial to make. Convert to radial
    // coordinates (pixel angle and radius from the center),
    // then increase the angle more as the radius decreases.
    // This creates a swirl.
    //
    // Angular coordinates.
    float r = length(p); // Radius.
    float ang = atan(p.y, p.x); // Angle..
    ang = mod(ang + 2./(r + .15), TAU); // Increase toward the center.
    // Convert back to cartesian coordinates.
    p = vec2(cos(ang), sin(ang))*r;
    
    return p;
 
}

// Basic spiral transform function.
vec2 transf(vec2 p){

    // Polar.
    p = spiral(p); 
    
    // Translation.
    p -= vec2(1, -1)*iTime/4.;
 
    //if(mod(floor(p.y/sc.y), 2.)==1.) p.x -= iTime/8.;//sc.x/2.;
    //else p.x += iTime/8.;
    
    // ID and local coordinates.
    vec2 ip = floor(p/sc);
    p -= (ip + .5)*sc;
    
    // Global ID, to be used elsewhere.
    gIP = ip;
 
    // Transformed coordinates.
    return p;
    
}


/////////////////



float dist2D(vec2 p){

     
    #if PATTERN == 1
    
    // Polar spiral with animation. A square grid and IDs
    // are calculated too.
    p = transf(p);
    
    // Boxes.
    float d2 = sBoxS(p, sc/2., .0);
    
    #else
    
    // Spiral.
    p = spiral(p);
    // Animation.
    p = p - vec2(1, -1)*iTime/4.;
    
    // Object ID.
    gIP = floor(p/sc);
    
      
    float scl = TAU*2.; // Scale.
    
    // Petal objects.  
    // Repeat sinusoidal functions.
    #ifdef FRAME
    float d2 = -abs(sin(p.x*scl)*cos(p.y*scl))/scl - .02;
    #else
    float d2 = -abs(sin(p.x*scl)*cos(p.y*scl))/scl*4. - .02;
    #endif

   
    #endif
    
    // Store the distance field and object ID.
    gVal = vec3(d2, gIP);
    
    return d2;

}

 
// Smoothing factor. Not used here.
float gF = 1.;

float distObj(vec3 uv){

    /*
    #if 1
    
    // Unused derivative based smoothing factor. Used for
    // precise gaps, and so forth. 
    vec2 e = vec2(.0015, 0);///iResolution.y;
    
    float dt = dist2D(uv.xy);
    float dtX = (dist2D(uv.xy + e.xy) - dt)/e.x;
    float dtY = (dist2D(uv.xy + e.yx) - dt)/e.x;
    
    //float dF = length(fwidth(dist2D(uv.xy, 1.)))*iResolution.y;    
    float dF = length(vec2(dtX, dtY));
    //float dF = dot(vec2(dtX, dtY), vec2(1));
      
    gF = dF;
    #endif
    */
   
    return dist2D(uv.xy);
    
    
}




// The extruded image.
float map(vec3 p){
    
    // Floor.
    float fl = -p.z;
    
    /*
    // Experiment with brick tiling... Not for this example.
    vec2 q = p.xy;
    vec2 sc2 = sc/vec2(1, 3);
    if(mod(floor(q.y/sc2.y), 2.)>.5)  q.x += sc2.x/2.;
    vec2 iq = floor(q/sc2);
    q -= (iq + .5)*sc2;
    float sq = sBoxS(q, sc2/2., .0);
    fl += max(sq, -.01);// + max(sq, dot(q, q)*.25);
    */
 
    // 2D distance.
    float d2 = distObj(p);
    //d2 /= gF;
    
    // Spacing.
    d2 += .04; 
    
    
    // Add a frame, if required.
    #ifdef FRAME
    float fr2 = abs(d2 + .015) - .015;
    d2 += .015;
    #endif


   
    float h = .04;
    float d = opExtrusion(d2, p.z + h, h);
    d += d2*.25;
    
    //d = 1e5; // Debug. Frame only, if selected.
    
    
    #ifdef FRAME
    h += .01;
    float fr = opExtrusion(fr2, p.z + h, h);
    #else 
    float fr = 1e5;
    #endif
    
    // Overall object ID.
    objID = fl<d && fl<fr? 0 : d<fr? 1 : 2;
    
    // Combining the floor with the extruded objects.
    return min(fl, min(d, fr));

 
}

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float t = 0., d;
    
    for(int i = min(0, iFrame); i<96; i++){
        
        d = map(ro + rd*t); // Surface distance.
        
        // If we've hit the surface, or gone too far, break;
        if(abs(d)<.001 || t>FAR) break;
        
        t += d*.7; // Ray shortening. 
    }

    return min(t, FAR);
}


// Standard normal function. It's not as fast as the tetrahedral calculation, 
// but more symmetrical.
vec3 normal(in vec3 p) {
	
    //const vec2 e = vec2(.001, 0);
    //return normalize(vec3(map(p + e.xyy) - map(p - e.xyy),
    //                      map(p + e.yxy) - map(p - e.yxy),	
    //                      map(p + e.yyx) - map(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    vec3 e = vec3(.002, 0, 0), mp = e.zzz; // Spalmer's clever zeroing.
    for(int i = min(iFrame, 0); i<6; i++){
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

    // More would be nicer. More is always nicer, but not always affordable. :)
    const int maxIterationsShad = 32; 
   
    // Coincides with the hit condition in the "trace" function. I've added in 
    // a touch of jittering to alleviate banding.
    ro += n*(.0015 + hash21(ro.xy + ro.yz + n.xz)*.01);
    vec3 rd = lp - ro; // Unnormalized direction ray.

    float shade = 1.;
    float t = 0.; 
    float end = max(length(rd), .0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. 
    // Obviously, the lowest number to give a decent shadow is the best one to choose. 
    for (int i = min(iFrame, 0); i<maxIterationsShad; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        // shade = min(shade, smoothstep(0., 1., k*d/t)); // Thanks to IQ for this tidbit.
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>end) break; 
        
        
        // So many options here, and none are perfect: 
        // dist += clamp(d, .01, stepDist), etc.
        t += clamp(d, .01, .2);       
        
    }

    // Shadow.
    return max(shade, 0.); 
}

// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n){

	float sca = 2., occ = 0.;
    for( int i = 0; i<5; i++ ){
    
        float hr = float(i + 1)*.125/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
    }
    
    return clamp(1. - occ, 0., 1.);  
}


// The normal function is just an application of the finite (central, forward) 
// difference method. The less used curvature function is a second derivative 
// extension of the former -- In fact, you can derive the curvature function from 
// the normal function.
//
// Original usage (I think?) - Cheap curvature: https://www.shadertoy.com/view/Xts3WM
// Other usage: Xyptonjtroz: https://www.shadertoy.com/view/4ts3z2
//
// spr: sample spread, amp: amplitude, offs: offset.
float curve(in vec3 p, in float spr, in float amp, in float offs){
    
    spr /= 450.;
    
    float sgn = 1.;
    vec3 e = vec3(spr, 0, 0); 
    float d = -map(p)*6.;
    for(int i = min(iFrame, 0); i<6; i++){
		d += map(p + sgn*e);
        sgn = -sgn;
        if((i&1)==1){ e = e.zxy; }
    }
   
    // By the way, I take a lot of liberties with this part of the formula. 
    // Dividing by the sample spread squared (e.x*e.x) is technically correct, 
    // but I'll sometimes divide by other things to get the result I want.
    //
    //return clamp(d/e.x/e.x*amp/16. + offs, -1., 1.)*.5 + .5;
    return smoothstep(-1., 1., d/(e.x*e.x)*amp/64. + offs);

}

// Cheesy 3D environmental texture -- I really need to put more
// effort into these.
vec3 envTex(vec3 p){

    float ns = gradN3D(p)*.57 + gradN3D(p*2.)*.28 + gradN3D(p*4.)*.15;
    ns = smoothstep(.45, .65, ns);
    vec3 refTx = pow(vec3(ns), vec3(1, 2, 8));  
    refTx = mix(refTx.zyx, refTx, smoothstep(.3, .7, gradN3D(p*2.5)));
    return refTx;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    
    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;

    
	// Camera Setup.
    vec3 ro = vec3(cos(iTime/4.)*.1, sin(iTime/4.)*.1, -1.5); // Ray origin.
	vec3 lk = vec3(0); // "Look At" position.
 
    // Light positioning.
 	vec3 lp = lk + vec3(.25, .5, -1);// Put it a bit in behind the camera.
	

    // Using the above to produce the unit ray-direction vector.
    float FOV = 1.; // FOV - Field of view.
    vec3 fwd = normalize(lk - ro); // Forward.
    //if(dot(fwd, vec3(fwd.z, 0, -fwd.x))==0.) fwd = normalize(fwd - vec3(0, 0, .00001));
    vec3 rgt = normalize(cross(vec3(0, 1, 0), fwd));// Right. 
    // "right" and "forward" are perpendicular normals, so the result is normalized.
    vec3 up = cross(fwd, rgt); // Up.
    
    // Camera.
    //mat3 mCam = mat3(rgt, up, fwd);
    // rd - Ray direction.
    //vec3 rd = mCam*normalize(vec3(uv, 1./FOV));//
    vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);
    
    
    
 
    
    // Raymarch to the scene.
    float t = trace(ro, rd);
    
    // Save the object ID.
    int svObjID = objID;
    // Saving the distance and warped object ID.
    vec3 svVal = gVal;
  
	
    // Initiate the scene color to black.
	vec3 col = vec3(0);
	
	// The ray has effectively hit the surface, so light it up.
	if(t < FAR){
        
  	
    	// Surface position and surface normal.
	    vec3 sp = ro + rd*t;
        vec3 sn = normal(sp);
        
            	// Light direction vector.
	    vec3 ld = lp - sp;

        // Distance from respective light to the surface point.
	    float lDist = max(length(ld), .001);
    	
    	// Normalize the light direction vector.
	    ld /= lDist;

        
        
        // Shadows and ambient self shadowing.
    	float sh = softShadow(sp, lp, sn, 16.);
    	float ao = calcAO(sp, sn); // Ambient occlusion.
        
        
        // Scene curvature.
        float spr = 4., amp = 1., offs = .0;
        float crv = curve(sp, spr, amp, offs);

	    
	    // Light attenuation, based on the distances above.
	    float atten = 1./(1. + lDist*.05);

    	
    	// Diffuse lighting.
	    float diff = max( dot(sn, ld), 0.);
        diff = pow(diff, 4.)*2.; // Ramping up the diffuse.
    	
    	// Specular lighting.
	    float spec = pow(max(dot(reflect(ld, sn), rd), 0.), 32.); 
	    
	    // Fresnel term. Good for giving a surface a bit of a reflective glow.
        //float fre = pow(clamp(1. - abs(dot(sn, rd))*.5, 0., 1.), 2.);
        
		// Schlick approximation. I use it to tone down the specular term. It's pretty subtle,
        // so could almost be aproximated by a constant, but I prefer it. Here, it's being
        // used to give a hard clay consistency... It "kind of" works.
		float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
		float freS = mix(.15, 1., Schlick);  //F0 = .2 - Glass... or close enough. 
        
          
        // Obtaining the texel color. 
	    vec3 texCol = vec3(.6); 
        
        vec3 txP = sp;
        float sf = 1.5/iResolution.y;
        float ew = .005;

        // The extruded grid.
        if(svObjID>0){
            
            float rnd = hash21(svVal.yz + .1);
            vec3 cCol = .5 + .45*cos(TAU*rnd/6. - crv*.1 + vec3(0, 1, 2)*1.);//rnd/6.
            texCol = cCol;
            
            #if PATTERN == 0
            // Darken the sinusoidal petal pattern, since the curves
            // reflect the light more.
            texCol *= .65;
            #endif
            
            
            // Frame color, if selected.
            if(svObjID==2) texCol = mix(texCol, vec3(1), .25);
            
 
        }
        else {
            
            // Brownish.
            texCol = vec3(.5, .275, .125); 
              
            //texCol = vec3(1)*dot(texCol, vec3(.299, .587, .114));
        
        }
        
        // More shading.
        //float d2 = svVal.x;
        //texCol *= max(-d2*6., 0.) + .5;
 
        
        // Greyscale option.
        vec3 svCol = texCol;
        #if COLOR == 0
        float gr = dot(texCol, vec3(.299, .587, .114));
        //if(svObjID!=2) 
           texCol = mix(svCol.zyx, vec3(gr), .8);
        #endif
       
        // Morphing the texture coordinates and normal, to
        // match the distance function.
        txP = sp;
        vec3 txN = sn;
        //if(svObjID>0){ // Leaving the back wall unwarped.
          
            txP.xy = transf(txP.xy);
            txN.xy = transf(txN.xy);
            
            txP.xy += svVal.yz*sc;
        //}
        
        // Apply a metallic grunge texture, similar to 
        // the Shadertoy one.
        vec3 tx3 = GrungeTex(txP*2.);
        vec3 tx = tx3.xyz;
        
        texCol *= tx*3.;        
        svCol *= tx*3.;
       
       
        
        // Specular reflection.
        vec3 hv = normalize(ld - rd); // Half vector.
        vec3 ref = reflect(rd, sn); // Surface reflection.
        vec3 q = ref*3.;
        q.xy *= rot2(iTime/2.);
        vec3 refTx = envTex(q); // Environment texture.
        refTx = refTx*refTx*2.; 
        //refTx = mix(refTx, smoothstep(.15, .5, GrungeTex(ref*1.))*3., .35);
        // Specular environment reflection.
        float spRef = pow(max(dot(hv, sn), 0.), 8.); // Specular reflection.
        float rf = (objID == 0)? .25 : 1.;
        texCol = texCol + svCol*spRef*refTx*rf*4.; 

         
        // Combining the above terms to produce the final color.
        col = texCol*(diff*sh + .25 + vec3(1, .97, .92)*spec*freS*8.*sh);
      
        // Mild curvature
        col *= crv + .25;
        //col *= 1.25 - abs(crv)*1.25;
        
        // Shading.
        col *= ao*atten;
        
        // It's sometimes helpful to check things like shadows and AO by themselves.
        //col = vec3(ao);
          
	
	}
    
    // Horizon fog. Not visible here, but provided for completeness.
    col = mix(col, vec3(0), smoothstep(0., .99, t/FAR));
          
          
    // Vignette. I like vignettes because they look nice, but I remember
    // being told that their practical use is to draw the user's eye to
    // the center of the image.
    uv = fragCoord/iResolution.xy;
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./16.);
          
          
    
    // Rough gamma correction.
	fragColor = vec4(sqrt(max(col, 0.)), 1);
	
}