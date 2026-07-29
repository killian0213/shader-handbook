// Buffer D (buffer) — [SH18] Visage by P_Malin
// https://www.shadertoy.com/view/4lcyD8


//    _____             _    ______ __   __  ____   _                                      _____  _          _        
//   |  __ \           | |  |  ____|\ \ / / |  _ \ | |                            ___     / ____|| |        | |       
//   | |__) |___   ___ | |_ | |__    \ V /  | |_) || |  ___    ___   _ __ ___    ( _ )   | (___  | |_  __ _ | |_  ___ 
//   |  ___// _ \ / __|| __||  __|    > <   |  _ < | | / _ \  / _ \ | '_ ` _ \   / _ \/\  \___ \ | __|/ _` || __|/ _ \
//   | |   | (_) |\__ \| |_ | |      / . \  | |_) || || (_) || (_) || | | | | | | (_>  <  ____) || |_| (_| || |_|  __/
//   |_|    \___/ |___/ \__||_|     /_/ \_\ |____/ |_| \___/  \___/ |_| |_| |_|  \___/\/ |_____/  \__|\__,_| \__|\___|
//                                                                                                                    
//                                                                                                                    
                                                             

#define ENABLE_TAA_JITTER

#define FLY_CAM_INVERT_Y 1

#define iChannelState			iChannel1
#define iChannelKeyboard 		iChannel3


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

void FlyCam_GetAxes( FlyCamState flyCam, out vec3 vRight, out vec3 vUp, out vec3 vForwards )
{
    vec3 vAngles = flyCam.vAngles;
    mat3 rotX = mat3(1.0, 0.0, 0.0, 
                     0.0, cos(vAngles.x), sin(vAngles.x), 
                     0.0, -sin(vAngles.x), cos(vAngles.x));
    
    mat3 rotY = mat3(cos(vAngles.y), 0.0, -sin(vAngles.y), 
                     0.0, 1.0, 0.0, 
                     sin(vAngles.y), 0.0, cos(vAngles.y));    

    mat3 rotZ = mat3(cos(vAngles.z), sin(vAngles.z), 0.0,
                     -sin(vAngles.z), cos(vAngles.z), 0.0,
                     0.0, 0.0, 1.0 );
    
    
    mat3 m = rotY * rotX * rotZ;
    
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
    float fMoveSpeed = iTimeDelta * 0.5;
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

vec3 GetBloom( vec2 vBloomSize, vec2 vBloomCoord, vec2 vUV )
{
    vec3 vResult = vec3(0);
    
    #define KERNEL_SIZE 8
    #define BLOOM_STRENGTH 16.0
    #define KERNEL_SIZE_F float(KERNEL_SIZE)     
    
    float fTot = 0.0;
    
    {
        float fY = -KERNEL_SIZE_F;
        for( int y=-KERNEL_SIZE; y<=KERNEL_SIZE; y++ )
        {
            float fX = -KERNEL_SIZE_F;
            for( int x=-KERNEL_SIZE; x<=KERNEL_SIZE; x++ )
            {            

                vec2 vOffset = vec2( fX, fY );
                vec2 vTapUV =  (vBloomCoord.xy + vOffset + 0.5) / vBloomSize;

                vec4 vTapSample = textureLod( iChannel0, vTapUV, 0.0 ).rgba;
                if( vTapUV.y < 1.0 / iResolution.y )
                {
                   vTapSample = vec4(0.0);
                }

                vec2 vDelta = vOffset / KERNEL_SIZE_F;

                float f = dot( vDelta, vDelta );
                float fWeight = exp2( -f * BLOOM_STRENGTH );
                vResult += vTapSample.xyz * fWeight;
                fTot += fWeight;

                fX += 1.0;
            }

            fY += 1.0;
        }
    }

    #define HORIZONTAL_BLUR_SIZE 128
    #define HORIZONTAL_BLOOM_STRENGTH 128.0
    
    
    {
        float fY = 0.0;
        float fX = -float(HORIZONTAL_BLUR_SIZE);
        for( int x=-HORIZONTAL_BLUR_SIZE; x<=HORIZONTAL_BLUR_SIZE; x++ )
        {            

            vec2 vOffset = vec2( fX, fY );
            vec2 vTapUV =  (vBloomCoord.xy + vOffset + 0.5) / vBloomSize;

            vec4 vTapSample = textureLod( iChannel0, vTapUV, 0.0 ).rgba;
            if( vTapUV.y < 1.0 / iResolution.y )
            {
                vTapSample = vec4(0.0);
            }

            vec2 vDelta = vOffset / float(HORIZONTAL_BLUR_SIZE);

            float f = dot( vDelta, vDelta );
            float fWeight = exp2( -f * HORIZONTAL_BLOOM_STRENGTH );
            vResult += vTapSample.xyz * fWeight;
            fTot += fWeight;

            fX += 1.0;
        }
    }
    
    
    vResult /= fTot; 
 
    return vResult;
}

    
struct StageState
{
    int stageId;
    float fSceneTime;
    float fBegin;
    float fTime;
    float fLength;
    float fFraction;
};
  


const vec3 vCamEyeStart = vec3(-0.28, 0.0116, 0.15);
const vec3 vCamEyePanOut = vec3(-0.3, 0.0116, 0.4);
const vec3 vCamEyePanSide = vec3(-0.55, 0.004, 0.25);
const vec3 vCamLeftSidePosA = vec3(-0.84, -0.2, 0.9885);    
const vec3 vCamFrontPosA = vec3(0.3538, -0.0675, 1.5351);
const vec3 vCamAbove = vec3(-1.04, 1.22, 1.74);
const vec3 vCamNose = vec3(0.2971, -0.4393, 0.8276);
	

const vec3 vTargetEyeStart = vec3(-0.28, 0.0116, 0.14);
const vec3 vTargetEye = vec3(-0.3, 0.0116, 0.14);
const vec3 vTargetEyeSide = vec3(-0.3, -0.01, 0.05);
const vec3 vTargetLeftSidePosA = vec3(-0.02727, -0.1839, -0.2 );
const vec3 vTargetFrontPosA = vec3(-0.02727, -0.1839, -0.2 );
const vec3 vTargetNose = vec3( 0.0717, -0.3134, 0.2846 );

const vec3 vFocusEye = vec3(-0.28, 0.0116, 0.12);
const vec3 vFocusLeftSidePosA = vec3(0.3201, 0.0095, 0.1174 );
const vec3 vFocusFrontPosA = vec3(0.0901, -0.1431, 0.1837 );
const vec3 vFocusNose = vec3( 0.0717, -0.3134, 0.2846 );

const int
    LOOK_MODE_FORWARDS = 0,
    LOOK_MODE_CAM = 1,
    LOOK_MODE_RANDOM = 2;

const int
    HEAD_MODE_FORWARDS = 0,
    HEAD_MODE_TRACK = 1;

struct ShotState
{
    vec3 vCam;
    vec3 vTarget;
    vec3 vFocus;
    int lookMode;
    int headMode;
    float fov;
};

const ShotState shotStateZoomInOnEye = ShotState
(
    vCamEyeStart, 		// vec3 vCamStart;
    vTargetEyeStart, 		// vec3 vTargetStart;
    vFocusEye, 
    LOOK_MODE_FORWARDS, // int lookModeStart;
    HEAD_MODE_FORWARDS, // int headModeStart;
    15.0
);    

    
const ShotState shotStateEyePanOut = ShotState
(
    vCamEyePanOut, 		// vec3 vCamStart;
    vTargetEye, 		// vec3 vTargetStart;
    vFocusEye, 
    LOOK_MODE_FORWARDS, // int lookModeStart;
    HEAD_MODE_FORWARDS, // int headModeStart;
    15.0
); 

    
const ShotState shotStateEyeLookAround = ShotState
(
    vCamEyePanOut, 		// vec3 vCamStart;
    vTargetEye, 		// vec3 vTargetStart;
    vFocusEye, 
    LOOK_MODE_RANDOM, 	// int lookModeStart;
    HEAD_MODE_FORWARDS, // int headModeStart;
    15.0
);

const ShotState shotStateSidePosRandom = ShotState
(
    vCamEyePanSide, 	// vec3 vCamStart;
    vTargetEyeSide, 	// vec3 vTargetStart;    
    vFocusEye,     
    LOOK_MODE_RANDOM, 	// int lookModeStart;    
    HEAD_MODE_FORWARDS, // int headModeStart;    
    15.0
);

const ShotState shotStateSidePosEyeLookAtCam = ShotState
(
    vCamLeftSidePosA,
    vTargetLeftSidePosA,    
    vFocusLeftSidePosA,
    LOOK_MODE_CAM,    
    HEAD_MODE_FORWARDS,
    15.0
);

const ShotState shotStateSidePosHeadTurn = ShotState
(
    vCamLeftSidePosA,
    vTargetLeftSidePosA, 
    vFocusLeftSidePosA,
    LOOK_MODE_CAM,    
    HEAD_MODE_TRACK,
    15.0
);

const ShotState shotStateFrontPosLookAtCam = ShotState
(
    vCamFrontPosA,
    vTargetFrontPosA,
    vFocusFrontPosA,
    LOOK_MODE_CAM, 
    HEAD_MODE_TRACK,
    15.0
);


const ShotState shotStateFrontPosLookRandom = ShotState
(
    vCamFrontPosA,
    vTargetFrontPosA, 
    vFocusFrontPosA,
    LOOK_MODE_RANDOM,    
    HEAD_MODE_TRACK,
    15.0
);


const ShotState shotStateAboveRandom = ShotState
(
    vCamAbove,
    vTargetFrontPosA,    
    vFocusFrontPosA,
    LOOK_MODE_RANDOM,    
    HEAD_MODE_TRACK,
    15.0
);

const ShotState shotStateAboveCam = ShotState
(
    vCamAbove,
    vTargetFrontPosA,
    vFocusFrontPosA,
    LOOK_MODE_CAM,    
    HEAD_MODE_TRACK,
    15.0
);

const ShotState shotStateNose = ShotState
(
    vCamNose,
    vTargetNose, 
    vFocusNose,
    LOOK_MODE_CAM,    
    HEAD_MODE_TRACK,
    15.0
);

vec3 GetRandomLookDir( float fSceneTime )
{
    return vec3( sin(fSceneTime) * 1.0, -0.1 + sin(fSceneTime * 0.456) * 0.5, 2.0);
}

vec3 GetRandomLookDirDarting( float fSceneTime )
{
    float fT = fSceneTime * 0.5;
    
    float fTimeA = floor( fT );
    float fTimeB = fTimeA + 1.0;
    
    float fTimeFrac = fract( fT );
    
    vec3 vDirA = GetRandomLookDir( fTimeA );
    vec3 vDirB = GetRandomLookDir( fTimeB );
    
    float t = smoothstep( 0.8, 1.0, fTimeFrac );
    
    return mix(vDirA, vDirB, t);
}


vec3 GetAnimTarget( int lookMode, float fSceneTime, vec3 vCamPos )
{
    vec3 vTarget;
    switch( lookMode )
    {
        default:
        case LOOK_MODE_FORWARDS:
        	vTarget = vec3( 0.0, 0.0, 2.0);        	
        break;
        
        case LOOK_MODE_CAM:
        	vTarget = vCamPos;
        break;
        
        case LOOK_MODE_RANDOM:
        	vTarget = GetRandomLookDirDarting( fSceneTime );
        break;
    }
    
    return vTarget;
}

vec3 GetAnimHeadAngles( int headMode, AnimState animState )
{
    vec3 vHeadAngles = vec3(0);
    
    switch( headMode )
    {
        default:
        case HEAD_MODE_FORWARDS:
        break;
        
        case HEAD_MODE_TRACK:
			vHeadAngles = vec3( animState.vEyeTarget.y * 0.075, -animState.vEyeTarget.x * 0.05, -animState.vEyeTarget.x * 0.05 * 0.1 );
        break;
    }
    
    return vHeadAngles;
}

void GenericShot( StageState stageState, inout CameraState cam, inout AnimState animState, ShotState start, ShotState end )
{
    float t = smoothstep( 0.0, 1.0, stageState.fFraction );

    cam.vPos = mix( start.vCam, end.vCam, t );    
    cam.vTarget = mix( start.vTarget, end.vTarget, t );   
        
    vec3 vLookStart = GetAnimTarget( start.lookMode, stageState.fSceneTime, cam.vPos );
    vec3 vLookEnd = GetAnimTarget( end.lookMode, stageState.fSceneTime, cam.vPos );
    
    animState.vEyeTarget = mix(vLookStart, vLookEnd, t);
    
    vec3 vHeadAnglesStart = GetAnimHeadAngles( start.headMode, animState );
    vec3 vHeadAnglesEnd = GetAnimHeadAngles( end.headMode, animState );
            
    animState.vHeadAngles = mix( vHeadAnglesStart, vHeadAnglesEnd, t );
        
    vec3 vFocus = mix( start.vFocus, end.vFocus, t );
    vec3 vToFocus = cam.vPos - vFocus;
    vec3 vCamDir = normalize( cam.vTarget - cam.vPos );
    cam.fPlaneInFocus = dot(vCamDir, vToFocus);
}

void SceneAnimation( float fTime, inout CameraState cam, inout AnimState animState )
{
    const int 
        STAGE_BEGIN = 0,
        STAGE_B = 1,
        STAGE_C = 2,
        STAGE_D = 3,
        STAGE_E = 4,
        STAGE_F = 5,
        STAGE_G = 6,
        STAGE_H = 7,
        STAGE_I = 8,
        STAGE_J = 9,
        STAGE_K = 10,
        STAGE_L = 11,
        STAGE_M = 12,
        STAGE_BLEND_FINAL = 98,
        STAGE_END = 99;

    struct AnimStage
    {
        int stageId;
        float fLength;
    };

    AnimStage g_animStages[] = AnimStage[]
    (
        AnimStage( STAGE_BEGIN, 13.0 ),
        AnimStage( STAGE_B, 8.0 ),
        AnimStage( STAGE_C, 10.0 ),
        AnimStage( STAGE_D, 10.0 ),
        AnimStage( STAGE_E, 3.0 ),
        AnimStage( STAGE_F, 5.0 ),
        AnimStage( STAGE_G, 10.0 ),
        AnimStage( STAGE_H, 2.0 ),
        AnimStage( STAGE_I, 2.0 ),
        AnimStage( STAGE_J, 10.0 ),
        AnimStage( STAGE_K, 10.0 ),
        AnimStage( STAGE_L, 5.0 ),
        AnimStage( STAGE_M, 5.0 ),
        AnimStage( STAGE_BLEND_FINAL, 5.0 ),
        

        AnimStage( STAGE_END, 100.0 )
    );
    
    StageState stageState;
    stageState.fSceneTime = fTime;
    stageState.stageId = STAGE_END;
    stageState.fBegin = 0.0f;
    stageState.fTime = 0.0f;
    stageState.fLength = 1.0f;
    stageState.fFraction = 0.0f;

    float fStageBegin = 0.0f;
    
    for ( int stageIndex = 0; stageIndex < g_animStages.length(); stageIndex++ )
    {
        AnimStage stage = g_animStages[stageIndex];
        float fStageTime = fTime - fStageBegin;
        
        if ( fStageTime >= 0.0 && fStageTime < stage.fLength )
        {
            stageState.stageId = stage.stageId;
            stageState.fBegin = fStageBegin;
            stageState.fTime = fStageTime;
            stageState.fLength = stage.fLength;
            stageState.fFraction = stageState.fTime / stage.fLength;
            break;
        }
        
        fStageBegin += stage.fLength;
    }
    
       
    ShotState shotOrbit;
    
    float d = 1.0 + (cos( fTime * 0.1323 ) * 0.5 + 0.5) * 1.5;
    float xr = sin( fTime * 0.1345 ) * PI * 0.3;
    float yr = cos( fTime * 0.08913 ) * PI * 0.1;
    shotOrbit.vTarget = vec3(0,-0.2,-0.6);
	shotOrbit.vCam = shotOrbit.vCam + vec3(sin(xr) * cos( yr ), sin(yr), cos(xr) * cos( yr ))  * d;    
    shotOrbit.vFocus = shotOrbit.vTarget;
    shotOrbit.lookMode = LOOK_MODE_CAM;
	shotOrbit.headMode = HEAD_MODE_FORWARDS;
	float l = length( shotOrbit.vCam - shotOrbit.vTarget);
    shotOrbit.fov = 15.0 / ( 1.0 + l * 0.1 );

    switch( stageState.stageId )
    {
        case STAGE_BEGIN:
        	GenericShot( stageState, cam, animState, shotStateZoomInOnEye, shotStateEyePanOut );
        break;
        
        case STAGE_B:
        	GenericShot( stageState, cam, animState, shotStateEyePanOut, shotStateEyeLookAround );
        break;
        
        case STAGE_C:        
        	GenericShot( stageState, cam, animState, shotStateEyeLookAround, shotStateSidePosRandom );
        break;
        
        case STAGE_D:    
        	GenericShot( stageState, cam, animState, shotStateSidePosRandom, shotStateSidePosEyeLookAtCam );
        break;

        case STAGE_E:        
        	GenericShot( stageState, cam, animState, shotStateSidePosEyeLookAtCam, shotStateSidePosHeadTurn );
        break;
        
        case STAGE_F:        
        	GenericShot( stageState, cam, animState, shotStateSidePosHeadTurn, shotStateFrontPosLookAtCam );
        break;
        
        case STAGE_G:        
        	GenericShot( stageState, cam, animState, shotStateFrontPosLookAtCam, shotStateFrontPosLookRandom );
        break;
        
        case STAGE_H:                
        	GenericShot( stageState, cam, animState, shotStateAboveRandom, shotStateAboveCam );
        break;
        
        case STAGE_I:                
        	GenericShot( stageState, cam, animState, shotStateAboveCam, shotStateAboveCam );
        break;        

        case STAGE_J:                
        	GenericShot( stageState, cam, animState, shotStateAboveCam, shotStateFrontPosLookAtCam );
        break;        

        case STAGE_K:                
        	GenericShot( stageState, cam, animState, shotStateFrontPosLookAtCam, shotStateFrontPosLookRandom );
        break;        

        case STAGE_L:                
        	GenericShot( stageState, cam, animState, shotStateFrontPosLookRandom, shotStateNose );
        break;        

        case STAGE_M:                
        	GenericShot( stageState, cam, animState, shotStateNose, shotStateNose );
        break;   
        
        case STAGE_BLEND_FINAL:
        	GenericShot( stageState, cam, animState, shotStateNose, shotOrbit );
            cam.fPlaneInFocus = -1.0;
        break;

        case STAGE_END:
        {            
        	GenericShot( stageState, cam, animState, shotOrbit, shotOrbit );
            cam.fPlaneInFocus = -1.0;
            
            float fEyeTime = fTime;
            float fEyeModeTime = fTime / 10.0;
            int fEyeModeNow = int( floor( fEyeModeTime ) );
            int fEyeModeNext = fEyeModeNow + 1;
            
            int lookModeCurr = ((fEyeModeNow % 2) == 0) ? LOOK_MODE_CAM : LOOK_MODE_RANDOM;
            int lookModeNext = ((fEyeModeNext % 2) == 0) ? LOOK_MODE_CAM : LOOK_MODE_RANDOM;
            
            vec3 vTargetCurr = GetAnimTarget( lookModeCurr, fTime, cam.vPos );
            vec3 vTargetNext = GetAnimTarget( lookModeNext, fTime, cam.vPos );
            
            float t = clamp( mod( fEyeModeTime, 10.0), 0.0, 1.0 );
			animState.vEyeTarget = mix(vTargetCurr, vTargetNext, t);
			animState.vHeadAngles =  GetAnimHeadAngles( HEAD_MODE_FORWARDS, animState );
        }
        break;
    }
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	//vec2 gBloomSize = min( vec2(320.0, 240.0), iResolution.xy );
    vec2 vBloomSize = iResolution.xy / 4.0;//min( vec2(320.0, 240.0), iResolution.xy );
    
    vec2 vBloomCoord = fragCoord.xy;
    vBloomCoord.y -= 1.0;
    
	vec2 vUV = vBloomCoord.xy / vBloomSize;
    
    if ( vUV.x > 1.0 || vUV.y > 1.0 ) 
    {
        discard;
        return;
    }

    // output linear color
    //fragColor = texture( iChannel0, vUV );
    //return;
   

	vec3 vResult = vec3(0.0);
    
    vResult = GetBloom( vBloomSize, vBloomCoord, vUV );
    
    
    vec4 vPrevSample = texelFetch( iChannel1, ivec2(fragCoord), 0 ).rgba;
    vResult = max( vResult, vPrevSample.xyz * vec3(0.5, 0.6, 0.7) );

/*
    ivec2 iFragCoord = ivec2( fragCoord.xy );
    if( iFragCoord.y == 0 )
    {
     	vResult = vec3(1000.0); 
    }
*/
    fragColor = vec4(vResult, 1.0);
    
    // State Update...
    

    float fReduction = 1.0;
    if ( Key_IsToggled( iChannelKeyboard, KEY_R ) )
    {
        //fReduction = clamp( 30.0 * iTimeDelta - 0.5, 1.0, 4.0 );
    	fReduction = 4.0f;
    }
    vec2 vReducedResolution = iResolution.xy / fReduction;    

    ivec2 iAddr = ivec2(fragCoord.xy);
    
    if ( iAddr.y != 0 ) return;
    
    // Setup Cam
    CameraState cam;
    AnimState animState;
    
    // Set defaults
    cam.vPos = vec3(0,0.1,3.0);
    cam.vTarget = vec3(0,-0.25, 0);
    cam.vUp = vec3(0,1,0);
    cam.fFov = 15.0;
    cam.fPlaneInFocus = length(cam.vTarget - cam.vPos);
    cam.vJitter = vec2(0.0);        
    
	animState.vEyeTarget = cam.vPos;
    animState.vHeadAngles = vec3(0);

        
    SceneAnimation( iTime, cam, animState );
    
    
    // Update FlyCam
    FlyCamState flyCam;
    FlyCam_LoadState( flyCam, iChannelState, ivec2(8,0) );
    
	FlyCam_Init( flyCam, vec3(-0.1, 0.2, 3.5), vec3(.1, PI, 0) );
    
    if ( Key_IsToggled( iChannelKeyboard, KEY_SPACE ) )
    {
		FlyCam_Update( flyCam );
        
        vec3 vForwards, vRight, vUp;
        FlyCam_GetAxes( flyCam, vRight, vUp, vForwards );

        cam.vPos = flyCam.vPos;
        cam.vTarget = flyCam.vPos + vForwards;
        cam.vUp = vUp;
        cam.fPlaneInFocus = length(flyCam.vPos);        
        
        vec3 vEyeTarget = cam.vPos;
        if ( Key_IsToggled( iChannelKeyboard, KEY_F ) )
        {
            vEyeTarget = GetRandomLookDirDarting( iTime );
        }       

        animState.vEyeTarget = vEyeTarget;

        float xr = vEyeTarget.y * 0.075;
        float yr = -vEyeTarget.x * 0.05;

        if ( Key_IsToggled( iChannelKeyboard, KEY_G ) )
        {
            xr = 0.0;
            yr = 0.0;
        }

        animState.vHeadAngles = vec3( xr, yr, yr * 0.1 );
        
        cam.fPlaneInFocus = -1.0; // auto focus
    }    
    else
    {
		flyCam.vPos = cam.vPos;
    }
    
#ifdef ENABLE_TAA_JITTER
    cam.vJitter = hash21( fract( iTime ) ) - 0.5f;
#endif    

	Cam_StoreState( ivec2(0), cam, fragColor, iAddr );    
	//Cam_StoreState( ivec2(4,0), camPrev, fragColor, iAddr );    
    FlyCam_StoreState( ivec2(8,0), flyCam, fragColor, iAddr );
    
    StoreVec4( ADDR_RESOLUTION, vec4( vReducedResolution,0,0 ), fragColor, iAddr );
    
    AnimState_StoreState( ADDR_ANIMSTATE, animState, fragColor, iAddr );       
}
