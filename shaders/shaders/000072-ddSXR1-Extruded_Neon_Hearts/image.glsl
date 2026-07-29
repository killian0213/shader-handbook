// Image (image) — Extruded Neon Hearts by Shane
// https://www.shadertoy.com/view/ddSXR1

/*

    Extruded Neon Hearts
    --------------------
    
    This is an extruded version of a reasonably popular geometric heart pattern that has
    been constructed and rendered in realtime. It's a simple variation on a common pentagon 
    floret arrangement, which is technically known for being the dual of a 3,3,3,3,6 snub 
    trihexagonal semi-regular tessellation of the grid... It's a fancy sounding description, 
    but the imagery is pretty basic, if you're not sure and feel like looking it up. :)
    
    Extruded square grids are a modern computer image cliche. You'll see them everywhere,
    especially in stock imagery. Hexagon grids are less common, and triangle grids are 
    less common still, but there are still plenty around. There are a lot of varations as 
    well, like subdivided grids, offset grids to a lesser degree and so forth.
    
    After looking around the internet, I noticed that people don't stray much from these 
    base extrusion patterns. Semi-regular grid patterns and their duals are reasonably 
    common in the 2D realm, but you rarely see extruded versions, if at all, so a while 
    back I decided to make some. Obviously, more complicated patterns require more
    calculation, and that can be exacerbated in a realtime pixelshader environment, but 
    I've seen people on here code harder stuff, so I'm surprised that there are no examples
    on here at all.
    
    There are a number of ways to construct these patterns, and I'm not sure what would
    be the most efficient, but I've tried my best. The objective for the time being was to 
    get a few extruded semi-regular patterns on the board with the hope that better methods 
    for their construction will be devised later. By the way, a raymarched traversal is a
    lot faster, and I intend to code one of those up later. 
    
    By the way, there a couple of defines to change the pattern shape and glow color, for
    anyone interested.


    
    Related examples:
    
    // I like this example, since it's a simple 2D semi-regular tiling 
    // visual reference. The floret pattern is contained in it somewhere.
    Wythoff Uniform Tilings + Duals - Fizzer 
    https://www.shadertoy.com/view/3tyXWw
    
    // A Wythoff\Kaspar-Klug based approach to semi-regular patterns, etc. It's
    // a nice looking shader. Remaindeer has a really cool extruded boundary 
    // version on here too, if you feel like looking that up. Although, that
    // shouldn't be confused with the kind of extrusion I'm performing here, which
    // requires neighboring cell considerations.
    caspar-klug sdf - remaindeer
    https://www.shadertoy.com/view/cdsSDS
    
    // The following is mildly related believe it or not.
    Extruded Hexagon Fractal Curve - Shane
    https://www.shadertoy.com/view/cdjGWy
    
*/


// Glow color - Red: 0, Blue: 1, Green: 2
#define COLOR 1

// Extruded shape. Just the two. The floret is a little slow at the moment,
// but I'll put some effort in later to make it faster.
//
// Heart: 0, Floret 1.
#define SHAPE 0



#define ZERO min(iFrame, 0)

// Global tile scale.
const float scale = 1./2.;

// Max ray distance.
#define FAR 20.


// Scene object ID.
float objID;


// Tri-Planar blending function. Based on an old Nvidia tutorial by Ryan Geiss.
vec3 tex3D(sampler2D t, in vec3 p, in vec3 n){ 
    
    n = max(abs(n) - .2, .001); // max(abs(n), 0.001), etc.
    //n /= dot(n, vec3(.8)); 
    n /= length(n);
    
    // Texure samples. One for each plane.
    vec3 tx = texture(t, p.yz).xyz;
    vec3 ty = texture(t, p.zx).xyz;
    vec3 tz = texture(t, p.xy).xyz;
    
    // Multiply each texture plane by its normal dominance factor.... or however you wish
    // to describe it. For instance, if the normal faces up or down, the "ty" texture sample,
    // represnting the XZ plane, will be used, which makes sense.
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return mat3(tx*tx, ty*ty, tz*tz)*n; // Equivalent to: tx*tx*n.x + ty*ty*n.y + tz*tz*n.z;

}

vec3 getCol(sampler2D s2D, vec2 p){
 
    //p *= vec2(iResolution.y/iResolution.x, 1);
    vec3 tx = texture(s2D, p*scale/16.*s).xyz; 
    return tx*tx;

    //float rnd = hash21(p);
    //return .5 + .45*cos(6.2831*rnd + vec3(0, 1, 2)*1.5);
}

float ht;
float getHeight(vec2 p){

    vec3 col = getCol(iChannel0, p);
    if(fract(dot(col, vec3(1))*143.5273)<.2) return -1.;
    float h = dot(col, vec3(.299, .587, .114));
    ht = smoothstep(.9, .94, sin(6.2831*h*4. + iTime));
    return h*.25*(1. + ht) + .025; 
}


// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h){
    
    vec2 w = vec2( sdf, abs(pz) - h );
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.));

    /*
    // Slight rounding. A little nicer, but slower.
    const float sf = .015;
    vec2 w = vec2( sdf, abs(pz) - h - sf/2.);
  	return min(max(w.x, w.y), 0.) + length(max(w + sf, 0.)) - sf;
    */
}





vec4 gVal; // Global container for 2D distance, etc.
vec3 glow, lCol; // Global glow and glow color variables.


// The extruded image.
float map(vec3 p){

    
    
    // Floor.
    float fl = abs(p.z - .5) - .5;

    
    float gridScale = scale;
    
    // Hexagonal grid coordinates.
    vec4 p4 = getGrid(p.xy/gridScale);
        
    // Rendering the grid boundaries, or just some black hexagons in the center.
    float gHx = getHex(p4.xy, .5, 0.);
    
 
    
    const vec2 sDiv12 = s/12.;
    
    
    const float ew = .0; // Edge width.
    const float ang = atan(sqrt(3.)/5.); // Rotation angle.
    const float invR = 1./sqrt(7.); // Scaling factor.
    vec2 q = p4.xy;
    
    // Rotate the coordinates in the hexagon grid.
    q = rot2(ang)*q;
    float hR = 1.5*invR;
    float ctrHx = getHex(q, hR, 0.);
    
    
    // Triangle radius.
    float tR = hR/.8660254;
    float ctrTri = getTri(rot2(3.14159/6.)*q, tR);
    ctrTri = min(ctrTri, getTri(rot2(-3.14159/6.)*q, tR));
    ctrTri = max(ctrTri, ctrHx);
    
    // Edge construction lines and shape distance holder.
    float[6] flLn, flLn2, d6;
    
    
    // Iterate through all six sides of the hexagon cell and create
    // some edge construction lines.
    for(int i = 0; i<6; i++){
       vec2 vi = vID[i]*sDiv12;
       // Short for the following:
       //flLn[i] = distLineS(q, vec2(0), vi);
       flLn[i] = dot(q, vec2(-vi.y, vi.x)*sqrt(3.));
    }
    
    #if SHAPE == 0
    int j = int(mod(floor(hash21(p4.zw)*36.), 2.));
    #endif
    
 
    vec2[6] cID6;
    #if SHAPE == 0
    for(int i = ZERO; i<6; i+=2){
    #else
    for(int i = ZERO; i<6; i++){
    #endif
    
        
        #if SHAPE == 0
        int ip0 = (i + j)%6;
        int ip1 = (i + 2 + j)%6;
        #else
        int ip0 = i;
        int ip1 = (i + 1)%6;
        #endif
        
        // The 2D field for this particular shape.
        d6[i] = (max(ctrTri, max(flLn[ip0], -flLn[ip1])) + ew)*gridScale;
        // The ID.
        cID6[i] = p4.zw + eID[i]*invR*2.;
         
    }
    
    /*
    // It'd be nice to use polar partitioning to cut down on GPU costs, but,
    // unfortunately, there are overlap issues. I might try again later.
    float naB;
    vec2 qB = rot2(-3.14159/6.)*q;
    qB = polRot(qB, naB, 6.);
    int indB = int(mod(8. - naB, 6.));
    float hi = getHeight(cID6[indB]);
    */
    
    float svHt = -1e5;

    float df = 1e5;
    #if SHAPE == 0
    for(int i = ZERO; i<6; i+=2){
    #else
    for(int i = ZERO; i<6; i++){
    #endif        
 
        // Extruding the 2D field.
        float hi = getHeight(cID6[i]);//dot(dCol, vec3(.299, .587, .114))*.2;//.2;
        float di = opExtrusion(d6[i], p.z + hi/2., hi/2.);
        // Extra face height to reflect light a bit better.
        di += d6[i]*.125;
        // Face rippling.
        //di += (smoothstep(0., .5, sin(d6[i]*124. - 1.57/2.*0.)*.5 + .5) - .5)*.005;
        
        // Minimum distance.
        if(di<df){
        
            df = di;
            gVal = vec4(d6[i], hi, cID6[i]);
            svHt = ht;
        }
    }
    
    /////
        
    // Some of the neighboring florets (or heart tips) encroach into this cell, so we 
    // need to construct those too. We only need the tips of the objects, which are
    // hexagonal in shape, so those will do.
    float na;
    q = polRot(q, na, 6.);
    q.x -= tR;
    q *= rot2(3.14159/6.);
    float smHx = getHex(q, invR/2. - ew, 0.); // Triangle.
    smHx *= gridScale;
    
    int ind = int(mod(8. - na, 6.));
    
    
    // Add the neighbors.
    #if SHAPE == 0
    // Check to see whether the neighbor has been rotated, and if so
    // offset the index to match.
    int jn = int(mod(floor(hash21(p4.zw + eID[ind]*2.)*36.), 2.));
    int ind2 = int(mod(7. - floor((na + float(jn))/2.)*2., 6.));
    vec2 smHxID = p4.zw + eID[(ind)%6]*2. - eID[(ind2)%6]*invR*2.;
    #else
    vec2 smHxID = p4.zw + eID[ind]*(1. - invR)*2.; // See above.
    #endif
    
    float hgt = getHeight(smHxID);
    float dB = opExtrusion(smHx, p.z + hgt/2., hgt/2.);
    dB += smHx*.125;
    //dB += (smoothstep(0., .5, sin(smHx*80. - 1.57/2.*0.)*.5 + .5) - .5)*.003;
         
    // Update.
    if(dB<df){
        df = dB;
        gVal = vec4(smHx, hgt, smHxID);
        svHt = ht;
    }
    
    
    // Overall object ID.
    objID = fl<df? 1. : 0.;
 
    // Glow color beam calculations.
    lCol = vec3(0);
    if(df<.25 && objID<.5){
       vec3 gCol = mix(vec3(1, .1, .3), vec3(1., .3, .1), hash21(gVal.zw + .12));
       lCol = svHt*gCol*smoothstep(0., .5, -(gVal.x));
    }
   
    
    
    // Combining the floor with the extruded object.
    return  min(fl, df);
 
}

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    // Adding some jitter to the jump off point to alleviate banding.
    float t = hash31(fract(ro/7.319) + rd)*.1, d;
    
    glow = vec3(0);
    
    for(int i = ZERO; i<96; i++){
    
        d = map(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(d)<.001 || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.
        
        //t += d*.7;//d<.5? d*.5 : d*.9; 
        
        // Accumulate the glow color.
        glow += lCol;///(1. + t);
        
        // Note that the ray is capped (to .1). It's slower, but is necessary for the
        // glow to work. I guess it could also help with overstepping the mark a bit.
        t += min(d*.7, .1); 
    }

    return min(t, FAR);
}


// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p, float t) {
	
    //const vec2 e = vec2(.001, 0);
    //return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy),	
    //                      m(p + e.yyx) - m(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    vec3 e = vec3(.004, 0, 0), mp = e.zzz; // Spalmer's clever zeroing.
    for(int i = min(iFrame, 0); i<6; i++){
		mp.x += map(p + sgn*e)*sgn;
        sgn = -sgn;
        if((i&1)==1){ mp = mp.yzx; e = e.zxy; }
    }
    
    return normalize(mp);
}


// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with limited 
// iterations is impossible... However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not always affordable. :)
    const int maxIterationsShad = 32; 
    
    ro += n*.0015; // Coincides with the hit condition in the "trace" function.  
    vec3 rd = lp - ro; // Unnormalized direction ray.

    float shade = 1.;
    float t = 0.; 
    float end = max(length(rd), .0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, 
    // the lowest number to give a decent shadow is the best one to choose. 
    for (int i = min(iFrame, 0); i<maxIterationsShad; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*d/t)); // Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += clamp(d, .01, stepDist), etc.
        t += clamp(d, .005, .1); 
        
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>end) break; 
    }

    // Sometimes, I'll add a constant to the final shade value, which lightens the shadow a bit --
    // It's a preference thing. Really dark shadows look too brutal to me. Sometimes, I'll add 
    // AO also just for kicks. :)
    return max(shade, 0.); 
}


// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n){

	float sca = 3., occ = 0.;
    for( int i = 0; i<5; i++ ){
    
        float hr = float(i + 1)*.15/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
    }
    
    return clamp(1. - occ, 0., 1.);  
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    
    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;

    
	// Camera Setup.
    vec3 ro = vec3(cos(iTime/4.)*.15, sin(iTime/4.)*.15 + iTime/8., -1.5); // Camera position.
	vec3 lk = vec3(0, iTime/8. + .6, 0);//vec3(0, -.25, iTime);  // "Look At" position.
 
    // Light positioning. One is just in front of the camera, and the other is in front of that.
 	vec3 lp = lk + vec3(-.5, 1.5, -1);// Put it a bit in front of the camera.
	

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
    float svObjID = objID;
    
    vec4 svVal = gVal;
  
	
    // Initiate the scene color to black.
	vec3 col = vec3(0);
	
	// The ray has effectively hit the surface, so light it up.
	if(t < FAR){
        
  	
    	// Surface position and surface normal.
	    vec3 sp = ro + rd*t;
        vec3 sn = getNormal(sp, t);
        
            	// Light direction vector.
	    vec3 ld = lp - sp;

        // Distance from respective light to the surface point.
	    float lDist = max(length(ld), .001);
    	
    	// Normalize the light direction vector.
	    ld /= lDist;

        
        
        // Shadows and ambient self shadowing.
    	float sh = softShadow(sp, lp, sn, 16.);
    	float ao = calcAO(sp, sn); // Ambient occlusion.
        //sh = min(sh + ao*.25, 1.);
	    
	    // Light attenuation, based on the distances above.
	    float atten = 1./(1. + lDist*.05);

    	
    	// Diffuse lighting.
	    float diff = max( dot(sn, ld), 0.);
        //diff = pow(diff, 4.)*2.; // Ramping up the diffuse.
    	
    	// Specular lighting.
	    float spec = pow(max(dot(reflect(ld, sn), rd ), 0.), 32.); 
	    
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
        if(svObjID<.5){
            
             // Light edge.
            float d = svVal.x; // 2D face distance.
            float h = svVal.y; // Object height.
            float dz = txP.z + h; // Heigh cutoff.
            
            // Face color.
            vec3 fCol = getCol(iChannel0, svVal.zw/1.);
            fCol = vec3(1.35)*(dot(fCol, vec3(.299, .587, .114)) + .25);
      
          
            // Tri-planar texture lookup.
            vec3 tx = tex3D(iChannel1, sp - vec3(0, 0, -h), sn);
           
           
            // Matches the glow color in the distance function.
            vec3 hCol = mix(vec3(1, .1, .3), vec3(1., .3, .1), hash21(svVal.zw + .12));
            // Blending the glow portion from timber to metallic when it's glowing.
            vec3 tx2 = mix(tx*vec3(.8, 1, 1.2)*(hCol*.5 + 1.25), tx, min(glow.x*2., 1.));
            
            // Rendering face colors and borders.
            vec3 sideCol = vec3(.35);
            texCol = mix(sideCol, vec3(0), 1. - smoothstep(0., sf, dz - ew));
            texCol = mix(texCol, sideCol, 1. - smoothstep(0., sf, d + ew));//*vec3(1.4, 1, .5)
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, d + .04));
            texCol = mix(texCol*(tx*2. + .05), fCol*(tx2*2. + .05), 1. - smoothstep(0., sf, d + .04 + ew*2.));
            
             // Ramp up the diffuse value for a more metallic look.
            //diff = pow(diff, 4.)*2.;
           
 
        }
        else {
            
            // The floor.
            
            // Background.
            texCol = vec3(.7);
            
             // Tri-planar texture lookup.
            vec3 tx = tex3D(iChannel1, sp, sn);
           
            // Combine for the final surface color.
            texCol *= tx + .05;//*vec3(1.2, 1, .8);
            
            //texCol *= vec3(1.2, 1, .8);
            
            // Ground rim.
            float d = abs(svVal.x) - ew*1.5;
            if(svVal.y>0.) texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, d)); 
          
        }
        
        
        // Specular reflection.
        vec3 hv = normalize(-rd + ld); // Half vector.
        vec3 ref = reflect(rd, sn); // Surface reflection.
        vec3 refTx = texture(iChannel2, ref).xyz; refTx *= refTx;
        refTx = (texCol*1.5 + .66)*refTx;//smoothstep(.2, .5, refTx);
        float spRef = pow(max(dot(hv, sn), 0.), 8.); // Specular reflection.
        float rf = (svObjID == 1.)? .25 : 1.;//mix(.5, 1., 1. - smoothstep(0., .01, d + .08));
        texCol += spRef*refTx*rf*1.; //smoothstep(.03, 1., spRef) 

        //texCol = texCol + vec3(4, .5, 1)*texCol*glow*4.;
       
        
        // Combining the above terms to produce the final color.
        col = texCol*(diff*sh + .3 + vec3(1, .97, .92)*spec*freS*2.*sh);
        
        // Apply the glow color.
        #if COLOR == 0
        col = col/2. + col*glow*36.;
        #elif COLOR == 1
        col *= vec3(1.1, 1, .9);   
        col = col/2. + col*glow.zyx/vec3(1.1, 1, .9)*40.;
        #else
        col *= vec3(1.2, 1, .8);   
        col = col/2. + col*glow.yxz/vec3(1.2, 1, .8)*32.;
        #endif
        
        // Shading.
        col *= ao*atten;
        
        // It's sometimes helpful to check things like shadows and AO by themselves.
        //col = vec3(ao);
          
	
	}
    
    // Horizon fog. Not visible here, but provided for completeness.
    col = mix(col, vec3(0), smoothstep(0., .99, t/FAR));
          
    
    // Rought gamma correction.
	fragColor = vec4(sqrt(max(col, 0.)), 1);
	
}