// Buffer A (buffer) — [SH16B] Mach 1 by P_Malin
// https://www.shadertoy.com/view/MttGz4


// Scene Render

// This buffer was used like an environment map before shadertoy added cubemap support
#if 0

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
};
    
void Cam_LoadState( out CameraState cam, sampler2D sampler, ivec2 addr )
{
    cam.vPos = LoadVec3( sampler, addr + ivec2(0,0) );
    vec4 targetFov = LoadVec4( sampler, addr + ivec2(1,0) );
    cam.vTarget = targetFov.xyz;
    cam.fFov = targetFov.w;
}

void Cam_StoreState( vec2 addr, const in CameraState cam, inout vec4 fragColor, in vec2 fragCoord )
{
    StoreVec3( addr + vec2(0,0), cam.vPos, fragColor, fragCoord );
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
    //return ( Scene_Trace( vRayOrigin, vRayDir, fLightDist ).fDist < fLightDist ? 0.0 : 1.0;
    
    float mint = 0.02, tmax = 2.5;
	float res = 1.0;
    float t = mint;
    for( int i=0; i<16; i++ )
    {
		float h = Scene_GetDistance( vRayOrigin + vRayDir * t ).fDist;
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );    
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
            
            // Reflect Ray
            vRayOrigin = surfaceInfo.vPos;
            vRayDir = normalize( reflect( vRayDir, surfaceInfo.vBumpNormal ) );
        }
                
		vResultColor += vPassColor * vPassContribution;
		vPassContribution *= vReflectance;			        
    }
    
    vec4 vFinalSkyColor = Env_GetSkyColor( vRayOrigin, vRayDir );
    vFinalSkyColor.rgb = Env_ApplyAtmosphere( vFinalSkyColor.rgb, vRayOrigin, vRayDir, vFinalSkyColor.a );		
	vResultColor += vFinalSkyColor.rgb * vPassContribution;
    
    vResultColor = FX_Apply( vResultColor, vInRayOrigin, vInRayDir, firstTraceResult.fDist );
    
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

// Materials

#define MAT_SKY 		-1.0
#define MAT_MOUNTAIN 	0.0
#define MAT_SAND 		2.0

SurfaceInfo Scene_GetSurfaceInfo( const in vec3 vRayOrigin,  const in vec3 vRayDir, SceneResult traceResult )
{
    SurfaceInfo surfaceInfo;
    
    surfaceInfo.vPos = vRayOrigin + vRayDir * (traceResult.fDist);
    surfaceInfo.vNormal = Scene_GetNormal( surfaceInfo.vPos ); 
    surfaceInfo.vBumpNormal = surfaceInfo.vNormal;
    surfaceInfo.vAlbedo = vec3(1.0); //fract( surfaceInfo.vPos + 0.1 );
    surfaceInfo.vR0 = vec3( 0.01 );
    surfaceInfo.fSmoothness = 0.0;
    surfaceInfo.vEmissive = vec3( 0.0 );
    
    surfaceInfo.vR0 = vec3( 0.01 );
    vec3 vSand = texture( iChannel2, surfaceInfo.vPos.xz * 0.01).rgb;
    vSand = vSand * vSand;
    vec3 vMountain = texture( iChannel1, surfaceInfo.vPos.xz * 0.01).rgb;
    vMountain = vMountain * vMountain;
    
    surfaceInfo.vAlbedo = mix(vSand, vMountain, clamp( surfaceInfo.vPos.y * 0.2, 0.0, 1.0) ); 
    
    //surfaceInfo.vAlbedo = mix(surfaceInfo.vAlbedo, vec3(1,1,1), clamp( (surfaceInfo.vPos.y - 55.0) * 0.2, 0.0, 1.0) ); 
            
    
    return surfaceInfo;
}

// Scene Description


SceneResult Scene_GetDistance( const vec3 vPos )
{
    SceneResult result = SceneResult( kMaxTraceDist, MAT_SKY, vec3(0.0) );
    

    float fMountainDist = 50.0 - length(vPos.xz);
    float fAngle = atan( vPos.x, vPos.z );
    fMountainDist = max( fMountainDist, vPos.y - 10.0 + sin( fAngle * 50.0 ) * 5.0);
    
//    result = Scene_Union( result, SceneResult( fMountainDist, MAT_MOUNTAIN, vec3(0.0) ) );
    //result = Scene_Subtract( result, SceneResult( length( vPos - vec3( 0, 3, 0 ) ) - 1.9, MAT_CHROME, vec3(0.0) ) );
    //result = Scene_Intersection( result, SceneResult( length( vPos - vec3( 0, 3, 0 ) ) - 1.9, MAT_CHROME, vec3(0.0) ) );
    
	//float fHeight = 0.0;//1.0 - texture( iChannel1, vPos.xz * 0.1 - vec2(0, iTime) ).r;
    
    float fHeight = FBM_DXY( vPos.xz * 0.005, vec2(0.0), 0.8, -0.1).z;
    fHeight = fHeight* fHeight * fHeight * fHeight;
    fHeight = fHeight * 200.0;
    fHeight = fHeight * (1.0 - exp2( length( vPos.xz ) * -0.003 ) );
    
    result = Scene_Union( result, SceneResult( vPos.y - fHeight, MAT_SAND, vec3(0.0) ) );
                                              
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

SurfaceLighting Scene_GetSurfaceLighting( const in vec3 vViewDir, in SurfaceInfo surfaceInfo )
{
    SurfaceLighting surfaceLighting;
    
    surfaceLighting.vDiffuse = vec3(0.0);
    surfaceLighting.vSpecular = vec3(0.0);    
    
    Light_AddDirectional( surfaceLighting, surfaceInfo, vViewDir, g_vSunDir, g_vSunColor );
    //Light_AddPoint( surfaceLighting, surfaceInfo, vViewDir, vec3(-2.0, 5.0, 0.0), vec3( 0.5, 1, 0.5 ) );
    
    float fAO = 1.0;//Scene_GetAmbientOcclusion( surfaceInfo.vPos, surfaceInfo.vNormal );
    // AO
    surfaceLighting.vDiffuse += fAO * (surfaceInfo.vBumpNormal.y * 0.5 + 0.5) * vec3(0.5, 1, 1);
    
    return surfaceLighting;
}

// Environment

vec4 Env_GetSkyColor( const vec3 vViewPos, const vec3 vViewDir )
{
	vec4 vResult = vec4(0.0);
	
    vResult.rgb = mix( vec3(0.02, 0.04, 0.06), vec3(0.1, 0.3, 0.8) * 3.0, vViewDir.y * 0.5 + 0.5 );
	


    // Cloud
    float fCloud = texture( iChannel3, vViewDir.xz * 0.01 / vViewDir.y ).r;
    fCloud = clamp( fCloud * fCloud * 3.0 - 1.0, 0.0, 1.0);
    vResult.rgb = mix( vResult.rgb, vec3(8.0), fCloud );
    
    
    // Sun
    //float NdotV = dot( g_vSunDir, vViewDir );
    //vResult += smoothstep( cos(radians(.7)), cos(radians(.5)), NdotV ) * g_vSunColor * 2000.0;
    
    vResult.w = kFarDist;
    
	return vResult;	
}

vec3 Env_ApplyAtmosphere( const in vec3 vColor, const in vec3 vRayOrigin,  const in vec3 vRayDir, const in float fDist)
{
    return vColor;
    /*
	float fFogFactor = Env_GetFogFactor( fDist );
	vec3 vFogColor = Env_GetFogColor( vRayDir );
	
	Env_AddDirectionalLightFlareToFog( vFogColor, vRayDir, g_vSunDir, g_vSunColor);
    
    return mix( vFogColor, vColor, fFogFactor );	    
	*/
}

// FX

vec4 FX_ColDensity( vec3 vPos )
{
    float density = 0.0;
    if (length( vPos ) < 5.0 )
        density = 0.02;
    return vec4(10,10,10, density);
}

vec3 FX_Apply( in vec3 vColor, const in vec3 vRayOrigin,  const in vec3 vRayDir, const in float fDist)
{
/*    float t= 0.03;
    float f = 1.0;
    for(int iter=0; iter<64; iter++)
    {
        if( t > fDist )
        {
            break;
        }
        
        vec3 p = vRayOrigin + vRayDir * t;
        vec4 vEffect = FX_ColDensity( p );
        vec4 vEffect2 = FX_ColDensity( p + g_vSunDir * 0.1 ) ;
        
        vEffect.xyz *= clamp( (vEffect.w - vEffect2.w) / 0.1, 0.0, 1.0 );
        
        vColor = mix(vColor, vEffect.rgb, f * vEffect.w);
        f = f * (1.0 - vEffect.w);
        
		t += (0.04+t*0.012);        
    }    */
    
    return vColor;
}

// Camera 

CameraState GetCameraState()
{
    CameraState camera;
    
    float fAngle = (iMouse.x / iResolution.x) * 3.14 * 2.0;
    float fDist = 15.0;
    
    float fHeight = (iMouse.y / iResolution.y) * 15.0;
    
    camera.vPos = vec3( sin(fAngle) * fDist, fHeight, cos(fAngle) * fDist );
    camera.vTarget = vec3( 0.0, 2.0, 0.5 );
    camera.fFov = 25.0;
    
    return camera;
}

void mainImage( out vec4 vFragColor, in vec2 vFragCoord )
{
    vec2 vUV = vFragCoord.xy / iResolution.xy; 
    vec4 vOldData = LoadVec4( iChannel0, ivec2(0,0) );
 
    
    vec3 vRayOrigin, vRayDir;

// Environment map render
#if 1
    // Passthrough shader if previous value was valid
	if ( iFrame > 0 && vOldData.x == iResolution.x && vOldData.y == iResolution.y )
    {
        vFragColor = texture( iChannel0, vUV );
        return;
    }
    
    vRayOrigin = vec3(0.0, 1.0, 0.0);
    
    float fSkyElevationMin = -PI * 0.125;
    float fSkyElevationMax = PI * 0.5;
    
    float fHeading = vUV.x * PI;
    if ( vUV.y > 0.5 )
    {
	    vUV.y = 1.0 - vUV.y;
        fHeading += PI;
    }
    float fElevation = mix( fSkyElevationMin, fSkyElevationMax, vUV.y * 2.0 );
    
    vRayDir.x = sin( fHeading ) * cos( fElevation );
    vRayDir.y = sin( fElevation );
    vRayDir.z = cos( fHeading ) * cos( fElevation );
#else    
    CameraState cam = GetCameraState();
    Cam_GetCameraRay( vUV, cam, vRayOrigin, vRayDir );
#endif
    
	vec4 vColorLinAmdDepth = Scene_GetColorAndDepth( vRayOrigin, vRayDir );    

    vColorLinAmdDepth.rgb = max( vColorLinAmdDepth.rgb, vec3(0.0) );
        
    vFragColor = vColorLinAmdDepth;
    
    //vFragColor.r = fract( atan(vRayDir.x, vRayDir.z) / (PI * 2.0) );
    
    // Debug update frequency
    //vFragColor.r = fract( iTime * 10.0 );
    
    if ( vColorLinAmdDepth.r > 40000.0 || vColorLinAmdDepth.g > 40000.0 || vColorLinAmdDepth.b > 40000.0 )
    {
        vFragColor = vec4(0.0);
    }

    vec4 textureA = texture( iChannel1, vec2(0,0) );
    vec4 textureB = texture( iChannel2, vec2(0,0) );
    vec4 textureC = texture( iChannel3, vec2(0,0) );

    vec4 vFrameData = vec4( 0 );
    // Don't stamp output as valud until input textures have loaded
    if ( length(textureA.rgb) > 0.01 && length(textureB.rgb) > 0.01 && length(textureC.rgb) > 0.01 )
    {  
        vFrameData =  vec4( floor(iResolution.x), floor(iResolution.y), 0, 0 );
    }
    
    StoreVec4( vec2(0,0), vFrameData, vFragColor, vFragCoord );
}


#endif

void mainImage( out vec4 vFragColor, in vec2 vFragCoord )
{
    discard;
}