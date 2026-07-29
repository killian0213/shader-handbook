// Buffer A (buffer) — Fractal Explorer DOF by Dave_Hoskins
// https://www.shadertoy.com/view/MdyGRW

// Adaption of Ben Quantock, WASD 2016 ( https://www.shadertoy.com/view/ldyGzW )
// With speed limits and frame delta added by Dave Hoskins.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define INVERT_Y 0

#define ACCEL .01
#define DECAY  .85 // how much velocity is preserved per frame (proportionally)
#define MAX_SPEED  .02

#if INVERT_Y
const float yMul = 1.0;
#else
const float yMul = -1.0;
#endif
const int KEY_W		= 87;
const int KEY_A		= 65;
const int KEY_S		= 83;
const int KEY_D		= 68;
const int KEY_LEFT  = 37;
const int KEY_UP    = 38;
const int KEY_RIGHT = 39;
const int KEY_DOWN  = 40;

const int KEY_SPACE	= 32;
const int KEY_SHIFT	= 16;

//----------------------------------------------------------------------------------------
float ReadKey( int key )
{
   	return step(.5,texture( iChannel3, vec2( (float(key)+.5)/256.0, .25)).x);
}

//----------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = vec4(0.0,0.0,0.0,1.0);

    if ( int(fragCoord.y) == 0 )
    {
        if ( int(fragCoord.x) == 0 )
        {
            vec3 camPos = texture( iChannel0, vec2(.5,.5)/iResolution.xy, -100.0 ).xyz;
            vec3 camVel = texture( iChannel0, vec2(3.5,.5)/iResolution.xy, -100.0 ).xyz;
            float time  = (iTime-texture( iChannel0, vec2(4.5,.5)/iResolution.xy, -100.0 ).x)*30.0;
             if (iFrame == 0)
		    {
        		fragColor = vec4(-10.0,-1.2,2.5, 1.);
            }else
            {
                camVel *= time*(1.0+ReadKey(KEY_SHIFT)+ReadKey(KEY_SPACE));
                vec3 oldCam = camPos;
                camPos.x += camVel.x;if (Map(camPos) < 0.002) camPos.x = oldCam.x;
                camPos.y += camVel.y;if (Map(camPos) < 0.002) camPos.y = oldCam.y;
                camPos.z += camVel.z;if (Map(camPos) < 0.002) camPos.z = oldCam.z;
            	fragColor = vec4(camPos, 0);
            }
        }
        else if ( int(fragCoord.x) <= 2 )
        {
            vec4 baseCamRot = texture( iChannel0, vec2(2.5,.5)/iResolution.xy, -100.0 );
            vec4 camRot = texture( iChannel0, vec2(1.5,.5)/iResolution.xy, -100.0 );

            vec2 mouseRot = (iMouse.yx/iResolution.yx-.5)*vec2(.5*yMul,1.);
            
            camRot.w = iMouse.z;
            
            bool press = (camRot.w > .0);
            bool lastPress = (baseCamRot.w > .0);
            bool click = press && !lastPress;
            if ( click )
            {
                baseCamRot.xy -= mouseRot;
            }
            
            if ( press )
            {
                camRot.xy = baseCamRot.xy + mouseRot;
            }
            else
            {
                //update the base pos
                baseCamRot = camRot;
            }

            baseCamRot.w = camRot.w;
            
            // store
            if ( int(fragCoord.x) == 1 )
            {
				if (iFrame == 0)
		    	{
        			fragColor = vec4(1., 0.1, 0,0);
            	}else
            	fragColor = camRot;
            }
            else
            {
            	fragColor = baseCamRot;
            }
        }
        else if ( int(fragCoord.x) == 3 )
        {
            vec4 camVel = texture( iChannel0, vec2(3.5,.5)/iResolution.xy, -100.0 );
            vec4 camRot = texture( iChannel0, vec2(1.5,.5)/iResolution.xy, -100.0 )*6.28318530718;
            
            vec3 forward = vec3(0,0,ACCEL);
            vec3 right 	 = vec3(ACCEL,0,0);

            forward.zy = forward.zy*cos(camRot.x) + sin(camRot.x)*vec2(1,-1)*forward.yz;
            right.zy = right.zy*cos(camRot.x) + sin(camRot.x)*vec2(1,-1)*right.yz;
                
            forward.xz = forward.xz*cos(camRot.y) + sin(camRot.y)*vec2(1,-1)*forward.zx;
		    right.xz = right.xz*cos(camRot.y) + sin(camRot.y)*vec2(1,-1)*right.zx;
            
            camVel.xyz += (ReadKey(KEY_W)-ReadKey(KEY_S)+ReadKey(KEY_UP)-ReadKey(KEY_DOWN)) * forward;
            camVel.xyz += (ReadKey(KEY_D)-ReadKey(KEY_A)+ReadKey(KEY_RIGHT)-ReadKey(KEY_LEFT)) * right;
            

            camVel *= DECAY; // exponential decay
            float lim = length(camVel);
            if (lim > MAX_SPEED)
            {
                camVel = normalize(camVel) * MAX_SPEED;
            }
        
            
            fragColor = camVel;
        }
		else if ( int(fragCoord.x) == 4 )
        {
			fragColor = vec4(iTime);
	    }
    }
}
