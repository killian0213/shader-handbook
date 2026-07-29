// Common (common) — Ishigami Kouko by SL0ANE
// https://www.shadertoy.com/view/lcV3Dt

# define PI 3.1415926535897932384626433832795
# define FAI 1.618033988749
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
# define DEFAULT_INFO ObjectInfo(65535.0, Material( vec4(1.0, 1.0, 1.0, 1.0), vec4(0.0), vec4(0.0), vec3(0.0), vec3(0.0), vec3(0.0), 0.0, 0.0, 0.0, 1));
# define DEFAULT_MAT mat4(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, -8.0, 1.0)
# define ZERO (min(iFrame,0))

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
    int index;
};

struct ObjectInfo
{
	float dis;
    Material material;
};

// Util
float linerstep(float start, float end, float t)
{
    return (t - start) / (end - start);
}
float smoothone(float x)
{
    return smoothstep(0.0, 1.0, x * 0.5 + 0.5) * 2.0 - 1.0;
}

float smoothmid(float x, float mid)
{
    return 1.0 - (x < mid ? pow((mid - x) / mid, 2.0) : pow((mid - x) / (1.0 - mid), 2.0));
}

float quaLerp(float right, float up, float left, float down, float center, vec2 t)
{
    float factor = length(t);
    if(factor == 0.0) return center;
    t = normalize(t) * 0.5 + 0.5;
    return mix(center, mix(left, right, t.x) + mix(down, up, t.y), factor);
}

vec2 quaLerp(vec2 right, vec2 up, vec2 left, vec2 down, vec2 center, vec2 t)
{
    float factor = length(t);
    if(factor == 0.0) return center;
    t = normalize(t) * 0.5 + 0.5;
    return mix(center, mix(left, right, t.x) + mix(down, up, t.y), factor);
}

float triLerp(float x, float y, float z, float t)
{
    if(t < 0.0) return mix(y, x, -t);
    else return mix(y, z, t);
}

float triLerp(float x, float y, float z, float t, float smoo)
{
    t = mix(t, smoothone(t), smoo);
    return triLerp(x, y, z, t);
}

vec2 triLerp(vec2 x, vec2 y, vec2 z, float t)
{
    return vec2(triLerp(x.x, y.x, z.x, t), triLerp(x.y, y.y, z.y, t));
}

vec2 triLerp(vec2 x, vec2 y, vec2 z, float t, float smoo)
{
    t = mix(t, smoothone(t), smoo);
    return vec2(triLerp(x.x, y.x, z.x, t), triLerp(x.y, y.y, z.y, t));
}

vec3 triLerp(vec3 x, vec3 y, vec3 z, float t)
{
    return vec3(triLerp(x.x, y.x, z.x, t), triLerp(x.y, y.y, z.y, t), triLerp(x.z, y.z, z.z, t));
}

vec3 triLerp(vec3 x, vec3 y, vec3 z, float t, float smoo)
{
    t = mix(t, smoothone(t), smoo);
    return vec3(triLerp(x.x, y.x, z.x, t), triLerp(x.y, y.y, z.y, t), triLerp(x.z, y.z, z.z, t));
}

vec3 applyTransform(vec3 origin, vec3 trans_x, vec3 trans_y, vec3 trans_z)
{
    return origin.x * trans_x + origin.y * trans_y + origin.z * trans_z;
}

float multiStep(float value, float level, float minValue, float offset)
{
    if(level <= 1.0) return 1.0;
    
    float curLevel = value * level;
    float curOffset = floor(curLevel) / (level - 1.0);
    curLevel = floor(curLevel + mix(offset, 0.0, curOffset));
    
    curOffset = curLevel / (level - 1.0);
    curLevel += mix(minValue, 1.0, curOffset);
    curLevel = curLevel / level;
    
    float ddx = dFdx(curLevel);
    float ddy = dFdy(curLevel);
    float smoo = clamp(length(vec2(ddx, ddy)) * 0.25, 0.0, 1.0);
    
    return mix(curLevel, value, smoo);
}

float dot2(vec2 v)
{
    return dot(v, v);
}

float dot2(vec3 v)
{
    return dot(v, v);
}

float cro( in vec2 a, in vec2 b ) { return a.x*b.y - a.y*b.x; }

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

float xor( float a, float b )
{
    return max( min(a,b), -max(a,b) );
}

float sub(float d1, float d2)
{
    return max(d1, -d2);
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

Material objectMix(Material a, Material b, float k)
{
    Material outMat = a;
    outMat.color0 = mix(a.color0, b.color0, k);
    outMat.color1 = mix(a.color1, b.color1, k);
    outMat.color2 = mix(a.color2, b.color2, k);
    outMat.vect0 = mix(a.vect0, b.vect0, k);
    outMat.vect1 = mix(a.vect1, b.vect1, k);
    outMat.vect2 = mix(a.vect2, b.vect2, k);
	outMat.t0 = mix(a.t0, b.t0, k);
    outMat.t1 = mix(a.t1, b.t1, k);
    outMat.t2 = mix(a.t2, b.t2, k);
    
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

float opExtrusion( in vec3 p, in float sdf, in float h )
{
    vec2 w = vec2( sdf, abs(p.z) - h );
  	return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}


// 2D Shape
float sdCircle( vec2 p, vec2 sdf_pos, float r )
{
    return length(p - sdf_pos) - r;
}

float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float sdBezier( in vec2 pos, in vec2 A, in vec2 C, in vec2 B, out float it)
{    
    vec2 a = B - A;
    vec2 b = A - 2.0 * B + C;
    vec2 c = a * 2.0;
    vec2 d = A - pos;

    float kk = 1.0/dot(b,b);
    float kx = kk * dot(a,b);
    float ky = kk * (2.0*dot(a,a)+dot(d,b))/3.0;
    float kz = kk * dot(d,a);      

    float res = 0.0;
    float sgn = 0.0;

    float p  = ky - kx*kx;
    float q  = kx*(2.0*kx*kx - 3.0*ky) + kz;
    float p3 = p*p*p;
    float q2 = q*q;
    float h  = q2 + 4.0*p3;

    if( h>=0.0 ) 
    {   // 1 root
        h = sqrt(h);
        vec2 x = (vec2(h,-h)-q)/2.0;

        vec2 uv = sign(x)*pow(abs(x), vec2(1.0/3.0));
        float t = clamp( uv.x+uv.y-kx, 0.0, 1.0 );
        vec2  q = d+(c+b*t)*t;
        res = dot2(q);
    	sgn = cro(c+2.0*b*t,q);
        
        it = t;
    }
    else 
    {   // 3 roots
        float z = sqrt(-p);
        float v = acos(q/(p*z*2.0))/3.0;
        float m = cos(v);
        float n = sin(v)*1.732050808;
        vec3  t = clamp( vec3(m+m,-n-m,n-m)*z-kx, 0.0, 1.0 );
        vec2  qx=d+(c+b*t.x)*t.x; float dx=dot2(qx), sx = cro(c+2.0*b*t.x,qx);
        vec2  qy=d+(c+b*t.y)*t.y; float dy=dot2(qy), sy = cro(c+2.0*b*t.y,qy);
        if( dx<dy ) { res=dx; sgn=sx; it = t.x;} else {res=dy; sgn=sy; it = t.y;}
    }
    
    return sqrt( res )*sign(sgn);
}

vec2 bezier(vec2 start, vec2 end, vec2 dir, float t)
{
    float oneMinus = 1.0 - t;
    return oneMinus * oneMinus * start + 2.0 * t * oneMinus * dir + t * t * end;
}

vec2 bezierTangent(vec2 start, vec2 end, vec2 dir, float t)
{
    float oneMinus = 1.0 - t;
    return 2.0 * oneMinus * (dir - start) + 2.0 * t * (end - dir);
}

float sdEllipse(vec2 p, vec2 sdf_pos, vec2 ab)
{
    p = p - sdf_pos;
    
    p = abs(p);
    if (abs(ab.x - ab.y) < 0.001) return length(p) - ab.x;
    if( p.x > p.y ) {p=p.yx;ab=ab.yx;}
    float l = ab.y*ab.y - ab.x*ab.x;
    float m = ab.x*p.x/l;      float m2 = m*m; 
    float n = ab.y*p.y/l;      float n2 = n*n; 
    float c = (m2+n2-1.0)/3.0; float c3 = c*c*c;
    float q = c3 + m2*n2*2.0;
    float d = c3 + m2*n2;
    float g = m + m*n2;
    float co;
    if( d<0.0 )
    {
        float h = acos(q/c3)/3.0;
        float s = cos(h);
        float t = sin(h)*sqrt(3.0);
        float rx = sqrt( -c*(s + t + 2.0) + m2 );
        float ry = sqrt( -c*(s - t + 2.0) + m2 );
        co = (ry+sign(l)*rx+abs(g)/(rx*ry)- m)/2.0;
    }
    else
    {
        float h = 2.0*m*n*sqrt( d );
        float s = sign(q+h)*pow(abs(q+h), 1.0/3.0);
        float u = sign(q-h)*pow(abs(q-h), 1.0/3.0);
        float rx = -s - u - c*4.0 + 2.0*m2;
        float ry = (s - u)*sqrt(3.0);
        float rm = sqrt( rx*rx + ry*ry );
        co = (ry/sqrt(rm-rx)+2.0*g/rm-m)/2.0;
    }
    vec2 r = ab * vec2(co, sqrt(1.0-co*co));
    return length(r-p) * sign(p.y-r.y);
}

float sdOrientedVesica(vec2 p, vec2 a, vec2 b, float w)
{
    float r = 0.5*length(b-a);
    float d = 0.5*(r*r-w*w)/w;
    vec2 v = (b-a)/r;
    vec2 c = (b+a)*0.5;
    vec2 q = 0.5*abs(mat2(v.y,v.x,-v.x,v.y)*(p-c));
    vec3 h = (r*q.x<d*(q.y-r)) ? vec3(0.0,r,0.0) : vec3(-d,0.0,d+w);
    return length( q-h.xy) - h.z;
}

float sdUnevenCapsule( in vec2 p, in vec2 pa, in vec2 pb, in float ra, in float rb )
{
    p  -= pa;
    pb -= pa;
    float h = dot(pb,pb);
    vec2  q = vec2( dot(p,vec2(pb.y,-pb.x)), dot(p,pb) )/h;
    
    //-----------
    
    q.x = abs(q.x);
    
    float b = ra-rb;
    vec2  c = vec2(sqrt(h-b*b),b);
    
    float k = cro(c,q);
    float m = dot(c,q);
    float n = dot(q,q);
    
         if( k < 0.0 ) return sqrt(h*(n            )) - ra;
    else if( k > c.x ) return sqrt(h*(n+1.0-2.0*q.y)) - rb;
                       return m                       - ra;
}

// 3D Shape
float sdEllipsoid(vec3 p, vec3 sdf_pos, vec3 sdf_rad)
{
    vec3 transPoint = p - sdf_pos;
    float k0 = length(transPoint / sdf_rad);
    float k1 = length(transPoint / (sdf_rad * sdf_rad));
    return k0 * (k0-1.0) / k1;
}

float sdCapsule( vec3 p, vec3 sdf_pos_0, vec3 sdf_pos_1, float sdf_rad)
{
    vec3 pa = p - sdf_pos_0, ba = sdf_pos_1 - sdf_pos_0;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - sdf_rad;
}

float sdPlane( vec3 p, vec3 sdf_pos, vec3 sdf_normal)
{
    return dot(p - sdf_pos, sdf_normal);
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

float sdSphere(vec3 p, vec3 sdf_pos, float sdf_rad)
{
    vec3 transPoint = p - sdf_pos;
    return distance(transPoint, vec3(0)) - sdf_rad;
}

float sdVesicaSegment(vec3 p, vec3 sdf_pos_0, vec3 sdf_pos_1, float sdf_rad_0)
{
    vec3  c = (sdf_pos_0 + sdf_pos_1) * 0.5;
    float l = length(sdf_pos_1 - sdf_pos_0);
    vec3  v = (sdf_pos_1 - sdf_pos_0)/l;
    float y = dot(p - c, v);
    vec2  q = vec2(length(p - c - y * v),abs(y));
    
    float r = 0.5 * l;
    float d = 0.5 * (r * r - sdf_rad_0 * sdf_rad_0 ) / sdf_rad_0;
    vec3  h = (r * q.x < d * (q.y - r)) ? vec3(0.0, r, 0.0) : vec3(-d, 0.0, d + sdf_rad_0);
 
    return length(q - h.xy) - h.z;
}


float udTriangleSqr( vec3 p, vec3 a, vec3 b, vec3 c, vec3 ba, vec3 cb, vec3 ac, vec3 pa, vec3 pb, vec3 pc, out vec3 nor)
{
    nor = cross( ba, ac );

    return (sign(dot(cross(ba,nor),pa)) +
          sign(dot(cross(cb,nor),pb)) +
          sign(dot(cross(ac,nor),pc))<2.0)
          ?
          min( min(
          dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
          dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb) ),
          dot2(ac*clamp(dot(ac,pc)/dot2(ac),0.0,1.0)-pc) )
          :
          dot(nor,pa)*dot(nor,pa)/dot2(nor);
}

float sdPyramid( vec3 p, vec3 a, vec3 b, vec3 c, vec3 d, vec3 e)
{
    vec3 ba = b - a;
    vec3 cb = c - b;
    vec3 dc = d - c;
    vec3 ad = a - d;
    vec3 ea = e - a;
    vec3 eb = e - b;
    vec3 ec = e - c;
    vec3 ed = e - d;
  
    vec3 pa = p - a;
    vec3 pb = p - b;
    vec3 pc = p - c;
    vec3 pd = p - d;
    vec3 pe = p - e;
  
    vec3 nor0 = cross( ba, ad );
  
    float sd0 = (sign(dot(cross(ba,nor0),pa)) +
                 sign(dot(cross(cb,nor0),pb)) +
                 sign(dot(cross(dc,nor0),pc)) +
                 sign(dot(cross(ad,nor0),pd))<3.0)
                 ?
                 min( min( min(
                 dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
                 dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb) ),
                 dot2(dc*clamp(dot(dc,pc)/dot2(dc),0.0,1.0)-pc) ),
                 dot2(ad*clamp(dot(ad,pd)/dot2(ad),0.0,1.0)-pd) )
                 :
                 dot(nor0,pa)*dot(nor0,pa)/dot2(nor0);
                 
    vec3 nor1;             
    float sd1 = udTriangleSqr(p, e, a, d, -ea, -ad, ed, pe, pa, pd, nor1);
    
    vec3 nor2;
    float sd2 = udTriangleSqr(p, e, b, a, -eb, -ba, ea, pe, pb, pa, nor2);
    
    vec3 nor3;
    float sd3 = udTriangleSqr(p, e, c, b, -ec, -cb, eb, pe, pc, pb, nor3);
    
    vec3 nor4;
    float sd4 = udTriangleSqr(p, e, d, c, -ed, -dc, ec, pe, pd, pc, nor3);
               
    return sqrt(min(min(min(min(sd0, sd1), sd2), sd3), sd4));
}