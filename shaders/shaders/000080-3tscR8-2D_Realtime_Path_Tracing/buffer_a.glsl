// Buffer A (buffer) — 2D Realtime Path Tracing by Shane
// https://www.shadertoy.com/view/3tscR8

/*

	The 2D path tracing code itself...  I'm not even sure that
	you'd strickly call it path tracing, but it's randomly 
	sampled rays sent off in random directions that are 
	reflected off of objects according to their surface 
	properties, so close enough. Obviously, if you want a 
	treatise on the process itself, there are heaps of awesome
	examples on here already.

	On a side note, I intend to put up a few myself at some 
	stage.


*/



float gridField(vec2 p){
    
    vec2 ip = floor(p);
    p = abs(p - ip - .5);

    return abs(max(p.x, p.y) - .5) - .003;
}


// Reading the distance field from the texture map.
float map(vec2 p){
	// Reading distance fields from a texture means taking scaling into
    // consideration. If you zoom coordinates by a scalar (4, in this case), 
    // you need to scale the return distance value accordingly... Why does 
    // everything have to be so difficult? :D
    const float sc = 4.;
    vec4 tex = tx(iChannel0, p/sc);
    gIP = tex.yz; // The object ID is stored in the YZ channels..
    return tex.x*sc;
}



#define FAR 8.
#define DELTA .003
#define RSF 1.
#define RSF_SHAD 1.

float trace(vec2 o, vec2 r){
    
    // Raymarching.
    float d, t = 0.;
    
    // 96 iterations here: If speed and complilation time is a concern, choose the smallest 
    // number you can get away with. Apparently, swapping the zero for min(0, frame) can
    // force the compliler to not unroll the loop, so that can help sometimes too.
    for(int i=0; i<16; i++){
        
        // Surface distance.
        d = map(o + r*t);
        
        // In most cases, the "abs" call can reduce artifacts by forcing the ray to
        // close in on the surface by the set distance from either side. Because this is
        // two dimensional, it appears to be necessary -- rather than an option -- to avoid 
        // negative values... I haven't thought it through enough, but basically, 2D 
        // raymarching, or whatever you wish to call the process, works differently.
        //
        // Equivalent to abs(d)<DELTA... I'll assume it's faster, but I can't be sure.
        if(d*d<DELTA*DELTA || t>FAR) break;
        //if(d<DELTA || t>FAR) break;
        
        // No ray shortening is needed here, and in an ideal world, you'd never need it, but 
        // sometimes, something like "t += d*.7" will be the only easy way to reduce artifacts.
        t += d*RSF;
    }
    
    t = min(t, FAR); // Clipping to the far distance, which helps avoid artifacts.
    
    return t;
    
}

float lightTrace(vec2 o, vec2 r, float maxDst){
    
    // Raymarching.
    float d, t = 0.;
    
    
    // 96 iterations here: If speed and complilation time is a concern, choose the smallest 
    // number you can get away with. Apparently, swapping the zero for min(0, frame) can
    // force the compliler to not unroll the loop, so that can help sometimes too.
    for(int i=0; i<16; i++){
        
        // Surface distance.
        d = map(o + r*t);
        
        // In most cases, the "abs" call can reduce artifacts by forcing the ray to
        // close in on the surface by the set distance from either side.
        if(d<0. || t>maxDst) break;
        
        
        // No ray shortening is needed here, and in an ideal world, you'd never need it, but 
        // sometimes, something like "t += d*.7" will be the only easy way to reduce artifacts.
        t += d*RSF_SHAD;
    }
    
    //t = min(t, maxDst); // Clipping to the far distance, which helps avoid artifacts.
    
    return t;
    
}

/*
float shadowTrace(vec2 o, vec2 r){
    
    // Raymarching.
    float d, t = 0.;
    
    
    // 96 iterations here: If speed and complilation time is a concern, choose the smallest 
    // number you can get away with. Apparently, swapping the zero for min(0, frame) can
    // force the compliler to not unroll the loop, so that can help sometimes too.
    for(int i=0; i<16;i++){
        
        // Surface distance.
        d = map(o + r*t);
        
        // In most cases, the "abs" call can reduce artifacts by forcing the ray to
        // close in on the surface by the set distance from either side.
        if(d<0. || t>FAR) break;
        
        
        // No ray shortening is needed here, and in an ideal world, you'd never need it, but 
        // sometimes, something like "t += d*.7" will be the only easy way to reduce artifacts.
        t += d*RSF_SHAD;
    }
    
    t = min(t, FAR); // Clipping to the far distance, which helps avoid artifacts.
    
    return t;
    
}
*/

// Standard 2D normal function.
vec2 nr(in vec2 p){
    
	const vec2 e = vec2(.001, 0);
	return normalize(vec2(map(p + e.xy) - map(p - e.xy), 
                          map(p + e.yx) - map(p - e.yx)));
}

// Translating the camera.
vec2 getCamTrans(float t){ return vec2(sin(t/8.)/8., -t/6.); }

// Rotating the camera.
mat2 getCamRot(float t){
    
    //return rot2(0.);
    return rot2(cos(t/4.)/8.);
}


void mainImage(out vec4 fragColor, in vec2 fragCoord){

    // Aspect correct screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    
    
    // The overall scene color.
    vec3 col = vec3(0);
    
   
    vec2 cam = getCamTrans(iTime);
    mat2 camRot = getCamRot(iTime);
    
    // Threading a light through the moving pattern. The velocity is 1/6 units per second, and the
    // zoom factor is 8, so considering that the angular segment velocity is half that of the camera
    // velocity... I'm just going to take a few guesses... Can't believe that actually worked. Yay. 
    // We're doing physics. :D
    vec2 lp = vec2(0) - vec2(0, cam.y - 2./8.); // 2./texMapScale.
    vec2 rd;
    
 
    // Rotating and moving the canvas. A 2D "to" and "from" setup would be better, but this
    // will do for the purpose of the demonstration.
    uv = uv*camRot - cam;
    
    // Making a copy of the rotated coordinates for later use.
    vec2 rUV = uv;
    
    float sf = 1./iResolution.y*4.;
    float grid = gridField(uv*2.);
    
    
    #ifndef DISTANCE_FIELD_ONLY
 
    // Number of samples and the number of reflective bounces. As you can see, there are
    // far fewer than you'd expect.
    const int SAMPLES = 4;
    const int BOUNCES = 2;
    
    // Sample loop.
    for (int i =0; i < SAMPLES; i++){
        
        float fi = float(i);
        
        // Reflection factor: Basically, this controls the the reflected amount. Normally,
        // you'd have reflection coefficients for each object material, etc, but we're 
        // trying to keep things simple, so this will simply be reduced globally per 
        // reflective iteration... It's not that important. :)
        float refFactor = 1.; 
        
        // Random time.
        float fTm = fract(iTime) + fract(float(iFrame)*.01);
        
        // The initial jittered ray origin or camera point for this sample.
        vec2 ro = uv + (hash22(uv + fi + fTm + .35) - .5)/iResolution.y*1.;
        
        // The initial random unit direction ray for this sample.
        float ti = (fi + hash21(uv + fi + fTm))*6.2831/float(SAMPLES);
        rd = vec2(cos(ti), sin(ti));
        
        // The sample color.
        vec3 sCol = vec3(0);
        
        // Bounce loop.
        for(int j = 0; j<BOUNCES; j++){
            
            // Bounce trace.
            float t = trace(ro, rd);
            vec2 svID = gIP; // Saving the ID here.
            
            float fj = float(j);
            vec3 rCol = vec3(0);
            vec2 sp = ro + rd*t;
            
            if(t<FAR){
                
                // The randomly distributed unit direction vector: For 2D stuff, this seems 
                // to be the accepted way to go about it. Basically it's just a normalized
                // vector in a random circular direction, which makes sense on a 2D plane.
                float fij = fi*float(BOUNCES) + fj;
                float tij = (fij + hash21(uv + fij + fTm))*6.2831/float(SAMPLES*BOUNCES);
                vec2 rndRD = vec2(cos(tij), sin(tij));
                
                // Basic lighting stuff... I'm not sure it makes perfect sense in a 2D 
                // environment, but it'll do.
                //
                vec2 sn = nr(sp); // Normal.
                vec2 ld = (lp - sp); // Light direction.
                float lDist = length(ld); // Light distance.
                ld /= lDist; // Normalizing.
                float udif = dot(ld, sn); // Unsigned diffuse value.
                float spec = pow(max(dot(reflect(ld, sn), rd), 0.), 32.); // Specular.

                // You could do much fancier things with the object ID, but
                // I'm simply giving the rails different colors.
                vec3 oCol = svID.x < .5? vec3(.25, .5, 1) : vec3(1.5, .3, .15);
                 
                // No textures, but you could have them.
                //vec3 tx = texture(iChannel2, uv).xyz; tx *= tx;
                //tx = smoothstep(.0, .5, tx);
                
                
                 
                // Sending a ray from the hit point out toward the light.
                // Some people might call it shadowing. :)
                #ifdef LIGHT_TRACE
                vec3 dL = vec3(0);
                //vec3 shad = vec3(1);
                if(udif>0.){
                    float maxDist = lDist;//lDist; // FAR.
                    // Lamest cone sampled light ray ever. :)
                    vec2 cnLD = normalize(mix(ld, rndRD, .05));
                    float rt = lightTrace(sp + sn*DELTA*2., cnLD, maxDist);
                    //float rt = shadowTrace(sp + sn*DELTA*2., cnLD);
                    
                    // If we've reached the light, light things up. It's
                    // slightly different to the shadowed approach which 
                    // dictates that you darken things if you hit an object.
                    if(rt >= maxDist - DELTA) {
                        dL += pow(udif, 4.)*2.5;///(1. + rt*rt*4.);//
                         
                    }
                    //if(rt < maxDist) shad = vec3(0);
                }
                #endif
                
                
                // Shading and texture option. Not used.
                //float sh = max(.2 - dfIJ/.01, 0.);
                //oCol = mix(oCol, oCol*tx, (1. - step(0., -(dfIJ))));
                
                
                #ifdef LIGHT_TRACE
                // Apply the light traced light. Nicer, but more expensive. By the way,
                // this is all fake lighting. The specular is there because I was bored,
                // and it looked OK, so don't take any of this at face value.
                rCol = oCol*(dL + spec); 
                #else
                // Just some diffuse and specular light.
                float dfIJ = map(sp);
                rCol = oCol*(pow(max(udif, 0.), 4.)*2. + spec);
                rCol *= 1. - smoothstep(0., .0005, dfIJ)*.75; // Darkenging the background
                #endif
               
                // Light attenuation.
                rCol *= 4./(1. + lDist*lDist*4.);
                
                
                #ifdef SHOW_LIGHT
                // Displaying the moving light.
                rCol = mix(rCol, rCol*5., 1. - smoothstep(0., sf*4., length(uv - lp)));
                #endif
                
              
                // Mostly reflective, but adding in a little roughness.
                rd = normalize(mix(reflect(rd, sn), rndRD, .05)); 

                // Updating the ray origin to the hit point, then bumping the ray
                // off the surface to avoid self collisions.
                ro = sp + sn*DELTA*2.;

            }
            
            #ifdef SHOW_GRID
            // Display the grid as a background pattern.
            rCol = mix(rCol, rCol*2., (1. - smoothstep(0., sf*3., grid - .002))*.5);
            rCol = mix(rCol, vec3(0), (1. - smoothstep(0., sf, grid))*.9);
            #endif
            
             
            // Blending in the bounce color. Additive blending is an option, but
            // I'm mixing.
            sCol = mix(sCol, rCol, 1./float(1 + j)*refFactor);
            //lCol += rCol;
            refFactor *= .9;
            
            if(t>FAR-DELTA) break;
           
        }
         
        
        // Technially, this should be capped to one, but I wanted to really exaggerate
        // the effect.
        col += min(sCol, 2.);
        
        
    }
    
    // Divide by the sample number.
    col /= float(SAMPLES); 
    
    // If you cap the reflective colors, this isn't necessary. You might also choose
    // not to cap them, then cap here, etc. Too many choices. :)
    //col = min(col, 1.);
 
    
    
    #ifdef TEMPORAL_REPROJECTION
    // Camera reprojection. This is basically the crux of the example, and as you 
    // can see, it's not that involved. In essence, we're calculating where we 
    // believe the previous frame should be placed on the sceen in relation to the
    // new one -- Effectively, we'd like to place it directly under the new one. 
    // To do that, we index into the stored buffer at the current position minus 
    // the frame to frame camera difference.
    //
    // On a side note, I think the calculations are correct, but it's been a while 
    // since I've done this, so if there's something that doesn't look quite right,
    // it probably isn't... And feel free to let me know that. It's the only way
    // I'll learn not to be stupid. :D
    
    // Recalculating the UV coordinates.
    uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
   
    // Frame to frame camera translation difference.
    vec2 camDelta = getCamTrans(iTime - iTimeDelta);
    vec2 camOffs = -(camDelta - cam);
    
    // Frame to frame camera rotation difference.
    mat2 rotDelta = getCamRot(iTime - iTimeDelta);
    vec2 rotOffs = -(rotDelta*uv - camRot*uv);
    
    
    // Offsetting the UV coordinates accordingly, then projecting to the current
    // screen coordinates, which have to range from zero to one along X and Y.
    vec2 cuv = (uv - rotOffs - camOffs)*vec2(iResolution.y/iResolution.x, 1)  + .5;
    
    // Two differently rotated-translated rectangles are more than likely not going
    // to line up, so you need to check boundaries. You might note a bit of smudging
    // on the screen borders. Usually, your offscreen buffer would be larger, or the
    // onscreen buffer will be smaller. Basically, I could put a screen border around
    // everything, but I don't think it's that noticeable.
    if(cuv.x<0. || cuv.x>1.) cuv.x = uv.x*iResolution.y/iResolution.x + .5;
    if(cuv.y<0. || cuv.y>1.) cuv.y = uv.y + .5;
    vec3 tCol = texture(iChannel1, cuv).xyz;
    
    
    // Mixing in the new frmae with the previous one. In fact, we're cycling about
    // 8 screens. This effectively gives you 8 times the sampling. So, if your 
    // original sample count is just 8, this would boost it to 64. The reason you
    // don't go too high is that temporal reprojection is just an estimation, so
    // eventually, temporal screen lag will catch up with you.
    const float totTimeFrames = 8.;
    col = mix(tCol, col, 1./totTimeFrames);
    
    #endif
    
    #else
    
    // Display the distanc field only.
    
    // For anyone interested in the distance field map itself, uncomment the
    // DISTANCE_FIELD_ONLY option, and you'll see that it's nothing more than 
    // a moring Voronoi texture or moving Voronoi Truchet arrangement.
    //
    vec3 txM = tx(iChannel0, rUV/4.).xyz;
    col = vec3(0) + txM.x*repSc/2.;
    #ifdef SHOW_GRID
    col = mix(col, col*2., (1. - smoothstep(0., sf*3., grid - .0035))*.5);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, grid))*.9);
    #endif 
    
    float sh = max(.65 - txM.x*repSc*4., 0.);
    vec3 tCol = txM.y<.5? vec3(.15, .4, 4) : vec3(4, .4, .1);
    
    col = mix(col, vec3(0), (1. - smoothstep(0., sf, txM.x*repSc/2. - .03)));
    col = mix(col, tCol*sh, (1. - smoothstep(0., sf, txM.x*repSc/2.)));
    #endif 
    
    // Output to the buffer.
    fragColor = vec4((max(col, 0.)), 1);
}