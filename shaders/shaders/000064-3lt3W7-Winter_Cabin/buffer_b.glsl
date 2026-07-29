// Buffer B (buffer) — Winter Cabin by suyoku
// https://www.shadertoy.com/view/3lt3W7

// Created by Christopher Wallis
#define LARGE_NUMBER 1e20
#define EPSILON 0.0001

#define SKY_LIGHT_COLOR vec3(0.08, 0.16, 0.24)

struct CameraDescription
{
    vec3 Position;
    vec3 LookAt;    

    float LensHeight;
    float FocalDistance;
};
    
struct OrbLightDescription
{
    vec3 Position;
    float Radius;
    vec3 LightColor;
};
    
CameraDescription Camera = CameraDescription(
    vec3(0, 19, 380),
    vec3(0, 15, 0),
    2.0,
    7.0
);

OrbLightDescription CabinLamp = OrbLightDescription(
    vec3(35, 5.6, 7.0),
    1.2,
    vec3(20.0, 8.0, 0.4));

struct PointLightDescription
{
    vec3 Position;
    vec3 LightColor;
};

vec3 AmbientSnowColor = vec3(0, 0, 0.05);

// Pulse the lamp brighness to simulate fireplace-like lighting
float CabinLampMultiplier()
{
    float loopTimeLengthMS = 3000.0;    
    float halfLoopTimeLengthMS = loopTimeLengthMS / 2.0;
    float lerpValue = float(int(iTime * 1000.0) % int(halfLoopTimeLengthMS)) / (halfLoopTimeLengthMS);
    bool invertLerp = (int(iTime * 1000.0) / int(halfLoopTimeLengthMS)) % 2 == 1;
	if(invertLerp)
    {
       lerpValue = 1.0 - lerpValue; 
    }
    return mix(0.6, 1.2, lerpValue);
}

struct AABB
{
    vec3 origin;
    vec3 dimensions;
};

struct WindowDescription
{
    vec3 Position;
    vec3 Dimension;
};

    
#define NUM_POINT_LIGHTS 3
#define NUM_CABIN_WINDOWS 5
struct CabinDescription
{
	PointLightDescription PointLights[NUM_POINT_LIGHTS];
};
    
const vec3 CabinOrigin = vec3(40.0, 0.3, -10);
const vec3 CabinDimensions = vec3(25, 10, 15);
const vec3 CabinZOrientedWindowDimensions = vec3(3.0, 2.5, 0.3);
const vec3 CabinXOrientedWindowDimensions = vec3(
    CabinZOrientedWindowDimensions.z, 
    CabinZOrientedWindowDimensions.y, 
    CabinZOrientedWindowDimensions.x);
const float WindowYOffset = 5.0;
const AABB CabinAABB = AABB(
    CabinOrigin,
    CabinDimensions * vec3(2.0, 3.0, 2.0));

const vec3 FrontAtticWindowPosition = CabinOrigin + vec3(0, 16, CabinDimensions.z);
const vec3 SideMainRoomWindowPosition = CabinOrigin + vec3(CabinDimensions.x, WindowYOffset, 0.0);
const vec3 SideAtticRoomWindowPosition = SideMainRoomWindowPosition + vec3(0.0, 11.0, 0.0);
CabinDescription Cabin = CabinDescription(
    PointLightDescription[NUM_POINT_LIGHTS] (
       PointLightDescription(FrontAtticWindowPosition + vec3(0, 0, 4.5), vec3(9.0, 3.3, 0.2)),
       PointLightDescription(SideMainRoomWindowPosition + vec3(4.0, 0, 0), vec3(12.0, 4.0, 0.2)),
       PointLightDescription(SideAtticRoomWindowPosition + vec3(4.0, 0, 0), vec3(6.0, 2.2, 0.15))
	)
);

// --------------------------------------------//
//               Noise Functions
// --------------------------------------------//
float rand(float seed)
{
    return fract(sin(seed / 100.0) * 999.999);
}

// I believe this was written using Scratchapixel as a reference, it's been a while
// https://www.scratchapixel.com/code.php?id=57&origin=/lessons/procedural-generation-virtual-worlds/perlin-noise-part-2
vec2 GenerateGradientVector(float x, float y)
{
    float resolution = 1024.0;
    float val = x + y * resolution;
	float angle = rand(val) * 3.1415;
    return vec2(cos(angle), sin(angle));
}

// https://www.scratchapixel.com/code.php?id=57&origin=/lessons/procedural-generation-virtual-worlds/perlin-noise-part-2
float perlin_noise(vec2 pos)
{
    float x = pos.x / 32.0;
    float y = pos.y / 32.0;
    
	float value = 0.0;
    float x0 = floor(x);    
    float y0 = floor(y);
	float x1 = x0 + 1.0;	
    float y1 = y0 + 1.0;
    
    vec2 a = GenerateGradientVector(x0, y0);
    vec2 b = GenerateGradientVector(x1, y0);
    vec2 c = GenerateGradientVector(x0, y1);
    vec2 d = GenerateGradientVector(x1, y1);
    
    vec2 aD = vec2(x - x0, y - y0);    
    vec2 bD = vec2(x - x1, y - y0);
    vec2 cD = vec2(x - x0, y - y1);
    vec2 dD = vec2(x - x1, y - y1);
    
    float aDot = dot(a, aD);
    float bDot = dot(b, bD);
    float cDot = dot(c, cD);
    float dDot = dot(d, dD);
    
    float dx = x - x0;    
    float dy = y - y0;
	float sX = 3.0 * dx * dx - 2.0 * dx * dx * dx;
	float sY = 3.0 * dy * dy - 2.0 * dy * dy * dy;
    float firstAverage = mix(aDot, bDot, sX);
    float secondAverage = mix(cDot, dDot, sX);
    value = mix(firstAverage, secondAverage, y - y0);
	
	return ( value + 1.0 ) / 2.0;
}

float PerlinSeries(vec2 pos)
{
    return perlin_noise(pos) + 0.4 * perlin_noise(pos * 2.0) + 0.2 * perlin_noise(pos * 4.0);
}

// Taken from Inigo Quilez's Rainforest ShaderToy:
// https://www.shadertoy.com/view/4ttSWf
float hash1( float n )
{
    return fract( n*17.0*fract( n*0.3183099 ) );
}

// Taken from Inigo Quilez's Rainforest ShaderToy:
// https://www.shadertoy.com/view/4ttSWf
float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 w = fract(x);
    
    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    
    float n = p.x + 317.0*p.y + 157.0*p.z;
    
    float a = hash1(n+0.0);
    float b = hash1(n+1.0);
    float c = hash1(n+317.0);
    float d = hash1(n+318.0);
    float e = hash1(n+157.0);
	float f = hash1(n+158.0);
    float g = hash1(n+474.0);
    float h = hash1(n+475.0);

    float k0 =   a;
    float k1 =   b - a;
    float k2 =   c - a;
    float k3 =   e - a;
    float k4 =   a - b - c + d;
    float k5 =   a - c - e + g;
    float k6 =   a - b - e + f;
    float k7 = - a + b + c - d + e - f - g + h;

    return -1.0+2.0*(k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z);
}

const mat3 m3  = mat3( 0.00,  0.80,  0.60,
                      -0.80,  0.36, -0.48,
                      -0.60, -0.48,  0.64 );

// Taken from Inigo Quilez's Rainforest ShaderToy:
// https://www.shadertoy.com/view/4ttSWf
float fbm_4( in vec3 x )
{
    float f = 2.0;
    float s = 0.5;
    float a = 0.0;
    float b = 0.5;
    for( int i=min(0, iFrame); i<4; i++ )
    {
        float n = noise(x);
        a += b*n;
        b *= s;
        x = f*m3*x;
    }
	return a;
}

// --------------------------------------------//
//               SDF Functions
// --------------------------------------------//

// Taken from https://iquilezles.org/articles/distfunctions
float sdPlane( vec3 p )
{
	return p.y;
}

// Taken from https://iquilezles.org/articles/distfunctions
vec2 opU( vec2 d1, vec2 d2 )
{
	return (d1.x<d2.x) ? d1 : d2;
}

// Taken from https://iquilezles.org/articles/distfunctions
float opSmoothUnion( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

vec3 Translate(vec3 pos, vec3 translate)
{
    return pos -= translate;
}

// Taken from https://iquilezles.org/articles/distfunctions
float sdCapsule( vec3 p, vec3 origin, vec3 a, vec3 b, float r )
{
  p -= origin;
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

// Taken from https://iquilezles.org/articles/distfunctions
float sdCappedCylinder( vec3 p, vec3 origin, float h, float r )
{
	p -= origin;
  	vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
	return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

// Taken from https://iquilezles.org/articles/distfunctions
float CappedCylinder( vec3 p, vec3 cylinderOrigin, float h, float r )
{
  p = Translate(p, cylinderOrigin);
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

// Taken from https://iquilezles.org/articles/distfunctions
float BoxIntersect( vec3 p, vec3 boxOrigin, vec3 boxDimensions)
{
  p = Translate(p, boxOrigin);
  vec3 q = abs(p) - boxDimensions;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

// Taken from https://iquilezles.org/articles/distfunctions
vec3 SymetryAcrossXAxis(vec3 pos)
{
    pos.x = abs(pos.x);
    return pos;
}

// Taken from https://iquilezles.org/articles/distfunctions
float SphereIntersect( vec3 p, vec3 origin, float s )
{
  p = Translate(p, origin);
  return length(p)-s;
}

// Taken from https://iquilezles.org/articles/distfunctions
float sdCone( vec3 p, vec3 origin, vec2 c )
{
  p = Translate(p, origin);
  float q = length(p.xz);
  return dot(c,vec2(q,p.y));
}

// Taken from https://iquilezles.org/articles/distfunctions
float dot2(in vec2 v ) {return dot(v,v);}
float sdCappedCone( vec3 p, vec3 origin, float h, float r1, float r2 )
{
  p -= origin;
  vec2 q = vec2( length(p.xz), p.y );
  vec2 k1 = vec2(r2,h);
  vec2 k2 = vec2(r2-r1,2.0*h);
  vec2 ca = vec2(q.x-min(q.x,(q.y<0.0)?r1:r2), abs(q.y)-h);
  vec2 cb = q - k1 + k2*clamp( dot(k1-q,k2)/dot2(k2), 0.0, 1.0 );
  float s = (cb.x<0.0 && ca.y<0.0) ? -1.0 : 1.0;
  return s*sqrt( min(dot2(ca),dot2(cb)) );
}

// Modified Prism sdf code from https://iquilezles.org/articles/distfunctions
float TriPrism( vec3 p, vec2 h, float angle )
{
  float NinetyDegreesInRadians = PI / 2.0;
  vec3 q = abs(p);
  return max(q.z-h.y,max(q.x*sin(angle)+p.y*sin(NinetyDegreesInRadians - angle),-p.y)-h.x*sin(NinetyDegreesInRadians - angle));
}

float ZAlignedTriPrism( vec3 p, vec3 origin, vec2 h, float angle )
{
  p = Translate(p, origin);
  p.y -= h.x / 2.0;
  return TriPrism(p, h, angle);
}


// Strange hack required because using a global array causes
// some strange compiler optimizations to go wrong
WindowDescription GetWindow(int index)
{
    switch(index)
    {
        default:
        case 0:
        	return WindowDescription(FrontAtticWindowPosition, CabinZOrientedWindowDimensions * 0.6);
        case 1:
        	return WindowDescription(CabinOrigin + vec3(15, WindowYOffset, CabinDimensions.z), CabinZOrientedWindowDimensions);
        case 2:
			return WindowDescription(CabinOrigin + vec3(-15, WindowYOffset, CabinDimensions.z), CabinZOrientedWindowDimensions);
        case 3:
			return WindowDescription(CabinOrigin + vec3(CabinDimensions.x, WindowYOffset, 0.0), CabinXOrientedWindowDimensions);
		case 4:
        	return WindowDescription(SideAtticRoomWindowPosition, CabinXOrientedWindowDimensions * 0.6);
    }
}

#define MATERIAL_NEEDS_REFLECTION_RAYS 0x1
#define MATERIAL_IS_LIGHT_SOURCE 0x2
#define MATERIAL_NO_SPECULAR 0x4
#define MATERIAL_IS_SNOW 0x8
#define MATERIAL_SUPPORTS_SPECULAR_LIGHT 0x10

struct Material
{
    vec3 albedo;
    vec3 emissive;
    int flags;
};
    
Material NormalMaterial(vec3 albedo, int flags)
{
    return Material(albedo, vec3(0), flags);
}

bool NeedsReflectionRays(in Material m)
{
    return (m.flags & MATERIAL_NEEDS_REFLECTION_RAYS) != 0;
}

bool IsLightSource(in Material m)
{
    return (m.flags & MATERIAL_IS_LIGHT_SOURCE) != 0;
}

bool IsSnow(in Material m)
{
    return (m.flags & MATERIAL_IS_SNOW) != 0;
}

bool SupportsSpecular(in Material m)
{
    return (m.flags & MATERIAL_NO_SPECULAR) == 0;
}


bool SupportsSpecularLight(in Material m)
{
    return (m.flags & MATERIAL_SUPPORTS_SPECULAR_LIGHT) != 0;
}

Material GetMaterial(int materialID, vec3 position)
{
    Material materials[NUM_MATERIALS];
	materials[SNOW_MATERIAL_ID] = NormalMaterial(vec3(0.6, 0.6, 0.7), MATERIAL_NO_SPECULAR | MATERIAL_SUPPORTS_SPECULAR_LIGHT | MATERIAL_IS_SNOW);
    materials[ROOF_SNOW_MATERIAL_ID] = NormalMaterial(vec3(0.8, 0.8, 1.3), MATERIAL_SUPPORTS_SPECULAR_LIGHT | MATERIAL_IS_SNOW);
    materials[WOOD_MATERIAL_ID] = NormalMaterial(vec3(0.2, 0.1, 0.05), MATERIAL_NO_SPECULAR);
	materials[CABIN_LAMP_MATERIAL_ID] = NormalMaterial(CabinLamp.LightColor, MATERIAL_IS_LIGHT_SOURCE);
    materials[ICE_MATERIAL_ID] = NormalMaterial(vec3(0.05, 0.05, 0.1), MATERIAL_NEEDS_REFLECTION_RAYS);
    materials[TREE_MATERIAL_ID] = NormalMaterial(vec3(0.1, 0.1, 0.0), 0);
    materials[DISTANT_TREE_MATERIAL_ID] = NormalMaterial(vec3(0.03, 0.03, 0.0), MATERIAL_NO_SPECULAR);
    materials[LEAF_MATERIAL_ID] = NormalMaterial(vec3(0.1, 0.1, 0.0), MATERIAL_NO_SPECULAR);
    
    if(materialID < int(NUM_MATERIALS))
    {
        return materials[materialID];
    }
    else // Is a custom material
    {
		if(materialID >= int(CABIN_WINDOW_MATERIAL_CUSTOM_BASE_ID) && materialID < int(CABIN_WINDOW_MATERIAL_CUSTOM_BASE_ID + NUM_CABIN_WINDOWS))
        {
            int windowIndex = materialID - int(CABIN_WINDOW_MATERIAL_CUSTOM_BASE_ID);
            
            Material windowMaterial = Material(vec3(0.0, 0.0, 0.0), vec3(0), 0);
            WindowDescription window = GetWindow(windowIndex);
            float radius = max(window.Dimension.z, max(window.Dimension.x, window.Dimension.y));
            bool orientedTowardsXAxiz = window.Dimension.z > window.Dimension.x;
            if(orientedTowardsXAxiz)
            {
                position.xz = position.zx;
                window.Position.xz = window.Position.zx;
                window.Dimension.xz = window.Dimension.zx;
            }
            float xDist = abs(position.x - window.Position.x);
            float yDist = abs(position.y - window.Position.y);
            float xRatio = xDist / (window.Dimension.x / 2.0);
			float yRatio = yDist / (window.Dimension.y / 2.0);
            if(xRatio  < 0.13 || yRatio < 0.13)
            {
                return materials[WOOD_MATERIAL_ID];
            }
            
            float distFromCenter = length(position.xy - window.Position.xy);
            float lerpValue = min(distFromCenter / radius, 1.0);
			windowMaterial.emissive = mix(vec3(0.85, 0.85, 0.02), vec3(0.85, 0.15, 0.02), lerpValue);;
			return windowMaterial;
        }
    }
    
    
    // Should never get hit
    return materials[0];
}

bool IsColorSignificant(vec3 color)
{
    const float insignificantThreshold = 0.01;
    return color.r > insignificantThreshold || color.b > insignificantThreshold 
        || color.g > insignificantThreshold;
}

bool IntersectsAABB(vec3 rayOrigin, vec3 rayDirection, AABB aabb)
{
    vec3 inverseDirection = 1.0 / rayDirection;
    vec3 middlePoint = (aabb.origin - rayOrigin) * inverseDirection;
    vec3 maxL = middlePoint + aabb.dimensions * abs(inverseDirection);
    vec3 minL = middlePoint - aabb.dimensions * abs(inverseDirection);

    float minT = max(max(minL.x, minL.y), minL.z);
    float maxT = min(min(maxL.x, maxL.y), maxL.z);

    return max(minT, 0.0) < maxT;
}

float WoodDeformation(vec3 pos, bool horizontal)
{
    // Stretch the noise in a direction to give the appearance of wood grain
    vec2 uv = horizontal ? 
        vec2((pos.x + pos.z) / 500.0, pos.y / 50.0) : 
    	vec2((pos.x + pos.z) / 50.0, pos.y / 500.0);
    float noise = texture(iChannel3, uv).r;
    return mix(-0.075, 0.075, noise);
}

float CabinLogDeformation(vec3 pos)
{
    // abs of a sin wave seems to be a good enough approx. of logs
    return 0.2 * -abs(sin(pos.y * 2.3)) + 0.1 + WoodDeformation(pos, true);
}

float CabinBoxIntersect( vec3 p, vec3 boxOrigin, vec3 boxDimensions)
{
    return BoxIntersect(p, boxOrigin, boxDimensions) + CabinLogDeformation(p);
}

float ZAlignedCabinRoof( vec3 p, vec3 origin, vec2 h, float angle )
{
    return ZAlignedTriPrism(p, origin, h, angle) + CabinLogDeformation(p);
}

void swap(inout float x, inout float y)
{
    float temp = x;
    x = y;
    y = temp;
}

float XAlignedTriPrism( vec3 p, vec3 origin, vec2 h, float angle )
{
  p -= origin;
  p.y -= h.x / 2.0;
  swap(p.x, p.z);
  return TriPrism(p, h, angle);
}

float XAlignedCabinRoof( vec3 p, vec3 origin, vec2 h, float angle )
{
    return XAlignedTriPrism(p, origin, h, angle) + CabinLogDeformation(p);
}

float DetailedTreeIntersect(vec3 p, vec3 origin, float h, float r1, float r2, float fbmNoise )
{
    return sdCappedCone(p, origin, h, r1, r2) + 3.7 * fbmNoise;
}

float CapsuleGridIntersect( vec3 p, vec3 origin, float h, float r, float interval, vec3 l)
{
    p -= origin;
    vec3 q = p-interval*clamp(round(p/interval),-l,l);
    return sdCappedCylinder( q, vec3(0.0), h, r);
}

float TreeTrunkIntersect( vec3 p, vec3 origin, vec2 c )
{
  return sdCone(p, origin, c);
}

float DistantTreeIntersect( vec3 p, vec3 origin, vec2 c, float noiseValue )
{
  return sdCone(p, origin, c) + 2.9 * noiseValue;
}

float DistantTreeGridIntersect( vec3 p, vec3 origin, vec2 c, float interval, vec3 l, float noiseValue)
{
    p -= origin;
    vec3 q = p-interval*clamp(round(p/interval),-l,l);
    return DistantTreeIntersect( q, vec3(0.0), c, noiseValue);
}

float snowMicroDisplacement(in vec3 p)
{
    return 0.5 * PerlinSeries(p.xz * 32.0) - 0.25 +
        3.0 * smoothstep(0.0, 1.0, PerlinSeries(p.xz * 4.0)) - 1.5 +  
        4.0 * smoothstep(0.0, 1.0, PerlinSeries(p.xz * 1.0)) - 2.0;
}

float snowLandscape(in vec3 p )
{   
    vec2 CabinLocation = vec2(40.0, 25);
    float distToCabin = length(p.xz - CabinLocation);
    
    // Push the snow down to form a river moat around the cabin
    {
        // Offset the moat's center so it's not obvious the river is a circle
        vec2 RiverPivotLocation  = CabinLocation + vec2(50, -90);
    	float distToPivot = length(p.xz - RiverPivotLocation);
        
        // sin distortion to the river bank looks interesting
        float sinTransformedDistToPivot = 10.0 * sin(p.z / 20.0) + distToPivot;
        float riverDistFromPivot = 200.0;
        float riverWidth = 160.0;
        float riverDepth = 10.0;
        if(sinTransformedDistToPivot > riverDistFromPivot - riverWidth / 2.0 && 
           sinTransformedDistToPivot < riverDistFromPivot + riverWidth / 2.0)
        {
            float multiplier = 1.0 - (abs(sinTransformedDistToPivot - riverDistFromPivot) / (riverWidth / 2.0));
            multiplier = multiplier * multiplier * (3.0-2.0*multiplier);
            p.y += multiplier * riverDepth;
        }
    }
    
    float planeDist = sdPlane(p);
    float snowDuneDispacement = 3.0 * sin(p.x / 30.0)*sin(p.z / 30.0);
    float microDisplacement = 0.0;
    float approxCameraDist = length(p.xz);
    
    // Poor man's attempt at snow LOD
    if(approxCameraDist < 400.0)
    {
        microDisplacement = snowMicroDisplacement(p);
    }
    return planeDist + snowDuneDispacement + microDisplacement;
}

const float PatioOffset = 28.0;
const float stairWidth = CabinDimensions.x / 2.0;
const vec3 railingDimensions = vec3((CabinDimensions.x - stairWidth / 2.0) / 2.0, 0.4, 0.4);
const float railingHeight = CabinDimensions.y / 4.0;

float CabinPillarIntersect(vec3 pos)
{
    float woodDeformation = WoodDeformation(pos, false);
    // Make all SDFs symetrical wrt the cabin
    pos = SymetryAcrossXAxis(Translate(pos, CabinOrigin));
    
    float pillar1Dist = woodDeformation + sdCappedCylinder(pos, vec3(CabinDimensions.x - 0.7, 0, PatioOffset), CabinDimensions.y, 0.7);
    float pillar2Dist = woodDeformation + sdCappedCylinder(pos, vec3(stairWidth / 2.0, 0, PatioOffset), CabinDimensions.y, 0.7);
    return min(pillar1Dist, pillar2Dist);
}

float CabinRailingIntersect(vec3 pos)
{
    float woodDeformation = WoodDeformation(pos, false);
    // Make all SDFs symetrical wrt the cabin
    pos = SymetryAcrossXAxis(Translate(pos, CabinOrigin));
    
	float railingSupportDist = woodDeformation + CapsuleGridIntersect(pos, vec3((CabinDimensions.x + stairWidth / 2.0) / 2.0, 0, PatioOffset), railingHeight, 0.4, 2.5 , vec3(2, 0, 0));       
	float railingBarDistance = BoxIntersect(pos, vec3((CabinDimensions.x + stairWidth / 2.0) / 2.0, railingHeight, PatioOffset), railingDimensions);
	return min(railingSupportDist, railingBarDistance);
}

#define DEFAULT_INTERSECT_FLAG 0x0
#define SHADOW_INTERSECT_FLAG 0x1
#define SKIP_CABIN_INTERSECT_FLAG 0x2
#define SKIP_GROUND_PLANE_INTERSECT_FLAG 0x4

vec2 QueryDistanceField( in vec3 pos, in int IntersectFlags )
{    
    // Hacky way of trying to speed up the marching when the ray is far past the 
    // close-up geometry
    float approxCameraDist = length(pos.xz);
    bool farFromCamera = approxCameraDist > 500.0;
    
    vec2 res = vec2(99999.0f, 0);
    float noise = fbm_4(pos / 5.0);
    if((IntersectFlags & SHADOW_INTERSECT_FLAG) == 0)
    {
        // Spamming a bunch of instanced trees with enough interval difference to fake a random
        // assortment of trees in the background
        res = opU(res, vec2(DistantTreeGridIntersect(pos, vec3(0, 30, -400.0), vec2(0.8, 0.2), 40.0 , vec3(10, 0, 1), noise), DISTANT_TREE_MATERIAL_ID));
        res = opU(res, vec2(DistantTreeGridIntersect(pos, vec3(0, 50, -400.0), vec2(0.8, 0.2), 60.0 , vec3(10, 0, 1), noise), DISTANT_TREE_MATERIAL_ID));
        res = opU(res, vec2(DistantTreeGridIntersect(pos, vec3(0, 70, -400.0), vec2(0.8, 0.2), 150.0, vec3(10, 0, 1), noise), DISTANT_TREE_MATERIAL_ID));

        res = opU(res, vec2(DistantTreeGridIntersect(pos, vec3(-450, 30, 0.0), vec2(0.8, 0.2), 40.0 , vec3(1, 0, 10), noise), DISTANT_TREE_MATERIAL_ID));
        res = opU(res, vec2(DistantTreeGridIntersect(pos, vec3(-450, 50, 0.0), vec2(0.8, 0.2), 60.0 , vec3(1, 0, 10), noise), DISTANT_TREE_MATERIAL_ID));
        res = opU(res, vec2(DistantTreeGridIntersect(pos, vec3(-450, 70, 0.0), vec2(0.8, 0.2), 150.0, vec3(1, 0, 10), noise), DISTANT_TREE_MATERIAL_ID));

    }
    
    if(!farFromCamera && (IntersectFlags & SHADOW_INTERSECT_FLAG) == 0)
    {
        res = opU(res, vec2(TreeTrunkIntersect(pos, vec3(0, 50, -5.0), vec2(0.95, 0.05)), TREE_MATERIAL_ID));
        res = opU(res, vec2(DetailedTreeIntersect(pos, vec3(0, 30, -5.0), 25.0, 10.0, 0.0, noise), LEAF_MATERIAL_ID));    
        res = opU(res, vec2(DetailedTreeIntersect(pos, vec3(35, 30, -45.0), 50.0, 16.0, 0.0, noise), LEAF_MATERIAL_ID));    
        res = opU(res, vec2(TreeTrunkIntersect(pos, vec3(88, 50, -5.0), vec2(0.95, 0.05)), TREE_MATERIAL_ID));
        res = opU(res, vec2(DetailedTreeIntersect(pos, vec3(88, 30, -5.0), 30.0, 12.0, 0.0, noise), LEAF_MATERIAL_ID));    
    }
    
    if((IntersectFlags & SKIP_GROUND_PLANE_INTERSECT_FLAG) == 0)
    {
		res = opU(res, vec2( snowLandscape(pos), SNOW_MATERIAL_ID ));
    }

    res = opU(res, vec2(SphereIntersect(pos, CabinLamp.Position, CabinLamp.Radius), CABIN_LAMP_MATERIAL_ID));
    
    // Cabin
    if(!farFromCamera && (IntersectFlags & SKIP_CABIN_INTERSECT_FLAG) == 0)
    {
        vec3 PatioDimensions = vec3(CabinDimensions.x, 1, PatioOffset / 2.0);
        // Main room
        res = opU(res, vec2(CabinBoxIntersect(pos, CabinOrigin, CabinDimensions), WOOD_MATERIAL_ID));
        
        vec3 DoorDimensions = vec3(2.0, 7.0, 0.3);
        res = opU(res, vec2(BoxIntersect(pos, CabinOrigin + vec3(0, 0, CabinDimensions.z), DoorDimensions), WOOD_MATERIAL_ID));

        vec3 WindowDimensions = vec3(3.0, 2.5, 0.3);
        float WindowYOffset = 5.0;
        
        for(int i = 0; i < NUM_CABIN_WINDOWS; i++)
        {
            res = opU(res, vec2(BoxIntersect(pos, GetWindow(int(i)).Position, GetWindow(int(i)).Dimension), CABIN_WINDOW_MATERIAL_CUSTOM_BASE_ID + i));
        }
        
        res = opU(res, vec2(CabinPillarIntersect(pos), WOOD_MATERIAL_ID));
        res = opU(res, vec2(CabinRailingIntersect(pos), WOOD_MATERIAL_ID));
		
        // Patio roof
        res = opU(res, vec2(BoxIntersect(pos, CabinOrigin + vec3(0, CabinDimensions.y, PatioOffset / 2.0), PatioDimensions), WOOD_MATERIAL_ID));
 
        // Patio deck
        vec3 DeckDimensions = vec3(CabinDimensions.x, 5, PatioOffset / 2.0);
        res = opU(res, vec2(BoxIntersect(pos, CabinOrigin + vec3(0, -3.5, PatioOffset / 2.0), PatioDimensions), WOOD_MATERIAL_ID));

        float roofAngle = PI / 4.5;
        float atticRoofAngle = PI / 3.6;
        float CabinRoofHeight = CabinDimensions.z * 0.55;
        vec3 CabinRoofOrigin = CabinOrigin + vec3(0, CabinDimensions.y + 2.0, 0);

        if((IntersectFlags & SHADOW_INTERSECT_FLAG) == 0)
        {
        	res = opU(res, vec2(ZAlignedCabinRoof(pos, CabinRoofOrigin, vec2(CabinRoofHeight * 0.7, CabinDimensions.z), atticRoofAngle), WOOD_MATERIAL_ID));
        	res = opU(res, vec2(XAlignedCabinRoof(pos, CabinRoofOrigin, vec2(CabinRoofHeight, CabinDimensions.x), roofAngle), WOOD_MATERIAL_ID));
        }
        
		float yOffset = snowMicroDisplacement(pos) - 1.3;
        float unionMergeFactor = 1.25;
        // Roof snow
        res = opU(res, vec2(
            opSmoothUnion(
                opSmoothUnion(
                    // Patio roof snow
                    BoxIntersect(pos, CabinOrigin + vec3(0, CabinDimensions.y + yOffset, PatioOffset / 2.0), PatioDimensions * 0.98), 
                    // Main roof snow
                    XAlignedTriPrism(pos, CabinRoofOrigin + vec3(0, yOffset + 1.0, 0),  vec2(CabinRoofHeight, CabinDimensions.x) * 0.98, roofAngle),
                    unionMergeFactor),
                // Cabin attic room roof snow
                ZAlignedTriPrism(pos, CabinRoofOrigin + vec3(0, yOffset + 1.15, 0), 0.98 * vec2(CabinRoofHeight * 0.7, CabinDimensions.z),  atticRoofAngle),
                unionMergeFactor), 
            ROOF_SNOW_MATERIAL_ID));
    }

    return res;
}

int CalculateOptimizedIntersectFlags(in vec3 rayOrigin, in vec3 rayDirection)
{
    int intersectFlags = DEFAULT_INTERSECT_FLAG;
    if(!IntersectsAABB(rayOrigin, rayDirection, CabinAABB))
    {
        intersectFlags |= SKIP_CABIN_INTERSECT_FLAG;
    }
    
    float maxSnowPlaneHeight = 0.00;
	if(rayOrigin.y > maxSnowPlaneHeight)
    {
		float t = (maxSnowPlaneHeight - rayOrigin.y) / rayDirection.y;
        if(t < 0.0 || t > SCENE_MAX_T)
        {
            intersectFlags |= SKIP_GROUND_PLANE_INTERSECT_FLAG;
        }
    }
    
    
    return intersectFlags;
}

void Intersect( in vec3 rayOrigin, in vec3 rayDirection, in float tmin, in int intersectFlags, out int materialID, out float t)
{
    intersectFlags |= CalculateOptimizedIntersectFlags(rayOrigin, rayDirection);
    float tmax = SCENE_MAX_T;
    
	float precis = 0.002;
    float precisPadPerDist = 0.0001;
    t = tmin;
    materialID = INVALID_MATERIAL_ID;
    int maxIteration = 75;
    int i;
    for( i=(min(iFrame,0)); i<maxIteration; i++ )
    {
	    vec2 res = QueryDistanceField( rayOrigin+rayDirection*t, intersectFlags);
        if( res.x< (precis + t * precisPadPerDist) || t>tmax ) break;
        t += res.x;
	    materialID = int(res.y);
    }

    if( t>tmax ) materialID = INVALID_MATERIAL_ID;
}

// Mostly taken from https://iquilezles.org/articles/rmshadows
float SoftShadowIntersect(in vec3 rayOrigin, in vec3 rayDirection, in float tmin, in float tmax, in int iterations, in float width)
{
    int rayIntersectFlags = CalculateOptimizedIntersectFlags(rayOrigin, rayDirection);
	float precis = 0.01;
    float t = tmin;
    float shadowFactor = 1.0;
    float ph = 1e20;
    int i;
    for( i=(min(iFrame,0)); i<iterations; i++ )
    {
	    vec2 res = QueryDistanceField( rayOrigin+rayDirection*t, SHADOW_INTERSECT_FLAG | rayIntersectFlags );
        if( res.x < precis || t>tmax )
        {
            int materialID = int(res.y);
            if(materialID == int(INVALID_MATERIAL_ID) || materialID == int(CABIN_LAMP_MATERIAL_ID))
            {
                break;
            }
            else
            {
                shadowFactor = 0.0;
            }
        }
        float y = res.x*res.x/(2.0*ph);
        float d = sqrt(res.x*res.x-y*y);
        shadowFactor = min( shadowFactor, width*d/max(0.0,t-y) );

        ph = res.x;
        t += res.x;
    }
    return shadowFactor;
}

// Taken from https://iquilezles.org/articles/normalsSDF
vec3 GetNormal( in vec3 pos )
{
    #define ZERO (min(iFrame,0))
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*QueryDistanceField(pos+0.005*e, DEFAULT_INTERSECT_FLAG).x;
    }
    return normalize(n);
}

vec3 Diffuse(in vec3 normal, in vec3 lightVec, in vec3 diffuse)
{
    float nDotL = dot(normal, lightVec);
    return clamp(nDotL * diffuse, 0.0, 1.0);
}

// Global Illumination is guestimated to just be the sky color reflected off the snow.
// A small hack is done if GI is being sampled by the cabin since the sky color would
// be blocked by the roof and the lamp color would be more relevant.
vec3 GetGlobalIllumination(in vec3 pos)
{
    float cabinDist = length(pos - CabinOrigin);
    float lampReachDist = 55.0;
    float lerpValue = min(cabinDist / lampReachDist, 1.0);
    vec3 cabinGIValue = vec3(0.05, 0.026, 0.0);

	return mix(cabinGIValue, AmbientSnowColor, lerpValue);
}

vec3 GetSkyColor(vec3 rayDirection)
{
    
    float p = atan(rayDirection.x, rayDirection.z);
    p = p > 0.0 ? p : p + 2.0 * PI;
    vec2 uv = vec2(p / (2.0 * PI), acos(rayDirection.y) / PI);

    float yCapValue = 0.05 + .01 * sin(uv.x + iTime * 0.1);
    float yLerpValue = min(rayDirection.y, yCapValue) / yCapValue;
    vec3 skyColor = 1.3 * mix(vec3(0.02, 0.26, 0.64), vec3(0.04, 0.04, 0.6), yLerpValue);

    vec3 cloudTexture = texture(iChannel1, uv + vec2(iTime * 0.001, 0.0)).bgr;
    skyColor = skyColor * cloudTexture;
    
    vec2 auroraCenter = vec2(0.525, 0.5);
    float distanceFromAuroraCeter = length(uv - auroraCenter);
    float ring1Start = 0.05;
    float ring1End = 0.1;
    float distanceFromAuroraCeter1 = distanceFromAuroraCeter + 
        0.003 * sin(uv.y * 100.0 + iTime * 1.1) +
        0.001 * noise(vec3(uv * 200.0, iTime * 1.1));
    
    float yDistFromCenter = abs(uv.y - auroraCenter.y); 

    if(distanceFromAuroraCeter1 > ring1Start && distanceFromAuroraCeter1 < ring1End)
    {
        float ring1Center = ring1Start * 0.75 + ring1End * 0.25;
        float ring1Length = (distanceFromAuroraCeter1 < ring1Center) ? 
            (ring1Center - ring1Start) : (ring1End - ring1Center);
        float multiplier = 1.0 - (abs(distanceFromAuroraCeter1 - ring1Center) / ring1Length); 
        multiplier = pow(multiplier, 2.0);
        float borealisLerpValue = noise(vec3(uv.x * 200.0, 0.0, 0.0));
        vec3 borealisColor = mix(vec3(0.0, 0.4, 0.15), vec3(0.0, 0.2, 0.02), borealisLerpValue);
        skyColor += multiplier * borealisColor;
    }
    
    float ring2Start = 0.07;
    float ring2End = 0.1;
    float distanceFromAuroraCeter2 = distanceFromAuroraCeter + 
        0.005 * sin(uv.y * 80.0 + iTime * 1.5) +
        0.003 * noise(vec3(uv * 200.0, iTime * 1.1));
    if(distanceFromAuroraCeter2 > ring2Start && distanceFromAuroraCeter2 < ring2End)
    {
        float ring2Center = ring2Start * 0.75 + ring2End * 0.25;
        float ring2Length = (distanceFromAuroraCeter2 < ring2Center) ? 
            (ring2Center - ring2Start) : (ring2End - ring2Center);
        float multiplier = 1.0 - (abs(distanceFromAuroraCeter2 - ring2Center) / ring2Length); 
        multiplier = pow(multiplier, 2.0);
        float borealisLerpValue = uv.y * noise(vec3(0.0, uv.x * 250.0, 0.0));
        vec3 borealisColor = mix(vec3(0.3, 0, 0.13), vec3(0.12, 0.0, 0.05), borealisLerpValue);
        skyColor += multiplier * borealisColor;
    }
    
    float ring3Start = 0.11;
    float ring3End = 0.16;
    float distanceFromAuroraCeter3 = distanceFromAuroraCeter + 
        0.004 * sin(uv.y * 120.0 + iTime * 0.9) +
        0.003 * noise(vec3(uv * 200.0, iTime));
    if(distanceFromAuroraCeter3 > ring3Start && distanceFromAuroraCeter3 < ring3End)
    {
        float ring3Center = ring3Start * 0.75 + ring3End * 0.25;
        float ring3Length = (distanceFromAuroraCeter3 < ring3Center) ? 
            (ring3Center - ring3Start) : (ring3End - ring3Center);
        float multiplier = 1.0 - (abs(distanceFromAuroraCeter3 - ring3Center) / ring3Length); 
        multiplier = pow(multiplier, 2.0);
        float borealisLerpValue = uv.y * noise(vec3(0.0, uv.x * 250.0, 0.0));
        vec3 borealisColor = mix(vec3(0.05, 0.25, 0.15), vec3(0.0, 0.1, 0.2), borealisLerpValue);
        skyColor += multiplier * borealisColor;
    }
    
    clamp(skyColor, 0.0, 1.0);
    return skyColor;
}

void CalculateLighting(vec3 position, vec3 normal, vec3 reflectionDirection, Material material, bool shootShadowRays, inout vec3 diffuseColor, inout vec3 specularColor)
{
    vec3 lightDirection = (CabinLamp.Position - position);
    float lightDistance = length(lightDirection);
    lightDirection /= lightDistance;

    // Manually tuned light falloff for what looked best
    vec3 lightColor = CabinLampMultiplier() * CabinLamp.LightColor / pow(lightDistance, 0.7); 

    float shadowFactor = 1.0;
    if(shootShadowRays && IsColorSignificant(lightColor))
    {
       shadowFactor = SoftShadowIntersect(position, lightDirection, 0.1, 200.0, 50, 64.0);
    }

    if(SupportsSpecularLight(material))
    {
        specularColor += shadowFactor * 0.25 * lightColor * pow(max(dot(reflectionDirection, lightDirection), 0.0), 4.0);
    }
    diffuseColor += shadowFactor * lightColor * Diffuse(normal, lightDirection, material.albedo);
    diffuseColor += material.emissive;
    
    for(int i = 0; i < NUM_POINT_LIGHTS; i++)
    {
        vec3 pointLightDirection = (Cabin.PointLights[i].Position - position);
        float pointLightDistance = length(pointLightDirection);
        pointLightDirection /= pointLightDistance;

        vec3 pointLightColor = Cabin.PointLights[i].LightColor / (pointLightDistance * pointLightDistance);

        if(SupportsSpecularLight(material))
        {
            specularColor += 0.25 * pointLightColor * pow(max(dot(reflectionDirection, pointLightDirection), 0.0), 4.0);
        }
        diffuseColor += pointLightColor * Diffuse(normal, pointLightDirection, material.albedo);
    }
    
    diffuseColor += GetGlobalIllumination(position);

    {
        float skyNDotL = normal.y;
        // Alter where the sky light is coming from just for snow to give the snow
        // a little more texture
        if(IsSnow(material))
        {
            skyNDotL = dot(normal, normalize(vec3(1, 1, 0.2)));
            diffuseColor += 
                mix(vec3(0.1, 0.2, 0.3), SKY_LIGHT_COLOR * material.albedo, pow(skyNDotL, 4.0));
        }
        else
        {
			diffuseColor += SKY_LIGHT_COLOR * skyNDotL * material.albedo;
        }
    }

    specularColor = clamp(specularColor, 0.0, 1.0);
    diffuseColor = clamp(diffuseColor, 0.0, 1.0);
}

void UpdateMaterial(int materialID, vec3 position, vec3 normal, bool showSnowOnDistantTrees, inout Material material)
{
    // Convert upwards facing leaf materials to snow to imitate snowfall
    if((materialID == int(LEAF_MATERIAL_ID) && (normal.y > 0.2)) ||
       (showSnowOnDistantTrees && materialID == int(DISTANT_TREE_MATERIAL_ID) && (normal.y > 0.2)))
    {
        material = GetMaterial(int(SNOW_MATERIAL_ID), position);
    }
}

void TraceRay( in vec3 rayOrigin, in vec3 rayDirection, out vec3 diffuseColor, out vec3 specularColor, out float depth, out int materialID)
{
    depth = SCENE_MAX_T;
    diffuseColor = specularColor = vec3(0.0);
    
    float t;
    materialID = INVALID_MATERIAL_ID;
    Intersect(rayOrigin, rayDirection, 0.1, DEFAULT_INTERSECT_FLAG, materialID, t);
    
    if( materialID != INVALID_MATERIAL_ID )
    {
        depth = t;
        vec3 position = rayOrigin + t*rayDirection;
        Material material = GetMaterial(materialID, position);
		if(IsLightSource(material))
        {
            diffuseColor = min(material.albedo, vec3(1.0));
            return;
        }       
        
        vec3 normal = GetNormal( position );
       	UpdateMaterial(materialID, position, normal, true, material);
        vec3 reflectionDirection = reflect( rayDirection, normal );
		
        CalculateLighting(position, normal, reflectionDirection, material, true, diffuseColor, specularColor);
    }
    else
    {
       diffuseColor = GetSkyColor(rayDirection);
    }
}

mat3 GetViewMatrix(float xRotationFactor)
{ 
   float xRotation = ((1.0 - xRotationFactor) - 0.5) * PI * 0.4 + PI * 0.25;
   return mat3( cos(xRotation), 0.0, sin(xRotation),
                0.0,           1.0, 0.0,    
                -sin(xRotation),0.0, cos(xRotation));
}

float GetCameraPositionYOffset()
{
    return 25.0 * (iMouse.y / iResolution.y);
}

float GetRotationFactor()
{
    if(iMouse.x <= 0.0)
    {
        // Default value when shader is initially loaded up
        return 0.65f;
    }
    
    return iMouse.x / iResolution.x;
}
 
vec3 AdjustColorForFog(vec3 color, float depth, float height)
{
	vec3 fogColor = AmbientSnowColor;
    float fogHeight = 60.0;

	vec3 lerpFogColor = mix( color, fogColor, 1.0-exp(-0.0045*depth) );
    return mix(lerpFogColor, color, min(max(height, 0.0), fogHeight) / fogHeight);
}
                          
void FogPass(in vec3 rayOrigin, in vec3 rayDirection, in float depth, inout vec3 diffuseColor, inout vec3 specularColor)
{
	vec3 position = rayOrigin + rayDirection * depth;

    depth -= 230.0;
    depth = max(0.0, depth);

    diffuseColor = AdjustColorForFog(diffuseColor, depth, position.y);
    specularColor = AdjustColorForFog(specularColor, depth, position.y);
}

void RenderIce(in vec3 rayOrigin, in vec3 rayDirection, in float depth, inout vec3 diffuseColor, inout vec3 specularColor, inout int materialID)
{
    float icePlaneHeight = -7.0;
    vec3 position = rayOrigin + rayDirection * depth;
    
    if(position.y <= icePlaneHeight)
    {
        float iceDepth = (icePlaneHeight - rayOrigin.y) / rayDirection.y;
		vec3 icePosition = rayOrigin + rayDirection * iceDepth;
        
        // Coat the ice with bits of snow
        bool isIce = noise(icePosition / 4.0) > -0.620;
        
        // Ice is a plane so normal is always up
        vec3 normal = vec3(0, 1, 0);
        Material material = GetMaterial(int(ICE_MATERIAL_ID), position);
        vec3 reflectionDirection = reflect( rayDirection, normal );
		if(isIce)
        {
            materialID = ICE_MATERIAL_ID;
            int reflectionMaterialID = INVALID_MATERIAL_ID;
            float reflectionDistance = 0.0;
            {
                // Hack the reflection angle slightly
                // for the sake of art
                {
                    reflectionDirection.y -= 0.02;
                    reflectionDirection = normalize(reflectionDirection);
                }

                Intersect(icePosition + EPSILON * reflectionDirection, reflectionDirection, 0.01, DEFAULT_INTERSECT_FLAG, reflectionMaterialID, reflectionDistance);
                if(reflectionMaterialID != INVALID_MATERIAL_ID)
                {

                    vec3 reflectionPosition = icePosition + reflectionDirection * reflectionDistance;
                    vec3 reflectionNormal = GetNormal(reflectionPosition);
                    Material material = GetMaterial(reflectionMaterialID, reflectionPosition);
                    UpdateMaterial(reflectionMaterialID, reflectionPosition, reflectionNormal, true, material);

                    if(IsLightSource(material))
                    {
                        diffuseColor = min(material.albedo, vec3(1.0));
                    }
                    else
                    {
                        // Best variable name ever
                        vec3 reflectionReflection = reflect(reflectionDirection, normal);

                    	vec3 reflDiffuse;
                    	CalculateLighting(reflectionPosition, reflectionNormal, reflectionReflection, material, true, diffuseColor, specularColor);
                    	FogPass(icePosition, reflectionDirection, reflectionDistance, diffuseColor, specularColor);
                    }
                }
                else
                {
                    specularColor += GetSkyColor(reflectionDirection);
                }
            }
            float icePenetrationDepth = depth - iceDepth;
            diffuseColor = mix(material.albedo * SKY_LIGHT_COLOR, diffuseColor, 1.0-exp(-0.01*icePenetrationDepth) );
        }
        else
        {
            specularColor = diffuseColor = vec3(0.0);
            CalculateLighting(icePosition, normal, reflectionDirection, GetMaterial(int(SNOW_MATERIAL_ID), icePosition), false, diffuseColor, specularColor);
        } 
    }
}
                          
void TransparencyPass(in vec3 rayOrigin, in vec3 rayDirection, in float depth, inout vec3 diffuseColor, inout vec3 specularColor, inout int materialID)
{
	RenderIce(rayOrigin, rayDirection, depth, diffuseColor, specularColor, materialID);
}
                
vec3 PostProcessSnow(vec2 uv, in vec3 rayOrigin, in vec3 rayDirection, inout float depth)
{
    float aspectRatio = iResolution.y / iResolution.x;
    uv.y *= aspectRatio; 
    
    
    // Close Snowflakes
    {
        vec2 closeSnowUV = uv;
        
        // Offsetting by the rotation gives a good enough
        // illusion of 3D snow
        closeSnowUV.x += -GetRotationFactor() * 3.0;
        closeSnowUV.y += iTime / 4.0;
        closeSnowUV = fract(closeSnowUV);

        // This is super lame but I'm tired
        // and it's good enough...
        #define NUM_SNOWFLAKES 10
        vec3 Snowflakes[NUM_SNOWFLAKES];
        Snowflakes[0] = vec3(0.1, 0.7, 100.0);
        Snowflakes[1] = vec3(0.3, 0.3, 200.0);
        Snowflakes[2] = vec3(0.5, 0.5, 150.0);
        Snowflakes[3] = vec3(0.2, 0.73, 50.0);
        Snowflakes[4] = vec3(0.54, 0.94, 88.0);
        Snowflakes[5] = vec3(0.99, 0.34, 295.0);
        Snowflakes[6] = vec3(0.07, 0.28, 196.0);
        Snowflakes[7] = vec3(0.11, 0.32, 161.0);
        Snowflakes[8] = vec3(0.88, 0.9, 254.0);
        Snowflakes[9] = vec3(0.63, 0.01, 17.0);
            
        for(int i = 0; i < NUM_SNOWFLAKES; i++)
        {
            float uvDist = length(Snowflakes[i].xy - closeSnowUV);
            float snowDepth = Snowflakes[i].z;
            if(snowDepth < depth)
            {
                float radius = 0.008 * (1.0 - snowDepth / 300.0);
                if(uvDist < radius)
                {
                    vec3 diffuse = vec3(0.5) * (1.0 - (uvDist / radius));
                    vec3 specular = vec3(0.0);
                    FogPass(rayOrigin, rayDirection, snowDepth, diffuse, specular);
                    return diffuse;
                }
            }
        }
    }
    
    // Distance Snowflakes
    {
        // Offsetting by the rotation gives a good enough
        // illusion of 3D snow
        uv.x += -GetRotationFactor() * 2.0;

        uv.y += iTime / 10.0;
        vec4 noiseValue = texture(iChannel3, uv);
        float snowValue = noiseValue.r;
        float snowDepth = 300.0;//noiseValue.r * SCENE_MAX_T;
        if( (snowDepth < depth && snowValue > 0.95) )
        {
            vec3 diffuse = vec3(0.5);
            vec3 specular = vec3(0.0);
            FogPass(rayOrigin, rayDirection, snowDepth, diffuse, specular);
            return diffuse;
        }

    }
    return vec3(0.0);
}
                              
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    
    float aspectRatio = iResolution.x /  iResolution.y; 
    float lensWidth = Camera.LensHeight * aspectRatio;
    
    vec3 CameraPosition = Camera.Position + GetCameraPositionYOffset();
    
    vec3 NonNormalizedCameraView = Camera.LookAt - CameraPosition;
    float ViewLength = length(NonNormalizedCameraView);
    vec3 CameraView = NonNormalizedCameraView / ViewLength;

    vec3 lensPoint = CameraPosition;
    
    // Pivot the camera around the look at point
    {
        float rotationFactor = GetRotationFactor();
        mat3 viewMatrix = GetViewMatrix(rotationFactor);
        CameraView = CameraView * viewMatrix;
        lensPoint = Camera.LookAt - CameraView * ViewLength;
    }
    
    // Technically this could be calculated offline but I like 
    // being able to iterate quickly
    vec3 CameraRight = cross(CameraView, vec3(0, 1, 0));    
    vec3 CameraUp = cross(CameraRight, CameraView);

    vec3 focalPoint = lensPoint - Camera.FocalDistance * CameraView;
    lensPoint += CameraRight * (uv.x * 2.0 - 1.0) * lensWidth / 2.0;
    lensPoint += CameraUp * (uv.y * 2.0 - 1.0) * Camera.LensHeight / 2.0;
    
    vec3 rayOrigin = focalPoint;
    vec3 rayDirection = normalize(lensPoint - focalPoint);
    
    float depth = 0.0;
    vec3 diffuseColor, specularColor;
    int materialID;
    TraceRay( rayOrigin, rayDirection, diffuseColor, specularColor, depth, materialID);
    
    TransparencyPass(rayOrigin, rayDirection, depth, diffuseColor, specularColor, materialID);
    FogPass(rayOrigin, rayDirection, depth, diffuseColor, specularColor);    

    specularColor += PostProcessSnow(uv, rayOrigin, rayDirection, depth);
    
    specularColor = clamp(specularColor, 0.0, 1.0);
    diffuseColor = clamp(diffuseColor, 0.0, 1.0);
    
    // intBitsToFloat seems to have some issues with ShaderToy so compressing 
    // diffuse + specular in this lame way
    specularColor = specularColor * 1000.0f;
    specularColor -= fract(specularColor);
    vec3 color = specularColor + diffuseColor;
    depth = fract(depth / SCENE_MAX_T);
    depth += float(materialID);
    
    fragColor=vec4( color, depth );
}