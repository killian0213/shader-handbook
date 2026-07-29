// Image (image) — Extruded Hexagon Fractal Curve by Shane
// https://www.shadertoy.com/view/cdjGWy

/*

    Extruded Hexagon Fractal Curve
    ------------------------------
    
    This is an extruded hexagon fractal curve -- to match the 2D version that 
    I posted earlier. The original was constructed in a tri-level blob form, 
    but I've rendered this in a curved configuration to better display the 
    non-intersecting space-filling curve properties. As you can see, it has 
    a hexagon Truchet look about it.
    
    Although not the same, it has a similar feel to Fabrice Neyret and MLA's 
    Gosper curve examples, which are well worth the look if you haven't seen 
    them. Gosper curves are one those interesting and important topics that 
    very little code exists for.
    
    Technically, there's not much to this. I've rendered the curve in 2D to a
    backbuffer, then extruded the 2D field inside the raymarching distance 
    function, which is a lot faster than constructing things on the fly. As a 
    small aside, it would be much more practical to render from a fixed size 
    buffer for many reasons. Even though cube map faces have fixed sizes, 
    they are not fun to work with in that capacity.
    
    I kept the lighting and coloring very basic, which is just another way to 
    say, I was feeling lazy. :D There are a few defines at the top of the 
    "Common" tab for anyone interested in changing the color, curve shape, etc.
 


    
    Related examples:
    
    // The Gosper curves are different, but have a very similar feel.
    Gosper Closed Curves - mla
    https://www.shadertoy.com/view/mdXGWl
    
    // The original Gosper curve example on here.
    Gosper curve - FabriceNeyret2
    https://www.shadertoy.com/view/cdsGRj
    
    // A 2D hexagon fractal version.
    Hexagon Fractal Object - Shane
    https://www.shadertoy.com/view/cdfGzs
    
*/


// Global tile scale.
vec2 scale = vec2(1./8.);

// Max ray distance.
#define FAR 20.


// Scene object ID.
float objID;



// Height map value.
float hm(in vec2 p){ 

    // Reading into "Buffer A".
    // Stretching to account for the varying buffer size.
    p *= vec2(iResolution.y/iResolution.x, 1);
    return texture(iChannel0, p + .5).x;
    
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

 

// The extruded image.
float map(vec3 p){
    
    // Floor.
    float fl = p.y;

    // The 2D hexagon fractal object.
    float d2 = hm(p.xz);
    
    // Extruding the 2D field.
    float d = opExtrusion(d2, p.y, .05);
    
    //d += d2*.25; // Raised tops.
  
    // Overall object ID.
    objID = fl<d? 1. : 0.;
    
    // Combining the floor with the extruded object.
    return  min(fl, d);
 
}

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float t = 0., d;
    
    for(int i = min(0, iFrame); i<96; i++){
    
        d = map(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(d)<.001 || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.
        
        t += d*.7; 
    }

    return min(t, FAR);
}


// Standard normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p, float t) {
	
    //const vec2 e = vec2(.001, 0);
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
        //shade = min(shade, smoothstep(0., 1., k*d/t)); // Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += clamp(d, .01, stepDist), etc.
        t += clamp(d, .005, .15); 
        
        
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
    vec3 ro = vec3(cos(iTime/8.)*1.1, 1.25, sin(iTime/8.)*1.1); // Camera position, doubling as the ray origin.
	vec3 lk = vec3(0, -.06, 0);//vec3(0, -.25, iTime);  // "Look At" position.
 
    // Light positioning. One is just in front of the camera, and the other is in front of that.
 	vec3 lp = lk + vec3(-.25, .5, .4);// Put it a bit in front of the camera.
	

    // Using the above to produce the unit ray-direction vector.
    float FOV = .5; // FOV - Field of view.
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
        
        vec2 txP = sp.xz;        
        txP *= vec2(iResolution.y/iResolution.x, 1);
        vec4 tx = texture(iChannel0, txP + .5);
        float dst = tx.w;
        float sf = 1./iResolution.y;

        // The extruded grid.
        if(svObjID<.5){
            
            //float h = hm(sp.xz);
            

            
            dst = max(dst, sp.y - .05 - .02);

            
            // The fractal curve object color.
            #if COLOR == 0
            vec3 fg = vec3(1, .2, .4);
            fg = mix(fg, vec3(1, .4, .2), uv.y*.5 + .25);
            #elif COLOR == 1
            vec3 fg = vec3(.8, 1, .15);
            fg = mix(fg, vec3(1, .8, .2), uv.y*.5 + .25);
            #elif COLOR == 2
            vec3 fg = vec3(.2, .5, 1);
            fg = mix(fg, vec3(.1, .9, 1), uv.y*.5 + .25);
            #else
            vec3 fg = vec3(.85);
            fg = mix(fg, vec3(.88, .9, .95), uv.y*.5 + .25);
            #endif

            // Object color.
            
            float th = .005*float(2 - cInd);
            vec3 oCol = vec3(0);
            oCol = mix(oCol, pow(fg, vec3(1)), 1. - smoothstep(0., sf,  dst + .005));
            // Surface detail.
            //oCol = mix(oCol, oCol*.5, 1. - smoothstep(0., sf,  abs(dst + .013) - .001));

            texCol = mix(oCol, pow(fg, vec3(1.4)), 1. - smoothstep(0., sf, sp.y - .05 + .002));
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf, sp.y - .005));
 
        }
        else {
            
            // The floor pattern.
            
            
            // Background.
            texCol = vec3(.1); //vec3(.4, .35, .3); //vec3(.9, .95, 1)
      
            // The hexagon Truchet background.
            float hSc = .2/.8660254*sqrt(7.)/scale.x*2.; // Scale based on the main pattern level.
            vec2 hUV = rot2(-atan(sqrt(3.)/9.))*sp.xz; // Rotating the coordinates.
            float bgP = bgPat(hUV*hSc)/hSc;
            vec3 svBg = texCol;

            // Rendering the hexagon background pattern.
            texCol = mix(texCol, svBg*.8, (1. - smoothstep(0., sf*8., bgP)));  
            texCol = mix(texCol, svBg*.5, 1. - smoothstep(0., sf, bgP));   
            texCol = mix(texCol, svBg*1.1, 1. - smoothstep(0., sf, bgP + .0035));  
            // Surface detail.
            //texCol = mix(texCol, svBg*.6, 1. - smoothstep(0., sf,  abs(bgP + .011) - .001));
 
            // Rendering some dark edges to match the extruded pattern.
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., sf,  dst - .0005));
        
        }
       

        
        // Combining the above terms to produce the final color.
        col = texCol*(diff*sh + .3 + vec3(1, .97, .92)*spec*freS*2.*sh);
      
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