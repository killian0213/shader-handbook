// Buffer A (buffer) — Cube Face Animation by Shane
// https://www.shadertoy.com/view/tXfcWs

/*

    Cube Face Animation
    -------------------
    
    This is a fairly common walking cube animation. If you've spent any time 
    perusing repetitive short form geometric keyframe sequences, you're likely 
    to have come across some kind of variation. Anyone with a reasonable 
    knowledge of keyframe animation and 3D movement could make one. I was able 
    to put an untextured one together fairly quickly.
    
    Texturing raymarched keyframe objects inside the pixelshader environment, 
    on the other hand, requires more work, so that took longer. I've done it 
    before, so it wasn't too bad, but texturing things like this can be messy.
    It's a task much better suited to a vertex-style pipeline that stores UV
    coordinates, that's for sure.
    
    Anyway, it's customary to use an isometric camera for things like this to 
    provide an illusory feel, so I've done that. However, there is an option to 
    use a more conventional camera setup as well.
    
    I'm not entirely sure about the mid 2000s demoscene design choice, but I'm 
    going to stick with it. :) I think I might do another cleaner version with 
    a regular camera later on.


    
    Other cube animations:
    
    // Another fairly common cube animation.
    //
    Cube of Cubes - Flyguy
    https://www.shadertoy.com/view/Xll3DM
    
    // Very cool. Technically a square animation, but
    // I've seen it done with cubes too.
    //
    Bit for bit -  anastadunbar 
    https://www.shadertoy.com/view/MsV3Wt
    

*/
 

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

// Cube scale.
vec3 gSc = vec3(1)/4.;


// Object rotation, with some optional mouse movement.
vec3 objMove(vec3 p){

    // Moving the object up.
    p -= vec3(0, gSc.y, 0);
    
    #ifndef ISOMETRIC
    p.xz *= r2(PI/4.);
    #endif
    
 
    if(iMouse.z>1.){
        // Mouse override.
        vec2 ms = (iMouse.xy - iResolution.xy*.5)/iResolution.xy*PI;
        p.yz *= r2(-ms.y);  
        p.xz *= r2(-ms.x);   
    } 
 
    
    return p;

}



// Storage for four object distances.
vec4 objD;

// Box ID. There are 7 all up.
int bxID;

// Global rotational matrices and position. 
// Used for texturing.
mat2 gXZ, gYZ, gXY;
vec3 gQ;
   

float map(vec3 p){
   
     
    // Floor.
    float fl = p.y + gSc.y*2.;
 
    
    // Object positioning and movement.
    vec3 q = p;
    
    
    q = objMove(q);
    
    // Scale.
    vec3 sc = gSc;
    
    
    // The cube itself. Note the extra one. That's just a hack to 
    // ensure no cube roundness.
    float frSz = .01;
    float bx = sBoxS(q, sc/2., .0);
 
    
     // Total scenes.
    float sceneTotal = 6.;
    float tm = iTime/2.;  // General time.
    float fT = fract(tm); // Fraction time.
    float fNum = mod(floor(tm), sceneTotal); // Current frame number.

    mat2 aXZ, aYZ, aXY;
    
    vec3 svQ = q;

    vec3 start = vec3(0);
    vec3 pivot = vec3(0);


    fT = smoothstep(.0, .7, fT);
    
    
    // Set the minimum distance and box ID to the central box.
    float d = bx;
    bxID = int(sceneTotal);
    // Set the global coordinates and rotation matrices to it also.
    gQ = q;
    gXZ = gYZ = gXY = mat2(1, 0, 0, 1);
    

    
    // Iterate through all six cubes, move them, then determine
    // if any are closer than the central cube.
    for(int i = 0; i<6; i++){
     
        
        // Each cube is on a separate frame number.
        float iNum = mod(fNum + float(i), sceneTotal);
        
        // Just a way to check half the postions, instead of all 6.
        float iNumM3 = mod(iNum, sceneTotal/2.);
        // Even and odd cubes have opposing starting points and pivots. 
        float dir = mod(iNum, 2.) == 0.? 1. : -1.;
        
      
        // Set all 2D rotaion matrices to the identity.
        aXZ = aYZ = aXY = mat2(1, 0, 0, 1); 

        
        
        
        // Six different movements. Set the XZ, YZ and XY rotations, the 
        // start and pivot points for each frame. The opposite sides have 
        // similar movement in the opposing directions, etc., so we only 
        // need check three scenarios.
        if(iNumM3==0.){
             
            // Start, pivot and rotation for frame 1 and 4.
            start = dir*vec3(0, sc.y, 0);
            pivot = dir*vec3(0, -sc.y/2., sc.z/2.);
            aYZ = r2(mix(0., -PI, fT));
            
        }    
        if(iNumM3==1.){
            
            // Start, pivot and rotation for frame 2 and 5.
            start = dir*vec3(0, 0, -sc.z);
            pivot = dir*vec3(-sc.x/2., 0, sc.z/2.);
            aXZ = r2(mix(0., PI, fT));
           
        }    
        if(iNumM3==2.){
            
            // Start, pivot and rotation for frame 3 and 6.
            start = dir*vec3(sc.x, 0, 0);
            pivot = dir*vec3(-sc.x/2., -sc.y/2., 0);
            aXY = r2(mix(0., PI, fT));
          
        }  
        
        // Using the above values to set up the cube position.
        vec3 q2 = q;
        q2 -= start;
        q2 -= pivot;
        q2.xz *= aXZ;
        q2.yz *= aYZ;
        q2.xy *= aXY;
        q2 += pivot;

        // Cube distance for this position.
        float dI = sBoxS(q2, sc/2., .0);
 
        if(dI<d){ 
        
            d = dI; 
            bxID = i; 
            
            gXZ = aXZ; 
            gYZ = aYZ; 
            gXY = aXY;
            
            if(iNumM3>=0.){
               q2.xy *= r2(PI);
               gXY *= r2(PI);
            } 
            if(iNumM3>=1.){
                q2.yz *= r2(PI);
                gYZ *= r2(PI);
            }
            if(iNumM3>=2.){
                q2.xz *= r2(PI);
                gXZ *= r2(PI);
            }            
            
            svQ = q2;            
            gQ = q2;
            

        }
    
    
    }
 
    // Cutting out crosses to turn the cubes into frames.
    #ifdef HOLES
    float ew = sc.x*1./4.;
    float cr = sBoxS(svQ.xy, sc.xy/2. - ew, .0);
    cr = min(cr, sBoxS(svQ.yz, sc.yz/2. - ew, .0));
    cr = min(cr, sBoxS(svQ.xz, sc.xz/2. - ew, .0));
    d = max(d, -cr);
    #endif
 
 
    // Object distances.
    objD = vec4(fl, d, 1e5, 1e5);
     
    // Minum object distance.
    return min(fl, d);
    
}

float rayMarch(vec3 ro, vec3 rd){
    
    float d, t = 0.;//hash31(ro + rd)*.25; // Glow jitter.
    vec2 dt = vec2(1e8, 0); // IQ's edge desparkle trick.


    const int iter = 96;
    int i = 0;
     
    for (i = 0; i<iter; i++) {
       
        d = map(ro + rd*t);
       
        // IQ's clever edge desparkle trick. :)
        if (d<dt.x) { dt = vec2(d, t); } 

        if (abs(d)<.001 || t>FAR){
            break;
        }
        
        // Advance the ray.
        t += d*.9;
    }
    
    if(i == iter - 1) { t = dt.y; }

    // Don't go further than the far plane.
    return min(t, FAR);
}


// Ambient occlusion. Based on IQ's original.
float cao(in vec3 p, in vec3 n){

	float sca = 2., occ = 0.;
    for( int i = 0; i<6; i++ ){
    
        float hr = .01 + float(i)*.35/6.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
        //if(occ>1e5) break;
    }
    
    return clamp(1. - occ, 0., 1.);  
    
}

// Standard normal function. It's not as fast as the tetrahedral calculation, 
// but more symmetrical.
vec3 nr(in vec3 p) {
	
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



/*
// Cubic curvature function.
//
// spr: sample spread, amp: amplitude, offs: offset.
float curve(in vec3 p, in float spr, in float amp, in float offs){

    float d = map(p);
    
    spr /= 450.;

    // Cubic.
    vec2 e = vec2(spr, 0); 
	float d1 = map(p + e.xyy), d2 = map(p - e.xyy);
	float d3 = map(p + e.yxy), d4 = map(p - e.yxy);
	float d5 = map(p + e.yyx), d6 = map(p - e.yyx);
    return clamp((d1 + d2 + d3 + d4 + d5 + d6 - d*6.)/e.x/e.x/16.*amp + offs + .5, 0., 1.);

}
*/

 
// The simple face pattern.
vec3 pattern(vec2 p, float scl){

     
    // Scale.
    vec2 sc = gSc.xy*scl;
    
    //if(scl>.26 && mod(floor(p.y/sc.y), 2.)==1.) p.x += sc.x/4.;
    
    // Square grid ID.
    vec2 ip = floor(p/sc);
    
    // Hacky random square subdivision.
    if(hash21(ip + .31)<.5){
        sc /= 2.;
        ip = floor(p/sc);
    } 
    if(hash21(ip + .41)<.5){
        sc /= 2.;
        ip = floor(p/sc);
    }   
    
    // Local coordinates.
    p -= (ip + .5)*sc;
 
    // Grid square. 
    float d = sBoxS(p, sc/2., 0.);
    
    // Random color.
    float rnd = hash21(ip + .1);
    vec3 pCol = .5 + .45*cos(TAU*rnd/4. + vec3(0, 1, 2)*1.);
    
    // Making it greyscale. I'm keeping the color above, just in case
    // I'd like to use it later.
    float gr = dot(pCol, vec3(.299, .587, .114))*.5 + .5;
    pCol = vec3(gr);
    
    // Blinking... Not for this examples.
    //float blink = smoothstep(.9, .97, sin(TAU*hash21(ip + .2) + iTime)*.5 + .5);
    //pCol = mix(vec3(gr), vec3(gr)*2., blink);
    
    
    // Rendering the outline and shaded square.
    return mix(pCol*.1, pCol, 1. - smoothstep(0., .002, d + .003));

}


void mainImage( out vec4 c, vec2 u ){

    
    // Screen coordinates.
    u = (u - iResolution.xy*.5)/iResolution.y;
      
    // Unit direction ray, origin vector and light vector.
    vec3 r, o, l;
        

    #ifdef ISOMETRIC

    // Orthographic camera.
	o = vec3(u, -4);
    // A unit direction ray, without the UV vanishing horizon component.
    r = vec3(0, 0, 1); 
    
    // Directional light.
    l = normalize(vec3(1.5, 3.5, 1.35));
    
    // Extra orientation to give the object a
    // flat top hexagon perspective.
    o.xy *= r2(PI/6.);
    //r.xy *= r2(PI/6.);
  
    // Isometric angle. 
    float isoA = atan(sqrt(.5));
    o.yz = r2(-isoA)*o.yz;
    r.yz = r2(-isoA)*r.yz;
    o.xz = r2(-PI/4.)*o.xz;
    r.xz = r2(-PI/4.)*r.xz;

    // Extra camera positioning.
    o = o + vec3(0, gSc.y, .0);
    
    #else
    
    // More conventional camera setup.
    
    // Screen distortion.
    u *= .9 + dot(u, u)*.3;
    
    
    
    ///o = vec3(cos(iTime/4.)*.0, sin(iTime/4.)*.0 - .0, -1); 
	o = vec3(gSc.x*sin(iTime/2.), gSc.y*4., -gSc.z*6.); // Camera position, doubling as the ray origin.
    
    vec3 lk = vec3(0, gSc.y, 0);//vec3(0, -.25, iTime);  // "Look At" position.
 
    // Light positioning. 
 	l = lk + vec3(.25, .75, 0);// Put it a bit in front of the camera.
	

    // Using the above to produce the unit ray-direction vector.
    float FOV = 2./3.; // FOV - Field of view.
    vec3 fwd = normalize(lk - o); // Forward.
    //if(dot(fwd, vec3(fwd.z, 0, -fwd.x))==0.) fwd = normalize(fwd - vec3(0, 0, .00001));
    vec3 rgt = normalize(cross(vec3(0, 1, 0), fwd));// Right. 
    // "right" and "forward" are perpendicular normals, so the result is normalized.
    vec3 up = cross(fwd, rgt); // Up.
    
    // Camera.
    //mat3 mCam = mat3(rgt, up, fwd);
    // r - Ray direction.
    //r = mCam*normalize(vec3(uv, 1./FOV));//
    r = normalize(u.x*rgt + u.y*up + fwd/FOV);
    
    #endif
 
    
    
    // Raymarch the scene.
    float t = rayMarch(o, r); 

    
    // Object ID.
    int objID = objD.x<objD.y && objD.x<objD.z? 0 : objD.y<objD.z? 1 : 2;
    
    // Box ID.
    int svBID = bxID;
    
    // Global cube position and rotation matrices.
    vec3 svQ = gQ;
    mat2 svXZ = gXZ, svYZ = gYZ, svXY = gXY;
    
 
    
    // Scene color, initialized to zero.
    c = vec4(0);
    
    // If we've hit an object, light it up.
    if(t<FAR){
    
        // Surface hit point and normal.
        vec3 p = o + r*t, n = nr(p);
        
        // Shadows and ambient self shadowing.
    	float sh = softShadow(p, l, n, 16.);
        float ao = cao(p, n);
        
        // Light calculations.
        vec3 ld = l - p;
        float lDist = length(ld);
        ld /= lDist;
        
        // Attenuation.
        float atten = 1./(1. + lDist*lDist*.07);
        
        // Curvature.
        //float spr = 1.25, amp = 1., offs = .0;
        //float crv = curve(p, spr, amp, offs);
        
        // Texture value.
        vec3 tx = vec3(0);
        // Normal copy.
        vec3 svN = n;
        
         vec3 ip; // Cube-face square ID.
 
       
        if(objID>=1){
         
            // Animated cubes.
             
               
            // Surface color.
            c.xyz = .5 + .45*cos(TAU*hash21(vec2(svBID, 3))/12. + vec3(0, 1, 2));
            c.xyz = mix(c.xyz, vec3(1, .7, .4), .5);
        
            // Debug normal coloring.
            //c.xyz *= n.yzx + 1.5;
            
             
            // Applying the object move function to the texture normal.
            #ifndef ISOMETRIC
            svN.xz *= r2(PI/4.);
            #endif
            if(iMouse.z>1.){
                // Mouse override.
                vec2 ms = (iMouse.xy - iResolution.xy*.5)/iResolution.xy*PI;
                svN.yz *= r2(-ms.y);  
                svN.xz *= r2(-ms.x);   
            } 
            
            // Moving the texture normal.
            if(svBID<6){
                svN.xz *= svXZ;
                svN.yz *= svYZ;
                svN.xy *= svXY;
            }
            
            // Cube texture scale.
            float sc = 1./4.;
            
            // Cube texture coordinates.
            vec2 tuv = svQ.xy;
            if(abs(svN.x)>.5) tuv = svQ.yz;
            if(abs(svN.y)>.5) tuv = svQ.xz;
            vec3 cCol = pattern(tuv - vec2(svBID, 7)*sc, sc);
            // Cube texture cell IDs.
            ip = vec3(cCol.yz, sign(svN.z)*gSc.z);
            if(abs(svN.x)>.5) ip = vec3(sign(svN.x)*gSc.x, cCol.yz);
            if(abs(svN.y)>.5) ip = vec3(cCol.x, sign(svN.y)*gSc.y, cCol.z);
            
            /* 
            // Technically more correct, but involves three taps.
            vec3 txN = abs(svN);
            vec3 cColX = pattern(svQ.yz, sc);// + float(svBID)*gSc.x
            vec3 cColY = pattern(svQ.xz, sc);
            vec3 cColZ = pattern(svQ.xy, sc);
            vec3 cCol = mat3(cColX, cColY, cColZ)*txN;
            */
            
            //float gr = dot(cCol, vec3(.299, .587, .114)); // Greyscale.
            
            // Cube face cell shading.
            c.xyz *= cCol; 
        
            // Applying some extra texture.
            tx = tex3D(iChannel0, svQ, svN);
            c.xyz *= tx*2.;//*1. + .15;
            
            
            /* 
            // Normal-based coloring. Not used here.
            vec3 txN = svN;
            c = vec4(.95, .175, .175, 0);
            if(abs(txN.x)>.5) c = vec4(1, .5, .5, 0);
            if(abs(txN.y)>.5) c = vec4(1, .75, .75, 0);
            */
              
        
        }
        else{
           
           // The background texture.
           svQ = p;
           
           // Color.
           c.xyz = vec3(1, .7, .4);
           
           // Pattern.
           vec3 pat = pattern(r2(PI/4.)*p.xz, 1./1.4214);
           
           // Pattern square cell ID.
           ip = vec3(pat.x, 1, pat.z);
           
           // Applying the pattern shade.
           c.xyz *= pat;
           
           // Texturing.
           tx = tex3D(iChannel0, p/2., n);
           c.xyz *= tx;

           
        }
        
        // Greyscale texture value.
        float gr = dot(tx, vec3(.299, .587, .114));
        
       //////////////
        // Material properties for the cubes.
        float fresRef = .75;  // Reflectivity.
        float type = 1.;     // Dielectric or metallic.
        float rough = gr*2.;   // Roughness.
        
        // Floor material.
        if(objID==0){
             type = 0.; // Dielectric.
             
        }
      

 
        // Standard BRDF dot product calculations.
        vec3 h = normalize(ld - r); // Half vector.
        float ndl = dot(n, ld);
        float nr = clamp(dot(n, -r), 0., 1.);
        float nl = clamp(ndl, 0., 1.);
        float nh = clamp(dot(n, h), 0., 1.);
        float vh = clamp(dot(-r, h), 0., 1.);  
        
        
        //float bac = clamp(dot(n, -ld), 0., 1.); // Back scatter light.
        float bac = clamp(dot(n, -normalize(vec3(ld.x, 0, ld.z))), 0., 1.);
        bac = (bac*.5 + .5)*(n.y*.5 + .5); // Apply the back scatter.
        c.xyz += c.xyz*bac*vec3(.5, .05, .1);
 
        // Specular microfacet (Cook- Torrance) BRDF.
        //
        // F0 for dielectics in range [0., .16] 
        // Default FO is (.16 * .5^2) = .04
        // Common Fresnel values, F(0), or F0 here.
        // Water: .02, Plastic: .05, Glass: .08, Diamond: .17
        // Copper: vec3(.95, .64, .54), Aluminium: vec3(.91, .92, .92), 
        // Gold: vec3(1, .71, .29), Silver: vec3(.95, .93, .88), 
        // Iron: vec3(.56, .57, .58).
        vec3 f0 = vec3(.16*(fresRef*fresRef)); 
        // For metals, the base color is used for F0.
        f0 = mix(f0, c.xyz, type);
        vec3 FS = f0 + (1. - f0)*pow(1. - vh, 5.); // Fresnel-Schlick reflected light term.
        
        // BRDF style specular and diffuse calculations. There is so little
        // extra work involved, but the lighting quality is much better.
        vec3 spec = getSpec(FS, nh, nr, nl, rough);
        vec3 diff = getDiff(FS, nl, rough, type);
        /////////////////////
             
        
        // Edge lines. Based on curvature. Not used here.
        //c = mix(c, min(c*.0, 1.), abs(crv - .5)*2.*.5);
      
        
        // Applying lighting and ambient occlusion.
        c.xyz = c.xyz*(diff*sh + spec*sh*4. + .5)*ao*atten;
        
        
        // Specular reflection.
        vec3 ref = reflect(r, n); // Surface reflection.
        vec3 refTx = texture(iChannel1, ref).xyz; refTx *= refTx; // Cube map.
        float spRef = pow(nh, 5.);
        float rf = (objID == 0)? .5 : 8.;
        c.xyz = c.xyz + c.xyz*spRef*refTx*rf*ao;
 
  
        // Reddish electric charge. Hacked in at the last minute.
        // It needs more thought put into it.
       
        // Floor and cube distances.
        float d2;
        float tOffs = .5;
        float tDir = -1.;
        // Coordinates.
        vec3 pp = p - vec3(0, gSc.y, 0);
        pp.xz *= r2(PI/4.);
        vec3 q = mix(ip, floor(pp*64.)/64., .65);
        
        // Movement and distance fields.
        if(objID==0){ q.xz -= vec2(-.5, .25); tOffs = -.5; tDir = -1.; }
        q = abs(q);
        d2 = max(max(q.x, q.z), q.y);
        if(objID==0) d2 =  q.z - .5;//max(q.x, q.z) - .5;
        float hi = abs(mod(d2 + tOffs + tDir*iTime, 2.) - 1.);
        
        // Coloring.
        vec3 cCol = vec3(.022, .02, .018)*c.xyz*c.xyz*1./(.001 + hi*hi);
        cCol = mix(cCol.xzy, cCol, smoothstep(0., 1., n3D(p*4.)));
        if(objID>0) c.xyz += cCol;
        else c.xyz += cCol*.5;
        
      
     
    }
    
    
    
    // Applying fog: This fog begins at 90% towards the horizon.
    float ff = .15;
    #ifdef ISOMETRIC
    ff = .05;
    #endif
    c = mix(c, vec4(1, .7, .4, 0)*ff, smoothstep(.2, .9, t/FAR));
 
  
    // Save to "Buffer A" for post processing.
    c = vec4(max(c.xyz, 0.), t);
    
    
}