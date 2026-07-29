// Common (common) — Alice by SL0ANE
// https://www.shadertoy.com/view/4fjSDy

# define PI 3.1415926535897932384626433832795
# define TOLERANCE 0.0001

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

# define QUA_ZERO vec4(0.0, 0.0, 0.0, 1.0)
// Structure
struct Material
{
    vec4 color0;
    vec4 color1;
    vec4 color2;
    vec3 vect0;
    vec3 vect1;
    vec3 vect2;
    // #0: smoothness, fresnelPower, fresnelScale
	float t0;
    float t1;
    float t2;
    float t3;
    float t4;
    int index;
};

struct ObjectInfo
{
	float dis;
    Material material;
};

// Util
vec3 applyTransform(vec3 origin, vec3 trans_x, vec3 trans_y, vec3 trans_z)
{
    return origin.x * trans_x + origin.y * trans_y + origin.z * trans_z;
}

float multiStep(float value, float level, float minValue, float offset)
{
    if(level <= 1.0) return 1.0;
    
    float curLevel = value * level;
    float curOffset = floor(curLevel) / (level - 1.0);
    curLevel = curLevel + mix(offset, 0.0, curOffset);
    float curLevelCache = curLevel;
    float downLevel = round(curLevel - 1.0);
    float upLevel = downLevel + 1.0;
    
    float curLevelFirst = curLevel - downLevel;
    float aaf = fwidth(curLevelFirst);
    
    curLevelFirst = downLevel >= 0.0 ? mix(downLevel, upLevel, smoothstep(1.0 - aaf, 1.0, curLevelFirst)) : upLevel;
    
    downLevel = floor(curLevel);
    upLevel = downLevel + 1.0;
    
    float curLevelSecond = curLevel - downLevel;
    aaf = fwidth(curLevelSecond);
    
    curLevelSecond = upLevel < level ? mix(downLevel, upLevel, smoothstep(1.0 - aaf, 1.0, curLevelSecond)) : downLevel;
    
    curLevel = min(curLevelFirst, curLevelSecond);
    
    curOffset = curLevel / (level - 1.0);
    curLevel += mix(minValue, 1.0, curOffset);
    curLevel = curLevel / level;
    
    return clamp(curLevel, 0.0, 1.0);
}

float dot2(vec2 v)
{
    return dot(v, v);
}

float dot2(vec3 v)
{
    return dot(v, v);
}

vec4 conjugate(vec4 q) {
    return vec4(-q.x, -q.y, -q.z, q.w);
}

vec4 quaternionInverse(vec4 q) {
    return conjugate(q) / dot(q, q);
}

vec3 sss( float ndl, float ir )
{
    float pndl = clamp( ndl, 0.0, 1.0 );
    float nndl = clamp(-ndl, 0.0, 1.0 );

    return vec3(pndl) + 
           vec3(1.0,0.1,0.0)*0.250*(1.0-pndl)*(1.0-pndl)*pow(1.0-nndl,3.0/(ir+0.001))*clamp(ir-0.04,0.0,1.0);
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

float onion( in float sdf, in float thickness )
{
    return abs(sdf)-thickness;
}

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

float sub(float d1, float d2)
{
    return max(d1, -d2);
}

float xor(float d1, float d2)
{
    return max(min(d1,d2),-max(d1,d2));
}

uint murmurHash12(uvec2 src) {
    const uint M = 0x5bd1e995u;
    uint h = 1190494759u;
    src *= M; src ^= src>>24u; src *= M;
    h *= M; h ^= src.x; h *= M; h ^= src.y;
    h ^= h>>13u; h *= M; h ^= h>>15u;
    return h;
}

float hash12(vec2 src) {
    uint h = murmurHash12(floatBitsToUint(src));
    return uintBitsToFloat(h & 0x007fffffu | 0x3f800000u) - 1.0;
}

uint murmurHash11(uint src) {
    const uint M = 0x5bd1e995u;
    uint h = 1190494759u;
    src *= M; src ^= src>>24u; src *= M;
    h *= M; h ^= src;
    h ^= h>>13u; h *= M; h ^= h>>15u;
    return h;
}

float hash11(float src) {
    uint h = murmurHash11(floatBitsToUint(src));
    return uintBitsToFloat(h & 0x007fffffu | 0x3f800000u) - 1.0;
}

uvec2 murmurHash22(uvec2 src) {
    const uint M = 0x5bd1e995u;
    uvec2 h = uvec2(1190494759u, 2147483647u);
    src *= M; src ^= src>>24u; src *= M;
    h *= M; h ^= src.x; h *= M; h ^= src.y;
    h ^= h>>13u; h *= M; h ^= h>>15u;
    return h;
}

vec2 hash22(vec2 src) {
    uvec2 h = murmurHash22(floatBitsToUint(src));
    return uintBitsToFloat(h & 0x007fffffu | 0x3f800000u) - 1.0;
}

float perlin(float p, float freq, float rep, float offset)
{
    p += offset / freq;
    p *= freq;
    
	vec2 i = vec2(floor(p)) + vec2(0.0, 1.0);
    i = mod(i, vec2(rep * freq));
	float f = fract(p);
	float u = f * f * (3.0 - 2.0 * f);
	return mix(hash11(i.x), hash11(i.y), u);
}

float perlin(vec2 p, vec2 freq, vec2 rep, vec2 offset)
{
    p += offset / freq;
    p *= freq;
    vec4 gridSet = floor(p.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
    vec4 dirSet = fract(p.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
    // 必要时保证噪声在连接处连续
    gridSet = mod(gridSet, (rep * freq).xyxy);
    
    vec2 gridLevel_00 = hash22(gridSet.xy) * 2.0 - 1.0;
    vec2 gridLevel_01 = hash22(gridSet.xw) * 2.0 - 1.0;
    vec2 gridLevel_10 = hash22(gridSet.zy) * 2.0 - 1.0;
    vec2 gridLevel_11 = hash22(gridSet.zw) * 2.0 - 1.0;
    
    float product_00 = dot(gridLevel_00, dirSet.xy);
    float product_01 = dot(gridLevel_01, dirSet.xw);
    float product_10 = dot(gridLevel_10, dirSet.zy);
    float product_11 = dot(gridLevel_11, dirSet.zw);
    
    float t_0 = pow(dirSet.x, 3.0) * (6.0 * pow(dirSet.x, 2.0) - 15.0 * dirSet.x + 10.0);
    float t_1 = pow(dirSet.y, 3.0) * (6.0 * pow(dirSet.y, 2.0) - 15.0 * dirSet.y + 10.0);
    
    // return dirSet.x;
    return mix(mix(product_00, product_10, t_0), mix(product_01, product_11, t_0), t_1);
}

float voronoi(vec2 p, vec2 freq, vec2 rep, vec2 offset, vec2 bias) {
    p *= freq;
    p += offset;
    vec2 point = floor(p);
    vec2 f = fract(p);
    float res = 0.0;
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 b = vec2(i, j);
            vec2 pos = mod(point + b, rep * freq);
            vec2 r = vec2(b) - f + hash22(pos);
            res += 1.0 / pow(dot(r, r), 8.0);
        }
    }
    return pow(1.0 / res, 0.0625);
}

float voronoiAndHide(vec2 p, vec2 freq, vec2 rep, vec2 offset, vec2 bias, vec2 factor, float posibility) {
    p *= freq;
    p += offset;
    vec2 point = floor(p);
    vec2 f = fract(p);
    float res = 0.0;
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 b = vec2(i, j);
            vec2 pos = mod(point + b, rep * freq) + bias;
            vec2 r = vec2(b) - f + hash22(pos) * factor;
            if(hash12(pos + vec2(123.0, 456.0)) < posibility) res += 0.0;
            else res += 1.0 / pow(dot(r, r), 8.0);
        }
    }
    return clamp(pow(1.0 / res, 0.0625), 0.0, 1.0);
}

float fbm(vec2 x, float H, vec2 freq, vec2 rep, vec2 offset, int numOctaves)
{    
    float G = exp2(-H);
    float f = 1.0;
    float a = 1.0;
    float t = 0.0;
    for( int i=0; i < numOctaves; i++ )
    {
        t += a * perlin(f * x, freq, f * rep, offset / freq);
        f *= 2.0;
        a *= G;
    }
    return t;
}

ObjectInfo objectMin(ObjectInfo a, ObjectInfo b)
{
    if(a.dis < b.dis ) return a;
    else return b;
}

// Shape 2D

float sdCircle(vec2 p, vec2 sdf_pos, float r)
{
    vec2 transPoint = p - sdf_pos;
    return length(transPoint) - r;
}

float sdTriangleIsosceles(vec2 p, vec2 sdf_pos, vec2 q)
{
    p.x = abs(p.x);
    vec2 a = p - q*clamp( dot(p,q)/dot(q,q), 0.0, 1.0 );
    vec2 b = p - q*vec2( clamp( p.x/q.x, 0.0, 1.0 ), 1.0 );
    float s = -sign( q.y );
    vec2 d = min( vec2( dot(a,a), s*(p.x*q.y-p.y*q.x) ),
                  vec2( dot(b,b), s*(p.y-q.y)  ));
    return -sqrt(d.x)*sign(d.y);
}

float sdBezier( in vec2 pos, in vec2 A, in vec2 B, in vec2 C)
{    
    vec2 a = B - A;
    vec2 b = A - 2.0*B + C;
    vec2 c = a * 2.0;
    vec2 d = A - pos;
    float kk = 1.0/dot(b,b);
    float kx = kk * dot(a,b);
    float ky = kk * (2.0*dot(a,a)+dot(d,b)) / 3.0;
    float kz = kk * dot(d,a);      
    float res = 0.0;
    float p = ky - kx*kx;
    float p3 = p*p*p;
    float q = kx*(2.0*kx*kx-3.0*ky) + kz;
    float h = q*q + 4.0*p3;
    if( h >= 0.0) 
    { 
        h = sqrt(h);
        vec2 x = (vec2(h,-h)-q)/2.0;
        vec2 uv = sign(x)*pow(abs(x), vec2(1.0/3.0));
        float t = clamp( uv.x+uv.y-kx, 0.0, 1.0 );
        res = dot2(d + (c + b*t)*t);
    }
    else
    {
        float z = sqrt(-p);
        float v = acos( q/(p*z*2.0) ) / 3.0;
        float m = cos(v);
        float n = sin(v)*1.732050808;
        vec3  t = clamp(vec3(m+m,-n-m,n-m)*z-kx,0.0,1.0);
        
        float d1 = dot2(d+(c+b*t.x)*t.x);
        float d2 = dot2(d+(c+b*t.y)*t.y);
        if(d1 < d2) 
        {
            res = d1;
        }
        else
        {
            res = d2;
        }
    }
    return sqrt( res );
}

// Shape
float sdSphere(vec3 p, vec3 sdf_pos, float sdf_rad)
{
    vec3 transPoint = p - sdf_pos;
    return distance(transPoint, vec3(0)) - sdf_rad;
}

float sdEllipsoid(vec3 p, vec3 sdf_pos, vec3 sdf_rad)
{
    vec3 transPoint = p - sdf_pos;
    float k0 = length(transPoint / sdf_rad);
    float k1 = length(transPoint / (sdf_rad * sdf_rad));
    return k0 * (k0-1.0) / k1;
}

float sdCapsule(vec3 p, vec3 sdf_pos_0, vec3 sdf_pos_1, float sdf_rad)
{
    vec3 pa = p - sdf_pos_0, ba = sdf_pos_1 - sdf_pos_0;
    float h = clamp(dot(pa, ba)/dot(ba, ba), 0.0, 1.0);
    return length( pa - ba*h ) - sdf_rad;
}

float sdRoundCone( vec3 p, vec3 sdf_pos_0, vec3 sdf_pos_1, float sdf_rad_0, float sdf_rad_1 )
{
  vec3  ba = sdf_pos_1 - sdf_pos_0;
  float l2 = dot(ba,ba);
  float rr = sdf_rad_0 - sdf_rad_1;
  float a2 = l2 - rr*rr;
  float il2 = 1.0/l2;
    
  vec3 pa = p - sdf_pos_0;
  float y = dot(pa,ba);
  float z = y - l2;
  float x2 = dot2( pa*l2 - ba*y );
  float y2 = y*y*l2;
  float z2 = z*z*l2;

  float k = sign(rr)*rr*rr*x2;
  if( sign(z)*a2*z2>k ) return  sqrt(x2 + z2)        *il2 - sdf_rad_1;
  if( sign(y)*a2*y2<k ) return  sqrt(x2 + y2)        *il2 - sdf_rad_0;
                        return (sqrt(x2*a2*il2)+y*rr)*il2 - sdf_rad_0;
}

float sdCutHollowSphere( vec3 p, vec3 sdf_pos, float sdf_rot, float r, float h, float t )
{
  vec3 transPoint = p - sdf_pos;
  
  float w = sqrt(r*r-h*h);
  
  vec2 q = vec2( length(transPoint.xy), -transPoint.z);
  return ((h*q.x<w*q.y) ? length(q-vec2(w,h)) : 
                          abs(length(q)-r) ) - t;
}

float sdBox( vec3 p, vec3 sdf_pos, vec3 b )
{
  vec3 transPoint = p - sdf_pos;
  vec3 q = abs(transPoint) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
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