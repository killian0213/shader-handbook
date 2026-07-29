// Buffer A (buffer) — Castaway by P_Malin
// https://www.shadertoy.com/view/wt3XDj

//     _____                                       _____  _          _        
//    / ____|                                     / ____|| |        | |       
//   | |      __ _  _ __ ___    ___  _ __  __ _  | (___  | |_  __ _ | |_  ___ 
//   | |     / _` || '_ ` _ \  / _ \| '__|/ _` |  \___ \ | __|/ _` || __|/ _ \
//   | |____| (_| || | | | | ||  __/| |  | (_| |  ____) || |_| (_| || |_|  __/
//    \_____|\__,_||_| |_| |_| \___||_|   \__,_| |_____/  \__|\__,_| \__|\___|
//                                                                            
//                                                                            

#define iChannelState			iChannel0
#define iChannelRockTexture		iChannel1
#define iChannelKeyboard 		iChannel3

#define FLY_CAM_INVERT_Y 1

//   __          __             _           _                _____                               
//   \ \        / /            | |         (_)              / ____|                              
//    \ \  /\  / /_ _ _ __   __| | ___ _ __ _ _ __   __ _  | |     __ _ _ __ ___   ___ _ __ __ _ 
//     \ \/  \/ / _` | '_ \ / _` |/ _ \ '__| | '_ \ / _` | | |    / _` | '_ ` _ \ / _ \ '__/ _` |
//      \  /\  / (_| | | | | (_| |  __/ |  | | | | | (_| | | |___| (_| | | | | | |  __/ | | (_| |
//       \/  \/ \__,_|_| |_|\__,_|\___|_|  |_|_| |_|\__, |  \_____\__,_|_| |_| |_|\___|_|  \__,_|
//                                                   __/ |                                       
//                                                  |___/                                        

struct WanderCamState
{
    vec3 pos;
    vec3 lookAt;
    
    float targetAngle;
    float lookAtAngle;
    
    float eyeHeight;

    float timer;
    
    float shoreDistance;
    
    int iSitting;
    
    float lookAtElevation;
};

void WanderCam_LoadState( out WanderCamState wanderCam, sampler2D sampler, ivec2 addr )
{
    vec4 vPos = LoadVec4( sampler, addr + ivec2(0,0) );
    wanderCam.pos = vPos.xyz;
    vec4 vLookAt = LoadVec4( sampler, addr + ivec2(1,0) );
    wanderCam.lookAt = vLookAt.xyz;
    vec4 vMisc = LoadVec4( sampler, addr + ivec2(2,0) );    
    wanderCam.targetAngle = vMisc.x;
    wanderCam.lookAtAngle = vMisc.y;
    wanderCam.eyeHeight = vMisc.z;
    wanderCam.timer = vMisc.w;
    
    vec4 vMisc2 = LoadVec4( sampler, addr + ivec2(3,0) );    
    wanderCam.iSitting = int( vMisc2.y );
    wanderCam.shoreDistance = vMisc2.z;
    wanderCam.lookAtElevation = vMisc2.w;
}

void WanderCam_StoreState( ivec2 addr, const WanderCamState wanderCam, inout vec4 fragColor, in ivec2 fragCoord )
{
    StoreVec4( addr + ivec2(0,0), vec4( wanderCam.pos, 0 ), fragColor, fragCoord );
    StoreVec4( addr + ivec2(1,0), vec4( wanderCam.lookAt, 0 ), fragColor, fragCoord );
    StoreVec4( addr + ivec2(2,0), vec4( wanderCam.targetAngle, wanderCam.lookAtAngle, wanderCam.eyeHeight, wanderCam.timer ), fragColor, fragCoord );
    StoreVec4( addr + ivec2(3,0), vec4( 0, wanderCam.iSitting, wanderCam.shoreDistance, wanderCam.lookAtElevation ), fragColor, fragCoord );
}

void WanderCam_Init( inout WanderCamState wanderCam )
{
    if ( iFrame == 0 )
    {
        wanderCam.pos = vec3(0, 2, 40);
        wanderCam.lookAt = vec3(0,2,10);
        wanderCam.targetAngle = 0.;
        wanderCam.lookAtAngle = 0.3;
        wanderCam.lookAtElevation = -0.3;
        wanderCam.eyeHeight = 1.5;
		wanderCam.timer = 5.0;
        wanderCam.iSitting = 0;
        wanderCam.shoreDistance = 5.;
    }
}

vec2 WanderCam_GetTarget( WanderCamState wanderCam )
{
    float theta = wanderCam.targetAngle;
    return vec2( sin( theta ), cos( theta ) ) * (60.0 - wanderCam.shoreDistance);
}

vec3 WanderCam_GetLookAt( WanderCamState wanderCam )
{
    float theta = wanderCam.lookAtAngle;
    float phi = wanderCam.lookAtElevation;
    return vec3( sin( theta ) * cos(phi), sin(phi), cos( theta ) * cos(phi) );
}

void WanderCam_Update( inout WanderCamState wanderCam )
{
    vec2 target = WanderCam_GetTarget( wanderCam );
    vec2 toTarget = target - wanderCam.pos.xz;
    
    float len = length( toTarget );
    
    if ( len > 0.0 )
    {
        float moveRate = min( len * 0.5, 1.0 );
	    float currSpeed = 0.04f * moveRate;
        
        float speed = min( len, currSpeed );
        vec2 delta = normalize( toTarget ) * speed;

        wanderCam.pos.xz += delta;
    }
    
    if ( len < 0.1 )
    {
        wanderCam.timer -= iTimeDelta;
        if ( wanderCam.timer < 0.0 )
        {
            // do something different
            float rnd = hash11(iTime + 31.);

            if ( rnd < 0.1 )                
            {
                // extend timer
                wanderCam.timer = 2.0;
            }
			else
            if ( rnd < 0.4 )
            {
                // change lookat target
                wanderCam.lookAtAngle = hash11(iTime+7.) * 2. - 1.;
                wanderCam.lookAtElevation = hash11(iTime+29.) * -0.6 + 0.1;
                wanderCam.timer = 2.0;
            }
            else
            {
                // random chance to sit here if we haven't
                float rndSit = hash11(iTime + 45.);
                if ( wanderCam.iSitting == 0 && rndSit < 0.25 )
                {
                    wanderCam.iSitting = 1;
                    wanderCam.timer = 1.5;
                }
                else
                {
                    if ( wanderCam.iSitting == 1 )
                    {
	                    // stand up
                        wanderCam.iSitting = -1; // don't sit again
                        wanderCam.timer = 1.5;
                    }
                    else
                    {
                        // Move to a different location
                        wanderCam.targetAngle += (hash11(iTime) - 0.5) * 0.5;
                        wanderCam.targetAngle = clamp( wanderCam.targetAngle, -1.5, 1.5);
                        wanderCam.shoreDistance = hash11(iTime+27.) * 5.0;
                        wanderCam.timer = 5.0;
                    }                    
                }                
            }           
        }        
    }
    else
    {
        wanderCam.iSitting = 0;
    }

    float targeth = 1.5;
    if ( wanderCam.iSitting != 0 )
    {
    	targeth = 0.9;
    }
    
    wanderCam.eyeHeight = wanderCam.eyeHeight + (targeth - wanderCam.eyeHeight) * 0.03;
    
    wanderCam.pos.y = Terrain_GetHeight( iChannelRockTexture, wanderCam.pos.xz, false, true );
    wanderCam.pos.y += wanderCam.eyeHeight;

    vec3 lookAt = WanderCam_GetLookAt( wanderCam );
    
    vec3 idealLookAt = lookAt;
    wanderCam.lookAt = wanderCam.lookAt + (idealLookAt - wanderCam.lookAt) * 0.01;
}

//    _____ _          ____                
//   |  ___| |_   _   / ___|__ _ _ __ ___  
//   | |_  | | | | | | |   / _` | '_ ` _ \ 
//   |  _| | | |_| | | |__| (_| | | | | | |
//   |_|   |_|\__, |  \____\__,_|_| |_| |_|
//            |___/                        
//

struct FlyCamState
{
    vec3 vPos;
    vec3 vAngles;
    vec4 vPrevMouse;
};

void FlyCam_LoadState( out FlyCamState flyCam, sampler2D sampler, ivec2 addr )
{
    vec4 vPos = LoadVec4( sampler, addr + ivec2(0,0) );
    flyCam.vPos = vPos.xyz;
    vec4 vAngles = LoadVec4( sampler, addr + ivec2(1,0) );
    flyCam.vAngles = vAngles.xyz;
    vec4 vPrevMouse = LoadVec4( sampler, addr + ivec2(2,0) );    
    flyCam.vPrevMouse = vPrevMouse;
}

void FlyCam_StoreState( ivec2 addr, const in FlyCamState flyCam, inout vec4 fragColor, in ivec2 fragCoord )
{
    StoreVec4( addr + ivec2(0,0), vec4( flyCam.vPos, 0 ), fragColor, fragCoord );
    StoreVec4( addr + ivec2(1,0), vec4( flyCam.vAngles, 0 ), fragColor, fragCoord );
    StoreVec4( addr + ivec2(2,0), vec4( iMouse ), fragColor, fragCoord );
}

mat3 Mat_FromAngles( vec3 vAngles )
{
    mat3 rotX = mat3(1.0, 0.0, 0.0, 
                     0.0, cos(vAngles.x), sin(vAngles.x), 
                     0.0, -sin(vAngles.x), cos(vAngles.x));
    
    mat3 rotY = mat3(cos(vAngles.y), 0.0, -sin(vAngles.y), 
                     0.0, 1.0, 0.0, 
                     sin(vAngles.y), 0.0, cos(vAngles.y));    

    mat3 rotZ = mat3(cos(vAngles.z), sin(vAngles.z), 0.0,
                     -sin(vAngles.z), cos(vAngles.z), 0.0,
                     0.0, 0.0, 1.0 );
    
    
    return rotY * rotX * rotZ;    
}

void FlyCam_GetAxes( FlyCamState flyCam, out vec3 vRight, out vec3 vUp, out vec3 vForwards )
{
    vec3 vAngles = flyCam.vAngles;
    
    mat3 m = Mat_FromAngles( vAngles );
    
    vRight = m[0];
    vUp = m[1];
    vForwards = m[2];
}

void FlyCam_Init( inout FlyCamState flyCam, vec3 vStartPos, vec3 vStartAngles )
{
    if ( iFrame == 0 )
    {
        flyCam.vPos = vStartPos;
        flyCam.vAngles = vStartAngles;
        flyCam.vPrevMouse = iMouse;    
    }
}

void FlyCam_Update( inout FlyCamState flyCam )
{    
    //float fMoveSpeed = 0.01;
    float fMoveSpeed = iTimeDelta * 4.0;
    float fRotateSpeed = 3.0;
    
    if ( Key_IsPressed( iChannelKeyboard, KEY_SHIFT ) )
    {
        fMoveSpeed *= 4.0;
    }
          
    vec3 vMove = vec3(0.0);
        
    if ( Key_IsPressed( iChannelKeyboard, KEY_W ) )
    {
        vMove.z += fMoveSpeed;
    }
    if ( Key_IsPressed( iChannelKeyboard, KEY_S ) )
    {
        vMove.z -= fMoveSpeed;
    }

    if ( Key_IsPressed( iChannelKeyboard, KEY_A ) )
    {
        vMove.x -= fMoveSpeed;
    }
    if ( Key_IsPressed( iChannelKeyboard, KEY_D ) )
    {
        vMove.x += fMoveSpeed;
    }
    
    vec3 vForwards, vRight, vUp;
    FlyCam_GetAxes( flyCam, vRight, vUp, vForwards );
        
    flyCam.vPos += vRight * vMove.x + vForwards * vMove.z;
    
    vec3 vRotate = vec3(0);
    
    bool bMouseDown = iMouse.z > 0.0;
    bool bMouseWasDown = flyCam.vPrevMouse.z > 0.0;
    
    if ( bMouseDown && bMouseWasDown )
    {
    	vRotate.yx += ((iMouse.xy - flyCam.vPrevMouse.xy) / iResolution.xy) * fRotateSpeed;
    }
    
#if FLY_CAM_INVERT_Y    
    vRotate.x *= -1.0;
#endif    
    
    if ( Key_IsPressed( iChannelKeyboard, KEY_E ) )
    {
        vRotate.z -= fRotateSpeed * 0.01;
    }
    if ( Key_IsPressed( iChannelKeyboard, KEY_Q ) )
    {
        vRotate.z += fRotateSpeed * 0.01;
    }
        
	flyCam.vAngles += vRotate;
    
    flyCam.vAngles.x = clamp( flyCam.vAngles.x, -PI * .5, PI * .5 );
}



///////////////////////////////////////////////



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 iAddr = ivec2(fragCoord.xy);
    if ( iAddr.y != 0 || iAddr.x > 16 ) 
    {
        discard; 
        return;
    }
    
	fragColor = vec4(0.0f, 0.0f, 0.0f, 1.0f);
    
   // Setup Cam
    CameraState cam;
    
    // Set defaults
    
    vec3 vCameraInitialPos = vec3(-0.1, 5.0, 3.5);
    
    cam.vPos = vCameraInitialPos;
    cam.vTarget =  vCameraInitialPos + vec3(0,0, 3.0);
    cam.vUp = vec3(0,1,0);
    cam.fFov = 25.0;
    cam.fPlaneInFocus = length(cam.vTarget - cam.vPos);
    cam.vJitter = vec2(0.0);        
        
    WanderCamState wanderCam;
    WanderCam_LoadState( wanderCam, iChannelState, ivec2(11,0) );
    
    WanderCam_Init( wanderCam );
 
    
    // Update FlyCam
    FlyCamState flyCam;
    FlyCam_LoadState( flyCam, iChannelState, ivec2(8,0) );
    
    float pitch = 0.1;
    
	FlyCam_Init( flyCam, vCameraInitialPos, vec3(pitch, 0.0, 0) );    

    if ( Key_IsToggled( iChannelKeyboard, KEY_SPACE ) )
    {    
        FlyCam_Update( flyCam );

        vec3 vForwards, vRight, vUp;
        FlyCam_GetAxes( flyCam, vRight, vUp, vForwards );

        cam.vPos = flyCam.vPos;
        cam.vTarget = flyCam.vPos + vForwards;
        cam.vUp = vUp;
        cam.fPlaneInFocus = length(flyCam.vPos);        

        cam.fPlaneInFocus = -1.0; // auto focus
    }
    else
    {
		WanderCam_Update( wanderCam );
        
        // set cam from wander cam
        cam.vPos = wanderCam.pos;
        cam.vTarget = wanderCam.pos + wanderCam.lookAt;
        
        vec3 vNoise = SmoothNoise32( cam.vPos.xz + iTime * 0.5 );
        
        vec3 vShakyCamAngles = (vNoise - 0.5) * vec3( 0.05, 0.03, 0.01 );
        mat3 m = Mat_FromAngles( vShakyCamAngles );
        
        vec3 vToTarget = cam.vTarget - cam.vPos;
        cam.vTarget = cam.vPos + vToTarget * m;
        
        cam.vUp = vec3(0,1,0) * m;
        
        // update flycam position from wander cam
        flyCam.vPos = cam.vPos;
        vec3 vDir = cam.vTarget - cam.vPos;
        flyCam.vAngles = vec3( 0, atan(vDir.x, vDir.z), 0);
    }

    
#ifdef ENABLE_TAA_JITTER
    cam.vJitter = hash21( fract( iTime ) ) - 0.5f;
#endif    

	Cam_StoreState( ivec2(0), cam, fragColor, iAddr );    
    FlyCam_StoreState( ivec2(8,0), flyCam, fragColor, iAddr );
    WanderCam_StoreState( ivec2(11,0), wanderCam, fragColor, iAddr );
}