// Image (image) — Hexagonal Prism Flip by Shane
// https://www.shadertoy.com/view/ftyGWD

/*

    Hexagonal Prism Flip
    --------------------

	Flipping boxes and so forth from their standing cell position within
    a grid is a video loop standard. There are infinite variations, and 
    this is one of the simpler ones.
    
    Other than a bit of basic physics in the form of vector and matrix 
    manipulation, there's not a lot to it: Start off with an extruded grid
    of objects of some kind, animate the individual cell heights and 
    rotate... That can get a bit fiddly, but it's not too bad.
    
    Not a lot of effort was put into this. I used a recent extruded grid 
    shader as a template, manipulated the height routine, then colored the 
    objects a little. I kept the rendering style simple. 
    


	Physics shaders:
    
	// If you search "physics" on Shadertoy, Dr2's name will feature
    // a lot. Here's a fun motion and collision example.
    Rolling Stones - Dr2 
	https://www.shadertoy.com/view/MdsfD7
    
    // I love this.
    Loop Ramp - glk7 
    https://www.shadertoy.com/view/wtfXD4
    
    // A bouncing motion example with a really elegant solution.
    Bouncing Balls Example - blackle
    https://www.shadertoy.com/view/sss3W8


*/


// Global tile scale.
vec2 scale = vec2(1./5., 1./5.);

// Off the rows by half a cell to produce a brickwork feel. The staggered 
// effect can also make a quantized image look smoother.
#define ROW_OFFSET

// Use hexagon pylons instead of squares.
#define HEXAGON

// Boring out holes on alternate blocks to give it more of a tech feel and
// to provide a little extra visual stimuli. Without the holes, the image
// looks cleaner, but less interesting, I feel.
#define HOLES

// Raising the faces of the pylon tops. I find it can help bounce the light 
// off the surface in a more reflective way.
//#define RAISED

// Putting a ridge decoraction on the pylon tops.        
#define RIDGES


// The hexagons must use offset rows.
#ifdef HEXAGON
#ifndef ROW_OFFSET
#define ROW_OFFSET
#endif
#endif

// Max ray distance.
#define FAR 20.



// Scene object ID to separate the mesh object from the terrain.
float objID;


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }



float hash21(vec2 p){  
    
    // Attempting to fix accuracy problems on some systems by using
    // a slight variation on Dave Hoskin's hash formula, here:
    // https://www.shadertoy.com/view/4djSRW
    vec3 p3 = fract(vec3(p.xyx)*.1031);
    p3 += dot(p3, p3.yzx + 43.123);
    return fract((p3.x + p3.y)*p3.z);
    
    //p = fract(p*2.014371)*128. - vec2(63.537567, 64.484713);
    //return fract(dot(p.xyx*p.xyy, vec3(128.390654, 128.713193, 2.1396217)));
    
    // IQ's vec2 to float hash.
    //return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); 
}


// Height map value. A keyframe time variable is also passed in for usage
// inside the block function.
float hm(in vec2 p, inout float tm){ 

    
    // Unique random number for this grid cell.
    float rnd = hash21(p + .13);
     
    // Time variable: Manipulated to periodically fit into transcendental functions.
    // Modulo 8, in this case, means 8 keyframes. The random variable ensures that
    // the cell object moves at random times compared to its neighbors.
    tm = mod(rnd*8. + iTime*4./6.2831, 8.);
    
    // Keep the time variable (and as such, height) static for all but the first keyframe.
    tm = (tm<1.)? tm : 0.;

    // A cheap function to create an undulating wave below the flipping object.
    //p *= 2.;
    float waveHeight = dot(sin(p*1.4 - cos(p.yx*2.2 + mod(iTime, 6.2831))*2.), vec2(.25)) + .5;

    // Object height. Just a periodic function that goes up and down within
    // the first keyframe and remains at zero height for the other keyframes.
    float h = .5 - cos(tm*6.2831)*.5;
    
    // The total height is a mixture of the wave and periodic up-down function.
    // It's range is roughly zero to one, but not quite.
    return (h/4. + .25)*waveHeight + h;
    
    
}


// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h){
    
    vec2 w = vec2(sdf, abs(pz) - h);
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.));

}

/*
// IQ's extrusion formula with smoothing.
float opExtrusionS(in float sdf, in float pz, in float h, in float sf){
   
    // Slight rounding. A little nicer, but slower.
    vec2 w = vec2(sdf, abs(pz) - h) + sf;
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.)) - sf;
    
}
*/

#ifdef HEXAGON
// Signed distance to a regular hexagon, with a hacky smoothing variable thrown
// in. -- It's based off of IQ's more exact pentagon method.
float sHexS(in vec2 p, float r, in float sf){
    
      // Flat top.
      //const vec3 k = vec3(-.8660254, .5, .57735); // pi/6: cos, sin, tan.
      // Pointed top.
      const vec3 k = vec3(.5, -.8660254, .57735); // pi/6: cos, sin, tan.
     
      // X and Y reflection.  
      p = abs(p); 
      p -= 2.*min(dot(k.xy, p), 0.)*k.xy;

      r -= sf;
      // Polygon side.
      // Flat top.
      //return length(p - vec2(clamp(p.x, -k.z*r, k.z*r), r))*sign(p.y - r) - sf;
      // Pointed top.
      return length(p - vec2(r, clamp(p.y, -k.z*r, k.z*r)))*sign(p.x - r) - sf;
    
}
#endif

/*
// IQ's unsigned box formula.
float sBoxS(in vec2 p, in vec2 b, in float sf){

  return length(max(abs(p) - b + sf, 0.)) - sf;
}
*/

// IQ's signed box formula.
float sBoxS(in vec2 p, in vec2 b, in float sf){

  vec2 d = abs(p) - b + sf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - sf;
}

// Hack to obtain a couple of the static ground shape to create
// the floor honeycomb.
float shape;

// A regular extruded block grid.
//
// The idea is very simple: Produce a normal grid full of packed square pylons.
// That is, use the grid cell's center pixel to obtain a height value (read in
// from a height map), then render a pylon at that height.

vec4 blocks(vec3 q3){
    
    

    // Brick dimension: Length to height ratio with additional scaling.
    vec2 l = scale;
	vec2 s = scale*2.;
    #ifdef HEXAGON
    vec2 hSc = vec2(1, scale.y/scale.x*2./1.732);
    #endif
    
    float minSc = min(scale.x, scale.y);
    
    
    // Distance.
    float d = 1e5;
    // Cell center, local coordinates and overall cell ID.
    vec2 p, ip;
    
    // Individual brick ID.
    vec2 id = vec2(0); 
    
    // Four block corner postions.
    #ifdef ROW_OFFSET
    // Offset rows.
    vec2[4] ps4 = vec2[4](vec2(-.25, .25), vec2(.25), vec2(.5, -.25), vec2(0, -.25)); 
    #else
    vec2[4] ps4 = vec2[4](vec2(-.25, .25), vec2(.25), vec2(.25, -.25), vec2(-.25)); 
    #endif
    
    float data = 0.; // Extra data.
    
    shape = 1e5;
    
    for(int i = min(0, iFrame); i<4; i++){


        // Local coordinates.
        p = q3.xy;
        ip = floor(p/s - ps4[i]) + .5; // Local tile ID.
        
        // Correct positional individual tile ID.
        vec2 idi = (ip + ps4[i])*s;
        
        p -= idi; // New local position.


        // The extruded block height. See the height map function, above.
        
        /// Keyframe time variable.
        float tm;

        float h = hm(idi, tm);
        
        // Flip direction.
        float dir = (hash21(idi +.07)<.5)? 1. : -1.;
        // Randomly doubling the flip magnitude... Number of airborn flips.
        dir *= (hash21(idi +.05)<.5)? 2. : 1.;
        
        // It's necessary to let the object clear the ground before rotating, and 
        // for it to finish its rotation upon arrival, so a delay in the rotation 
        // process is necessary. How you arrange that is up to you, but this is how
        // I did it. It works, but I feel there'd be more elegant solutions.
        float delay = .175; // Spinning delay - Range: [0, 1].
        const float totRot = 3.14159; // Total rotation.
        mat2 cR = (abs(tm - .5)<.5 - delay)? 
                   rot2(dir*(tm - delay)/(1. - delay*2.)*totRot) : mat2(1, 0, 0, 1);
        
        // Move the object off the ground.
        vec3 p3 = vec3(p, q3.z + (h*scale.y*2. - (l.y/2. - .02)*1.));
        
        // Rotate.
        //p3.xy *= cR; // Rotating more than one axis... Probably a bit much.
        p3.yz *= cR;
               
            
        const float ew = .0125;
        #ifdef HEXAGON
        // Hexagon option. ROW_OFFSET is automatically turned on.
        float di2D = sHexS(p3.xy, minSc/1.732 - ew, .01);
        //float di2D = length(p3.xy) - (minSc/1.732 - ew); // Cylinder option.
        
        // Unrotated shape to carve out the floor.
        float shp = sHexS(p, minSc/1.732 - ew, .01);
        //float shp = length(p.xy) - (minSc/1.732 - ew); // Cylinder option.
        #else
        
        float di2D = sBoxS(p3.xy, l/2. - ew, .01);  
        //float di2D = length(p3.xy) - (minSc/2. - ew); // Cylinder option.
        // Unrotated shape to carve out the floor.
        float shp = sBoxS(p.xy, l/2. - ew, .01);
        //float shp = length(p.xy) - (minSc/2. - ew); // Cylinder option.
        #endif
        
        
        
        
        
        #ifdef HOLES
        // Boring out some of the boxes.
        if((i&1)==0)
        {
            di2D = max(di2D, -(di2D + minSc/3.5));
            //shp = max(shp, -(shp + minSc/4.));
        }
        #endif
        
        shape = min(shape, shp);
        
        
        // The extruded distance function value.
        float di = opExtrusion(di2D, p3.z, l.y/2.*(1. - h*.0) - ew);

        
        #ifdef RAISED
        // Raised tops.
        di += di2D*.25;//min(di2D, di2DB)*.5;
        #endif
        
        #ifdef RIDGES
        // Putting ridges on the faces.
        di += smoothstep(-.5, .5, sin(di2D/minSc*6.2831*5.))*.005;
        #endif
        
        /*
        // Lego.
        float cap = length(p3.xy) - minSc/6.;
        cap = opExtrusion(cap, p3.z, l.y/2.*(1. - h*.0) - ew + .035);
        di = min(di, cap); //di = max(di, -cap)
        */
        
        

        // If applicable, update the overall minimum distance value,
        // ID, and box ID. 
        if(di<d){
            d = di;
            id = idi;
            // Extra data. In this case, the 2D distance field.
            data = di2D;
            
        }
        
    }
    
    // Return the distance, position-base ID and box ID.
    return vec4(d, id, data);
}


// Block ID -- It's a bit lazy putting it here, but it works. :)
vec4 gID;

// The extruded image.
float map(vec3 p){
    
    // Floor.
    float fl = (-p.z + .02);
    //float fl = (-p.z + .02) + scale.y/2.;
    
    // The extruded blocks.
    vec4 d4 = blocks(p);
    gID = d4; // Individual block ID.
    
    
    // Cutting out prism shapes from the floor to create the honeycomb mold
    // for the prism block objects to sit in.
    fl = max(fl, -max(shape, abs(p.z) - scale.y));
    
    #ifdef RIDGES
    // Hollowing ridge grooves into the floor.
    float minSc = min(scale.x, scale.y);
    fl -= smoothstep(-.5, .5, sin(shape/minSc*6.2831*5.))*.005;
    #endif
    
    #ifdef RAISED
    // Hollowing out the floor to match the raised tops on the objects.
    fl -= shape*.25;//min(di2D, di2DB)*.5;
    #endif

    // Debug to see the honeycomb floor only.
    //d4.x += 1e5;
 
    // Overall object ID.
    objID = fl<d4.x? 1. : 0.;
    
    // Combining the floor with the extruded object.
    return  min(fl, d4.x);
 
}

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float t = 0., d;
    
    for(int i = min(0, iFrame); i<64; i++){
    
        d = map(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(d)<.001 || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.
        
        t += i<32? d*.4 : d*.9; 
    }

    return min(t, FAR);
}


// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p, float t) {
	
    //return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), map(p + e.yxy) - map(p - e.yxy),	
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
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += clamp(d, .01, stepDist), etc.
        t += clamp(d, .01, .15); 
        
        
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
    
    #ifdef HEXAGON
    scale *= vec2(2./1.732, 1);
	#endif
    
	// Camera Setup.
    // Tilted camera, just to prove it's 3D. :)
	//vec3 ro = vec3(0, -1.3, -2.2); // Camera position, doubling as the ray origin.
	//vec3 lk = ro + vec3(0, .12, .25);//vec3(0, -.25, iTime);  // "Look At" position.
	// Front on camera.
    vec3 ro = vec3(0, iTime/16., -1.5); // Camera position, doubling as the ray origin.
	vec3 lk = ro + vec3(0, .05, .25);//vec3(0, -.25, iTime);  // "Look At" position.
 
    // Light positioning. One is just in front of the camera, and the other is in front of that.
 	vec3 lp = ro + vec3(-.25, .5, .5);// Put it a bit in front of the camera.
	

    // Using the above to produce the unit ray-direction vector.
    float FOV = 1.; // FOV - Field of view.
    vec3 fwd = normalize(lk-ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x )); 
    // "right" and "forward" are perpendicular, due to the dot product being zero. Therefore, I'm 
    // assuming no normalization is necessary? The only reason I ask is that lots of people do 
    // normalize, so perhaps I'm overlooking something?
    vec3 up = cross(fwd, rgt); 

    // rd - Ray direction.
    //vec3 rd = normalize(fwd + FOV*uv.x*rgt + FOV*uv.y*up);
    vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);
    
    // Swiveling the camera about the XY-plane.
	rd.xy *= rot2( sin(iTime)/32. );
    
	 
    
    // Raymarch to the scene.
    float t = trace(ro, rd);
    
    // Save the block field value, block ID and 2D data field value.
    vec4 svGID = gID;
    
    float svObjID = objID;
    
  
	
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
        
          
        // Scene object color. 
	    vec3 texCol;   

        
        if(svObjID<.5){
            
            // The flipping prisms.
            
            // Manipulating IQ's cosine palette for golden hues.
            vec3 cCol = (.5 + .45*cos(6.2831*hash21(svGID.yz)/5. + vec3(0, 1, 2) - .1));
            
            // Turning it into a pink palette.
            texCol = mix(min(cCol.xzy*1.65, 1.), vec3(1), .05);
            
            // Light based gradient mix.
            texCol = mix(texCol, texCol.zyx, smoothstep(-.25, .5, ld.y));
            //texCol = texCol.yxz; // Color swizzle.
            
            // Plain white.
            //texCol = vec3(.75);
            // Greyscale.
            //texCol = vec3(hash21(svGID.yz + .15)*.5 + .35);
 
        }
        else {
            
            // The floor with the bored out honeycomb.
            texCol = (sp.z>scale.y - .01)? vec3(.2, .4, 1) : vec3(.05);
            
            texCol = mix(texCol, texCol.yzx, smoothstep(-.25, .5, -ld.y)*.25);
            
            //texCol = mix(texCol.yxz, texCol, .75);
        }
       
        
        // Combining the above terms to produce the final color.
        col = texCol*(diff*sh + .3 + vec3(1, .97, .92)*spec*freS*2.*sh);
      
        // Shading.
        col *= ao*atten;
        
          
	
	}
          
    
    // Rought gamma correction.
	fragColor = vec4(sqrt(max(col, 0.)), 1);
	
}