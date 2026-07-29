// Image (image) — Voronoi Greeble Displacement by Shane
// https://www.shadertoy.com/view/NllyWf

/*

    Voronoi Greeble Displacement
    ----------------------------

	Using a tailored Voronoi algorithm to precalculate a greeble-like displacement 
    map, then raymarching it in realtime -- or in simpler terms, raymarching a custom 
    texture. :)
    
    At present, creating a texture on a buffer for usage in a 3D scene is not what I'd 
    call ideal. If you require proof, search Shadertoy and you won't find a great deal 
    of examples, especially those of the wrapped variety. Having said that, considering 
    the benefits involved, I'm still a little surprised that there aren't more 
    precalculated texture examples than there are.
    
    Your two choices are either using a buffer with variable rectangular dimensions, or 
    loading in all six faces of the cube map, then rendering to one or more of the six 
    fixed size faces. In my case, I prefer the latter, which is the lesser of the two 
    evils. I've been told that most GPUs aren't affected too much by the cube map memory 
    requirements, so I'll take people's word for it, but my common sense tells me that 
    using just one fixed size 1024 by 1024 buffer would be a way better use of machine 
    resources... However, I'm not an expert on machine architecture, so who knows.
    
    Anyway, the obvious benefit is precalculation. The following scene -- if you can
    call it that -- involves nothing more than a single raymarched texture. Calculating
    the 2D displacement function in realtime inside the raymarching loop would be 
    prohibitively expensive.
    
    In regard to the texture creation itself, it's just a variation on a Voronoi algorithm.
    Because it was calculated just the once at startup, I was able to tweak things at
    my leisure. This is just a very basic example to show that it's possible to raymarch
    more than simple noise and Voronoi. I'm leading up to more interesting scenes. There
    are a few defines in the "Common" and "Image" tab to look at, for anyone interested.
    
    

    

	Related exmaples:
    
	// As mentioned, there aren't too many precalculated displacement
    // map examples utilizing the cube map, but here's one.
    Alien Plain - fizzer 
	https://www.shadertoy.com/view/wdGXzy 
    
    // Awesome precalculated texture example. TekF has a few that are
    // worth looking at.
    Sedimentary Erosion - TekF
    https://www.shadertoy.com/view/tt2Szh
    
    // Using a variable sized buffer to precalculate a height field.
    Mucous Membrane HeightField - tholzer
    https://www.shadertoy.com/view/4l3fWn


*/


// Show the displacement map in its 3D setting in more detail.
//#define MAP_DETAIL

// Just the displacement map on its own. Actually, this is a bump mapped
// version. The texture map itself is quite mundane. The MAP_DETAIL option
// above will need to be commented out for this to work.
//#define DISPLACEMENT_MAP

// Gold material... Gold and silver would look nice. Maybe next time. :)
//#define GOLD

// Grayscale, for that artsy look.
//#define GRAYSCALE



// Max ray distance.
#define FAR 20.

// No forced unroll.
#define ZERO min(0, iFrame)



// Scene object ID to separate the mesh object from the terrain.
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


// Smooth cube map face 2D texture blend.
float getTex(vec3 q){
    
    // Scaling.
    vec2 p = q.xy/4.;
    
    // Cube map texture coordinate conversion.
    p *= cubemapRes;
    vec2 ip = floor(p); p -= ip;
    vec2 uv = fract((ip + .5)/cubemapRes) - .5;
    
    // 2D neighboring texels stored in each of the four texture channels.
    vec4 p4 = texture(iChannel2, vec3(-.5, uv.yx)); 
    
    // Linearly interpolate.
    return mix(mix(p4.x, p4.y, p.x), mix(p4.z, p4.w, p.x), p.y);

}



// The extruded image.
float map(vec3 p){
    
    
    // Plane warp.
    //p.z -= (dot(p.x, p.x))*.0125;
   
    // The Voronoi greeble displacement value.
    float pat = getTex(p);
    
    // A second layer. Too much for this example.
    //float pat2 = getTex(p*2.);
    //pat = mix(pat, pat2, 1./4.);
    
     // Floor.
    float fl = -p.z;// + 1.;
    
    // Applying the displacement map.
    fl -= pat*.5;
    
    

    // Overall object ID. Just the one, so redundant here,
    // but there are usually more.
    objID = 0.;
    
    // Just the floor.
    return  fl;
 
}

 

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float t = 0., d;
    
    for(int i = min(iFrame, 0); i<128; i++){
    
        d = map(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(d)<.001 || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.
        
        //t += i<32? d*.75 : d; 
        t += d*.5; 
    }

    return min(t, FAR);
}


// Standard normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p) {
	
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

    // More would be nicer. More is always nicer, but not really affordable... Not on my slow test machine, anyway.
    const int maxIterationsShad = 32; 
    
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
        t += clamp(d, .01, .2); 
        
        
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
    for( int i = ZERO; i<5; i++ ){
    
        float hr = float(i + 1)*.15/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
        //if(d>1e8) break; // Fake break.
    }
    
    return clamp(1. - occ, 0., 1.);  
    
    
}

// Slightly modified version of Nimitz's curve function. The tetrahedral and normal six
// tap versions are in there. If four taps gives you what you want, then that'd be the
// one to use.
//
// I think it's based on a discrete finite difference approximation to the continuous
// Laplace differential operator? Either way, it gives you the curvature of a surface, 
// which is pretty handy. I used it to do a bit of fake shadowing.
//
// Original usage (I think?) - Cheap curvature: https://www.shadertoy.com/view/Xts3WM
// Other usage: Xyptonjtroz: https://www.shadertoy.com/view/4ts3z2
//
// spr: sample spread, amp: amplitude, offs: offset.
float curve(in vec3 p, in float spr, in float amp, in float offs){

    float d = map(p);
    
    spr /= 450.;
    
    #if 0
    // Tetrahedral.
    vec2 e = vec2(-spr, spr); // Example: ef = .25;
    float d1 = map(p + e.yxx), d2 = map(p + e.xxy);
    float d3 = map(p + e.xyx), d4 = map(p + e.yyy);
    return clamp((d1 + d2 + d3 + d4 - d*4.)/e.y/2.*amp + offs + .5, 0., 1.);
    #else  
    // Cubic.
    vec2 e = vec2(spr, 0); // Example: ef = .5;
	float d1 = map(p + e.xyy), d2 = map(p - e.xyy);
	float d3 = map(p + e.yxy), d4 = map(p - e.yxy);
	float d5 = map(p + e.yyx), d6 = map(p - e.yyx);
    return clamp((d1 + d2 + d3 + d4 + d5 + d6 - d*6.)/e.x/2.*amp + offs + .5, 0., 1.);
    
    //d *=2.;
    //return 1. - smoothstep(-.05, .05, (abs(d1 + d2 - d) + abs(d3 + d4 - d) + abs(d5 + d6 - d))/e.x/2.*amp + offs + .0);
    #endif

}

/*
// A global value to record the distance from the camera to the hit point. It's used to tone
// down the sand height values that are further away. If you don't do this, really bad
// Moire artifacts will arise. By the way, you should always avoid globals, if you can, but
// I didn't want to pass an extra variable through a bunch of different functions.
float gT;

// Surface bump function..
float bumpSurf3D(in vec3 p){
    
    
    
    float ns = getTex(p);
    
    
    // A surprizingly simple and efficient hack to get rid of the super annoying Moire pattern 
    // formed in the distance. Simply lessen the value when it's further away. Most people would
    // figure this out pretty quickly, but it took far too long before it hit me. :)
    return ns;///(1. + gT*gT*.015);
    

}

// Standard function-based bump mapping routine: This is the cheaper four tap version. There's
// a six tap version (samples taken from either side of each axis), but this works well enough.
vec3 doBumpMap(in vec3 p, in vec3 nor, float bumpfactor){
    
    // Larger sample distances give a less defined bump, but can sometimes lessen the aliasing.
    const vec2 e = vec2(0.001, 0); 
    
    // Gradient vector: vec3(df/dx, df/dy, df/dz);
    float ref = bumpSurf3D(p);
    vec3 grad = (vec3(bumpSurf3D(p - e.xyy),
                      bumpSurf3D(p - e.yxy),
                      bumpSurf3D(p - e.yyx)) - ref)/e.x; 
    
    
    // Six tap version, for comparisson. No discernible visual difference, in a lot of cases.
    //vec3 grad = vec3(bumpSurf3D(p - e.xyy) - bumpSurf3D(p + e.xyy),
    //                 bumpSurf3D(p - e.yxy) - bumpSurf3D(p + e.yxy),
    //                 bumpSurf3D(p - e.yyx) - bumpSurf3D(p + e.yyx))/e.x*.5;
    
       
    // Adjusting the tangent vector so that it's perpendicular to the normal. It's some kind 
    // of orthogonal space fix using the Gram-Schmidt process, or something to that effect.
    grad -= nor*dot(nor, grad);          
         
    // Applying the gradient vector to the normal. Larger bump factors make things more bumpy.
    return normalize(nor + grad*bumpfactor);
	
}
*/

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    
    // Aspect correct screen coordinates. Translation and scale is all that
    // 
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
	
	// Camera Setup.
	vec3 ro = vec3(cos(iTime/4.)*1.5, iTime/1.5, -1.5); // Camera position, doubling as the ray origin.
	vec3 lk = ro + vec3(cos(iTime/4.)*.05, cos(iTime/2.)*.025  + .1, .25); // "Look At" position.
 
    // Light positioning. One is just in front of the camera, and the other is in front of that.
 	vec3 lp = ro + vec3(.5, 1, .75);// Put it a bit in front of the camera.
	

    // Using the above to produce the unit ray-direction vector.
    float FOV = 1.333; // FOV - Field of view.
    vec3 fwd = normalize(lk - ro); // Forward.
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x )); // Right. 
    // "right" and "forward" are perpendicular normals, so the result is normalized.
    vec3 up = cross(fwd, rgt); // Up.

    // rd - Ray direction.
    vec3 rd = mat3(rgt, up, fwd)*normalize(vec3(uv, 1./FOV - dot(uv, uv)*.05));
    // Equivalent to:
    //vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);
    
    
    // Swiveling the camera about the XY-plane.
	rd.xy *= rot2(-sin(iTime/4.)/2. );

	 
    
    // Raymarch to the scene.
    float t = trace(ro, rd);

    // Object ID.
    float svObjID = objID;
  
	
    // Initiate the scene color to black.
	vec3 col = vec3(0);
	
	// The ray has effectively hit the surface, so light it up.
	if(t < FAR){
        
  	
    	// Surface position and surface normal.
	    vec3 sp = ro + rd*t;
	    //vec3 sn = getNormal(sp, edge, crv, ef, t);
        vec3 sn = getNormal(sp);
        
        
        //sn = doBumpMap(sp, sn, .05);///(1. + t*t/FAR/FAR*.25)
        
          
        // Obtaining the texel color. 
	    vec3 texCol;   

        // The extruded grid.
        if(svObjID<.5){
            
 
            // Surface texture.
            vec3 txP = sp;
            txP.xy *= rot2(3.14159/6.);
            vec3 tx = tex3D(iChannel0, txP, sn);
            
            // Texture application.
            texCol = .025 + tx/2.;
            
            #ifdef GOLD
            // Gold material.
            texCol *= vec3(1.4, .85, .4);
            #endif
             
            // Extra texture shading. Not used.
            //float shade = getTex(sp)*.9 + .1;
            // texCol *= shade;

        }
        else {
            
            // The background. Not used here.
            texCol = vec3(0);
        }
       
    	
    	// Light direction vector.
	    vec3 ld = lp - sp;

        // Distance from respective light to the surface point.
	    float lDist = max(length(ld), .001);
    	
    	// Normalize the light direction vector.
	    ld /= lDist;

        // Light attenuation, based on the distances above.
	    float atten = smoothstep(.1, .5, 1./(1. + lDist*lDist*.35))*1.;
        
        // Shadows and ambient self shadowing.
    	float sh = softShadow(sp, lp, sn, 16.);
    	float ao = calcAO(sp, sn); // Ambient occlusion.
        //sh = min(sh + ao*.25, 1.);
        
        // spr: sample spread, amp: amplitude, offs: offset.
		float spr = 4., amp = 1., offs = 0.;
        float crv = curve(sp, spr, amp, offs);
	    
	    

    	
    	// Diffuse lighting.
	    float diff = max( dot(sn, ld), 0.);
        diff = pow(diff, 32.)*4.; // Ramping up the diffuse.
    	
    	// Specular lighting.
	    float spec = pow(max(dot(reflect(ld, sn), rd ), 0.), 8.); 
	    
	    // Fresnel term. Good for giving a surface a bit of a reflective glow.
        float fre = pow(clamp(1. - abs(dot(sn, rd))*.5, 0., 1.), 2.);
        
        // Half vector.
        vec3 hv = normalize(rd + ld);
        // Specular Blinn Phong. The last term is highlight power related.
        float specBF = pow(max(dot(hv, sn), 0.), 6.);
   
        
        
		// Schlick approximation. I use it to tone down the specular term. It's pretty subtle,
        // so could almost be aproximated by a constant, but I prefer it. Feel free to look up
        // the "science," but it essentially takes that annoying central shine out. How
        // much you take out depends on the material, which is controlled by the material
        // constant.
		float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
		float freS = mix(.2, 1., Schlick);  //F0 = .2 - Glass... or close enough.        
        
        // Using the curvature to color the texture a bit.
        //texCol *= mix(vec3(.0, .1, .2), vec3(.9, .8, .8)/2., crv)*2.;//*.125 + .125;
      
        //texCol *= clamp(sp.z + .5, 0., 1.);
        // Combining the above terms to procude the final color.
        col = texCol*(diff*sh + .25);
        //col *= 2.;
        // The specular term: Instead of putting in two different colored lights, which
        // requires two expensive shadow runs, I'm using a cheap trick involving partitioning 
        // the specular color with repect to which side of the ray it's sitting on. Not science, 
        // but no one will notice, and those who do won't care. :)
        vec3 specCol = mix(vec3(1, .4, .2), vec3(1, .4, .2).xzy, smoothstep(0., .3, -rd.y + .3));
        specCol = mix(vec3(1, .4, .2), vec3(1, .4, .2).zyx, smoothstep(0., .3, -rd.x*2.));
        specCol *= texCol*8.;
        //col += specCol*spec*freS*2.*sh; 
        col += specCol*pow(spec, 8.)*freS*32.*sh; 
 
        // Cube map reflection. Not as cool as a second pass, but it works here.
        vec3 refCol = texture(iChannel1, reflect(rd, sn)).xyz; refCol *= refCol;
        col += col*refCol*6.;
        // Specular Blinn Phong.
        //col += specBF*refCol*4.;
        
        // Shading.
        col *= ao*atten;
        
        col *= crv; // Curvature based shading.
        
        // Dark lines.
        //col *= max(1. - abs(crv - .5)*2., 0.);
        
        
        // Greyscale value, just in case people switch to the Britney video, etc.
        // Stylistically, the example works better with color. The Britney video
        // looks OK, but I'm more of a Shirley Jones kind of guy. :)
        #ifdef GRAYSCALE
        col = vec3(1)*dot(col, vec3(.299, .587, .114));
        #endif
        
        #ifdef MAP_DETAIL
        // Also used for debugging purposes.
        col = vec3(crv*(sh*.9 + .1)); // ao, sh, etc.        
        #endif
          
	
	}
    

    // Just the displacement map on its own. Actually, this is a bump mapped
    // version. The texture map itself is quite mundane, which you can see 
    // if you set "b2" to 1.
    #ifdef DISPLACEMENT_MAP
    float b = getTex(vec3(uv*4. - iTime/4., 0));
    float b2 = getTex(vec3(uv*4. - iTime/4. - normalize(vec2(1, 2))/cubemapRes.x, 0));
    b2 = max(b2 - b, 0.)*cubemapRes.x;
    col = b*vec3(1)*(b2*.85 + .15);
    #endif      
    
    // Rought gamma correction.
	fragColor = vec4(sqrt(max(col, 0.)), 1);
	
}