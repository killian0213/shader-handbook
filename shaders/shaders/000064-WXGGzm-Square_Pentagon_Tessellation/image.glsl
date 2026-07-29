// Image (image) — Square Pentagon Tessellation by Shane
// https://www.shadertoy.com/view/WXGGzm

/*

    Square Pentagon Tessellation
    ----------------------------
    
    I love simple tessellation patterns. I like the less simple ones
    too, but those can be harder to raymarch. This one features a
    somewhat standard square (diamond) and octagon pattern with some
    additional subdivision. In particular, the octagon has been 
    subdivided into a rotated square flanked by four pentagons.
    
    The method I used to construct the pattern is robust, but it was
    put together quickly, so I'd imagine there'd be better ways to go
    about it. I also needed to produce it in such a way that a raymarch
    traversal would work. Plus, I wanted vertices to use as rivots.
    
    Vertices are great to have when you want to add some design detail,
    but obtaining them can sometimes drag down the frame rate.
    Calculating vertices is also dragging out compilation time to the
    five second mark on my machine, so apologies to anyone experiencing
    the same -- I'll see what I can do about that later. I'll also 
    tweak the code to speed things up in general.    
    
    Anyway, I didn't put a great deal of effort into the presentation,
    since I merely repackaged a previous shader, but I liked the way it 
    turned out, so I've posted it.
    
    

    
    Related examples:    
    
    // Flopine puts together some pretty nice isometric shaders.
    //
    Artober - Working -- Flopine
    https://www.shadertoy.com/view/slGBWd
    
    
    // Fizzer constructed a Truchet pattern, based on an octagonal
    // diamond grid, a while back.
    //
    4.8^2 Truchet -- Fizzer
    https://www.shadertoy.com/view/MlyBRG 
    
    
    // A blobby Truchet pattern, based on a diamond square tessellation.
    //
    Extruded Octagon Diamond Truchet -- Shane
    https://www.shadertoy.com/view/3tGBWV

    
*/

// PI and 2 PI.
#define PI 3.14159265
#define TAU 6.2831853

// Max ray distance.
#define FAR 20.

/////////////////
 
// Color scheme -- Grey: 0, Gold: 1.
#define COLOR 1

// Add a frame border to the objects. It's interesting, but a 
// little too busy for this example, so it's off by default.
#define FRAME

// Display the rivots (based on vertices), or not.
#define RIVOTS


/////////////////


// Scene object ID.
int objID;

 
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
     
    vec2 w = vec2( sdf, abs(pz) - h);
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.));
    
    /*
    // Slight rounding. A little nicer, but slower.
    const float sf = .015;
    vec2 w = vec2( sdf, abs(pz) - h - sf/2.);
  	return min(max(w.x, w.y), 0.) + length(max(w + sf, 0.)) - sf;
    */
}
 

 
// Global value and 2D ID containers.
vec4 gVal;
vec2 gIP;

 
/////////////////

 
// Height map value.
float hm(in vec2 p){  
    
    p *= 4.;
    float d = dot(sin(p*.5 - cos(p.yx*.7)), vec2(.25)) + .5;
    return mix(d, dot(sin(p - cos(p.yx*1.4)), vec2(.25)) + .5, 1./3.);

}

// Ray origin, ray direction, point on the line, normal. 
float rayLine(vec2 ro, vec2 rd, vec2 p, vec2 n){
   
   // This it trimmed down, and can be trimmed down more. Note that 
   // "1./dot(rd, n)" can be precalculated outside the loop.
   //return dot(p - ro, n)/dot(rd, n);
   float dn = dot(rd, n);
   return dn>0.? dot(p - ro, n)/dn : 1e8;   

}

// Global cell boundary distance variables.
vec3 gDir; // Cell traversing direction.
vec3 gRd; // Ray direction.
float gCD; // Cell boundary distance.


// The extruded image.
float map(vec3 p){
   
    // Floor.
    float fl = -p.z;
 
 
    // 2D distance.
    vec4 d4 = distField(p.xy);
    gIP = d4.yz;
    float d2 = d4.x;
    
    // Spacing.
    d2 += .01; 
    
    ////////
    // Save the direction ray, then align it to match flipped cell coordinates.
    //vec3 svRd = swtch==1? vec3(rot2(PI/4.)*gRd.xy, gRd.z) : gRd;
    vec3 svRd = gRd;
    
    // The minimum cell wall distance: This distance is used as a ray jump 
    // delimiter. It can slow things down a bit, but not by anywhere near as
    // much as you'd think. The upside is artifact free traversal. The towering
    // geometry you see wouldn't be possible at reasonable frame rates without it.
    float rC = 1e5;
    //for(int i = 0; i<pID; i++){
    for( int j = 0, i = pID - 1; j < pID; i = j, j++){ // IQ's wrap avoiding loop.
        // Minimum wall distance.
        float rCI = rayLine(gP, svRd.xy, vP[i], 
                            normalize(vP[i] - vP[j]).yx*vec2(1, -1));
        // Overall miimum cell wall distance.
        rC = min(rC, rCI); //min(rC, max(rCI, 0.));
    }
    // Capping above zero (probably not necessary here), then adding a touch 
    // extra to ensure the ray moves to the next cell.
    gCD = max(rC, 0.) + .0001;
    //////////   
    
    // Variations.
    //if(hash21(gIP + .08)<.35)
    //if(pID==4)
    //   d2 = abs(d2 + .0555) - .05;
    
    // Add a frame, if required.
    #ifdef FRAME
    float fr2 = abs(d2 + .015) - .015;
    d2 += .03;
    #endif
    
    // Variable pylong height.
    float h = hm(gIP*gSc);
    h = h*.45 + .05;
    // Extruding the 2D field value into a 3D pylong.
    float d = opExtrusion(d2, p.z + h, h);
    float fD = d;
    d += d2*.25; // Adding pointed tops to the pylon faces.
    //d += max(d2, -.035)*.5;
    
    //d = 1e5; // Debug. Frame only, if selected.
   
    
    #ifdef FRAME
    h += .005;
    float fr = opExtrusion(fr2, p.z + h, h);
    #else 
    float fr = 1e5;
    #endif
    
    
    #ifdef RIVOTS
    // Rivots.
    float riv = 1e5;
    // Iterating through all vertices, then (hackily) pushing them inward.
    for(int i = 0; i<pID; i++){
         float shr = .64;
         if(pID==5 && (i==3 || i==4) ) shr = .5;
         if(pID==8) shr = .92;
         riv = min(riv, length(gP - vP[i]*shr*.9 + normalize(vP[i])*.0));
         /*
         vec2 nrm = normalize(vP[(i + 1)%pID] - vP[i]);
         vec2 nrm2 = normalize(vP[(i + pID - 1)%pID] - vP[i]);
         nrm = mix(nrm, nrm2, .5);
         riv = min(riv, length(gP - vP[i] - nrm*.1));
         */
    }
    // Extruding the 2D vertex to form a rivot, then adding it to
    // the frame field -- since they'll be colored the same.
    riv = max(riv - .016, fD - .025);
    fr = min(fr, riv);
    #endif

    
    // Saving the 2D value, ID and height for later use.
    gVal = vec4(d2, gIP, h);
    
    // Overall object ID.
    objID = fl<d && fl<fr? 0 : d<fr? 1 : 2;
    
    // Combining the floor with the extruded objects.
    return min(fl, min(d, fr));

 
}

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float t = 0., d;
    
    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = step(0., rd) - .5;
    gRd = rd; 
    
    for(int i = min(0, iFrame); i<96; i++){
    
        d = map(ro + rd*t); // Surface distance.
        
        // Break, if we're close enough, or have gone too far.
        if(abs(d)<.001 || t>FAR) break; 
        
        // Restricting the minimum jump to the cell boundary distance.
        t += min(d*.8, gCD); 
    }

    return min(t, FAR);
}


// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with 
// limited iterations is impossible... However, I'd be very grateful if someone could 
// prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not always affordable. :)
    const int maxIterationsShad = 32; 
   
    // Coincides with the hit condition in the "trace" function. 
    ro += n*.0015;
    vec3 rd = lp - ro; // Unnormalized direction ray.
    
    // I've added in a touch of jittering to alleviate banding.
    ro += rd*hash21(ro.xy + ro.yz + n.xz)*.01;

    float shade = 1.;
    float t = 0.; 
    float end = max(length(rd), .0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;
    
    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = step(0., rd) - .5;
    gRd = rd;            

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. 
    // Obviously, the lowest number to give a decent shadow is the best one to choose. 
    for (int i = min(0, iFrame); i<maxIterationsShad; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        // shade = min(shade, smoothstep(0., 1., k*d/t)); // Thanks to IQ for this tidbit.
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>end) break; 
        
        
        // So many options here, and none are perfect: 
        // dist += clamp(d, .01, stepDist), etc.
        t += clamp(min(d, gCD), .01, .2);       
        
    }

    // Shadow.
    return max(shade, 0.); 
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
    vec3 e = vec3(.001, 0, 0), mp = e.zzz; // Spalmer's clever zeroing.
    for(int i = min(iFrame, 0); i<6; i++){
		mp.x += map(p + sgn*e)*sgn;
        sgn = -sgn;
        if((i&1)==1){ mp = mp.yzx; e = e.zxy; }
    }
    
    return normalize(mp);
}

// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n){

	float sca = 2., occ = 0.;
    for( int i = min(0, iFrame); i<5; i++ ){
    
        float hr = float(i + 1)*.125/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
    }
    
    return clamp(1. - occ, 0., 1.);  
}


// The normal function is just an application of the finite (central, forward) 
// difference method. The less used curvature function is a second derivative 
// extension of the former -- In fact, you can derive the curvature function 
// from it.
//
// I think it's technically called a discrete finite difference approximation to 
// the continuous Laplace differential operator? Either way, it gives you the 
// curvature of a surface, which is pretty handy.
//
// Original pixelshader usage (I think?) - Cheap curvature: 
// https://www.shadertoy.com/view/Xts3WM
//
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
    return clamp(d/e.x/e.x*amp/16. + offs, -1., 1.)*.5 + .5;
    //return smoothstep(-1., 1., d/e.x/e.x*amp/16. + offs);

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


    // Screen warp, for a more interesting perspective. It works here,
    // but it doesn't always.
    uv /= 1. - dot(uv, uv)*.2;
    
    
	// Camera Setup.
    vec3 ro = vec3(cos(iTime/4.)*.0 + iTime/4., sin(iTime/4.)*.0, -2); // Ray origin.
	vec3 lk = ro + vec3(0, .05*0., .1); // "Look At" position.
 
    // Light positioning.
 	vec3 lp = ro + vec3(.25, .5, 1);// Put it a bit in behind the camera.
	

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
    
    // Rotating the scene a bit.
    rd.xy *= rot2(-PI/8.);
    
    // Precalculate the octagon vertices.
    octagon();
 
    
    // Raymarch to the scene.
    float t = trace(ro, rd);
    
    // Save the object ID.
    int svObjID = objID;
    // Saving the distance and warped object ID.
    vec4 svVal = gVal;
    
    int svPID = pID;
  
	
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
        float spr = 3., amp = 1., offs = 0.;
        float crv = curve(sp, spr, amp, offs);

	    
	    // Light attenuation, based on the distances above.
	    float atten = 1./(1. + lDist*.05);

    	
    	// Diffuse lighting.
	    float diff = max( dot(ld, sn), 0.);
        diff = pow(diff, 4.)*2.; // Ramping up the diffuse.
    	
    	// Specular lighting.
	    float spec = pow(max(dot(reflect(ld, sn), rd), 0.), 32.); 
	    
	    // Fresnel term. Good for giving a surface a bit of a reflective glow.
        //float fre = pow(clamp(1. - abs(dot(sn, rd))*.5, 0., 1.), 2.);
        
		// Schlick approximation. I use it to tone down the specular term.
		float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
		float freS = mix(.15, 1., Schlick);  //F0 = .2 - Glass... or close enough. 
        
          
        // Obtaining the texel color. 
	    vec3 texCol = vec3(.5); 
        
        vec3 txP = sp;
        float sf = 1.5/iResolution.y;
        float ew = .005;
        
        // Saving the color when using the greyscale option.
        vec3 svCol = vec3(0);

        // The extruded grid.
        if(svObjID>0){
            
            // Pylon color.
            float rnd = hash21(svVal.yz + .2);
            vec3 cCol = .5 + .45*cos(TAU*rnd/5. + vec3(0, 1, 2));
            texCol = cCol;
           
            if(svObjID==1 )
               texCol = vec3(.25)*dot(texCol, vec3(.299, .587, .114));
               
            svCol = texCol;
         
            // Frame color, if selected.
            //if(svObjID==2) texCol = texCol.yzx;
            
            #if COLOR == 0
            float gr = dot(texCol, vec3(.299, .587, .114));
            texCol = mix(texCol.zyx, vec3(gr), .8);
            #endif
  
        }
        else {
            
            // Floor. Not used.
            // Brownish.
            texCol = vec3(.5, .275, .125); 
             
        }
        
        // More shading.
        //float d2 = svVal.x;
        //texCol *= max(-d2*6., 0.)*2. + .7;
        
        // Using pseudo science to apply a bit of faux back scatter. :)
        float bl = max(dot(-(vec3(ld.xy, 0)), sn), 0.);
        texCol = texCol + texCol*vec3(1, .0, .2)*bl*8.;
 
        
        

       
        
        // Apply a metallic grunge texture, similar to the Shadertoy one.
        vec3 tx3 = GrungeTex(sp*2.);
        
        vec3 tx = tx3.xyz;
        
        // Applying the texture.
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
        texCol = texCol + svCol*spRef*refTx*rf*8.; 

         
        // Combining the above terms to produce the final color.
        col = texCol*(diff*sh + .5 + vec3(1, .97, .92)*spec*freS*8.*sh);
      
        // Mild curvature
        //col *= crv + .35;
        col *= 1. - abs(crv - .5)*2.;
        
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