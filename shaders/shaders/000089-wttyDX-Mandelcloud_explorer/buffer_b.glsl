// Buffer B (buffer) — Mandelcloud explorer by michael0884
// https://www.shadertoy.com/view/wttyDX

//Controller

#define CAMERA_SPEED 3./60.
#define MOUSE_SENSITIVITY 0.2/60.

bool isKeyPressed(int KEY)
{
	return texelFetch( iChannel3, ivec2(KEY,0), 0 ).x > 0.5;
}

void mainImage( out vec4 c, in vec2 p )
{
    ivec2 pi = ivec2(p);
    if(pi.x < N && pi.y < 1)
    {
        c = GET_DATA(pi.x);
        
        vec4 mouse = GET_DATA(MOUSE_);
        vec2 mousespeed = mouse.xy;
        vec4 angles = GET_DATA(CAM_ANGLE_);
        mat3 camera = get_cam(angles.x, angles.y);
        vec4 pos = GET_DATA(CAM_POS_);
        vec4 vel = GET_DATA(CAM_VEL_);
        vec4 speed = GET_DATA(CAM_MAX_VEL_);
     
        switch(pi.x)
        {
        case MOUSE_:  //mouse speed calculation 
            if(length(iMouse.zw - iMouse.xy) > 10.)
  		    {
   				c.xy = iMouse.xy - c.zw; // mouse delta
                if(iFrame < 1)
                {
                    c.xy = vec2(0.);
                }
            }
            else
            {
				c.xy = vec2(0.); // mouse delta
            }
    		c.zw = iMouse.xy; // mouse pos
            break;
            
        case CAM_ANGLE_:  //angle computation
           
   			c.xy = c.xy + c.zw*MOUSE_SENSITIVITY; // angle delta
            c.y = clamp(c.y, PI*0.01, PI*0.99);
    		c.zw += vec2(-1.0, 1.0)*mouse.xy; // mouse pos
            c.zw *= 0.6;
            if(iFrame < 1)
            {
                c.xy = vec2(-PI*0.27,PI*0.5);
            }
            break;
            
        case CAM_POS_:  //position
            if(pos.w > 0.) {c.xyz += 0.05*vec3(sin(iTime), cos(iTime), 0.)*speed.x; c.w = pos.w;}
            c.xyz += vel.xyz*speed.x;
            if(length(vel.xyz)>0.1) c.w = 0.;
   			if(iFrame < 1)
            {
                c = vec4(-1.5,1.5,0.0,1.0);
            }
            
            break;
         case CAM_VEL_:  //velocity
          
            c.w++;
            if(length(mousespeed) >0. || isKeyPressed(KEY_Z))
            {
                c.w = 0.;
            }
            if(isKeyPressed(KEY_UP) || isKeyPressed(KEY_W))
   	   		{
   				c.xyz += camera[0]*speed.x;
                c.w = 0.;
            }
            if(isKeyPressed(KEY_DOWN) || isKeyPressed(KEY_S))
   	   		{
   				c.xyz -= camera[0]*speed.x;
                c.w = 0.;
            }
            if(isKeyPressed(KEY_RIGHT) || isKeyPressed(KEY_D))
   	   		{
   				c.xyz += camera[1]*speed.x;
                c.w = 0.;
            }
            if(isKeyPressed(KEY_LEFT) || isKeyPressed(KEY_A))
   	   		{
   				c.xyz -= camera[1]*speed.x;
                c.w = 0.;
            }
            c.xyz *= 0.8; //slowing down
            
            break;
          case CAM_MAX_VEL_: //camera max speed
            if(isKeyPressed(KEY_Q))
   	   		{
   				c.x *= 1.01;
            }
            if(isKeyPressed(KEY_E))
   	   		{
   				c.x *= 0.99;
            }
            if(iFrame < 1)
            {
                c.x = CAMERA_SPEED;
            }
            break; 
          case LIGHT_POS1_:
            if(isKeyPressed(KEY_P))
   	   		{
                c.xyz = pos.xyz+camera[0]*vec3(LIGHT_RAD*40.);
            }
            if(iFrame < 1)
            {
                c.xyz = vec3(0.2, 1.0, -0.4);
            }
            break;
          case LIGHT_POS2_:
            if(isKeyPressed(KEY_L))
   	   		{
                c.xyz = pos.xyz+camera[0]*vec3(LIGHT_RAD*40.);
            }
            if(iFrame < 1)
            {
                c.xyz = vec3(-0.8, 0., 0.);
            }
            break;
          case PCAM_ANGLE_:
            c = angles;
            break;
          case PCAM_POS_:
            c = pos;
            break;
          case PRESOLUTION_:
            c.xy = iResolution.xy;
            break;
        }   
    } else discard;
}