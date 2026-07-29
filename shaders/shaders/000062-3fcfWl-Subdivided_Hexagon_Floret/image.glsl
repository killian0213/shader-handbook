// Image (image) — Subdivided Hexagon Floret by Shane
// https://www.shadertoy.com/view/3fcfWl

/*

    Subdivided Hexagon Floret
    -------------------------
    
    Subdividing a standard hexagon floret pattern into something
    resembling a subdivided snub hexagon pattern, then traversing it.
    
    I was using the pattern to play around with material properties and 
    colors, so there's nothing particularly exciting about it. In fact, 
    I've posted similar patterns before. However, I wanted to post it 
    anyway. The code is a little drawn out, but none of it is difficult.
    
    There are so many different ways to produce a floret pattern, but all
    involve constucting a hexagon grid, then placing six pentagon petals
    around the cell center in such a way that it connects up to those of 
    its hexagon cell neighbors. The code is fast enough on my machine, 
    but I know of ways to make it faster, so I'll do that at some stage.
    
    For a scene like this, you need to include a bunch of things, like
    AO, shadows, BRDF, and so forth, which adds to the code footprint. 
    I wanted to code up the noise as well, so that also added to the 
    size. Either way, none of it is difficult, or lengthy by itself, but 
    it adds to the character count.
    
    There are some defines to try out in the "Common" tab, for anyone
    interested.
    


    Other examples:
    
    // This shows the relationship between snub hexagon 
    // tessellation and hexagon florets. MLA takes a reflection
    // approach to this one, but there are so many different
    // methods possible.
    //
    Snub Hexagonal Tiling  -- MLA
    https://www.shadertoy.com/view/3tKXzy
    // Based on Fizzer's example, here:
    Wythoff Uniform Tilings +Duals - Fizzer
    https://www.shadertoy.com/view/3tyXWw
    
    // A pentagonal (or icosahedral) based 
    // floret pattern.
    Pentagonal Hexecontahedron-02 -- shadertoyjiang 
    https://www.shadertoy.com/view/wcdBRn
    
*/
 

/////////////////

#define FAR 10.
#define ZERO min(0, iFrame)

//////////////////


// Height map value.
float hm(in vec2 p){  
    
    //return hash21F(p);
    p *= 2.;
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


// Object distances.
vec4 vObj;
// Saving values for later use.
vec4 gVal; 


// Global cell boundary distance variables.
vec3 gDir; // Cell traversing direction.
vec3 gRd; // Ray direction.
float gCD; // Cell boundary distance.


float map(vec3 p){

    // Floor.
    float fl = -p.z + .25;
    
    // Direction ray.
    svRd = gRd;
    
    // Tiling function.
    vec4 d4 = distField(p.xy);
    
  
    
    // Creating a tiny space between tiles to avoid artifacts.
    d4.x += .0025;
    
    // Extruded polygon height.
    float h = hm(d4.yz*4.);
    h *= .5;
    
    // Saved values, for later use.
    gVal = vec4(d4.xyz, h);
    
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
 
 
    // Extrusion.
    float d3 = max(abs(p.z + h/2. - .25) - h/2. - .25, d4.x);
    //d3 += d4.x/gSc*.05; // Raised tops.
    d3 += max(d4.x, -.05*gSc)*.25;
    
    // Saving the extruded object and floor.
    vObj = vec4(d3, fl, 1e5, 1e5);
    
    // Closest scene object.
    return min(d3, fl);


}


// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    //
    // IQ's suggestion: Moving the ray's jump-off point closer to the 
    // surface plane to gain some extra speed, especially when in 
    // fullscreen mode.
    float t = (-.5 - ro.z)/rd.z, d;
     
    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = step(0., rd) - .5;
    gRd = rd; 
    
    for(int i = min(0, iFrame); i<96; i++){
    
        d = map(ro + rd*t); // Surface distance.
        
        // Break, if we're close enough, or have gone too far.
        if(abs(d)<.001 || t>FAR) break; 
        
        // Restricting the minimum jump to the cell boundary distance.
        t += min(d*.7, gCD); 
    }

    return min(t, FAR);
}



// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with 
// limited iterations is impossible... However, I'd be very grateful if someone could 
// prove me wrong. :)
float softShadow(vec3 ro, vec3 rd, vec3 n, float lDist, float k){

    
    // IQ's suggestion: It's equivalent to moving the ray closer to the
    // surface plane, in order to gain some extra speed.
    lDist = (-.5 - ro.z)/rd.z;
   
    // Coincides with the hit condition in the "trace" function. 
    ro += n*.0015;
    
    // I've added in a touch of jittering to alleviate banding.
    ro += rd*hash21(ro.xy + ro.yz + n.xz)*.01;

    float shade = 1.;
    float t = 0.; 

    
    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = step(0., rd) - .5;
    gRd = rd;            

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. 
    // Obviously, the lowest number to give a decent shadow is the best one to choose. 
    for (int i = min(0, iFrame); i<32; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        // shade = min(shade, smoothstep(0., 1., k*d/t)); // Thanks to IQ for this tidbit.
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>lDist) break; 
        
        
        // So many options here, and none are perfect: 
        // dist += clamp(d, .01, stepDist), etc.
        t += clamp(min(d, gCD), .01, .2);       
        
    }

    // Shadow.
    return max(shade, 0.); 
}




// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 normal(in vec3 p) {
	
    //return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy),	
    //                      m(p + e.yyx) - m(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    vec3 e = vec3(.001, 0, 0), mp = e.zzz; // Spalmer's clever zeroing.
    for(int i = min(0, iFrame); i<6; i++){
		mp.x += map(p + sgn*e)*sgn;
        sgn = -sgn;
        if((i&1)==1){ mp = mp.yzx; e = e.zxy; }
    }
    
    return normalize(mp);
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
    
        float hr = .003 + float(i)*.2/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
    }
    
    return clamp(1. - occ, 0., 1.);  
}


// Cheesy 3D environmental texture -- I really need to put more
// effort into these.
vec3 envTex(vec3 p){
    
    // Scaling and translation.
    p *= 2.;
    p.z -= iTime/8.;
    // Noise layers.
    float ns = gradN3D(p)*.57 + gradN3D(p*3.)*.28 + gradN3D(p*9.)*.15;
    ns = smoothstep(.3, .45, ns); // Color ramp.
    vec3 refTx = pow(vec3(ns), vec3(1, 2, 4));  // Coloring.
    return mix(refTx.zyx, refTx, smoothstep(.3, .7, gradN3D(p*2.5))); // Mixing.
    
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    // Aspect corret coordinates.
    vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    // Mild screen warping.
    //uv *= .95 + dot(uv, uv)*.1;
 
    
     
    // PATTERN CONSTRUCTION.
 
    
    // Scene field calculations.
 
    // Unit ray and ray origin.
    vec3 rd = normalize(vec3(uv, 1));
    vec3 ro = vec3(0, 0, -1.5);
    
    // Rotation and translation.
    rd.xy *= rot2(sin(iTime/8.)*PI/2.);
    ro.xy += vec2(cos(iTime/16.)*2., sin(iTime/8.))*2.;
    
    
    // Two lights and light colors.
    mat2x3 lp = mat2x3(vec3(.5, .75, -1.25), 
                       vec3(-1, -.5, -1.25));
    mat2x3 lCol = mat2x3(vec3(1, .97, .92), vec3(.92, .97, 1));
    
    // Move the lights around their origins in an elliptic figure 8 manner. 
    lp[0].xy += vec2(cos(iTime/16.)*2., sin(iTime/8.))*2.;
    lp[1].xy += vec2(cos(iTime/16.)*2., sin(iTime/8.))*2.;
    
 
    // Trace the scene.
    float t = trace(ro, rd);
    
    // Object cell ID, 2D cell distance and vertex number.
    vec2 id = gVal.yz;
    float d = gVal.x;
    float h = gVal.w;
    int svPID = pID;
    
//    vec2 svID0 = gID0; // Octagon and square ID.
    
    // Object ID: Extruded object or mirrored floor. 
    int objID = vObj.x<vObj.y? 0 : 1;
    
    // Scene surface position and normal.
    vec3 sp = ro + t*rd;
    vec3 n = normal(sp);
    
    // Ambient occlusion.
    float ao = calcAO(sp, n);

    
    // Surface object coloring.
    float rnd = hash21(id + .019);
    #if COLOR_SCHEME == 0
    // Range and saturation. Normally constants.
    float range = hash21(id + .011); // 0 to 1.
    float satur = 1.;// hash21(id + .031)*.75 + .25; // 0 to 1.
    vec3 sCol = .5 + .45*cos(TAU*range*(rnd - 1./12.)/3. + vec3(0, 1.57, 3.14)*satur);
    vec3 sCol2 = .5 + .45*cos(TAU*range*(rnd + 1./12.)/3. + vec3(0, 1.57, 3.14)*satur);
    #else
    vec3 sCol = paintPalette(rnd/1. + 0./12.);
    vec3 sCol2 = paintPalette((rnd/1. + 1./12.) + 0./12.);
    #endif
    
    // Ordering the gradient colors in terms of luminosity. Basically, we want
    // the gradients to go from light in the center to dark on the edges.
    if(dot(sCol2 - sCol, vec3(.299, .587, .114))<0.){
       vec3 tmp = sCol; sCol = sCol2; sCol2 = tmp;
    }
    vec3 pCol = mix(sCol2, sCol, length(gP)/gSc*3.);
    
    // Greyscale.
    //float gr = dot(pCol, vec3(.299, .587, .114));
    //pCol = vec3(gr*.5);
     
    
    // Metallic material. Randomly give some of the 
    // objects a grey color to tone things down.
    if(MATERIAL==1){
       //pCol = vec3(rnd*.15 + .15);
       //if(hash21(id + .31)<.5) pCol *= vec3(1.6, 1.2, .6);
       
       if(hash21(id + .31)<.5) pCol = vec3(rnd*.15 + .15);
    }
    
      
     // Material surface noise.
    float ns = fBm(sp*64., 2., .5, 4);
    float ns2 = fBm(sp*256., 2., .5, 4);
    
    // Applying noise to the surface.
    if(MATERIAL==1) pCol *= ns2 + .25;
    else pCol *= ns2*.4 + .8;
 
    
    // Dark edge coloring.
    float rw = .004;
    float edge = abs(d) - rw;
    edge = max(edge, sp.z + h - rw/2.);
    pCol = mix(pCol, pCol*.2, 1. - smoothstep(0., .003, edge));//
    
    pCol = mix(pCol, pCol.yzx, 1. - smoothstep(0., .003, -(sp.z + h - rw/2.)));//
    
     
    // Material properties.
    float type = ns2*.1;
    float rough = ns*.4 + .1;
    float fresRef = .75;
    if(MATERIAL==1) type = ns2*.5 + .5;
  

    
    // Surface color.
    vec3 col = vec3(0);
    
    // Iterate through the two lights.
    for(int i = 0; i<1; i++){
        
        // Point light.
        vec3 ld = lp[i] - sp;
        float lDist = length(ld);
        ld /= max(lDist, 1e-5);
        // Attenuation.
        float atten = 1./(1. + lDist*.25);
        
        
        float sh = softShadow(sp, ld, n, lDist, 16.);

       
        // Backscatter.
        float bac = clamp(dot(n, -normalize(vec3(ld.xy, 0))), 0., 1.);
        pCol += pCol*vec3(1, .3, .1)*bac*bac*8.;
       
        // Standard BRDF dot product calculations.
        vec3 h = normalize(ld - rd); // Half vector.
        float ndl = dot(n, ld);
        float nr = clamp(dot(n, -rd), 0., 1.); // Leaving it here.
        float nl = clamp(ndl, 0., 1.);
        float nh = clamp(dot(n, h), 0., 1.);
        float vh = clamp(dot(-rd, h), 0., 1.); 
        // Fresnel related.
        vec3 f0 = vec3(.16*(fresRef*fresRef)); 
        // For metals, the base color is used for F0.
        f0 = mix(f0, pCol, type);
        vec3 FS = f0 + (1. - f0)*pow(1. - vh, 5.); // Fresnel-Schlick reflected light term.

        // BRDF style specular and diffuse calculations. There is so little
        // extra work involved, but the lighting quality is much better.
        vec3 spec = getSpec(FS, nh, nr, nl, rough);
        vec3 diff = getDiff(FS, nl, type);
        float specR = pow(nh, 5.);
        
        // Anisotropy. Cool, but not for this examples.
        //float aniso = length(sin(diff*TAU*3.)*.5 + .5)/sqrt(3.);
        //float aniso = sin(dot(diff, vec3(.299, .587, .114))*TAU*3.)*.5 + .5;
        float aniso = sin(nh*TAU*3.)*.5 + .5;
        if(MATERIAL==1) pCol *= aniso + .25;
  
 
        // Scene color.
        col += pCol*(.5*(sh*.25 + .75) + diff*sh + spec*sh*4.)*lCol[i]*atten*ao;
        
        // Faux environment mapping.
        vec3 refTx = envTex(reflect(rd, n));
        if(MATERIAL==1) col = col + col*specR*refTx*4.;
        else col = col + (col*specR*refTx);
        
        // Alternative Shadertoy Forest cube map version.
        //vec3 rrd = rd;
        //rrd.yz *= rot2(PI/3.); 
        //vec3 refTx = texture(iChannel0, reflect(rrd, n)).xyz; refTx *= refTx;
    
     }
     
 
     
     // Very subtle Reinhard-based high frequency tone mapping.
     col /= (3.5 + col)/4.;
     // Sigmoid tone mapping: There are a few, but XOR popularized this one.
     //col = tanh(col*1.2);
     

     // Output to screen.
     fragColor = vec4(sqrt(max(col, 0.)), 1);
}