// Buffer A (buffer) — STARRY NIGHT by alro
// https://www.shadertoy.com/view/3dlfWs

//Track mouse movement and resolution change between frames and set view direction.

#define EPS 1e-4

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    
    //Work with just the first four pixels
    if((fragCoord.x == 0.5) && (fragCoord.y < 4.0)){
        
        vec4 oldMouse = texelFetch(iChannel0, ivec2(0.5), 0).xyzw;
        vec4 mouse = (iMouse / iResolution.xyxy); 
        vec4 newMouse = vec4(0);

        float mouseDownLastFrame = texelFetch(iChannel0, ivec2(0.5, 3.5), 0).x;
        
        //If mouse button is down and was down last frame
        if(iMouse.z > 0.0 && mouseDownLastFrame > 0.0){
            
            //Difference between mouse position last frame and now
            vec2 mouseMove = mouse.xy-oldMouse.zw;
            newMouse = vec4(oldMouse.xy + vec2(3.5, 2.5)*mouseMove, mouse.xy);
        }else{
            newMouse = vec4(oldMouse.xy, mouse.xy);
        }
        newMouse.x = mod(newMouse.x, 2.0*PI);
        newMouse.y = max(-0.999, min(0.999, newMouse.y));

        //Store mouse data in the first pixel of Buffer C
        if(fragCoord == vec2(0.5, 0.5)){
            //Set value at first frames
            if(iFrame < 5){
                newMouse = vec4(0.1, 0.07, 0.0, 0.0);
                
            }
            fragColor = vec4(newMouse);
        }

        //Store view direction in the second pixel of Buffer A
        if(fragCoord == vec2(0.5, 1.5)){
            //Set camera position from mouse information
            vec3 targetDir = vec3(sin(newMouse.x), newMouse.y, -cos(newMouse.x));
            fragColor = vec4(targetDir, 1.0);
        }
        
        //Store resolution change data in the third pixel of Buffer A
        if(fragCoord == vec2(0.5, 2.5)){
            
            float resolutionChangeFlag = 0.0;
            
            //The resolution last frame
            vec2 oldResolution = texelFetch(iChannel0, ivec2(0.5, 2.5), 0).yz;
            
            if(iResolution.xy != oldResolution){
            	resolutionChangeFlag = 1.0;
            }
            
        	fragColor = vec4(resolutionChangeFlag, iResolution.xy, 1.0);
        }
        
        //Store whether the mouse button is down in the fourth pixel of Buffer A
        if(fragCoord == vec2(0.5, 3.5)){
            if(iMouse.z > 0.0){
            	fragColor = vec4(vec3(1.0), 1.0);
            }else{
            	fragColor = vec4(vec3(0.0), 1.0);
            }
        }
        
    }
}