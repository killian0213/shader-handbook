// Buffer A (buffer) — Fractal dimension explorer by michael0884
// https://www.shadertoy.com/view/tld3zn

/// UTILITY
///
/// Using the GPU as the CPU here, pretty inefficient I guess

bool isKeyPressed(int KEY)
{
	return texelFetch( iChannel3, ivec2(KEY,0), 0 ).x > 0.5;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    if(iFrame < 1)
    {
        fragColor = vec4(0.);
    }
    
    if(fragCoord.x <= N && fragCoord.y <= 1.)
    {
        //instruction
        int I = int(fragCoord.x); 
        fragColor = texelFetch(iChannel0,  ivec2(I,0), 0);
        vec4 mouse = texelFetch(iChannel0,  ivec2(MOUSE_INDX,0), 0);
        vec2 mousespeed = texelFetch(iChannel0,  ivec2(MOUSE_INDX,0), 0).xy;
        vec4 angles = texelFetch(iChannel0,  ivec2(ANGLE_INDX,0), 0);
        mat3 camera = transpose(getCamera(angles.xy));
        vec4 posit = texelFetch(iChannel0,  ivec2(POS_INDX,0), 0);
        vec4 vel = texelFetch(iChannel0,  ivec2(VEL_INDX,0), 0);
		vec4 speed = texelFetch(iChannel0,  ivec2(SPEED_INDX,0), 0);
        vec4 norm = calcGrad(posit.xyz);
        norm.xyz = norm.xyz/(length(norm.xyz) + 0.0001);
        switch(I)
        {
        case MOUSE_INDX:  //mouse speed calculation 
            if(length(iMouse.zw - iMouse.xy) > 10.)
  		    {
   				fragColor.xy = iMouse.xy - fragColor.zw; // mouse delta
                if(iFrame < 1)
                {
                    fragColor.xy = vec2(0.);
                }
            }
            else
            {
				fragColor.xy = vec2(0.); // mouse delta
            }
    		fragColor.zw = iMouse.xy; // mouse pos
            break;
            
        case ANGLE_INDX:  //angle computation
           
   			fragColor.xy = fragColor.xy + fragColor.zw*MOUSE_SENSITIVITY; // angle delta
            fragColor.y = clamp(fragColor.y, -PI*0.5, PI*0.5);
    		fragColor.zw += vec2(1,-1)*mouse.xy; // mouse pos
            fragColor.zw *= 0.8;
             if(iFrame < 1)
            {
                fragColor.xy = vec2(PI*1.25,0.);
            }
            break;
            
        case POS_INDX:  //position
          
            float DX = length(vel.xyz*speed.x)+0.0001;
            float MAXDX = map(fragColor.xyz + vel.xyz*speed.x).w + norm.w;
            if(DX > MAXDX)
                vel *= 0.25;
            fragColor.xyz += vel.xyz*speed.x;
   			fragColor.w = vel.w;
            if(iFrame < 1)
            {
                fragColor.xyz = vec3(13.,1.,10.4);
            }
           
            break;
         case VEL_INDX:  //velocity
          
            fragColor.w++;
            if(length(mousespeed) >0. || isKeyPressed(KEY_Z))
            {
                fragColor.w = 0.;
            }
            if(isKeyPressed(KEY_UP) || isKeyPressed(KEY_W))
   	   		{
   				fragColor.xyz += camera[1]*speed.x;
                fragColor.w = 0.;
            }
            if(isKeyPressed(KEY_DOWN) || isKeyPressed(KEY_S))
   	   		{
   				fragColor.xyz -= camera[1]*speed.x;
                fragColor.w = 0.;
            }
            if(isKeyPressed(KEY_RIGHT) || isKeyPressed(KEY_D))
   	   		{
   				fragColor.xyz += camera[0]*speed.x;
                fragColor.w = 0.;
            }
            if(isKeyPressed(KEY_LEFT) || isKeyPressed(KEY_A))
   	   		{
   				fragColor.xyz -= camera[0]*speed.x;
                fragColor.w = 0.;
            }
            fragColor.xyz *= 0.8; //slowing down
            
            //fractal collision detection, removing the normal velocity component 
          	fragColor.xyz += norm.xyz*max(dot(fragColor.xyz, -norm.xyz),0.)*exp(-max(norm.w,0.)/0.04);
            break;
          case LIGHT_INDX:  //light
            if(isKeyPressed(KEY_L))
   	   		{
   				fragColor.xyz = posit.xyz;
                fragColor.w = .08;
            }
            if(iFrame < 1)
            {
                fragColor = vec4(12.5,-4,10.5, 0.1);
            }
            break; 
          case SPEED_INDX: //camera max speed
            if(isKeyPressed(KEY_Q))
   	   		{
   				fragColor.x *= 1.01;
            }
            if(isKeyPressed(KEY_E))
   	   		{
   				fragColor.x *= 0.99;
            }
            if(iFrame < 1)
            {
                fragColor.x = CAMERA_SPEED;
            }
            break; 
        }   
    } else discard;
    
   
    
}