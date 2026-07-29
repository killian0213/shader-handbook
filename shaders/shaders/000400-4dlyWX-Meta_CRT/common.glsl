// Common (common) — Meta CRT by P_Malin
// https://www.shadertoy.com/view/4dlyWX

#define PI 3.141592654


///////////////////////////
// Hash Functions
///////////////////////////

// From: Hash without Sine by Dave Hoskins
// https://www.shadertoy.com/view/4djSRW

// *** Use this for integer stepped ranges, ie Value-Noise/Perlin noise functions.
//#define HASHSCALE1 .1031
//#define HASHSCALE3 vec3(.1031, .1030, .0973)
//#define HASHSCALE4 vec4(1031, .1030, .0973, .1099)

// For smaller input rangers like audio tick or 0-1 UVs use these...
#define HASHSCALE1 443.8975
#define HASHSCALE3 vec3(443.897, 441.423, 437.195)
#define HASHSCALE4 vec3(443.897, 441.423, 437.195, 444.129)


//----------------------------------------------------------------------------------------
//  1 out, 1 in...
float hash11(float p)
{
	vec3 p3  = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

//  2 out, 1 in...
vec2 hash21(float p)
{
	vec3 p3 = fract(vec3(p) * HASHSCALE3);
	p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx+p3.yz)*p3.zy);

}

///  2 out, 3 in...
vec2 hash23(vec3 p3)
{
	p3 = fract(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}

//  1 out, 3 in...
float hash13(vec3 p3)
{
	p3  = fract(p3 * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}


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

bool AtAddress( ivec2 p, ivec2 c ) { return all( equal( p, c ) ); }

void StoreVec4( in ivec2 vAddr, in vec4 vValue, inout vec4 fragColor, in ivec2 fragCoord )
{
    fragColor = AtAddress( fragCoord, vAddr ) ? vValue : fragColor;
}

void StoreVec3( in ivec2 vAddr, in vec3 vValue, inout vec4 fragColor, in ivec2 fragCoord )
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
    vec2 vJitter;
    float fPlaneInFocus;
};
    
void Cam_LoadState( out CameraState cam, sampler2D sampler, ivec2 addr )
{
    vec4 vPos = LoadVec4( sampler, addr + ivec2(0,0) );
    cam.vPos = vPos.xyz;
    vec4 targetFov = LoadVec4( sampler, addr + ivec2(1,0) );
    cam.vTarget = targetFov.xyz;
    cam.fFov = targetFov.w;
    vec4 jitterDof = LoadVec4( sampler, addr + ivec2(2,0) );
    cam.vJitter = jitterDof.xy;
    cam.fPlaneInFocus = jitterDof.z;
}

void Cam_StoreState( ivec2 addr, const in CameraState cam, inout vec4 fragColor, in ivec2 fragCoord )
{
    StoreVec4( addr + ivec2(0,0), vec4( cam.vPos, 0 ), fragColor, fragCoord );
    StoreVec4( addr + ivec2(1,0), vec4( cam.vTarget, cam.fFov ), fragColor, fragCoord );    
    StoreVec4( addr + ivec2(2,0), vec4( cam.vJitter, cam.fPlaneInFocus, 0 ), fragColor, fragCoord );    
}

mat3 Cam_GetWorldToCameraRotMatrix( const CameraState cameraState )
{
    vec3 vForward = normalize( cameraState.vTarget - cameraState.vPos );
	vec3 vRight = normalize( cross(vec3(0, 1, 0), vForward) );
	vec3 vUp = normalize( cross(vForward, vRight) );
    
    return mat3( vRight, vUp, vForward );
}

vec2 Cam_GetViewCoordFromUV( vec2 vUV, vec2 res )
{
	vec2 vWindow = vUV * 2.0 - 1.0;
	vWindow.x *= res.x / res.y;

	return vWindow;	
}

void Cam_GetCameraRay( vec2 vUV, vec2 res, CameraState cam, out vec3 vRayOrigin, out vec3 vRayDir )
{
    vec2 vView = Cam_GetViewCoordFromUV( vUV, res );
    vRayOrigin = cam.vPos;
    float fPerspDist = 1.0 / tan( radians( cam.fFov ) );
    vRayDir = normalize( Cam_GetWorldToCameraRotMatrix( cam ) * vec3( vView, fPerspDist ) );
}

vec2 Cam_GetUVFromWindowCoord( vec2 vWindow, vec2 res )
{
    vec2 vScaledWindow = vWindow;
    vScaledWindow.x *= res.y / res.x;

    return (vScaledWindow * 0.5 + 0.5);
}

vec2 Cam_WorldToWindowCoord(const in vec3 vWorldPos, const in CameraState cameraState )
{
    vec3 vOffset = vWorldPos - cameraState.vPos;
    vec3 vCameraLocal;

    vCameraLocal = vOffset * Cam_GetWorldToCameraRotMatrix( cameraState );
	
    vec2 vWindowPos = vCameraLocal.xy / (vCameraLocal.z * tan( radians( cameraState.fFov ) ));
    
    return vWindowPos;
}

float EncodeDepthAndObject( float depth, int objectId )
{
    //depth = max( 0.0, depth );
    //objectId = max( 0, objectId + 1 );
    //return exp2(-depth) + float(objectId);
    return depth;
}

float DecodeDepthAndObjectId( float value, out int objectId )
{
    objectId = 0;
    return max(0.0, value);
    //objectId = int( floor( value ) ) - 1; 
    //return abs( -log2(fract(value)) );
}

///////////////////////////////