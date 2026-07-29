// Common (common) — Quadtree ReSTIR GI by Mathis
// https://www.shadertoy.com/view/DslSDM

//Settings
const float START_LOD = 9.;
const float M_CLAMP_T = 10.;
const float ReservoirScale = 4.;
const float IReservoirScale = 1./ReservoirScale;
const vec3 SkyColor = vec3(0.6,0.85,1.)*1.25;
const vec3 SunColor = vec3(1.,0.7,0.2)*10.;
#define SecondBounce

//Other vars
const float I256 = 1./256.;
const float I512 = 1./512.;
const float I1024 = 1./1024.;
const float PI = 3.141592653;
const float PI2 = PI*2.;
const float IPI2 = 0.5/PI;
#define RES iChannelResolution[0].xy
#define IRES (1./iChannelResolution[0].xy)

vec3 SampleSky(vec2 d) {
    return SkyColor*max(0.,2.*d.y-1.); //+pow(max(0.,dot(d,normalize(vec2(1.,0.7)))),10.)*SunColor;
}

float LineDF(vec2 p, vec2 a, vec2 b) {
    //Distance Field
    vec2 ba = b-a;
    float k = dot(p-a,ba)/dot(ba,ba);
    return length((a+clamp(k,0.,1.)*(b-a))-p);
}

float BoxDF(vec2 p, vec2 b) {
    vec2 d = abs(p-b*0.5)-b*0.5;
    return min(max(d.x,d.y),0.)+length(max(d,0.));
}

float boxfar2(vec2 origin, vec2 dir, vec2 bmin, vec2 bmax) {
    //Returns the far side of a 2D box
    vec2 tMin = (bmin-origin)*dir;
    vec2 tMax = (bmax-origin)*dir;
    vec2 t2 = max(tMin,tMax);
    return min(t2.x,t2.y);
}

vec2 box2(vec2 origin, vec2 dir, vec2 bmin, vec2 bmax) {
    //Returns the near and far side of a 2D box
    vec2 tMin = (bmin-origin)*dir;
    vec2 tMax = (bmax-origin)*dir;
    vec2 t1 = max(tMin,tMax);
    vec2 t2 = min(tMin,tMax);
    return vec2(max(t2.x,t2.y),min(t1.x,t1.y));
}

vec2 boxNormal(vec2 origin, vec2 dir, vec2 bmin, vec2 bmax) {
    vec2 tMin=(bmin-origin)*dir;
    vec2 tMax=(bmax-origin)*dir;
    vec2 t1=min(tMin,tMax);
    vec2 t2=max(tMin,tMax);
    vec2 signdir = -(max(vec2(0.),sign(dir))*2.-1.);
    if (t1.x>t1.y) return vec2(signdir.x,0.);
    else return vec2(0.,signdir.y);
}

vec2 Rotate(vec2 p, float ang) {
    float c=cos(ang), s=sin(ang);
    return vec2(p.x*c-p.y*s,p.x*s+p.y*c);
}

//Bad vec2/vec3 to float functions
vec3 FloatToVec3(float v, float scale) {
    float x = fract(v);
    float y = floor(mod(v,100.))*0.01;
    float z = floor(v*0.01)*0.01;
    return vec3(x,y,z)*scale;
}

float Vec3ToFloat(vec3 v, float invscale) {
    v = min(v*invscale,vec3(0.999));
    return v.x+floor(v.y*100.)+floor(v.z*100.)*100.;
}

vec2 FloatToMAngle(float v) {
    return vec2(floor(v),fract(v)*PI2);
}

float MAngleToFloat(vec2 ma) {
    return ma.x+min(0.99999,ma.y*IPI2);
}