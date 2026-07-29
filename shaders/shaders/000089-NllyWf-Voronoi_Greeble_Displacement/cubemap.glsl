// Cube A (cubemap) — Voronoi Greeble Displacement by Shane
// https://www.shadertoy.com/view/NllyWf


// It can be a bit fiddly filling all four channels in at once, but thankfully, this is
// all calculated at startup. The idea is to put the function you wish to use in the
// middle of the loop here, instead of writing it out four times over.
vec4 funcFace0(vec3 p){
   
    
    vec4 col;
    
    vec3 q = p;
    
    for(int i = 0; i<4; i++){
        
        // Texture coordinates for this iteration.
        q.xy = mod(floor(p.xy*cubemapRes) + vec2(i&1, i>>1), cubemapRes)/cubemapRes;
        
        // Subtle, wrapped noise perturbation. Like everything added to the texture,
        // texture offsets need to be wrapped as well.
        gSc = vec3(32);
        float ns = n3DT(q*gSc);
        float ns2 = n3DT(q*gSc + .35);
        gSc = vec3(16.);
        ns = mix(ns, n3DT(q*gSc), 1./3.);
        ns2 = mix(ns, n3DT(q*gSc + .35), 1./3.);
        q.xy += (vec2(ns, ns2) - .5)*.0025;

        
        // Wrapped multilayer tertiary order Voronoi.
        gSc = vec3(8);
        #ifdef RAND_ROT
        vec3 rotF = vec3(.03); // Rotation factor - Range: [0, 1].
        #else
        vec3 rotF = vec3(0);
        #endif
        //vec3 sc = vec3(1, 1, 2);
        vec3 sc = vec3(1, 1, 1);
        int rowOffset = 0;
        vec3 v = Voronoi(q*gSc, sc, rotF, 1./1., rowOffset, 1);
     
        
        #if VARIATION == 0
        float vor = abs(v.x - .05);
        #elif VARIATION == 1
        float vor = abs(v.y - .15);
        #elif VARIATION == 2
        float vor = abs(v.z - v.y - v.x);
        #else 
        float vor = abs((v.y - clamp(.15 - v.z - v.x, 0., .25)) - .15);
        #endif
   
        #ifdef CORRUGATE
        // Adding subtle corrugation. It looks interesting, but not for this example.
        vor = mix(vor, floor(vor*31.999)/31., .15);
        #endif
        
        vor = min(vor*1.35, 1.); // Increasing the slope and capping for a beveled effect.
        
        float sf = .4; // Fine edge smoothing.
        
        #ifdef LINES
        // Adding some cell border detail.
        vor = mix(vor, smoothstep(-sf, sf, (max(1. - vor*42./gSc.x, 0.) - 1./2.)), .15);//
        #endif
        
        //if(hash33(vIP).x>.5) vor = abs(.5-vor);//abs(fract(v.x) - .5)*2.;   

        
        col[i] = vor;
        
        
        
        sf = .1;
        gSc = vec3(128);//
        rotF = vec3(.03);
        //vec3 sc = vec3(1, 1, 2);
        // Putting the height from above into the Z slot.
        sc = vec3(1, 1, 1);//vor*.25 + .75
        rowOffset = 1;
        v = Voronoi(q*gSc, sc, rotF, 1./4., rowOffset, 1);
        
        vor = abs(v.x - .2);
 
        float v2 = mix(min(vor*1.5, 1.), smoothstep(-sf*1., sf*1., (max(1. - vor*64./gSc.x, 0.) - 1./2.)), .15);
        col[i] = mix(col[i], vor, 1./96.);// - col[i]
        //col[i] = ov;
 
        
    }
    
    // Return the four function values -- One for each channel.
    return col;
    
}


// Cube mapping - Adapted from one of Fizzer's routines. 
int CubeFaceCoords(vec3 p){

    // Elegant cubic space stepping trick, as seen in many voxel related examples.
    vec3 f = abs(p); f = step(f.zxy, f)*step(f.yzx, f); 
    
    ivec3 idF = ivec3(p.x<.0? 0 : 1, p.y<.0? 2 : 3, p.z<0.? 4 : 5);
    
    return f.x>.5? idF.x : f.y>.5? idF.y : idF.z; 
}



void mainCubemap(out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir){
    
    
    // UV coordinates.
    //
    // For whatever reason (which I'd love expained), the Y coordinates flip each
    // frame if I don't negate the coordinates here -- I'm assuming this is internal, 
    // a VFlip thing, or there's something I'm missing. If there are experts out there, 
    // any feedback would be welcome. :)
    vec2 uv = fract(fragCoord/iResolution.y*vec2(1, -1));
    
    // Adapting one of Fizzer's old cube mapping routines to obtain the cube face ID 
    // from the ray direction vector.
    int faceID = CubeFaceCoords(rayDir);
  
  
    // Pixel storage.
    vec4 col = vec4(0);
    
    // Precalculation flag: GPUs are annoying. Sometimes, they'll will calculate
    // both the "if" and "else" statements every time. The "if" part here is extremely
    // expensive, so we don't want that. The solution is to not have an "if-else"
    // statement at all.
    int preCalc = 0;
    

    // Initial conditions -- Performed upon initiation.
    //if(abs(tx(iChannel0, uv, 5).w - iResolution.y)>.001){
    //if(iFrame<1){
    //
    // Great hack, by IQ, to ensure that this loads either on the first frame, or in the
    // event that the texture hasn't loaded (this happens a lot), wait, then do it...
    // Well kind of. Either way, it works. It's quite clever, which means that it's something 
    // I never would have considered. :)
    if(textureSize(iChannel0,0).x<2 || iFrame<1){
        
        // This is part of an ugly hack that attempts to force the GPU compiler
        // to not unroll the Voronoi loops. Not sure if it'll work, but I'm 
        // trying it anyway, in the hope to get compiler times down on some
        // machines. For the record, this takes about 3 seconds to compile on 
        // my machine.
        frame0 = iFrame;
        
 
        
        
        // Fill the first cube face with a custom 3D function.
        if(faceID==0){
            
            //vec3 p = convert2DTo3D(uv);      
            vec3 p = vec3(uv, 0);      
            
            col = funcFace0(p);
            //col = mix(col, 1.-funcFace0(p*2.), 1./16.);
            
            preCalc = 1;
           
        }

        /*
        // Last channel on the last face: Used to store the current 
        // resolution to ensure loading... Yeah, it's wasteful and it
        // slows things down, but until there's a reliable initiation
        // variable, I guess it'll have to do. :)
        if(faceID==5){
            
            col.w = iResolution.y;
        }
        */

        
    }
    
    
    if(preCalc == 0 && faceID == 0){

        if(faceID == 0) col = texture(iChannel0, vec3(-.5, uv.yx - .5));
        //col = tx(iChannel0, uv, faceID);
    }
    
    
    // Update the cubemap faces.
    fragColor = col;
    
}

