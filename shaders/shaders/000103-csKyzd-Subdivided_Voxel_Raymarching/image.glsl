// Image (image) — Subdivided Voxel Raymarching by Shane
// https://www.shadertoy.com/view/csKyzd

/*

	Subdivided Voxel Raymarching
	----------------------------
    
    I don't think I've posted a tunnel flythrough for a while, so here's 
    something that I've had sitting in my account in one form or another
    for ages. I'd describe the aesthetic here as weird but interesting. :)
    This particular scene style is not commonly seen because it relies on 
    a raymarching trick that's not often used. I'm not sure what it's 
    officially called, but Shadertoy user Nimitz called it sparse cell 
    raymarching in one of his examples, so that's as good a term as any. :)    

	Traversing sparse voxels inside a raymarching loop is not a new idea,
    but it's one that's seldomly used, which surprises me since it opens
    up so many possibilities. Basically, you can render a voxelized scene
    with virtually all of the benefits of raymarching, and without putting
    too much pressure on the GPU.
    
    The rendering speed is not too bad, all things considered, but I'll try 
    to tweak it more later to cater to those with slower machines. Anyway, 
    I have a few of these that I plan to post at some stage.
    
    


	Other examples: 
    

    // Really stylish.
    Sparse grid marching - nimitz
    https://www.shadertoy.com/view/XlfGDs
    
	// A cell be cell traversal with raymarching inside each cell.
    // Amazing to think that this is over ten years old.
    Cubescape - iq
	https://www.shadertoy.com/view/Msl3Rr 
    
    // A rectangular prism example that should be easier to understand.
    Cell-By-Cell Raymarching - Shane
    https://www.shadertoy.com/view/DdBfzt
 

*/

// Scene: There are four surfaces to voxelize... or quasi-voxelize. I quickly
// put some simple ones in there, but you could code up any surface you can
// dream up... that doesn't fry the GPU. :)
//
// Tunnel: 0, Noisy Tunnel: 1, Blobby Surface: 2, Warped double planes: 3.
#define SCENE 1


#define PI 3.14159265
#define FAR 60.

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }


// Object ID: Either the back plane, extruded object or beacons.
int objID;


// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){

    // Depending on your machine, this should be faster than
    // the block below it.
    return texture(iChannel2, vec3(f*vec2(.2483, .3437), .5)).x;
    /* 
    uvec2 p = floatBitsToUint(f);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
    */
}

// IQ's "uint" based uvec3 to float hash.
float hash31(vec3 f){

    
    //return texture(iChannel1, f.xy*vec2(.2483, .1437) + f.z*vec2(.4865, .5467)).x;
    // Volume noise texture.
    return texture(iChannel2, f*vec3(.2483, .4237, .4865)).x;
    /* 
    uvec3 p = floatBitsToUint(f);
    p = 1103515245U*((p >> 2U)^(p.yzx>>1U)^p.zxy);
    uint h32 = 1103515245U*(((p.x)^(p.y>>3U))^(p.z>>6U));

    uint n = h32^(h32 >> 16);
    return float(n & uint(0x7fffffffU))/float(0x7fffffff);
    */ 
}

// Commutative smooth minimum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smin(float a, float b, float k){

   float f = max(0., 1. - abs(b - a)/k);
   return min(a, b) - k*.25*f*f;
}

// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smax(float a, float b, float k){
    
   float f = max(0., 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
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

// The path is a 2D sinusoid that varies over time, depending upon the frequencies, 
// and amplitudes.
vec2 path(in float z){ 
    
   
    //return vec2(0); // Straight.
    float a = sin(z*.11);
    float b = cos(z*.14);
    return vec2((a*4. -b*1.5), (b*1.7 + a*1.5)); 
    //return vec2(a*4. -b*1.5, 0.); // Just X.
    //return vec2(0, b*1.7 + a*1.5); // Just Y.
}

 

 
/*
// Compact, self-contained version of IQ's 3D value noise function.
float n3D(vec3 p){
	const vec3 s = vec3(7, 157, 113);
	vec3 ip = floor(p); p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p*p*(3. - 2.*p); //p *= p*p*(p*(p * 6. - 15.) + 10.);
    h = mix(fract(sin(mod(h, 6.2831))*43758.5453), 
            fract(sin(mod(h + s.x, 6.2831))*43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}
*/

// Texture volume based 3D noise.
float n3D(vec3 p){
	
    return texture(iChannel2, p/32.).x; // Range: [0, 1].
}


// IQ's 3D signed box formula.
float sBoxS(vec3 p, vec3 b, float sf){

  p = abs(p) - b + sf;
  return min(max(p.x, max(p.y, p.z)), 0.) + length(max(p, 0.)) - sf;
}

// IQ's 2D signed box formula with some added rounding.
float sBoxS(vec2 p, vec2 b, float sf){

  p = abs(p) - b + sf;
  return min(max(p.x, p.y), 0.) + length(max(p, 0.)) - sf;
}


// Global cell boundary distance variables.
vec3 gDir; // Cell traversing direction.
vec3 gRd; // Ray direction.
float gCD; // Cell boundary distance.
// Box dimension and local XY coordinates.
vec3 gSc; 
vec2 gP;


// Scene: There are four surfaces to voxelize... or quasi-voxelize. I quickly
// put some simple ones in there, but you could code up any surface you can
// dream up... that doesn't fry the GPU. :)
//
float getFunc(vec3 p){

    #if SCENE == 0
    
    // Standard perturbed tunnel function. It looks better without
    // subdivision turned on.

    // Offset the tunnel about the XY plane as we traverse Z.
    p.xy -= path(p.z);
    
    
    // Standard tunnel. Comment out the above first.
    float n = 3.5 - length(p.xy*vec2(1, .7));

    // Square tunnel. Almost redundant in a voxel renderer. :)
    //float n = 3. - max(abs(p.x), abs(p.y)); 

    // Tunnel with a floor.
    return min(p.y + 3., n); //n = min(-abs(p.y) + 3., n);

    #elif SCENE == 1
 
    // Simple noisy tunnel.
    
    float d = n3D(p/5.) - .55;//(.4 + sin(iTime/8.)*.125);

    p.xy -= path(p.z);

    float t = 2.5 - length(p.xy);
    //float t2 = 1. - length(p.xy - vec2(0, 2)); // Tunnel for light, above "t."


    return smax(t, d, .5); 
    
    #elif SCENE == 2 

    // Blobby transcendental surface... Not really suited to this
    // setup... Needs tweaking.
    
    p.xy -= path(p.z);

    p /= 4.;

    p = (cos(p*.315*2. + sin(p.zxy*.875*2.)));

    float n = dot(p, p);

    p = sin(p*3. + cos(p.yzx*3.));

    n -= .9 + p.x*p.y*p.z*.35;

    return n; 
    
    #else 
    
    // Warped double plane.
    
    p.xy -= path(p.z); // Move the scene around a sinusoidal path.
    p.xy = rot2(p.z/8.)*p.xy; // Twist it about XY with respect to distance.
    
    //float n = dot(sin(p*1. + sin(p.yzx*.5 + iTime)), vec3(.25)); // Timelapse effect.
    float n = dot(sin(p*1. + sin(p.yzx*.5)), vec3(.25)); // Sinusoidal layer.
     
    return 2. - abs(p.y) + n; // Warped double planes, "abs(p.y)," plus surface layers.
    
    #endif
     
}

// Global storage for the cell distance and ID.
vec4 gVal;


// The code here is a little fiddly, but if you ignore the individual logic, 
// you can see that we're partitioning space into repeat cells -- as is often 
// done -- then rendering (or not rendering, hence the sparse attribute) an 
// object inside each cell. The only difference between this example and a 
// regular one is a few lines at the end which involve raytracing from the 
// current point in each cell to the cell walls. That's it.
//
float map(vec3 q){
    
    
    // Subdividing space into cells, resulting in
    // the local coordinates and cell ID.
    //
    vec3 sc = vec3(1.36); // Scale.
    vec3 p = q; // Global coordinates.
    vec3 ip = (floor(p/sc) + .5)*sc; // Cell ID.
    int split = 0; // No division.
    if(hash31(ip + .03)<.35){ 
       sc /= 2.;
       ip = (floor(p/sc) + .5)*sc; // New cell ID, if needed.
       split = 1; // The cell has been divided.
    } 
    p -= ip;  // Local coordinates.
    
    
    // Plugging the cell's central coordinate ID into a 3D distance
    // function.
    float fn = getFunc(ip);
    
    // No object hit ID... Probably not necessary.
    objID = 0;
    
    
    // Voxel object and frameword distance.
    float vox = 1e5, frame = 1e5;
    
   
    // If we're below the 3D function threshold, render an object
    // inside the cell space.
    if(fn<0.){ 
    
        // Render a slightly round cube that takes up the cell.
        float minSc = min(min(sc.x, sc.y), sc.z);
        vox = sBoxS(p, sc/2. - .0*minSc, .05*minSc);
        float oVox = vox;

        float hw = minSc/3.; // Hole dimension.
 
        float xRnd = hash31(ip + .011) - .6;
        //float yRnd = hash31(ip + .022) - .6;
        float zRnd = hash31(ip + .033) - .6;
        
        float divF = 3.;
        vec3 q = mod(p + sc/divF/2., sc/divF) - sc/2./divF;
        
        // Bore out random Sierpinski-style holes from the XY cube face.
        if(zRnd<0.){ 
        
            // Large hole.
            float hXY = sBoxS(p.xy, mix(sc.xy, vec2(minSc), .5)/2., 0.);
            vox = smax(vox, -hXY - hw, .05*minSc);
            
            // Smaller holes.
            if(hash31(ip + .41)<.5){
                float hXY2 = sBoxS(q.xy, vec2(minSc)/2./divF, 0.);
                vox = smax(vox, -hXY2 - hw/divF, .05*minSc/divF);
            }
             
        }
        
        // Bore out random Sierpinski-style holes from the YZ cube face.
        if(xRnd<0.){
        
            // Large hole.
            float hYZ = sBoxS(p.yz, mix(sc.yz, vec2(minSc), .5)/2., 0.);
            vox = smax(vox, -hYZ - hw, .05*minSc);
            
            // Smaller holes.
            if(hash31(ip + .43)<.5){
                float hYZ2 = sBoxS(q.yz, vec2(minSc)/2./divF, 0.);
                vox = smax(vox, -hYZ2 - hw/divF, .05*minSc/divF);
            }
             
        }
        
        // XY cube face.
        //if(yRnd<0.){
        
            //float hXZ = sBoxS(p.xz, sc.xz/2., 0.);
            //vox = smax(vox, -hXZ - hw, .05*minSc);
 
            //float hXZ2 = sBoxS(q.xz, sc.xy/2./divF, 0.);
            //vox = smax(vox, -hXZ2 - hw/divF, .05*minSc/divF);
            
        //}
        
   
        // Frame lattice of sorts. Only calculate the frame lattice when
        // no cell subdivision has occurred. That's a design choice, not
        // a necessity.
        if(split==0){
        
            // Face selection.
            vec3 dir = abs(p); 
            dir = step(dir.yzx, dir.xyz)*step(dir.zxy, dir.xyz)*sign(p); 
            int splitN = hash31(ip + dir*sc + .03)<.333? 1 : 0;

            float fnN = getFunc(ip + dir*sc);

            float wF = .1; // Width factor.
            

            frame = sBoxS(p, sc/2.*wF*1.5, minSc*.025);
            //frame = length(p) - minSc/2.*wF*2.;

            // Replace some of the silver boxes.
            float met = hash31(floor(ip/3.) + .3) - .5;
            if(met<0. && hash31(floor(ip) + .22)<.65) vox = 1e5;

            if(fnN<0.){ // - dir*sc/2.


                vec3 lSc = minSc/2.*wF + abs(dir)*minSc;//*(1. - wF)*2.;
                frame = min(frame, sBoxS(p, lSc, .025*minSc));

                //vox = length(p - dir*sc/4.) - minSc/8.;

            } 
            
            // The edge evaluation isn't really meant to be performed with
            // a split lattice, so there's some untidy open edges. This hack 
            // cleans them up a bit.
            frame = max(frame, oVox);
     
            
             
        
        }  
        
         // Object ID.
        objID = vox<frame? 1 : 2;
   
        
    
    }
 
    // Storing the cell distance and cell ID for later usage.
    gVal = vec4(vox, ip);
    
    
    // Current position to the forward facing cubic cell wall 
    // plane intersection distances.
    vec3 rC = (gDir*sc - vec3(p))/gRd;
    
    // Minimum of all distances, plus not allowing negative distances, which
    // stops the ray from tracing backwards... I'm not entirely sure it's
    // necessary here, but it stops artifacts from appearing with other 
    // non-rectangular grids.
    gCD = max(min(min(rC.x, rC.y), rC.z), 0.) + .0015;
 
    
    // Return the minimum overall scene distance.
    return min(vox, frame); 

    
}

/*
// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total. 
// I tried to make it as concise as possible. Whether that translates to speed, or not, 
// I couldn't say.
vec3 doBumpMap( sampler2D tx, in vec3 p, in vec3 n, float bf){
   
    const vec2 e = vec2(0.001, 0);
    
    // Three gradient vectors rolled into a matrix, constructed with offset 
    // greyscale texture values.    
    mat3 m = mat3(tex3D(tx, p - e.xyy, n), tex3D(tx, p - e.yxy, n), 
                  tex3D(tx, p - e.yyx, n));
    
    vec3 g = vec3(0.299, 0.587, 0.114)*m; // Converting to greyscale.
    g = (g - dot(tex3D(tx,  p , n), vec3(0.299, 0.587, 0.114)) )/e.x; g -= n*dot(n, g);
                      
    return normalize( n + g*bf ); // Bumped normal. "bf" - bump factor.
    
}
*/

// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float d, t = 0.; //hash31(ro + rd)*.15
    
    //vec2 dt = vec2(1e5, 0); // IQ's clever desparkling trick.
    
    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = step(0., rd) - .5; // Equivalent to: sign(rd)*.5;
    gRd = rd; 
    
     
    const int iMax = 128;
    for (int i = min(iFrame, 0); i<iMax; i++){ 
    
        d = map(ro + rd*t);       
        //dt = d<dt.x? vec2(d, dt.x) : dt; // Shuffle things along.
        
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, 
        // as "t" increases. It's a cheap trick that works in most situations.
        if(abs(d)<.001 || t>FAR) break; 
        
        //t += i<32? d*.75 : d; 
        t += min(d*.9, gCD); 
    }
    
    // If we've run through the entire loop and hit the far boundary, 
    // check to see that we haven't clipped an edge point along the way. 
    // Obvious... to IQ, but it never occurred to me. :)
    //if(i>=iMax - 1) t = dt.y;

    return min(t, FAR);
}



// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p, float t) {
	
    const vec2 e = vec2(.001, 0);
    
    //return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), 
    //                      map(p + e.yxy) - map(p - e.yxy),	
    //                      map(p + e.yyx) - map(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    float mp[6];
    vec3[3] e6 = vec3[3](e.xyy, e.yxy, e.yyx);
    for(int i = min(iFrame, 0); i<6; i++){
		mp[i] = map(p + sgn*e6[i/2]);
        sgn = -sgn;
        if(sgn>2.) break; // Fake conditional break;
    }
    
    return normalize(vec3(mp[0] - mp[1], mp[2] - mp[3], mp[4] - mp[5]));
}


// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with 
// limited iterations is impossible... However, I'd be very grateful if someone could 
// prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not always affordable. :)
    const int maxIterationsShad = 48; 
    
    ro += n*.0015; // Coincides with the hit condition in the "trace" function.
    vec3 rd = lp - ro; // Unnormalized direction ray.
    

    float shade = 1.;
    float t = 0.; 
    float end = max(length(rd), .0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;
    
    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = sign(rd)*.5;
    gRd = rd;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. 
    // Obviously, the lowest number to give a decent shadow is the best one to choose. 
    for (int i = min(iFrame, 0); i<maxIterationsShad; i++){

        float d = map(ro + rd*t);
       
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), 
        // dist += clamp(h, .01, stepDist), etc.
        t += clamp(min(d*.9, gCD), .02, .25); 
        
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>end) break; 
    }

    // Shadow.
    return max(shade, 0.); 
}


// A slight variation on a function from Nimitz's hash collection, here: 
// Quality hashes collection WebGL2 - https://www.shadertoy.com/view/Xt3cDn
vec2 hash23(vec3 f){

    uvec3 p = floatBitsToUint(f);
    p = 1103515245U*((p >> 2U)^(p.yzx>>1U)^p.zxy);
    uint h32 = 1103515245U*(((p.x)^(p.y>>3U))^(p.z>>6U));

    uint n = h32^(h32>>16);

    uvec2 rz = uvec2(n, n*48271U);
    // Standard uvec2 to vec2 conversion with wrapping and normalizing.
    return vec2((rz>>1)&uvec2(0x7fffffffU))/float(0x7fffffff);
}

 
// A nice random hemispherical routine taken out of one of IQ's examples.
// The routine itself was written by Fizzer.
vec3 cosDir(in vec3 p, in vec3 n){

    vec2 rnd = hash23(p);
    float u = rnd.x;
    float v = rnd.y;
    
    // Method 1 and 2 first generate a frame of reference to use with an arbitrary
    // distribution, cosine in this case. Method 3 (invented by fizzer) specializes 
    // the whole math to the cosine distribution and simplfies the result to a more 
    // compact version that does not depend on a full frame of reference.

    // Method by fizzer: http://www.amietia.com/lambertnotangent.html
    float a = 6.2831853*v;
    u = 2.*u - 1.;
    return normalize(n + vec3(sqrt(1. - u*u)*vec2(cos(a), sin(a)), u));
    
}

// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n){
    

	float sca = 3., occ = 0.;
    for(int i = 0; i<12; i++){
    
        float hr = (float(i) + 1.)*.35/12.; 
        //float fi = float(i + 1);
        //vec3 rnd = vec3(hash31(p + fi), hash31(p + fi + .1), hash31(p + fi + .3)) - .5;
        //vec3 rn = normalize(n + rnd*.15);
        vec3 rn = cosDir(p + n*hr, n); // Random half hemisphere vector.
        float d = map(p + rn*hr);
        
        occ = occ + max(hr - d, 0.)*sca;
        sca *= .7;
    }
    
    return clamp(1. - occ, 0., 1.);    
    
}
 
///////////////////////////


// Microfaceted normal distribution function.
float D_GGX(float NoH, float roughness) {
    float alpha = pow(roughness, 4.);
    float b = (NoH*NoH*(alpha - 1.) + 1.);
    return alpha/(3.14159265*b*b);
}

// Surface geometry function.
float G1_GGX_Schlick(float NoV, float roughness) {
    //float r = roughness; // original
    float r = .5 + .5*roughness; // Disney remapping.
    float k = (r*r)/2.;
    float denom = NoV*(1. - k) + k;
    return max(NoV, .001)/denom;
}

float G_Smith(float NoV, float NoL, float roughness) {
    float g1_l = G1_GGX_Schlick(NoL, roughness);
    float g1_v = G1_GGX_Schlick(NoV, roughness);
    return g1_l*g1_v;
}

// Bidirectional Reflectance Distribution Function (BRDF). 
//
// If you want a quick crash course in BRDF, see the following:
// Microfacet BRDF: Theory and Implementation of Basic PBR Materials
// https://www.youtube.com/watch?v=gya7x9H3mV0&t=730s
//
vec3 BRDF(vec3 col, vec3 n, vec3 l, vec3 v, 
          float type, float rough, float fresRef){
     
  vec3 h = normalize(v + l); // Half vector.

  // Standard BRDF dot product calculations.
  float nv = clamp(dot(n, v), 0., 1.);
  float nl = clamp(dot(n, l), 0., 1.);
  float nh = clamp(dot(n, h), 0., 1.);
  float vh = clamp(dot(v, h), 0., 1.);  

  
  // Specular microfacet (Cook- Torrance) BRDF.
  //
  // F0 for dielectics in range [0., .16] 
  // Default FO is (.16 * .5^2) = .04
  // Common Fresnel values, F(0), or F0 here.
  // Water: .02, Plastic: .05, Glass: .08, Diamond: .17
  // Copper: vec3(.95, .64, .54), Aluminium: vec3(.91, .92, .92), Gold: vec3(1, .71, .29),
  // Silver: vec3(.95, .93, .88), Iron: vec3(.56, .57, .58).
  vec3 f0 = vec3(.16*(fresRef*fresRef)); 
  // For metals, the base color is used for F0.
  f0 = mix(f0, col, type);
  vec3 F = f0 + (1. - f0)*pow(1. - vh, 5.);  // Fresnel-Schlick reflected light term.
  // Microfacet distribution... Most dominant term.
  float D = D_GGX(nh, rough); 
  // Geometry self shadowing term.
  float G = G_Smith(nv, nl, rough); 
  // Combining the terms above.
  vec3 spec = F*D*G/(4.*max(nv, .001));
  
  
  // Diffuse calculations.
  vec3 diff = vec3(nl);
  diff *= 1. - F; // If not specular, use as diffuse (optional).
  diff *= (1. - type); // No diffuse for metals.

  
  // Combining diffuse and specular.
  // You could specify a specular color, multiply it by the base
  // color, or multiply by a constant. It's up to you.
  return (col*diff + spec*3.14159265);
  
}
 

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
	
	// Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
	
	// Camera Setup.
	vec3 camPos = vec3(0, 0, iTime*5.); // Camera position, doubling as the ray origin.
    vec3 lookAt = camPos + vec3(0, 0, .25);  // "Look At" position.
 
    // Light positioning. 
 	vec3 lightPos = camPos + vec3(0, .5, 6);// Put it in front of the camera.

	// Using the Z-value to perturb the XY-plane.
	// Sending the camera, "look at," and two light vectors down the tunnel. The "path" 
    // function is synchronized with the distance function.
	lookAt.xy += path(lookAt.z);
	camPos.xy += path(camPos.z);
	lightPos.xy += path(lightPos.z);

    // Using the above to produce the unit ray-direction vector.
    float FOV = PI/3.; // FOV - Field of view.
    vec3 forward = normalize(lookAt - camPos);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x )); 
    vec3 up = cross(forward, right);

    // rd - Ray direction.
    vec3 rd = normalize(uv.x*right + uv.y*up + forward/FOV);
    // Fisheye lens.
    //rd = normalize(vec3(rd.xy, rd.z - dot(rd.xy, rd.xy)*.2));    
    
    // Swiveling the camera about the XY-plane (from left to right) when turning corners.
    // Naturally, it's synchronized with the path in some kind of way.
	rd.xy = rot2( path(lookAt.z).x/24.)*rd.xy;
    

    // Scene distance.
	float t = trace(camPos, rd);
    
    // Object ID: Back plane (0), or the metaballs (1).
    int svObjID = objID;
    
    // Saving some 3D cell values. In this case, distance and ID.
    vec4 svVal = gVal;
    
    
    // Background fog color.
    vec3 fog = mix(vec3(.32, .28, .16)*3., vec3(.32, .12, .08)*2., -rd.y*.5 + .5);
    //vec3 fog = vec3(0);
	
    // Initialize the scene color.
    vec3 sceneCol = fog;
    
	
	// The ray has effectively hit the surface, so light it up.
	if(t<FAR && svObjID>0){
	
   	
    	// Surface position and surface normal.
	    vec3 sp = camPos + rd*t;
        
        // Voxel normal.
        vec3 sn = getNormal(sp, t);
        
        // Sometimes, it's necessary to save a copy of the unbumped normal.
        //vec3 snNoBump = sn;
        
        // I try to avoid it, but it's possible to do a texture bump and a function-based
        // bump in succession. It's also possible to roll them into one, but I wanted
        // the separation... Can't remember why, but it's more readable anyway.
        //
        // Texture scale factor.
        const float tSize0 = 1./3.;
        // Texture-based bump mapping.
	    //sn = doBumpMap(iChannel0, sp*tSize0, sn, .003);

        // Function based bump mapping. Comment it out to see the under layer. It's pretty
        // comparable to regular beveled Voronoi... Close enough, anyway.
        //sn = doBumpMap(sp, sn, .1);
        
       
	    // Ambient occlusion.
	    float ao = calcAO(sp, sn) ;//calculateAO(sp, sn);//*.75 + .25;

        
    	// Light direction vectors.
	    vec3 ld = lightPos - sp;

        // Distance from respective lights to the surface point.
	    float lDist = max(length(ld), .0001);
    	
    	// Normalize the light direction vectors.
	    ld /= lDist;
	    
	    // Light attenuation, based on the distances above.
	    float atten = 1./(1. + lDist*lDist*.05); // + distlpsp*distlpsp*0.025
    	
        // Ambient light.
        // I wanted to use a little more than a constant for ambient light, but 
        // without having to resort to sophisticated methods, then I remembered 
        // Blackle's example, here:
        // Quick Lighting Tech - blackle
        // https://www.shadertoy.com/view/ttGfz1
        //float ambience = pow(length(sin(sn*2.)*.45 + .5)/sqrt(3.), 2.)*.75; // Studio.
        float ambience = length(sin(sn*2.)*.5 + .5)/sqrt(3.)*
                         smoothstep(-1., 1., sn.y)*.5; // Outdoor.
 
    	
    	// Diffuse lighting.
	    float diff = max(dot(sn, ld), 0.);
   	
    	// Specular lighting.
	    float spec = pow(max( dot( reflect(-ld, sn), -rd ), 0.0 ), 32.);

	    
	    // Fresnel term. Good for giving a surface a bit of a reflective glow.
        float fre = pow( clamp(dot(sn, rd) + 1., .0, 1.), 1.);
        
        // Obtaining the texel color. 
        vec3 ref = reflect(sn, rd);

        // Object texturing.
        
        // Coloring.
        float rnd = hash31(svVal.yzw);
	    vec3 texCol = .5 + .45*cos(6.2831*rnd/3. + vec3(0, 1, 2) + .5);
        
        texCol = vec3(1)*dot(texCol, vec3(.299, .587, .114));
        
        // Metallic box threshold.
        float met = hash31(floor(svVal.yzw/3.) + .3) - .5;
        // Metallic coloring for some boxes and the frame.
        if(met<0. || svObjID==2) texCol = vec3(.2);
        //if(svObjID==2) texCol *= vec3(1, .8, .6)*1.2;
 
        // Multiplying objects by respective texture colors.
        if(met<0. || svObjID==2) texCol *= tex3D(iChannel1, sp/4., sn)*4.;
	    else texCol *= .1 + tex3D(iChannel0, sp*tSize0, sn)*4.;
        
         
        // Shadows.
        float shad = softShadow(sp, lightPos, sn, 8.);
        
        
        float rnd2 = hash31(svVal.yzw + .2);
        float matType = 0.; // Dielectric.
        float roughness = min(dot(texCol, vec3(.299, .587, .114))*.5, 1.);
        float reflectance = hash31(svVal.yzw)*.75;
        // Metallic properties for some boxes and the framework.
        if(met<0. || svObjID==2) { 
            texCol = texCol*2.*vec3(1, .8, .5); 
            matType = 1.; reflectance = .5; // Metallic.
            roughness = min(roughness*5., 1.);
        }

        
        // Requires "St Peter's Basillica" cube map loaded into "iChannel3".
        // Specular reflection.
        vec3 hv = normalize(-rd + ld); // Half vector.
        vec3 refTx = texture(iChannel3, ref, 1.).xyz; refTx *= refTx; // Cube map.
        float spRef = pow(max(dot(hv, sn), 0.), 8.); // Specular reflection.
        //spRef = mix(spRef/4., spRef, 1. - smoothstep(0., .01, d + .05));   
        float rf = 8.;//(svObjID == 1)? 8. : 1.;
        texCol += texCol*spRef*dot(refTx, vec3(.299, .587, .114))*rf;


        
        // Cook-Torrance based lighting.
        vec3 ct = BRDF(texCol, sn, ld, -rd, matType, roughness, reflectance);
        
        // Combining the ambient and microfaceted terms to form the final color:
        // None of it is technically correct, but it does the job. Note the hacky 
        // ambient shadow term. Shadows on the microfaceted metal doesn't look 
        // right without it... If an expert out there knows of simple ways to 
        // improve this, feel free to let me know. :)
        sceneCol = (texCol*ambience*(shad*.5 + .5) + ct*(shad));


	    // Shading.
        sceneCol *= atten*ao;
        
        // "XT95" did such a good job with the AO, that it's worth a look on its own. :)
        //sceneCol = vec3(ao); 

	   
	
	}
       
    // Blend in a bit of fog for atmospheric effect.    
    sceneCol = mix(sceneCol, fog, smoothstep(.2, .99, t/FAR)); // exp(-.002*t*t), etc.

    // Clamp and present the badly gamma corrected pixel to the screen.
	fragColor = vec4(sqrt(clamp(sceneCol, 0., 1.)), 1.0);
	
}