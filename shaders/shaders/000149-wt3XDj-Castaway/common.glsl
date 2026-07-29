// Common (common) — Castaway by P_Malin
// https://www.shadertoy.com/view/wt3XDj

//     _____                                           
//    / ____|                                          
//   | |      ___   _ __ ___   _ __ ___    ___   _ __  
//   | |     / _ \ | '_ ` _ \ | '_ ` _ \  / _ \ | '_ \ 
//   | |____| (_) || | | | | || | | | | || (_) || | | |
//    \_____|\___/ |_| |_| |_||_| |_| |_| \___/ |_| |_|
//                                                     
//                                                     

#define PI	3.141592654
#define TAU 6.283185308

#define ZERO (min(0,iFrame))


#define IOR_AIR 	1.0f
#define IOR_WATER 	1.33f

#define EQUIRECTANGULAR_PROJECTION 0

float RadianceChange( float IA, float IB )
{
    float x = IB / IA;
    return x * x;
}


//  ____        _          ____  _                             
// |  _ \  __ _| |_ __ _  / ___|| |_ ___  _ __ __ _  __ _  ___ 
// | | | |/ _` | __/ _` | \___ \| __/ _ \| '__/ _` |/ _` |/ _ \
// | |_| | (_| | || (_| |  ___) | || (_) | | | (_| | (_| |  __/
// |____/ \__,_|\__\__,_| |____/ \__\___/|_|  \__,_|\__, |\___|
//                                                  |___/      
//

vec4 LoadVec4( sampler2D sampler, in ivec2 addr )
{
    return texelFetch( sampler, addr, 0 );
}

vec3 LoadVec3( sampler2D sampler, in ivec2 addr )
{
    return LoadVec4( sampler, addr ).xyz;
}

bool AtAddress( ivec2 p, ivec2 c ) { return all( equal( p, c ) ); }

void StoreVec4( in ivec2 addr, in vec4 value, inout vec4 fragColor, in ivec2 fragCoord )
{
    fragColor = AtAddress( fragCoord, addr ) ? value : fragColor;
}

void StoreVec3( in ivec2 addr, in vec3 value, inout vec4 fragColor, in ivec2 fragCoord )
{
    StoreVec4( addr, vec4( value, 0.0 ), fragColor, fragCoord );
}

//
//  ____       _        _   _             
// |  _ \ ___ | |_ __ _| |_(_) ___  _ __  
// | |_) / _ \| __/ _` | __| |/ _ \| '_ \ 
// |  _ < (_) | || (_| | |_| | (_) | | | |
// |_| \_\___/ \__\__,_|\__|_|\___/|_| |_|
//                                        
//

vec3 RotateX( const in vec3 pos, const in float angle )
{
    float s = sin( angle );
    float c = cos( angle );
    
    vec3 result = vec3( pos.x, c * pos.y + s * pos.z, -s * pos.y + c * pos.z );
    
    return result;
}

vec3 RotateY( const in vec3 pos, const in float angle )
{
    float s = sin( angle );
    float c = cos( angle );
    
    vec3 result = vec3( c * pos.x + s * pos.z, pos.y, -s * pos.x + c * pos.z );
    
    return result;
}

vec3 RotateZ( const in vec3 pos, const in float angle )
{
    float s = sin( angle );
    float c = cos( angle );
    
    vec3 result = vec3( c * pos.x + s * pos.y, -s * pos.x + c * pos.y, pos.z );
    
    return result;
}


mat3 MatFromAngles( vec3 angles )
{
    mat3 rotX = mat3(1.0, 0.0, 0.0, 
                     0.0, cos(angles.x), sin(angles.x), 
                     0.0, -sin(angles.x), cos(angles.x));
    
    mat3 rotY = mat3(cos(angles.y), 0.0, -sin(angles.y), 
                     0.0, 1.0, 0.0, 
                     sin(angles.y), 0.0, cos(angles.y));    

    mat3 rotZ = mat3(cos(angles.z), sin(angles.z), 0.0,
                     -sin(angles.z), cos(angles.z), 0.0,
                     0.0, 0.0, 1.0 );
    
    
    mat3 m = rotY * rotX * rotZ;
    
    return m;
}


//   ___              _                  _             
//  / _ \ _   _  __ _| |_ ___ _ __ _ __ (_) ___  _ __  
// | | | | | | |/ _` | __/ _ \ '__| '_ \| |/ _ \| '_ \ 
// | |_| | |_| | (_| | ||  __/ |  | | | | | (_) | | | |
//  \__\_\\__,_|\__,_|\__\___|_|  |_| |_|_|\___/|_| |_|
//                                                     
//

vec4 QuatMul( vec4 lhs, vec4 rhs ) 
{
      return vec4( lhs.y * rhs.z - lhs.z * rhs.y + lhs.x * rhs.w + lhs.w *rhs.x,
                   lhs.z * rhs.x - lhs.x * rhs.z + lhs.y * rhs.w + lhs.w *rhs.y,
                   lhs.x * rhs.y - lhs.y * rhs.x + lhs.z * rhs.w + lhs.w *rhs.z,
                   lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z *rhs.z );
}

vec4 QuatFromAxisAngle( vec3 axis, float angle )
{
	return vec4( normalize(axis) * sin( angle ), cos( angle ) );    
}

vec4 QuatFromVec3( vec3 rot )
{
    float l = length( rot );
    if ( l <= 0.0 )
    {
        return vec4( 0.0, 0.0, 0.0, 1.0 );
    }
    return QuatFromAxisAngle( rot, l );
}

mat3 QuatToMat3( const in vec4 q )
{
	vec4 qSq = q * q;
	float xy2 = q.x * q.y * 2.0;
	float xz2 = q.x * q.z * 2.0;
	float yz2 = q.y * q.z * 2.0;
	float wx2 = q.w * q.x * 2.0;
	float wy2 = q.w * q.y * 2.0;
	float wz2 = q.w * q.z * 2.0;
 
	return mat3 (	
     qSq.w + qSq.x - qSq.y - qSq.z, xy2 - wz2, xz2 + wy2,
     xy2 + wz2, qSq.w - qSq.x + qSq.y - qSq.z, yz2 - wx2,
     xz2 - wy2, yz2 + wx2, qSq.w - qSq.x - qSq.y + qSq.z );
}

vec3 QuatMul( vec3 v, vec4 q )
{
    // TODO Validate vs other quat code
    vec3 t = 2.0 * cross(q.xyz, v);
	return v + q.w * t + cross(q.xyz, t);
}

//
//  _  __          _                         _ 
// | |/ /___ _   _| |__   ___   __ _ _ __ __| |
// | ' // _ \ | | | '_ \ / _ \ / _` | '__/ _` |
// | . \  __/ |_| | |_) | (_) | (_| | | | (_| |
// |_|\_\___|\__, |_.__/ \___/ \__,_|_|  \__,_|
//           |___/                             
//

const int KEY_SPACE = 32;
const int KEY_LEFT  = 37;
const int KEY_UP    = 38;
const int KEY_RIGHT = 39;
const int KEY_DOWN  = 40;
const int KEY_A     = 65;
const int KEY_B     = 66;
const int KEY_C     = 67;
const int KEY_D     = 68;
const int KEY_E     = 69;
const int KEY_F     = 70;
const int KEY_G     = 71;
const int KEY_H     = 72;
const int KEY_I     = 73;
const int KEY_J     = 74;
const int KEY_K     = 75;
const int KEY_L     = 76;
const int KEY_M     = 77;
const int KEY_N     = 78;
const int KEY_O     = 79;
const int KEY_P     = 80;
const int KEY_Q     = 81;
const int KEY_R     = 82;
const int KEY_S     = 83;
const int KEY_T     = 84;
const int KEY_U     = 85;
const int KEY_V     = 86;
const int KEY_W     = 87;
const int KEY_X     = 88;
const int KEY_Y     = 89;
const int KEY_Z     = 90;
const int KEY_COMMA = 188;
const int KEY_PER   = 190;

const int KEY_1 = 	49;
const int KEY_2 = 	50;
const int KEY_3 = 	51;
const int KEY_ENTER = 13;
const int KEY_SHIFT = 16;
const int KEY_CTRL  = 17;
const int KEY_ALT   = 18;
const int KEY_TAB	= 9;

bool Key_IsPressed( sampler2D samp, int key )
{
    return texelFetch( samp, ivec2(key, 0), 0 ).x > 0.0;    
}

bool Key_IsToggled(sampler2D samp, int key )
{
    return texelFetch( samp, ivec2(key, 2), 0 ).x > 0.0;    
}

// ---- 8< ---- GLSL Number Printing - @P_Malin ---- 8< ----
// Creative Commons CC0 1.0 Universal (CC-0) 
// https://www.shadertoy.com/view/4sBSWW

float DigitBin( const int x )
{
    return x==0?480599.0:x==1?139810.0:x==2?476951.0:x==3?476999.0:x==4?350020.0:x==5?464711.0:x==6?464727.0:x==7?476228.0:x==8?481111.0:x==9?481095.0:0.0;
}

float PrintValue( vec2 vStringCoords, float fValue, float fMaxDigits, float fDecimalPlaces )
{       
    if ((vStringCoords.y < 0.0) || (vStringCoords.y >= 1.0)) return 0.0;
    
    bool bNeg = ( fValue < 0.0 );
	fValue = abs(fValue);
    
	float fLog10Value = log2(abs(fValue)) / log2(10.0);
	float fBiggestIndex = max(floor(fLog10Value), 0.0);
	float fDigitIndex = fMaxDigits - floor(vStringCoords.x);
	float fCharBin = 0.0;
	if(fDigitIndex > (-fDecimalPlaces - 1.01)) {
		if(fDigitIndex > fBiggestIndex) {
			if((bNeg) && (fDigitIndex < (fBiggestIndex+1.5))) fCharBin = 1792.0;
		} else {		
			if(fDigitIndex == -1.0) {
				if(fDecimalPlaces > 0.0) fCharBin = 2.0;
			} else {
                float fReducedRangeValue = fValue;
                if(fDigitIndex < 0.0) { fReducedRangeValue = fract( fValue ); fDigitIndex += 1.0; }
				float fDigitValue = (abs(fReducedRangeValue / (pow(10.0, fDigitIndex))));
                fCharBin = DigitBin(int(floor(mod(fDigitValue, 10.0))));
			}
        }
	}
    return floor(mod((fCharBin / pow(2.0, floor(fract(vStringCoords.x) * 4.0) + (floor(vStringCoords.y * 5.0) * 4.0))), 2.0));
}

vec3 CylinderProjectionToDir( vec2 uv )
{
    float theta = uv.x * TAU + 2.0;
    float sy = sin(uv.y * PI);
    float cy = -cos(uv.y * PI);
    
    vec2 mapDir = vec2( sin(theta), cos(theta) );
    vec3 dir = vec3(mapDir.x * sy, cy, mapDir.y * sy);
    return dir;
}

// ---- 8< -------- 8< -------- 8< -------- 8< ----


//
//   ____                               
//  / ___|__ _ _ __ ___   ___ _ __ __ _ 
// | |   / _` | '_ ` _ \ / _ \ '__/ _` |
// | |__| (_| | | | | | |  __/ | | (_| |
//  \____\__,_|_| |_| |_|\___|_|  \__,_|
//                                      


struct CameraState
{
    vec3 vPos;
    vec3 vTarget;
    vec3 vUp;
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
    vec4 vUp = LoadVec4( sampler, addr + ivec2(2,0) );
    cam.vUp = vUp.xyz;
    
    vec4 jitterDof = LoadVec4( sampler, addr + ivec2(3,0) );
    cam.vJitter = jitterDof.xy;
    cam.fPlaneInFocus = jitterDof.z;
}

void Cam_StoreState( ivec2 addr, const in CameraState cam, inout vec4 fragColor, in ivec2 fragCoord )
{
    StoreVec4( addr + ivec2(0,0), vec4( cam.vPos, 0 ), fragColor, fragCoord );
    StoreVec4( addr + ivec2(1,0), vec4( cam.vTarget, cam.fFov ), fragColor, fragCoord );    
    StoreVec4( addr + ivec2(2,0), vec4( cam.vUp, 0 ), fragColor, fragCoord );    
    StoreVec4( addr + ivec2(3,0), vec4( cam.vJitter, cam.fPlaneInFocus, 0 ), fragColor, fragCoord );    
}

mat3 Cam_GetWorldToCameraRotMatrix( const CameraState cameraState )
{
    vec3 vForward = normalize( cameraState.vTarget - cameraState.vPos );
	vec3 vRight = normalize( cross( cameraState.vUp, vForward) );
	vec3 vUp = normalize( cross(vForward, vRight) );
    
    return mat3( vRight, vUp, vForward );
}

vec2 Cam_GetViewCoordFromUV( vec2 vUV, float fAspectRatio )
{
	vec2 vWindow = vUV * 2.0 - 1.0;
	vWindow.x *= fAspectRatio;

	return vWindow;	
}

void Cam_GetCameraRay( const vec2 vUV, const float fAspectRatio, const CameraState cam, out vec3 vRayOrigin, out vec3 vRayDir )
{
    vec2 vView = Cam_GetViewCoordFromUV( vUV, fAspectRatio );
    vRayOrigin = cam.vPos;
    float fPerspDist = 1.0 / tan( radians( cam.fFov ) );
    vRayDir = normalize( Cam_GetWorldToCameraRotMatrix( cam ) * vec3( vView, fPerspDist ) );
    #if EQUIRECTANGULAR_PROJECTION
    vRayDir = CylinderProjectionToDir(vUV);
    #endif
}

// fAspectRatio = iResolution.x / iResolution.y;
vec2 Cam_GetUVFromWindowCoord( const in vec2 vWindow, float fAspectRatio )
{
    vec2 vScaledWindow = vWindow;
    vScaledWindow.x /= fAspectRatio;

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

void Cam_DebugOverlay( inout vec3 colour, CameraState cam, vec2 uv, float depth )
{
    vec2 pos = uv * vec2(80,30);
    pos.x -= 2.0;
    pos.y -= 28.0;
    
    if ( pos.x > -0.5 && pos.y < 1.5 && pos.x < 40.5 && pos.y > -4.5 )
    {
        colour = vec3(0);
    }
    
    vec2 hpos = pos;
    colour = mix( colour, vec3(0,0,1), PrintValue( hpos, cam.vPos.x, 3.0, 3.0 ) );
    hpos.x -= 10.0;
    colour = mix( colour, vec3(0,0,1), PrintValue( hpos, cam.vPos.y, 3.0, 3.0 ) );
    hpos.x -= 10.0;
    colour = mix( colour, vec3(0,0,1), PrintValue( hpos, cam.vPos.z, 3.0, 3.0 ) );
    hpos.x -= 10.0;
    
    pos.y += 1.3;
    
	hpos = pos;
    colour = mix( colour, vec3(1,0,1), PrintValue( hpos, cam.vTarget.x, 3.0, 3.0 ) );
    hpos.x -= 10.0;
    colour = mix( colour, vec3(1,0,1), PrintValue( hpos, cam.vTarget.y, 3.0, 3.0 ) );
    hpos.x -= 10.0;
    colour = mix( colour, vec3(1,0,1), PrintValue( hpos, cam.vTarget.z, 3.0, 3.0 ) );
    hpos.x -= 10.0;
    
    pos.y += 1.3;
    
	hpos = pos;
    colour = mix( colour, vec3(0,1,0), PrintValue( hpos, cam.fFov, 3.0, 3.0 ) );
    hpos.x -= 10.0;
    colour = mix( colour, vec3(0,1,0), PrintValue( hpos, depth, 3.0, 3.0 ) );
    
    
    vec3 vDir = normalize(cam.vTarget - cam.vPos);
    vec3 vTarget2 = cam.vPos + vDir * depth;
    
    pos.y += 1.3;
    
	hpos = pos;
    colour = mix( colour, vec3(0,1,1), PrintValue( hpos, vTarget2.x, 3.0, 3.0 ) );
    hpos.x -= 10.0;
    colour = mix( colour, vec3(0,1,1), PrintValue( hpos, vTarget2.y, 3.0, 3.0 ) );
    hpos.x -= 10.0;
    colour = mix( colour, vec3(0,1,1), PrintValue( hpos, vTarget2.z, 3.0, 3.0 ) );
    hpos.x -= 10.0;    
}

//  _   _           _       _____                 _   _                 
// | | | | __ _ ___| |__   |  ___|   _ _ __   ___| |_(_) ___  _ __  ___ 
// | |_| |/ _` / __| '_ \  | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
// |  _  | (_| \__ \ | | | |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
// |_| |_|\__,_|___/_| |_| |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
//                                                                      

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
// Hash without Sine
// MIT License...
/* Copyright (c)2014 David Hoskins.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.*/

//----------------------------------------------------------------------------------------
//  1 out, 1 in...
float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

//----------------------------------------------------------------------------------------
//  1 out, 2 in...
float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

//----------------------------------------------------------------------------------------
//  1 out, 3 in...
float hash13(vec3 p3)
{
	p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

//----------------------------------------------------------------------------------------
//  2 out, 1 in...
vec2 hash21(float p)
{
	vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}

//----------------------------------------------------------------------------------------
///  2 out, 2 in...
vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}

//----------------------------------------------------------------------------------------
///  2 out, 3 in...
vec2 hash23(vec3 p3)
{
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

//----------------------------------------------------------------------------------------
//  3 out, 1 in...
vec3 hash31(float p)
{
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}


//----------------------------------------------------------------------------------------
///  3 out, 2 in...
vec3 hash32(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

//----------------------------------------------------------------------------------------
///  3 out, 3 in...
vec3 hash33(vec3 p3)
{
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);

}

//----------------------------------------------------------------------------------------
// 4 out, 1 in...
vec4 hash41(float p)
{
	vec4 p4 = fract(vec4(p) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
    
}

//----------------------------------------------------------------------------------------
// 4 out, 2 in...
vec4 hash42(vec2 p)
{
	vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);

}

//----------------------------------------------------------------------------------------
// 4 out, 3 in...
vec4 hash43(vec3 p)
{
	vec4 p4 = fract(vec4(p.xyzx)  * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

//----------------------------------------------------------------------------------------
// 4 out, 4 in...
vec4 hash44(vec4 p4)
{
	p4 = fract(p4  * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}


// https://iquilezles.org/articles/intersectors
// sphere of size ra centered at point ce
vec2 sphIntersect( in vec3 ro, in vec3 rd, in vec3 ce, float ra )
{
    vec3 oc = ro - ce;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - ra*ra;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1.0); // no intersection
    h = sqrt( h );
    return vec2( -b-h, -b+h );
}

// https://iquilezles.org/articles/smin
float smin( float a, float b, float k )
{
	float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
	return mix( b, a, h ) - k*h*(1.0-h);
}

// https://iquilezles.org/articles/smin
float smax( float a, float b, float k )
{
	float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
	return mix( a, b, h ) + k*h*(1.0-h);
}

///////////////////////////////////////////////////////////
// Smoothnoise

vec2 SmoothNoise22( vec2 o ) 
{
	vec2 p = floor(o);
	vec2 f = fract(o);
		
	float n = p.x + p.y*57.0;

	vec2 a = hash21(n+  0.0);
	vec2 b = hash21(n+  1.0);
	vec2 c = hash21(n+ 57.0);
	vec2 d = hash21(n+ 58.0);
	
	vec2 f2 = f * f;
	vec2 f3 = f2 * f;
	
	vec2 t = 3.0 * f2 - 2.0 * f3;
	
	float u = t.x;
	float v = t.y;

	vec2 res = a + (b-a)*u +(c-a)*v + (a-b+d-c)*u*v;
    
    return res;
}


vec3 SmoothNoise32( vec2 o ) 
{
	vec2 p = floor(o);
	vec2 f = fract(o);
		
	float n = p.x + p.y*57.0;

	vec3 a = hash31(n+  0.0);
	vec3 b = hash31(n+  1.0);
	vec3 c = hash31(n+ 57.0);
	vec3 d = hash31(n+ 58.0);
	
	vec2 f2 = f * f;
	vec2 f3 = f2 * f;
	
	vec2 t = 3.0 * f2 - 2.0 * f3;
	
	float u = t.x;
	float v = t.y;

	vec3 res = a + (b-a)*u +(c-a)*v + (a-b+d-c)*u*v;
    
    return res;
}

////////////////////////////////////////////
// Sky / Environment sampling
	   
struct EnvironmentSettings
{
    float time;
    
    vec3 skyZenithCol;
    vec3 skyHorizonCol;
    
    vec3 sunDiscCol;
    vec3 sunLightCol;
    
    vec3 ambientCol;
    
    float sunElevation;
    float sunHeading;
    vec3 sunDir;
    
    vec3 fogCol;
    float fogDensity;
    float skyFogDensity;
};

float CloudSample( sampler2D iChannel, vec2 uv, float time, float spread )
{
    vec2 cloudUV0 = uv;
    cloudUV0 += time * 0.0005;
    vec2 cloudUV1 = cloudUV0 * 2.0f; 
    cloudUV1 += time * 0.0005;
    float cloudSampleA0 = texture( iChannel, cloudUV0, spread ).r;    
    float cloudSampleA1 = texture( iChannel, cloudUV1, spread ).b;
	float cloudDensityA = cloudSampleA0 * 0.7 + cloudSampleA1 * 0.3;
    
    return cloudDensityA;
}

vec4 TraceSky( EnvironmentSettings env, sampler2D iChannel, vec3 dir, float time, float spread, bool sunDisc )
{       
    // sky gradient
    float f = clamp( 1.0 - dir.y, 0.0f, 1.0f );    
    f = f * f * f * f;
    vec3 col = mix( env.skyZenithCol, env.skyHorizonCol, f );    
    
    // sun disc
    float VdotL = dot( dir, env.sunDir );        
    
    if ( sunDisc )
    {
        const float a0 = cos( radians( 1.0 ) );
        const float a1 = cos( radians( 0.8 ) );

        float sunBlend = smoothstep( a0, a1, VdotL );
        col = mix( col, env.sunDiscCol, sunBlend );    
    }
    
    float dist = 100000.0;
    
    // cloud layer 
    if ( dir.y > 0.0 )
    {
        float earthRadius = 6371000.0f;
        vec3 earthOrigin = vec3(0.0f, -earthRadius, 0.0f );
        float cloudHeight = 6000.0f;
        float cloudRadius = earthRadius + cloudHeight;

        vec2 cloudInt = sphIntersect( vec3(0), dir, earthOrigin, cloudRadius );
        float cloudT = cloudInt.y;
        
        dist = cloudT;


        vec3 cloudPos = dir * cloudT;

        vec3 cloudN = normalize( cloudPos - earthOrigin );

        vec2 cloudUV = cloudPos.xz * 0.00001f;
        float cloudDensityA = CloudSample( iChannel, cloudUV, time, spread );
        float bumpOffset = 0.0003f;
        float cloudDensityB = CloudSample( iChannel, cloudUV - env.sunDir.xz * bumpOffset, time, spread );

        float cloudDensity = (cloudDensityA + cloudDensityB) * 0.5;

        // bumpmap towards sun
        float cloudBumpLight = max( 0.0f, (cloudDensityB - cloudDensityA) * 1.5 + 0.5);

        float sunThicknessFactor = 1.0 / dot( cloudN, env.sunDir );
        
        sunThicknessFactor = abs( sunThicknessFactor );


        float toSunFactor = 1.0 - max( 0.0, dot(dir, env.sunDir));
        float toSunAmount = exp( toSunFactor * -20.0 );
        
        float cloudSunLight = cloudBumpLight * (1.0 + toSunAmount * 2.5);

        float viewThicknessFactor = 1.0 / dot( cloudN, dir );

        float cover = 0.2;
        float density = 0.1;

        float thickness = max( 0.0, (cloudDensity - cover) / (1.0 - cover) );

        float cloudOpticalDepth = thickness * viewThicknessFactor;
        float sunCloudOpticalDepth = thickness * sunThicknessFactor;
        
        vec3 litCloudCol = env.sunLightCol * cloudSunLight * ( exp( sunCloudOpticalDepth * -density ) ) * 10.0; 
        vec3 cloudCol = litCloudCol + env.ambientCol;


        float cloudBlend = 1.0 - exp( cloudOpticalDepth * -density );
        col = mix( col, cloudCol, cloudBlend );       
    }
    
    return vec4( col, dist );   
}

/////////////////////////////////////////////////
// Terrain Height


float Terrain_GetShape( vec2 mapPos )
{
    float d = length(mapPos);
        
    float h = SmoothNoise22( mapPos * 0.02 ).x * 100.0 + 50.0;

   	return min( h, d );
}

float Terrain_GetBaseHeight( vec2 mapPos )
{
    float dist = Terrain_GetShape( mapPos );
    float hIsland = 2.0 - dist * dist * 0.0005;

	return hIsland;
}

vec3 GetRockSample( sampler2D rockSampler, vec2 mapPos, float mipLod )
{
    vec2 uv = mapPos * 0.1;
    vec3 textureSample = textureLod( rockSampler, uv.yx, mipLod ).rgb;
    //textureSample.r = (textureSample.r - textureSample.g) / (1.0f - textureSample.g);
    return textureSample = textureSample * textureSample;
}



vec2 Terrain_GetHeights( sampler2D rockSampler,vec2 mapPos, bool detail )
{
    //h = 1.0 - exp( h * -1. );
    //float dist = length( mapPos );
    
    vec2 smoothNoise = SmoothNoise22( mapPos * 20.0 );
        
    float h0 = Terrain_GetBaseHeight( mapPos );
    
    float rockRelief = 0.05;
    
    // + smoothNoise.y
    float rockScale = smoothstep( 2.0, -2.5, h0 );
    //rockScale -= (smoothNoise.y - 0.5) * 0.25;
    vec3 rockSample = GetRockSample( rockSampler, mapPos, 0.0 );
    float rockh = h0 + ((rockSample.g * rockSample.b) - 1.0 + rockScale * 1.5 ) * rockRelief ;// + rockScale - 2.0 * (1.0 - rockScale);
    
    //h += hIsland + 10.0;
    //h = smax( h, hIsland, 0.5 );

    //h= hIsland - h;
    
    //h = 1.0 - exp( h * -0.5 );
    float h = h0 + smoothNoise.x * 0.001;
    
    if ( detail )
    {
        float sandWaveBlend = smoothstep( 0.5, 1.5, h );
        float f = mapPos.y * 20.0 + sin( mapPos.x * 0.3) * 10.0+ cos( mapPos.x * 0.5) * 10.0;
        
    	float w = sin(f) * 0.5 + 0.5;
    
    	w = pow ( 1.0 - w, 1.5 );        
        
        float wave = w * 0.005 * sandWaveBlend;
        
        float rough = SmoothNoise22( mapPos * 2.0 ).x * 0.03;
        
        h += mix( wave, rough, smoothstep( 1.3, 1.5, h ) );
        
        h += SmoothNoise22( mapPos * 1.0 ).x * 0.02;
	    h += SmoothNoise22( mapPos * 1000.0 ).x * 0.001;	
    
        // todo: footsteps?
        //h += (0.5 - textureLod( iChannel2, mapPos * 0.1, 0.0 ).r) * 0.1;
    
#if 1
        if ( h > rockh )
        {
	        float delta = h - rockh;
            float amount = exp2( -delta * 50.0 );
            h -= amount * 0.01;
        }
#endif     
            
    }
    
    return vec2(h,rockh);
}


float Terrain_GetHeight( sampler2D rockSampler, vec2 mapPos, bool detail, bool onlySand )
{
    vec2 heights = Terrain_GetHeights( rockSampler, mapPos, detail );   

    if ( onlySand )
        return heights.x;
    
    return max( heights.x, heights.y );
}

