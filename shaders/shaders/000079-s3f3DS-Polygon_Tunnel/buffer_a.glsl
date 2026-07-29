// Buffer A (buffer) — Polygon Tunnel by Shane
// https://www.shadertoy.com/view/s3f3DS

/*

    Polygon Tunnel
    --------------

    This is a fairly standard spiral polygon tunnel example. There are plenty
    of them on Shadertoy, and on the internet in general. Basically, you create
    repeat polygon segments, then rotate them along the Z-axis.
    
    In this case, I've chosen a stock standard triangle. To add a little variety, 
    I've randomly applied some lit-up window elements along the polygon walls. 
    None of it is particularly hard to do... If you're comfortable with basic 
    CSG moves and polar repetition, it shouldn't be too difficult to reproduce.
    
    I wrote this quite some time ago, but only recently put in some finishing 
    touches, which included glow and DOF. I like these kinds of things with more
    naive lighting as well, so might post others at a later date.
  
    
    
    Other examples: 

   
    // Diatribes has a lot of interesting polygon-based tunnel examples. 
    // I really like the heavily glow-lit aesthetic, which is kind of 
    // reminiscent of path-traced light emission. I have a few examples 
    // along these lines that I'd like to post at some stage.
    Hacker Bunker 1 -- diatribes
    https://www.shadertoy.com/view/sfBXRG
    
    // A hexagon based tunnel example.
    Hyperkart -- diatribes
    https://www.shadertoy.com/view/scS3Wm
    
    // A really nicely shaded square tunnel with
    // a pretty small code footprint.
    大龙猫 - Tunnel Cable -- totetmatt 
    https://www.shadertoy.com/view/MfVfz3



*/
 
 
 // Surface structure: There are 4, but virtually anything will work.
// Cellular: 0, Gyroid: 1, Gyroid with 2 levels: 2, Gyroid (reverse space): 3.
#define SURFACE 0


////////////////////

// Far plane.
#define FAR 50.

// Loop... anti-unrolling hack. :)
#define ZERO min(iFrame, 0)
/////////////////////



// A slight variation on one of Dave Hoskins's hash functions,
// which you can find here:
//
// Hash without Sine -- Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
// 1 out, 2 in...
float hash21(vec2 p){
    
	vec3 p3  = fract(vec3(p.xyx)*.1031);
    p3 += dot(p3, p3.yzx + 42.123);
    
    return fract((p3.x + p3.y) * p3.z);
    
    // Animated.
    //p3.x = fract((p3.x + p3.y) * p3.z);
    //return sin(p3.x*TAU + iTime); // Animation, if desired.
     
}

 
// A slight variation on one of Dave Hoskins's hash functions,
// which you can find here:
//
// Hash without Sine -- Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
// 1 out, 3 in...
float hash31(vec3 p3)
{
	p3  = fract(p3*vec3(.6031, .5030, .4973));
    p3 += dot(p3, p3.zyx + 43.527);
    return fract((p3.x + p3.y) * p3.z);
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

 
// IQ's 2D box function, with added smoothing factor.
float sBoxS(in vec2 p, in vec2 b, in float rf){
  
  vec2 d = abs(p) - b + rf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rf;
    
}

// The path is a 2D sinusoid that varies over time, depending upon the frequencies, 
// and amplitudes.
vec2 path(in float z){ 
    
    return vec2(0); // Straight line.
    /*
    // Curved path.
    float a = sin(z*.11);
    float b = cos(z*.14);
    return vec2(a*2. - b*1.5, b*1.7 + a*1.5); 
    */
} 
 
// Surface ID and glow.
int gID;
vec3 glow; 

// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h, in float sf){

    // Slight rounding. A little nicer, but slower.
    vec2 w = vec2(sdf, abs(pz) - h) + sf;
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.)) - sf;
}
 
 

// Ray origin, ray direction, point on the line, normal. 
float rayLine(vec2 ro, vec2 rd, vec2 p, vec2 n){
   
   // This it trimmed down, and can be trimmed down more. Note that 
   // "1./dot(rd, n)" can be precalculated outside the loop. However,
   // this isn't a GPU intensive example, so it doesn't matter here.
   //return dot(p - ro, n)/dot(rd, n);
   float dn = dot(rd, n);
   return dn>0.? dot(p - ro, n)/dn : 1e8;   

}  

// Global cell boundary distance variables.
vec3 gDir; // Cell traversing direction.
vec3 gRd; // Ray direction.
float gCD; // Cell boundary distance.
// Box dimension and local XY coordinates.
vec3 gSc; 
vec3 gP;

vec4 gVal;

 

// Color routine - Based on IQ's cosine palette.
vec3 getCol(vec2 p){

    float range = hash21(p + .011); // 0 to 1.
    float saturation = .9; //hash21(p + .031)*.5 + .5; // 0 to 1.
    return .5 + .45*cos(TAU*range/2.75 + vec3(0, 1.57, 3.14)*saturation + 3.);
     
}

// Not entirely correct, but good enough for this example. 
// Based on a routine found here:
//
// Regular Polygon SDF - BasmanovDaniil
// https://www.shadertoy.com/view/MtScRG
//
float poly(vec2 p, float vertNum, float r){

    float a = mod(atan(p.x, p.y), TAU/vertNum) - TAU/vertNum/2.;
    float inRad = r*cos(TAU/vertNum/2.);
    return cos(a)*length(p) - inRad;
   
}

// Global color and object distance container.
vec3 gCol;
vec4 vDist;

// Perturbed gyroid (or cellular) tunnel function: In essence, it's one or two
// smoothly combined gyroid functions, with a cylindrical hole (wrapped around the
// camera path) smoothly carved out from them.
//
float map(vec3 p3){

   
    // Scale.
    const vec3 sc = vec3(1, 1, 2); 
    
    // Arranging for the tunnel to follow the path. I set the path to 
    // a straight line, so it's redundant here, but it's there in the
    // event that I want to make changes.
    vec3 p = p3 - vec3(path(p3.z), 0);
 
    
    vec3 svP = p;
 
    float ipZ = floor(p.z/sc.z) + .5;
    p.z -= ipZ*sc.z;
     
    // Extra outer tunnel walls. Not used here.
    float outer = -1e5;//poly(p.yx, 6., 3.);   
    
    
    
    // Rotating the each polygon segment along the Z-axis.
    p.xy *= rot2(-floor(ipZ)*PI/6.);

    // Tunnel polygon (triangle) walls. 
    float d2 = poly(p.xy, 3., 3.);
    d2 = -d2; // Negative space.
    
    // Truncating the tunnel walls with the outer tunnel.
    // Redundant here though.
    d2 = min(d2, -(outer + .5));   
  
    // Extruding the 2D (negative) polygon along Z to construct
    // this particular segment.
    float d = opExtrusion(d2, p.z, sc.z/2.  - .025, .01);
    // The surrounding frame.
    float frame = opExtrusion(abs(-d2 + .05) - .05, abs(p.z) - sc.z/2. + .15, .1, .03);
    
   
    // Adding some random subdived window guages to each of the
    // polygon panel sides.
    // Triangle polar repeat.
    p.xy *= rot2(TAU/12.); // Extra rotation.
    float aN = 3.;
    float a = atan(p.y, p.x)/TAU;
    float ia = (floor(a*aN) + .5)/aN;
    p.xy *= rot2(-ia*TAU);
    p.x -= 1.5;
    
    // Repeat random subdivided control panel lights, or something
    // to that effect. I put this together without a lot of forethought. :)
    vec2 q = p.yz;
    vec2 wSc = vec2(2, 2)/3.;
    float wSz = .25;
    vec2 wID = floor(q/wSc) + .5;
    // Random subdivision.
    if(hash21(wID + vec2(ipZ, floor(ia*aN - .5)))<.5){ 
        wSc /= 2.; wSz /= 2.; 
        wID = floor(q/wSc) + .5;
    }
    // The sunken window construction.
    q = q - clamp(wID, -floor(vec2(1, .5)/wSc)-.5, floor(vec2(1, .5)/wSc) + .5)*wSc;
    float port = sBoxS(q, vec2(wSz), .05);//length(p.yz) - .5;
    float window = smax(max(port, -(port + .08)), d - .02, .03);
    
    // Randomly omit some of the control panel lights to break things up.
    int doLight = 1;
    if(hash21(wID + vec2(ipZ, floor(ia*aN - .5))  + .51)<.35){
    //if(mod(floor(ia*aN - .5) + floor(ipZ)*2., 3.)==1.){
       window = 1e5; port = 1e5; 
       doLight = 0;
    }
       
    // Panel control floor. Used as the floor for the light cavities.
    float fl = d + .2;
    
    // Cut out the window port from the main panel walls.
    d = max(d, -port);

    
     
    {
    // Add some pipes along the walls... I'm not sure why I decided to do this,
    // but I got used to it being part of the design.
    vec3 q = svP;
    q.xy *= rot2(PI/12.);
    // Polar repeat. 6 in all.
    float aN = 6.;
    float a = atan(q.y, q.x)/TAU;
    float ia = (floor(a*aN) + .5)/aN;
    q.xy *= rot2(-ia*TAU);
    q.x -= 1.85;
    // Construct the pipes.
    q.z = abs(abs(p.z) - sc.z/2. + .025) - .05;
    float pipe = length(q.xy) - .075;//length(p.yz) - .5;
    frame = min(frame, max(pipe - .05, q.z));
    
    // Add the pipes to the tunnel walls.
    d = min(d, pipe);
    }

       
   
    // Adding some glow to the control panel lights. Not a lot of thought was
    // put into this, but it seems to work.
    float portDist = max(port + .2,  d - .1); // Light box distance.
    vec3 lCol = getCol(wID + vec2(ipZ, floor(ia*aN - .5))); // Light color.
    gCol = lCol; // Set the global color.
    // If within range, add the glow.
    if(portDist<d) glow += lCol/(.01 + portDist*portDist*8.);
      
    
    ////////////////////
    // We need to cover both directions, so we take the absolute value. 
    float rC = abs((gDir.z*sc.z - p.z)/gRd.z); // For 2D, this will work too.
    gCD = rC + .0003; // Adding a touch to advance to the next cell.
   
    // Minimum of all distances, plus not allowing negative distances, which
    // stops the ray from tracing backwards... or something like that.
    gCD = max(rC, 0.) + .0005;
    
    gCD = min(gCD, .5);
     
    // Global position, scale and saved values for later use.
    gP = p;
    gSc = sc;    
    gVal = vec4(d2, ipZ, 1, 1);
 
 
    ////////////////////
    
    
   
    // Object ID.    
    vDist = vec4(d, frame, window, fl);
    
    
    // Return the distance value for the scene.
    return min(min(d, frame), min(window, fl));
 
}


// Standard raymarching function.
float trace(in vec3 ro, in vec3 rd){

    // Reset the glow to zero.
    glow = vec3(0);
    
    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = step(0., rd) - .5;
    gRd = rd; 
    
    // Note the jittering, since we're using cheap glow.
    float d, t = hash31(fract(ro*89.567)*7. + rd)*.5;
    for(int i = ZERO; i<180; i++){
        
        // Surface distance.
        d = map(ro + rd*t);
        // Surface distance check.
        if(abs(d)<.001 || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.)
        // Since we're calculatig glow inside the distance function (which is
        // a cheap hack), we need to delimit the ray jumping distance a bit.
        t += min(d*.8, gCD);//min(d*.9, .2);
        
    }

    // Clamp the distace to the far plane, in order to avoid occasional artifacts.
    return min(t, FAR);
}

// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 normal(in vec3 p) {
	
    //return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy),	
    //                      m(p + e.yyx) - m(p - e.yyx)));
    
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
float softShadow(vec3 ro, vec3 rd, vec3 n, float lDist, float k){

   
    // Coincides with the hit condition in the "trace" function. 
    ro += n*.0015;
     

    float shade = 1.;
    float t = 0.; 

    
    // I've added in a touch of jittering to alleviate banding.
    ro += rd*hash31(ro + n*57.13)*.01;
    
    
    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = step(0., rd) - .5;
    gRd = rd;
 

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. 
    // Obviously, the lowest number to give a decent shadow is the best one to choose. 
    for (int i = min(0, iFrame); i<64; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        // shade = min(shade, smoothstep(0., 1., k*d/t)); // Thanks to IQ for this tidbit.
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>lDist) break; 
        
        
        // So many options here, and none are perfect: 
        // dist += clamp(d, .01, stepDist), etc.
        t += clamp(min(d, gCD), .01, .15);       
        
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
    
        float hr = float(i + 1)*.15/5.;        
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


// Planar to spherical camera. Not quite, but close enough.
vec3 sphereCam(in vec2 p){
    
    //return normalize(vec3(p, 2)); // Debug.
    
    // A more conventional way to spherize.
    //return vec3(sin(p.x)*cos(p.y), sin(p.y), cos(p.x)*cos(p.y));
  
    float t = 1./(1. + dot(p, p)/3.);
    return vec3(p*t, 2.*t - 1.);
}
//////
 


void mainImage( out vec4 fragColor, in vec2 fragCoord ){
	
	// Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
 	
	// Camera Setup.
	vec3 lookAt = vec3(0, 0, iTime*4.);  // "Look At" position.
	vec3 camPos = lookAt + vec3(0, 0, -.2); // Camera position, doubling as the ray origin.
 
    // Light positioning. 
 	vec3 lightPos = camPos + vec3(0, 0, 5); // Placed in front of the camera.

	// Using the Z-value to perturb the XY-plane.
	lookAt.xy += path(lookAt.z);
	camPos.xy += path(camPos.z);
	lightPos.xy += path(lightPos.z);

    // Using the above to produce the unit ray-direction vector.
    float FOV = TAU/6.; // FOV - Field of view.
    vec3 forward = normalize(lookAt - camPos);
    vec3 right = normalize(vec3(forward.z, 0, -forward.x )); 
    vec3 up = cross(forward, right);

    // rd - Ray direction.
    //vec3 rd = normalize(uv.x*right + uv.y*up + forward/FOV );
    mat3 cam = mat3(right, up, forward);
    //vec3 rd = cam*normalize(vec3(uv, 1./FOV));
    
    // A bit of lens mutation to increase the scene peripheral, if that's your thing.
    vec3 rd = cam*sphereCam(uv*PI*.7/FOV);
    
    //float fov = PI*.5*length(uv);
    //vec3 rd = cam*normalize(vec3(normalize(uv), 1./tan(fov)));
    
    // A bit of lens mutation to increase the scene peripheral, if that's your thing.
    //vec3 rd = normalize(forward + FOV*uv.x*right + FOV*uv.y*up);
    //rd = normalize(vec3(rd.xy, rd.z - dot(rd.xy, rd.xy)*.25));    
    
    // Swiveling the camera about the XY-plane (from left to right) when turning corners.
    // Naturally, it's synchronized with the path in some kind of way.
 	rd.xy = rot2(-path(lookAt.z).x/16.)*rd.xy;
    
    
    // Tilt toward the plane a bit.
    rd.xz *= rot2(1.);
    rd.xy *= rot2(iTime/2.);
     
    
    // Mouse movement.
    if(iMouse.z>1.){
        rd.yz *= rot2((iMouse.y - iResolution.y*.5)/iResolution.y*3.1459);  
        rd.xz *= rot2((iMouse.x - iResolution.x*.5)/iResolution.x*3.1459);  
    }  
		
    // Standard ray marching routine.
	float t = trace(camPos, rd);
    
    // Object ID.
    int svGID = vDist.x<vDist.y && vDist.x<vDist.z && vDist.x<vDist.w? 0 : 
                vDist.y<vDist.z && vDist.y<vDist.w? 1 : vDist.z<vDist.w? 2 : 3;
    
    // Glow, panel control color and various saved values.
    vec3 svGlow = glow;
    vec3 svCol = gCol;
    vec4 svVal = gVal;
    

    // Sky color... Tunnel exit color.
    vec3 sky = vec3(.5, .7, 1)*2.; 
 
    // Initialize the scene color.
    vec3 sceneCol = sky;
   
	// The ray has effectively hit the surface, so light it up.
	if(t<FAR){
    
        // Surface position.
        vec3 sp = camPos + t*rd;
    
        // Surface normal.	    
	    vec3 sn = normal(sp);
        
         
        #if 1
        // Light direction vector.
	    vec3 ld = lightPos - sp;
      
        // Distance from the light to the surface point.
	    float lDist = max(length(ld), 1e-5);
    	
    	// Normalize the light direction vector.
	    ld /= lDist;
	    
	    // Light attenuation, based on the distances above.
	    float atten = 1./(1. + lDist*lDist*.05); // + distlpsp*distlpsp*0.025
        #else
        vec3 ld = normalize(-vec3(.0, -1, -3));
        float atten = 1.;
        float lDist = FAR;        
        #endif
        
	    
	    // Ambient occlusion and shadows.
        float ao = calcAO(sp, sn);
        float sh = softShadow(sp, ld, sn, lDist, 8.); 
         
        
        // Scene curvature.
        float spr = 5., ampC = 1., offs = .0;
        float crv = curve(sp, spr, ampC, offs);
      
  
        // Tunnel panel section ID.
        vec2 id = svVal.zw;
        
        // Texture 
        vec3 tx = tex3D(iChannel0, sp/6., sn);
        float gr = dot(tx, vec3(.299, .587, .114)); // Greyscale.
        
        
        /////////////////
        
        // Coloring.
        
        // Wall panel color.
        float rnd = hash21(id + .1);
        vec3 texCol = vec3(rnd*.1 + .1);
        
        // Add extra glow color to the light controls.
        if(svGID==3) texCol += svGlow*.02; 

        /*
        // Gold... Needs work.
        if(svGID>=1) texCol *= vec3(1.5, 1, .5);
        else texCol *= vec3(1.35, 1, .65);
        svGlow = mix(svGlow.yxz, svGlow.xzy, .2);
        */
        
        // Texturing.
        texCol *= tx; 
    
 
        //////////////
           
        
        // Ambient light.
        //
	    // Quick Lighting Tech - blackle
        // https://www.shadertoy.com/view/ttGfz1
        // Studio and outdoor.
        //float amb = pow(length(sin(sn*2.)*.5 + .5), 2.);
        float amb = length(sin(sn*2.)*.5 + .5)/sqrt(3.)*smoothstep(-1., 1., sn.y); 
 
           
        // Material properties.
        float fresRef = .5;  // Reflectivity.
        float type = .2;     // Dielectric or metallic.
        float rough = min(gr*2., 1.); // Roughness.
        
        if(svGID>=1){
            // Plastic chrome trim.
            fresRef = .7;             
        }

        // Standard BRDF dot product calculations.
        vec3 h = normalize(ld - rd); // Half vector.
        float ndl = dot(sn, ld);
        float nr = clamp(dot(sn, -rd), 0., 1.);
        float nl = clamp(ndl, 0., 1.);
        float nh = clamp(dot(sn, h), 0., 1.);
        float vh = clamp(dot(-rd, h), 0., 1.);  
 
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
        f0 = mix(f0, texCol, type);
        vec3 FS = f0 + (1. - f0)*pow(1. - vh, 5.); // Fresnel-Schlick reflected light term.
        
        // BRDF style specular and diffuse calculations. There is so little
        // extra work involved, but the lighting quality is much better.
        vec3 spec = getSpec(FS, nh, nr, nl, rough);
        vec3 diff = getDiff(FS, nl, rough, type);
       
        
         
        // Add this after calculating the material based lighting above.
        // Using pseudo science to apply a bit of faux back scatter. :)
        float bl = max(dot(-normalize(vec3(ld.x, 0, ld.z)), sn), 0.);
        texCol = texCol + texCol*sky*bl*2.;
        
        texCol += texCol*sky*(sn.y*.35 + .65)*.5; // Slight overhead normal lighting.
        //texCol *= 1. + sn.yzx*.25; // Normal color shading.
   
  
    
    	// Combining the above terms to produce the final color. 
        // It's based more on acheiving a certain aesthetic than science.
        sceneCol = texCol*(diff*sh + amb*(sh*.5 + .5) + vec3(4)*spec*sh);
        
        
   
        // Specular reflection -- Requires the "Forest" cube map.
        float speR = pow(max(dot(normalize(ld - rd), sn), 0.), 8.);
        vec3 rf = reflect(rd, sn); // Surface reflection.

        vec3 rTx = texture(iChannel1, rf).xyz; rTx *= rTx;
        float rF = svGID==0? 4. : 32.; // More reflection on the frames.
        sceneCol = sceneCol + sceneCol*speR*rTx*rF;  

        
        
        
        
        // Cheap reflection.
        //vec3 ref = reflect(rd, sn);
        //sceneCol += 8.*sceneCol*smoothstep( -0.2, 0.2, ref.y ) * (0.04 + 0.96*f0)*ao; 
        
        // White panel experiment.
        //if(svGID==0) sceneCol += vec3(.2, .3, .6)/(1. + t*t*.05)*(sh*.5 + .5);
        //if(svGID==3) sceneCol += svGlow*.003/(1. + t*t*.05)*(sh*.5 + .5);
        
        // Curvature shading, for a little extra depth.
        sceneCol *= crv*1. + .5;
        
        // Dark cartoon lines. Not for here.
        //sceneCol *= 1. - abs(crv - .5)*2.*.9;
        
          
	    // Shading.
        sceneCol *= atten*ao; 
 
	 }
    
     // Adding the control pannel window glow.
     sceneCol += (sceneCol + .002)*svGlow*.5;//*vec3(1, .1, .2)
    
     // Applying fog.
     sceneCol = mix(sceneCol, sky, smoothstep(.2, 1., t/FAR));
 

     // Clamp and present the pixel to the buffer. Pass in the overall
     // scene distance to use for the DOF.
	 fragColor = vec4(max(sceneCol, 0.), t);
	
}