// Image (image) — Random Subdivision Traversal by Shane
// https://www.shadertoy.com/view/W3VXWc

/*

    Random Subdivision Traversal
    ----------------------------    
    
    Random 2D subdivision is not new -- I've posted a few examples over
    the years, and plenty of others have too. Subsurface scattering has
    been covered many times also. However, I figured that combining the 
    two would be original, until I did a quick search and realised that
    Tater had posted a beautiful example along these lines. Therefore,
    there is virtually nothing original about this. :)
    
    Nevertheless, I wanted to post a cheap subsurface scattering (SSS)
    example that, at the very least, gives the impression that some kind
    of translucency is happening. This doesn't feature real subsurface
    scattering, but rather a cheap imitation. Even so, the effect was 
    enough to fool my eyes.
    
    In general, the idea is to march out from the surface in the direction
    of the light, then accumulate distance weighted values. That's it. 
    I've seen it performed a few times, but I'm not sure where it 
    originated. Either way, I've used Poisson's implementation from his 
    nicely lit "Conetraced Soft Shadows" example, which I've linked to 
    below. I integrated some of Poisson's lighting also, which in turn was 
    based on the style of lighting that you'll find in some of IQ's 
    examples. It also influenced the color scheme to a certain degree. My 
    contribution was to inject some BRDF calculations into the mix.
    
    Performance is OK, but I had difficulty trying to fit everything in, 
    so this could do with more speed, which I'll try to address later.
    Anyway, I have a more interesting 3D subdivision example that I'll 
    post pretty soon.
    
    
    
    Related examples:
    
    // Poisson always posts good quality examples, of which this
    // is just one.
    Conetraced Soft Shadows -- Poisson
    https://www.shadertoy.com/view/DdtGWf
    
    // Beautiful example -- Almost 1000 likes, so most people seem
    // to agree. :) Anyway, the SSS routine IQ uses is my subjective
    // preference for a cheap, nice-looking all-round routine.
    Snail -- iq
    https://www.shadertoy.com/view/ld3Gz2
    
    // Fantastic example. The algorithm itself was based on something
    // written by Ob5vr.
    Cubic Dispersal -- Tater
    https://www.shadertoy.com/view/fldXWS
    //
    Based on:
    20210920_octree traversal --  0b5vr 
    https://www.shadertoy.com/view/NsKGDy
    
    // Not technically SSS, but it has that feel to it. In addition,
    // it's very pleasing to eye, and the code is confusingly short. :)
    Sunset Ball -- SnoopethDuckDuck
    https://www.shadertoy.com/view/wfXcDn

*/


#define FAR 15.

#define PI 3.14159265358979
#define TAU 6.2831853


// Subsurface scattering (SSS) calculation preferences.
//
// All are rough estimates. The second option (SUB 1) is based on one
// of IQ's random scattering variations and is my personal preference, but 
// I've stuck with the first option. IQ's version has a more realistic 
// feel to it, but SSS is hard to guage; I've never put on a lab coat and
// studied the effects of light transmission through Gummy Bears, so I'm 
// not really sure how various translucent surfaces are supposed to look. :)
//
// Faux light based: 0, Normal scattering: 1, Direction ray scattering: 2.
#define SUB 0


// Bore out holes in the blocks, or not. This slows things down a bit,
// but I like the way it looks, so it's on as a default.
#define DISPLAY_HOLES

// Soft reflections involve an extra pass, so can slow things down, but 
// they look nice. It kind of looks interesting without them though.
#define SOFT_RELECTIONS



// Standard 2D rotation formula.
mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }
 
float hash21(vec2 p) {
    p = fract(p*vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x*p.y);
}

// Hash without Sine -- Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
// 2 out, 2 in...
vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx)*vec3(.3031, .4030, .5973));
    p3 += dot(p3, p3.yzx + 42.1237);
    return fract((p3.xx+p3.yz)*p3.zy);
}

/*
// Based on one of IQ's cheap hash functions. I like it because it's
// fast and compact.
vec2 hash22(vec2 p){ 
    const vec2 k = vec2(.3183099, .3678794);
    float n = dot(p, vec2(111.53, 113.47));
    return fract(n*fract(k*n));
}
*/


// IQ's "uint" based uvec3 to float hash with Fabrice's modification.
float hash31(vec3 f){
   
    uvec3 p = floatBitsToUint(f);
    p = 1664525U*((p >> 2U)^(p.yzx>>1U)^p.zxy);
    uint h32 = 1103515245U*(((p.x)^(p.y>>3U))^(p.z>>6U));

    uint n = h32^(h32 >> 16);
    return float(n & uint(0x7fffffffU))/float(0x7fffffff);
    
}


// Hash without Sine -- Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
//  3 out, 3 in...
vec3 hash33(vec3 p){

 	p = fract(p*vec3(.5031, .6030, .4973));
    p += dot(p, p.yxz + 142.5453);
    return fract((p.xxy + p.yxx)*p.zyx);

}


// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smax(float a, float b, float k){
    
   float f = max(0., 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
}


// The path is a 2D sinusoid that varies over time, depending upon the frequencies, 
// and amplitudes.
vec2 path(in float z){ 
    
    #if 1
    // Straight line.
    return vec2(0); 
    #else
    // Curved path.
    float a = sin(z*.13);
    float b = cos(z*.17);
    return vec2(a*3. - b*1.5, b*.1 + a*.1); 
    #endif
}

// Very basic transcental height function with slight gutter
// carved out that follows the camera path... which is set to
// zero for the default, so is a bit wasteful. :)
float hf(vec2 p){

    // Camera path.
    float x = abs(p.x - path(p.y).x);
    
    x = min(x/2., 1.)*.7 + .3; // Slight camera path gutter.
    float h = dot(sin(p*2. - cos(p.yx*3.)*1.5), vec2(.25)) + .5;
    
    // Height field with camera path carved out.
    return clamp(h*x, 0., 1.);

}

// The SDF to a box.
// Taken from iquilezles.org/articles/distfunctions2d
float sBox(vec2 p, vec2 b, in float rf){

    vec2 d = abs(p) - b + rf;
    return min(max(d.x, d.y), 0.) + length(max(d, 0.))  - rf;
}

/*
// IQ's 3D box formula with added smoothing.
float sBox(in vec3 p, in vec3 b, in float rf){
  
  vec3 d = abs(p) - b + rf;
  return min(max(max(d.x, d.y), d.z), 0.) + length(max(d, 0.)) - rf;
    
}
*/

// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h, in float sf){

    // Slight rounding. A little nicer, but slower.
    vec2 w = vec2(sdf, abs(pz) - h) + sf;
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.)) - sf;
}


// Ray origin, ray direction, point on the line, normal. 
float rayLine(vec2 ro, vec2 rd, vec2 p, vec2 n){
   
   // This it trimmed down, and can be trimmed down more. Note that 
   // "1./dot(rd, n)" can be precalculated outside the loop.
   //return dot(p - ro, n)/dot(rd, n);
   float dn = dot(rd, n);
   return dn>0.? dot(p - ro, n)/dn : 1e8;   

} 

// Object distance container.
vec4 vObj;

vec3 gRd; // Global ray direction.
vec3 gDir; // Global step direction.
float gCD; // Global cell wall distance.

// Storage for values used outside the raymarching function.
vec4 gVal;
vec3 gP;
vec3 gDim;


// The SDF for the bricks.
float map(vec3 p){

    float fl = p.y + 1.;
    
    // The brick size.
    // Could be anything.
    vec2 sc = vec2(3)/1.;
    
    // XZ plane coordinates.
    vec2 offs = vec2(0);
    vec2 q = p.xz;
    // Cell ID.
    vec2 iq = floor(q/sc) + .5;
    // Shifing rows across by half.
    if(mod(iq.y - .5, 2.)==1.){ 
        q.x -= sc.x/2.;
        iq = floor(q/sc) + .5;
        offs.x += .5;
    }
    // Local cell coordinates.
    q -= iq*sc;
    iq += offs;
    
    ///////////////// 
    // Subdividing each cell with a standard 2D random subdision routine.
    
    // Initial dimensions.
    vec2 dim = sc;
    
    // Left and right... for 2 dimensions, so probably not the best
    // naming strategy. :) I was in a hurry when writing this. I will 
    // rename these "minimum and maximum" later.
    
    // Set the minimum and maxium coordinates to the far left and right
    // sides of the square cell.
    vec2 left = -dim/2.;
    vec2 right = dim/2.;
    
    
     
    float mgn = .35; // Margin width.
    
    // Static ID.
    vec2 idd = vec2(0);
    // Each larger square cell is subdivided, so well use its random ID
    // to offset at a different place to give it a unique partitioning.
    vec2 rndOffs = hash22(iq + .07); 
   
    // Iteration number. Four looks better, but is too slow. The algorithm itself
    // is not slow, but all the extra stuff I've thrown in is. :)
    const int iter = 3;
    for(int i = 0; i<iter; i++){
        
        
        // Random split.
        vec2 rndSplit = idd + (rndOffs + vec2(3, 5)/float(i + 1)*117.3);
        vec2 rnd2Ani = sin(TAU*rndSplit + iTime)*.5*(1. - mgn*2.) + .5;
        //vec2 rnd2Ani = fract(rnd2*7.7)*(1. - mgn*2.) + mgn;
        //vec2 rnd2Ani = abs(fract(rnd2 + iTime/8.) - .5)*2.;
        //rnd2Ani = smoothstep(.2, .8, rnd2Ani)*(1. - mgn*2.) + mgn;
  
        // The split line. This will be the new left or right coordinates.
        // If we're on the left of the dividing line, the split coordinates
        // will be the new... right coordinate, and vice versa.
        vec2 split = mix(left, right, rnd2Ani);
        
        // Line step.
        vec2 ln2 = q - split;
        // Step left or right.
        vec2 stepLn = step(0., ln2);
        //vec2 sgnLn = (1. - stepLn*2.)*ln2; 
       
        // If we step right, update the ID. Otherwise stay put.
        idd += mix(vec2(0), vec2(1), stepLn)/pow(2., float(i)); 
        
        // Update the left and right coordinates, depend upon which side
        // of the line we've stepped.
        left = mix(left, split, stepLn);
        right = mix(split, right, stepLn);
    
        
    }

    // The new dimensions are the difference between the right (maxium) 
    // and left (minimum) coordinates.
    dim = right - left;
    
    // Split the difference for the  center coordinates
    vec2 cntr = mix(left, right, .5);
    // Center the local coordinates.
    q -= cntr;
    
    // Update the position-based ID.
    iq += cntr/sc;
    
 
    
    /////////////////    
    
    // Random height for the block.
    float h = hf(iq*sc);
    h = h*1.4 + .1;
    
    // Edge width, or gap, in this case.
    float ew = .005;
    
    // Global 3D coordinates and dimension.
    gP = vec3(q.x, p.y - h/2. + .5, q.y);
    gDim = vec3(dim.x/2. - ew, h/2. + .5, dim.y/2. - ew);
    
    //float d = sBox(vec3(q.x, p.y - h/2., q.y), 
    //                 vec3(sc.x/2. - ew, h/2., sc.y/2. - ew), .01);
    
    // The 2D base and extruded box.
    float d2 = sBox(gP.xz, gDim.xz, .03);
    float d =  opExtrusion(d2, gP.y, gDim.y + .025, .03);
    
 
    // Rounded tops to accentuate the lighting algorithm a bit.
    d = smax(d, length(gP - vec3(0, gDim.y - sc.x/2. + .025, 0)) - sc.x/2., .03);
    
    #ifdef DISPLAY_HOLES
    // Random box holes. I was going to produce some Menger sponge related
    // related geometry, but it slowed things down, so just one random level.
    vec3 bxRnd = hash33(vec3(idd.x, 13, idd.y) + .43);
    if(bxRnd.x<.5) d = smax(d, -sBox(gP.yz, gDim.yz - .12, .003), .03);
    if(bxRnd.y<.5){ 
        float dXZ = sBox(gP.xz, gDim.xz - .12, .003);
        d = smax(d, -dXZ, .03); 
        d2 = smax(d2, -dXZ, .03);
    }
    if(bxRnd.z<.5) d = smax(d, -sBox(gP.xy, gDim.xy - .12, .003), .03);
    #endif  
     
    // Beveling... Only one "L" in the word beveling. I sometimes forget that. :)
    //d += max(d2, -.025)*.5;
    
    // Saving the distance, ID and height for later use.
    gVal = vec4(d, idd, h);
    
                       
    // Distance from the current point to the cell wall in the 
    // direction of the unit ray. Use it as a ray delimiting 
    // distance to ensure the ray doesn't skip over the next cell.
    //
  
    // if(dot(gRd.xz, vec2(1, 0))<0.) dir.x = -dir.x;
    // if(dot(gRd.xz, vec2(0, 1))<0.) dir.z = -dir.z;
    vec2 rC = abs((gDir.xz*dim - q)/gRd.xz); // Ray to cube walls.
    // Distance from the current point to just inside the next cell. 
    gCD = min(rC.x, rC.y) + .0001;    
    
 /*  
    // The slower way to obtain the cell wall distance, for anyone
    // who's not sure how the above comes about.
    vec2 n1 = vec2(1, 0); // Right face normal.
    vec2 n2 = vec2(0, -1); // Forward (or back) face normal.
    if(dot(gRd.xz, n1)<0.) n1 *= -1.;
    if(dot(gRd.xz, n2)<0.) n2 *= -1.;  
    
    vec2 rC;
    rC.x = rayLine(gP.xz, gRd.xz, n1*dim/2., n1);
    rC.y = rayLine(gP.xz, gRd.xz, n2*dim/2., n2);    
*/        
    
    // Store the object distances. There are only two here, but when there 
    // are more, it makes more sense to sort IDs outside of the loop.
    vObj = vec4(d, fl, 0, 0);
    
    // Return the distance.
    return min(d, fl);
}

// Raymarch function.
float trace(vec3 ro, vec3 rd){

    gRd = rd; // Global ray direction.
    gDir = step(0., gRd) - .5; // Step direction.

    float t = 0.;
    
    const int maxSteps = 96;

    for(int i = 0; i < maxSteps; i++) {
        
        // Scene distance.
        float d = map(ro + rd*t);
        
        // Surface check.
        if(abs(d)<.001 || t>FAR) break;        
        
        // Limit the ray jump distance to ensure that it
        // doesn't go any further than the next cell.
        t += min(d, gCD);
    }
    
    // Return the distance.
    return min(t, FAR);

}

// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with 
// limited iterations is impossible... However, I'd be very grateful if someone could 
// prove me wrong. :)
float softShadow(vec3 ro, vec3 rd, vec3 n, float lDist, float k){

    // Initialize the shade and ray distance.
    float shade = 1.;
    float t = 0.; 
 
    // Coincides with the hit condition in the "trace" function. I've added in 
    // a touch of jittering to alleviate banding.
    ro += n*.0015 + rd*hash31(ro + rd + n)*.005;

    gRd = rd; // Global ray direction.
    gDir = step(0., gRd) - .5; // Step direction.


    // Max shadow iterations - More iterations make nicer shadows, but slow things down. 
    // Obviously, the lowest number to give a decent shadow is the best one to choose. 
    for (int i = min(0, iFrame); i<48; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        
        // Early exit, if necessary.
        if (d<0. || t>lDist) break;       

        //shade = min(shade, smoothstep(0., 1., k*d/t)); // Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += clamp(d, .01, stepDist), etc.
        t += clamp(min(d, gCD), .005, .25); 
        
    }

    // Shadow.
    return max(shade, 0.); 
}


// Standard normal function. It's not as fast as the tetrahedral calculation, 
// but more symmetrical.
vec3 nr(in vec3 p){
	
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


// Ambient occlusion. Based on IQ's original.
float cao(in vec3 p, in vec3 n){

	float sca = 2., occ = 0.;
    for( int i = 0; i<6; i++ ){
    
        float hr = .01 + float(i)*.25/6.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
        //if(occ>1e5) break;
    }
    
    return clamp(1. - occ, 0., 1.);      
} 


// Scattering calculation preferences.
//
#if SUB == 0
// This is a slight retweaking of Poisson's SSS function,
// which can be found, here:
//
// Conetraced Soft Shadows -- Poisson
// https://www.shadertoy.com/view/DdtGWf
//
// ra is the subsurface radius.
float subsurface(vec3 ro, vec3 rd, float ra) {
    
    const int sN = 10; // Sample number.
    float sss = 0.;
    
    // Randomly march out from the surface in the direction 
    // of the light accumulating weighted values.
    for (int i = 0; i<sN; i++){
    
        // Random, but increasing, sample distance.
        float rnd = hash31(ro + float(i))*.1;
        float d = float(i)*ra*(1. + rnd); 
        // Accumulate weighted samples.
        sss += clamp(map(ro + rd*d)/d, 0., 1.);
        //sss += smoothstep(0., 1., map(ro + rd*h)/h);
    }
    
    sss /= float(sN); // Average the scattering value.
    
    // Giving the results more of a bell curve distribution.
    return smoothstep(0., 1., sss); 
}
#else
// This is a rough version of one of IQ's subsurface formulas and XT95's
// thickness formula, which you can find at the links below:
// I haven't finished tweaking everything yet, but the results seem more
// authentic... I think. It's hard to tell what the scattering distribution
// should look like.
//
// Snail -- iq
// https://www.shadertoy.com/view/ld3Gz2
//
// Alien Cocoons -- XT95
// https://www.shadertoy.com/view/MsdGz2
//
float subsurface(in vec3 p, in vec3 rd, float ra){
    
	float occ = 0.;
    float i0 = hash31(p + rd)*ra;
    for( int i = 0; i<16; i++){
    
        float h = i0 + float(i)*ra;
        // Smoother scattering.
        //vec3 dir = normalize(sin(float(i)*16.01 + vec3(0, 2.03, 4.02)));
        // More dispersed, but noisy (due to the sample count) and expensive, distribution.
        vec3 dir = normalize(hash33(p + h + vec3(i)) - .5);
        dir *= sign(dot(dir, rd));
        occ += (h - map(p - h*dir));
    }
    
    return smoothstep(0., 1., 1. - occ/4.);     
}
#endif

 
// Hacky sky routine. It's good enough for this example.
vec3 sky(vec3 rd, vec3 ld){ 
    
    //float sun = clamp(dot(ld, rd), 0., 1.);

    // Sky color.
    vec3 col = mix(vec3(.45,.65, 1), vec3(0,.15, .5), clamp(rd.y*2., 0., 1.));
    
    // Horizon.
    vec3 hor = vec3(.65, .8, 1); //mix(vec3(.65, .8, 1), vec3(1, .9, .5), sun);
    col = mix(col, hor, 1. - smoothstep(0., .15, rd.y + .1));
    
    //col = mix(vec3(1.4, 1.25, 1.4), col, smoothstep(-.35, 0., rd.y + pow(sun, 32.)*.1));
     
    return col;    
}
 

void mainImage(out vec4 fr, vec2 fc) {

    // Screen coordinates.
    vec2 u = (fc - iResolution.xy/2.)/iResolution.y;
    
    // Screen warp.
    u /= max(.9 - dot(u, u)*.7, 1e-5);
     
    // Look, ray origin and light position.
    vec3 lk = vec3(0, .5, iTime);
    vec3 ro = lk + vec3(0, 1, -1.5); // Camera position, doubling as the ray origin.
    vec3 lp = lk + vec3(1, 1, 1)*8.;

	// Using the Z-value to perturb the XY-plane.
	lk.xy += path(lk.z);
	ro.xy += path(ro.z);
	//lp.xy += path(lp.z);
    
    // More accurate field of view... I think. I'll check it later.
    float FOV = tan(radians(30.)/2.)*4.;
   
    // Camera.
    vec3 camDir = normalize(lk - ro); 
    vec3 worldUp = vec3(0, 1, 0);
    vec3 camRight = normalize(cross(worldUp, camDir));
    vec3 camUp = cross(camDir, camRight);
    vec3 rd = normalize(camRight*u.x + camUp*u.y + camDir/FOV);
     
    
    // Swiveling the camera about the XY-plane (from left to right) when turning corners.
    // It's synchronized with the path in some kind of way.
 	rd.xy = r2(-path(lk.z).x/16.)*rd.xy; 
    
    // Rotating more for an interesting perspective.
    rd.xz *= r2(-TAU/8.);
    
    // Raymarch.
    float t = trace(ro, rd);
 
    // Distance, ID and object height.
    vec4 svVal = gVal;
    
    // Local object position and ID.
    vec3 svP = gP;
    vec3 svDim = gDim;
    
    // The ray to cell wall distance. Handy for all kinds of things,
    // but I'm not using it here. Next time. :)
    //float svCD = gCD; 
    
    // Object ID.
    int objID = vObj.x<vObj.y? 0 : 1;
    
    
    // Hit position.
    vec3 sp = ro + rd*t;
    
    // Light. A scene like this would be more accurate using direct lighting, but
    // sometimes, I'll use a far away point light to bring out the SSS a little more.
    #if 1
    vec3 ld = normalize(vec3(1, 1, 1));
    float lDist = FAR;
    #else
    vec3 ld = lp - sp;
    float lDist = max(length(ld), 1e-5);
    ld /= lDist;
    #endif
    
    // Sky. I played around with a lot of different sky setups, but decided
    // less is more.
    vec3 sky = sky(rd, ld);
    vec3 col = sky;
    
    vec3 sunCol = vec3(1, .8, .6)*2.;
    
    
    if(t<FAR) {
      
        // Surface normal.
        vec3 sn = nr(sp);
        
        
        // Shadow, soft reflective pass, and ambient occlusion.
        float sh = softShadow(sp, ld, sn, lDist, 8.);
        #ifdef SOFT_RELECTIONS
        float shR = softShadow(sp, reflect(rd, sn), sn, lDist, 16.);
        #endif
        float ao = cao(sp, sn)*(.5 + .5*sn.y);
        
        //float atten = 1./(1. + lDist*.1); // Light attenuation.
        
        // Very rough, but cheap subsurface scattering.
        #if SUB == 0
        vec3 sRay = ld;
        #elif SUB == 1
        vec3 sRay = -sn;
        #else
        vec3 sRay = rd;
        #endif
        float sss = subsurface(sp - sn*.005, sRay, .05);
       
        // COLORING.
        //
        // Object color.
        float rnd = hash21(svVal.yz + .23);
        // Spectrum.
        //vec3 oCol = .35 + .3*cos(TAU*(1. - svVal.w)/1. + rnd*.5 + vec3(0, 1.5, 3) + 4.);
        // The orange side of the color wheel.
        vec3 oCol = .52 + .43*cos(TAU*(rnd)/4. + rnd*.1 + vec3(0, 1, 2)*1. + .7);
   
        /*
        // Old edge calculations. Saving them for later.
        if(objID==0){
            
            float bx = sBox(svP.yz, svDim.yz, 0.);
            float by = sBox(svP.xz, svDim.xz, 0.);
            float bz = sBox(svP.xy, svDim.xy, 0.);
            bx = min(min(bx, by), bz);
            bx = abs(bx) - .007;
            oCol = mix(oCol, oCol*.35, 1. - smoothstep(0., .005, bx));
        }
        */
        
        if(objID==1) oCol = vec3(.05);
        //else oCol = vec3(.5, .1, 1)*dot(oCol, vec3(.299, .587, .114)); // Grape.
        
        
        
        // LIGHTING.
 

        float bou = .5 - .5*sn.y; // Bounce light.

        //float bac = clamp(dot(sn, -ld), 0., 1.); // Back scatter light.
        float bac = clamp(dot(sn, -normalize(vec3(ld.x, 0, ld.z))), 0., 1.);
        bac = (bac*.5 + .5)*bou; // Apply the back scatter.
   
        // Material properties.
        float fresRef = .7;  // Reflectivity.
        float type = 0.;     // Dielectric or metallic.
        float rough = .35;   // Roughness.


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
        f0 = mix(f0, oCol, type);
        vec3 FS = f0 + (1. - f0)*pow(1. - vh, 5.); // Fresnel-Schlick reflected light term.
        
        // BRDF style specular and diffuse calculations. There is so little
        // extra work involved, but the lighting quality is much better.
        vec3 spec = getSpec(FS, nh, nr, nl, rough);
        vec3 diff = getDiff(FS, nl, rough, type);
 
        
        // Applying lighting to the materials. This uses elements from a lot of
        // IQ's examples. However, a lot of some of this is based on Poisson's
        // interpretation.
  
        vec3 lin = sunCol*diff*sh; // Sun diffuse.
        lin += sunCol*oCol*ao*bac; // Sun illumination.
      
        // Subsurface scattering.
        vec3 sssCol = vec3(.8, .25, .1);
        vec3 sss3 = sssCol*sss*(1. - diff*sh);
        //vec3 sss3 = pow(vec3(1, .8, .6)*sss, vec3(1, 3, 8)); 
        lin += sunCol*sss3; // Sun SSS.
        
        lin += .35*sky*ao; // Sky diffuse.
             
        col = oCol*lin; // Scene color so far.
        
        #ifdef SOFT_RELECTIONS
        // Soft reflective lighting.
        if(objID==0){
      
            col += .2*sunCol*spec*shR; // Sun reflection.
            col += sky*shR*FS; // Sky reflection .       
        } 
        #endif
         
        
    }
     
    // Horizon fog.
    col = mix(col, sky, smoothstep(.4, 1., t/FAR));   
    
    // Extra sun scatter.
    col += sunCol*pow(clamp(dot(rd, ld),0.,1.), 8.)*.7;
  
    // Sigmoid tone mapping with exposure rolled in.
    col = atan(col*2.);
    
    // Rough gamma correction and screen presentation.
    fr = vec4(pow(max(col, 0.), vec3(1)/2.2), 1);
    
}
