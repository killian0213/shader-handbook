// Buffer A (buffer) — Extruded Maze by Shane
// https://www.shadertoy.com/view/wXjGD1

/*

    Extruded Maze
    -------------
    
    I like maze imagery. There's a lot of it on the internet, and on Shadertoy. 
    I'm not sure what the technical definition of a maze is, but I doubt this 
    would qualify. Either way, it's an interesting pattern with a maze like feel
    to it.
    
    The purpose of this exercise was to explore cheap ways to produce an eroded, 
    worn looking material. The embers on the floor were added as an afterthought, 
    and I'm still not sure whether it enhanced or detracted from the final result.
    
    There are two maze pattern options in the "Common" tab, for anyone interested.
    The second maze looks more interesting and was supposed to be the default.
    Unfortunately, the code to produce it was more involved than I anticiapted, 
    which made it slower.
    
    Anyway, I wanted to post this as a framework for later use. I intend to do
    something more interesting with the next one. I'll probably use a more 
    traditional maze creation algorithm as well.
    
    
    
    // Other examples:
    
    // I've always like this example. I'm going to make a more
    // 3D-ish looking version at some stage, and a 2D hexagon
    // based one too, if I can find the time.
    hexastairs: ladder like + doors -- FabriceNeyret2
    https://www.shadertoy.com/view/wsyBDm
    
    // One of Dr2's solvable extruded mazes.
    Maze Ball Solved - Dr2
    https://www.shadertoy.com/view/tdfXRM
    
    // Bitless has a heap of interesting shaders. I like the
    // rendering style of this one.
    Office Hell -- bitless
    https://www.shadertoy.com/view/ttVSRz


*/


// Max ray distance.
#define FAR 20.



// Scene object ID to separate the mesh object from the terrain.
float objID;


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


// Texture sample.
//
vec3 getTex(sampler2D iCh, vec2 p){
    
    // Strething things out so that the image fills up the window. You don't need to,
    // but this looks better. I think the original video is in the oldschool 4 to 3
    // format, whereas the canvas is along the order of 16 to 9, which we're used to.
    // If using repeat textures, you'd comment the first line out.
    //p *= vec2(iResolution.y/iResolution.x, 1);
    vec3 tx = texture(iCh, p).xyz;
    return tx*tx; // Rough sRGB to linear conversion.
}

// Height map value.
float hm(in vec2 p){ return dot(sin(p*1.25 - cos(p.yx*2.)), vec2(.25)) + .5; }
 
// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h, in float sf){

    // Slight rounding. A little nicer, but slower.
    vec2 w = vec2( sdf, abs(pz) - h) + sf;
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.)) - sf;
}
 

 
// Subdivided rectangle grid.
vec3 getGrid(inout vec2 p, vec2 sc){
  
    vec3 d3 = truchet(p);
    
    // Local coordinates and cell ID.
    return vec3(d3.x, d3.yz*sc);
}

// Glow.
vec3 glow;
float mzStrip;

// Global cell boundary distance variables.
vec3 gDir; // Cell traversing direction.
vec3 gRd; // Ray direction.
float gCD; // Cell boundary distance.
// Box dimension and local XY coordinates.
vec3 gSc; 
vec2 gP;


float gNS;

vec3 gRo;
 
// An extruded subdivided block grid. Use the grid cell's center pixel 
// to obtain a height value (read in from a height map), then render a 
// pylon at that height.

vec4 exMaze(vec3 q3){
    
 
    // Local coordinates.
    vec2 p = q3.xy;

    //vec3 sc = vec3(1); // Scale.
    // Local coordinates and cell ID.
    vec3 p3 = getGrid(p, sc.xy); 
    
    // 2D field value and corresponding position-based ID.
    float d2 = p3.x;
    vec2 id = p3.yz;




    // The extruded block height. See the height map function, above.
    //float h = hm(q3.xy);
    float h = .4; // Constant height for this one.
  

    // Extrude the 2D shape.
    float d = opExtrusion(d2, q3.z + h/2., h/2., .0);// - bev;
    //float dL = opExtrusion(d2 + .08, q3.z + h/2., h/2. + .05, .0);// - bev;
    vec2 L2 = vec2(d2 + lw/2.*1.5-lw, q3.z + h*0. + .0);//.115
    float dL = length(L2) - .015;
    
    // Maxe glow strip variable.
    mzStrip = dL;
    

    // Beveling.
    d -= min(-d2/sc.x, .1)*.1;
    
    /*
    // Putting some random Lego-like circles, or whatever on top.
    if(min(sc.x, sc.y)>.125 && hash21(id + .03)<1.5){ 
       //float dB = opExtrusion(d2 + .07, q3.z + h/2. + .3, h/2., .0);
       float dB = length(abs(p) - vec2(.5, 0)*sc.x);
       dB = min(dB,  length(abs(p) - vec2(0, .5)*sc.x));
       dB = opExtrusion(dB - sc.x/12., q3.z + h/2. + .05, h/2., .0);
       d = min(d, dB);
       //mzStrip = dB;
    } 
    */
   
   
    // Using some cheap sinusoidal noise to produce an eroded look.
    vec3 q3B = q3;
    q3B.xz *= rot2(PI/8.);
    q3B.yz *= rot2(PI/12.);
    // First layer of noise.
    float ns = ((dot(sin(q3B*6. - cos(q3B.yzx*12. + 1.)), vec3(1)/6.) + .5) - .65)/8.;
    // Second noise layer.
    ns = mix(ns, ((dot(sin(q3B*32. + 1.5 - cos(q3B.yzx*64. + 2.)), vec3(1)/6.) + .5) - .6)/8., .5);
    d = min(max(d, ns), (d + .025 + sin(ns*64.)*.01));
    gNS = ns;
    
    // Maxe glow strip variable.
    mzStrip = max(mzStrip, ns + .045);
  
      
    
    // The distance from the current ray position to the cell boundary
    // wall in the direction of the unit direction ray.
    //vec3 rC = (gDir*vec3(sc, 1) - vec3(p, q3.z))/gRd;
    vec2 rC = (gDir.xy*sc.xy - p)/gRd.xy;  // For 2D, this will work too.
    
    // Minimum of all distances
    //gCD = max(min(min(rC.x, rC.y), rC.z), 0.) + .0001;
    gCD = max(min(rC.x, rC.y), 0.) + .0001; // Adding a touch to advance to the next cell.
    // Saving the box dimensions and local coordinates.
    gSc = vec3(sc.xy, h);
    gP = p;//p;

        
   
    // Return the distance, position-base ID and box ID.
    return vec4(d, d2, id);
}


// Block ID -- It's a bit lazy putting it here, but it works. :)
vec4 gID;

// The extruded image.
float map(vec3 p){
    
    // Floor.
    float h = hm(p.xy*4. - gNS) -.5;
    float fl = -p.z - h*.1;
    fl = max(fl, -gNS);
    fl = min(fl, -p.z + .05);
    fl = min(fl, -p.z - h*.1 + .05);

    // The extruded maze.
    vec4 d4 = exMaze(p);
    gID = d4; // Individual block ID.
    
    // Add glow to the maze glow strip.
    if(mzStrip<min(d4.x, fl)) //mzStrip<.25 && 
        glow += vec3(4, 1.5, .5)*
                smoothstep(0., .25, .0025/max(mzStrip*mzStrip/.2/.2, .001));
   
 
    // Overall object ID.
    objID = fl<d4.x && fl<mzStrip? 0. : d4.x<mzStrip? 1. : 2.;
    
    // Combining the floor with the extruded image
    return  min(fl, min(d4.x, mzStrip));
 
}



// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){
     
    
    float tmin = 0.;
    float tmax = FAR;
    
    // IQ's bounding plane addition, to help give some extra performance.
    //
    // If ray starts above bounding plane, skip all the empty space.
    // If ray starts below bounding plane, never march beyond it.
    const float boundZ = -.7;
    float h = (boundZ - ro.z)/rd.z;
    if(h>0.){
    
        if( ro.z<boundZ ) tmin = max(tmin, h);
        else tmax = min(h, FAR);
    }

    // Overall ray distance and scene distance.
    float d, t = tmin + hash31(ro + rd)*.15;
  
    
    //vec2 dt = vec2(1e5, 0); // IQ's clever desparkling trick.
    
    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = step(0., rd) - .5;
    gRd = rd; 
    
    // Reset the glow to zero.
    glow = vec3(0);
    
    int i;
    const int iMax = 128;
    for (i = min(iFrame, 0); i<iMax; i++){ 
    
        d = map(ro + rd*t);       
        //dt = d<dt.x? vec2(d, dt.x) : dt; // Shuffle things along.
        
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, 
        // as "t" increases. It's a cheap trick that works in most situations.
        if(abs(d)<.001 || t>FAR) break; 
        
        //t += i<32? d*.75 : d; 
        t += min(d*.8, gCD); 
    }
    
    // If we've run through the entire loop and hit the far boundary, 
    // check to see that we haven't clipped an edge point along the way. 
    // Obvious... to IQ, but it never occurred to me. :)
    //if(i>=iMax - 1) t = dt.y;

    return min(t, FAR);
}

 

// Standard normal function. It's not as fast as the tetrahedral calculation, 
// but more symmetrical.
vec3 getNormal(in vec3 p, float t) {
	
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

// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with 
// limited iterations is impossible... However, I'd be very grateful if someone could 
// prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not always affordable. :)
    const int maxIterationsShad = 64; 
    
    ro += n*.0015; // Coincides with the hit condition in the "trace" function.
    vec3 rd = lp - ro; // Unnormalized direction ray.
    

    float shade = 1.;
    float t = 0.; 
    float end = max(length(rd), .0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;
    
    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = step(0., rd) - .5;
    gRd = rd;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. 
    // Obviously, the lowest number to give a decent shadow is the best one to choose. 
    for (int i = min(iFrame, 0); i<maxIterationsShad; i++){

        float d = map(ro + rd*t);
        
        
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), 
        // dist += clamp(h, .01, stepDist), etc.
        t += clamp(min(d*.8, gCD), .01, .25); 
        
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>end) break; 
    }

    // Shadow.
    return max(shade, 0.); 
}


// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n){

	float sca = 2., occ = 0.;
    for(int i = 0; i<5; i++){
    
        float hr = float(i + 1)*.125/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
    }
    
    return clamp(1. - occ, 0., 1.);    
    
}

 
void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    
    // Screen coordinates.    
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
	
    // Screen warp.
    //uv *= .96 + dot(uv, uv)*.08;
    
	// Camera Setup.
	vec3 ro = vec3(iTime/2., 0, -1.85); // Camera position, doubling as the ray origin.
	vec3 lk = ro + vec3(.0, .18, .25);//vec3(0, -.25, iTime);  // "Look At" position.
 
    // Saving the camera position.
    gRo = ro;
 
    // Light positioning.
    vec3 lp = ro + vec3(1.75, .5, 0);// Put it a bit in front of the camera.
    vec3 lp2 = ro + vec3(.35, 2, 0);// Put it a bit in front of the camera.
	

    // Using the above to produce the unit ray-direction vector.
    float FOV = 1.25; // FOV - Field of view.
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x ));
    vec3 up = cross(fwd, rgt); 

    // rd - Ray direction.
    //vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);
    mat3 cam = mat3(rgt, up, fwd);
    vec3 rd = cam*normalize(vec3(uv, 1./FOV));
    
    
    // Rotation.
	rd.xy *= rot2(-PI/10.);    

	 
    
    // Raymarch to the scene.
    float t = trace(ro, rd);
    
    // Save the block ID and object ID.
    vec4 svGID = gID;
    
    // Scene object ID. Either the pylons or the floor.
    float svObjID = objID;
    
    // Saving the block scale and local 2D base coordinates.
    vec3 svSc = gSc;
    vec2 svP = gP;
    
    // Glow.
    vec3 svGlow = glow;
    
    float svNS = gNS;
    
 	
    // Initiate the scene color to black.
    vec3 col = vec3(0);
	
	// The ray has effectively hit the surface, so light it up.
	if(t < FAR){
        
  	
    	// Surface position and surface normal.
	    vec3 sp = ro + rd*t;
	    //vec3 sn = getNormal(sp, edge, crv, ef, t);
        vec3 sn = getNormal(sp, t);
        
        // Light direction vectorw.
	    vec3 ld = lp - sp;
	    vec3 ld2 = lp2- sp;

        // Distance from respective light to the surface point.
	    float lDist = max(length(ld), .001);
	    float lDist2 = max(length(ld2), .001);
    	
    	// Normalize the light direction vector.
	    ld /= lDist;
 	    ld2 /= lDist2;
        
          
        // Obtaining the texel color. 
	    vec3 oCol; 
        
        
        // Standard material properties: Roughness, matType and reflectance.
        //
        float roughness = 1.; // Lower roughness reflects more light, as expected.
        float matType = 0.; // Dielectric (non conducting): 0, or metallic: 1.
        float reflectance = .1; // Reflective strength. // Bokeh picks up on reflectance.


        // The extruded grid.
        if(svObjID>0.){
            
            // Random coloring using IQ's short versatile palette formula.
            //float rnd = hash21(svGID.zw + .34);
            //vec3 sCol = .5 + .45*cos(6.2831853*rnd/1. + vec3(0, 1, 2)*1.5);
             
            // Texturing.
            vec3 tx = tex3D(iChannel1, sp/2., sn);
            oCol = smoothstep(.0, .7, tx);

            // Coloring according to the noise value in the raymarching function.
            oCol = mix(vec3(1, 1, 1)*oCol, oCol*vec3(.2, .25, .3), 
                       smoothstep(-.001, .001, svNS));

            // Texture based roughness.
            float grT = dot(tx, vec3(.299, .587, .114)); 
            roughness *= grT*grT*4. + .0;

            if(svObjID==2.){ oCol = tx*.5 + .5; matType = 0.; roughness *= 4.; }

            // Erosion based roughness.
            roughness += mix(0., 5., smoothstep(0., .001, svNS));


            // Edges.
            float edge = abs(svGID.y) - .01;
            edge = max(abs(sp.z + svSc.z) - .005, edge);
            edge = min(edge, abs(svSc.z) - .025);


            // Darken the sides of the maze.
            oCol = mix(oCol*.5, oCol, smoothstep(.05, 1., abs(sn.z)));

            if(svObjID==1.) oCol = mix(oCol, oCol*.1, 1. - smoothstep(0., .005, edge));
        
        }
        else {
            
            // The dark floor in the background. Hidden behind the pylons, but
            // I'm including it anyway.
            vec3 tx = getTex(iChannel1, sp.xy);
            oCol = vec3(1, .8, .6)/4.*(tx*2. + .0);
            
            // Noise based coloring.
            oCol = mix(vec3(1, 1, 1)*oCol, oCol*vec3(.3, .2, .1), smoothstep(-.001, .001, svNS));
            
           
             float edge = abs(svGID.y) - .01;
             oCol = mix(oCol, oCol*.1, 1. - smoothstep(0., .0075, edge));
            
            float grT = dot(tx, vec3(.299, .587, .114)); 
            roughness *= grT*grT*4. + .0;
            
            //reflectance = 1.;
            //matType = 1.;
            
        
            
        }
        
        //oCol /= 1.5;
        
        //if(abs(sn.z)<.5){
        // A bit of backfill light.
        vec3 fillDir = vec3(-ld.xy, 0.);
        vec3 fillDir2 = vec3(-ld2.xy, 0.);
        float bl = max(dot(fillDir, sn), 0.);
        float bl2 = max(dot(fillDir2, sn), 0.);
         
        // Apply less to the ground than the wall material.
        float amp = svObjID>0.? 1. : .25;
        amp *= 1. - smoothstep(0., .9, abs(sn.z));
        oCol = mix(oCol, oCol + vec3(1, .2, .05)*amp*4., bl);
        oCol = mix(oCol, oCol + vec3(0, .25, 1)*amp*4., bl2);
        //} 
        
        // Shadows and ambient self shadowing.
    	float sh = softShadow(sp, lp, sn, 16.);
        float sh2 = softShadow(sp, lp2, sn, 16.);
 
    	float ao = calcAO(sp, sn); // Ambient occlusion.
	    
	    // Light attenuation, based on the distances above.
	    float atten = 4./(1. + lDist*lDist*lDist*lDist*.2);
	    float atten2 = 4./(1. + lDist2*lDist2*lDist2*lDist2*.2);
    	
         
        /*
        // Cheap specular reflections. Requires loading the "Forest" cube map 
        // into "iChannel0".
        float speR = pow(max(dot(normalize(ld - rd), sn), 0.), 5.);
        float speR2 = pow(max(dot(normalize(ld2 - rd), sn), 0.), 5.);
        vec3 rf = reflect(rd, sn); // Surface reflection.
        vec3 rTx = texture(iChannel0, rf).zyx; rTx *= rTx;
        oCol = oCol/2. + oCol*speR*rTx*2.+ oCol*speR2*rTx*2.;
        */
         
        
        // I wanted to use a little more than a constant for ambient light this 
        // time around, but without having to resort to sophisticated methods, then I
        // remembered Blackle's example, here:
        // Quick Lighting Tech - blackle
        // https://www.shadertoy.com/view/ttGfz1
        // Studio.
        float am = pow(length(sin(sn*2.)*.5 + .5)/sqrt(3.), 2.)*1.5; 
        // Outdoor.
        //float am = length(sin(sn*2.)*.5 + .5)/sqrt(3.)*smoothstep(-1., 1., -sn.z); 


        // Cook-Torrance based lighting. The last term is specular coloring.
        vec3 ct = BRDF(oCol, sn, ld, -rd, matType, roughness, reflectance, vec3(1));
        vec3 ct2 = BRDF(oCol, sn, ld2, -rd, matType, roughness, reflectance, vec3(1));

        col = vec3(0);
        // Combining the ambient and microfaceted terms to form the final color:
        // None of it is technically correct, but it does the job. Note the hacky 
        // ambient shadow term. Shadows on the microfaceted metal doesn't look 
        // right without it... If an expert out there knows of simple ways to 
        // improve this, feel free to let me know. :)
        vec3 lCol = 2.*vec3(.2, .4, 1);
        vec3 lCol2 = 2.*vec3(1, .3, .4);

        // Extra color.
        //lCol = mix(lCol, lCol.yxz*lCol.yxz, -uv.y + .5);
        //lCol2 = mix(lCol2, lCol2.yxz*lCol2.yxz, -uv.y + .5);
        
        // Adding in the glowing embers.
        oCol *= (glow + 1.); 
 
         
        // Combining the two light passes.   
        col = lCol*(oCol*am*(.5 + sh*.5) + ct*(sh))*atten;        
        col += lCol2*(oCol*am*(.5 + sh2*.5) + ct2*(sh2))*atten2; 

      
        // Dark debug.
        //col = lCol*oCol*(glow/8. + .1); 
        //col += lCol2*oCol*(glow/8. + .1);         
 
 
        
        // Shading.
        col *= ao;
          
	
	}
    
    
    // Applying fog: This fog begins at 90% towards the horizon.
    col = mix(col, vec3(0), smoothstep(.25, .9, t/FAR));
 
    
     
    #ifdef SHOW_2D_PATTERN
    vec4 b = exMaze(vec3(uv*4. + vec2(0, iTime/4.), 1));
    float rnd = hash21(b.zw + .34);
    vec3 sCol = .5 + .45*cos(6.2831853*rnd/8. + vec3(0, 1, 2));
    sCol = mix(sCol.xzy, sCol.yzx, uv.y);
    col = mix(vec3(0), sCol, 1. - smoothstep(0., 1./iResolution.y, b.y/4. + .003));
    #endif
    
 
    // Rough gamma correction.
    fragColor = vec4((max(col, 0.)), t);
    
	
}