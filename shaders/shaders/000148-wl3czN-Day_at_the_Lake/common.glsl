// Common (common) — Day at the Lake by nimitz
// https://www.shadertoy.com/view/wl3czN

// Day at the Lake by nimitz, 2020 (twitter: @stormoid)
// https://www.shadertoy.com/view/wl3czN
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

// Camera and cyclic noises (for clouds, water and terrain)

#define FAR 30.

const float fov = 1.3;
vec3 lgt = normalize( vec3(0.0, 0.27, -0.9) );

vec3 lcol = vec3(0);

mat3 rot_x(float a){float sa = sin(a); float ca = cos(a); return mat3(1.,.0,.0,    .0,ca,sa,   .0,-sa,ca);}
mat3 rot_y(float a){float sa = sin(a); float ca = cos(a); return mat3(ca,.0,sa,    .0,1.,.0,   -sa,.0,ca);}
mat3 rot_z(float a){float sa = sin(a); float ca = cos(a); return mat3(ca,sa,.0,    -sa,ca,.0,  .0,.0,1.);}

mat3 getRay(vec2 p, vec2 mo, out vec3 ro, out vec3 rd, float time)
{
    mo.y = 0.15;
    mo.x = mo.x*0.7 + 0.2;
    mo.x += sin(time*0.1)*0.5;
    
	ro = vec3(-3.5, -1.71, -4.0);
    rd = normalize(vec3(p, -fov));
    
    mat3 cam = rot_x(-mo.y)*rot_y(-mo.x);
	rd *= cam;
    
    mat3 invCam = rot_y(mo.x)*rot_x(mo.y);
    return invCam;
}

// For latitude 35, toD = time of day, toY = time of year, both 0..1
// not 100% accurate, but cheap to evaluate and pretty close
vec3 sunPos(float toD, float toY)
{
    toY = 1.0 - abs(fract(toY)-0.5)*2.0;
    float mid = 1.0-abs(toY-0.5)*2.0;
    float k = mix(0.68, 1.5, toY);
    float xk = pow(toD, k);
    toD = xk/(xk + pow(1.0-toD, k));
    toD = -toD*6.283853 - 1.5708 + 0.1;
    return normalize(vec3(sin(toD)*mix(0.4,0.7, mid) + mix(0.1, -0.1, toY), sin(toD) + mix(-.7, 0.69, toY), cos(toD)));
}

vec3 intcPlane(vec3 ro, vec3 rd, float plH)
{
    ro.y += plH;
    float t = -ro.y/rd.y;
    if (t < 0.)
        return vec3(1e6);
    float u =  ro.x + rd.x*t;
    float v =  ro.z + rd.z*t;
    return vec3(t,u,v);
}

// Clouds cyclic noise
const mat3 m3x = mat3(0.33338, 0.56034, -0.71817, -0.87887, 0.32651, -0.15323, 0.15162, 0.69596, 0.61339)*2.01;
vec4 cloudMap(vec3 p, float time)
{
    p.xz += vec2(-time*1.0, time*0.25);
    time *= 0.25;
    p.y -= 9.0;
    p *= vec3(0.19,0.3,0.19)*0.45;
    vec3 bp = p;
    float rz = 0.;
    vec3 drv = vec3(0);
    
    float z = 0.5;
    float trk= 0.9;
    float dspAmp = 0.2;
    
    float att = clamp(1.31-abs(p.y - 5.5)*0.095,0.,1.);
    float off = dot(sin(p*.52)*0.7+0.3, cos(p.yzx*0.6)*0.7+0.3)*0.75 - 0.2; //large structures
    float ofst = 12.1 - time*0.1;
    
    for (int i = 0; i<6; i++)
    {
        p += sin(p.yzx*trk - trk*2.0)*dspAmp;
        
        vec3 c = cos(p);
        vec3 s = sin(p);
        vec3 cs = cos(p.yzx + s.xyz + ofst);
        vec3 ss = sin(p.yzx + s.xyz + ofst);
        vec3 s2 = sin(p + s.zxy + ofst);
        vec3 cdrv = (c*(cs - s*ss) - s*ss.yzx - s.zxy*s2)*z;
        
        rz += (dot(s, cs) + off - 0.1)*z; //cloud density
        rz *= att;
        drv += cdrv;
        
        p += cdrv*0.05;
        p.xz += time*0.1;
        
        dspAmp *= 0.7;
        z *= 0.57;
        trk *= 2.1;
        p *= m3x;
    }
    
    return vec4(rz, drv);
}

// Water surface cyclic noise
mat2 m2w = mat2(0.90475, 0.42594, -0.42594, 0.90475)*2.12;
float waterDsp(vec2 p, float time)
{
    float rz = 0.;
    float z = 0.4;
    float trk= 1.0;
    float dspAmp = 0.5;
    
    for (int i = 0; i<5; i++)
    {
        p += sin(p.yx*0.5*trk + trk*2.5)*dspAmp;
        rz += pow(abs(dot(cos(p*0.37), sin(p - time*0.5*trk))*z), 1.2);
        
        z *= 0.49;
        trk *= 1.35;
        dspAmp *= 0.8;
        p *= m2w;
    }
    
    return rz;
}

// Terrain cyclic noise
float ttime = 0.;
const mat3 m3 = mat3(0.33338, 0.56034, -0.71817, -0.87887, 0.32651, -0.15323, 0.15162, 0.69596, 0.61339)*2.1;

void cyclicOctave(inout vec3 p, inout float rz, inout float z, inout float trk, inout float dspAmp)
{
    p += sin(p.yzx*0.25*trk - trk*6.1 + cos(p*0.1 + 0.5)*1.0)*dspAmp;
    float ofst = 4.6;
    vec3 s = sin(p*1.3);
    rz += smoothstep(-1.1, 0.5, dot(s, cos(p.yzx*0.95 + s.xyz + ofst)))*z;

    dspAmp *= 0.65;
    z *= 0.45;
    trk *= 1.45;
    p *= m3;
}

float cyclic3D(vec3 p )
{
    vec3 bp = p;
    float rz = 0.;
    vec3 drv = vec3(0);  
    float z = 1.44;
    float trk= 1.0;
    float dspAmp = 1.;
    
    for (int i = 0; i<=10; i++)
    {
        cyclicOctave(p, rz, z, trk, dspAmp);
    }
    rz -= 1.1;
    return rz;
}

float cyclic3DSimp(vec3 p )
{
    vec3 bp = p;
    float rz = 0.;
    float z = 1.44;
    float trk= 1.0;
    float dspAmp = 1.;
    
    for (int i = 0; i<=5; i++)
    {
      	cyclicOctave(p, rz, z, trk, dspAmp);
    }
    rz -= 1.1;
    return rz;
}

float map(vec3 p)
{
    float d = p.y;
    d -= sin(p.z*0.2 + 1.0 - cos(p.x*0.25))*0.35;
    float att = clamp(p.y*0.3 + 1.3, 0.,1.);
    d += cyclic3D(p*0.3)*att*1. + 1.;  
    return d;
}

float mapSimp(vec3 p)
{
    float d = p.y;
    d -= sin(p.z*0.2 + 1.0 - cos(p.x*0.25))*0.35;
    float att = clamp(p.y*0.3 + 1.3, 0.,1.);  
    d += cyclic3DSimp(p*0.3)*att*1. + 1.;
    return d;
}
