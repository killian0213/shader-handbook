// Buffer A (buffer) — Minimal Islamic Pattern by Shane
// https://www.shadertoy.com/view/ffXSWs

/*

    Minimal Islamic Pattern
    -----------------------
    
    This is a minimal Islamic tiling based on an octagon-diamond grid.
    Any basic tutorial featuring the history of tessellation will usually
    touch upon Islamic tiles. I wouldn't say they're difficult to make, but
    even the simple commonly-used ones can involve multiple steps. However, 
    there are a few really simple representations out there, and this is one
    of them.
    
    Without looking too hard, you can see that the construction is based on 
    a semi-regular octagon-diamond grid. There is some further fairly 
    rudimentary subdivision inside the octagons, but that's about it. The 
    process is outlined in more detail below.
    
    I kept the lighting and coloring fairly standard. I like the pattern, 
    but the final render was lacking something, so I applied some 
    postprocessing to liven it up a bit. I really like these patterns when
    constructed in materials like marble and timber, so I'd like to try 
    that at a later date.


    
    Related examples:
    
    // I'm not sure what would constitute the most minimal Islamic 
    // pattern, but it'd make for an interesting exercise. The 
    // following is pretty minimal.
    rotating oriental pattern 2b -- FabriceNeyret2
    https://www.shadertoy.com/view/wddGz7
    
    // A fairly simple four fold symmetry example. Of course, it's all 
    // relative -- Coding up anything more complicated than a square grid 
    // makes my head hurt. :)
    Islamic Fourfold Pattern -- cursorminer
    https://www.shadertoy.com/view/wcyBzW

    // A more common Girih pattern, but requires more work to raymarch.
    Islamic Decagon Star Pattern -- Shane
    https://www.shadertoy.com/view/3cffDB
    
*/

////////////

// Blinking diamonds.
//#define BLINK

////////////


// Global tile scale.
vec2 scale = vec2(1./8.);

// Max ray distance.
#define FAR 10.


// Scene object ID.
int objID; 
 
// IQ's rectangle distance.
float sBoxS(in vec2 p, in vec2 b, float sf){
  
  vec2 d = abs(p) - b + sf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - sf;
}
 

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
    
    //vec2 w = vec2( sdf, abs(pz) - h );
  	//return min(max(w.x, w.y), 0.) + length(max(w, 0.));

    
    // Slight rounding. A little nicer, but slower.
    float sf = .0085;
    vec2 w = vec2(sdf, abs(pz) - h) + sf;
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.)) - sf;
     
}


const vec2 gSc = vec2(1)/2.;

vec2 id0; // Original square grid ID.

// Polygon object and diamond IDs.
int polyID, diaID;
int pID; // Vertex number... Not used here.
vec2 gP; // Local coordinates.


// Grid square vertex and mid edge ID.
const mat4x2 vID = mat4x2(vec2(-.5), vec2(-.5, .5), vec2(.5), vec2(.5, -.5));
const mat4x2 eID = mat4x2(vec2(-.5, 0), vec2(0, .5), vec2(.5, 0), vec2(0, -.5));

// Vertex and edge points.
const mat4x2 v = mat4x2(vec2(-.5)*gSc, vec2(-.5, .5)*gSc, 
                        vec2(.5)*gSc, vec2(.5, -.5)*gSc);
const mat4x2 e = mat4x2(vec2(-.5, 0)*gSc, vec2(0, .5)*gSc, 
                        vec2(.5, 0)*gSc, vec2(0, -.5)*gSc);


// The subdivided octagon, diamond pattern. I wrote this in a hurry, so there'd
// be better ways to go about it, but it works well enough.
vec4 distField(vec2 p){


    // Square grid ID and local coordinates.
    vec2 ip = floor(p/gSc);
    p -= (ip + .5)*gSc;
    
    // ID, set to the square's center.
    vec2 id = ip;
    
    // Square cell ID.
    id0 = id;
    
    // Vertex ID and polygon ID.
    pID = 4;
    polyID = 0;
    
    // Minimum scale. Both are the same, so it's redundant here.
    float minSc = min(gSc.x, gSc.y);
 
    // Smoothing factor.
    float smF = .015;
    
    // Square cell distance.
    float sq = sBoxS(p, gSc/2., smF);
    
    // Diamond rotation.
    vec2 q = abs(p) - gSc/2.;
    q *= rot2(PI/4.);
    
    // Set the distance to the diamonds.    
    float d = sBoxS(q, gSc*cos(PI/4.)/4., smF);
    pID = 4; // Four vertices.
    
    // Initialize the polygon and diamond IDs.
    polyID = 0;
    diaID = 0;
    
    // The octagon is the negative space bounded by the cell square.
    float oct = smax(sq, -d, smF);
    
    
    if(oct<d){
        
        // Octagon distance.
    
        d = oct;
        
        pID = 8;
        
        // Grouping 2x2 cells (four in all) into quadrants.
        vec2 mIP = mod(id, 2.);
        float qrt = mIP.x + mIP.y*2.;
        if(qrt==0.) qrt = 1.;
        else if(qrt==1.) qrt = 0.;
        
        // Orienting each octagon to form the star-like pattern.
        p *= rot2(qrt*PI/2.);
        
        // Construct the inner part.
        
        // L-shape.
        vec2 q2 = p - vec2(-1, 1)*gSc/2.;
        // Square block (filled in).
        float inner = sBoxS(q2, gSc/2., smF/2.);
        float outer = sBoxS(q2, gSc/2. + gSc/4., smF*2.);
        
       
        float innerSq = sBoxS(p*rot2(PI/4.), gSc*cos(PI/4.)/2., smF);
        
        if(inner<0.){
            
            // Inner (top left);
            d = inner;
            
            polyID = 0;
            
            id += vID[1]/2.;
            
            if(innerSq<0.){
               d = smax(d, innerSq, smF);
               polyID = 1;
            }
            else {
               d = smax(d, -innerSq, smF);
               
               polyID = 4; 
            }
        }
        else if(outer>0.){
            
            // Outer (bottom right).
            d = -outer;
            polyID = 0;
            id += vID[3]/2.;
            
            if(innerSq<0.){
               d = smax(d, innerSq, smF);
               polyID = 2;
            }
            else {
               d = smax(d, -innerSq, smF);
               polyID = 4;
            }
        
        }
        else {
             // The middle L-section.
             d = smax(d, -inner, smF);
             d = smax(d, outer, smF);
             
             polyID = 3; 
             
             // Two decorative holes.
             vec2 hp = mix(v[0], v[1], .375) + eID[2]*minSc*.28;
             d = max(d, -(length(p - hp) - .0125));
             hp = mix(v[2], v[1], .375) + eID[3]*minSc*.28;
             d = max(d, -(length(p - hp) - .0125));


        }
        
        // Use the octagon to trim the boundary.
        d = smax(d, oct + .005, smF);
        
        // Extra smoothing.
        d -= (abs(d + .0275) - .0275)*.2;
          
    
    }
    else {
        
        // Diamond.
        int qID = 0;
        
        // Square corner identification.
        if(p.x>=0.) qID += 2;
        if(p.y>=0.) qID += 1;
        if(qID==2) qID = 3;
        else if(qID==3) qID = 2;
        
        polyID = 0;
        
        // Setting the ID to the square corner the diamond
        // resides in.
        id += vID[qID];
        
        // Moving the local coordinates to the
        // center of the diamond.
        p -= v[qID];
        
        // Separate diamond IDs for decorative purposes.
        vec2 mIP = mod(floor(id), 2.);
        diaID = mIP.y + mIP.x==1.? 1 : 0;
         
        // Central holes... Too busy, I think.
        //float hole = d + .07;//length(p); //
        //d = max(d, -(abs(hole - .037) - .003));
        //d = max(d, -(length(p) - .018) + .002);
        
    
    
    }
    
    
     
    gP = p;
    
    // Inner border detailing.
    if(polyID>=-3) d = max(d, -(abs(d + .02) + .002));
    
    if(mod(id0.x + id0.y, 2.)<.5){
       
       // Swapping IDs on a checkered basis to match 
       // height and colors.
       if(polyID==1) polyID = 2;
       else if(polyID==2) polyID = 1;
    
    } 

    return vec4(d, id, polyID);
}


// Object and value storage for later use. 
vec4 vObj;
vec4 val;

// Glow.
vec3 glow;

// The extruded image.
float map(vec3 p3){

    
    
    // Floor.
    float fl = p3.y;

    
    // Scene field calculations.
    vec2 p = p3.xz;
      
    // 2D pattern distance.
    vec4 d4 = distField(p);
    vec2 id = d4.yz;
    val = d4;
    
    // 2D distance.
    float d2 = d4.x; 
     
      
    // Giving the 2D objects some depth.
    float h = .02;
    if(polyID>=3) h = .08;
    
    // Extruding the 2D object.
    float d = opExtrusion(d2, p3.y - h/2. + .5, h/2. + .5);
    
    // Beveling the panels.
    if(polyID>=3){
    
        // Gold panels.
        d += max(d2, -.03)*.5;
        //d += d2*.25; 
        
    }
    else if(polyID>0){
    
        // Black and white panels.
        
        // Rounded surface.
        //d = max(d2, length(vec3(gP.x, p3.y + gSc.x*4. - .025, gP.y)) - gSc.x*4.); 
        // Adding the 2D distance to a 3D one can give you raised surfaces.
        //d += max(d2, -.025)*.25;
        d += d2*.125;
    }
    else {
        // Diamond.
        // Rounded surface: Placing a sphere above the ground plane in the
        // diamond center, then using the 2D distance to restrict it to the
        // diamond boundaries... It's a standard CSG move.
        //d = smax(d2, length(vec3(gP.x, p3.y + gSc.x/2. - .04, gP.y)) - gSc.x/2., .01); 
        d += max(d2, -.035)*.4;
        d += d2*.05;
    }
    
    
    // Simple distance-based accumulation to produce some glow.
    vec3 glI = vec3(.2, .4, 1)*.0025/(.1 + d*d);
    #ifdef BLINK
    float rnd = hash21(id + .232);
    glI = mix(glI, glI*8., smoothstep(.85, .95, sin(TAU*rnd + iTime)));
    #endif
    if(d<.5 && polyID==0 && diaID==0) glow += glI;
    
    
       
    // Object IDs.
    vObj = vec4(fl, d, 1e5, 1e5);
    
    // Minimum scene distance.
    return min(fl, d); 
 
}

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    //
    // IQ's suggestion: Moving the ray's jump-off point closer to the 
    // surface plane to gain some extra speed, especially when in 
    // fullscreen mode.
    float t = (.5 - ro.y)/rd.y, d;
    
    // Initialize the glow.
    glow = vec3(0);
 
    
    for(int i = min(0, iFrame); i<128; i++){
    
        d = map(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(d)<.001 || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.
        
        t += d*.7; 
    }

    return min(t, FAR);
}


// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 normal(in vec3 p){
	
    //return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy),	
    //                      m(p + e.yyx) - m(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    vec3 e = vec3(.002, 0, 0), mp = e.zzz; // Spalmer's clever zeroing.
    for(int i = 0; i<6; i++){
		mp.x += map(p + sgn*e)*sgn;
        sgn = -sgn;
        if((i&1)==1){ mp = mp.yzx; e = e.zxy; }
    }
    
    return normalize(mp);
}

// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with 
// limited iterations is impossible... However, I'd be very grateful if someone could 
// prove me wrong. :)
float softShadow(vec3 ro, vec3 rd, vec3 n, float lDist, float k){

    
    // IQ's suggestion: It's equivalent to moving the ray closer to the
    // surface plane, in order to gain some extra speed.
    lDist = (.5 - ro.y)/rd.y;
   
    // Coincides with the hit condition in the "trace" function. 
    ro += n*.0015;
    
    // A touch of jittering to alleviate banding.
    //ro += rd*hash31(ro + n)*.005;

    float shade = 1.;
    float t = 0.; 
           

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. 
    // Obviously, the lowest number to give a decent shadow is the best one to choose. 
    for (int i = min(0, iFrame); i<48; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        // shade = min(shade, smoothstep(0., 1., k*d/t)); // Thanks to IQ for this tidbit.
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>lDist) break; 
        
        
        // So many options here, and none are perfect: 
        // dist += clamp(d, .01, stepDist), etc.
        t += clamp(d, .01, .2);       
        
    }

    // Shadow.
    return max(shade, 0.); 
}


// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.

// For anyone not familiar with the process, the idea of the function is to very 
// roughly approximate the self shadowing that occurs around a surface when light 
// is being bounced all over the place. In particular, it marches out from the 
// surface in the direction of the surface normal, then determines the overall light
// occlusion based on how far the ray is from any given surface. It also factors in 
// how far away the ray is from orginating surface point itself. You can see all that 
// in the workings.
float calcAO(in vec3 p, in vec3 n){

	float sca = 2., occ = 0.;
    for( int i = 0; i<5; i++ ){
    
        float hr = float(i + 1)*.25/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .75;
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
float curve(in vec3 p, vec3 n, in float spr, in float amp, in float offs){
    
    // Sample spread. Measured in the order of pixels.
    spr /= 450.;
/*  
    // Seven tap curvature. Fine for cheap scenes, but not for all. 
    
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
 
*/ 

    // A five tap version that is pretty close to the seven tap one.
    // There's a tetrahedral version as well.
    
    vec3 an = (abs(n.x)<.99) ? vec3(1, 0, 0) : vec3(0, 1, 0);
    // Basis related vectors.
    vec3 t1 = normalize(cross(an, n));
    vec3 t2 = cross(n, t1);
    
    float d = -map(p)*4.;
    for(int i = min(iFrame, 0); i<4; i++){
        if(i==2) t1 = t2;
		d += map(p + t1*spr);
        spr = -spr;        
    }    

    return clamp(d/spr/spr*amp/16. + .5 + offs, 0., 1.);

}

 
void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    
    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    // Slight spherical screen distortion.
    uv *= .95 + dot(uv, uv)*.1;
    
	// Camera Setup.
    vec3 lk = vec3(iTime/6., 0, iTime/8.);
    vec3 ro = lk + vec3(.008, 1.8, -.125); // Camera position, doubling as the ray origin.
	
    // Light positioning. 
 	vec3 lp = lk + vec3(.5, 1, .5);// Put it a bit in front of the camera.
	

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
    rd.yz *= rot2(.2);
      
 
    
    // Raymarch to the scene.
    float t = trace(ro, rd);
    
    // Save the object ID.
    //float svObjID = objID;
    objID = 0; float minDist = 1e5;
    
    for(int i = 0; i<4; i++){
       if(vObj[i]<minDist){
           minDist = vObj[i];
           objID = i;
       }
    }
    
    // Diamond ID -- Last minute addition.
    int svDID = diaID;
    
    // Stored values from the raymarching function -- 2D distance, ID, etc.
    vec4 svVal = val;
    
    //vec2 svP = gP;
 	
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
	    float lDist = max(length(ld), .0001);
    	
    	// Normalize the light direction vector.
	    ld /= lDist;

        
        
        // Shadows and ambient self shadowing.
    	float sh = softShadow(sp, ld, sn, lDist, 16.);
    	float ao = calcAO(sp, sn); // Ambient occlusion.
        //sh = min(sh + ao*.25, 1.);
        
        
        // Curvature.
        float spr = 2., amp = 1., offs = .0;
        float crv = curve(sp, sn, spr, amp, offs);

	    
	    // Light attenuation, based on the distances above.
	    float atten = 1./(1. + lDist*.05);

            
        // Obtaining the texel color. 
	    vec3 texCol; 
        
        
        vec3 tx = tex3D(iChannel0, sp/2. + hash21(svVal.yz + .02)*.5, sn);
        
        
        vec3 txP = sp;
        float sf = 1.5/iResolution.y;
        float ew = .005;
        int svPolyID = int(svVal.w);

        // The extruded grid.
        if(objID>0){
            
            

            // Coloring.
            texCol = vec3(1);
            
            
            // Random panel ID.
            vec2 id = svVal.yz;
            float rnd = hash21(id + .1);
             
            // Set some of the diamonds to the metallic material.
            if(svDID==1) svPolyID = 3;
           
           
            if(svPolyID >= 3) texCol = vec3(rnd*.05 + .05);  // Metallic panels.
            if(svPolyID == 2) texCol = vec3(rnd*.05 + .5); // White inner star panels.
            if(svPolyID == 1) texCol = vec3(rnd*.05 + .075); // Dark inner star panels.
              
            // Coloring the blue diamond objects.
            if(svPolyID == 0){
                
                texCol = .5 + .45*cos(TAU*rnd/5. + vec3(0, PI/2., PI)*.8 - .25);
                texCol = texCol.zyx*.2; // Blue.
                
                // Alternative purple diamonds... Too much.
                //vec2 id0 = mod(floor(id), 2.);
                //texCol = mix(texCol.yxz*1.5, texCol, float(mod(id0.y , 2.)<.5));
            }
            
            // Gold trim.          
            if(svPolyID>=3) texCol *= vec3(1.2, .9, .4);
            //if(svDID==1) texCol /= vec3(1.2, .9, .4);
            
            /*
            // Inner jewel diamond frames. Another failed coloring experiment. :)
            if(svPolyID==4){ 
                  
                vec2 iid = floor(sp.xz/gSc + .5);
                if(mod(iid.x + iid.y, 2.)<.5){
                   if(mod(floor(iid.y), 2.)<.5) texCol /= vec3(1.2, .9, .4)/1.5;
                   else texCol /= vec3(1.2, .9, .4)*3.;
                }
            }
            */
            
            // Texturing.
            texCol *= tx*4.;
 
        }
        else {
            
            // The floor. Not seen.
            texCol = vec3(.01);
            svPolyID == -1;
           
        }
        
        
        /////////////////        
       
        // Ambient light.
        //
	    // Quick Lighting Tech - blackle
        // https://www.shadertoy.com/view/ttGfz1
        // Studio and outdoor.
        //float amb = .5*pow(length(sin(sn*2.)*.5 + .5)/sqrt(3.), 2.);
        float amb = .5*length(sin(sn*2.)*.5 + .5)/sqrt(2.)*smoothstep(-1., 1., -sn.z); 
 
       
        ///////////////
        // Material properties.
        
        float gr = dot(tx, vec3(.299, .587, .114));
        float type = .1; 
        float rough = gr*1.;// Texture-based roughness.
        float fresRef = .5;
        
        // Metallic and diamond objects.
        if(svPolyID >= 3 || svPolyID == 0){
            type = .8;
            rough = gr*2.;
            fresRef = svPolyID == 0? 1. : .5;
        }
  
        // Standard BRDF dot product calculations.
        vec3 h = normalize(ld - rd); // Half vector.
        float ndl = dot(sn, ld);
        float nr = clamp(dot(sn, -rd), 0., 1.); // Leaving it here.
        float nl = clamp(ndl, 0., 1.);
        float nh = clamp(dot(sn, h), 0., 1.);
        float vh = clamp(dot(-rd, h), 0., 1.); 
        // Fresnel related.
        vec3 f0 = vec3(.16*(fresRef*fresRef)); 
        // For metals, the base color is used for F0.
        f0 = mix(f0, texCol, type);
        vec3 FS = f0 + (1. - f0)*pow(1. - vh, 5.); // Fresnel-Schlick reflected light term.

        // BRDF style specular and diffuse calculations. There is so little
        // extra work involved, but the lighting quality is much better.
        vec3 spec = getSpec(FS, nh, nr, nl, rough);
        vec3 diff = getDiff(FS, nl, type);
        float speR = pow(nh, 5.);
  

//////////////////
        
        // Combining the above terms to produce the final color.
        col = texCol*(diff*sh + spec*sh*2. + amb*(sh*.5 + .5));
        
        // Backscatter.
        float bac = clamp(dot(sn, -normalize(vec3(ld.x, 0, ld.z))), 0., 1.);
        col += col*vec3(1, .7, .4)*bac*8.;
        
        // Applying the curvature shade.
        col *= crv*1.1 + .2;
        // Dark edges. I'll sometimes use this as a debug to see how 
        // well the curvature function is working.
        //col *= 1. - abs(crv - .5)*2.;

         
        // Shading.
        col *= ao*atten;
        
        
        // Faux specular reflection -- Requires the "Forest" cube map.
        vec3 rf = reflect(rd, sn); // Surface reflection.
        vec3 rTx = texture(iChannel1, rf).xyz; rTx *= rTx;
        float rF = svPolyID>=3 || svPolyID==0? 32. : .05; // || svPolyID==0
        if(svPolyID>=0) col = col + col*speR*rTx*rF;  
  
        
        // It's sometimes helpful to check things like shadows and AO by themselves.
        //col = vec3(ao*(diff*sh + .1));
          
	
	}
    
    // Applying the glow. There are better ways to apply it, but
    // it's a minor effect for this example,so this will do.
    col += col*glow;
    
    
    // Horizon fog. Not visible here, but provided for completeness.
    //col = mix(col, vec3(0), smoothstep(0., .99, t/FAR));
          
    
    // Rought gamma correction.
	fragColor = vec4(max(col, 0.), t);
	
}