// Cube A (cubemap) — Asteroid Debris by Shane
// https://www.shadertoy.com/view/tsGXWm


// The cubemap routine. 

void mainCubemap(out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir){
 
    // UV coordinates.
    // 
    // I'm guessing here, but in this particular tab, "iResolution.xy" is
    // simply the dimension of the cubemap faces, or 1024 by 1024. This 
    // caused me a lot of confusion for a while. :)   
    //
    // For whatever reason (which I'd love expained), the Y coordinates flip each
    // frame, if I don't negate the coordinates here -- I'm assuming this is internal, 
    // a VFlip thing, or there's something I'm missing. If there are experts out 
    // there, any feedback would be welcome. :)
    vec2 uv = fract(fragCoord/iResolution.y*vec2(1, -1));
    
   
    // Color variable: Technically, it's not holding colors, but rather isovalues.
    vec3 col = vec3(0); 
    
    
    // Flag the initialization frame. The calculations below are only performed 
    // once, which is just as well, because they're prohibitively expensive to put
    // in a raymarching loop. Trust me, I tried, and my computer's still not talking
    // to me. :D
    //
    // To my knowledge, this is the only way to guarantee that the program
    // doesn't continue on without loading everything in -- Surely, there's
    // a better way, so if anyone knows of one, feel free to let me know.
    //
    if(abs(tx(iChannel0, uv).w - iResolution.y)>.001){
    // I wish it were a guarantee, because it's heaps easier, but it's not.
    //if(iFrame==0){ 
         
        // Convert the standard UV coordinates to to a voxel in a 100 sided
        // cube. I've seen a few 3D packing examples that convert the "rayDir"
        // vector to cube faces, etc, but it's not necessary here.
        vec3 p = convertCoord(uv);
        
        
        // It took me a while to convince myself that the wrapping scales only
        // need to be whole numbers to wrap on a 100 sided cube. They don't need 
        // to be factors of 100... I'm kind of mostly cautiously sure of that. :D
        //
        // This particular example needs to wrap. Hence the wrapping variables (gSc).
        // 
        
        // Isovalue one. Just a couple of layers of gradient noise. It's used as a
        // base structure to mold the rocks to.
        gSc = 12.;
        float c = gradN3D(p*gSc);
        gSc = 24.;
        c = c*.66 + gradN3D(p*gSc)*.34;
 

        // The Voronoi and gradient noise middle-range layers. Used in the distance
        // function, then reused to bump map a bit of detail onto the asteroid field
        // rocks -- or whatever you want to call them.
        gSc = 10.;
        vec3 v2 = Voronoi(p*gSc, vec3(0));
        gSc = 40.;
        float c2 = gradN3D(p*gSc);
        gSc = 80.;
        c2 = c2*.66 + gradN3D(p*gSc*2.)*.34;
        c2 = mix(1. - smoothstep(0., .35, v2.x - .01), c2, .5);

       
        
        gSc = 6.;
        vec3 v3 = Voronoi(p*gSc, vec3(0));
        // X and Y prefer different smoothstep values.
        float c3 = smoothstep(0., .525, v3.x);
        //float c3 = smoothstep(0., .7, v3.y);
  
        
        // Load in the isovalues.
        col = vec3(c, c2, c3);
        
       
    }    
    else {
        
        // The cubemap isovalues were all calculated in the previous frame, so
        // all that's needed from this point is a single texel retrieval. I think
        // there's a way to do it with discard as well, but I'm not positive.
        col = tx(iChannel0, uv).xyz;
  
    }
     
   
    // Storing the three isovalues in the first three channels, and the resolution
    // in the forth for initialization. It would be nice if Shadertoy had a guaranteed
    // varibale to flag the first frame after all textures have loaded. I remember
    // doing this with my own backend code, so I know it's easier said than done, but
    // it's worth it.
    fragColor = vec4(clamp(col, -1., 1.), iResolution.y);
    
}

