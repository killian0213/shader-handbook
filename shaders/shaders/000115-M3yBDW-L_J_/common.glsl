// Common (common) — Lā Jī by SL0ANE
// https://www.shadertoy.com/view/M3yBDW

// 宏
// # define MODELING


// 常数
# define MAX_DISTANCE 32.0
# define MAX_STEP 128

# define PI 3.1415926535897932384626433832795


// 输入缓冲

# define POINTER_ROT ivec2(0, 1)
# define POINTER_TIME ivec2(0, 2)
# define POINTER_PRESS ivec2(0, 3)
# define POINTER_MOUSE ivec2(0, 4)
# define POINTER_RESETCAM ivec2(0, 5)

# define store(P, V) if (all(equal(ivec2(fragCoord), P))) fragColor = V
# define load(P) texelFetch(iChannel2, ivec2(P), 0)

# define keyToggle(ascii)  ( texelFetch(iChannel3,ivec2(ascii,2),0).x > 0.)
# define keyClick(ascii)   ( texelFetch(iChannel3,ivec2(ascii,1),0).x > 0.)
# define keyDown(ascii)    ( texelFetch(iChannel3,ivec2(ascii,0),0).x > 0.)


// 物体材质的部分

struct Material
{
    vec4 color0;   // albedo
    vec4 color1;   // specular
    vec4 color2;   // rimlight
    vec4 color3;   // emissive
    int index;    // 着色类型
}; 

struct ObjectInfo
{
	float dis;
    Material material;
};

ObjectInfo objectMin(ObjectInfo a, ObjectInfo b)
{
    if(a.dis < b.dis ) return a;
    else return b;
}

Material objectMix(Material a, Material b, float k)
{
    Material outMat = a;
    outMat.color0 = mix(a.color0, b.color0, k);
    outMat.color1 = mix(a.color1, b.color1, k);
    outMat.color2 = mix(a.color2, b.color2, k);
    outMat.color2 = mix(a.color3, b.color3, k);
    
    return outMat;
}

ObjectInfo objectSmoothMin(ObjectInfo a, ObjectInfo b, float k)
{
    float h = max(k - abs(a.dis - b.dis), 0.0);
    ObjectInfo outInfo = a;
    float rate;
    if(a.dis < b.dis) rate = a.dis / b.dis * 0.5;
    else rate = 1.0 - b.dis / a.dis * 0.5;
    outInfo.material = objectMix(a.material, b.material, rate);
    outInfo.dis = min(a.dis, b.dis) - h * h * 0.25 / k;
    
    return outInfo;
}

ObjectInfo objectSmoothMinWithoutBlend(ObjectInfo a, ObjectInfo b, float k)
{
    float h = max(k - abs(a.dis - b.dis), 0.0);
    ObjectInfo outInfo = a;
    if(a.dis < b.dis) outInfo.material = a.material;
    else outInfo.material = b.material;
    
    outInfo.dis = min(a.dis, b.dis) - h * h * 0.25 / k;
    return outInfo;
}


// SDF运算

float sint( float d1, float d2, float k )
{
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h);
}

float smin(float a, float b, float k)
{
    float h = max(k - abs(a - b), 0.0);
    return min(a, b) - h * h * 0.25 / k;
}

float ssub(float a, float b, float k)
{
    float h = clamp( 0.5 - 0.5 * (b + a) / k, 0.0, 1.0 );
    return mix(a, -b, h) + k * h * (1.0 - h);
}

float xor( float a, float b )
{
    return max( min(a,b), -max(a,b) );
}

float sub(float d1, float d2)
{
    return max(d1, -d2);
}


// 随机数


// 噪声


// 2D图形SDF

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sdQuadraticCircle( in vec2 p )
{
    p = abs(p); if( p.y>p.x ) p=p.yx;

    float a = p.x-p.y;
    float b = p.x+p.y;
    float c = (2.0*b-1.0)/3.0;
    float h = a*a + c*c*c;
    float t;
    if( h>=0.0 )
    {   
        h = sqrt(h);
        t = sign(h-a)*pow(abs(h-a),1.0/3.0) - pow(h+a,1.0/3.0);
    }
    else
    {   
        float z = sqrt(-c);
        float v = acos(a/(c*z))/3.0;
        t = -z*(cos(v)+sin(v)*1.732050808);
    }
    t *= 0.5;
    vec2 w = vec2(-t,t) + 0.75 - t*t - p;
    return length(w) * sign( a*a*0.5+b-1.5 );
}


// 3D图形SDF

float sdSphere(vec3 p, float sdf_rad)
{
    return distance(p, vec3(0)) - sdf_rad;
}

float sdCapsule( vec3 p, vec3 sdf_pos_0, vec3 sdf_pos_1, float sdf_rad)
{
    vec3 pa = p - sdf_pos_0, ba = sdf_pos_1 - sdf_pos_0;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - sdf_rad;
}

float dot2( in vec3 v ) { return dot(v,v); }
float cos_acos_3( in float x )
{
	x = sqrt(0.5+0.5*x);
    return x*(x*(x*(x*-0.008972+0.039071)-0.107074)+0.576975)+0.5; 
}
vec2 sdBezier(vec3 pos, vec3 A, vec3 B, vec3 C)
{    
    vec3 a = B - A;
    vec3 b = A - 2.0*B + C;
    vec3 c = a * 2.0;
    vec3 d = A - pos;

    float kk = 1.0 / dot(b,b);
    float kx = kk * dot(a,b);
    float ky = kk * (2.0*dot(a,a)+dot(d,b)) / 3.0;
    float kz = kk * dot(d,a);      

    vec2 res;

    float p = ky - kx*kx;
    float p3 = p*p*p;
    float q = kx*(2.0*kx*kx - 3.0*ky) + kz;
    float q2 = q*q;
    float h = q2 + 4.0*p3;

    if(h >= 0.0) 
    { 
        h = sqrt(h);
        vec2 x = (vec2(h,-h)-q)/2.0;
        
        vec2 uv = sign(x)*pow(abs(x), vec2(1.0/3.0));
        float t = clamp(uv.x+uv.y-kx, 0.0, 1.0);

        res = vec2(dot2(d+(c+b*t)*t),t);
    }
    else
    {
        float z = sqrt(-p);
        #if 0
        float v = acos( q/(p*z*2.0) ) / 3.0;
        float m = cos(v);
        float n = sin(v)*1.732050808;
        #else
        float m = cos_acos_3( q/(p*z*2.0) );
        float n = sqrt(1.0-m*m)*1.732050808;
        #endif
        vec3 t = clamp( vec3(m+m,-n-m,n-m)*z-kx, 0.0, 1.0);

        float dis = dot2(d+(c+b*t.x)*t.x);
        res = vec2(dis,t.x);

        dis = dot2(d+(c+b*t.y)*t.y);
        if( dis<res.x ) res = vec2(dis,t.y );
    }
    
    res.x = sqrt(res.x);
    return res;
}

float sdHalfTorus(vec3 p, float r, float r0, float r1)
{
    vec2 sc = vec2(1.0, 0.0);
    float side = sign(p.z);
    p.y = -p.y;
    
    float disToDot0 = dot(vec2(p.z, p.y), sc);
    float disToDot1 = dot(vec2(-p.z, p.y), sc);
    float disToRing = length(p.zy);
    
    disToDot0 = sqrt(dot(p,p) + r * r - 2.0 * r * disToDot0);
    disToDot1 = sqrt(dot(p,p) + r * r - 2.0 * r * disToDot1);
    disToRing = sqrt(dot(p,p) + r * r - 2.0 * r * disToRing);
    
    bool onEdge = sc.y * p.z > sc.x * p.y;
    
    float t = -side * (onEdge ? 1.0 : abs(p.z) / sqrt(dot(p.zy, p.zy)));
    t = t * 0.5 + 0.5;
    
    float base = min(disToDot0 - r0, disToDot1 - r1);
    disToRing = onEdge ? base : disToRing;
    
    if(onEdge)
    {
        return base;
    }
    
    return min(base, disToRing - mix(r0, r1, t));
}

float sdBox( vec3 p, vec3 b )
{
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdCutHollowSphere(vec3 p, vec3 dir, float r, float h, float t)
{
    float y = dot(dir, p);
    float x = length(p - y * dir);
    
    vec2 q = vec2(x, y);
    
    float w = sqrt(r*r-h*h);
    
    return ((h*q.x<w*q.y) ? length(q-vec2(w,h)) : 
                            abs(length(q)-r) ) - t;
}

float sdEllipsoid( vec3 p, vec3 r )
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

float sdVesicaSegment( in vec3 p, in vec3 a, in vec3 b, in float w )
{
    vec3  c = (a+b)*0.5;
    float l = length(b-a);
    vec3  v = (b-a)/l;
    float y = dot(p-c,v);
    vec2  q = vec2(length(p-c-y*v),abs(y));
    
    float r = 0.5*l;
    float d = 0.5*(r*r-w*w)/w;
    vec3  h = (r*q.x<d*(q.y-r)) ? vec3(0.0,r,0.0) : vec3(-d,0.0,d+w);
 
    return length(q-h.xy) - h.z;
}

// 分级

float multistep(float val, float level)
{
    level = level - 1.0;
    
    val *= level;
    float aaf = fwidth(val);
    val = aaf > 0.1 * level ? round(val) : mix(floor(val), ceil(val), smoothstep(floor(val) + 0.5, floor(val) + 0.5 + aaf, val));
    
    return val / level;
}


// 四元数相关

float cro( in vec2 a, in vec2 b ) { return a.x*b.y - a.y*b.x; }

vec4 conjugate(vec4 q) {
    return vec4(-q.x, -q.y, -q.z, q.w);
}

vec4 quaternionInverse(vec4 q) {
    return conjugate(q) / dot(q, q);
}

vec4 quaternionMul(vec4 left, vec4 right)
{
    float w = left.w*right.w - left.x*right.x - left.y*right.y - left.z * right.z;
    float x = left.w*right.x + left.x*right.w + left.z*right.y - left.y * right.z;
    float y = left.w*right.y + left.y*right.w + left.x*right.z - left.z * right.x;
    float z = left.w*right.z + left.z*right.w + left.y*right.x - left.x * right.y;
    
    return vec4(x, y, z, w);
}

vec4 quaternionLerp(vec4 starting, vec4 ending, float t)
{
    float cosa = starting.x *ending.x + starting.y * ending.y + starting.z *ending.z  + starting.w * ending.w;
    
    if (cosa < 0.0) 
    {
        ending.x = -ending.x;
        ending.y = -ending.y;
        ending.z = -ending.z;
        ending.w = -ending.w;
        cosa = -cosa;
    }
    
    float k0, k1;
    
    if (cosa > 0.9995f) 
    {
        k0 = 1.0 - t;
        k1 = t;
    }
    else 
    {
        float sina = sqrt(1.0 - cosa * cosa);
        float a = atan(sina, cosa);
        k0 = sin((1.0 - t) * a) / sina;
        k1 = sin(t * a) / sina;
    }
    
    vec4 result;
    
    result.x = starting.x * k0 + ending.x * k1;
    result.y = starting.y * k0 + ending.y * k1;
    result.z = starting.z * k0 + ending.z * k1;
    result.w = starting.w * k0 + ending.w * k1;
    
    return result;
}

vec3 rotatePoint(vec3 p, vec3 center, vec4 q) {
    vec4 pQuaternion = vec4(p - center, 0.0);

    vec4 rotatedP = quaternionMul(quaternionMul(q , pQuaternion), conjugate(q));
    vec3 rotatedPoint = rotatedP.xyz;
    
    rotatedPoint += center;
    
    return rotatedPoint;
}

mat4 createModelMat(vec4 q, vec3 offset)
{
    float qx2 = q.x * q.x;
    float qy2 = q.y * q.y;
    float qz2 = q.z * q.z;

    float qxqy = q.x * q.y;
    float qxqz = q.x * q.z;
    float qxqw = q.x * q.w;
    float qyqz = q.y * q.z;
    float qyqw = q.y * q.w;
    float qzqw = q.z * q.w;
    
    return mat4(1.0 - 2.0 * (qy2 + qz2), 2.0 * (qxqy - qzqw),     2.0 * (qxqz + qyqw),     0.0,
                2.0 * (qxqy + qzqw),     1.0 - 2.0 * (qx2 + qz2), 2.0 * (qyqz - qxqw),     0.0,
                2.0 * (qxqz - qyqw),     2.0 * (qyqz + qxqw),     1.0 - 2.0 * (qx2 + qy2), 0.0,
                offset.x,                offset.y,                offset.z,                1.0);
}

mat4 createModelInverseMat(vec4 q, vec3 offset)
{
    return createModelMat(quaternionInverse(q), vec3(0.0)) * mat4(1.0,       0.0,       0.0,       0.0,
                0.0,       1.0,       0.0,       0.0,
                0.0,       0.0,       1.0,       0.0,
                -offset.x, -offset.y, -offset.z, 1.0);
}


// 场景

#define SCENE_SETUP
#define DEFAULT_ROT vec4(0.0177416, 0.912676, -0.0398483, 0.4063495)
float cameraDistance = 16.0f;
float cameraFov = 36.0f;
mat4 cameraTransform = mat4(
    1.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
    0.0, 0.0, -10.0, 1.0
);

void getCameraParam(vec2 fragCoord, vec2 resolution, inout vec3 ray, inout vec3 front, inout vec3 start, inout float pixelSize)
{
    vec2 uv = (fragCoord.xy - resolution.xy / 2.0) / resolution.x;
    float tanFov = tan(cameraFov / 360.0 * PI);
    
    #ifdef MODELING
    if(uv.x < 0.0) ray = normalize(vec3(uv + vec2(0.25, 0.0), 0.5 / tanFov));
    else ray = normalize(vec3(uv - vec2(0.25, 0.0), 0.5 / tanFov));
    #else
    ray = normalize(vec3(uv, 0.5 / tanFov));
    #endif
    ray = (cameraTransform * vec4(ray, 0.0)).xyz;
    front = (cameraTransform * vec4(vec3(0.0, 0.0, 1.0), 0.0)).xyz;
    start = (cameraTransform * vec4(vec3(0.0), 1.0)).xyz;
    pixelSize = 2.0 * tanFov / resolution.x;
}

float outlineStrength = 3.0 / 1024.0;

struct ChickenInfo
{
    float boneBeakOpen;
    float boneWingSpread;
    float boneSpringSpin;
    float boneWalk;
}; 

const float bodyAng = 8.0 / 180.0 * PI;
const mat4 bodyTransformInv =
inverse(mat4(
    1.0, 0.0, 0.0, 0.0,
    0.0, cos(bodyAng), -sin(bodyAng), 0.0,
    0.0, sin(bodyAng), cos(bodyAng), 0.0,
    0.0, 0.25, 0.0, 1.0
));
float sdBody(vec3 pos)
{
    float res;
    float sdMainPart = sdHalfTorus((bodyTransformInv * vec4(pos, 1.0)).xyz, 1.0, 0.9, 0.85);  
    res = sdMainPart;
    return res;
}

const vec3 beakDirClose = vec3(0.0, -1.0, 0.0);
const vec3 beakDirOpen = normalize(vec3(0.0, -1.0, 1.25));
float sdBeak(vec3 pos, float boneBeakOpen)
{
    #define BEAK_OFFSET vec3(0.0, 0.13, 1.9);
    
    pos -= BEAK_OFFSET;
    float res;
    float beakOpenFactor = mix(0.0, 0.08, boneBeakOpen);
    
    pos.y = abs(pos.y) - (beakOpenFactor + 0.094);
    float sdBeak = sdCutHollowSphere(pos, normalize(mix(beakDirClose, beakDirOpen, boneBeakOpen)), 0.22, 0.05, 0.02);
    
    // float sdBeak = sdCapsule(pos, vec3(0.0, 0.12 + beakOpenFactor, 0.0), vec3(0.0, -0.12 - beakOpenFactor, -0.02), 0.25);
    // sdBeak = abs(sdBeak) - 0.01;
    // sdBeak = ssub(sdBeak, sdBox(pos, vec3(1.0, 0.01 + beakOpenFactor, 1.0)), 0.1);
    
    res = sdBeak;
    
    return res;
}

float sdScomb(vec3 pos)
{
    #define SCOMB_OFFSET vec3(0.0, 0.77, 1.0)
    #define SCOMB_START -0.75
    #define SCOMB_COUNT 3
    #define SCOMB_STEP 0.8
    #define SCOMB_LENGTH  0.7
    #define SCOMB_SIZE vec3(0.24, 0.36, 0.32)
    
    float res;
    pos -= SCOMB_OFFSET;
    
    float sdScomb = 65535.0;
    float ang = SCOMB_START;
    
    for(int i = 0; i < SCOMB_COUNT; i++)
    {
        vec3 segPos = vec3(0.0, cos(ang), sin(ang)) * SCOMB_LENGTH;
        sdScomb = smin(sdScomb, sdEllipsoid(pos - segPos, SCOMB_SIZE), 0.03);
        ang += SCOMB_STEP;
    }
    
    res = sdScomb;
    
    return res;
}

const vec3 wingRightClose = normalize(vec3(0.0, -1.0, 0.3));
const vec3 wingRightOpen = normalize(vec3(0.0, 0.875, 1.0));
const vec3 wingFrontClose = normalize(vec3(0.3, -0.3, -1.0));
const vec3 wingFrontOpen = vec3(1.0, 0.0, 0.0);

float sdWing(vec3 pos, float boneWingSpread)
{
    float res;
    pos.x = abs(pos.x);
    
    // boneWingSpread = sin(iTime) * 0.5 + 0.5;
    
    #define WING_OFFSET_CLOSE vec3(0.72, -0.35, 0.3)
    #define WING_OFFSET_OPEN vec3(0.64, -0.15, 0.0)
    #define WING_THICKNESS_CLOSE 0.15
    #define WING_THICKNESS_OPEN 0.1
    #define WING_SEG_COUNT 3
    #define WING_START_ANGLE 0.0
    #define WING_START_OFFSET 0.0
    #define WING_STEP_ANGLE_CLOSE 0.3
    #define WING_STEP_ANGLE_OPEN 0.2
    #define WING_STEP_OFFSET_CLOSE 0.0
    #define WING_STEP_OFFSET_OPEN 0.2
    #define WING_START_LENGTH_CLOSE 1.0
    #define WING_START_LENGTH_OPEN 1.8
    #define WING_LENGTH_FACTOR_CLOSE 1.12
    #define WING_LENGTH_FACTOR_OPEN 0.72
    #define WING_START_WIDTH_CLOSE 0.15
    #define WING_START_WIDTH_OPEN 0.2
    #define WING_WIDTH_FACTOR_CLOSE 1.0
    #define WING_WIDTH_FACTOR_OPEN 0.8
    
    pos -= mix(WING_OFFSET_CLOSE, WING_OFFSET_OPEN, boneWingSpread);
    
    float testDis = length(pos);
    
    vec3 wingRight = mix(wingRightClose, wingRightOpen, boneWingSpread);
    vec3 wingFront = mix(wingFrontClose, wingFrontOpen, boneWingSpread);
    wingFront -= dot(wingRight, wingFront) * wingRight;
    wingFront = normalize(wingFront);
    vec3 wingUp = cross(wingRight, wingFront);
    
    float sdWing = 65535.0;
    float wingLength = mix(WING_START_LENGTH_CLOSE, WING_START_LENGTH_OPEN, boneWingSpread);
    float wingLengthFactor = mix(WING_LENGTH_FACTOR_CLOSE, WING_LENGTH_FACTOR_OPEN, boneWingSpread);
    float wingAngle = WING_START_ANGLE;
    vec3 wingOffset = WING_START_OFFSET * -wingRight;
    float wingStepAngle = mix(WING_STEP_ANGLE_CLOSE, WING_STEP_ANGLE_OPEN, boneWingSpread);
    float wingStepOffset = mix(WING_STEP_OFFSET_CLOSE, WING_STEP_OFFSET_OPEN, boneWingSpread);
    float wingThickness = mix(WING_THICKNESS_CLOSE, WING_THICKNESS_OPEN, boneWingSpread);
    float wingWidth = mix(WING_START_WIDTH_CLOSE, WING_START_WIDTH_OPEN, boneWingSpread);
    float wingWidthFactor = mix(WING_WIDTH_FACTOR_CLOSE, WING_WIDTH_FACTOR_OPEN, boneWingSpread);
    
    for(int i = 0; i < WING_SEG_COUNT; i++)
    {
        vec3 segFront = cos(wingAngle) * wingFront - sin(wingAngle) * wingRight;
        sdWing = smin(sdWing, sdVesicaSegment(pos - wingOffset, vec3(0.0, 0.0, 0.0), segFront * wingLength, wingWidth) - wingThickness, 0.1);
        wingLength *= wingLengthFactor;
        wingOffset += wingStepOffset * -wingRight;
        wingAngle += wingStepAngle;
        wingWidth *= wingWidthFactor;
    }
    
    res = sdWing;
    
    return res;
}

#define SPRING_OFFSET vec3(0.0, 0.85, -1.0)
vec3 getSpringPos(vec3 pos, float boneSpringSpin)
{
    boneSpringSpin *= 2.0 * PI;
    pos -= SPRING_OFFSET;
    
    vec3 posRight = vec3(cos(boneSpringSpin), 0.0, sin(boneSpringSpin));
    vec3 posFront = vec3(-sin(boneSpringSpin), 0.0, cos(boneSpringSpin));
    pos = pos.x * posRight + pos.z * posFront + vec3(0.0, pos.y, 0.0);
    
    return pos;
}

float sdSpring(vec3 pos, float boneSpringSpin)
{
    float res;
    
    vec3 basePos = pos - SPRING_OFFSET - vec3(0.0, 0.1, 0.0);
    float sdBase = length(basePos.xz) - 0.2;
    vec2 sdExtend = vec2(sdBase, abs(basePos.y) - 0.12);
    sdBase = min(max(sdExtend.x, sdExtend.y), 0.0) + length(max(sdExtend, 0.0)) - 0.05;
    
    pos = getSpringPos(pos, boneSpringSpin);
    
    vec3 stickPos = pos - vec3(0.0, 0.5, 0.0);
    float sdStick = length(stickPos.xz) - 0.1;
    sdExtend = vec2(sdStick, abs(stickPos.y) - 0.25);
    sdStick = min(max(sdExtend.x, sdExtend.y), 0.0) + length(max(sdExtend, 0.0));
    
    pos.z = abs(pos.z);
    
    vec3 tiePos = pos - vec3(0.0, 0.9, 0.0);
    float sdTie = length(tiePos.xz) - 0.1;
    sdExtend = vec2(sdTie, abs(tiePos.y) - 0.15);
    sdTie = min(max(sdExtend.x, sdExtend.y), 0.0) + length(max(sdExtend, 0.0)) - 0.05;
    
    vec3 ringPos = tiePos - vec3(0.0, 0.0, 0.42);
    float sdRing = abs(length(ringPos.yz) - 0.2) - 0.04;
    sdExtend = vec2(sdRing, abs(ringPos.x) - 0.1);
    sdRing = min(max(sdExtend.x, sdExtend.y), 0.0) + length(max(sdExtend, 0.0)) - 0.05;
    
    res = min(sdBase, sdStick);
    res = min(res, sdTie);
    res = min(res, sdRing);
    return res;
}

float sdFoot(vec3 pos, float boneWalk)
{
    #define FOOT_OFFSET vec3(0.0, -1.15, -0.0)
    #define FOOT_CENTER vec3(0.0, 0.9, 0.0)
    #define FOOT_RADIUS 0.95
    #define FOOT_LENGTH 0.5
    #define FOOT_WIDTH 0.1
    #define FOOT_ANGLE 0.3
    #define FOOT_THICKNESS 0.1
    #define FOOT_DIS 0.25
    
    boneWalk *= PI;
    
    pos -= FOOT_OFFSET;
    
    float footAngle = cos(boneWalk) * FOOT_ANGLE;
    vec3 footDir = vec3(0.0, -cos(footAngle), sin(footAngle));
    vec3 footStartPos = FOOT_CENTER + footDir * FOOT_RADIUS + vec3(FOOT_DIS, 0.0, 0.0);
    vec3 footEndPos = FOOT_CENTER + footDir * (FOOT_RADIUS + FOOT_LENGTH) + vec3(FOOT_DIS, 0.0, 0.0);
    
    vec3 mirrorVector = normalize(vec3(footStartPos.x, 0.0, footStartPos.z));
    float mirrorFactor = dot(mirrorVector, pos);
    if(mirrorFactor < 0.0) pos -= 2.0 * mirrorFactor * mirrorVector;
    
    float sdFoot = sdVesicaSegment(pos, footStartPos, footEndPos, FOOT_WIDTH) - FOOT_THICKNESS;
    
    return sdFoot;
}

#define PERIOD 4.0
#define TRANSITION_TIME 0.5
#define WALK_SPEED 1.2
#define RUN_SPEED 2.5

float animTime = 0.0;
float transitionValue = 1.0;
float integrateTimeSpeed(float time) {
    float cycleTime = mod(time, PERIOD);
    float n = floor(time / PERIOD);
    
    float halfPeriod = PERIOD / 2.0;
    float pot = PI / TRANSITION_TIME;
    float diff = RUN_SPEED - WALK_SPEED;

    float S1 = (WALK_SPEED * TRANSITION_TIME) + (0.5 * diff * (TRANSITION_TIME - sin(pot * TRANSITION_TIME) / pot));
    float S2 = RUN_SPEED * (halfPeriod - TRANSITION_TIME);
    float S3 = (WALK_SPEED * TRANSITION_TIME) + (0.5 * diff * (TRANSITION_TIME + sin(pot * TRANSITION_TIME) / pot));
    float S4 = WALK_SPEED * (halfPeriod - TRANSITION_TIME);
    
    float S_full = S1 + S2 + S3 + S4;

    float S_remain = 0.0;
    
    if (cycleTime < TRANSITION_TIME) {
        S_remain = (WALK_SPEED * cycleTime) + (0.5 * diff * (cycleTime - sin(pot * cycleTime) / pot));
    } 
    else if (cycleTime < halfPeriod) {
        S_remain = S1 + RUN_SPEED * (cycleTime - TRANSITION_TIME);
    } 
    else if (cycleTime < (halfPeriod + TRANSITION_TIME)) {
        float t = cycleTime - halfPeriod;
        S_remain = S1 + S2 + (WALK_SPEED * t) + (0.5 * diff * (t + sin(pot * t) / pot));
    } 
    else {
        S_remain = S1 + S2 + S3 + WALK_SPEED * (cycleTime - halfPeriod - TRANSITION_TIME);
    }

    return n * S_full + S_remain;
}

void updateTime(float time)
{
    time += PERIOD * 0.5 + TRANSITION_TIME;
    float cycleTime = mod(time, PERIOD);
    
    if (cycleTime < TRANSITION_TIME) {
        // 从 0 过渡到 1
        transitionValue = 0.5 * (1.0 - cos(PI * cycleTime / TRANSITION_TIME));
    } else if (cycleTime < (PERIOD / 2.0)) {
        // 保持在 1
        transitionValue = 1.0;
    } else if (cycleTime < (PERIOD / 2.0 + TRANSITION_TIME)) {
        // 从 1 过渡到 0
        transitionValue = 0.5 * (1.0 + cos(PI * (cycleTime - PERIOD / 2.0) / TRANSITION_TIME));
    } else {
        // 保持在 0
        transitionValue = 0.0;
    }
    
    animTime = integrateTimeSpeed(time);
}

ChickenInfo getChickenInfo(inout vec3 pos, float time)
{
    float boneWalk = fract(animTime) * 2.0 - 1.0;

    ChickenInfo info = ChickenInfo(
        0.0,
        transitionValue, // 使用周期函数控制第二个参数
        fract(animTime * 1.2),
        boneWalk
    );
    
    float posFactor = info.boneWalk * PI;
    pos -= vec3(0.0, 0.36 * abs(cos(posFactor)), 0.0);
    vec3 frontDir = normalize(mix(vec3(0.0, 0.0, 1.0), vec3(0.0, 0.2, 1.0), transitionValue));
    vec3 upDir = vec3(0.08 * cos(-posFactor), 1.0, 0.0);
    upDir = upDir - dot(upDir, frontDir) * frontDir;
    vec3 rightDir = normalize(cross(upDir, frontDir));
    pos = pos.x * rightDir + pos.y * upDir + pos.z * frontDir;
     
    return info;
}

float sdChicken(vec3 pos, float time)
{
    ChickenInfo info = getChickenInfo(pos, time);
    
    float sdBody = sdBody(pos);
    float sdBeak = sdBeak(pos, info.boneBeakOpen);
    float sdScomb = sdScomb(pos);
    float sdWing = sdWing(pos, info.boneWingSpread);
    float sdSpring = sdSpring(pos, info.boneSpringSpin);
    float sdFoot = sdFoot(pos, info.boneWalk);
    float res = sdBody;
    res = min(res, sdBeak);
    res = min(res, sdScomb);
    res = min(res, sdWing);
    res = min(res, sdSpring);
    res = min(res, sdFoot);
    return res;
}

float sdFloor(vec3 pos)
{
    return pos.y + 1.9;
}

float sceneMap(vec3 pos, float time)
{
    float sdChicken = sdChicken(pos, time);
    float sdFloor = sdFloor(pos);
    return min(sdFloor, sdChicken);
}