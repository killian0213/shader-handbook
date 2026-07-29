// Buffer B (buffer) — [SH16B] Mach 1 by P_Malin
// https://www.shadertoy.com/view/MttGz4

// Scene Render

#define kMaxTraceDist 1000.0
#define kFarDist 1100.0

#define MAT_FG_BEGIN 	10.0

#define PI 3.141592654

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

///////////////////////////
// Scene
///////////////////////////

struct SceneResult
{
	float fDist;
	float fObjectId;
    vec3 vUVW;
};

SceneResult Scene_Union( const in SceneResult a, const in SceneResult b )
{
    if ( a.fDist < b.fDist )
    {
        return a;
    }
    return b;
}
    
SceneResult Scene_Subtract( const in SceneResult a, const in SceneResult b )
{
    if ( -a.fDist < b.fDist )
    {
        return a;
    }

    SceneResult result;
    result.fDist = -b.fDist;
    result.fObjectId = b.fObjectId;
    result.vUVW = b.vUVW;
    return result;
}

SceneResult Scene_Intersection( const in SceneResult a, const in SceneResult b )
{
    if ( a.fDist > b.fDist )
    {
        return a;
    }
    return b;
}
    
SceneResult Scene_GetDistance( const vec3 vPos );    

vec3 Scene_GetNormal(const in vec3 vPos)
{
    const float fDelta = 0.001;
    vec2 e = vec2( -1, 1 );
    
    vec3 vNormal = 
        Scene_GetDistance( vPos + e.yxx * fDelta ).fDist * e.yxx + 
        Scene_GetDistance( vPos + e.xxy * fDelta ).fDist * e.xxy + 
        Scene_GetDistance( vPos + e.xyx * fDelta ).fDist * e.xyx + 
        Scene_GetDistance( vPos + e.yyy * fDelta ).fDist * e.yyy;
    
    if ( dot( vNormal, vNormal ) < 0.00001 )
    {
        return vec3(0, 1, 0);
    }
    
    return normalize( vNormal );
}    
    
SceneResult Scene_Trace( const in vec3 vRayOrigin, const in vec3 vRayDir, float maxDist )
{	
    SceneResult result;
    result.fDist = 0.0;
    result.vUVW = vec3(0.0);
    result.fObjectId = 0.0;
    
	float t = 0.1;
	const int kRaymarchMaxIter = 128;
	for(int i=0; i<kRaymarchMaxIter; i++)
	{		
		result = Scene_GetDistance( vRayOrigin + vRayDir * t );		
        t += result.fDist;

        if ( abs(result.fDist) < 0.001 )
		{
			break;
		}		
        if ( t > maxDist )
        {
            result.fObjectId = -1.0;
	        t = maxDist;
            break;
        }
	}
    
    result.fDist = t;

    return result;
}    

float Scene_TraceShadow( const in vec3 vRayOrigin, const in vec3 vRayDir, const in float fLightDist )
{
    //return 1.0;
    //return Scene_Trace( vRayOrigin, vRayDir, fLightDist ).fDist < fLightDist ? 0.0 : 1.0;
    
    float mint = 0.02, tmax = 5.0;
	float res = 1.0;
    float t = mint;
    for( int i=0; i<16; i++ )
    {
		float h = Scene_GetDistance( vRayOrigin + vRayDir * t ).fDist;
        res = min( res, 10.0*h/t );
        t += clamp( h, 0.02, 0.40 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 ) * 0.75 + 0.25;    
}

float Scene_GetAmbientOcclusion( const in vec3 vPos, const in vec3 vDir )
{
    float fOcclusion = 0.0;
    float fScale = 1.0;
    for( int i=0; i<5; i++ )
    {
        float fOffsetDist = 0.01 + 1.0*float(i)/4.0;
        vec3 vAOPos = vDir * fOffsetDist + vPos;
        float fDist = Scene_GetDistance( vAOPos ).fDist;
        fOcclusion += (fOffsetDist - fDist) * fScale;
        fScale *= 0.4;
    }
    
    return clamp( 1.0 - 2.0*fOcclusion, 0.0, 1.0 );
}

///////////////////////////
// Lighting
///////////////////////////
    
struct SurfaceInfo
{
    vec3 vPos;
    vec3 vNormal;
    vec3 vBumpNormal;    
    vec3 vAlbedo;
    vec3 vR0;
    float fSmoothness;
    vec3 vEmissive;
};
    
SurfaceInfo Scene_GetSurfaceInfo( const in vec3 vRayOrigin,  const in vec3 vRayDir, SceneResult traceResult );

struct SurfaceLighting
{
    vec3 vDiffuse;
    vec3 vSpecular;
};
    
SurfaceLighting Scene_GetSurfaceLighting( const in vec3 vRayDir, in SurfaceInfo surfaceInfo );

float Light_GIV( float dotNV, float k)
{
	return 1.0 / ((dotNV + 0.0001) * (1.0 - k)+k);
}

void Light_Add(inout SurfaceLighting lighting, SurfaceInfo surface, const in vec3 vViewDir, const in vec3 vLightDir, const in vec3 vLightColour)
{
	float fNDotL = clamp(dot(vLightDir, surface.vBumpNormal), 0.0, 1.0);
	
	lighting.vDiffuse += vLightColour * fNDotL;
    
	vec3 vH = normalize( -vViewDir + vLightDir );
	float fNdotV = clamp(dot(-vViewDir, surface.vBumpNormal), 0.0, 1.0);
	float fNdotH = clamp(dot(surface.vBumpNormal, vH), 0.0, 1.0);
    
	float alpha = 1.0 - surface.fSmoothness;
	// D

	float alphaSqr = alpha * alpha;
	float pi = 3.14159;
	float denom = fNdotH * fNdotH * (alphaSqr - 1.0) + 1.0;
	float d = alphaSqr / (pi * denom * denom);

	float k = alpha / 2.0;
	float vis = Light_GIV(fNDotL, k) * Light_GIV(fNdotV, k);

	float fSpecularIntensity = d * vis * fNDotL;    
	lighting.vSpecular += vLightColour * fSpecularIntensity;    
}

void Light_AddPoint(inout SurfaceLighting lighting, SurfaceInfo surface, const in vec3 vViewDir, const in vec3 vLightPos, const in vec3 vLightColour)
{    
    vec3 vPos = surface.vPos;
	vec3 vToLight = vLightPos - vPos;	
    
	vec3 vLightDir = normalize(vToLight);
	float fDistance2 = dot(vToLight, vToLight);
	float fAttenuation = 100.0 / (fDistance2);
	
	float fShadowFactor = Scene_TraceShadow( surface.vPos, vLightDir, length(vToLight) );
	
	Light_Add( lighting, surface, vViewDir, vLightDir, vLightColour * fShadowFactor * fAttenuation);
}

void Light_AddDirectional(inout SurfaceLighting lighting, SurfaceInfo surface, const in vec3 vViewDir, const in vec3 vLightDir, const in vec3 vLightColour)
{	
	float fAttenuation = 1.0;
	float fShadowFactor = Scene_TraceShadow( surface.vPos, vLightDir, 10.0 );
	
	Light_Add( lighting, surface, vViewDir, vLightDir, vLightColour * fShadowFactor * fAttenuation);
}

vec3 Light_GetFresnel( vec3 vView, vec3 vNormal, vec3 vR0, float fGloss )
{
    float NdotV = max( 0.0, dot( vView, vNormal ) );

    return vR0 + (vec3(1.0) - vR0) * pow( 1.0 - NdotV, 5.0 ) * pow( fGloss, 20.0 );
}

void Env_AddPointLightFlare(inout vec3 vEmissiveGlow, const in vec3 vRayOrigin, const in vec3 vRayDir, const in float fIntersectDistance, const in vec3 vLightPos, const in vec3 vLightColour)
{
    vec3 vToLight = vLightPos - vRayOrigin;
    float fPointDot = dot(vToLight, vRayDir);
    fPointDot = clamp(fPointDot, 0.0, fIntersectDistance);

    vec3 vClosestPoint = vRayOrigin + vRayDir * fPointDot;
    float fDist = length(vClosestPoint - vLightPos);
	vEmissiveGlow += sqrt(vLightColour * 0.05 / (fDist * fDist));
}

void Env_AddDirectionalLightFlareToFog(inout vec3 vFogColour, const in vec3 vRayDir, const in vec3 vLightDir, const in vec3 vLightColour)
{
	float fDirDot = clamp(dot(vLightDir, vRayDir) * 0.5 + 0.5, 0.0, 1.0);
	float kSpreadPower = 2.0;
	vFogColour += vLightColour * pow(fDirDot, kSpreadPower) * 0.25;
}


///////////////////////////
// Rendering
///////////////////////////

vec4 Env_GetSkyColor( const vec3 vViewPos, const vec3 vViewDir );
vec3 Env_ApplyAtmosphere( const in vec3 vColor, const in vec3 vRayOrigin,  const in vec3 vRayDir, const in float fDist);
vec3 FX_Apply( in vec3 vColor, const in vec3 vRayOrigin,  const in vec3 vRayDir, const in float fDist);

vec4 Scene_GetColorAndDepth( const in vec3 vInRayOrigin, const in vec3 vInRayDir )
{
    vec3 vRayOrigin = vInRayOrigin;
    vec3 vRayDir = vInRayDir;
    
	vec3 vResultColor = vec3(0.0);
	vec3 vPassContribution = vec3(1.0);
            
	SceneResult firstTraceResult;
    
	for( int iPassIndex=0; iPassIndex<3; iPassIndex++ )
	{	        
    	SceneResult traceResult = Scene_Trace( vRayOrigin, vRayDir, kMaxTraceDist );
        
        if ( iPassIndex == 0 )
        {
            firstTraceResult = traceResult;
        }
        
		vec3 vPassColor = vec3(0.0);
		vec3 vReflectance = vec3(1.0);

		if( traceResult.fObjectId < 0.0 )
		{
            break; 
        }
        else
        {
            SurfaceInfo surfaceInfo = Scene_GetSurfaceInfo( vRayOrigin, vRayDir, traceResult );
            SurfaceLighting surfaceLighting = Scene_GetSurfaceLighting( vRayDir, surfaceInfo );
                
            // calculate reflectance (Fresnel)
            float NdotV = clamp( dot(surfaceInfo.vBumpNormal, -vRayDir), 0.0, 1.0);
			vReflectance = Light_GetFresnel( -vRayDir, surfaceInfo.vBumpNormal, surfaceInfo.vR0, surfaceInfo.fSmoothness );
			
			vPassColor = 
                mix( surfaceInfo.vAlbedo * surfaceLighting.vDiffuse + surfaceInfo.vEmissive, surfaceLighting.vSpecular, vReflectance );
        
	        vPassColor = Env_ApplyAtmosphere( vPassColor, vRayOrigin, vRayDir, traceResult.fDist );		
    		vPassColor = FX_Apply( vPassColor, vRayOrigin, vRayDir, traceResult.fDist );
            
            // Reflect Ray
            vRayOrigin = surfaceInfo.vPos;
            vRayDir = normalize( reflect( vRayDir, surfaceInfo.vBumpNormal ) );
        }
                
		vResultColor += vPassColor * vPassContribution;
		vPassContribution *= vReflectance;			        
    }
    
    vec4 vFinalSkyColor = Env_GetSkyColor( vRayOrigin, vRayDir );
    vFinalSkyColor.rgb = Env_ApplyAtmosphere( vFinalSkyColor.rgb, vRayOrigin, vRayDir, vFinalSkyColor.a );		
	vFinalSkyColor.rgb = FX_Apply( vFinalSkyColor.rgb, vRayOrigin, vRayDir, vFinalSkyColor.a );
    vResultColor += vFinalSkyColor.rgb * vPassContribution;
    
    //vResultColor = FX_Apply( vResultColor, vInRayOrigin, vInRayDir, firstTraceResult.fDist );
    
    if ( firstTraceResult.fObjectId >= MAT_FG_BEGIN )
    {
        firstTraceResult.fDist = -firstTraceResult.fDist;
    }
    
    return vec4( vResultColor, firstTraceResult.fDist );
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////
// Utility Functions
///////////////////////////

#define MOD2 vec2(4.438975,3.972973)

float Hash( float p ) 
{
    // https://www.shadertoy.com/view/4djSRW - Dave Hoskins
	vec2 p2 = fract(vec2(p) * MOD2);
    p2 += dot(p2.yx, p2.xy+19.19);
	return fract(p2.x * p2.y);    
	//return fract(sin(n)*43758.5453);
}

float SmoothNoise(in vec2 o) 
{
	vec2 p = floor(o);
	vec2 f = fract(o);
		
	float n = p.x + p.y*57.0;

	float a = Hash(n+  0.0);
	float b = Hash(n+  1.0);
	float c = Hash(n+ 57.0);
	float d = Hash(n+ 58.0);
	
	vec2 f2 = f * f;
	vec2 f3 = f2 * f;
	
	vec2 t = 3.0 * f2 - 2.0 * f3;
	
	float u = t.x;
	float v = t.y;

	float res = a + (b-a)*u +(c-a)*v + (a-b+d-c)*u*v;
    
    return res;
}


vec3 SmoothNoise_DXY(in vec2 o) 
{
	vec2 p = floor(o);
	vec2 f = fract(o);
		
	float n = p.x + p.y*57.0;

	float a = Hash(n+  0.0);
	float b = Hash(n+  1.0);
	float c = Hash(n+ 57.0);
	float d = Hash(n+ 58.0);
	
	vec2 f2 = f * f;
	vec2 f3 = f2 * f;
	
	vec2 t = 3.0 * f2 - 2.0 * f3;
	vec2 dt = 6.0 * f - 6.0 * f2;
	
	float u = t.x;
	float v = t.y;
	float du = dt.x;	
	float dv = dt.y;	

	float res = a + (b-a)*u +(c-a)*v + (a-b+d-c)*u*v;
    
	float dx = (b-a)*du + (a-b+d-c)*du*v;
	float dy = (c-a)*dv + (a-b+d-c)*u*dv;    
    
    return vec3(dx, dy, res);
}

vec3 FBM_DXY( vec2 p, vec2 flow, float ps, float df ) {
	vec3 f = vec3(0.0);
    float tot = 0.0;
    float a = 1.0;
    //flow *= 0.6;
    for( int i=0; i<4; i++)
    {
        p += flow;
        flow *= -0.75; // modify flow for each octave - negating this is fun
        vec3 v = SmoothNoise_DXY( p );
        f += v * a;
        p += v.xy * df;
        p *= 2.0;
        tot += a;
        a *= ps;
    }
    return f / tot;
}


/////////////////////////
// Scene Description
/////////////////////////

struct SceneState
{
    vec3 vCarPos;
    float fThruster;
    float fDustTrail;
    float fCarVel;
    float fEffect;
};  
    
SceneState g_sceneState;
    
// Materials

#define MAT_SKY 		-1.0
#define MAT_SAND 		1.0

//#define MAT_WATER 		0.0
//#define MAT_GOLD 		2.0

#define MAT_CHROME 		10.0
#define MAT_CAR_PAINT	11.0


vec3 GetWaterExtinction( float dist )
{
    float fOpticalDepth = dist * 6.0;

    vec3 vExtinctCol = 1.0 - vec3(0.5, 0.4, 0.1);           
    vec3 vExtinction = exp2( -fOpticalDepth * vExtinctCol );
    
    return vExtinction;
}

SurfaceInfo Scene_GetSurfaceInfo( const in vec3 vRayOrigin,  const in vec3 vRayDir, SceneResult traceResult )
{
    SurfaceInfo surfaceInfo;
    
    surfaceInfo.vPos = vRayOrigin + vRayDir * (traceResult.fDist);
    
    surfaceInfo.vNormal = Scene_GetNormal( surfaceInfo.vPos ); 
    surfaceInfo.vBumpNormal = surfaceInfo.vNormal;
    surfaceInfo.vAlbedo = vec3(1.0); //fract( surfaceInfo.vPos + 0.1 );
    surfaceInfo.vR0 = vec3( 0.01 );
    surfaceInfo.fSmoothness = 1.0;
    surfaceInfo.vEmissive = vec3( 0.0 );
        
    if ( traceResult.fObjectId == MAT_CHROME )
    {
    	surfaceInfo.vR0 = vec3( 0.3 );
	    surfaceInfo.vAlbedo = vec3( 0.0 );
    }
    /*else
    if ( traceResult.fObjectId == MAT_GOLD )
    {
        surfaceInfo.vR0 = vec3( 0.8, 0.6, 0.1 );
	    surfaceInfo.vAlbedo = vec3( 0.0 );
        
        float f = fract(surfaceInfo.vPos.y);
        if ( f > 0.9 )
        {
            surfaceInfo.vEmissive = vec3( 1, 4, 8 ) * 100.0;
        }
    }
    else
    if ( traceResult.fObjectId == MAT_WATER )
    {
	    surfaceInfo.vR0 = vec3( 0.01 );
        surfaceInfo.fSmoothness = 1.0;
        surfaceInfo.vBumpNormal.xy += FBM_DXY( surfaceInfo.vPos.xz * 2.0, vec2(0), 0.9, 0.2).yz * 0.2;
        surfaceInfo.vBumpNormal = normalize( surfaceInfo.vBumpNormal );
        vec3 vRefractedRay = refract( -vRayDir, surfaceInfo.vBumpNormal, 1.0 / 1.33 );
        float fDepth = vRefractedRay.y;
        float fRayLength = 2.0 / fDepth;
        vec2 vUVOffset = vRefractedRay.xz * fRayLength;
        surfaceInfo.vAlbedo = texture( iChannel0, surfaceInfo.vPos.xz + vUVOffset ).rgb;
        surfaceInfo.vAlbedo = surfaceInfo.vAlbedo * surfaceInfo.vAlbedo;
        
        surfaceInfo.vAlbedo *= GetWaterExtinction( -fRayLength * 0.25 );
    }*/
    else
    if ( traceResult.fObjectId == MAT_SAND )
    {
    	surfaceInfo.vR0 = vec3( 0.0 );
	    //surfaceInfo.vAlbedo = vec3( 1.0, 0.0, 0.0 );
        vec2 vSandPos = surfaceInfo.vPos.xz + 0.2;
        vec3 vSample1 = texture( iChannel0, vSandPos * 0.05).rgb;
        //vSample1 = vSample1 * vSample1;
        vec3 vSample2 = texture( iChannel0, vSandPos * 0.001).rgb;
        //vSample2 = vSample2 * vSample2;
        surfaceInfo.vAlbedo = vSample1 * vSample2;
        //float f = FBM_DXY( surfaceInfo.vPos.xz * 3.0, vec2(0,0), 0.7, -0.5 ).z;
        //f = f * f;
        //surfaceInfo.vAlbedo = mix( vec3(0.2, 0.1, 0.05), vec3(0.6, 0.5, 0.2), f );
        surfaceInfo.fSmoothness = 0.1;        
        //surfaceInfo.fSmoothness = 1.0 - surfaceInfo.vAlbedo.r;        

        
        // heat haze
        
        //surfaceInfo.vR0 = vec3(0.02);
        //surfaceInfo.fSmoothness = 0.95;
        //surfaceInfo.vBumpNormal.xz += FBM_DXY(surfaceInfo.vPos.xz * 2.0, vec2(iTime, 0.0), 0.5, 0.5 ).xy * .1;
        //surfaceInfo.vBumpNormal = normalize( surfaceInfo.vBumpNormal );
        vec2 vMin = vec2(0.0, -97.5);
        vec2 vMax = vec2(2.0, -95.0);
        vec2 vUV = (surfaceInfo.vPos.xz - vMin) / (vMax - vMin);
		if ( vUV.x > 0.0 && vUV.x < 1.0 &&
            vUV.y > 0.0 && vUV.y < 1.0 )
        {
            float fAmount = max(0.0, 1.0 - surfaceInfo.vAlbedo.r * 2.5);
            surfaceInfo.vAlbedo = mix( vec3(0.1,0.1,.25), vec3(.9,1,1), fAmount );
            
			surfaceInfo.vAlbedo = surfaceInfo.vAlbedo * surfaceInfo.vAlbedo;
        }
    }
    else
    if ( traceResult.fObjectId == MAT_CAR_PAINT )
    {
    	surfaceInfo.vR0 = vec3( 0.02 );
	    surfaceInfo.vAlbedo = vec3( 0.01, 0.01, 0.01 );
        surfaceInfo.fSmoothness = 0.95;       
    }
    
    if ( traceResult.fObjectId == MAT_CAR_PAINT || traceResult.fObjectId == MAT_CHROME )
    {
        vec3 vDirt = mix(texture(iChannel0, traceResult.vUVW.zy * vec2(0.2, 1.0)).rgb, texture(iChannel0, traceResult.vUVW.xy).rgb, abs(surfaceInfo.vNormal.z) ) ;
        float fDirt = vDirt.r;
        
        float fMix = clamp( fDirt - traceResult.vUVW.y * 0.4, 0.0, 1.0 );
        
        vDirt = vDirt * vDirt * 0.15;

        surfaceInfo.vAlbedo = mix( surfaceInfo.vAlbedo, vDirt, fMix );
        surfaceInfo.vR0 = mix( surfaceInfo.vR0, vec3(0.01), fMix );
        surfaceInfo.fSmoothness = mix( surfaceInfo.fSmoothness, 0.01, fMix ); 
    }
    
    return surfaceInfo;
}

// Scene Description

float NozzleDist( vec2 vProfile, float r1, float r2, float l, float thickness )
{
    float f = vProfile.x  / l;
    float fDist = vProfile.y - mix( r1, r2, f );
    fDist = max( fDist, - fDist - thickness );
    fDist = max( fDist, vProfile.x - l );
    fDist = max( fDist, -vProfile.x  );    
    
    return fDist;
}

float ConvexCurveSectionDist( vec2 vProfile, float r1, float r2, float x1, float x2 )
{    
    float l = x2 - x1;
    float curveDR = abs(r2 - r1);
    float circleR = (l * l + curveDR * curveDR) / (2.0 * curveDR);
    float fDist = length( vProfile - vec2(x2, r1 - circleR) )  - circleR;
    
    return fDist;
}

float ConcaveCurveSectionDist( vec2 vProfile, float r1, float r2, float x1, float x2 )
{    
    /*float l = x2 - x1;
    float curveDR = abs(r2 - r1);
    float circleR = (l * l + curveDR * curveDR) / (2.0 * curveDR);
    float fDist = length( vProfile - vec2(0, r1 - circleR) )  - circleR;*/
    
    float l = x2 - x1;
    float curveDR = r2 - r1;    
    float circleR = (l * l + curveDR * curveDR) / (2.0 * curveDR);    
    float fDist = circleR - length( vProfile - vec2(x1, r1 + circleR) );

    fDist = max( fDist, vProfile.y - r2 );
    
    return fDist;
}
    
SceneResult CarCentre_GetDistance( vec3 vPos )
{
    //vPos.y -= clamp(vPos.z, -3.0, 0.0) * 0.1;
    vec2 vProfile = vec2( vPos.z, length( vPos.xy ) );
    
    const float fNoseStartRadius = 0.5;
    const float fNoseEndRadius = 0.1;
    const float fNoseLength = 3.0;
    
    const float fNoseDR = fNoseStartRadius - fNoseEndRadius;
    
    const float frontCurveCircleRadius = (fNoseLength * fNoseLength + fNoseDR * fNoseDR) / (2.0 * fNoseDR);    
    
    //float dist = length( vProfile - vec2(0, fNoseStartRadius-frontCurveCircleRadius) ) - frontCurveCircleRadius;
    
    float dist = ConvexCurveSectionDist( vProfile, fNoseStartRadius, fNoseEndRadius, -fNoseLength, 0.0 );
    
    const float fSpikeLength = 2.0;
    dist = min(dist, vProfile.y - 0.05);
	dist = max(dist, (vProfile.y - 0.05 - (vProfile.x + (fNoseLength + fSpikeLength))) * (1.0 / sqrt(2.0))); // pointy tip    

	// cabin cone
    const float fCCStartRadius = fNoseStartRadius;
    const float fCCEndRadius = 1.0;
    const float fCCLength = 5.0;
    
    float fCCRadius = ConcaveCurveSectionDist(vProfile, fCCStartRadius, fCCEndRadius, 0.0, fCCLength );
    
/*        if ( vProfile.x < 0.0 )
        {
            fCCRadius = 0.0;
        }
        if ( vProfile.x > fCCLength)
        {
            fCCRadius = fCCEndRadius;
        }*/
    
     
    if ( vProfile.x > 0.0 )
    {
    	dist = min ( dist, fCCRadius );
    }
    
    const float rRCEndRadius = 1.5;
    float fRRadius = ConvexCurveSectionDist(vProfile, rRCEndRadius, fCCEndRadius, fCCLength, 15.0 );
    
    dist = min( dist, fRRadius );

    // back end cap
    dist = max( dist, vProfile.x - 14.0 );
    
    // taper body
    dist = max( dist, vPos.x + vPos.z * 0.02 - 0.8 );
    
    // flatten base
    dist = max( dist, -vPos.y - 0.6 );
    
    // Fin Vertical
    
    float fVFinDist = (vPos.y - vPos.z) / sqrt(2.0) + 8.0;
    fVFinDist = max( fVFinDist, abs(vPos.x ) - 0.1 );
    fVFinDist = max( fVFinDist, abs(vPos.y - 1.0 ) - 1.0 );
    fVFinDist = max( fVFinDist, vPos.z - 13.8 );
    dist = min( dist, fVFinDist );
    
    // Fin
    vec3 vFinDir = normalize(vec3( 1.0, -0.5, -0.5 ));
    float fFinDist = dot(vPos - vec3(0.0, 2.0, 11.5), vFinDir) ;
    fFinDist = max( fFinDist, vPos.z - 16.0 );
    fFinDist = max( fFinDist, abs(vPos.y - 2.0 ) - 0.1 );
    dist = min( dist, fFinDist );
    
    SceneResult result = SceneResult( dist, MAT_CAR_PAINT, vec3(vPos) );

    
    if ( -vProfile.x > fNoseLength - 0.1 )
    {
        result.fObjectId = MAT_CHROME;
    }
    
    //result = Scene_Union( result, SceneResult( vProfile.y - 0.05, MAT_CHROME, vec3(0.0) ) );
    
    //vPos.x *= 1.5;
    //SceneResult result = SceneResult( kMaxTraceDist, MAT_SKY, vec3(0.0) );
    
    /*
    vec3 vClosest = vPos;
    vClosest.z = clamp( vClosest.z, 0.0, 4.0 );
        
    float fRadius = 1.0;
    
    fRadius = min( fRadius, smoothstep( 0.0, 1.0, vPos.z * 0.2 + 0.5) );
    
    float fRearRadius = clamp( vPos.z * 0.5 - 5.0 , 0.0, 1.0 );
    fRadius = min( fRadius, sqrt( 1.0 - fRearRadius * fRearRadius )  );
    //fRadius = max(fRadius, -vPos.z * 0.25 );

    //{
//    	fRadius = smoothstep(0.0, 1.0, fRadius);
//    }

    //vClosest.xy = normalize(vClosest.xy) * min( length(vClosest.xy), fRadius );
    
    //float dist = length(vPos - vClosest) - 0.5;
    float dist = length(vPos.xy) - fRadius;
    dist = max( dist, -vPos.z + -10.0 );
    dist = max( dist, vPos.z -8.0 );
    
    //dist /= 1.5;
    */
    
    return result;
}

SceneResult CarEngine_GetDistance( vec3 vPos )
{
    //SceneResult result = SceneResult( kMaxTraceDist, MAT_SKY, vec3(0.0) );
    
    vec2 vProfile = vec2( vPos.z, length( vPos.xy ) );

    float fDist = kMaxTraceDist;
    
    const float fEngineRadius1 = 1.0;
    const float fEngineRadius2 = 0.9;
    const float fEngineRearLength = 7.0;
    
    float fEngineRadiusCurr = mix( fEngineRadius1, fEngineRadius2, vProfile.x  / fEngineRearLength);
    float fCylinderDist = vProfile.y - fEngineRadiusCurr;
    fCylinderDist = max( fCylinderDist, -vProfile.x );
    
    fDist = min( fDist, fCylinderDist );
    
    const float fEngineFrontCurveLength = 1.5;
    const float fEngineFrontCurveRadius = 0.6;
    
    float frontCurveDist = ConvexCurveSectionDist( vProfile, fEngineRadius1, fEngineFrontCurveRadius, -fEngineFrontCurveLength, 0.0 );
    frontCurveDist = max( frontCurveDist, -vProfile.x - fEngineFrontCurveLength);
    
    
    fDist = min( fDist, frontCurveDist );
    
    fDist = max( fDist, vProfile.x - fEngineRearLength);
    
    SceneResult result = SceneResult( fDist, MAT_CAR_PAINT, vec3(vPos) );

    const float fEngineInnerCylinderRadius1 = fEngineFrontCurveRadius - 0.025;
    const float fEngineInnerCylinderRadius2 = fEngineRadius2 - 0.0;
    
    result = Scene_Union( result, SceneResult( length( vProfile - vec2(-fEngineFrontCurveLength + 0.08, fEngineFrontCurveRadius - 0.2 )) - 0.22, MAT_CHROME, vec3(0.0) ) );
    

    float fGroovePos = floor(vProfile.x) + 0.5;
    float fGrooveDist = abs( vProfile.x - fGroovePos ) - vProfile.y - 0.025 + fEngineRadiusCurr;
    result = Scene_Subtract( result, SceneResult( fGrooveDist, MAT_CAR_PAINT, vec3(vPos) ) );
    
    float fInnerCylinderDist = vProfile.y - mix( fEngineInnerCylinderRadius1, fEngineInnerCylinderRadius2, (vProfile.x - fEngineFrontCurveLength) / (fEngineFrontCurveLength + fEngineRearLength) );    
    //fInnerCylinderDist = max( fInnerCylinderDist, 1.0 - abs( vProfile.x - 5.0 ) );
    result = Scene_Subtract( result, SceneResult( fInnerCylinderDist, MAT_CHROME, vec3(0.0) ) );
	
    const float rearNozzleStart = fEngineRearLength - 1.0;
    const float rearNozzleEnd = fEngineRearLength + 0.2;
    float fRearNozzleDist = NozzleDist( vProfile - vec2(rearNozzleStart, 0.0), 0.4, 0.85, rearNozzleEnd - rearNozzleStart, 0.05 );
    result = Scene_Union( result, SceneResult( fRearNozzleDist, MAT_CHROME, vec3(0.0) ) );
    
    const float rearNozzle2Start = fEngineRearLength - 0.2;
    const float rearNozzle2End = fEngineRearLength + 0.4;
    float fRearNozzle2Dist = NozzleDist( vProfile - vec2(rearNozzle2Start, 0.0), 0.5, 0.3, rearNozzle2End - rearNozzle2Start + 0.1, 0.05 );
    result = Scene_Union( result, SceneResult( fRearNozzle2Dist, MAT_CHROME, vec3(0.0) ) );
        
    /*
    vec3 vClosest = vec3(0.0);
    vClosest.z = clamp( vPos.z, 0.0, 6.0 );

    float dist = length( vPos - vClosest ) - 1.0;
    
    SceneResult result = SceneResult( dist, MAT_CAR_PAINT, vec3(0.0) );

    float fRadialDist = length(vPos.xy);
    result = Scene_Subtract( result, SceneResult( fRadialDist - 0.6, MAT_CHROME, vec3(0.0) ) );
    
	*/
    
    if ( vPos.z < -1.3 )
    {
        result.fObjectId = MAT_CHROME;
    }
    return result;
}

SceneResult Car_GetDistance( const vec3 vPos )
{
    //SceneResult result = SceneResult( kMaxTraceDist, MAT_SKY, vec3(0.0) );
    //SceneResult result = SceneResult( length( vPos - vec3( 0, 1, 0 ) ) - 2.0, MAT_GOLD, vec3(0.0) );
    
    vec3 vMirror = vPos;
    vMirror.x = abs(vMirror.x);
    
    SceneResult result = CarEngine_GetDistance( vMirror - vec3( 1.4, 1.1, -2 ) );
    //result = Scene_Union( result, CarEngine_GetDistance( vPos - vec3( 1.5, 1, -2 ) ) );
    
    result = Scene_Union( result, CarCentre_GetDistance( vMirror - vec3( 0, .7, -4 ) ) );
    
    result.vUVW = vPos;
    
    return result;
}

SceneResult Scene_GetDistance( const vec3 vPos )
{
    SceneResult result = SceneResult( kMaxTraceDist, MAT_SKY, vec3(0.0) );

    result = Scene_Union( result, Car_GetDistance( vPos - g_sceneState.vCarPos ) );
    
    
    //result = Scene_Union( result, SceneResult( length( vPos - vec3( 0, 1, 0 ) ) - 2.0, MAT_GOLD, vec3(0.0) ) );
    //result = Scene_Subtract( result, SceneResult( length( vPos - vec3( 0, 3, 0 ) ) - 1.9, MAT_CHROME, vec3(0.0) ) );
    //result = Scene_Intersection( result, SceneResult( length( vPos - vec3( 0, 3, 0 ) ) - 1.9, MAT_CHROME, vec3(0.0) ) );
    
	float fHeight = 1.0;//1.0 - texture( iChannel1, vPos.xz * 0.1 - vec2(0, iTime) ).r;
    
    result = Scene_Union( result, SceneResult( vPos.y + fHeight * 0.5, MAT_SAND, vec3(0.0) ) );
                                                  
/*    float l = length( vPos.xz );
    result = Scene_Union( result, SceneResult( vPos.y - 2.0 + exp(-l * 0.1) * 4.0, MAT_SAND, vec3(0.0) ) );
    result = Scene_Union( result, SceneResult( vPos.y 
//                                              + sin(iTime + vPos.x * 8.0) * 0.02
//                                              + sin(iTime * 2.0 + vPos.z * 8.0) * 0.02
//                                              + sin(iTime * 3.0 + vPos.x * 10.0) * 0.01
//                                              + sin(iTime * 4.0 + vPos.z * 10.0) * 0.01
                                              , MAT_WATER, vec3(0.0) ) );*/
        
    return result;
}

// Scene Lighting

vec3 g_vSunDir = normalize(vec3(1.0, 0.4, -0.8));
vec3 g_vSunColor = vec3(1, 0.5, 0.25) * 5.0;
vec3 g_vAmbientColor = vec3(0.5, 1, 1);

SurfaceLighting Scene_GetSurfaceLighting( const in vec3 vViewDir, in SurfaceInfo surfaceInfo )
{
    SurfaceLighting surfaceLighting;
    
    surfaceLighting.vDiffuse = vec3(0.0);
    surfaceLighting.vSpecular = vec3(0.0);    
    
    Light_AddDirectional( surfaceLighting, surfaceInfo, vViewDir, g_vSunDir, g_vSunColor );
    
    vec3 vThrusterLightCol = vec3( 1.0, 0.5, 0.3 ) * 1.0 * g_sceneState.fThruster;
    Light_AddPoint( surfaceLighting, surfaceInfo, vViewDir, g_sceneState.vCarPos + vec3(1.4, 1.0, 5.8), vThrusterLightCol );
    Light_AddPoint( surfaceLighting, surfaceInfo, vViewDir, g_sceneState.vCarPos + vec3(-1.4, 1.0, 5.8), vThrusterLightCol );
    
    float fAO = 1.0;//Scene_GetAmbientOcclusion( surfaceInfo.vPos, surfaceInfo.vNormal );
    // AO
    surfaceLighting.vDiffuse += fAO * (surfaceInfo.vBumpNormal.y * 0.5 + 0.5) * g_vAmbientColor;
    
    return surfaceLighting;
}

// Environment

vec4 Env_GetSkyColor( const vec3 vViewPos, const vec3 vViewDir )
{
	vec4 vResult = vec4( 0.0, 0.0, 0.0, kFarDist );
	
    float fElevation = atan( vViewDir.y, length(vViewDir.xz) );
    float fHeading = atan( vViewDir.x, vViewDir.z );
    
    float fSkyElevationMin = -PI * 0.125;
    float fSkyElevationMax = PI * 0.5;

    float fScaledElevation = 0.5 * ((fElevation - fSkyElevationMin) / (fSkyElevationMax - fSkyElevationMin));
    if (fHeading < 0.0) fScaledElevation = 1.0 - fScaledElevation;
    vec2 vUV = vec2( fract(fHeading / PI), fScaledElevation );
    
    //vResult = textureLod( iChannel3, vUV, 0.0 );
    vResult = textureLod( iChannel3, vViewDir, 0.0 );
    
    //vResult = mix( vec3(0.02, 0.04, 0.06), vec3(0.1, 0.3, 0.8) * 3.0, vViewDir.y * 0.5 + 0.5 );
	
    // Sun
    float NdotV = dot( g_vSunDir, vViewDir );
    vResult.rgb += smoothstep( cos(radians(.7)), cos(radians(.5)), NdotV ) * g_vSunColor * 5000.0;
    
	return vResult;	
}

float Env_GetFogFactor(const in float fDist)
{
	float kFogDensity = 0.0015;
	return exp(fDist * -kFogDensity);	
}

vec3 Env_GetFogColor(const in vec3 vDir)
{
	return vec3(0.4, 0.5, 0.6) * 2.0;		
}

vec3 Env_ApplyAtmosphere( const in vec3 vColor, const in vec3 vRayOrigin,  const in vec3 vRayDir, const in float fDist)
{
	float fFogFactor = Env_GetFogFactor( fDist );
	vec3 vFogColor = Env_GetFogColor( vRayDir );
	
	Env_AddDirectionalLightFlareToFog( vFogColor, vRayDir, g_vSunDir, g_vSunColor * 3.0);
    
    vec3 vResult = mix( vFogColor, vColor, fFogFactor );

    if ( g_sceneState.fEffect == 1.0 )
    {        
        vec3 vWorldPos = vRayOrigin + vRayDir * fDist;
        if ( vWorldPos.y < 0.001 )
        {
			vResult = vec3(1.0, 1.0, 0.02) * 0.25;          
            vWorldPos.z -= iTime * 10.0;
        }
        else
        {
			vResult = vec3(0.01, 1.0, 0.02) * 20.0;
        }

        vec3 vFractPos = abs(fract(vWorldPos - 0.2) - 0.5) * 2.0;
        float f = max( max( vFractPos.x, vFractPos.y ), vFractPos.z );
        vResult *= pow( f, 20.0 );
    }

    return vResult;	    
}

// FX
float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
	
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = textureLod( iChannel1, (uv+ 0.5)/256.0, 0.0 ).yx;
	return mix( rg.x, rg.y, f.z );
}


float FX_SmokeDensity(vec3 vPos)
{
    vec2 vProfile = vec2( vPos.z, length( vPos.xy) );
    
    vec2 vClamped;
    vClamped.x = clamp( vProfile.x, 0.0, 10000.0 );
    vClamped.y = 0.0;
    
    float t = vClamped.x / 500.0;
    
    float r = (1.0 - exp2( t * -30.0 )) * 10.0;
    //float r = sqrt(t) * 10.0;
    
    
    float l = length( vProfile - vClamped ) - r;
    
    // gradual fade
    return l * exp2( t * -0.05 ) * g_sceneState.fDustTrail;
}

float FX_Noise( vec3 vPos )
{
    vec3 vNoisePos = vPos;
    return noise( vNoisePos );
}

vec4 FX_ColDensity( vec3 vPos )
{
    float density = 0.0;

 	vec3 vLocalCarPos = vPos - g_sceneState.vCarPos;
    
    vec3 vSmokePos = vec3( 0, 0.0, 10.0 );
        
    float n1 = FX_SmokeDensity( vLocalCarPos - vSmokePos );
    vec3 vOffsetPos = vLocalCarPos + g_vSunDir * 0.3;
    float n2 = FX_SmokeDensity( vOffsetPos - vSmokePos);
    
    vec3 vNoisePos = vLocalCarPos - vSmokePos;
    float fNoiseSpeed = 50.0;
    float fFreq = 3.5;
    if ( vLocalCarPos.z > 10.0 )
    {
        vNoisePos = vPos;
        fFreq = 1.5;
        fNoiseSpeed = 20.0;
        vNoisePos.y -= iTime;
    }
    else
    {
    	vNoisePos.z -= iTime * 30.0;
        
    }

    float fNoise1 = FX_Noise( vNoisePos * fFreq );
    float fNoise2 = FX_Noise( (vNoisePos + g_vSunDir * 0.3) * fFreq );
    
    n1 += fNoise1 * 3.0;
    n2 += fNoise2 * 3.0;
    
    if ( n1 < 0.0 )
        density = min( 1.0, -n1 * 0.1);
    else
    	density = -n1;
    
    float sh = clamp( (n2 - n1)* 0.5 + 0.1, 0.0, 1.0 );
    
    vec3 vCol = g_vSunColor * sh + g_vAmbientColor * 0.4;
    
    // Darken middle
    vCol *= clamp( 1.0 + n1 * 0.25, 0.0, 1.0);
    vCol *= vec3(1.0, 0.8, 0.65);

    vec3 vMirror = vLocalCarPos;
    vMirror.x = abs(vMirror.x);
    
    vec3 vFlamePos = vMirror - vec3( +1.4, 1.1, 5.2 );
    float fFlameDist = length( vFlamePos.xy ) - 0.4;
    fFlameDist = max( fFlameDist, -vFlamePos.z - 0.5 );
    float fFlameFade = clamp( (vFlamePos.z + 0.2 ) * 0.25, 0.0, 1.0 );
    fFlameDist += fFlameFade * fFlameFade;
    
    float fl = fFlameDist - fNoise1 * 0.5;
    fl += 0.7 * (1.0 - g_sceneState.fThruster);
    if ( fl < 0.0)
    {
        density = -fl * 0.5;
    	vCol = mix( vec3(0.01, 0.01, 1.) * 30.0, vec3( 1.0, 0.2, 0.05) * 30.0, pow( fFlameFade, 0.05) );
    }
    else
    {
        density = max( density, -fl );
    }
    
    //vCol *= 10.0;
    
    return vec4(vCol, density);
}

vec3 FX_Apply( in vec3 vColor, const in vec3 vRayOrigin,  const in vec3 vRayDir, const in float fDist)
{
    float t= 0.03;
    float f = 1.0;
    float st = 0.03;
    for(int iter=0; iter<64; iter++)
    {
        if( t > fDist )
        {
            break;
        }
        
        vec3 p = vRayOrigin + vRayDir * t;
        vec4 vEffect = FX_ColDensity( p );
        if ( vEffect.w >= 0.0 )
        {
        	vColor = mix(vColor, vEffect.rgb, f * vEffect.w);
        	f = f * (1.0 - vEffect.w);
        
            t += st;
			st += (0.04+st*0.012);     
        }
        else
        {
			t += -vEffect.w + 0.03;
            st = 0.03;
        }
            
    }
    
    return vColor;
}

// Camera 


CameraState GetCameraState_MouseOrbitCar()
{
    CameraState camera;

    float fAngle = (iMouse.x / iResolution.x) * 3.14 * 2.0;
    float fDist = (iMouse.y / iResolution.y) * 40.0;
    
    float fHeight = 1.0;
    
    camera.vTarget = g_sceneState.vCarPos + vec3( 0.0, 1.0, 0.5 );
    camera.vPos = camera.vTarget + vec3( sin(fAngle) * fDist, fHeight, cos(fAngle) * fDist );
    camera.fFov = 20.0;
    
    return camera;
}

struct Sequence
{
    float fDt;
    float fTime;
    float fLength;
    float fBlend;
    float fSmoothBlend;
};
    
Sequence Sequence_Init( float fTime, float fDt )
{
    Sequence seq;
    seq.fDt = fDt;
    seq.fTime = fTime + fDt;
    seq.fLength = 0.0;
    seq.fBlend = 0.0;
    seq.fSmoothBlend = 0.0;
    return seq;
}

bool Sequence_Next( inout Sequence seq, float fLength )
{
    seq.fTime -= seq.fLength;
    seq.fLength = fLength;
    seq.fBlend = seq.fTime / fLength;
    seq.fSmoothBlend = smoothstep( 0.0, 1.0, seq.fBlend );
    
    float fTestTime = seq.fTime - seq.fDt;
    return fTestTime >= 0.0 && fTestTime < fLength;
}

struct CarInt
{
    float s;
    float u;
    float a;
};
    
void CarInt_Update( inout CarInt carInt, float fTime )
{
    carInt.s += carInt.u * fTime + .5 * carInt.a * fTime * fTime;
    carInt.u += carInt.a * fTime;
}

float CarInt_GetDisplacement( CarInt carInt, float fTime )
{
    return carInt.s + carInt.u * fTime + .5 * carInt.a * fTime * fTime;    
}

float CarInt_GetVelocity( CarInt carInt, float fTime )
{
    return carInt.u + carInt.a * fTime;
}

void GetSceneState( out SceneState scene, out CameraState camera, float fTime, float fDt )
{
    scene.vCarPos = vec3(0.0);
    scene.vCarPos.y -= 0.7;
    scene.fThruster = 0.0;
    scene.fDustTrail = 0.0;
    scene.fCarVel = 0.0;
    scene.fEffect = 0.0;

    camera.vPos = vec3( 0.0, 1.0, -10.0 );
    camera.vTarget = vec3( 0.0, 0.0, 0.0 );
    camera.fFov = 15.0;
    camera.fAperture = 0.5;
    
    float fCameraShake = 0.0;

    //scene.fThruster = clamp( sin(iTime) * 0.5 + 0.5, 0.0, 1.0);
    //scene.fDustTrail = scene.fThruster;
    //    scene.vCarPos.z = -iTime * 100.0;//343.0;
        
    Sequence seq = Sequence_Init( fTime, fDt );

    CarInt carInt;
    carInt.s = 0.0;
    carInt.u = 0.0;
    carInt.a = 0.0;
    
    if ( Sequence_Next( seq, 8.0 ) )
    {
	    scene.vCarPos.y = 0.0;
    }

    // Initial Vel
    carInt.u = 100.0;    
    if ( Sequence_Next( seq, 4.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

	    camera.vTarget = vec3( 0.0, 1.0, -100.0 );
        camera.vPos = camera.vTarget + vec3( 10.0, -0.5, -5.0 );
        
        //camera.vTarget = camera.vPos + normalize(camera.vTarget - camera.vPos) * 100.0 * (1.0 - seq.fBlend * 0.9);
    	//camera.fAperture = 1.5;
    }
    
    CarInt_Update( carInt, seq.fLength );

    // vel +50 in 10 secs
    carInt.a = 100.0 / 15.0;    

    if ( Sequence_Next( seq, 5.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

	    camera.vTarget = scene.vCarPos + vec3( 0.0, 1.0, -15.0 );
        camera.vTarget.z += seq.fSmoothBlend * 20.0;
        camera.vPos = camera.vTarget + vec3( -8.0, 1.5, -3.0 );
        camera.fFov = 20.0;
    	camera.fAperture = 0.5;
        fCameraShake = 1.0;
    }
    CarInt_Update( carInt, seq.fLength );
    
    if ( Sequence_Next( seq, 5.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

	    camera.vTarget = scene.vCarPos + vec3( 0.0, 1.0, -4.5 );
        camera.vPos = camera.vTarget + mix( vec3( -4.0, 2.0, -20.0 ), vec3( -30.0, 1.0, 40.0 ) ,seq.fBlend );
        camera.vTarget.z += seq.fBlend * 10.0;
        camera.fFov = mix( 25.0, 15.0, seq.fBlend );
    	camera.fAperture = 1.5;
        fCameraShake = 1.0;
    }    
    CarInt_Update( carInt, seq.fLength );
    
    if ( Sequence_Next( seq, 5.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

	    camera.vTarget = scene.vCarPos + vec3( 0.0, 1.5, -2.5 );
        camera.vPos = camera.vTarget + mix( vec3( 10.0, 3.0, -20.0 ), vec3( -10.0, 3.0, -20.0 ) ,seq.fSmoothBlend );
        camera.fFov = 8.0;
    	camera.fAperture = 1.5;
        fCameraShake = 1.0;
    }
    
    CarInt_Update( carInt, seq.fLength );

    carInt.a = 0.0;    
    if ( Sequence_Next( seq, 3.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

	    camera.vTarget = scene.vCarPos + vec3( 1.5, 1.4, 5.5 );
        camera.vPos = camera.vTarget + vec3( 3.0, -0.5 + seq.fSmoothBlend * 2.0, 4.0+ pow( seq.fBlend, 4.0) * 16.0 );
        camera.fFov = 20.0;
    	camera.fAperture = 0.5;
        
        scene.fThruster = seq.fSmoothBlend;
        fCameraShake = 1.0;
    }

    // vel +150 in 10 secs
    carInt.a = 150.0 / 30.0;    
    if ( Sequence_Next( seq, 5.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

        // Tail fin cam
	    camera.vTarget = scene.vCarPos + vec3( 0.0, 1.8, 3.5 );
        camera.vPos = camera.vTarget + vec3( 0.0, 1.2, 4.0 );
        camera.fFov = 35.0;
    	camera.fAperture = 0.3;
        
        scene.fThruster = 1.0;
        scene.fDustTrail = seq.fBlend * 0.1;
        fCameraShake = 1.0;
    }
    
    CarInt_Update( carInt, seq.fLength );


    if ( Sequence_Next( seq, 5.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

	    camera.vTarget = scene.vCarPos + vec3( 0.0, 1.0, seq.fSmoothBlend * 10.5 );
        camera.vPos = camera.vTarget + vec3( 10.0, 2.0, -30.0 );
        camera.fFov = 15.0;
    	camera.fAperture = 1.0;

        scene.fThruster = 1.0;
        scene.fDustTrail = 0.1 + seq.fSmoothBlend * 0.9;
        fCameraShake = 1.0;
    }
    
    CarInt_Update( carInt, seq.fLength );

    if ( Sequence_Next( seq, 15.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

        camera.vTarget = scene.vCarPos + mix( vec3( 0.0, 1.0, 20.0 ), vec3( 0.0, 1.0, -15.0 ), seq.fBlend );
	    camera.vPos = camera.vTarget + vec3( -8.0, 2.0, 4.5 );
        camera.fFov = 20.0;
    	camera.fAperture = 0.4;

        scene.fThruster = 1.0;
        scene.fDustTrail = 1.0;
        fCameraShake = 1.0;
    }
    CarInt_Update( carInt, seq.fLength );
    
    if ( Sequence_Next( seq, 5.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

        // Tail fin cam
	    camera.vTarget = scene.vCarPos + vec3( 0.0, 1.8, 3.5 );
        camera.vPos = camera.vTarget + vec3( 0.0, 1.2, 4.0 );
        camera.fFov = 45.0;
    	camera.fAperture = 0.3;
        
        scene.fThruster = 1.0;
        scene.fDustTrail = 1.0;
        fCameraShake = 1.0;
    }
    CarInt_Update( carInt, seq.fLength );

    carInt.a = 0.0;    
    if ( Sequence_Next( seq, 17.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

        camera.vPos = vec3(0.0);
        camera.vPos.z = -CarInt_GetDisplacement( carInt, 0.0 );
        
        camera.vPos += vec3( 12.0, 0.5, -650.0 );
	    camera.vTarget = camera.vPos + vec3( -4.0, 0.0, 10.0 );
        
        camera.fFov = 10.0;
    	camera.fAperture = 0.5;
        
        scene.fThruster = 1.0;
        scene.fDustTrail = 1.0;
        fCameraShake = 1.0;
    }
    
    camera.vTarget.y += (noise(camera.vPos * 0.2) - 0.5) * fCameraShake / length(camera.vTarget - camera.vPos);
    
    if ( Sequence_Next( seq, 1000.0 ) )
    {
        scene.vCarPos = vec3(0.0, 0.0, 0.0);
        scene.fCarVel = 0.0;

	    camera.vTarget = scene.vCarPos + vec3( 0.0, 0.0, 2.0 );
        camera.vPos = camera.vTarget + vec3(sin(seq.fTime * 0.4) * 40.0, 20.0, cos(seq.fTime * 0.4) * 40.0 );        
        
        camera.fFov = 10.0;
    	camera.fAperture = 5.0;
        
        scene.fThruster = 0.0;
        scene.fDustTrail = 0.0;
        fCameraShake = 0.0;

        scene.fEffect = 1.0;
	}
    
    //camera = GetCameraState_MouseOrbitCar();
}

void mainImage( out vec4 vFragColor, in vec2 vFragCoord )
{
    vec2 vUV = vFragCoord.xy / iResolution.xy; 

    float fTime = iTime;
    
    // Scrubbing
    if (false)
    if (iMouse.z > 0.0 )
    {
        fTime = iMouse.x * 100.0 / iResolution.x;
    }
       

    CameraState camPrev;       
    SceneState temp;
    GetSceneState( temp, camPrev, fTime, - 1.0 / 60.0 );
    
    CameraState cam;       
    GetSceneState( g_sceneState, cam, fTime, 0.0 );
    
    vec3 vRayOrigin, vRayDir;
    Cam_GetCameraRay( vUV, cam, vRayOrigin, vRayDir );
    
    //float l = abs( vRayDir.y ) / vRayOrigin.y;
    //float fAmount = .0001 / (l + 0.02);
    //vRayDir.yz += FBM_DXY(vUV * 30.0, vec2(0.0, -iTime * 3.0), 0.5, -0.0 ).xy * fAmount;
 
    if ( iTime < 8.0 )        
    {      
        vec2 vCoord = vUV - 0.5;
        vCoord.x *= iResolution.x / iResolution.y;
        vRayOrigin = vec3( 100.0, 100.0, 100.0 );
        vRayDir = vec3(0.0, -1.0, 0.0);

        vec2 vRegion;
        
        vRegion = (vCoord + vec2(0,0.25)) * vec2(1.0, 2.0) * 0.5 + 0.5;
        if ( vRegion.x >= 0.0 && vRegion.x < 1.0 && vRegion.y >= 0.0 && vRegion.y < 1.0 )
        {
            vec2 vRangeMin = vec2( -13.0, -7.5 );
            vec2 vRangeMax = vec2( 18.0, 7.5 );
            vRayOrigin.zx = mix(vRangeMin, vRangeMax, vRegion );
            vRayOrigin.y = 20.0;
            vRayDir = vec3(0.0, -1.0, 0.0);
        }

        vRegion = (vCoord + vec2(0,-0.78)) * vec2(1.0, 2.0) * 0.5 + 0.5;
        if ( vRegion.x >= 0.0 && vRegion.x < 1.0 && vRegion.y >= 0.0 && vRegion.y < 1.0 )
        {
            vec2 vRangeMin = vec2( -13.0, 0.1 );
            vec2 vRangeMax = vec2( 18.0, 15. );
            vRayOrigin.zy = mix(vRangeMin, vRangeMax, vRegion );
            vRayOrigin.x = 20.0;
            vRayDir = vec3(-1.0, 0.0, 0.0);
        }
        
        vRegion = (vCoord + vec2(.3,-0.12)) * vec2(3.0, 6.0) * 0.5 + 0.5;
        if ( vRegion.x >= 0.1 && vRegion.x < 0.9 && vRegion.y >= 0.0 && vRegion.y < 0.85 )
        {
            vec2 vRangeMin = vec2( -3.5, 0.1 );
            vec2 vRangeMax = vec2( 3.5, 3.5 );
            vRayOrigin.xy = mix(vRangeMin, vRangeMax, vRegion );
            vRayOrigin.z = -20.0;
            vRayDir = vec3(0.0, 0.0, 1.0);
        }

        vRegion = (vCoord + vec2(-0.3,-0.12)) * vec2(3.0, 6.0) * 0.5 + 0.5;
        if ( vRegion.x >= 0.1 && vRegion.x < 0.9 && vRegion.y >= 0.0 && vRegion.y < 0.85 )
        {
            vec2 vRangeMin = vec2( -3.5, 0.1 );
            vec2 vRangeMax = vec2( 3.5, 3.5 );
            vRayOrigin.xy = mix(vRangeMin, vRangeMax, vRegion );
            vRayOrigin.z = 20.0;
            vRayDir = vec3(0.0, 0.0, -1.0);
        }
    }
    
	vec4 vColorLinAmdDepth = Scene_GetColorAndDepth( vRayOrigin, vRayDir );    
    vColorLinAmdDepth.rgb = max( vColorLinAmdDepth.rgb, vec3(0.0) );
        
    vFragColor = vColorLinAmdDepth;
    
    if ( vColorLinAmdDepth.r > 40000.0 || vColorLinAmdDepth.g > 40000.0 || vColorLinAmdDepth.b > 40000.0 )
    {
        vFragColor = vec4(0.0);
    }
    /*
    if ( vColorLinAmdDepth.r > 400.0 || vColorLinAmdDepth.g > 400.0 || vColorLinAmdDepth.b > 400.0 )
    {
        vFragColor.rgb = vec3(1.0 * (sin(iTime * 10.0) * 0.5 + 0.5), 0.0, 0.0);
    }
    else
    {
        vFragColor.rgb *= .25;
	}
	*/    
    
    Cam_StoreState( vec2(0,0), cam, vFragColor, vFragCoord );
    
    Cam_StoreState( vec2(2,0), camPrev, vFragColor, vFragCoord );
    
	StoreVec4( vec2(4,0), vec4(g_sceneState.fCarVel / 60.0), vFragColor, vFragCoord );
}

#if 1
void mainVR( out vec4 vFragColor, in vec2 vFragCoord, in vec3 fragRayOri, in vec3 fragRayDir )
{   
    
    float fTime = iTime;
    
    CameraState camPrev;       
    SceneState temp;
    GetSceneState( temp, camPrev, fTime, - 1.0 / 60.0 );
    
    CameraState cam;       
    GetSceneState( g_sceneState, cam, fTime, 0.0 );
    
    vec3 vRayOrigin, vRayDir;
    
    Cam_GetCameraRay( vec2(0.5), cam, vRayOrigin, vRayDir );
    
    vRayOrigin += fragRayOri;
    vRayDir = fragRayDir;
    
    
	vec4 vColorLinAmdDepth = Scene_GetColorAndDepth( vRayOrigin, vRayDir );    
    vColorLinAmdDepth.rgb = max( vColorLinAmdDepth.rgb, vec3(0.0) );
        
    vFragColor = vColorLinAmdDepth;
    
    if ( vColorLinAmdDepth.r > 40000.0 || vColorLinAmdDepth.g > 40000.0 || vColorLinAmdDepth.b > 40000.0 )
    {
        vFragColor = vec4(0.0);
    }
    
    
    Cam_StoreState( vec2(0,0), cam, vFragColor, vFragCoord );
    
    Cam_StoreState( vec2(2,0), camPrev, vFragColor, vFragCoord );
    
	StoreVec4( vec2(4,0), vec4(g_sceneState.fCarVel / 60.0), vFragColor, vFragCoord );    
}
#endif
