// Buffer C (buffer) — [SH16B] Mach 1 by P_Malin
// https://www.shadertoy.com/view/MttGz4

// Depth of field / motion blur effect

///////////////////////////
// Data Storage
///////////////////////////

vec4 LoadVec4( sampler2D sampler, in ivec2 vAddr )
{
    return texelFetch( sampler, vAddr, 0 );
}

vec3 LoadVec3( sampler2D sampler, in ivec2 vAddr )
{
    return LoadVec4( sampler, vAddr ).xyz;
}

bool AtAddress( vec2 p, vec2 c ) { return all( equal( floor(p), floor(c) ) ); }

void StoreVec4( in vec2 vAddr, in vec4 vValue, inout vec4 fragColor, in vec2 fragCoord )
{
    fragColor = AtAddress( fragCoord, vAddr ) ? vValue : fragColor;
}

void StoreVec3( in vec2 vAddr, in vec3 vValue, inout vec4 fragColor, in vec2 fragCoord )
{
    StoreVec4( vAddr, vec4( vValue, 0.0 ), fragColor, fragCoord);
}

///////////////////////////
// Camera
///////////////////////////

struct CameraState
{
    vec3 vPos;
    vec3 vTarget;
    float fFov;
    float fAperture;
};
    
void Cam_LoadState( out CameraState cam, sampler2D sampler, ivec2 addr )
{
    vec4 posAperture = LoadVec4( sampler, addr + ivec2(0,0) );
    cam.vPos = posAperture.xyz;
    cam.fAperture = posAperture.w;
    vec4 targetFov = LoadVec4( sampler, addr + ivec2(1,0) );
    cam.vTarget = targetFov.xyz;
    cam.fFov = targetFov.w;
}

void Cam_StoreState( vec2 addr, const in CameraState cam, inout vec4 fragColor, in vec2 fragCoord )
{
    StoreVec4( addr + vec2(0,0), vec4( cam.vPos, cam.fAperture ), fragColor, fragCoord );
    StoreVec4( addr + vec2(1,0), vec4( cam.vTarget, cam.fFov ), fragColor, fragCoord );    
}

mat3 Cam_GetWorldToCameraRotMatrix( const CameraState cameraState )
{
    vec3 vForward = normalize( cameraState.vTarget - cameraState.vPos );
	vec3 vRight = normalize( cross(vec3(0, 1, 0), vForward) );
	vec3 vUp = normalize( cross(vForward, vRight) );
    
    return mat3( vRight, vUp, vForward );
}

vec2 Cam_GetViewCoordFromUV( const in vec2 vUV )
{
	vec2 vWindow = vUV * 2.0 - 1.0;
	vWindow.x *= iResolution.x / iResolution.y;

	return vWindow;	
}

void Cam_GetCameraRay( const vec2 vUV, const CameraState cam, out vec3 vRayOrigin, out vec3 vRayDir )
{
    vec2 vView = Cam_GetViewCoordFromUV( vUV );
    vRayOrigin = cam.vPos;
    float fPerspDist = 1.0 / tan( radians( cam.fFov ) );
    vRayDir = normalize( Cam_GetWorldToCameraRotMatrix( cam ) * vec3( vView, fPerspDist ) );
}

vec2 Cam_GetUVFromWindowCoord( const in vec2 vWindow )
{
    vec2 vScaledWindow = vWindow;
    vScaledWindow.x *= iResolution.y / iResolution.x;

    return vScaledWindow * 0.5 + 0.5;
}

vec2 Cam_WorldToWindowCoord(const in vec3 vWorldPos, const in CameraState cameraState )
{
    vec3 vOffset = vWorldPos - cameraState.vPos;
    vec3 vCameraLocal;

    vCameraLocal = vOffset * Cam_GetWorldToCameraRotMatrix( cameraState );
	
    vec2 vWindowPos = vCameraLocal.xy / (vCameraLocal.z * tan( radians( cameraState.fFov ) ));
    
    return vWindowPos;
}

///////////////////////////////////////////////


float GetCoC( float fDistance, float fPlaneInFocus, float fAperture )
{
	// http://http.developer.nvidia.com/GPUGems/gpugems_ch23.html

    float fFocalLength = 0.15;
    
    if ( iMouse.z > 0.0 )
    {
        fFocalLength += (iMouse.y / iResolution.y) * 0.5;
    }
    
	return abs(fAperture * (fFocalLength * (fDistance - fPlaneInFocus)) /
          (fDistance * (fPlaneInFocus - fFocalLength)));  
}

// Random

#define MOD2 vec2(4.438975,3.972973)
#define HASHSCALE1 443.8975
#define HASHSCALE3 vec3(443.897, 441.423, 437.195)
#define HASHSCALE4 vec3(443.897, 441.423, 437.195, 444.129)

float Hash( float p ) 
{
    // https://www.shadertoy.com/view/4djSRW - Dave Hoskins
	vec2 p2 = fract(vec2(p) * MOD2);
    p2 += dot(p2.yx, p2.xy+19.19);
	return fract(p2.x * p2.y);    
}

vec2 Hash23(vec3 p3)
{
	p3 = fract(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract(vec2((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y));
}


#define MOTION_BLUR_TAPS 32

float fGolden = 3.141592 * (3.0 - sqrt(5.0));

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 vUV = fragCoord.xy / iResolution.xy;

    // output linear color
    //fragColor = texture( iChannel0, vUV );
    //return;
    
    vec4 vSample = textureLod( iChannel0, vUV, 0.0 ).rgba;
	
    float fDepth = abs(vSample.w);
    
    CameraState cameraStateCurr;
    Cam_LoadState( cameraStateCurr, iChannel0, ivec2(0,0) );
    
    CameraState cameraStatePrev;
    Cam_LoadState( cameraStatePrev, iChannel0, ivec2(2,0) );

    vec4 vCarVel = LoadVec4( iChannel0, ivec2(4,0) );
   
    float fShutterAngle = 0.5;
    
    if ( iMouse.z > 0.0 )
    {
        fShutterAngle = (iMouse.x / iResolution.x);
    }
    
    
    cameraStatePrev.vPos = mix( cameraStateCurr.vPos, cameraStatePrev.vPos, fShutterAngle );
    cameraStatePrev.vTarget = mix( cameraStateCurr.vTarget, cameraStatePrev.vTarget, fShutterAngle );
    cameraStatePrev.fFov = mix( cameraStateCurr.fFov, cameraStatePrev.fFov, fShutterAngle );
    cameraStatePrev.fAperture = mix( cameraStateCurr.fAperture, cameraStatePrev.fAperture, fShutterAngle );
        
    //cameraStatePrev.vTarget.z -= 2.0;
    //cameraStatePrev.vPos.z -= 2.0;
    
    //cameraStatePrev.fFov -= 10.0;

    if( vSample.a < 0.0 )
    {
    	cameraStatePrev.vTarget.z += vCarVel.x * fShutterAngle;
    	cameraStatePrev.vPos.z += vCarVel.x * fShutterAngle;
        
    }    


    
	vec3 vCameraPos, vRayDir;
    Cam_GetCameraRay( vUV, cameraStateCurr, vCameraPos, vRayDir );
        
    vec3 vWorldPos = vCameraPos + vRayDir * fDepth;
    
    //fragColor.xyz = fract( vWorldPos );
    //fragColor.a = 1.0;
    //return;
    
    vec2 vPrevWindow = Cam_WorldToWindowCoord( vWorldPos, cameraStatePrev );
    vec2 vPrevUV = Cam_GetUVFromWindowCoord( vPrevWindow );

    // No motion blur for FG objects
    //if( vSample.a < 0.0 )
    //{
      //  vPrevUV = vUV;
    //}
        
	vec3 vResult = vec3(0.0);
    
    float fTot = 0.0;
    
    float fPlaneInFocus = length(cameraStateCurr.vPos - cameraStateCurr.vTarget);
    
    float fCoC = GetCoC( abs(fDepth), fPlaneInFocus, cameraStateCurr.fAperture );
    
    float r = 1.0;
    vec2 vangle = vec2(0.0,fCoC); // Start angle
    
    vResult.rgb = vec3(0.0);//vSample.rgb * fCoC;
    fTot += 0.0;//fCoC;
    
    float fMotionBlurTaps = float(MOTION_BLUR_TAPS);
    
    float fAspect = iResolution.y / iResolution.x;
    
    float f = 0.0;
    float fIndex = 0.0;
    for(int i=1; i<MOTION_BLUR_TAPS; i++)
    {
        vec2 vTapUV = mix( vUV, vPrevUV, f - .5);
                
        vec2 vRand = Hash23( vec3( vUV.x, vUV.y, fract(iTime * .123 + fIndex * 1.234) ) );
        //float fRand = Hash2( iTime + fIndex + vUV.x + vUV.y * 12.345);
        
        // http://blog.marmakoide.org/?p=1
        
        float fTheta = vRand.x * 3.14 * 2.0;//fRand * fGolden * fMotionBlurTaps;
        //float fRadius = fCoC * sqrt( vRand.y ); // uniform disc
        float fRadius = fCoC * pow( vRand.y, 0.4 ); // less dense centre
        
        //float fRadius = fCoC * sqrt( fRand * fMotionBlurTaps ) / sqrt( fMotionBlurTaps );        
        
        vTapUV += vec2( sin(fTheta) * fAspect, cos(fTheta) ) * fRadius;
        
        //vTapUV.y = abs( vTapUV.y );
        
        vec4 vTapSample = textureLod( iChannel0, vTapUV, 0.0 ).rgba;        
        if( vTapUV.y < 1.0 / iResolution.y )
        {
            vTapSample = vec4(0.0);
        }        
        //if(vTapUV.y > 0.0)
        if( sign(vTapSample.a) == sign(vSample.a) )
        {
  		  	float fCurrCoC = GetCoC( abs(vTapSample.a), fPlaneInFocus, cameraStateCurr.fAperture );
            
            float fWeight = fCurrCoC;
            
    		vResult += vTapSample.rgb * fWeight;
        	fTot += fWeight;
        }
        f += 1.0 / fMotionBlurTaps;
        fIndex += 1.0;
    }
    vResult /= fTot;
        
    // Draw depth
    //vFinal = vec3(1.0) / abs(vSample.a);    
    
    // passthrough depth
	fragColor = vec4(vResult, vSample.a);

    Cam_StoreState( vec2(0,0), cameraStateCurr, fragColor, fragCoord );
}
