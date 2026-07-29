// Common (common) — Moving around scene with TAA by morimea
// https://www.shadertoy.com/view/DdSBDy


//#define move_SUN_circle_inf
#define move_rounds
#ifdef move_rounds
const float rspd = 0.0235; //rotation speed
#endif

// change number of rays for better qality
#define AORays 8
#define reflectionRays 6
#define shadowRays 6

#ifdef move_rounds
vec3 lightDir = normalize(vec3(0.045, .15, 1.0));
#else 
const vec3 lightDir = normalize(vec3(0.045, .15, 1.0));
#endif

// edit parameters
// ---------------

// when enabled 2nd light bounce (num of rays=AORays)
#define sunlight_2nd_bounce

#define enable_reflections
#define reflection_color_emi

// when ConeVector used in bounce light and emision light have not correct form 
// (compare to CosineWeightedSample, comment define below)
#define use_ConeVector
#define use_reproject_TAA

// when turned off dymanic TAA - BufD is unused
#define use_dynamic_TAA

// texture or volume, texture use single float in BufB
// and BufC copy to self alpha, just to have less texture reads in BufD that apply albedo TAA
// albedo addition to color moved to BufD because TAA-pixel-jitter
// no textures in this shader
//#define enable_textures

// when enabled dynamic TAA - there visible "border" on volume-shadow and object edges
// I did unjitter it in Image shader // unjittering volume fog
// it better now, line not jittering but it still visible 1 pixel around objects when camera move
#define enable_volume

#define volumeSteps 10
const float volume_fogDensity = .125;

const float camera_fov = 70.;



#define add_clouds

#define cloud_render_scale
#define rscale ivec2(2,2)

// ---------------


// ---------------
//ANGLE

//#define ANGLE_loops 0
#define ANGLE_loops min(iFrame,0)




#define MAX_DIST 1000.
#define MIN_DIST .0001


// OBJ_ is >=0, not negative
#define OBJ_SKY 0
#define OBJ_SPHERE 1
#define OBJ_FLOOR 2
#define OBJ_FLOOR2 3
#define OBJ_FLOOR3 4
#define OBJ_FLOOR4 5
#define OBJ_BOX 6
#define OBJ_BOX2 7
#define OBJ_SPHERE2 8
#define OBJ_SPHERE3 9
#define OBJ_BEZIER1 10

//#define OBJ_CYL_bot 18
//#define OBJ_CYL_top 19
#define OBJ_CYL1 20
#define OBJ_CYL2 21
#define OBJ_CYL3 22
#define OBJ_CYL4 23
#define OBJ_CYL5 24
#define OBJ_CYL6 25

// range 50+ number of repetitions RREP_num - if needed, not used here, id is static OBJ_RR_CYL, look RayTracing_Radial_RepetitionMin
#define OBJ_RR_CYL 50
#define OBJ_RR_CYL2 51
#define OBJ_RR_CYL3 52

//


const vec3 upVec = vec3(0.0, 1.0, 0.0);

#define PI 3.141592653589793
#define TAU 6.283185307179586
#define c_goldenRatioConjugate 0.61803398875f



// Camera related (just to have less code in buffers)
// ---------------
const ivec2 MEMORY_BOUNDARY = ivec2(2, 16); //BufA reserved (and top right pixel)

const ivec2 RES_LAST0 = ivec2(0, 0);
const ivec2 RES_LAST1 = ivec2(0, 1);
const ivec2 INIT0 = ivec2(0, 2);
const ivec2 TARGET0 = ivec2(0, 3);
const ivec2 TARGET1 = ivec2(0, 4);
const ivec2 TARGET2 = ivec2(0, 5);

const ivec2 POSITION0 = ivec2(0, 6);
const ivec2 POSITION1 = ivec2(0, 7);
const ivec2 POSITION2 = ivec2(0, 8);
const ivec2 POSITION_last0 = ivec2(0, 9);
const ivec2 POSITION_last1 = ivec2(0, 10);
const ivec2 POSITION_last2 = ivec2(0, 11);

const ivec2 VMOUSE0 = ivec2(1, 0);
const ivec2 VMOUSE1 = ivec2(1, 1);
const ivec2 VMOUSE2 = ivec2(1, 2);
const ivec2 VMOUSE_last0 = ivec2(1, 3);
const ivec2 VMOUSE_last1 = ivec2(1, 4);

const ivec2 INPUT0 = ivec2(1, 5);
const ivec2 HALTON0 = ivec2(1, 6);
const ivec2 HALTON1 = ivec2(1, 7);
const ivec2 HALTON_last0 = ivec2(1, 8);
const ivec2 HALTON_last1 = ivec2(1, 9);
const ivec2 PMOUSE0 = ivec2(1, 10);
const ivec2 PMOUSE1 = ivec2(1, 11);

const ivec2 LOCAL_T = ivec2(0, 12);
const ivec2 LOCAL_T_last = ivec2(0, 13);
const ivec2 LMC = ivec2(0, 14);

const ivec2 HTARGET0 = ivec2(1, 12);
const ivec2 HTARGET1 = ivec2(1, 13);
const ivec2 HTARGET2 = ivec2(1, 14);

const ivec2 RES_CHANGE = ivec2(1, 15);
const ivec2 INPUT0_timer = ivec2(0, 15);

float load(ivec2 P, sampler2D self){return texelFetch(self, ivec2(P), 0).a;}

mat3 rotx(float a){float s = sin(a);float c = cos(a);return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, c, s), vec3(0.0, -s, c));  }
mat3 roty(float a){float s = sin(a);float c = cos(a);return mat3(vec3(c, 0.0, s), vec3(0.0, 1.0, 0.0), vec3(-s, 0.0, c));}
mat3 rotz(float a){float s = sin(a);float c = cos(a);return mat3(vec3(c, s, 0.0), vec3(-s, c, 0.0), vec3(0.0, 0.0, 1.0 ));}

// Camera
#ifdef move_rounds
float rtimer = 0.;
float rtimer_last = 0.;
#endif
mat3 rotationMatrix(vec2 m){
  mat3 rotX = mat3(1.0, 0.0, 0.0, 0.0, cos(m.y), sin(m.y), 0.0, -sin(m.y), cos(m.y));
  mat3 rotY = mat3(cos(m.x), 0.0, -sin(m.x), 0.0, 1.0, 0.0, sin(m.x), 0.0, cos(m.x));
#ifdef move_rounds
  return roty(-rtimer*rspd)*rotY*rotX;
#else
  return rotY*rotX;
#endif
}

mat3 rotationMatrix_last(vec2 m){
  mat3 rotX = mat3(1.0, 0.0, 0.0, 0.0, cos(m.y), sin(m.y), 0.0, -sin(m.y), cos(m.y));
  mat3 rotY = mat3(cos(m.x), 0.0, -sin(m.x), 0.0, 1.0, 0.0, sin(m.x), 0.0, cos(m.x));
#ifdef move_rounds
  return roty(-rtimer_last*rspd)*rotY*rotX;
#else
  return rotY*rotX;
#endif
}

void SetCamera(vec2 uv, sampler2D caminfo, out vec3 ro, out vec3 rd, vec2 ires)
{
    ro = vec3(load(POSITION0,caminfo),load(POSITION1,caminfo),load(POSITION2,caminfo));
    vec2 m = vec2(load(VMOUSE0,caminfo),load(VMOUSE1,caminfo));
    m.y = -m.y;
    float fov=camera_fov;
    float aspect = ires.x / ires.y;
    float screenSize = (1.0 / (tan(((180.-fov)* (3.1415926 / 180.0)) / 2.0)));
    rd = vec3(uv*screenSize, 1./aspect);
    
    //rd+=0.000001*(1.-abs(sign(rd)));
    rd = normalize(rd);
    rd = rotationMatrix(m) * rd;
}

void SetCamera_prev(vec2 uv, sampler2D caminfo, out vec3 ro, out vec3 rd, vec2 ires)
{
    ro = vec3(load(POSITION_last0,caminfo),load(POSITION_last1,caminfo),load(POSITION_last2,caminfo));
    vec2 m = vec2(load(VMOUSE_last0,caminfo),load(VMOUSE_last1,caminfo));
    m.y = -m.y;
    float fov=camera_fov;
    float aspect = ires.x / ires.y;
    float screenSize = (1.0 / (tan(((180.-fov)* (3.1415926 / 180.0)) / 2.0)));
    rd = vec3(uv*screenSize, 1./aspect);
    
    //rd+=0.000001*(1.-abs(sign(rd)));
    rd = normalize(rd);
    rd = rotationMatrix_last(m) * rd;
}

void SetCamera_m(vec2 uv, vec2 m, out vec3 rd, vec2 ires)
{
    m.y = -m.y;
    float fov=camera_fov;
    float aspect = ires.x / ires.y;
    float screenSize = (1.0 / (tan(((180.-fov)* (3.1415926 / 180.0)) / 2.0)));
    rd = vec3(uv*screenSize, 1./aspect);
    
    //rd+=0.000001*(1.-abs(sign(rd)));
    rd = normalize(rd);
    rd = rotationMatrix(m) * rd;
}

// ---------------



// ---------------

// material by object id
// remember about dFd bugs
// ---------------

void material_OBJ_FLOOR(vec3 pos, vec3 norm, out vec3 albedo, out vec3 emission, 
                        out float roughness, out float metalness){
    albedo = vec3(1.,1.,1.);
    emission = vec3(0.,0.,0.);
    roughness = 0.742531;
    metalness = 0.1521;
}
void material_OBJ_FLOOR4(vec3 pos, vec3 norm, out vec3 albedo, out vec3 emission, 
                        out float roughness, out float metalness){
    albedo = 0.5*vec3(1.,1.,1.);
    emission = vec3(0.,0.,0.);
    roughness = 0.2;
    metalness = 0.9;
}


void material_OBJ_FLOOR2(vec3 pos, vec3 norm, out vec3 albedo, out vec3 emission, 
                        out float roughness, out float metalness){
    float tp = 1.-step(0.2,abs(length(pos.xz)-47.5));
    albedo = mix(vec3(1.,1.,1.),vec3(1.,1.,0.),tp);
    emission = vec3(0.,0.,0.);
    roughness = 0.2531-0.2*tp;
    metalness = 0.521-0.42*tp;
}

void material_OBJ_RRT(vec3 pos, int obj, vec3 norm, out vec3 albedo, out vec3 emission, 
                        out float roughness, out float metalness){
    albedo = vec3(1., 1., 1.)*0.81;
    emission = vec3(0.,0.,0.);
    roughness = 0.6531;
    metalness = 0.7521;
}

void material_OBJ_CYL(vec3 pos, vec3 norm, out vec3 albedo, out vec3 emission, 
                        out float roughness, out float metalness, int obj){
    float a = float(obj!=OBJ_CYL1);
    albedo = vec3(1., 1., 1.)-a*.05;
    emission = vec3(0., 0., 0.);
    roughness = 0.31-0.11*a;
    metalness = 0.17+0.473*a;
    if(obj==OBJ_CYL6||obj==OBJ_CYL1){
        vec2 tuv=0.5+vec2(atan(pos.z,pos.x)/(3.1415926*2.), pos.y);
#ifndef move_SUN_circle_inf
        emission = float(obj==OBJ_CYL6)*7.*vec3(0.75,0.95,1.25)*step(0.8,fract(tuv.x*20.))*step(tuv.x,0.35);
#endif
        if(obj==OBJ_CYL1){
            vec2 p = vec2((fract(tuv.x*11.)-0.5)*5.5,(tuv.y-7.5)*0.25);
            vec2 td = abs(p)-vec2(0.8,0.1);
            float d = length(max(td,0.0)) + min(max(td.x,td.y),0.0);
            float tx=step(abs(d-0.2)-0.12,0.);
            vec3 c = mix(vec3(1., .35, 0.051),vec3(.251, 1., 0.75),float(int(tuv.x*11.)%2));
            vec2 tp = p;tp+=vec2(0.6*(1.-2.*float(int(tuv.x*11.)%2)),0.025);
            p = vec2((fract(tuv.x*600.)-0.5),fract((tuv.y)*2.5)-0.5);
            float tvv = 0.45-0.85*(tp.x*tp.x)-1.282*tp.y;
            float ep = step(length(p),tvv*step(0.15,tvv))*step(tp.y,.12+0.025);
            albedo = mix(mix(vec3(1.),vec3(0.25),ep),c,tx);
            roughness = mix(mix(roughness,0.2,tx),0.15,ep);
#ifndef move_SUN_circle_inf
            emission = 6.*(c*0.5+0.5)*(1.-step(0.,d-0.12))*step(floor(tuv.x*11.),4.5);
#endif
        }
    }
}

vec3 get_normal_OBJ_FLOOR(vec3 pos, vec3 ro){
    return normalize(vec3(0.0,sign(sign(-pos.y+ro.y)+0.001),0.0));
}

vec3 cylNormal(in vec3 p, float ra, float ins);
vec3 get_normal_OBJ_CYL(vec3 pos, float ra, float ins){
    return cylNormal(pos, ra, ins);
}
/*
vec3 get_normal_OBJ_CYL_top(){
    return vec3(0.,1.,0.);
}
vec3 get_normal_OBJ_CYL_bot(){
    return vec3(0.,-1.,0.);
}
*/

// ---------------



// sky
//----------------------------------------------

const float sunAngularDiameter = 2.5;

const float sunIluminance = 1.5;

const float goldenAngle = 2.3999632297286533;

// sky from https://www.shadertoy.com/view/3dlSW7

float hGPhase(float cosTheta, const float g){
	float g2 = g * g;
    
    return 0.25 * (1.0 - g2) * pow(g2 - 2.0 * g * cosTheta + 1.0, -1.5);
}

vec3 calculateSunColor(float sunZenith){
	return mix(vec3(1.0, 0.4, 0.05), vec3(1.0), max(sunZenith, 0.0));
}

// sun dot turned off in this shader - it have bad visible trace on movement when intersect with objects
float calculateSun(float lDotV){return 0.;}
/*
float calculateSun(float lDotV){
    const float cosRad = cos(radians(sunAngularDiameter));
    const float sunLuminance = sunIluminance / ((1.0 - cosRad) * TAU);
    
    return smoothstep(cosRad,cosRad*1.001, lDotV) * sunLuminance;
}
*/

vec3 calculateSky(vec3 background, float lDotU, float lDotV){
    float phaseMie = hGPhase(lDotV, 0.8);
    
    float zenith = max(lDotU, 0.0);
    
    float sunZenith = lightDir.y;
    const vec3 topCol = vec3(0.1, 0.34, 1.0);
    
    const vec3 bottomCol = 0.8+0.2*vec3(0.1, 0.34, 1.0);
    //const vec3 bottomCol = vec3(1.0);
    
    vec3 sky = mix(topCol, (bottomCol + topCol), exp2(-zenith * 8.0));
         sky += phaseMie * exp2(-zenith * 6.0);
    
    vec3 absorbColor = calculateSunColor(1.0 - exp2(-zenith * 2.0));
    
    sky = sky * mix(absorbColor * 0.9 + 0.1, vec3(1.0), sunZenith);
	return background * absorbColor + sky * sunIluminance * (1.0 - clamp(-sunZenith * 10.0, 0.0, 1.0));	
}

//----------------------------------------------



// pathtracing functions
//----------------------------------------------

// with ConeVector better visual result
// ConeVector distribution, look this screenshots
// https://danilw.github.io/GLSL-howto/vulkan_sh_launcher/upl_demos/pathtracer/ray_distr1.jpg
// https://danilw.github.io/GLSL-howto/vulkan_sh_launcher/upl_demos/pathtracer/ray_distr2.png
#ifdef use_ConeVector

mat3 calculateTangentMatrix(vec3 direction){
	vec3 c1 = cross(direction, vec3(0.0, 0.0, 1.0));
	vec3 c2 = cross(direction, vec3(0.0, 1.0, 0.0));
    
    vec3 tangent = dot(c1, c1) > dot(c2, c2) ? c1 : c2;
    vec3 biDir = cross(direction, tangent);
    
    return mat3(tangent, biDir, direction);
}

vec3 calculateConeVector(const float i, const float angularRadius, const int steps) {
    float x = i * 2.0 - 1.0;
    float y = i * float(steps) * 16.0 * 16.0 * goldenAngle;
    
    float angle = acos(x) * radians(angularRadius) * 1./PI;
    float c = cos(angle);
    float s = sin(angle);

    return vec3(cos(y) * s, sin(y) * s, c);
}

vec3 calculateRoughSpecular(const float i, const int steps, float roughness) {
    float r = roughness * roughness * roughness * roughness;
    float x = (r * i) / max(1.0 - i,0.0001);
    float y = i * float(steps) * 16.0 * 16.0 * goldenAngle;
    //if(1.0 - i<0.)
    //x = (r * i)*1000.;
    float c = inversesqrt(x + 1.0);
    float s = sqrt(x) * c;

    return vec3(cos(y) * s, sin(y) * s, c);
}

#else

// CosineWeightedSample

float seed;
float hash11_seed()
{
    float p=seed;
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    seed+=1.33;
    return fract(p);
}

vec3 ortho(vec3 v) {
  return abs(v.x) > abs(v.z) ? vec3(-v.y, v.x, 0.0)  : vec3(0.0, -v.z, v.y);
}

vec3 getCosineWeightedSample(vec3 dir, float radius) {
	vec3 o1 = normalize(ortho(dir));
	vec3 o2 = normalize(cross(dir, o1));
	vec2 r = vec2(hash11_seed(), hash11_seed());
	r.x = r.x * 2.0 * PI;
	r.y = pow(r.y, radius);
	float oneminus = sqrt(abs(1.0-r.y*r.y));
	return cos(r.x) * oneminus * o1 + sin(r.x) * oneminus * o2 + r.y * dir;
}


#endif
//----------------------------------------------

// reprojection
//----------------------------------------------

vec2 pos2uv(vec3 pos, sampler2D caminfo, vec2 ires){
    vec3 ro_old = vec3(load(POSITION_last0,caminfo),load(POSITION_last1,caminfo),load(POSITION_last2,caminfo));
    vec2 m_old = vec2(load(VMOUSE_last0,caminfo),load(VMOUSE_last1,caminfo))*vec2(1.,-1.);
    vec3 td = pos - ro_old;
    if(length(td)<0.0001)return vec2(-1.);
    vec3 dir = normalize(td) * (rotationMatrix_last(m_old));
    float fov=camera_fov;
    float aspect = ires.x / ires.y;
    float screenSize = (1.0 / (tan(((180.-fov)* (3.1415926 / 180.0)) / 2.0)));
    dir.z+=0.0001*(1.-abs(sign(dir.z)));
    return dir.xy * (.5/screenSize) / dir.z ;
}

float distancePixel( vec2 prevFragCoord, vec3 pos, sampler2D samplerx, vec2 ires, vec3 p_ro, vec3 p_rd){
    if(  min(ires.xy-1., prevFragCoord) != prevFragCoord
      || max(vec2(0.)      , prevFragCoord) != prevFragCoord) return MAX_DIST;
    
    float prev_d = textureLod(samplerx, prevFragCoord/ires.xy,0.).b;
    vec3 prevPos = p_ro + p_rd*prev_d;
    return length(prevPos-pos);
}


#define PixelAcceptance 4.
#define PixelCheckDistance .5
vec4 previousSample(vec3 ro, vec3 pos, sampler2D caminfo, sampler2D last_pos_fbo, sampler2D last_color, vec2 ires){
    vec2 old_halton_px_shift=vec2(load(HALTON_last0,caminfo),load(HALTON_last1,caminfo));
    vec2 prevUv = pos2uv(pos, caminfo, ires) - old_halton_px_shift/ires.y;
    vec2 prevFragCoord = prevUv * ires.y + ires.xy/2.0;
    
    vec2 pfc=vec2(0.);
    vec2 finalpfc=vec2(0.);
    float dist, finaldist = MAX_DIST;
    for(int x = -1; x <= 1; x++){
        for(int y = -1; y <= 1; y++){
            pfc = prevFragCoord + PixelCheckDistance*vec2(x, y);
            vec2 tuv = pfc/ires.xy * 2.0 - 1.0;
            tuv.y *= ires.y/ires.x;
            vec3 p_ro;
            vec3 p_rd;
            SetCamera_prev( tuv, caminfo, p_ro, p_rd, ires);
            dist = distancePixel(pfc, pos, last_pos_fbo, ires, p_ro, p_rd);
            if(dist < finaldist){
                finalpfc = pfc;
                finaldist = dist;
            }
      }
    }
    
    if(finaldist < (PixelAcceptance/ires.y)*(length(pos-ro)))
        return textureLod(last_color, finalpfc/ires.xy,0.);
    return vec4(0.);
}

//----------------------------------------------






// intersection template
//----------------------------------------------

struct HitInfo {
    float t;
    vec3 norm;
    vec4 color;
    vec3 emisson;
    float rough;
    float metal;
    int obj_type;
};


bool boxAABB(in vec3 dims, vec3 ro, vec3 rd) {
    rd += 0.0001 * (1.0 - abs(sign(rd)));
    vec3 n = ro / rd;
    vec3 k = dims / abs(rd);
    vec3 t1 = -k - n, t2 = k - n;
    float tN = max(max(t1.x, t1.y), t1.z);
    float tF = min(min(t2.x, t2.y), t2.z);
    return tN < tF && tF > 0.0;
}

bool PlaneIntersect(vec4 Plane, vec3 ro, vec3 rd, out float t, out vec3 norm) {
    norm=vec3(0.,1.,0.);
    t=-1.;
    float dd = dot(rd, Plane.xyz);
    if (dd == 0.0) return false;
    float t1 = -(dot(ro, Plane.xyz) + Plane.w) / dd;
    if (t1 < 0.0) return false;
    norm = normalize(Plane.xyz);
    t = t1;
    return true;
}

vec3 cylNormal( in vec3 p, float ra, float ins)
{
    vec3 a=vec3(0.,1.,0.);
    vec3 b=vec3(0.,-1.,0.);
    vec3  pa = p - a;
    vec3  ba = b - a;
    float baba = dot(ba,ba);
    float paba = dot(pa,ba);
    float h = dot(pa,ba)/baba;
    return ins*(pa - ba*h)/ra;
}

bool CylinderInfIntersect( in vec3 ro, in vec3 rd, in float ra, vec3 ca, out float tN, out vec3 norm, float ins) 
{
    norm=vec3(0.,1.,0.);
    tN=MAX_DIST;
    vec3  oc = ro;
    float card = dot(ca,rd);
    float caoc = dot(ca,oc);
    float a = 1.0 - card*card;
    float b = dot( oc, rd) - caoc*card;
    float c = dot( oc, oc) - caoc*caoc - ra*ra;
    float h = b*b - a*c;
    if( h<0.0 ) return false;
    h = ins*sqrt(h);
    float t=(-b-h)/a;
    if( t<0.0 ) return false;
    tN=t;
    norm=cylNormal( ro+tN*rd, ra, ins);
    return true;
}

void CylinderInfIntersectMin(vec3 ro, vec3 rd, float rad, float heigh, vec3 opos, int obj, inout bool result, inout HitInfo hit, float ins) {
    float tnew;
    vec3 normnew;
    ro -= opos;
    if (CylinderInfIntersect(ro, rd, rad, vec3(0.,1.,0.), tnew, normnew, ins)) {
        if (tnew < hit.t) {
            vec3 pos = ro+rd*tnew;
            if(abs(pos.y)>heigh){
                return;
            }
            
            hit.t = tnew;
            hit.norm = normnew;
            hit.emisson = vec3(0.,0.,0.);
            vec3 albedo;
            material_OBJ_CYL(pos+opos, hit.norm,  albedo, hit.emisson, hit.rough, hit.metal, obj);
            hit.color = vec4(albedo, 1.);
            hit.obj_type = obj;
            result = true;
        }
    }
}


void GroundIntersectMin(vec3 ro, vec3 rd, inout bool result, inout HitInfo hit, int obj, vec2 r) {
    float tnew;
    vec3 normnew;
    vec4 pp=vec4(normalize(vec3(0.0, 1., 0.0)), 0.);
    
    // sunlight_2nd_bounce can be buggere here - visual bugs on floor
    // +vec3(0.,1.,0.) - change y component to bigger, I do it in minDist, no idea why
    
    if (PlaneIntersect(pp, ro+vec3(0.,1.,0.), rd, tnew, normnew)) {
        if (tnew < hit.t) {
            if ((step(r.x,length((ro+rd*tnew).xz))<0.5) && (step(r.y,length((ro+rd*tnew).xz))>0.5)) {
                hit.t = tnew;
                hit.norm = normnew;

                hit.emisson = vec3(0.,0.,0.);
                vec3 albedo;
                if(obj==OBJ_FLOOR4)material_OBJ_FLOOR4(ro+rd*hit.t, hit.norm,  albedo, hit.emisson, hit.rough, hit.metal);
                else{
                if(obj==OBJ_FLOOR2)
                material_OBJ_FLOOR2(ro+rd*hit.t, hit.norm,  albedo, hit.emisson, hit.rough, hit.metal);
                else
                material_OBJ_FLOOR(ro+rd*hit.t, hit.norm,  albedo, hit.emisson, hit.rough, hit.metal);
                }
                hit.color = vec4(albedo, 1.);
                hit.obj_type = obj;
                result = true;
            }
        }
    }
}



// base on RayTracing Radial Repetition 
// https://www.shadertoy.com/view/stKcWD

struct its
{
	float t;
	vec3 n;    //normal 
	
};
const its  NO_its=its(MAX_DIST,vec3(0.,1.,0.));

struct span
{
	its n;
	its f;
    bool next;
};

span iPlane( in vec3 ro, in vec3 rd, in vec3 n ,float h)
{
    float d1= -dot(ro,n)/dot(rd,n),   d2= -(dot(ro-h*n,n))/dot(rd,n);
    vec3  u = normalize(cross(n,vec3(0,0,1))), v = normalize(cross(u,n) );
    vec3 oNor=n;
    if(d1<d2) return span(its(d1,-oNor),its(d2,oNor),false);
    return span(its(d2,oNor),its(d1,-oNor),false);
}

span iCylinder( in vec3 ro, in vec3 rd, in vec3 ca, float cr )
{
    vec3  oc = ro ;
    float card = dot(ca,rd);
    float caoc = dot(ca,oc);
    float a = 1.0 - card*card;
    float b = dot( oc, rd) - caoc*card;
    float c = dot( oc, oc) - caoc*caoc - cr*cr;
    float h = b*b - a*c;
    if( h<0.0 ) return span(NO_its,NO_its,false); //no intersection
    h = sqrt(h);
    vec2 t =vec2(-b-h,-b+h)/a;
    vec2 d= vec2(dot(oc +t.x*rd,ca) ,dot(oc +t.y*rd,ca) );
    vec3 nN=normalize( oc +t.x*rd -d.x*ca),nF=normalize( oc +t.y*rd -d.y*ca);
    its iN= its( t.x, nN); //todo uv
    its iF= its( t.y, nF);
    return  span(iN , iF,false );   
}

span Inter(span a, span b)
{
   
   bvec4 cp = bvec4(a.n.t<b.n.t,a.n.t<b.f.t,a.f.t<b.n.t,a.f.t<b.f.t);
   if(b.n.t==MAX_DIST || a.n.t==MAX_DIST) return span(NO_its,NO_its,false);
   else if(cp.x && cp.z) return span(NO_its,NO_its,false);
   else if(cp.x && !cp.z && cp.w)  return span(b.n,a.f,false);
   else if(cp.x && !cp.z && !cp.w) return b;
   else if(!cp.x && cp.y &&  cp.w) return a;
   else if(!cp.x && cp.y &&  !cp.w) return span(a.n,b.f,false);
   else return span(NO_its,NO_its,false);
}

span Sub(span a, span b)
{

   bvec4 cp = bvec4(a.n.t<b.n.t,a.n.t<b.f.t,a.f.t<b.n.t,a.f.t<b.f.t); 
    if(a.n.t==MAX_DIST) return span(NO_its,NO_its,false);
    else if(b.n.t==MAX_DIST) return a;   
   else if(cp.x && cp.z) return a;
   else if(cp.x && !cp.z && cp.w)  return span(a.n,b.n,false);
   else if(cp.x && !cp.z && !cp.w && b.n.t>0.) return span(a.n,b.n,true); 
   else if(cp.x && !cp.z && !cp.w && b.n.t<0.) return span(b.f,a.f,false); //+ secondary span =  span(b.f,a.f)
   else if(!cp.x && cp.y && cp.w) return span(NO_its,NO_its,false);
   else if(!cp.x && cp.y && !cp.w) return span(b.f,a.f,false);
   else return a;
   
}


vec3 opU( vec3 d, span s, inout vec3 normal, float mat ) {
    its ix= s.n;   
    //if(ix.t<0.) ix=s.f;
    if( ix.t<d.y && ix.t>d.x) {
        normal=ix.n;
        d=vec3(d.x, ix.t, mat);
    }
	return d;
}

vec3 RayTracing_Radial_Repetition( in vec3 ro, in vec3 rd, out vec3 normal, vec4 prm, float rtc) {
    float RREP_tk = prm.x;
    float RREP_num = prm.y;
    float RREP_r = prm.z;
    float RREP_h = prm.w;
    
    float RREP_thc = rtc*RREP_r*2./RREP_num;
    vec3  d_ret = vec3(MIN_DIST, MAX_DIST, 0.);
        
    span s2,s3,s4;
    
    s2= iCylinder(ro,rd, vec3(0,1,0), RREP_r+RREP_tk );
    s3= iPlane(ro,rd,vec3(0,1.,0),RREP_h);
    s2= Inter(s2,s3);
    s4= iCylinder(ro,rd, vec3(0,1,0), RREP_r-RREP_tk );

    //backward disk intersection
    span s5=span(s4.f,s2.f,false);
    float d2=s4.f.t;
    
    //front disk intersection
    s2=Sub(s2,s4);
    
    // outside of cylinder - can be removed if visual impact minimal
    
    if(s2.n.t<MAX_DIST  ){
         vec2 p =  s2.n.t<0.? ro.xz:
             (ro+rd*s2.n.t).xz;
         float an = atan(p.y,p.x)+PI,
               id= floor(an/TAU*RREP_num),
               anc=(id+.5)/RREP_num*TAU,
               sg= sign(dot(vec2(-sin(anc),cos(anc)),rd.xz));
          // this for loop - 2 iterations may be not enough - visible transparent steps on RREP_num=6 
          for(int i=0; i<2;i++){ 
             vec3 nm= vec3(sin(anc),0.,-cos(anc)); s3=iPlane(ro+nm*RREP_thc*0.5,rd,nm,RREP_thc);           
             s4=Inter(s2,s3);             
             d_ret= opU(  d_ret,  s4,normal , id);
             anc-=sg/RREP_num*TAU;
             id-=sg;
             if(id>=RREP_num)id = 0.;
             if(id<0.)id = RREP_num-1.;
         }     
     }
     
     // inside of cylinder - can be removed if visual impact minimal
     /*
     if(s2.n.t<MAX_DIST  && s2.next){
         vec2 p = (ro+rd*d2).xz;
         float an = atan(p.y,p.x)+PI,
               id= floor(an/TAU*RREP_num),
               anc=(id+.5)/RREP_num*TAU,
               sg= sign(dot(vec2(-sin(anc),cos(anc)),rd.xz));
          for(int i=0; i<2;i++){ 
             vec3 nm= vec3(sin(anc),0.,-cos(anc)); s3=iPlane(ro+nm*RREP_thc*0.5,rd,nm,RREP_thc);
             s4=Inter(s5,s3);
             d_ret= opU(  d_ret,  s4,normal , id);
             anc-=sg/RREP_num*TAU;
             id-=sg;
             if(id>=RREP_num)id = 0.;
             if(id<0.)id = RREP_num-1.;
          }      
      
    }
    */
    if(dot(rd,normal)>0.) normal=-normal;
    d_ret.z+=0.5;
    return d_ret;
}

void RayTracing_Radial_RepetitionMin(vec3 ro, vec3 rd, inout bool result, inout HitInfo hit, vec4 prm, float rtc, int obj) {
    float tnew;
    vec3 normnew;
    vec3 rrt = RayTracing_Radial_Repetition(ro, rd, normnew, prm, rtc);
    tnew = rrt.y;
    if (tnew < hit.t) {
        hit.t = tnew;
        hit.norm = normnew;
        vec3 albedo;
        material_OBJ_RRT(ro+rd*hit.t, obj, hit.norm,  albedo, hit.emisson, hit.rough, hit.metal);

        hit.color = vec4(albedo, 1.);
        hit.obj_type = obj; //+int(rrt.z); //ID is +0.5 and +OBJ_RR_CYL - if needed
        result = true;
    }
}

//----------------------------------------------



// render NOT OPTIMIZED
// can be optimized by separating normal/albedo calculation and hit(bool)
// by making two functions, one used by shadows other by pathtracing
// look get_scene_ 
//----------------------------------------------

const float RREP_tk1=.065;
const float RREP_num1=900.;
const float RREP_r1 = 50.-RREP_tk1*0.85;
const float RREP_h1 = 1.;
const float RREP_rtc1 = 0.35;
const vec3 RR1pos = vec3(0., -5., 0.);
const vec4 RR1prm = vec4(RREP_tk1, RREP_num1, RREP_r1, RREP_h1);

const float RREP_tk2=.75;
const float RREP_num2=50.;
const float RREP_r2 = 58.;
const float RREP_h2 = 300.;
const float RREP_rtc2 = .5;
const vec3 RR2pos = vec3(0., 150., 0.);
const vec4 RR2prm = vec4(RREP_tk2, RREP_num2, RREP_r2, RREP_h2);

const float RREP_tk3=.7;
const float RREP_num3=800.;
const float RREP_r3 = 45.75;
const float RREP_h3 = .15;
const float RREP_rtc3 = 1.;
const vec3 RR3pos = vec3(0., -5., 0.);
const vec4 RR3prm = vec4(RREP_tk3, RREP_num3, RREP_r3, RREP_h3);

const vec2 TTor = vec2(44.0,0.5);
const vec3 TTor_pos=vec3(0.,-5.25,-0.);

bool minDist(vec3 ro, vec3 rd, out HitInfo hit)
{
    hit.t = MAX_DIST;
    hit.obj_type = OBJ_SKY;
    hit.norm = vec3(0.,1.,0.);
    
    float lDotU = dot(rd, upVec);
    float lDotV = dot(rd, lightDir);
    
    hit.color=vec4(calculateSky(calculateSun(lDotV)*calculateSunColor(lightDir.y), lDotU, lDotV),1.);
    hit.emisson = vec3(0.,0.,0.);
    bool result = false;


    GroundIntersectMin(ro+vec3(.0, -6., .0), rd, result, hit, OBJ_FLOOR, vec2(50.,0.001));
    GroundIntersectMin(ro+vec3(.0, -6.-.35, .0), rd, result, hit, OBJ_FLOOR2, vec2(50.,47.));
    GroundIntersectMin(ro+vec3(.0, -6.-4.5, .0), rd, result, hit, OBJ_FLOOR3, vec2(50.,0.001));
    
    GroundIntersectMin(ro+vec3(.0, -6.-.25, .0), rd, result, hit, OBJ_FLOOR4, vec2(46.2,46.1));    
    GroundIntersectMin(ro+vec3(.0, -6.-.25, .0), rd, result, hit, OBJ_FLOOR4, vec2(45.4,45.3));    


    CylinderInfIntersectMin(ro, rd,44.2,4.47,vec3(0.,5.,0.),OBJ_CYL1,result, hit, 1.);
    
    CylinderInfIntersectMin(ro, rd,46.2,.05,vec3(0.,5.2,0.),OBJ_CYL2,result, hit, 1.);
    CylinderInfIntersectMin(ro, rd,46.1,.05,vec3(0.,5.2,0.),OBJ_CYL3,result, hit, -1.);
    
    CylinderInfIntersectMin(ro, rd,45.4,.05,vec3(0.,5.2,0.),OBJ_CYL4,result, hit, 1.);
    CylinderInfIntersectMin(ro, rd,45.3,.05,vec3(0.,5.2,0.),OBJ_CYL5,result, hit, -1.);
    
    CylinderInfIntersectMin(ro, rd,47.3,.3485,vec3(0.,5.,0.),OBJ_CYL6,result, hit, -1.);
    
    RayTracing_Radial_RepetitionMin(ro+RR1pos, rd, result, hit, RR1prm, RREP_rtc1, OBJ_RR_CYL);
    RayTracing_Radial_RepetitionMin(ro+RR2pos, rd, result, hit, RR2prm, RREP_rtc2, OBJ_RR_CYL2);
    RayTracing_Radial_RepetitionMin(ro+RR3pos, rd, result, hit, RR3prm, RREP_rtc3, OBJ_RR_CYL3);

    
    
    return result;
}

//----------------------------------------------


// noise https://www.shadertoy.com/view/7sGBzW
// hash https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash21(float p)
{
	vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}
vec3 hash33(vec3 p3)
{
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}


// saved in BufA as alpha
float Bnoise(vec2 U) {
    float v = 0.;
    for (int k=0; k<9; k++)
        v += hash12( U + vec2(k%3-1,k/3-1) ); 
    v=.9 *( 1.125*hash12(U)- v/8.) + .5;
    //return clamp(v,0.,1.);
    //return fract(abs(v));
    return v < 0. ? -v : v > 1. ? 2.-v : v ;
}

// halton low discrepancy sequence, from https://www.shadertoy.com/view/wdXSW8
void halton_loop(inout vec2 s, inout vec4 a){
    const vec2 coprimes = vec2(2.0f, 3.0f);
    a.xy = a.xy/coprimes;
    a.zw += a.xy*mod(s, coprimes);
    s = floor(s/coprimes);
}
vec2 halton (int index){
    vec2 s = vec2(index, index);
	vec4 a = vec4(1,1,0,0);
    if (s.x > 0. && s.y > 0.)halton_loop(s, a);
    if (s.x > 0. && s.y > 0.)halton_loop(s, a);
    if (s.x > 0. && s.y > 0.)halton_loop(s, a);
    if (s.x > 0. && s.y > 0.)halton_loop(s, a);
    if (s.x > 0. && s.y > 0.)halton_loop(s, a);
    if (s.x > 0. && s.y > 0.)halton_loop(s, a);
    if (s.x > 0. && s.y > 0.)halton_loop(s, a);
    if (s.x > 0. && s.y > 0.)halton_loop(s, a);
    return a.zw;
}



// https://www.shadertoy.com/view/3ddfDj
vec4 biplanar( sampler2D sam, in vec3 p, in vec3 n, vec3 dpdx, vec3 dpdy )
{
    n = abs(n);

    // major axis (in x; yz are following axis)
    ivec3 ma = (n.x>n.y && n.x>n.z) ? ivec3(0,1,2) :
               (n.y>n.z)            ? ivec3(1,2,0) :
                                      ivec3(2,0,1) ;
    // minor axis (in x; yz are following axis)
    ivec3 mi = (n.x<n.y && n.x<n.z) ? ivec3(0,1,2) :
               (n.y<n.z)            ? ivec3(1,2,0) :
                                      ivec3(2,0,1) ;
        
    // median axis (in x;  yz are following axis)
    ivec3 me = ivec3(3) - mi - ma;
    
    // project+fetch
    vec4 x = textureGrad( sam, vec2(   p[ma.y],   p[ma.z]), 
                               vec2(dpdx[ma.y],dpdx[ma.z]), 
                               vec2(dpdy[ma.y],dpdy[ma.z]) );
    vec4 y = textureGrad( sam, vec2(   p[me.y],   p[me.z]), 
                               vec2(dpdx[me.y],dpdx[me.z]),
                               vec2(dpdy[me.y],dpdy[me.z]) );
    
    // blend and return
    vec2 m = vec2(n[ma.x],n[me.x]);
    m = clamp( (m-0.5773)/(1.0-0.5773), 0.0, 1.0 );

	return (x*m.x + y*m.y) / (m.x + m.y);
}

vec4 triplanar( sampler2D sam, in vec3 p, in vec3 n, vec3 dpdx, vec3 dpdy )
{
	vec4 x = texture( sam, p.yz );
	vec4 y = texture( sam, p.zx );
	vec4 z = texture( sam, p.xy );
    
    vec3 m = pow( abs(n), vec3(8.0) );
	return (x*m.x + y*m.y + z*m.z)/(m.x+m.y+m.z);
}



// https://www.shadertoy.com/view/Nls3Rn

#define pack_Snormfloat3x10(x) uintBitsToFloat(packSnorm3x10(x))
#define unpack_Snormfloat3x10(x) unpackSnorm3x10(floatBitsToUint(x))
//#define pack_Unormfloat3x10(x) uintBitsToFloat(packSnorm3x10((x-0.5)*2.))
//#define unpack_Unormfloat3x10(x) (unpackSnorm3x10(floatBitsToUint(x))/2.+0.5)

// NOTE - Unormfloat3x10 above result noticeable "jump" when color~=0.5
// Unormfloat3x10 will down/upscale 0.5+-0.001 to 0.5
// look last few lines in BufB where pack_Unormfloat3x10 used for TAA feedback

// As solution I use only >0 region of Snorm

#define pack_Unormfloat3x10(x) uintBitsToFloat(packSnorm3x10(x))
#define unpack_Unormfloat3x10(x) (unpackSnorm3x10(floatBitsToUint(x)))

uint packSnorm3x10(vec3 x) {
    x = clamp(x,-1., 1.) * 511.;
    uvec3 sig = uvec3(mix(vec3(0), vec3(1), greaterThanEqual(sign(x),vec3(0))));
    uvec3 mag = uvec3(abs(x));
    uvec3 r = sig.xyz << 9 | mag.xyz;
    return r.x << 22 | r.y << 12 | r.z << 2;
}

vec3 unpackSnorm3x10(uint x) {
    uvec3 r = (uvec3(x) >> uvec3(22, 12, 2)) & uvec3(0x3FF);
    uvec3 sig = r >> 9;
    uvec3 mag = r & uvec3(0x1FF);
    vec3 fsig = mix(vec3(-1), vec3(1), greaterThanEqual(sig, uvec3(1)));
    vec3 fmag = vec3(mag) / 511.;
    return fsig * fmag;
}

#ifdef add_clouds
#ifdef cloud_render_scale
vec3 texture_Bilinear( sampler2D c, vec2 t )
{
    const int fx = 1;
    ivec2 res = textureSize(c,0).xy/rscale;
    vec2 p = vec2(res-fx)*t - 0.5+float(fx);
    vec2 f = fract(p);
    ivec2 i = ivec2(p);

    return mix(mix(unpack_Unormfloat3x10(texelFetch(c,clamp(i+ivec2(0,0),ivec2(0),res-1),0).a),
                   unpack_Unormfloat3x10(texelFetch(c,clamp(i+ivec2(1,0),ivec2(0),res-1),0).a), f.x),
               mix(unpack_Unormfloat3x10(texelFetch(c,clamp(i+ivec2(0,1),ivec2(0),res-1),0).a),
                   unpack_Unormfloat3x10(texelFetch(c,clamp(i+ivec2(1,1),ivec2(0),res-1),0).a), f.x), f.y);
}
#endif
#endif


// https://www.shadertoy.com/view/NtXyD8
// thanks to https://www.wolframalpha.com/input?i=2.51y%5E2%2B.03y%3Dx%282.43y%5E2%2B.59y%2B.14%29+solve+for+y
vec3 ACES_Inv(vec3 x) {
    x = clamp(x, 0., 1.);
    return (sqrt(-10127.*x*x + 13702.*x + 9.) + 59.*x - 3.) / (502. - 486.*x); 
}

vec3 ACESFilm( vec3 x )
{
    float tA = 2.51;
    float tB = 0.03;
    float tC = 2.43;
    float tD = 0.59;
    float tE = 0.14;
    return clamp((x*(tA*x+tB))/(x*(tC*x+tD)+tE),0.0,1.0);
}

float angle2d(vec2 c, vec2 e) {
    float theta = atan(e.y-c.y, e.x-c.x);
    return theta;
}
mat2 MD(float a){float s = sin( a );float c = cos( a );return mat2(vec2(c, -s), vec2(s, c));}


