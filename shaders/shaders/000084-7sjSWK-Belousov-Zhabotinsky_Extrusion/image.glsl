// Image (image) — Belousov-Zhabotinsky Extrusion by Shane
// https://www.shadertoy.com/view/7sjSWK

/*


    Belousov-Zhabotinsky Extrusion
    ------------------------------

	FlexMonkey put together a really cool diffusion based example a while back
    that I thought was pretty awesome, so I wanted to make a version of it. The
    original is a Belousov–Zhabotinsky reaction mapped to a 2D hexagonal grid, 
    so I was curious as to how it would look in extruded form.
    
    I used a simpler and somewhat less sophisticated method to create the 
    Belousov–Zhabotinsky reaction pattern itself, but it's essentially the same 
    thing -- By the way, the link to FlexMonkey's original is below.
    
    Codewise, there's nothing particularly exciting in here, but I thought I'd
    post it for anyone interested in this kind of thing.
    
    

	Based on:
    
	// FlexMonkey (A.K.A Simon Gladman) has a heap of nice diffusion related 
    // examples on here.
    Pixelated Belousov–Zhabotinsky - FlexMonkey
	https://www.shadertoy.com/view/ltlfWn 
    
    Other examples:
    
    // A really nice concise version.
    Belousov-Zhabotinsky Reaction - Cornusammonis
    https://www.shadertoy.com/view/XtcGD2
    
    // The smallest Turing routine you're likely to find. If you set the 
    // texture to multicolor and uncomment the Belousov–Zhabotinsky line,
    // you'll see a rough hardware version of this pattern.
    Two Tweet Turing Texture - Shane
    https://www.shadertoy.com/view/4ldcWS

*/



// Max ray distance.
#define FAR 20.

// Hollow out the pylon center -- Kind of intersting.
//#define HOLLOW

// Flatten the scene, but give the pylons just a tiny variation for lighting.
//#define FLAT

// Greyscale.
//#define GREYSCALE
        



// Scene object ID to separate the mesh object from the terrain.
float objID;


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }


// 2D Texture routine.
vec3 getTex2D(vec2 p){
    
    // Strething things out so that the image fills up the window. You don't need to,
    // but this looks better. I think the original video is in the oldschool 4 to 3
    // format, whereas the canvas is along the order of 16 to 9, which we're used to.
    // If using repeat textures, you'd comment the first line out.
    //p *= vec2(iResolution.y/iResolution.x, 1);
    vec3 tx = texture(iChannel1, fract(p)).xyz;
    return tx*tx; // Rough sRGB to linear conversion.
}


// Cube map texture reader.
vec3 getTex(vec2 p){
    
    // Strething things out so that the image fills up the window. You don't need to,
    // but this looks better. I think the original video is in the oldschool 4 to 3
    // format, whereas the canvas is along the order of 16 to 9, which we're used to.
    // If using repeat textures, you'd comment the first line out.
    //p *= vec2(iResolution.y/iResolution.x, 1);
  
    p /= 4.;
    //p = (mod(floor(p*1024.), 1024.) + .5)/1024.;
    return texture(iChannel0, vec3(fract(p) - .5, .5)).xyz;
 

}

// Height map value, which is just the pixel's greyscale value.
float hm(in vec2 p){ return dot(getTex(p), vec3(.299, .587, .114)); }

// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h){
    
    vec2 w = vec2( sdf, abs(pz) - h );
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.));

    /*
    // Slight rounding. A little nicer, but slower.
    const float sf = .025;
    vec2 w = vec2( sdf, abs(pz) - h - sf/2. );
  	return min(max(w.x, w.y), 0.) + length(max(w + sf, 0.)) - sf;
    */
}


// Signed distance to a regular hexagon, with a hacky smoothing variable thrown
// in. -- It's based off of IQ's more exact pentagon method, which is here:
float sHexS(in vec2 p, float r, in float sf){
    
  const vec3 k = vec3(-.8660254, .5, .57735); // pi/6: cos, sin, tan.

  // X and Y reflection.  
  p = abs(p); 
  p -= 2.*min(dot(k.xy, p), 0.)*k.xy;
   
 
  r -= sf;
  // Polygon side.
  return length(p - vec2(clamp(p.x, -k.z*r, k.z*r), r))*sign(p.y - r) - sf;
    
}
 
// A regular extruded block grid.
//
// The idea is very simple: Produce a normal grid full of packed square pylons.
// That is, use the grid cell's center pixel to obtain a height value (read in
// from a height map), then render a pylon at that height.

vec4 blocks(vec3 q3){
    
    // Scale.
    //#define STRETCH
    #ifdef STRETCH
	const vec2 scale = vec2(1./12., 1./16.);
     // Brick dimension: Length to height ratio with additional scaling.
	const vec2 l = vec2(scale.x*1.732/2., scale.y);
    #else
    const float scale = 1./16.;
     // Brick dimension: Length to height ratio with additional scaling.
	const vec2 l = vec2(scale*1.732/2., scale);
    #endif
    
   
    // A helper vector, but basically, it's the size of the repeat cell.
	const vec2 s = l*2.;
    
    // Distance.
    float d = 1e5;
    // Local coordinates, cell center, and overall cell IDs.
    vec2 p, cntr, id = vec2(0), idi = vec2(0);
    

    
    
    // Four block corner postions.
    const vec2 ll = vec2(.5);
    //vec2[4] ps4 = vec2[4](vec2(-ll.x, ll.y), ll, -ll, vec2(ll.x, -ll.y));
    // Pointed top.
    //vec2[4] ps4 = vec2[4](vec2(-ll.x, ll.y), ll, -ll + vec2(ll.x, 0), vec2(ll.x, -ll.y) + vec2(ll.x, 0));
    // Flat top.
    vec2[4] ps4 = vec2[4](vec2(-ll.x, ll.y), ll + vec2(0., ll.y), -ll, vec2(ll.x, -ll.y) + vec2(0., ll.y));
    
    float boxID = 0.; // Box ID. Not used in this example, but helpful.
    
    for(int i = 0; i<4; i++){

        // Block center.
        cntr = ps4[i]/2.;

        // Local coordinates.
        p = q3.xy;
        //ip = floor(p/s - cntr) + .5 + cntr; // Local tile ID.
        // Correct positional individual tile ID.
        idi = (floor(p/s - cntr) + .5 + cntr)*s;
        p -= idi; // New local position.

                    
 
        // The extruded block height. See the height map function, above.
        float h = hm(idi)*.5 + .5;
        
        // Block width -- Normally set to one, but I'm using the underlying color
        // to change the width.
        float w = max(1. - h*h*2.2, .1);
        
        // Tempering the height.
        #ifdef FLAT
        h *= .05; // Relatively flat. Just a tiny variation for lighting.
        #else
        h *= .3;
        #endif
        
        
            
        // The hexagonal cross section. The corners are slightly rounded on this
        // version, but they don't have to be.
        #ifdef STRETCH
        vec2 lu = l/vec2(1.732/2., 1);
        vec2 pStretch = lu.x<lu.y? vec2(1, lu.x/lu.y) : vec2(lu.y/lu.x, 1);
        float r = min(lu.x, lu.y)/2.;
        float di2D = sHexS(p*pStretch, r*(.5 - w)*2., .2*r*(.5 - w));
        #else
        float di2D = sHexS(p, scale*(.5 - w), .2*scale*(.5 - w));
        //float di2D = sCylS(p, scale*(.5 - w));
        #endif
        
        #ifdef HOLLOW
        // Hollow out the pylon center.
        di2D = abs(di2D + .14*scale) - .14*scale;
        #endif

        // The extruded distance function value.
        float di = opExtrusion(di2D, (q3.z + h), h);
        
        //di = min(di, length(vec3(p, q3.z + h*2.)) - (scale/2. - w/2.*scale/2.)*.98);
        di += di2D/6.;

        // If applicable, update the overall minimum distance value,
        // ID, and box ID. 
        if(di<d){
            d = di;
            id = idi;
            // BoxID.
            boxID = di2D;
        }
        
    }
    
    // Return the distance, position-base ID and box ID.
    return vec4(d, id, boxID);
}


// Block ID -- It's a bit lazy putting it here, but it works. :)
vec3 gID;

// The extruded image.
float map(vec3 p){
    
    // Floor.
    float fl = -p.z + .03;

    // The extruded blocks.
    vec4 d4 = blocks(p);
    gID = d4.yzw; // Individual block ID.
    
 
    // Overall object ID.
    objID = fl<d4.x? 1. : 0.;
    
    // Combining the floor with the extruded image
    return  min(fl, d4.x);
 
}

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float t = 0., d;
    
    for(int i = min(iFrame, 0); i<80; i++){
    
        d = map(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(d)<.001 || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.
        
        //t += i<32? d*.75 : d; 
        t += d*.7; 
    }

    return min(t, FAR);
}


// Standard normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p, float t) {
	const vec2 e = vec2(.001, 0);
	return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), 
                          map(p + e.yxy) - map(p - e.yxy),	
                          map(p + e.yyx) - map(p - e.yyx)));
}


// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with limited 
// iterations is impossible... However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not really affordable... Not on my slow test machine, 
    //anyway.
    const int maxIterationsShad = 24; 
    
    ro += n*.0015;
    vec3 rd = lp - ro; // Unnormalized direction ray.
    

    float shade = 1.;
    float t = 0.;//.0015; // Coincides with the hit condition in the "trace" function.  
    float end = max(length(rd), 0.0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i = min(iFrame, 0); i<maxIterationsShad; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Subtle difference. Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), dist += clamp(h, .01, stepDist), etc.
        t += clamp(d, .01, .25); 
        
        
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
float calcAO(in vec3 p, in vec3 n)
{
	float sca = 3., occ = 0.;
    for( int i = 0; i<5; i++ ){
    
        float hr = float(i + 1)*.15/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
    }
    
    return clamp(1. - occ, 0., 1.);  
    
    
}

/*
// Compact, self-contained version of IQ's 3D value noise function. I have a transparent noise
// example that explains it, if you require it.
float n3D(in vec3 p){
    
	const vec3 s = vec3(7, 157, 113);
	vec3 ip = floor(p); p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p*p*(3. - 2.*p); //p *= p*p*(p*(p * 6. - 15.) + 10.);
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}

// Very basic pseudo environment mapping... and by that, I mean it's fake. :) However, it 
// does give the impression that the surface is reflecting the surrounds in some way.
//
// More sophisticated environment mapping:
// UI easy to integrate - XT95    
// https://www.shadertoy.com/view/ldKSDm
vec3 envMap(vec3 p){
    
    p *= 3.;
    p.y += iTime;
    
    float n3D2 = n3D(p*2.);
   
    // A bit of fBm.
    float c = n3D(p)*.57 + n3D2*.28 + n3D(p*4.)*.15;
    c = smoothstep(.4, 1., c); // Putting in some dark space.
    
    p = vec3(c, c*c, c*c*c); // Redish tinge.
    
    return mix(p, p.xzy, n3D2*.4); // Mixing in a bit of purple.

}

*/

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    
    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
	
	// Camera Setup.
	vec3 ro = vec3(0, iTime/8., -4.25); // Camera position, doubling as the ray origin.
	vec3 lk = ro + vec3(0, .07, .25);//vec3(0, -.25, iTime);  // "Look At" position.
 
    // Light positioning. One is just in front of the camera, and the other is in front of that.
 	vec3 lp = ro + vec3(.5, 2, 3);// Put it a bit in front of the camera.
	

    // Using the above to produce the unit ray-direction vector.
    float FOV = .5; // FOV - Field of view.
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x )); 
    // "right" and "forward" are perpendicular, due to the dot product being zero. Therefore, I'm 
    // assuming no normalization is necessary? The only reason I ask is that lots of people do 
    // normalize, so perhaps I'm overlooking something?
    vec3 up = cross(fwd, rgt); 

    // rd - Ray direction.
    //vec3 rd = normalize(fwd + FOV*uv.x*rgt + FOV*uv.y*up);
    vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);
    
    // Swiveling the camera about the XY-plane.
	//rd.xy *= rot2( sin(iTime)/32. );

    

	 
    
    // Raymarch to the scene.
    float t = trace(ro, rd);
    
    // Save the block ID and object ID.
    vec3 svGID = gID;
    
    float svObjID = objID;
  
	
    // Initiate the scene color to black.
	vec3 col = vec3(0);
	
	// The ray has effectively hit the surface, so light it up.
	if(t < FAR){
        
  	
    	// Surface position and surface normal.
	    vec3 sp = ro + rd*t;
	    //vec3 sn = getNormal(sp, edge, crv, ef, t);
        vec3 sn = getNormal(sp, t);
        
        // Light direction vector.
	    vec3 ld = lp - sp;

        // Distance from respective light to the surface point.
	    float lDist = max(length(ld), .001);
    	
    	// Normalize the light direction vector.
	    ld /= lDist;

        
        
        // Shadows and ambient self shadowing.
    	float sh = softShadow(sp, lp, sn, 8.);
    	float ao = calcAO(sp, sn); // Ambient occlusion.
        //sh = min(sh + ao*.25, 1.);
	    
	    // Light attenuation, based on the distances above.
	    float atten = 1./(1. + lDist*.05);

    	
    	// Diffuse lighting.
	    float diff = max( dot(sn, ld), 0.);
        //diff = pow(diff, 4.)*2.; // Ramping up the diffuse.
    	
    	// Specular lighting.
	    float spec = pow(max(dot(reflect(ld, sn), rd ), 0.), 32.); 
	    
        /*
	    // Fresnel term. Good for giving a surface a bit of a reflective glow.
        float fre = pow(clamp(1. + dot(sn, rd), 0., 1.), 2.);
        
		// Schlick approximation. I use it to tone down the specular term. It's pretty subtle,
        // so could almost be aproximated by a constant, but I prefer it. Here, it's being
        // used to give a hard clay consistency... It "kind of" works.
		float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
		float freS = mix(.15, 1., Schlick);  //F0 = .2 - Glass... or close enough.     
        */
          
        // Obtaining the texel color. 
	    vec3 texCol;   

        // The extruded grid.
        if(svObjID<.5){
            
            // Coloring the individual blocks with the saved ID.
            
            vec3 tx = getTex(svGID.xy); // See scale in the distance function.
            //vec3 tx2 = vec3(hash21(svGID.xy + .1), hash21(svGID.xy + .2), hash21(svGID.xy + .3));
            vec3 tx2 = getTex2D(svGID.xy/2.); // Texture based color.
            tx = smoothstep(0., .5, tx);
            tx2 = smoothstep(0., .5, tx2);
            
            #ifdef GREYSCALE
            // Greyscale value.
            float gr = clamp(dot(tx*2. - .25, vec3(.299, .587, .114)), 0., 1.);
            texCol = tx2*gr*1.5;
            #else
            // Applying some color. 
            texCol = tx*.8 + .2;
            texCol = .53 + .42*cos(-texCol*6.2831/2.8 + vec3(0, 1, 2) + 2.5);
            texCol *= tx2*3.;
            #endif
            
            // Central dots.
            //vec2 svP = sp.xy - svGID.xy;
            //texCol = mix(texCol, vec3(0), 1. - smoothstep(0., .005, length(svP) - .04/8.));
            
            /*
            // Hexagonal face value.
            float ht = (hm(svGID.xy)*.5 + .5)*.3;
            float hex = svGID.z;
   
            float hex2 = hex;
            hex = max(abs(hex), abs(sp.z + ht*2.)) - .004; // Face border.
            //hex = min(hex, abs(hex2 + .01) - .00125); // Extra border.
            // Applying the face border.
            texCol = mix(texCol, texCol/8., (1. - smoothstep(0., .002, hex)));
            */
        }
        else {
            
            // The dark floor in the background. Hiddent behind the pylons, but
            // you still need it.
            texCol = vec3(.05);
        }
       
    	
   
        
        // Combining the above terms to procude the final color.
        col = texCol*(diff*sh + .25 + vec3(1, .7, .4)*spec*2.*sh);
        
        // Fake environment mapping.
        //vec3 cTex = envMap(reflect(rd, sn));
        //col += col*cTex.zyx*sh*5.;

        // Shading.
        col *= ao*atten;
        
        
	
	}
    
          
    
    // Rought gamma correction.
	fragColor = vec4(sqrt(max(col, 0.)), 1);
	
}