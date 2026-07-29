// Common (common) — Curved Surface Reflection by NuSan
// https://www.shadertoy.com/view/msjXDR



const int line_points=30;
const int ctrl_points=6;
const int maxReflect=6;
const int ray_per_frame=20;
const float timeblur=0.9;
const float luminosity=6.0;
const float rayblur = 0.02;


const bool spatialBlur = false;

const bool DrawUI = true;
const bool DrawTestRay = false;

const int ButtonNumber = 3;
const vec2 ButtonSpread = vec2(-0.75,0.35);

float rnd(float t) {
    return fract(sin(t*547.824)*324.384);
}

vec3 rnd3(vec3 t) {
    return fract(sin(t*547.824 + t.yzx*827.398 + t.zxy*241.154)*324.384);
}

vec2 hash23(vec3 p3)
{
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

//length squared
float lengthSquared(vec2 v, vec2 w)
{
    return (v.x - w.x) * (v.x - w.x) + (v.y - w.y) * (v.y - w.y);
}

//Returns squared distance between point p and line segment L defined by endpoints LA, LB
float distanceToSegmentSquared(vec2 p, vec2 LA, vec2 LB)
{
    //distance of line segment
    float l2 = lengthSquared(LA,LB);
    //If line segment is 0 length, just get difference with first endpoint
    if (l2 == 0.0) 
        return lengthSquared(p, LA);
    
    //Vector representation of L
    vec2 v = LB - LA;
    vec2 w = p - LA;
    
    //t is percentage along line L point p falls
    float t = dot(w,v) / l2;  
    t = clamp(t,0.0,1.0);
    
    //projection of p onto v,w is nearest point
    vec2 nearestPoint = vec2(LA.x + t * v.x, LA.y + t * v.y);
    
    //Distance between p and projectedpoint
    return lengthSquared(p, nearestPoint);
}


float NearestPercentSegment(vec2 p, vec2 LA, vec2 LB) {
//distance of line segment
    float l2 = lengthSquared(LA,LB);
    //If line segment is 0 length, just return 0
    if (l2 == 0.0) 
        return 0.0;
    
    //Vector representation of L
    vec2 v = LB - LA;
    vec2 w = p - LA;
    
    //t is percentage along line L point p falls
    float t = dot(w,v) / l2;  
    t = clamp(t,0.0,1.0);
    
    return t;
}

float distanceToSegment(vec2 p, vec2 v, vec2 w)
{
    return sqrt(distanceToSegmentSquared(p,v,w));
}

//Cross product of 2d vectors returns scalar
//1 = perpendicular, 0 = colinear
float cross2D(vec2 v1, vec2 v2)
{
    return v1.x * v2.y - v1.y * v2.x;
}

//Line intersection algorithm
//Based off Andre LeMothe's algorithm in "Tricks of the Windows Game Programming Gurus".
bool lineIntersection(vec2 L1A, vec2 L1B, vec2 L2A, vec2 L2B, out vec2 p)
{
    vec2 v1 = L1B - L1A;
    vec2 v2 = L2B - L2A;
    float d = cross2D(v1,v2);
   
    vec2 LA_delta = L1A - L2A;

    float s = cross2D(v1,LA_delta) / d;
    float t = cross2D(v2,LA_delta) / d;
    
    if (s >= 0.0 && s <= 1.0 && t >= 0.0 && t <= 1.0)
    {
        p = vec2(L1A.x + (t * v1.x), L1A.y + (t * v1.y)); 
        return true;
    }
    return false;
}


vec4 someFunction( vec4 a, float b )
{
    return a+b;
}