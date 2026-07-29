// Buffer A (buffer) — [SH18] Visage by P_Malin
// https://www.shadertoy.com/view/4lcyD8

//     _____                           _____                   _             
//    / ____|                         |  __ \                 | |            
//   | (___    ___  ___  _ __    ___  | |__) | ___  _ __    __| |  ___  _ __ 
//    \___ \  / __|/ _ \| '_ \  / _ \ |  _  / / _ \| '_ \  / _` | / _ \| '__|
//    ____) || (__|  __/| | | ||  __/ | | \ \|  __/| | | || (_| ||  __/| |   
//   |_____/  \___|\___||_| |_| \___| |_|  \_\\___||_| |_| \__,_| \___||_|   
//                                                                           
//                                                                           

#define RAYMARCH_ITER 48
#define RAY_BOUNCES 2
#define SHADOW_STEPS 28

#define SCENE_SKIN 1
#define SCENE_EYES 1
#define SCENE_NOSE 1
#define SCENE_HAIR 1
#define SCENE_EARS 1
#define SCENE_MOUTH 1

#define MODEL_TOGGLES 0
// Z,X,C - toggle model parts

#define iChannelState			iChannel0
#define iChannelKeyboard 		iChannel3

//    ____                      
//   / ___|  ___ ___ _ __   ___ 
//   \___ \ / __/ _ \ '_ \ / _ \
//    ___) | (_|  __/ | | |  __/
//   |____/ \___\___|_| |_|\___|
//                              

struct SceneResult
{
	float fDist;
	int iObjectId;
    vec3 vUVW;
};
    

SceneResult Scene_GetDistance( vec3 vPos );

    
SceneResult Scene_Union( SceneResult a, SceneResult b )
{
    if ( b.fDist < a.fDist )
    {
        return b;
    }
    return a;
}

    
SceneResult Scene_Subtract( SceneResult a, SceneResult b )
{
    if ( a.fDist < -b.fDist )
    {
        b.fDist = -b.fDist;
        return b;
    }
    
    return a;
}

float smin( float a, float b, float k )
{
	float e = max(0.0, k - abs(a - b));
	return min(a, b) - e*e * 0.25 / k;
}

SceneResult Scene_SmoothSubtract( SceneResult a, SceneResult b, float k )
{    
    float fA = a.fDist;
    float fB = -b.fDist;        
    
    float fC = -smin( -fA, -fB, k );
    
    a.fDist = fC;
    b.fDist = fC;
    
    if ( fA < (fB + k) )
    {        
        return b;
    }
    
    return a;
}

SceneResult Scene_GetDistance( vec3 vPos );    

vec3 Scene_GetNormal(const in vec3 vPos)
{
    const float fDelta = 0.0001;
    vec2 e = vec2( -1, 1 );
    
    vec3 vNormal = 
        Scene_GetDistance( e.yxx * fDelta + vPos ).fDist * e.yxx + 
        Scene_GetDistance( e.xxy * fDelta + vPos ).fDist * e.xxy + 
        Scene_GetDistance( e.xyx * fDelta + vPos ).fDist * e.xyx + 
        Scene_GetDistance( e.yyy * fDelta + vPos ).fDist * e.yyy;
    
    return normalize( vNormal );
}    
    
SceneResult Scene_Trace( const in vec3 vRayOrigin, const in vec3 vRayDir, float minDist, float maxDist )
{	
    SceneResult result;
    result.fDist = 0.0;
    result.vUVW = vec3(0.0);
    result.iObjectId = -1;
    
	float t = minDist;
    
	for(int i=0; i<RAYMARCH_ITER; i++)
	{		
        float epsilon = 0.0001 * t;
		result = Scene_GetDistance( vRayOrigin + vRayDir * t );
        if ( abs(result.fDist) < epsilon )
		{
			break;
		}
                        
        if ( t > maxDist )
        {
            result.iObjectId = -1;
	        t = maxDist;
            break;
        }       
        
        if ( result.fDist > 1.0 )
        {
            result.iObjectId = -1;            
        }    
        
        t += result.fDist; 
	}
    
    result.fDist = max( t, minDist );


    return result;
}    

float Scene_TraceShadow( const in vec3 vRayOrigin, const in vec3 vRayDir, const in float fMinDist, const in float fLightDist )
{
    // Soft Shadow Variation
    // https://www.shadertoy.com/view/lsKcDD    
    // based on Sebastian Aaltonen's soft shadow improvement
    
	float res = 1.0;
    float t = fMinDist;
    float ph = 1e10; // big, such that y = 0 on the first iteration
    
    for( int i=0; i<SHADOW_STEPS; i++ )
    {
		float h = Scene_GetDistance( vRayOrigin + vRayDir*t ).fDist;

        // use this if you are getting artifact on the first iteration, or unroll the
        // first iteration out of the loop
        //float y = (i==0) ? 0.0 : h*h/(2.0*ph); 

        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, 10.0*d/max(0.0,t-y) );
        ph = h;
        
        t += h;
        
        if( res<0.0001 || t>fLightDist ) break;
        
    }
    return clamp( res, 0.0, 1.0 );    
}

float Scene_GetAmbientOcclusion( const in vec3 vPos, const in vec3 vDir )
{
    float fOcclusion = 0.0;
    float fScale = 1.0;
    for( int i=0; i<5; i++ )
    {
        float fOffsetDist = 0.001 + 0.1*float(i)/4.0;
        vec3 vAOPos = vDir * fOffsetDist + vPos;
        float fDist = Scene_GetDistance( vAOPos ).fDist;
        fOcclusion += (fOffsetDist - fDist) * fScale;
        fScale *= 0.46;
    }
    
    return clamp( 1.0 - 30.0*fOcclusion, 0.0, 1.0 );
}


//    _     _       _     _   _             
//   | |   (_) __ _| |__ | |_(_)_ __   __ _ 
//   | |   | |/ _` | '_ \| __| | '_ \ / _` |
//   | |___| | (_| | | | | |_| | | | | (_| |
//   |_____|_|\__, |_| |_|\__|_|_| |_|\__, |
//            |___/                   |___/ 
//                                          

#define ENABLE_EMISSIVE 0

struct SurfaceInfo
{
    vec3 vPos;
    vec3 vNormal;
    vec3 vDiffNormal;    
    vec3 vSpecNormal;    
    vec3 vAlbedo;
    vec3 vR0;
    float fGloss;
    float fSkin;
#if ENABLE_EMISSIVE    
    vec3 vEmissive;
#endif    
};
    
SurfaceInfo Scene_GetSurfaceInfo( vec3 vRayOrigin, vec3 vRayDir, SceneResult traceResult );

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

float AlphaSqrFromGloss( const in float gloss )
{
	float MAX_SPEC = 10.0;
	return 2.0f  / ( 2.0f + exp2( gloss * MAX_SPEC) );
}

void Light_Add(inout SurfaceLighting lighting, SurfaceInfo surface, vec3 vViewDir, vec3 vLightDir, vec3 vLightColour, float fShadow)
{
	float fDiffNDotL = clamp(dot(vLightDir, surface.vDiffNormal), 0.0, 1.0);
	float fSpecNDotL = clamp(dot(vLightDir, surface.vSpecNormal), 0.0, 1.0);
	
    if ( surface.fSkin > 0.0 )
    {    
        float fSSFactor = fDiffNDotL * fShadow;
        fSSFactor = pow ( fSSFactor, 0.3 );
    	vLightColour *= mix( vec3(1,0,0), vec3(1.0), fSSFactor );
    }
        
	lighting.vDiffuse += vLightColour * fDiffNDotL * fShadow;
    
	vec3 vH = normalize( -vViewDir + vLightDir );
	float fNdotV = clamp(dot(-vViewDir, surface.vSpecNormal), 0.0, 1.0);
	float fNdotH = clamp(dot(surface.vSpecNormal, vH), 0.0, 1.0);
    
	// D

	float alphaSqr = AlphaSqrFromGloss( surface.fGloss );
    float alpha = sqrt( alphaSqr );
	float denom = fNdotH * fNdotH * (alphaSqr - 1.0) + 1.0;
	float d = alphaSqr / (PI * denom * denom);

	float k = alpha / 2.0;
	float vis = Light_GIV(fSpecNDotL, k) * Light_GIV(fNdotV, k);

	float fSpecularIntensity = d * vis * fSpecNDotL;    
	lighting.vSpecular += vLightColour * fSpecularIntensity * fShadow;    
}

void Light_AddPoint(inout SurfaceLighting lighting, SurfaceInfo surface, const in vec3 vViewDir, const in vec3 vLightPos, const vec3 vLightColour)
{    
    vec3 vPos = surface.vPos;
	vec3 vToLight = vLightPos - vPos;	
    
	vec3 vLightDir = normalize(vToLight);
	float fDistance2 = dot(vToLight, vToLight);
	float fAttenuation = 100.0 / (fDistance2);
	
	float fShadowFactor = Scene_TraceShadow( surface.vPos, vLightDir, 0.001, length(vToLight) );
	
	Light_Add( lighting, surface, vViewDir, vLightDir, vLightColour * fAttenuation, fShadowFactor);
}

float Light_SpotFactor( vec3 vLightDir, vec3 vSpotDir, float fSpotInnerAngle, float fSpotOuterAngle )   
{
    float fSpotDot = dot( vLightDir, -vSpotDir );
    
    float fTheta = acos(fSpotDot);

    float fAngularAttenuation = clamp( (fTheta - fSpotOuterAngle) / (fSpotInnerAngle - fSpotOuterAngle), 0.0, 1.0 );
    
    float fShapeT = fTheta / fSpotOuterAngle;
    fShapeT = fShapeT * fShapeT * fShapeT;
    float fShape = (sin( (1.0 - fShapeT) * 10.0));
    fShape = fShape * fShape * (fShapeT) + (1.0 - fShapeT);
    
    //return fShape;
    return fAngularAttenuation * fShape;
}
    

void Light_AddSpot( inout SurfaceLighting lighting, SurfaceInfo surface, const in vec3 vViewDir, const vec3 vLightPos, const vec3 vSpotDir, float fSpotInnerAngle, float fSpotOuterAngle, vec3 vLightColour )
{
    vec3 vPos = surface.vPos;
	vec3 vToLight = vLightPos - vPos;	
    
	vec3 vLightDir = normalize(vToLight);
	float fDistance2 = dot(vToLight, vToLight);
	float fAttenuation = 100.0 / (fDistance2);
	
	float fShadowFactor = Scene_TraceShadow( surface.vPos, vLightDir, 0.1, length(vToLight) );
    
    fShadowFactor *= Light_SpotFactor( vLightDir, vSpotDir, fSpotInnerAngle, fSpotOuterAngle );
	
	Light_Add( lighting, surface, vViewDir, vLightDir, vLightColour * fAttenuation, fShadowFactor);    
}

void Light_AddDirectional(inout SurfaceLighting lighting, SurfaceInfo surface, const in vec3 vViewDir, const in vec3 vLightDir, const in vec3 vLightColour)
{	
	float fAttenuation = 1.0;
	float fShadowFactor = Scene_TraceShadow( surface.vPos, vLightDir, 0.005, 10.0 );
	
	Light_Add( lighting, surface, vViewDir, vLightDir, vLightColour * fAttenuation, fShadowFactor);
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

//    ____                _           _             
//   |  _ \ ___ _ __   __| | ___ _ __(_)_ __   __ _ 
//   | |_) / _ \ '_ \ / _` |/ _ \ '__| | '_ \ / _` |
//   |  _ <  __/ | | | (_| |  __/ |  | | | | | (_| |
//   |_| \_\___|_| |_|\__,_|\___|_|  |_|_| |_|\__, |
//                                            |___/ 
//                                                  

vec3 Env_GetSkyColor( vec3 vViewPos, vec3 vViewDir, float fRaySpread );
vec3 Env_ApplyAtmosphere( const in vec3 vColor, const in vec3 vRayOrigin,  const in vec3 vRayDir, const in float fDist );
vec3 FX_Apply( in vec3 vColor, const in vec3 vRayOrigin,  const in vec3 vRayDir, const in float fDist);


vec4 Render_GetColorAndDepth( vec3 vRayOrigin, vec3 vRayDir )
{
    float fRaySpread = 1.0;
    
	vec3 vResultColor = vec3(0,0,0);
    float fResultDepth = 0.0;
    
    
	SceneResult firstTraceResult;
    
    float fStartDist = 0.0f;
    float fMaxDist = 10.0f;
    
    vec3 vRemaining = vec3(1.0);
    
	for( int iPassIndex=0; iPassIndex < RAY_BOUNCES; iPassIndex++ )
    {
    	SceneResult traceResult = Scene_Trace( vRayOrigin, vRayDir, fStartDist, fMaxDist );

        if ( iPassIndex == 0 )
        {
            firstTraceResult = traceResult;
        }
        
        vec3 vColor = vec3(0);
        vec3 vReflectAmount = vec3(0);
        
		if( traceResult.iObjectId < 0 )
		{
            vColor = Env_GetSkyColor( vRayOrigin, vRayDir, fRaySpread * traceResult.fDist );
			vColor = Env_ApplyAtmosphere( vColor, vRayOrigin, vRayDir, traceResult.fDist );
        }
        else
        {
            
            SurfaceInfo surfaceInfo = Scene_GetSurfaceInfo( vRayOrigin, vRayDir, traceResult );
            SurfaceLighting surfaceLighting = Scene_GetSurfaceLighting( vRayDir, surfaceInfo );
                
            // calculate reflectance (Fresnel)
			vReflectAmount = Light_GetFresnel( -vRayDir, surfaceInfo.vSpecNormal, surfaceInfo.vR0, surfaceInfo.fGloss );

            vec3 vTransmitted = surfaceInfo.vAlbedo * surfaceLighting.vDiffuse;
#if ENABLE_EMISSIVE            
			vTransmitted += surfaceInfo.vEmissive;
#endif    
			vColor = vTransmitted * (vec3(1.0) - vReflectAmount); 
            fRaySpread *= surfaceInfo.fGloss;
            
            vec3 vReflectRayOrigin = surfaceInfo.vPos;
            vec3 vReflectRayDir = normalize( reflect( vRayDir, surfaceInfo.vSpecNormal ) );
            fStartDist = 0.001 / max(0.0000001,abs(dot( vReflectRayDir, surfaceInfo.vNormal ))); 

            vColor += surfaceLighting.vSpecular * vReflectAmount;            

			vColor = Env_ApplyAtmosphere( vColor, vRayOrigin, vRayDir, traceResult.fDist );
			vColor = FX_Apply( vColor, vRayOrigin, vRayDir, traceResult.fDist );
            
            vRayOrigin = vReflectRayOrigin;
            vRayDir = vReflectRayDir;
        }
        
        vResultColor += vColor * vRemaining;
        vRemaining *= vReflectAmount;        
    }

    {
        vec3 vColor = Env_GetSkyColor( vRayOrigin, vRayDir, fRaySpread );
        vColor = Env_ApplyAtmosphere( vColor, vRayOrigin, vRayDir, 1000.0 );
        vResultColor += vColor * vRemaining;
    }
    
    return vec4( vResultColor, EncodeDepthAndObject( firstTraceResult.fDist, firstTraceResult.iObjectId ) );
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////

//    ____                        ____                      _       _   _             
//   / ___|  ___ ___ _ __   ___  |  _ \  ___  ___  ___ _ __(_)_ __ | |_(_) ___  _ __  
//   \___ \ / __/ _ \ '_ \ / _ \ | | | |/ _ \/ __|/ __| '__| | '_ \| __| |/ _ \| '_ \ 
//    ___) | (_|  __/ | | |  __/ | |_| |  __/\__ \ (__| |  | | |_) | |_| | (_) | | | |
//   |____/ \___\___|_| |_|\___| |____/ \___||___/\___|_|  |_| .__/ \__|_|\___/|_| |_|
//                                                           |_|                      
//

// Materials

const int 
    MAT_DEFAULT = 0,
	MAT_CHROME = 1,
    MAT_EYEBALL_L = 2,
    MAT_EYEBALL_R = 3,
    MAT_SKIN = 4,
    MAT_HAIR = 5;


struct SceneState
{
    mat3 mHeadRot;
    vec3 vNeckOffset;
    
    vec3 lEyePos;
    vec3 lEyeDir;
    
    vec3 rEyePos;
    vec3 rEyeDir;
};

SceneState g_sceneState;

vec3 InvTransformHeadPos( vec3 vPos )
{
    return  g_sceneState.mHeadRot * (vPos + g_sceneState.vNeckOffset) - g_sceneState.vNeckOffset;
}

vec3 InvTransformHeadDir( vec3 vPos )
{
    return g_sceneState.mHeadRot * vPos;
}

vec3 TransformHeadPos( vec3 vPos )
{
    return (vPos + g_sceneState.vNeckOffset) * g_sceneState.mHeadRot - g_sceneState.vNeckOffset;
}


void ClampEyeDir( inout vec3 vDir, float fSide )
{
    vDir.z = max( 0.01, vDir.z );
    vDir /= vDir.z;
    
    vDir.x = clamp( vDir.x * fSide, -0.4, 0.6) * fSide;
    vDir.y = clamp( vDir.y, -0.3, 0.3);
    
    vDir = normalize( vDir );
}

void InitSceneState( AnimState animState, vec3 vCamPos )
{   
    vec3 vEyeTarget = animState.vEyeTarget;
    
    g_sceneState.mHeadRot = MatFromAngles( animState.vHeadAngles );    
    
    g_sceneState.vNeckOffset = vec3( 0.0, 1.0, 1.2 );
    
    float ipd = 0.3f;
    g_sceneState.lEyePos = TransformHeadPos( vec3( ipd, 0.0f, 0.0f ) );
    g_sceneState.rEyePos = TransformHeadPos( vec3( -ipd, 0.0f, 0.0f ) );
    
    g_sceneState.lEyeDir = vEyeTarget - g_sceneState.lEyePos;
    g_sceneState.rEyeDir = vEyeTarget - g_sceneState.rEyePos;
    
    ClampEyeDir( g_sceneState.lEyeDir, 1.0 );
    ClampEyeDir( g_sceneState.rEyeDir, -1.0 );
}

// https://iquilezles.org/articles/distfunctions   
float sdTorus( vec3 p, vec2 t )
{
    return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}

float sdCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
	vec3 pa = p-a, ba = b-a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h ) - r;
}

float sdEllipsoid( in vec3 p, in vec3 r) {
    return (length(p/r ) - 1.) * min(min(r.x,r.y),r.z);
}


    
const float fEyeRadius = 0.25f * 0.5f;
const float fCorneaShift = 0.4 * fEyeRadius;
const float fCorneaSphereRadius = 0.66 * fEyeRadius;

float SdEllipsoid( vec3 p, vec3 r )
{
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}


SceneResult Scene_GetDistance( vec3 vPos )
{
    SceneResult result;
    
    result.fDist = 1000.0;
    result.vUVW = vPos;
    result.iObjectId = MAT_DEFAULT;
    
    vec3 vHeadDomain = vPos;
    
    //vHeadDomain *= headRot;        
    
#if SCENE_EYES
    SceneResult resultEye;
    
    vec3 vEyePos;
    vec3 vEyeDir;
    
    vec3 vEyeMid = (g_sceneState.lEyePos + g_sceneState.rEyePos) * 0.5;
    vec3 vEyeOffset = vEyeMid - vPos;
    vec3 vEyeDiff = g_sceneState.lEyePos - g_sceneState.rEyePos;
    
    float fEyeDir = 1.0;
    
    if( dot( vEyeDiff, vEyeOffset) < 0.0 )
    {
        vEyePos = g_sceneState.lEyePos;
        vEyeDir = g_sceneState.lEyeDir;
	    resultEye.iObjectId = MAT_EYEBALL_L;
        fEyeDir = 1.0;
    }
	else
    {
        vEyePos = g_sceneState.rEyePos;
        vEyeDir = g_sceneState.rEyeDir;        
	    resultEye.iObjectId = MAT_EYEBALL_R;
        fEyeDir = -1.0;
    }
    
    float fEyeCullDist = length( vPos - vEyePos ) - 0.23;
    
    bool testEyes = ( fEyeCullDist < 0.0 );        
    
    vec3 vEyeDomain;
    float fEyeDist;
    
    if ( testEyes )
    {
	    vEyeDomain = InvTransformHeadDir( vPos - vEyePos );
    
        float d1 = length( vEyeDomain ) - fEyeRadius;
        float d2 = length( vEyeDomain - vEyeDir * fCorneaShift ) - fCorneaSphereRadius;

         fEyeDist = smin( d1, d2, 0.003);

        resultEye.fDist = fEyeDist;
        resultEye.vUVW = vEyeDomain;

#if MODEL_TOGGLES    
        if( !Key_IsToggled( iChannelKeyboard, KEY_X ) )
#endif            
        {
            result = Scene_Union(result, resultEye);
        }
    }
#endif    
    
#if SCENE_SKIN    
    
    SceneResult resultSkin;
    
    vec3 vFaceDomainPos = InvTransformHeadPos( vHeadDomain );

    
#if 1
    //float fSmile = sin( iTime ) * 0.5 + 0.5;
    float fSmile = 1.0;
    
    float fSmileRad = 0.26;
    float fSmileSide = 1.0;
    vec3 vSmileDomain = vFaceDomainPos;
    if ( vSmileDomain.x < 0.0 )
    {
        vSmileDomain.x = -vSmileDomain.x;
        fSmileSide = -1.0;
    }
    float fSmileDist = (fSmileRad - length( vSmileDomain - vec3(0.25, -0.48, 0.1) ));

    {
        SceneResult resultTemp;
        resultTemp.fDist = -fSmileDist;
        resultTemp.iObjectId = MAT_DEFAULT;
        resultTemp.vUVW = vPos;
        //result = Scene_Union(result, resultTemp);  
    }     
    
    vec3 vSmileDir = vec3( fSmileSide * -1.0, -0.6, 0.3 );
    
    fSmileDist = max( 0.0, fSmileDist / fSmileRad );
    vFaceDomainPos += fSmileDist * fSmileDist * 0.1 * fSmile * vSmileDir;
#endif     
          
    
    vec3 vFaceDomain = vFaceDomainPos;
    vFaceDomain.x = abs( vFaceDomain.x );
    vHeadDomain.x = abs( vHeadDomain.x );
    
    float fForeheadDist = SdEllipsoid( vFaceDomain - vec3(0.0, 0.24, -0.56 ) * 1.2, vec3(0.6f, 0.75f, 0.75f) * 1.2 );
    float fBrowDist = SdEllipsoid( vFaceDomain - vec3(0.3, 0.0, -0.2 ) * 1.2, vec3( 0.2f, 0.4f, 0.3f) * 1.2 );
    float fSkullBackDist = SdEllipsoid( vFaceDomain - vec3(0.0, 0.25, -0.75 ) * 1.2, vec3(0.65f, 0.75f, 0.8f) * 1.2 );
    float fSkullBaseDist = SdEllipsoid( vFaceDomain - vec3(0.02, -0.2, -0.9 ) * 1.2, vec3(0.425f, 0.8f, 0.5f) * 1.2 );
    float fMouthExtrudeDist = SdEllipsoid( vFaceDomain - vec3(0.0, -0.475, -0.1 ) * 1.2, vec3(0.2f, 0.2f, 0.3f) * 1.2 );
    
    float fFaceDist = SdEllipsoid( vFaceDomain - vec3(0.0, -0.3, -0.4 ) * 1.2, vec3(0.46f, 0.6f, 0.6f) * 1.2 );
    float fCheekDist = SdEllipsoid( vFaceDomain - vec3(0.25, -0.2, -0.2 ) * 1.2, vec3( 0.2f, 0.4f, 0.3f) * 1.2 );
    float fChinDist = SdEllipsoid( vFaceDomain - vec3(0.0, -0.65, -0.1 ) * 1.2, vec3(0.28f, 0.25f, 0.25f) * 1.2 );

    float fNeckDist = SdEllipsoid( vHeadDomain - vec3(0.0, -1.3, -0.95 ) * 1.2, vec3(0.4f, 0.7f, 0.4f) * 1.2 );
    float fNeckDist2 = SdEllipsoid( vHeadDomain - vec3(0.0, -0.85, -0.725 ) * 1.2, vec3(0.325f, 0.5f, 0.33f) * 1.2 );

    float fShoulderDist = SdEllipsoid( vHeadDomain - vec3(0.25, -1.45, -1.0 ) * 1.2, vec3(0.7f, 0.25f, 0.45f) * 1.2 );
    
    fNeckDist = smin( fNeckDist, fNeckDist2, 0.1 ); 

	fFaceDist = smin( fFaceDist, fChinDist, 0.1 ); 
	fFaceDist = smin( fFaceDist, fCheekDist, 0.1 ); 
    fFaceDist = smin( fFaceDist, fMouthExtrudeDist, 0.1 ); 
	    
    fForeheadDist = smin( fForeheadDist, fBrowDist, 0.1 ); 

    float fSkullDist = smin( fSkullBackDist, fSkullBaseDist, 0.1 ); 
    fSkullDist = smin( fSkullDist, fForeheadDist, 0.1 ); 
    
    float fHeadDist = smin( fFaceDist, fSkullDist, 0.1 );
    

    fHeadDist = smin( fHeadDist, fNeckDist, 0.1 );

	fHeadDist = smin( fHeadDist, fShoulderDist, 0.1 );
 
    
    float fSkinDist = fHeadDist;
    
    float ws = sin( fMouthExtrudeDist * 15.0) * 0.5 + 0.5;
    fSkinDist += ws * ws * 0.01 / (1.0 + fMouthExtrudeDist * 8.0);
    

#if MODEL_TOGGLES    
    if( Key_IsToggled( iChannelKeyboard, KEY_Z ) )
    {
        fSkinDist = 1000.0;
    }    
#endif        
    
    float fEyeRecessDist = SdEllipsoid( vFaceDomain - vec3(0.5, -0.075, 0.43 ), vec3(0.5, 0.25, 0.35) );    
    float fEyeRecessDist2 = SdEllipsoid( vFaceDomain - vec3(0.4, -0.1, 0.12 ), vec3(0.2, 0.1, 0.05) );    
    fEyeRecessDist = smin( fEyeRecessDist, fEyeRecessDist2, 0.08 );    
	fSkinDist = -smin( -fSkinDist, fEyeRecessDist, 0.08 );    

    resultSkin.vUVW.z = 0.0f;      
    
#if SCENE_NOSE    
#if MODEL_TOGGLES    
    if( !Key_IsToggled( iChannelKeyboard, KEY_C ) )
#endif        
    {    
        float fNoseDist = SdEllipsoid( vFaceDomain - vec3(0.0, -0.25, 0.15 ) * 1.2, vec3(0.06, 0.15, 0.1) * 1.2 );
        float fNoseBridgeDist = SdEllipsoid( vFaceDomain - vec3(0.0, -0.15, 0.05 ) * 1.2, vec3(0.06, 0.18, 0.1) * 1.2 );
        float fNoseTipDist = SdEllipsoid( vFaceDomain - vec3(0.0, -0.3, 0.25 ) * 1.2, vec3(0.05, 0.05, 0.06) * 1.2 );
        float fNoseBulgeDist = SdEllipsoid( vFaceDomain - vec3(0.06, -0.31, 0.225 ) * 1.2, vec3(0.04, 0.04, 0.05) * 1.2 );
        float fNostrilDist = SdEllipsoid( vFaceDomain - vec3(0.04, -0.35, 0.26 ) * 1.2, vec3(0.02, 0.03, 0.015) * 1.2 );
        fNoseDist = smin( fNoseDist, fNoseBridgeDist, 0.1);
        fNoseDist = smin( fNoseDist, fNoseTipDist, 0.1);
        fNoseDist = smin( fNoseDist, fNoseBulgeDist, 0.03);
        fNoseDist = -smin( -fNoseDist, fNostrilDist, 0.015);

        fSkinDist = smin( fSkinDist, fNoseDist, 0.05);
    }
#endif    
         
    vec3 vMouthDomain = vFaceDomain - vec3(0, -0.6, 0);    
    float fFreq = 1.0 + abs(vMouthDomain.y) * 13.0;
    float px = clamp( vFaceDomain.x * 6.0 * fFreq, 0.0, 1.0 );
    px = pow( px, 0.8);
    float pd = (-cos(px * PI * 2.0 ) * 0.5 + 0.5);
    float fPhiltrumDist = ( pd * pd) * 0.005;
        
    fPhiltrumDist *= smoothstep( 0.2, 0.0f, abs( vMouthDomain.y ) );
        
    
#if SCENE_MOUTH
    float fMouthCullDist = length( vMouthDomain - vec3(0,0,-0.1) ) - 0.38;
    {
        SceneResult resultTemp;
        resultTemp.fDist = fMouthCullDist;
        resultTemp.iObjectId = MAT_DEFAULT;
        resultTemp.vUVW = vPos;
        //result = Scene_Union(result, resultTemp);  
    }    
    
    if ( fMouthCullDist < 0.0 )    
    {
        float fMouthWidth = 0.2;

        float fMouthSX = vMouthDomain.x / fMouthWidth;
        //float fMouthX = fMouthSX * 0.5 + 0.5;

        float fMouthTop = 0.0f;
        float fMouthBot = 0.0f;
        float fLipWidthTop = 0.05;
        float fLipWidthBot = 0.04;

        float fMouthEdgeDist = abs(vMouthDomain.x) - fMouthWidth;
        
        float fCornerFade = smoothstep(1.0, 0.2, abs(fMouthSX) );
        fLipWidthTop *= fCornerFade;
        fLipWidthBot *= fCornerFade;
        

        float fMouthDistTop = (vMouthDomain.y - fMouthTop);
        float fMouthDistBot = -(vMouthDomain.y - fMouthBot);

        float fMouthDist = 0.0;
        float fLipWidth = 0.0;
        
        if ( fMouthDistTop > fMouthDistBot )
        {
            fMouthDist = fMouthDistTop;
            fLipWidth = fLipWidthTop;
        }
        else
        {
            fMouthDist = fMouthDistBot;
            fLipWidth = fLipWidthBot;
            fPhiltrumDist *= 0.3;
        }
        
        if ( fLipWidthTop > 0.0 )
        fSkinDist = -smin( -fSkinDist, fMouthDist, fLipWidth );
        
        float fMouthT = max( fMouthDistTop / fLipWidthTop, fMouthDistBot / fLipWidthBot ) - 0.3;
        fPhiltrumDist *= smoothstep( 0.2, 0.9, fMouthT );
        
        fMouthT = clamp( fMouthT, 0.0, 1.0 );
        
        fMouthT = 1.0 - fMouthT * fMouthT;
        resultSkin.vUVW.z = fMouthT;
    }
	
    fSkinDist -= fPhiltrumDist;
#endif    



    resultSkin.vUVW.xy = vFaceDomainPos.xy;

    
#if SCENE_EARS
    vec3 vEarDomain = vFaceDomain;
    vEarDomain -= vec3( 0.62, -0.15, -0.7 );

    float fEarCullDist = length( vEarDomain - vec3(0,0,-0.1) ) - 0.4;
    {
        SceneResult resultTemp;
        resultTemp.fDist = fEarCullDist;
        resultTemp.iObjectId = MAT_DEFAULT;
        resultTemp.vUVW = vPos;
        //result = Scene_Union(result, resultTemp);  
    }
    
    if ( fEarCullDist < 0.0 )
    {   
        vEarDomain.z *= 1.5; // z scale
        vEarDomain.x += vEarDomain.z*.45; // slope / stick out back
        vEarDomain.z += smoothstep(-.2, 0., vEarDomain.y)*.1; // ear shape
        vEarDomain.x += smoothstep(-.1, .4, vEarDomain.y) * -0.2; // stick out top
        float fLobe = smoothstep(-.05, -.4, vEarDomain.y);
        vEarDomain.x += fLobe * -0.04; // stick out lobe
        vEarDomain.y += fLobe * 0.03; // pull down lobe
        vEarDomain.z *= 1.0 + fLobe * 0.2;
        float ear = sdCylinder(vEarDomain.yxz+vec3(0,.05,0), vec2(.2, .05));

        vec2 vSwirlDomain = vEarDomain.zy - vec2( 0.04, -0.05 );

        float sl = length( vSwirlDomain );
        float sa = atan( vSwirlDomain.x, vSwirlDomain.y );
        float sf = sin( sl * 30.0 );
        ear -= sf * sf * 0.01;

        ear = smin(ear, sdTorus(vEarDomain.yxz, vec2(.2, .03)), .005);

        ear = min(ear, length(vEarDomain-vec3(0.0,-0.05,.1)) - 0.05 ); // bump

        resultSkin.vUVW.z = max( resultSkin.vUVW.z, (0.6 - 0.2 * sf) / (1.0 +  ear * 30.0) );
        
        fSkinDist = smin(fSkinDist, ear * 0.85, .03);

        fSkinDist = -smin(-fSkinDist, length(vEarDomain - vec3(-0.03, -0.05, 0.05)) - 0.01, .06); // hole

    }    
#endif

    
#if SCENE_EYES    
    float fEyeX, fEyeLidSubtractTop, fEyeLidSubtractBot;
    if ( testEyes )
    {
        float fEyelidThickness = 0.0;// 0.0125f;

        float fEyelidDist = fEyeDist - fEyelidThickness;

        fEyeX = ( fEyeDir * -vEyeDomain.x / fEyeRadius) * 0.5 + 0.5; 

        float fEyelidShape = sin( fEyeX * PI ) * 0.5 + 0.5;
        float fTopMag = clamp( vEyeDir.y + 0.25, 0.1, 0.45 );
        float fTopAng = -fEyelidShape * fTopMag;

        float fBotMag = clamp( -vEyeDir.y + 0.25, 0.1, 0.4 );
        float fBotAng = fEyelidShape * fEyelidShape * fBotMag;

        float fBlink = clamp( 1.0 - mod( iTime, 5.0 ) * 10.0, 0.0, 1.0 );
        
        //fBlink = sin( iTime * 2.0 ) * 0.5 + 0.5;
        
        fBotAng = fBotAng * (1.0 - fBlink * 0.5); // bottom closes slightly
        fTopAng = mix( fTopAng, fBotAng, fBlink ); // Top blends to meet bottom

        float es = sin( -0.05 * fEyeDir );
        float ec = cos( -0.05 * fEyeDir );

        vec3 vEyeLidDirTop = normalize( vec3(es, cos(fTopAng), ec * sin(fTopAng)) );
        fEyeLidSubtractTop = dot( vEyeLidDirTop, (vEyeDomain) );

        float fEyelashCurlDist = clamp(fEyelidDist - 0.02, 0.0, 0.03);
        fEyeLidSubtractTop -= fEyelashCurlDist * fEyelashCurlDist * 20.0 * (1.0 - fEyeX); // eyelash curl

        vec3 vEyeLidDirBot = normalize( vec3(es, cos(fBotAng), ec * sin(fBotAng)) );
        fEyeLidSubtractBot = -dot( vEyeLidDirBot, (vEyeDomain) );

        float fEyeLidSubtract = -smin( -fEyeLidSubtractBot, -fEyeLidSubtractTop, 0.02 );

        // Set eyelid inner color
        float fEyeLidBlend =-fEyelidDist - fEyeLidSubtract;
        fEyeLidBlend += 0.005;
        if ( fEyeLidBlend > 0.0f )
        {
            fEyeLidBlend *= 150.0;

            resultSkin.vUVW.z = max( resultSkin.vUVW.z, clamp( fEyeLidBlend, 0.0f, 1.0f ) );
        }

        //fEyeLidSubtract += -fEyeDist * fEyeDist * 0.1;

    #if 1
        float bmb = fBotMag * (1.0 - fBlink);
        float wdb = fEyeLidSubtractBot / (1.0 - bmb * 0.5);
        float wsb = sin( wdb * wdb * 1000.0 );
        fEyelidDist -= wsb * wsb * 0.005 * clamp(fEyeLidSubtractBot * 10.0, 0.0, 0.1) * (bmb * 0.8 + 0.2);

        float bmt = fTopMag * (1.0 - fBlink);
        float wdt = fEyeLidSubtractTop / (1.0 - bmt * 1.5);
        float wst = sin( 2.0 + wdt * wdt * 1000.0 );
        fEyelidDist -= wst * wst * 0.02 * clamp( fEyeLidSubtractTop * 20.0, 0.0, 0.1) * (bmt * 0.8 + 0.2);

    #endif    

        fEyelidDist = -smin( -fEyelidDist, fEyeLidSubtract, 0.005 );

        fSkinDist = smin( fSkinDist, fEyelidDist , 0.02 );        
        //fSkinDist = min( fSkinDist, fEyelidDist );        
    }
#endif    
  
    
        
    float fBlush = clamp( 1.0 - fCheekDist * 10.0, 0.0, 1.0 );
    resultSkin.vUVW.z = max( resultSkin.vUVW.z, 0.3 * fBlush );
    
#endif    

    
#if SCENE_HAIR    
    SceneResult resultHair;
	    
    float fHairDistA = SdEllipsoid( vFaceDomain - vec3(0.0, 0.53, -0.68 ) * 1.2, vec3(0.65f, 0.52f, 0.8f) * 1.2 );
    float fHairDistB = SdEllipsoid( vFaceDomain - vec3(0.1, 0.2, -0.75 ) * 1.2, vec3(0.63f, 0.5f, 0.7f) * 1.2 );
    float fHairDistC = SdEllipsoid( vFaceDomain - vec3(0.1, -0.15, -0.73 ) * 1.2, vec3(0.435f, 0.5f, 0.8f) * 1.2 );
    float fHairDistD = SdEllipsoid( vFaceDomain - vec3(0.52, -0.0, -0.47 ) * 1.2, vec3(0.1f, 0.23f, 0.13f) );
    
    float fHairDist = fHairDistA;
	fHairDist = smin( fHairDist, fHairDistB, 0.2 );
    fHairDist = smin( fHairDist, fHairDistC, 0.2 );

    if ( fHairDist > -0.1 )
    {
	    fHairDist = min( fHairDist, length( vFaceDomain - vec3(0.0, 0.3, -1.9 ) ) - 0.4 );
        float fHairSub = SdEllipsoid( vFaceDomain - vec3(0.1, -0.2, -0.62 ) * 1.2, vec3(1.1f, 0.45f, 0.33f) );

        fHairSub = min( fHairSub, length( vFaceDomain - vec3(0,-0.2,0.5) ) - 0.5 );
        fHairSub = min( fHairSub, length( vFaceDomain - vec3(0.4,0.4,0.1) ) - 0.2 );

        fHairDist = -smin( -fHairDist, fHairSub, 0.1 );
    }
    
    float fBlush2 = clamp( (0.1 - fHairDist) * 5.0, 0.0, 1.0 );
    resultSkin.vUVW.z = max( resultSkin.vUVW.z, fBlush2 * 0.3 );
    
    
	resultHair.iObjectId = MAT_HAIR;
    resultHair.vUVW = vPos;
    
    if ( fHairDist < 0.05 )
    {
        vec3 vHairOrigin = vFaceDomain;
        vHairOrigin.y += 0.1;
        vHairOrigin.y += vHairOrigin.z * 0.25;
        
        float hb = atan( vHairOrigin.z, vHairOrigin.y );
        float ha = atan( vHairOrigin.x, vHairOrigin.y );
        
        if ( (fHairDistD - 0.05) < fHairDist )
        {
            float b = -0.2 - vFaceDomain.y;
            hb = vFaceDomain.y * 0.5;
            ha = vFaceDomain.z + b * b * 2.0;
        }
            
	    fHairDist = smin( fHairDist, fHairDistD, 0.1 );
            
        
	    fHairDist += textureLod( iChannel2, vec2( ha * 2.5, hb * 0.001 ), 0.0 ).r * 0.06;
        
        resultHair.vUVW.x = ha;        
        resultHair.vUVW.y = hb;
    }
    resultHair.fDist = fHairDist;
    

    result = Scene_Union(result, resultHair);
#endif    
    
#if (SCENE_EYES && SCENE_SKIN)
    if ( testEyes )
    {    
        float fTopEyelashOffset = -0.005;
        float fBotEyelashOffset = -0.01;

        float fTopEyelashThickness = 0.001;
        float fTopEyelashLength = 0.04 * (1.0 - abs( fEyeX - 0.3 ) );

        float fBotEyelashThickness = 0.001;
        float fBotEyelashLength = 0.005;

        float fTopEyelashDist = fEyeLidSubtractTop;
        fTopEyelashDist = abs( fTopEyelashDist + fTopEyelashOffset) - fTopEyelashThickness;
        fTopEyelashDist = max( fTopEyelashDist, fEyeDist - fTopEyelashLength );


        float fBotEyelashDist = fEyeLidSubtractBot;
        fBotEyelashDist = abs( fBotEyelashDist + fBotEyelashOffset) - fBotEyelashThickness;
        fBotEyelashDist = max( fBotEyelashDist, fEyeDist - fBotEyelashLength );

        float fEyelashDist = min( fTopEyelashDist, fBotEyelashDist );        

        //float f2 = sin( vPos.x * 1000.0 + sin( vPos.x * 123.0) );
        //float f2 = 
        //fEyelashDist += (f2 * 0.5 + 0.5) * 0.01;
        //if ( textureLod( iChannel2, vec2(vPos.x * 5.0, 0.5), 0.0 ).r > 0.5 )
        {
            vec2 vLashPos = vPos.xz - vEyePos.xz;
            vLashPos.y += 0.01;

            float ang = vLashPos.x / vLashPos.y;

            if ( fEyelashDist < 0.01 )
            {
                fEyelashDist += textureLod( iChannel2, vec2(ang, 0.5), 0.0 ).r * 0.002;
            }
        }


        fSkinDist = smin( fSkinDist, fEyelashDist + 0.001, 0.005 );

        SceneResult resultLash;
        resultLash.fDist = fEyelashDist;
        resultLash.iObjectId = MAT_HAIR;
        resultLash.vUVW = vEyeDomain;
        result = Scene_Union(result, resultLash);
    }
#endif    
 
    //result.fDist = mix( result.fDist, length(vPos) - 0.5, sin(iTime) * 0.5 + 0.5);
    
    //result.iObjectId = MAT_CHROME;
    //result.iObjectId = MAT_DEFAULT;
    
    //result.fDist *= 0.9;

    /*
    SceneResult resultSphere;
    resultSphere.fDist = SdEllipsoid( vPos + g_sceneState.vNeckOffset, vec3(1.02, 0.03, 0.015) * 1.2 );
    //length( vPos - vec3(-1.0, 0.0, 1.0) ) - 0.25;
    resultSphere.iObjectId = MAT_CHROME;
    resultSphere.vUVW = vPos;
	result = Scene_Union(result, resultSphere);
    */
                
    resultSkin.fDist = fSkinDist;
	resultSkin.iObjectId = MAT_SKIN;
    result = Scene_Union(result, resultSkin);    
    
    
    /*SceneResult resultTeeth;
    vec3 vToothDomain = vFaceDomain - vec3(0, -0.6, -0.03);
    resultTeeth.fDist = length( vToothDomain ) - 0.25;
    resultTeeth.fDist = -min( -resultTeeth.fDist, abs(vToothDomain.y) - 0.05 );
    resultTeeth.iObjectId = MAT_DEFAULT;
    resultTeeth.vUVW = vFaceDomain;
    result = Scene_Union(result, resultTeeth);    */
    
    
    /*if ( fEyeLidBlend < 0.0f && fEyeLidBlend > -0.005f )
    {
		resultSkin.iObjectId = MAT_HAIR;
    } */
	
    //result.iObjectId = MAT_CHROME;
        
    
    return result;
}

SurfaceInfo Scene_GetSurfaceInfo( vec3 vRayOrigin, vec3 vRayDir, SceneResult traceResult )
{
    SurfaceInfo surfaceInfo;
    
    surfaceInfo.vPos = vRayOrigin + vRayDir * (traceResult.fDist);
    
    surfaceInfo.vNormal = Scene_GetNormal( surfaceInfo.vPos ); 
    surfaceInfo.vDiffNormal = surfaceInfo.vNormal;
    surfaceInfo.vSpecNormal = surfaceInfo.vNormal;
    surfaceInfo.vAlbedo = vec3(1.0);
    surfaceInfo.vR0 = vec3( 0.02 );
    surfaceInfo.fGloss = 1.0;
#if ENABLE_EMISSIVE            
    surfaceInfo.vEmissive = vec3( 0.0 );
#endif    
    surfaceInfo.fSkin = 0.0f;
    
    switch ( traceResult.iObjectId )
    {
    //case MAT_CHROME:
        //surfaceInfo.vR0 = vec3(1.0);
		//break;
        
    case MAT_SKIN:
        float z = clamp( abs(traceResult.vUVW.z), 0.0, 1.0 );
        // Skin tone to red
        surfaceInfo.vAlbedo = mix( vec3(0.76f, 0.58f, 0.50f), vec3(0.76f, 0.46f,0.45f) * 0.75, z );
        surfaceInfo.vAlbedo = surfaceInfo.vAlbedo * surfaceInfo.vAlbedo;
        // Red areas more smooth
        surfaceInfo.fGloss = 0.4 + sqrt( z ) * 0.2;
        
        surfaceInfo.fSkin = 1.0f;
        surfaceInfo.vR0 = vec3( 0.015f );
        
        // add low frequency noise to red - gives the impression of blue structures under skin
        vec4 vLowNoiseSample = textureLod( iChannel2, traceResult.vUVW.xy * 0.05, 0.0);
        float blueness = vLowNoiseSample.r;
        surfaceInfo.vAlbedo.r += blueness * 0.1;
                
        // noise pattern
        vec4 vNoiseSample = textureLod( iChannel2, traceResult.vUVW.xy * 1.0, 0.0);
        float t = vNoiseSample.x;
        float skinNoise =  t * t * 0.15 * ( 1.0 - z * 0.9);
        surfaceInfo.vAlbedo *= 1.0 - skinNoise;
        
        vec4 vHighNoiseSample = textureLod( iChannel2, traceResult.vUVW.xy * 8.0, 0.0);
    
        
        
        // freckles
        float t2 = vNoiseSample.y * vNoiseSample.y;
        t2 = max (0.0, 1.0 - t2 * 50.0 );
        //t2 = t2 * t2;
        //t2 = max(0.0, (t2 - 0.75) / (1.0 - 0.75));
        t2 *= ( 1.0 - z * 0.9) * 0.25;
        surfaceInfo.vAlbedo = mix( surfaceInfo.vAlbedo, vec3(0.1, 0.02, 0.0), t2 );

        
        //surfaceInfo.vAlbedo *= 0.3; // skin tone
        
        // Eyebrows
        if ( traceResult.vUVW.y > 0.09 && traceResult.vUVW.y < 0.22 && abs(traceResult.vUVW.x) > 0.1 )
        {
            float fEyebrowDist = 100.0;
            vec2 vEyebrowPos = vec2(0.0, 0.06);
            vec2 vEyebrowDomain = traceResult.vUVW.xy;
            vEyebrowDomain.x = abs( vEyebrowDomain.x );
            vEyebrowDomain -= vEyebrowPos;
                    
            float fEyebrowBottom = vEyebrowDomain.y - sin( vEyebrowDomain.x * 6.2 - 0.5 ) * 0.1 * 1.2;
            float fEyebrowTop = vEyebrowDomain.y - sin( vEyebrowDomain.x * 7.0 - 0.5 ) * 0.1 - 0.03;
            
            float fEyebrowShape = min( fEyebrowBottom, -fEyebrowTop );

            fEyebrowShape = smin( fEyebrowShape, vEyebrowDomain.x - 0.15, 0.05 );
            fEyebrowShape = smin( fEyebrowShape, 0.48 - vEyebrowDomain.x - vEyebrowDomain.y * 0.25, 0.02 );

            fEyebrowDist = -fEyebrowShape;    
            
            
            float fBlendBase = clamp( 1.0 - fEyebrowDist * 50.0, 0.0, 1.0 );
            
            float fTexture = textureLod( iChannel2, vec2( fEyebrowBottom * 2.5 + vEyebrowDomain.x * -0.4, vEyebrowDomain.x * 0.225 ), 0.0 ).r;
            float fBlend = max( 0.0, fBlendBase - fTexture * 0.5 );
            surfaceInfo.fSkin *= 1.0 - fBlend;

            fBlend *= 0.8;
            
            surfaceInfo.vAlbedo = mix ( surfaceInfo.vAlbedo, vec3(0), fBlend );
        }
	
        // hacky skin bump map (applied to specular normal only)
        surfaceInfo.fGloss *= surfaceInfo.fSkin;
        surfaceInfo.vSpecNormal += ((vHighNoiseSample.xyz * 1.5 + vNoiseSample.yzw * 0.5) - 1.0) * 0.3 * surfaceInfo.fSkin;

        break;        
        
    case MAT_EYEBALL_L:
    case MAT_EYEBALL_R:
        {
            vec3 vEyeDir;
            vec3 vEyePos;
            if ( traceResult.iObjectId == MAT_EYEBALL_L )
            {
                vEyePos = g_sceneState.lEyePos;
                vEyeDir = g_sceneState.lEyeDir;
            }
            else
            {
                vEyePos = g_sceneState.rEyePos;
                vEyeDir = g_sceneState.rEyeDir;
            }
            
            vec3 vSide = normalize( cross( vec3(0,1,0), vEyeDir ) );
            vec3 vUp = normalize( cross( vEyeDir, vSide ) );
            
            vec3 vEyeOffset = surfaceInfo.vPos - vEyePos;

            vec2 vUV;
            vUV.x = dot( vEyeOffset, vSide );
            vUV.y = dot( vEyeOffset, vUp );

            
            const float fCorneaStartZ = 0.84f * fEyeRadius;
            const float fIrisSize = 0.48f * fEyeRadius;
            //const float fPupilFraction = 0.4f;
            float fPupilFraction = 0.4f + sin(iTime * 0.4) * 0.1f;                

            float zOffset = dot(vEyeOffset, vEyeDir);
            
            float thickness = zOffset - fCorneaStartZ;
            if ( thickness > 0.0f )
            {
                float refractiveIndex = 1.0 / 1.3f;
                vec3 vRefracted = refract(vRayDir, surfaceInfo.vSpecNormal, refractiveIndex);

                float refractedZ = dot( vRefracted, vEyeDir );
                
                float opticalDepth = thickness / refractedZ;

                vec3 vUVOffset = vec3(vRefracted * opticalDepth);
                vUV.x -= dot( vUVOffset, vSide );
                vUV.y -= dot( vUVOffset, vUp );
            }

            vec2 vIrisUV = vUV / fIrisSize;

            float irisR = length( vIrisUV );
            float irisT = atan( vUV.x, vUV.y ) / TAU;

            float R = irisR * fIrisSize;

            float fBloodShot = textureLod( iChannel2, vec2( irisR, irisT ) * vec2(0.02, 0.4) + 0.3, 0.0).r;

            float fBloodShotFade = 1.0 - dot( vEyeDir, surfaceInfo.vNormal);
            fBloodShot *= fBloodShotFade + 0.4;

            fBloodShot = fBloodShot * fBloodShot * fBloodShot;
                        
            surfaceInfo.vAlbedo = mix( vec3(1.0, 0.8, 0.8), vec3(0.5f, 0.2f, 0.2f), fBloodShot );                

            if ( zOffset > 0.0 )
            {
                // Darken around iris
                float fIrisOuterBlend = clamp( -(irisR - 1.15) * 5.0, 0.0, 1.0f );                                                           
                surfaceInfo.vAlbedo *= mix( 1.0, 0.2, fIrisOuterBlend);


                float fIrisBlend = clamp( -(irisR - 1.0) * 10.0, 0.0, 1.0f );

                if ( fIrisBlend > 0.0 )
                {
                    float fMiscNoise = textureLod( iChannel2, vUV * 0.25 + 0.1, 0.0).r;

                    vec3 vIrisColor =  mix( vec3(0.2, .3, 0.8) * 0.3, vec3(0.8, 0.5, 0.2) * 0.2, fMiscNoise );

                    float scaledIrisR = irisR - fPupilFraction;
                    
                    float fIrisNoise = textureLod( iChannel2, vec2( scaledIrisR, irisT ) * vec2(0.03, 0.8), 0.0).r;

                    fIrisNoise = pow( fIrisNoise, 1.5);


                    vec3 vIrisAlbedo = vIrisColor * (fIrisNoise + 0.8);
                    vIrisAlbedo = min( vIrisAlbedo, vec3(1.0) );

                    surfaceInfo.vAlbedo = mix( surfaceInfo.vAlbedo, vIrisAlbedo, fIrisBlend );


                    vec3 vNormal2 = vEyeDir;
                    vNormal2 -= vSide * vIrisUV.x * 0.75;
                    vNormal2 -= vUp * vIrisUV.y * 0.75;
                    surfaceInfo.vDiffNormal = mix( surfaceInfo.vDiffNormal, vNormal2, fIrisBlend );


                    //surfaceInfo.vAlbedo = vec3(1);
                    float fIrisBump = textureLod( iChannel2, vec2( scaledIrisR, irisT - 0.001 ) * vec2(0.03, 0.8), 0.0).r;                   
                    fIrisBump = fIrisNoise - fIrisBump;
                    surfaceInfo.vDiffNormal.x += cos( irisT * TAU ) * fIrisBump;
                    surfaceInfo.vDiffNormal.y += sin( irisT * TAU ) * fIrisBump;

                }

                //surfaceInfo.vSpecNormal += (textureLod( iChannel2, vec2( irisR, irisT ) * vec2(0.1,1), 0.0).xyz * 2.0 - 1.0) * 0.01 * (1.0f - fIrisBlend);



                float fPupilBlend = clamp( -(irisR-fPupilFraction) * 10.0, 0.0, 1.0f );
                {
                    surfaceInfo.vAlbedo = mix( surfaceInfo.vAlbedo, vec3(0, 0, 0), fPupilBlend);

                    vec3 vPerpDir = -normalize( vec3( vIrisUV, 0.0 ) );
                    surfaceInfo.vDiffNormal = mix( surfaceInfo.vDiffNormal, vPerpDir, fPupilBlend );
                }
            }
        }
        break;

	case MAT_HAIR:
        surfaceInfo.fGloss = 0.6f;
        
        vec4 vHairSample = textureLod( iChannel2, vec2(traceResult.vUVW.xy) * vec2(10.0, 0.1), 0.0);
        surfaceInfo.vAlbedo = vHairSample.rrr;
        
        vec3 vHairCol = vec3(1.0, 0.4, 0.1) * 0.4;
        //surfaceInfo.vAlbedo = vec3(0.5);
        surfaceInfo.vAlbedo *= vHairCol;
        surfaceInfo.vR0 = vHairCol * vHairSample.g * 0.1 + 0.005;
        //surfaceInfo.vSpecNormal = normalize( cross( surfaceInfo.vSpecNormal, vec3(0,1,0) ) );
        
		break;
    }
    
	surfaceInfo.vDiffNormal = normalize( surfaceInfo.vDiffNormal );
    surfaceInfo.vSpecNormal = normalize( surfaceInfo.vSpecNormal );
    
    
    return surfaceInfo;
}

// Scene Lighting

vec3 g_vSunDir = normalize(vec3(0.3, 0.4, 0.5));
vec3 g_vSunColor = vec3(1, 0.95, 0.8) * 5.0;
vec3 g_vAmbientColor = vec3(1.0, 1.2, 1.5)* 1.0 * vec3(0.5, 1.0, 0.5);

SurfaceLighting Scene_GetSurfaceLighting( const in vec3 vViewDir, in SurfaceInfo surfaceInfo )
{
    SurfaceLighting surfaceLighting;
    
    surfaceLighting.vDiffuse = vec3(0.0);
    surfaceLighting.vSpecular = vec3(0.0);    
    
    Light_AddDirectional( surfaceLighting, surfaceInfo, vViewDir, g_vSunDir, g_vSunColor );
    
    vec3 vLightPos = vec3(-2.0, 0.4, 2.0);
    vec3 vLightCol = vec3(0.1);
    
    //Light_AddSpot( surfaceLighting, surfaceInfo, vViewDir, vSpotPos, vSpotDir, radians(10.0), radians(60.0), vLightCol * 0.02 );
    Light_AddPoint( surfaceLighting, surfaceInfo, vViewDir, vLightPos, vLightCol );
    
    float fAO = Scene_GetAmbientOcclusion( surfaceInfo.vPos, surfaceInfo.vDiffNormal );
    // AO
    surfaceLighting.vDiffuse += fAO * (surfaceInfo.vDiffNormal.y * 0.5 + 0.5) * g_vAmbientColor;
    
    return surfaceLighting;
}

// Environment

vec3 Env_GetSkyColor( vec3 vViewPos, vec3 vViewDir, float fRaySpread )
{
	vec3 vResult = vec3( 0.0, 0.0, 0.0 );
   
#if 1
    float fFactor = 1.0f - fRaySpread * fRaySpread;
    vec3 vEnvMap = textureLod( iChannel1, vViewDir.zyx, 8.0 * fFactor ).rgb;
    //vEnvMap = vEnvMap * vEnvMap;
    //float kEnvmapExposure = 0.999;
    //vResult.rgb = -log2(1.0 - vEnvMap * kEnvmapExposure);
    vResult.rgb = vEnvMap;
#endif
    
    // Sun
    //float NdotV = dot( g_vSunDir, vViewDir );
    //vResult.rgb += smoothstep( cos(radians(.7)), cos(radians(.5)), NdotV ) * g_vSunColor * 5000.0;

    return vResult * 3.5;
}

float Env_GetFogFactor(const in vec3 vRayOrigin,  const in vec3 vRayDir, const in float fDist )
{    
	float kFogDensity = 0.1;
	return exp(fDist * -kFogDensity);	
}

vec3 Env_GetFogColor(const in vec3 vDir)
{    
	return vec3(0.5, 0.45, 0.4) * 2.0;		
}

vec3 Env_ApplyAtmosphere( const in vec3 vColor, const in vec3 vRayOrigin,  const in vec3 vRayDir, const in float fDist )
{
    return vColor;
    
    //vec3 vResult = vColor;        
	//float fFogFactor = Env_GetFogFactor( vRayOrigin, vRayDir, fDist );
	//vec3 vFogColor = Env_GetFogColor( vRayDir );	
    //vResult = mix( vFogColor, vResult, fFogFactor );
    //return vResult;	    
}


vec3 FX_Apply( in vec3 vColor, const in vec3 vRayOrigin,  const in vec3 vRayDir, const in float fDist)
{    
    return vColor;
}


void mainImage( out vec4 vFragColor, in vec2 vFragCoord )
{
    if ( iFrame == 0 )
    {
        vFragColor = vec4(0);
        return;
    }
    
    vec2 vReducedResolution = texelFetch( iChannelState, ADDR_RESOLUTION, 0).xy;
    vec2 vUV = vFragCoord.xy / vReducedResolution.xy;
        
    CameraState cam;
	Cam_LoadState( cam, iChannelState, ivec2(0,0) );
    

    AnimState animState;
    AnimState_LoadState( animState, iChannelState, ADDR_ANIMSTATE );    
    
    // Trace Scene
    float fAspectRatio = iResolution.x / iResolution.y;            
    
    vec3 vRayOrigin, vRayDir;
    vec2 vJitterUV = vUV + cam.vJitter / vReducedResolution.xy;
    Cam_GetCameraRay( vJitterUV, fAspectRatio, cam, vRayOrigin, vRayDir );
 
    InitSceneState( animState, cam.vPos );
    
    if ( cam.fPlaneInFocus < 0.0 )
    {
        vec3 vForwards = normalize(cam.vTarget - cam.vPos);
        SceneResult focusTrace = Scene_Trace( cam.vPos, vForwards, 0.0, 100.0 );
        cam.fPlaneInFocus = focusTrace.fDist;     
    }
    
    float fHitDist = 0.0f;
    vFragColor = Render_GetColorAndDepth( vRayOrigin, vRayDir );    
    
	Cam_StoreState( ivec2(0), cam, vFragColor, ivec2(vFragCoord.xy) );        
}
