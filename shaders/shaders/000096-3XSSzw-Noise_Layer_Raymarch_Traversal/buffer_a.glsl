// Buffer A (buffer) — Noise Layer Raymarch Traversal by Shane
// https://www.shadertoy.com/view/3XSSzw

/*

    Noise Layer Raymarch Traversal
    ------------------------------
    
    Performing a raymarch traversal through cross-sectional contour 
    layers of 2D noise. It's a pretty common exercise among graphics
    programmers. I put this together some time ago, but the code was
    pretty messy, so it took me some time to make it presentable.
    
    I got a bit carried away with the visual presentation. I'm not sure
    what look I was going for, but I'd been looking at a lot of that 
    weird AI imagery, so I'm pretty sure that was an influence. It's 
    kind of ironic that I'm attempting to copy the aesthetic of an 
    algorithm designed to rip off the aesthetics of graphic artists. :)
    
    Anyway, most of the character count is taken up with window dressing.
    Rendering noise layers is not particularly hard. You have to be 
    comfortable with traversing through slices, but that's only a few
    lines of code. It seems to run fast enough in Window mode, but I 
    wouldn't call this a fast shader, so apologies to anyone trying to
    run it on slower machines.
    
    I'd originally applied a gradient factor to the 2D slices, but it 
    seemed to raymarch easier without it. However, I used it to render
    clean equiwidth lines on the surfaces. I have a way more interesting
    contour related scene that I'll post at some stage.
    
    
    
    Similar examples:
    
    // 2D contours with some faux 3D shading.
    Contoured Layers - Shane
    https://www.shadertoy.com/view/3lj3zt


*/

// PI and 2 PI
#define PI 3.14159265358979
#define TAU 6.283185307179586


 
// Maximum ray distance.
#define FAR  15.

// Global tile scale. Value of about "1./2." to "1./6" work, 
// but it's designed to work with the currect value.
#define GSCALE vec3(1, 1./12., 1)

// There are two noise functions, namely, gradient noise and sine noise.
// Gradient noise: 0, Sine noise: 1.
#define NOISE_FUNC 0

// Light type: Point: 0, Direct: 1
#define LIGHT_TYPE 0

// Puting a rounded bevel on the layered contours.
#define BEVEL

// Forward camera speed for that tunnel boring effect. 
// Set to zero for a static camera.
#define CAM_Z .25


// Bore out some holes.
//#define HOLES



// Global time variable.
float tm;


//////////////

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

 
// Tri-Planar blending function: Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D tex, in vec3 p, in vec3 n){    
    
    // Tightening up the normal a bit.
    n = max(n*n - .2, .001); // max(abs(n), 0.001), etc.
    n /= dot(n, vec3(1)); 
    //n /= length(n); 
    
    // Texure samples. One for each plane.
    vec3 tx = texture(tex, p.yz).xyz;
    vec3 ty = texture(tex, p.zx).xyz;
    vec3 tz = texture(tex, p.xy).xyz;
    
    // Multiply each texture plane by its normal dominance factor.... or however you wish
    // to describe it. For instance, if the normal faces up or down, the "ty" texture 
    // sample, representing the XZ plane, will be used, which makes sense.
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like
    // that. :) Once the final color value is gamma corrected, you should see correct 
    // looking colors.
    return mat3(tx*tx, ty*ty, tz*tz)*n; // Equivalent to: tx*tx*n.x + ty*ty*n.y + tz*tz*n.z;

}
 

// IQ's "uint" based uvec3 to float hash.
float hash31(vec3 f){

    uvec3 p = floatBitsToUint(f);
    p = 1664525U*((p >> 2U)^(p.yzx>>1U)^p.zxy);
    uint h32 = 1103515245U*(((p.x)^(p.y>>3U))^(p.z>>6U));

    uint n = h32^(h32 >> 16);
    return float(n & uint(0x7fffffffU))/float(0x7fffffff);
}


// A slight variation on one of Dave Hoskins's hash functions,
// which you can find here:
//
// Hash without Sine -- Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
// 2 out, 2 in...

//#define STATIC
vec2 hash22G(vec2 p){
    
	vec3 p3 = fract(vec3(p.xyx)*vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 35.3873);
    #ifdef STATIC
    return fract((p3.xx + p3.yz)*p3.zy)*2. - 1.;
    #else
    p = fract((p3.xx + p3.yz)*p3.zy);
    return sin(p*TAU + tm); // Animation, if desired.
    #endif
}



#if NOISE_FUNC == 1
// I made this function up pretty quickly. It's just a combination of
// two sine layers, combined in a similar manner to fBM noise layers.
float sinNoise(vec2 f){

    float d = dot(sin(f*2. + tm*.5 - cos(f.yx*2.8 - tm*.5)), vec2(.25)) + .5;
    f *= 2.;
    return mix(d, dot(sin(f*2. + tm*1. - cos(f.yx*2.8 - tm*1.)), vec2(.25)) + .5, 1./3.);

}
#else
// Gradient noise: Ken Perlin came up with it, or a version of it. Either way, this is
// based on IQ's implementation. It's a pretty simple process: Break space into squares, 
// attach random 2D vectors to each of the square's four vertices, then smoothly 
// interpolate the space between them.
float gradN2D(in vec2 f){
    
    // Used as shorthand to write things like vec3(1, 0, 1) in the short form, e.yxy. 
    const vec2 e = vec2(0, 1);
   
    // Set up the cubic grid.
    // Integer value - unique to each cube, and used as an ID to generate random vectors for 
    // the cube vertiies. Note that vertices shared among the cubes have the save random 
    // vectors attributed to them.
    vec2 p = floor(f);
    f -= p; // Fractional position within the cube.
    

    // Smoothing - for smooth interpolation. Use the last line see the difference.
    // Quintic smoothing. Slower and more squarish, but derivatives are smooth too.
    vec2 w = f*f*f*(f*(f*6.-15.)+10.); 
    //vec2 w = f*f*(3. - 2.*f); // Cubic smoothing. 
    //vec2 w = f*f*f; w = ( 7. + (w - 7. ) * f ) * w; // Super smooth, but less practical.
    //vec2 w = .5 - .5*cos(f*PI); // Cosinusoidal smoothing.
    //vec2 w = f; // No smoothing. Gives a blocky appearance.
    
    // Smoothly interpolating between the four verticies of the square. Due to the shared 
    // vertices between grid squares, the result is blending of random values throughout the 
    // 2D space. By the way, the "dot" operation makes most sense visually, but isn't the 
    // only metric possible.
    float c = mix(mix(dot(hash22G(p + e.xx), f - e.xx), 
                      dot(hash22G(p + e.yx), f - e.yx), w.x),
                  mix(dot(hash22G(p + e.xy), f - e.xy), 
                      dot(hash22G(p + e.yy), f - e.yy), w.x), w.y);
    
    // Taking the final result, and converting it to the zero to one range.
    return c*.5 + .5; // Range: [0, 1].
}

#endif

// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h, in float sf){
 
    // Slight rounding. A little nicer, but slower.
    vec2 w = vec2( sdf, abs(pz) - h) + sf;
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.)) - sf;   
}

// The 2D distance value. It could be anything you want, but
// for this example, where using some cliche gradient noise.
float dist2D(vec2 p, float iDepth){
      
    
    #if NOISE_FUNC == 1
    // Layer depth (or time) distortion.
    tm = -iDepth*5.;// + iTime/8.;
    
    float d = sinNoise(p*2.);
    #else
    // Layer depth (or time) distortion.
    tm = -iDepth*3.; // + iTime/8.;
    
    // Gradient noise formula.
    float d = gradN2D(p*2.);
    #endif
    
    #if NOISE_FUNC == 1
    d += iDepth*.85 - .36;
    #else
    d += iDepth*.48 - .42;
    #endif
      
    //d = mix(d, d*d, .5);
    return d/2.;
}

/*
vec3 getCol(float val){
    return (.5 + .45*cos(mod(TAU*val + vec3(0, 1, 2)*(1. + val), TAU)));
}
*/

// Ray origin, ray direction, point on the line, normal. 
float rayLine(vec3 ro, vec3 rd, vec3 p, vec3 n){
   
   // This it trimmed down, and can be trimmed down more. Note that 
   // "1./dot(rd, n)" can be precalculated outside the loop. However,
   // this isn't a GPU intensive example, so it doesn't matter here.
   //return max(dot(p - ro, n), 0.)/max(dot(rd, n), 1e-8);
   float dn = dot(rd, n);
   return dn>0.? dot(p - ro, n)/dn : 1e8;   
   //return dn>0.? max(dot(p - ro, n), 0.)/dn : 1e8;   

} 
 
vec4 vObjID;

// Global cell boundary distance variables.
vec3 gDir; // Cell traversing direction.
vec3 gRd; // Ray direction.
float gCD; // Cell boundary distance.
// Scale and local XY coordinates and save values
vec3 gSc; 
vec3 gP;
vec4 gID;

 
// A simple glow variable.
vec3 glow;

float map(vec3 q3) {


    // Floor. Redundant here.
    float fl = q3.y + 1.;
 
 
    vec3 sc = GSCALE; // Scale.
  
    // Local coordinates of vertical (Y) slices. 
    float ipy = (floor(q3.y/sc.y) + .5)*sc.y;
    float py = q3.y - ipy;
 
    // 2D slice distance field value.
    float d2 = dist2D(q3.xz, ipy); 
    vec2 p = q3.xz;
     
     
 

    // Top and bottom faces.  
    gCD = rayLine(vec3(q3.x, py, q3.y), gRd, gDir*vec3(0, sc.y, 0), gDir*vec3(0, 2, 0));
    // Minimum of all distances, plus not allowing negative distances, which
    // stops the ray from tracing backwards... I'm not entirely sure it's
    // necessary here, but it stops artifacts from appearing with other grids.
    gCD = max(gCD, 0.) + .0015;
   

    //////////////
    
 
    // Holes in the layer objects.
    #ifdef HOLES
    d2 = max(d2, -(d2 + .035 - ipy/16.));
    #endif
    
    // Contour layer height.
    #ifdef BEVEL
    float yH = py>0.? sc.y/2.*.66 : sc.y/2. - .0015;
    #else
    float yH = sc.y/2. - .0015;
    #endif
    
    // Creating the extruded contour layers.
    // Maximum block height.
    float maxH = sc.y*2.;
    float d = ipy<maxH? opExtrusion(d2, py, yH, 0.) : 1e5;

 
    #ifdef BEVEL
    // Putting curves on the top to reflect the light better.
    if(py>0.){
        
        d += d2*.25;//(min(d2, .002));//d2*.75; // Raised tops.
        d = max(d, abs(py) - sc.y/2. + .0015);
    }
    #endif
     
    
   
    // Add some gradient glow to the lower slices.
    if(d<.25){ 
        float dd = min(q3.y + sc.y*4., 0.);
        glow += max(-dd, 0.)*2.;    
    }
    
    
     // Saving the dimensions and local coordinates.
    gSc = sc;
    gP = vec3(p.x, py, p.y);
    gID = vec4(d2, vec3(0, ipy, 0));
    

    // Saving the individual object values for sorting (later).
    vObjID = vec4(fl, d, 1e5, 1e5);
 
    // Scene distance.
    return min(fl, d);
}


float rayMarch(vec3 ro, vec3 rd) {
    
    float d, t = hash31(ro + rd)*.25; // Glow jitter.
    vec2 dt = vec2(1e8, 0); // IQ's edge desparkle trick.


    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = step(0., rd) - .5; // sign(rd)*.5;
    gRd = rd;
    

    // Initialize the glow to zero.
    glow = vec3(0);

    const int iter = 160;
    int i = 0;
     
    for (i = 0; i<iter; i++) {
        
        // Scene distance.       
        d = map(ro + rd*t);
         
        // IQ's clever edge desparkle trick. :)
        //if (abs(d)<dt.x) { dt = vec2(min(d*.8, gCD), t); } 
        
        // If we're within the surface threshold, or if the
        // ray has gone too far, break;
        if (abs(d)<.001 || t > FAR) {
           break;
        }
        
        // Advance the ray.
        t += min(d*.8, gCD);
    }
    
    //if(i == iter - 1) { t = dt.y; }

    // Cap the total scene distance. It rarely comes up, but
    // capping can stop far plane sparkles from occuring.
    return min(t, FAR);
}

float softShadow(in vec3 p, in vec3 ld, in float lDist, in float k) {
    
    float res = 1.;
    float t = 0.;

    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = step(0., ld) - .5;
    gRd = ld; 

    for (int i=0; i<64; i++){

        float d = map(p + ld*t);
        res = min(res, k*d/t);
        if (d<0. || t>lDist) break;

        t += clamp(min(d*.8, gCD), .01, .25);
    }
    return clamp(res, 0., 1.);
}

// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 normal(in vec3 p) {

    /*
    // Hardware normal, but only for smooth surfaces... Hardware derivatives 
    // remind of when LCD screens first came out. I appreciated the technology, 
    // but they were terrible to look at. :)
    vec3 fdx = dFdx(p);
    vec3 fdy = dFdy(p);
    return normalize(cross(fdx, -fdy));
    */
	
    //return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), map
    //                      map(p + e.yxy) - map(p - e.yxy),	
    //                      map(p + e.yyx) - map(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    vec3 e = vec3(.0025, 0, 0), mp = e.zzz; // Spalmer's clever zeroing.
    for(int i = min(iFrame, 0); i<6; i++){
		mp.x += map(p + sgn*e)*sgn;
        sgn = -sgn;
        if((i&1)==1){ mp = mp.yzx; e = e.zxy; }
    }
    
    return normalize(mp);
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
    
        float hr = (float(i) + 1.)*.25/12.; 
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

	
// The path is a 2D sinusoid that varies over time, depending upon the frequencies, 
// and amplitudes.
vec2 path(in float z){ float s = sin(z/4.)*cos(z/2.); return vec2(s*8., 0.); }


vec4 render(vec3 ro, vec3 rd, inout float svVal){


    #if LIGHT_TYPE == 0
    vec3 lp = ro + vec3(1, 1.5, 3);
    //lp.xy += path(lp.z);
    #else
    vec3 ld = normalize(vec3(1, 1.5, 3));//-vec3(-1.5, -3, -3)
    //vec3 lp = ro + ld*FAR;
    #endif
    

    float t = rayMarch(ro, rd);
    
    svVal = t;

    // Saving the global scale, local cell coorinates and cell ID.
    vec3 svSc = gSc;
    vec3 svP = gP;
    vec4 svGID = gID;
    
    vec3 svGlow = glow; // Glow.
  
    
    // Saving the time value calculated in the distance function.
    float svTm = tm;
     
    
    // Scene object identification.
    int objID = vObjID.x<vObjID.y? 0 : 1;
    
    // Surface position.
    vec3 p = ro + rd*t;
    
    vec3 sky = mix(vec3(2, .8, .4), vec3(.4, .8, 2), smoothstep(0., 1., p.y + 1.));
   
      // Initializing.
    vec3 col = sky;
   
 
    if (t<FAR){
        
  
        // Normal.
        vec3 n = normal(p);
        
        // Light.
        #if LIGHT_TYPE == 0
        vec3 ld = lp - p;
        float lDist = length(ld);
        ld /= lDist;
        #else
        float lDist = FAR;//length(lp - p);
        #endif
        
         
        // Shadow and ambient occlusion.
        float shd = softShadow(p + n*.0015, ld, lDist, 8.);
        float ao = calcAO(p, n);
         

        // Block ID and corresponding height.
        //vec3 id = svGID.yzw;
 
        // Object color. Bluish graphite, or something.
        vec3 oCol = vec3(.1, .15, .3);
        //vec3 oCol = getCol(pow(max(GSCALE.y*3.-svGID.z, 0.), 2.)/1.66);
         
        // Side color.
        vec3 sCol = mix(vec3(.4, .25, 1), vec3(1, .2, .4), 
                        clamp(1. - max(p.y + .25, 0.)*4., 0., 1.));
        // Mixing the side colors with the top graphite color.                  
        oCol = mix(oCol, sCol*4., 1. - smoothstep(0., .003, svP.y - svSc.y/4.));


///// 
        // Determining the surface gradient value, then applying 
        // it to the surface distance value in order to obtain
        // concise edge lines. This is a pretty standard way to
        // produce concise equiwidth 2D surface contour lines.
        tm = svTm; // Time value.
        vec2 q = p.xz;
        float px = .001;
        #if NOISE_FUNC == 1
        float d = sinNoise(q*2.);
        float d3X = sinNoise((q - vec2(px, 0))*2.); 
        float d3Y = sinNoise((q - vec2(0, px))*2.);        
        #else
        // 2D surface contour samples.
        float d = gradN2D(q*2.);
        float d3X = gradN2D((q - vec2(px, 0))*2.); 
        float d3Y = gradN2D((q - vec2(0, px))*2.);
        #endif
        // 2D surface slice gradient.
        vec2 dX = (vec2(d3X, d3Y) - d)/px/2.;
        float dt = length(dX); 
        // Applying the gradiet factor to the saved 2D surface value.
        svGID.x /= dt;
///////  
        // Using the surface value above to produce concise edges on the slices.
        float ew = .004;
        float bord = abs(svGID.x + ew/2.) - ew;
        bord = max(bord, abs(abs(svP.y + ew) - svSc.y/2. + ew*2.) - ew);
        // Applying the edges to the extruded noise slices.
        oCol = mix(oCol, (oCol*3. + .5), 1. - smoothstep(0., .003, bord - ew*2.));
        oCol = mix(oCol, oCol*.05, 1. - smoothstep(0., .003, bord));
     
        /*
        // Adding some fake curvature lines and AO to each level.
        // This was hacked in on the spot, but seems to work.
        float py = mod(p.y, svSc.y) - svSc.y/2.;
        float ln = abs(py) - svSc.y/4.*.96;
        oCol = mix(oCol, oCol*.25, smoothstep(0., .003, ln*(1. - abs(n.y))));
        */
        
        
        // Floor color.
        //if(objID==0) oCol = vec3(.25);
 
     
        // Using pseudo science to apply a bit of faux back scatter. :)
        vec3 fillDir = vec3(-ld.xz, 0.);
        float bl = max(dot(fillDir, n), 0.);
        oCol = mix(oCol, oCol + sky*3., bl + .04);
      
      
        // Texture coordinates.
        vec3 txP = vec3(p.x, p.y - svSc.y, p.z);
        vec3 tx = tex3D(iChannel0, txP*3. + svGID.z, n);
        txP.xz = rot2(PI/5.)*txP.xz;
        //tx = mix(tx, tex3D(iChannel0, txP*5. + svGID.z/2., n), .35);
        
        // Applying the texture.
        oCol *= tx*1.8 + .35;
       
        #if LIGHT_TYPE == 0
        float atten = 1./(1. + lDist*.1);
        #else
        // Direct lighting attenuation. Not realistic, but all 
        // lighting is fake anyway. :)
        float atten = 1./(1. + lDist*.03);
        #endif
 

        // Diffuse value.
        float dif = max(dot(ld, n), 0.);
        dif = pow(dif, 4. + 4.*tx.x); // Diffusivity based on texture.
        
        // Specular value.
        float spe = pow(max(dot(reflect(ld, n), rd), 0.), 64.*tx.x + 8.);

      
        // Cheap specular reflections.
        float speR = pow(max(dot(normalize(ld - rd), n), 0.), 8.);
        vec3 rf = reflect(rd, n); // Surface reflection.
        vec3 rTx = texture(iChannel1, rf).zxy; rTx *= rTx;
        oCol = oCol + oCol*speR*rTx*4.;
        
        
        // I wanted to use a little more than a constant for ambient light this 
        // time around, but without having to resort to sophisticated methods, then I
        // remembered Blackle's example, here:
        // Quick Lighting Tech - blackle
        // https://www.shadertoy.com/view/ttGfz1
        //
        // Studio.
        float am = pow(length(sin(n)*.5 + .5)/sqrt(3.), 2.); 
        // Outdoor.
        //float am = length(sin(n*2.)*.5 + .5)/sqrt(3.)*smoothstep(-1., 1., n.y); 
        
        //oCol *= n.y*.5 + .75;

        // Lit color.
        col = oCol*(am*(shd*.5 + .5) + dif*shd + vec3(1, .97, .92)*spe*0.*shd)*ao*atten;
   
         
        // Adding a touch of glow to the column walls.
        col += vec3(1.2, .5, .15)*col*svGlow*4.;
        //sky += vec3(1.2, .5, .15)*sky*svGlow;
         
        // Debug.
        //col = vec3(ao);
    }
    
  
    // Fog.
    col = mix(col, sky.xyz*2., smoothstep(.15, .99, t/FAR));
    
    // Slight desaturation.
    //col = mix(col, vec3(1)*dot(col, vec3(.299, .587, .114)), .15);
  
    
    // Returning the final color for this pass... There's only one
    // pass here, but a render function is useful when you want to
    // bounce light around.
    const float focD = 2., coc = .8;
    // Linear distance from either side of the focal point.
    float l = abs(t - focD) - coc;
    l = clamp(l/coc, 0., 2.);
    svVal = mix(l, smoothstep(0., 1., -p.y + .15), .25);
    return vec4(col, 0.);
  
}



void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
 
    // Coordinates.
    vec2 u = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    // Screen warp.
    u *= 1. + dot(u, u)*.125;
    
    // Global time.
    tm = iTime;
    
    // Look vector and camera origin.
    vec3 lk = vec3(0, 0, iTime*CAM_Z);
    vec3 ro = lk + vec3(0, 1., -1.4);
    
    //lk.xy += path(lk.z);
	//ro.xy += path(ro.z);
 
    // Setting up a camera using the usual process. The variable names
    // here suggest that this lot came from one of IQ's examples.
    vec3 ww = normalize(lk - ro);
    vec3 uu = normalize(cross(vec3(0, 1, 1), ww ));
    vec3 vv = cross(ww, uu);
    const float FOV = PI/4.; // Field of view.
    vec3 rd = normalize(u.x*uu + u.y*vv + ww/FOV); // Unit direction vector.
    
    // Swiveling the camera from left to right when turning corners.
    vec2 pDir = normalize(path(lk.z) - path(ro.z));
    //rd.xz = rot2(acos(dot(vec2(0, 1), pDir)))*rd.xz; 
    float turn = path(lk.z).x;
    rd.xz = rot2(turn/32.)*rd.xz;
    rd.xy *= rot2(-turn/64.);
    
    
    /*
    // Mouse movement.
    if(iMouse.z>1.){
        rd.yz *= rot2((iMouse.y - iResolution.y*.5)/iResolution.y*3.1459);  
        rd.xz *= rot2((iMouse.x - iResolution.x*.5)/iResolution.x*3.1459);  
    } 
    */

    // Render... I was going to perform a couple of passes, but decided against 
    // it. However, it's usually a good idea to have a separate render function.
    float t = FAR;
    vec4 c4 = render(ro, rd, t);
    vec3 col = c4.xyz;
    

    
    // Save.
    fragColor = vec4((max(col, 0.)), t);//gr
    
}
