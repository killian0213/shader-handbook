// Buffer A (buffer) — Extruded Tron Circuit by Shane
// https://www.shadertoy.com/view/dsGcDz


int dr(vec2 uv){
    
    // Obtain a random direction.
    uv = mod(uv, SIZE);
    return int(1024.*hash31(vec3(uv, float(iFrame))))&3;
     
}

vec4 tx(vec2 uv){ 
    // Wrapped texel fetch.
    uv = mod(uv, SIZE);
    return texelFetch(iChannel0, ivec2(uv), 0);
}



void mainImage(out vec4 fragColor, vec2 fragCoord){


    // Reject any pixels outside the wrapping area to lessen the GPU load.
    if(fragCoord.x>SIZE || fragCoord.y>SIZE) discard;

  
    // Skipping a few frames to slow down the animation and faster machines.
    float frameRate = 1./iTimeDelta;
    int iFr = int(round(frameRate/60.));
    if(iFrame%iFr>0){       
       fragColor = tx(fragCoord);
       return;        
    }
   
    if(textureSize(iChannel0, 0).x<2 || iFrame==0 || iMouse.z>0.){
        
        // Starting conditions. The following is a bit messy, but I'm
        // essentially spacing out some starting points on a grid.
        
        vec4 rVal = vec4(0, -1, 0, 0);
        vec2 ip = floor(fragCoord);
        #if 0
        if(length(mod(ip, 1./scale) - .0 - floor((1./scale/2.))) < 0.01){
          rVal.x = .5;
          rVal.z = 1.;
        }
        #else
        vec2 mIP = mod(ip, 1./scale);
        vec2 repIp = mIP;
        float rSc = 6.;
        if(mod(floor(repIp.y/rSc), 2.)<.5){
            repIp.x += floor(rSc/2.); // Offset rows.
            mIP.x += floor(rSc/2.);
        }
        
        repIp = mod(repIp, rSc);
        mIP = mod(mIP, 1./scale);
        
        if(repIp.x == 0. && repIp.y == 0.){ 
            rVal.x = .5;
            mIP = floor(mIP/rSc);
            float colID = (mIP.x + mIP.y*rSc)/(rSc*rSc);
            //float colID = hash21(mIP + .157);
            rVal.y = colID;
            rVal.z = 1.;
        
        }
        #endif 
        
        fragColor = rVal;
 
        
    }else{
        
       
        
        // Currect pixel value and neighboring cell pixel values.
        vec4 a = tx(fragCoord), // Current.
              
        lft = tx(fragCoord + vec2(-1, 0)), // Left
        up = tx(fragCoord + vec2(0, 1)), // Up.
        rgt = tx(fragCoord + vec2(1, 0)), // Right.
        dwn = tx(fragCoord + vec2(0, -1)); // Down.
 
              
        ////////
        // No more than two connections allowed.
        int cn = 0;
        //ivec4 dCn = ivec4(0);
        int iVal = int(a.x);
        ivec4 iVal4 = ivec4(lft.x, up.x, rgt.x, dwn.x);
        for(int i = 0; i<4; i++){
            if((iVal&(1<<i))>0) cn++;

        }        
        
        ////////
         
        // On the first try, don't connect from both ends.
        int maxCons = 2; 
        
        // For the initialized cell, only allow connections from one
        // side... This avoids duplicates from forming.
        if(a.z==1.) maxCons = 1; // Set the maxium connections to one.
         
  
          
        if(a.x==0.){
        
            // If the current cell is empty, but a neighboring cell has
            // an existing connection.

            int rnd = dr(fragCoord); // Obtain a random direction for this pixel.
            // If the random direction of the empty cell is left and the 
            // left cell is not empty, flag left.


            // At this point we're opening a connection to the possibility of
            // of being activated from it's neighboring pixel. Most form, but not
            // all, since some connections will be blocked by another worm passing
            // by. Therefore, when equilibrium for this pass has been reached, open 
            // connections that haven't formed need to be deactivated.


            if(cn<maxCons)if(rnd==0 && (int(lft.x)&4)>0){ a.x = 1.; a.y = lft.y; cn++; } // Flag left.
            if(cn<maxCons)if(rnd==1 && (int(up.x)&8)>0){ a.x = 2.; a.y = up.y; cn++; }   // Flag up.
            if(cn<maxCons)if(rnd==2 && (int(rgt.x)&1)>0){ a.x = 4.; a.y = rgt.y; cn++; } // Flag right.
            if(cn<maxCons)if(rnd==3 &&(int(dwn.x)&2)>0){ a.x = 8.; a.y = dwn.y; cn++; } // Flag down.
 
        }
        else
        {  
        
            // If the current cell is not empty, but a neighboring one is empty.
 

            // 1 - left, 2 - up, 4 - right, 8 - down.
  
            if(hash31(vec3(fragCoord + .5, iTime))<1.5){
            // If the left cell is empty and the random direction of that particular 
            // cell is right (connecting the current cell) flag the left direction.
            if(cn<maxCons)if(lft.x==0. && dr(fragCoord + vec2(-1, 0)) == 2){ a.x += 1.; cn++;  }// Flag left.
            if(cn<maxCons)if(up.x==0. && dr(fragCoord + vec2(0, 1)) == 3){ a.x += 2.; cn++; } // Flag up.
            if(cn<maxCons)if(rgt.x==0. && dr(fragCoord + vec2(1, 0)) == 0){ a.x += 4.; cn++; } // Flag right.
            if(cn<maxCons)if(dwn.x==0. && dr(fragCoord + vec2(0, -1)) == 1){ a.x += 8.; cn++; }// Flag down.
             
            }
            else {
            
                if(cn<maxCons){
                   if(lft.x==0. && dr(fragCoord + vec2(-1, 0)) == 2){ a.x += 1.;  }// Flag left.
                   if(up.x==0. && dr(fragCoord + vec2(0, 1)) == 3){ a.x += 2.;  } // Flag up.
                   if(rgt.x==0. && dr(fragCoord + vec2(1, 0)) == 0){ a.x += 4.;  } // Flag right.
                   if(dwn.x==0. && dr(fragCoord + vec2(0, -1)) == 1){ a.x += 8.;  }// Flag down.
                }  
                
            } 
        
         
         }  
         
         //if(a.w>8.) a.z = 0.;
         
         a.w++;
         
           
         if(a.w>256.){
         
             // When every worm can go no further, you need to check for
             // open connections (when another worm has blocked the path)
             // and deactivate them.
             if((int(lft.x)&4)==0 && (int(a.x)&1)>0) a.x -= 1.;
             if((int(up.x)&8)==0 && (int(a.x)&2)>0) a.x -= 2.;
             if((int(rgt.x)&1)==0 && (int(a.x)&4)>0) a.x -= 4.;
             if((int(dwn.x)&2)==0 && (int(a.x)&8)>0) a.x -= 8.;
              
              
             a.w = 0.; // Restart the counter.
             // If it's finished in one direction, unflag the starting position. 
             // This is optional, but I like it becausse it produces a more packed 
             // and complete pattern.
             a.z = 0.; 
             
         
         }
 
          
        
        fragColor = a;
    }
}