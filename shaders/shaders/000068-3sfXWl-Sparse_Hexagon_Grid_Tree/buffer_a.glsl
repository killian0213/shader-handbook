// Buffer A (buffer) — Sparse Hexagon Grid Tree by Shane
// https://www.shadertoy.com/view/3sfXWl


// Sparse hexagon tree production.


// Texel fetch.
vec4 tx(vec2 uv){ 
    
    uv = mod(uv, GRID_SIZE);
    return texelFetch(iChannel0, ivec2(uv), 0);
}

void mainImage(out vec4 fragColor, vec2 fragCoord){


    // If the texture is not loaded, or we're on the first frame
    // or the mouse-down button has been hit, initiate the buffer.
    if(textureSize(iChannel0, 0).x<2 || iFrame==0 || iMouse.z>0.){
        
        // Zero out.
        vec4 rVal = vec4(0);
        vec2 ip = floor(fragCoord);
        //ip = mod(ip, GRID_SIZE);
        #if 0
        // Starter value. One one, so only one tree is formed.
        if(length(ip - floor((1./scale)/2.)) < 0.01) rVal.x = .5;
        //if(ip == vec2(floor(1./scale/2.))) rVal.x = .5;
        #else
        // Repetitive starter values, forming several trees.
        // In this case, it'll be four.
        vec2 repIp = ip;
        float rSc = GRID_SIZE/2.;
        //if(mod(floor(repIp.y/rSc), 2.)<.5) repIp.x += rSc/2.; // Offset rows.
        repIp = mod(repIp, rSc);
        if(repIp.x == 0. && repIp.y == 0.){ 
            rVal.x = .5;
            // Random ID.
            float colID = hash21(ip*scale + .4213);
            rVal.y = (ip.y*2. + ip.x)/rSc/rSc;//colID;
        }
        #endif 
        
        fragColor = rVal;

        
    }
    else {
    
        // Deliberately slowing the proces down, so that you can see
        // the pattern forming. Without this, that pattern would 
        // form almost instantly.
        if(mod(floor(iTime*160.), 4.)>.5){
        
           fragColor = tx(fragCoord);
           return;
        }
    
        // Wrapped grid coordinate.
        vec2 u = mod(fragCoord, GRID_SIZE);
        
        // Obtain the current stored cell states.
        vec4 a = texelFetch(iChannel0, ivec2(u), 0);  
        
        // Obtain the random direction for this pixel at this point in time.
        vec2 dir = rndDir(vec3(u, iFrame)); 
        // Use the random direction above to move to the neighbor in that direction,
        // then obtain the random direction for that cell.
        vec2 dirNgbr = rndDir(vec3(mod(u + dir, GRID_SIZE), iFrame)); 
        // Obtain the cell information for that neighbor as well.
        vec4 colNgbr = texelFetch(iChannel0, ivec2(mod(u + dir, GRID_SIZE)), 0);
        
        // Current cell and neighboring cell indices.
        float dirIndex = dirToIndex(dir); 
        float dirNgbrIndex = dirToIndex(dirNgbr); 
        
        //vec2 negNgbrDir = e[(int(dirNgbrIndex) + ASIZE/2)%ASIZE];
   
        if(a.x==0.){ 
            // If the current cell is empty, but a neighboring cell is not.
            //dirToIndex(dir)
            if(colNgbr.x>0. && dir == -dirNgbr){ 
            a.x = pow(2., dirIndex); a.y = colNgbr.y; a.z++; } // Flag left. Color = left.
       
        }
        else{
        
            // If the current cell is not empty, but a neighboring cell is.
            if(colNgbr.x==0. && dir == -dirNgbr){ a.x += pow(2., dirIndex); a.z++; }
        }
        
 
        // Update the buffer.
        fragColor = a; 
    }
    
}