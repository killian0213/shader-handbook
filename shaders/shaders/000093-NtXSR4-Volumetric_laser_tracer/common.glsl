// Common (common) — Volumetric laser tracer by michael0884
// https://www.shadertoy.com/view/NtXSR4

#define TWO_PI 6.28318530718
#define PI 3.14159265359
#define FOV 1.1
#define CAM_ANGLE 0.001
#define MAX_STEPS 90
#define MIN_DIST 1e-5
#define MAX_DIST 500.0

//(reused some of @ollj's code, made it more readible)

vec3 light = normalize(vec3(0,1,0));
const float light_bright =1.0;
const float light_ang = 0.1;

//specific controller buffer Addresses
const float CamP = 0.,     //camera position 
            CamA = 1.,     //camera rotation quaternion    
            CamV = 2.,     //camera velocity
            CamAV = 3.,    //camera rotation velocity
            PrevCamP = 4., //previous frame camera position
            PrevCamA = 5., //previous frame camera rotation quaternion
            PrevMouse = 6.,//previous mouse pos
            NAddr = 7.;    //max address count
            
#define get(i) texelFetch(iChannel2,ivec2(i,0),0)

float sqr(float x)
{
    return x*x;
}

float iPlane( in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal,
              in vec3 planeNormal, in float planeDist) {
    float a = dot(rd, planeNormal);
    float d = -(dot(ro, planeNormal)+planeDist)/a;
    if (a > 0. || d < distBound.x || d > distBound.y) {
        return MAX_DIST;
    } else {
        normal = planeNormal;
    	return d;
    }
}

float iSphere( in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal,
               float sphereRadius ) {
    float b = dot(ro, rd);
    float c = dot(ro, ro) - sphereRadius*sphereRadius;
    float h = b*b - c;
    if (h < 0.) {
        return MAX_DIST;
    } else {
	    h = sqrt(h);
        float d1 = -b-h;
        float d2 = -b+h;
        if (d1 >= distBound.x && d1 <= distBound.y) {
            normal = normalize(ro + rd*d1);
            return d1;
        } else if (d2 >= distBound.x && d2 <= distBound.y) { 
            normal = normalize(ro + rd*d2);            
            return d2;
        } else {
            return MAX_DIST;
        }
    }
}

float iBox( in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal, 
            in vec3 boxSize ) {
    vec3 m = sign(rd)/max(abs(rd), 1e-8);
    vec3 n = m*ro;
    vec3 k = abs(m)*boxSize;
	
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

	float tN = max( max( t1.x, t1.y ), t1.z );
	float tF = min( min( t2.x, t2.y ), t2.z );
	
    if (tN > tF || tF <= 0.) {
        return MAX_DIST;
    } else {
        if (tN >= distBound.x && tN <= distBound.y) {
        	normal = -sign(rd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
            return tN;
        } else if (tF >= distBound.x && tF <= distBound.y) { 
        	normal = -sign(rd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
            return tF;
        } else {
            return MAX_DIST;
        }
    }
}

float iCylinder( in vec3 ro, in vec3 rd, 
                in vec3 pa, in vec3 pb, float ra ) // extreme a, extreme b, radius
{
    vec3 ba = pb-pa;

    vec3  oc = ro - pa;

    float baba = dot(ba,ba);
    float bard = dot(ba,rd);
    float baoc = dot(ba,oc);
    
    float k2 = baba            - bard*bard;
    float k1 = baba*dot(oc,rd) - baoc*bard;
    float k0 = baba*dot(oc,oc) - baoc*baoc - ra*ra*baba;
    
    float h = k1*k1 - k2*k0;
    if( h<0.0 ) return 1e10;
    h = sqrt(h);
    float t = (-k1-h)/k2;

    // body
    float y = baoc + t*bard;
    if( y>0.0 && y<baba ) return t;
    
    // caps
    t = ( ((y<0.0) ? 0.0 : baba) - baoc)/bard;
    if( abs(k1+k2*t)<h )
    {
        return t;
    }

    return 1e10;
}

//ollj quaternionRotation math
//
//ANY rotations in 3d are non-commutative!
//
//matrix rotations are just bulky, memory wasting
//EulerRotations almost certainly fail to rotate over the SHORTEST path.
//EulerRotations almost certainly will gimbalLock and get stuck along one axis
//QuaternionRotations are superior here.
//-> we only use EulerRorations for simple input devices (keyboard input)
//-> we convert to quaternions, buffered as vec4.

//quaternion Identity
vec4 qid() 
{
    return vec4(0, 0, 0, 1);
}

//return quaternion from axis and angle
vec4 aa2q(vec3 axis, float ang) 
{
    vec2 g = vec2(sin(ang), cos(ang)) * 0.5;
    return normalize(vec4(axis * g.x, g.y));
}

//return AxisAngle of NORMALIZED quaternion input
vec4 q2aa(vec4 q) 
{
    return vec4(q.xyz / sqrt(1.0 - q.w * q.w), acos(q.w) * 2.);
}

//return q2, rotated by q1, order matters (is non commutative) : (aka quaternion multiplication == AxisAngleRotation)
vec4 qq2q(vec4 q1, vec4 q2) 
{
    return vec4(q1.xyz * q2.w + q2.xyz * q1.w + cross(q1.xyz, q2.xyz), (q1.w * q2.w) - dot(q1.xyz, q2.xyz));
}

//extension to qq2q(), scaled by sensitivity [f] (==quaternion ANGULAR equivalent to slerp() )
vec4 qq2qLerp(vec4 a, vec4 b, float f) 
{
    float d = dot(a, b), t = acos(abs(d)), o = (1. / sin(t));
    return normalize(a * sin(t * (1.0 - f)) * o * sign(d) + b * sin(t * f) * o);
}

//doing qq2q() multiple times, you need to normalize() the quaternion, to fix rounding errors.
//how often you do this is up to you.

//normalize q (assuming length(q) is already close to 1, we can skip whe sqrt()
vec4 qn(vec4 q) 
{
    return q / dot(q,q);
}

//return quaternion, that is the shortest rotation, between looking to [a before], and looking to [b after] the rotation.
//http://wiki.secondlife.com/wiki/LlRotBetween
vec4 qBetween(vec3 a, vec3 b) 
{
    float v = sqrt(dot(a,a) * dot(a,a));

    if(v == 0.) return qid();
    
    v = dot(a, b) / v;
    vec3 c = a.yzx * b.zxy - a.zxy * b.yzx / v;
    float d = dot(c,c);
    
    if(d != 0.) 
    {
        float s = (v > - 0.707107) ? 1. + v : d / (1. + sqrt(1. - d));
        return vec4(c, s) / sqrt(d + s * s);
    }
    
    if(v > 0.) return qid();
    
    float m = length(a.xy);
    
    return (m != 0.) ? vec4(a.y, - a.x, 0, 0) / m : vec4(1, 0, 0, 0);
}

//return inverse of quaternion
vec4 qinv(vec4 q) 
{
    return vec4(- q.xyz, q.w) / dot(q,q);
}

//return VECTOR p, rotated by quaterion q;
vec3 qv2v(vec4 q, vec3 p) 
{
    return qq2q(q, qq2q(vec4(p, .0), qinv(q))).xyz;
}

//qv2v()  with swapped inputs
//return quaterion P (as vector), as if it is rotated by VECTOR p (as if it is a quaternion)
vec3 vq2v(vec3 p, vec4 q) 
{
    return qq2q(qinv(q), qq2q(vec4(p, 0.0), q)).xyz;
}

vec3 vq2v(vec4 a, vec3 b) 
{
    return qv2v(a, b);
}

//in case of namespace confuction
vec3 qv2v(vec3 a, vec4 b) 
{
    return vq2v(a, b);
}

//return mat3 of quaternion (rotation matrix without translation)
//https://www.shadertoy.com/view/WsGfWm
mat3 q2m(vec4 q) 
{
    vec3 a = vec3(-1, 1, 1);
    vec3 u = q.zyz * a, v = q.xyx * a.xxy;
    mat3 m = mat3(0.5) + mat3(0, u.x,u.y,u.z, 0, v.x,v.y,v.z, 0) * q.w + matrixCompMult(outerProduct(q.xyz, q.xyz), 1. - mat3(1));
    q *= q; 
    m -= mat3(q.y + q.z, 0, 0, 0, q.x + q.z, 0, 0, 0, q.x + q.y);
    return m * 2.0;
}

//return quaternion of orthogonal matrix (with determinant==1., or else quaternionm will not be normalized)
vec4 m2q(mat3 m) 
{
#define m2f(a,b) m[a][b]-m[b][a]
    //http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/
    float q = 2. * sqrt(abs(1. + m[0][0] + m[1][1] + m[2][2]));
    return vec4(vec3(m2f(2, 1), m2f(0, 1), m2f(1, 0)) / q / 4., q);
#undef m2f
}

float at2e(vec2 a) 
{
    a *= 2.;
    return atan(a.x, 1. - a.y);
}

//return quaternion of Euler[yaw,pitch,roll]     
vec4 eYPR2q(vec3 o) 
{
    o *= .5;
    vec3 s = sin(o);
    //https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles#Source_code
    o = cos(o);
    vec4 a = vec4(s.xz, o.xz);
    return a.yyww * a.zxxz * o.y + a.wwyy * a.xzzx * s.y * vec4(-1, 1, -1, 1);
}

vec4 eYPR2q(vec2 o) 
{
    o *= .5;
    vec2 s = sin(o);
    o = cos(o);
    vec4 a = vec4(s.x, 0., o.x, 0.);
    return a.yyww * a.zxxz * o.y + a.wwyy * a.xzzx * s.y * vec4(- 1, 1, - 1, 1);
}

mat3 getCam(vec4 q) 
{
    return q2m(q);
}

//internal RNG state 
uvec4 s0, s1; 
ivec2 pixel;

void rng_initialize(vec2 p, int frame)
{
    pixel = ivec2(p);

    //white noise seed
    s0 = uvec4(p, uint(frame), uint(p.x) + uint(p.y));
    
    //blue noise seed
    s1 = uvec4(frame, frame*15843, frame*31 + 4566, frame*2345 + 58585);
}

// https://www.pcg-random.org/
uvec4 pcg4d(inout uvec4 v)
{
	v = v * 1664525u + 1013904223u;
    v.x += v.y*v.w; v.y += v.z*v.x; v.z += v.x*v.y; v.w += v.y*v.z;
    v = v ^ (v>>16u);
    v.x += v.y*v.w; v.y += v.z*v.x; v.z += v.x*v.y; v.w += v.y*v.z;
    return v;
}

float rand(){ return float(pcg4d(s0).x)/float(0xffffffffu); }
vec2 rand2(){ return vec2(pcg4d(s0).xy)/float(0xffffffffu); }
vec3 rand3(){ return vec3(pcg4d(s0).xyz)/float(0xffffffffu); }
vec4 rand4(){ return vec4(pcg4d(s0))/float(0xffffffffu); }

vec2 nrand2(float sigma, vec2 mean)
{
	vec2 Z = rand2();
    return mean + sigma * sqrt(-2.0 * log(Z.x)) * 
           vec2(cos(TWO_PI * Z.y),sin(TWO_PI * Z.y));
}

vec3 nrand3(float sigma, vec3 mean)
{
	vec4 Z = rand4();
    return mean + sigma * sqrt(-2.0 * log(Z.xxy)) * 
           vec3(cos(TWO_PI * Z.z),sin(TWO_PI * Z.z),cos(TWO_PI * Z.w));
}

//uniformly spherically distributed
vec3 udir(vec2 rng)
{
    vec2 r = vec2(2.*PI*rng.x, acos(2.*rng.y-1.));
    vec2 c = cos(r), s = sin(r);
    return vec3(c.x*s.y, s.x*s.y, c.y);
}


const float PI2 = 6.2831853071;

// Valid from 1000 to 40000 K (and additionally 0 for pure full white)
vec3 colorTemperatureToRGB(const in float temperature){
  // Values from: http://blenderartists.org/forum/showthread.php?270332-OSL-Goodness&p=2268693&viewfull=1#post2268693   
  mat3 m = (temperature <= 6500.0) ? mat3(vec3(0.0, -2902.1955373783176, -8257.7997278925690),
	                                      vec3(0.0, 1669.5803561666639, 2575.2827530017594),
	                                      vec3(1.0, 1.3302673723350029, 1.8993753891711275)) : 
	 								 mat3(vec3(1745.0425298314172, 1216.6168361476490, -8257.7997278925690),
   	                                      vec3(-2666.3474220535695, -2173.1012343082230, 2575.2827530017594),
	                                      vec3(0.55995389139931482, 0.70381203140554553, 1.8993753891711275)); 
  return mix(clamp(vec3(m[0] / (vec3(clamp(temperature, 1000.0, 40000.0)) + m[1]) + m[2]), vec3(0.0), vec3(1.0)), vec3(1.0), smoothstep(1000.0, 0.0, temperature));
}


const float aperture_size = 0.0;
vec2 aperture()
{
    vec2 r = rand2();
    return vec2(sin(TWO_PI*r.x), cos(TWO_PI*r.x))*sqrt(r.y);
}

float saturate (float x)
{
    return min(1.0, max(0.0,x));
}
vec3 saturate (vec3 x)
{
    return min(vec3(1.,1.,1.), max(vec3(0.,0.,0.),x));
}

vec3 bump3y (vec3 x, vec3 yoffset)
{
	vec3 y = vec3(1.,1.,1.) - x * x;
	y = saturate(y-yoffset);
	return y;
}
vec3 spectral_zucconi(float w)
{
    // w: [400, 700]
	// x: [0,   1]
	float x = saturate((w - 400.0)/ 300.0);

	const vec3 cs = vec3(3.54541723, 2.86670055, 2.29421995);
	const vec3 xs = vec3(0.69548916, 0.49416934, 0.28269708);
	const vec3 ys = vec3(0.02320775, 0.15936245, 0.53520021);

	return bump3y (	cs * (x - xs), ys);
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

float capIntersect( in vec3 ro, in vec3 rd, in vec3 pa, in vec3 pb, in float r )
{
    vec3  ba = pb - pa;
    vec3  oa = ro - pa;

    float baba = dot(ba,ba);
    float bard = dot(ba,rd);
    float baoa = dot(ba,oa);
    float rdoa = dot(rd,oa);
    float oaoa = dot(oa,oa);

    float a = baba      - bard*bard;
    float b = baba*rdoa - baoa*bard;
    float c = baba*oaoa - baoa*baoa - r*r*baba;
    float h = b*b - a*c;
    if( h>=0.0 )
    {
        float t = (-b-sqrt(h))/a;
        float y = baoa + t*bard;
        // body
        if( y>0.0 && y<baba ) return t;
        // caps
        vec3 oc = (y<=0.0) ? oa : ro - pb;
        b = dot(rd,oc);
        c = dot(oc,oc) - r*r;
        h = b*b - c;
        if( h>0.0 ) return -b - sqrt(h);
    }
    return -1.0;
}