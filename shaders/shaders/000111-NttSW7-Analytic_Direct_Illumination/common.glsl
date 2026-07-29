// Common (common) — Analytic Direct Illumination by Mathis
// https://www.shadertoy.com/view/NttSW7

//Settings
const vec3 SkyColor = vec3(0.2,0.5,1.);
const vec3 SunColor = vec3(1.,0.7,0.1)*10.;
const float SunA = 2.; //Sun-angle position
const float SunS = 64.; //Sun-size, higher is smaller
const vec3 EmissiveColor = vec3(1.,0.9,0.9)*4.;
#define Sun
#define InteractRadius iChannelResolution[0].y*0.05

//Other vars
#define NObjects 6.
#define NVA 18
const float PI = 3.141592653;
const float PI2 = PI*2.;
const float IPI2 = 0.5/PI;
const float SSunS = sqrt(SunS);
const float ISSunS = 1./SSunS;
#define RES iChannelResolution[0].xy
#define IRES (1./iChannelResolution[0].xy)

struct GeoInt { float a0; float a1; vec4 p; vec3 E; };

float LineDF(vec2 p, vec2 a, vec2 b) {
    //Distance Field
    vec2 ba = b-a;
    float k = dot(p-a,ba)/dot(ba,ba);
    return length((a+clamp(k,0.,1.)*(b-a))-p);
}

float PlaneDF(vec2 p, vec2 a, vec2 b) {
    //Distance Field
    vec2 ba = b-a;
    vec2 lnorm = normalize(vec2(-ba.y,ba.x));
    return abs(dot(p-a,lnorm));
}

vec2 LineXI(vec2 uv, vec2 a, vec2 b) {
    //Intersection of the line from UV with dir vec2(1.,0.)
    vec2 dir = b-a;
    vec2 rp = a-uv;
    return a+dir*(-rp.y/dir.y);
}

float LineRI(vec2 uv, vec2 dir, vec4 ab) {
    //Intersection of the line
    vec2 ltan = ab.zw-ab.xy;
    vec2 lnorm = vec2(-ltan.y,ltan.x);
    return -dot(uv-ab.xy,lnorm)/dot(dir,lnorm);
}

vec4 RenderGeometry(vec2 UV, sampler2D ch0, vec2 ires) {
    float SDF = 10.;
    float ssdf; vec3 E = vec3(0.); vec4 linep;
    for (float i=0.; i<NObjects; i++) {
        linep = texture(ch0,vec2(1.5+i,0.5)*ires);
        ssdf = LineDF(UV,linep.xy,linep.zw);
        if (ssdf<SDF) {
            SDF = ssdf;
            if (i==5.) E = EmissiveColor; else E = vec3(0.);
        }
    }
    float W = 1.-clamp(0.,1.,SDF-1.);
    return vec4(E*W,W);
}

vec3 SkyIntegral(float a0, float a1) {
    //Integrates the sky
        //Integrand: SkyColor.xyz*(1.+0.5*sin(a))
        //Integral: SkyColor.xyz*(a-0.5*cos(a))
    vec3 SI = SkyColor*(a1-a0-0.5*(cos(a1)-cos(a0)));
    #ifdef Sun
        //Integrand: SunColor/(1+SunS*(a-SunA)^2)
        //Integral: SunColor.xyz*(-atan(sqrt(SunS)*(SunA-a)))/sqrt(SunS)
    SI += SunColor*(atan(SSunS*(SunA-a0))-atan(SSunS*(SunA-a1)))*ISSunS;
    #endif
    return SI;
}