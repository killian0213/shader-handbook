// Buffer A (buffer) — 3D Diffusion Automata by Shane
// https://www.shadertoy.com/view/cl3yDN



void mainImage(out vec4 fragColor, vec2 fragCoord){

    // Reject any pixels outside the wrapping area to lessen the GPU load.
    if(fragCoord.x>cubeMapRes || fragCoord.y>cubeMapRes) discard;


    // Wrapped coordinates... Kind of redundant here, since we're rejecting
    // pixels outside this area range, but it's good practice.
    vec2 u = mod(fragCoord, cubeMapRes);
    vec4 col;
    
    // Convert the 2D canvas coordinates to 3D coordinates.
    vec3 p = convertCoord(u);

    
    if(textureSize(iChannel0, 0).x<2 || iFrame==0){ // || iMouse.z>0.
    
        // Initial setup conditions:
        
        // Initial cell index: This is a 2D position (in float form), which 
        // allows for diffusion of pictures. However, any initial cell 
        // identifier (like a random number) can be put here.
        col.x = p.x + p.y*wrap + p.z*wrap*wrap;
        //col.x = p.x + (p.y + p.z*wrap)*wrap;
        //col.x = floor(u.x/4) + floor(u.y/4.)*iResolution.y;
        // Direction index. Clockwise from the left. 0,1,2,3.
        col.y = 0.; // Any number will do.
        // When conditions are met, the cell object will transfer from one
        // cell to the next via an interpolating mechanism that ranges
        // between zero and one.
        //
        // Motion timer [0,1] range. Thanks, SnoopethDuckDuck.
        col.z = 1.; // Put it into "accepting new transfer" mode.
        // Initial random active/inactive threshold. It could be pattern
        // based, random, or whatever you wish. This one is obviously random.
        col.w = step(.4, hash31(p + .11)); // Inactive or active: 0 or 1.
        
           
    } 
    else {
    
        // Obtain the current stored cell states.
        col = texelFetch(iChannel0, ivec2(u), 0);  
        
        // Obtain the current stored cell states.
        //vec2 uv = convertCoord(p);
        //col = texelFetch(iChannel0, ivec2(uv), 0);  

        
        // I wanted the cells to wrap along the XY plane, but at the same 
        // time be clamped to the near and far Z walls. The solution is very
        // simple... but still took me an hour. :) In the XY directions, let
        // the cells objects move in all six directions. However, if they hit 
        // the front or back Z positions, don't allow them to move in the Z 
        // direction... OMG, that was so obvious. :D
        float maxDirections = (p.z<0. || p.z>=wrap)? 4. : 6.;
        
        // Obtain the random direction for this pixel at this point in time.
        vec3 dir = rndDir(vec4(p, iFrame), maxDirections); 
  
        
        // Use the random direction above to move to the neighboring cell in that 
        // direction, then obtain the random direction for that cell... That was a 
        // bit wordy, but a lot of this stuff depends on understanding it.
        //
        vec3 nP = p + dir; // Neighboring cell position.
        // Neighboring cell movement needs to be restricted along the far Z planes also.
        if(nP.z<0. || nP.z>=wrap) maxDirections = 4.;
        // The random direction value in the neighboring cell... Not the direction
        // to the neighboring cell, which is a different entity.
        vec3 dirNgbr = rndDir(vec4(mod(nP, wrap), iFrame), maxDirections); 
        // Obtain the cell information for that neighbor as well.
        //vec4 colNgbr = texelFetch(iChannel0, ivec2(mod(p + dir, wrap)), 0);
        vec2 uvN = convertCoord(mod(nP, wrap));
        vec4 colNgbr = texelFetch(iChannel0, ivec2(uvN), 0);
         
        
        // If a transfer is still in progress, update the transfer timer -- which,
        // in turn, will be converted to cell object position.
        if (col.z < 1.){ 
            // Increment the motion timer.
            
            // Converting to 3D cell coordinates.
            vec3 ip = mod(vec3(col.x, floor(col.x/wrap), floor(col.x/(wrap*wrap))), wrap);
            
            float rnd = hash31(ip + .2); // Random number for each cell.
            float dS =  (1. - rnd*.66)*3.*iTimeDelta; // Incremental distance change.
            col.z = min(col.z + dS, 1.); // Increasing the distance, whilst not overshooting.
        }
        // Both cells (current and neighbor) need to have completed a motion transfer 
        // and be awaiting te next transfer ("col.z == 1." and "colNgbr.z == 1").
        //
        // The transfer between cells needs to be valid (the cell and neighbor directions 
        // need to point toward each other). Finally, two empty or two full cells obviously 
        // can't cell swap, which leaves full to empty, or empty to full. In other words, 
        // an active cell can only transfer to an inactive one, or an inactive cell can only
        // receive a transfer from a full one (Ie. col.a != colNgbr.a).
        else if(colNgbr.z == 1. && dir == -dirNgbr && col.w != colNgbr.w) {
    
            // An inactive cell will receive the index of the transferring
            // active cell.
            if (col.w == 0.) col.x = colNgbr.x; // New index.
            col.y = dirToIndex(dir); // Store the random direction index at this time point.
            col.z = 0.;          // Reset the timer back to the start.
            col.w = colNgbr.w;   // The inactive cell will now be active, and vice versa.
 
        }
        
        
    }
    
    // Store the updated values to the buffer.
    fragColor = col;
}
