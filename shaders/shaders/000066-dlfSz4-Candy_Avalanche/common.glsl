// Common (common) — Candy Avalanche by fenix
// https://www.shadertoy.com/view/dlfSz4

// constants
const float PI = 3.141592653589793;
const float PARTICLE_SIZE = .08;
const float FAR_CLIP = 1e6;

// PARTICLES

// returns the ids of the four closest particles from the input
ivec4 fxGetClosestImpl(sampler2D sampler, ivec2 xy)
{
    return ivec4(texelFetch(sampler, xy, 0));
}

#define fxGetClosest(X) fxGetClosestImpl(iChannel1, X)

// enable for speed if your particle update is too slow
// this helps it two ways: faster update per particle, plus,
// less stable so more particles fall off the screen
#define EIGHT_NBS 0

#if EIGHT_NBS
#define L_NEIGHBORS 0
#define R_NEIGHBORS 1
#define POS 2
#define RPOS 3
#define VEL 4
#define NUM_PARTICLE_DATA_TYPES 5
#else
#define UL_NEIGHBORS 0
#define UR_NEIGHBORS 1
#define LL_NEIGHBORS 2
#define LR_NEIGHBORS 3
#define POS 4
#define RPOS 5
#define VEL 6
#define NUM_PARTICLE_DATA_TYPES 7
#endif

// returns the location of the particle within the particle buffer corresponding with the input id 
ivec2 fxLocFromID(int width, int id, int dataType)
{
    int index = id * NUM_PARTICLE_DATA_TYPES + dataType;
    return ivec2( index % width, index / width);
}

struct fxParticle
{
    vec3 pos;
    vec3 vel;
    vec3 rPos;
#if EIGHT_NBS
    ivec4 nbs[2];
#else
    ivec4 nbs[4];
#endif
};

// get the particle corresponding to the id
fxParticle fxGetParticleImpl(sampler2D sampler, int resolutionWidth, int id)
{
#if EIGHT_NBS
    vec4 particleData0 = texelFetch(sampler, fxLocFromID(resolutionWidth, id, L_NEIGHBORS), 0);
    vec4 particleData1 = texelFetch(sampler, fxLocFromID(resolutionWidth, id, R_NEIGHBORS), 0);
    vec4 particleData2 = texelFetch(sampler, fxLocFromID(resolutionWidth, id, POS), 0);
    vec4 particleData3 = texelFetch(sampler, fxLocFromID(resolutionWidth, id, RPOS), 0);
    vec4 particleData4 = texelFetch(sampler, fxLocFromID(resolutionWidth, id, VEL), 0);

    fxParticle particle;
    particle.nbs[0] = ivec4(particleData0);
    particle.nbs[1] = ivec4(particleData1);
    particle.pos = particleData2.xyz;
    particle.rPos = particleData3.xyz;
    particle.vel = particleData4.xyz;
#else
    vec4 particleData0 = texelFetch(sampler, fxLocFromID(resolutionWidth, id, UL_NEIGHBORS), 0);
    vec4 particleData1 = texelFetch(sampler, fxLocFromID(resolutionWidth, id, UR_NEIGHBORS), 0);
    vec4 particleData2 = texelFetch(sampler, fxLocFromID(resolutionWidth, id, LL_NEIGHBORS), 0);
    vec4 particleData3 = texelFetch(sampler, fxLocFromID(resolutionWidth, id, LR_NEIGHBORS), 0);
    vec4 particleData4 = texelFetch(sampler, fxLocFromID(resolutionWidth, id, POS), 0);
    vec4 particleData5 = texelFetch(sampler, fxLocFromID(resolutionWidth, id, RPOS), 0);
    vec4 particleData6 = texelFetch(sampler, fxLocFromID(resolutionWidth, id, VEL), 0);

    fxParticle particle;
    particle.nbs[0] = ivec4(particleData0);
    particle.nbs[1] = ivec4(particleData1);
    particle.nbs[2] = ivec4(particleData2);
    particle.nbs[3] = ivec4(particleData3);
    particle.pos = particleData4.xyz;
    particle.rPos = particleData5.xyz;
    particle.vel = particleData6.xyz;
#endif

    return particle;
}

#define fxGetParticle(X) fxGetParticleImpl(iChannel0, int(iResolution.x), X)

vec4 fxSaveParticle(fxParticle p, int dataType)
{    
    switch(dataType)
    {
#if EIGHT_NBS
    case L_NEIGHBORS:
        return vec4(p.nbs[0]);
    case R_NEIGHBORS:
        return vec4(p.nbs[1]);
#else
    case UL_NEIGHBORS:
        return vec4(p.nbs[0]);
    case UR_NEIGHBORS:
        return vec4(p.nbs[1]);
    case LL_NEIGHBORS:
        return vec4(p.nbs[2]);
    case LR_NEIGHBORS:
        return vec4(p.nbs[3]);
#endif
    case POS:  
        return vec4(p.pos, 0);
    case RPOS:  
        return vec4(p.rPos, 0);
    case VEL:  
        return vec4(p.vel, 0);
    }
}

vec4 fxGetParticleDataImpl(sampler2D sampler, int resolutionWidth, int id, int dataType)
{
    return texelFetch(sampler, fxLocFromID(resolutionWidth, id, dataType), 0);
}

#define fxGetParticleData(X, Y) fxGetParticleDataImpl(iChannel0, int(iResolution.x), X, Y)

// global variables, initialized via computeMaxParticles
const int IDEAL_MAX_PARTICLES = 40000;
int MAX_PARTICLES = IDEAL_MAX_PARTICLES; // how many particles, total

// computes the real number of particles that we can simulate in case our buffer isn't big enough
void computeMaxParticles(vec3 res)
{
    MAX_PARTICLES = IDEAL_MAX_PARTICLES;
    MAX_PARTICLES = min(MAX_PARTICLES, int(res.x * res.y) / NUM_PARTICLE_DATA_TYPES);
}

// PERSISTENT STATE

struct fxState
{
    float resolution;
    float chuteX;
    float chuteVel;
    float lastMouseX;
    float camDist;
};

void fxInitStateImpl(inout fxState state, vec3 iResolution)
{
    state.resolution = -iResolution.x * iResolution.y;
    state.chuteX = 0.;
    state.chuteVel = 0.05;
    state.lastMouseX = 0.;
    state.camDist = 10.;
}

#define fxInitState(state) fxInitStateImpl(state, iResolution)

fxState fxGetStateImpl(sampler2D sampler, int iFrame, vec3 iResolution)
{
    vec4 data0 = texelFetch(sampler, ivec2(0, 0), 0);
    vec4 data1 = texelFetch(sampler, ivec2(1, 0), 0);
    
    fxState state;
    state.resolution = data0.x;
    state.chuteX = data0.y;
    state.chuteVel = data0.z;
    state.lastMouseX = data0.w;
    state.camDist = data1.x;
    
    if (iFrame == 0 || abs(state.resolution) != iResolution.x * iResolution.y)
        fxInitStateImpl(state, iResolution);
        
    return state;
}


#define fxGetState() fxGetStateImpl(iChannel1, iFrame, iResolution)

vec4 fxPutState(fxState state, ivec2 ifc)
{
    if (ifc == ivec2(0))
        return vec4(state.resolution, state.chuteX, state.chuteVel, state.lastMouseX);
    else
        return vec4(state.camDist, 0, 0, 0);
}

// CAMERA

void fxCalcCamera(fxState state, out vec3 cameraLookAt, out vec3 cameraPos, out vec3 cameraFwd, out vec3 cameraLeft, out vec3 cameraUp)
{
    cameraLookAt = vec3(0, 0, 0);
    cameraPos	 = vec3(3, 1, -3) * state.camDist;

    cameraFwd  = normalize(cameraLookAt - cameraPos);
    cameraLeft = -normalize(cross(cameraFwd, vec3(0.0,1.0,0.0)));
    cameraUp   = normalize(cross(cameraLeft, cameraFwd));
}

mat4 fxCalcCameraMat(vec3 resolution, vec3 cameraLeft, vec3 cameraUp, vec3 cameraFwd, vec3 cameraPos)
{
    return mat4(vec4(-0.5 * cameraLeft, 0.0) *.3,
        vec4(-0.5*cameraUp, 0.0) * .3,
        vec4(cameraFwd, 0.0),
        vec4(cameraPos, 1.0));
}

vec3 fxCalcRay(in vec2 fragCoord, in vec3 iResolution, in vec3 cameraFwd, in vec3 cameraUp, in vec3 cameraLeft)
{
	vec2 screenPos = (fragCoord.xy - .5 * iResolution.xy) / iResolution.y;
	return normalize(cameraFwd - screenPos.x * cameraLeft * .3 - screenPos.y * cameraUp * .3);
}

// SDFS

float sdBox(vec3 p, vec3 s)
{
    p = abs(p) - s;
	return length(max(p, 0.)) + min(max(p.x, max(p.y, p.z)), 0.);
}

float sdCappedCylinder( vec3 p, float h, float r )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

mat2 rotMat(float a)
{
    vec2 sc = vec2(sin(a), cos(a));
    return mat2(sc.y, -sc.x, sc.x, sc.y);
}

float mapCubes(vec3 p)
{
    p.y += floor(p.x) - floor(p.z);
    p.xz = fract(p.xz) - .5;

    float d = sdBox(p, vec3(.5));
    d = min(d, sdBox(p + vec3(1, -1, 0), vec3(.5)));
    d = min(d, sdBox(p + vec3(0, -1, -1), vec3(.5)));
    return d;
}

// https://iquilezles.org/articles/normalsSDF
vec3 normCubes(vec3 p)
{
    const vec2 e = vec2(1.0,-1.0)*0.000005773;
    return normalize( e.xyy*mapCubes(p + e.xyy) + 
					  e.yyx*mapCubes(p + e.yyx) + 
					  e.yxy*mapCubes(p + e.yxy) + 
					  e.xxx*mapCubes(p + e.xxx) );
}

vec3 getChutePos(fxState state)
{
    return vec3(-1.5 + state.chuteX, 7, 1.5 + state.chuteX);
}

float mapChute(vec3 p, fxState state)
{
    return sdCappedCylinder(p - getChutePos(state), 1., 1.);
}

// https://iquilezles.org/articles/normalsSDF
vec3 normChute(vec3 p, fxState state)
{
    const vec2 e = vec2(1.0,-1.0)*0.0005773;
    return normalize( e.xyy*mapChute(p + e.xyy, state) + 
					  e.yyx*mapChute(p + e.yyx, state) + 
					  e.yxy*mapChute(p + e.yxy, state) + 
					  e.xxx*mapChute(p + e.xxx, state) );
}

// G BUFFER

// note there are five dwords here...c is stored where the normal z would usually be, and the normal z is reconstructed
struct fxGBufferPixel
{
    vec3 n;  // normal
    float t; // scene depth (not actually z depth)
    float m; // material
};

vec4 fxPackGBuffer(fxGBufferPixel pix)
{
    // material is tucked away in where the normal's z is, so record the sign there
    return vec4(pix.n.xy, pix.m * sign(pix.n.z), pix.t);
}

fxGBufferPixel fxUnpackGBuffer(vec4 fragColor)
{
    fxGBufferPixel pix;
    pix.n.xy = fragColor.xy;
    
    // reconstruct the z component of the normal
    if (fragColor.z == 0.) fragColor.z = 1e-3;
    pix.n.z = sqrt(max(0., 1. - (pix.n.x * pix.n.x + pix.n.y * pix.n.y))) * sign(fragColor.z);
    
    pix.m = abs(fragColor.z);
    pix.t = fragColor.w;
    return pix;
}

// MISC

#define keyDown(ascii)    ( texelFetch(iChannel3,ivec2(ascii,0),0).x > 0.)

#define KEY_SHIFT 16
#define KEY_CTRL 17
#define KEY_SPACE 32
#define KEY_UP 38
#define KEY_DOWN 40

void insertion_sort(inout ivec4 i, inout vec4 d, int i_, float d_)
{	
    if(any(equal(ivec4(i_),i))) return;
    if     (d_ < d[0])             
        i = ivec4(i_,i.xyz),    d = vec4(d_,d.xyz);
    else if(d_ < d[1])             
        i = ivec4(i.x,i_,i.yz), d = vec4(d.x,d_,d.yz);
    else if(d_ < d[2])            
        i = ivec4(i.xy,i_,i.z), d = vec4(d.xy,d_,d.z);
    else if(d_ < d[3])           
        i = ivec4(i.xyz,i_),    d = vec4(d.xyz,d_);
}

uvec4 hash(uvec4 x){
    x = ((x >> 16u) ^ x.yzwx) * 0x45d9f3bu;
    x = ((x >> 16u) ^ x.yzwx) * 0x45d9f3bu;
    x = ((x >> 16u) ^ x.yzwx) * 0x45d9f3bu;
    x = ((x >> 16u) ^ x.yzwx) * 0x45d9f3bu;
    //x = (x >> 16u) ^ x;
    return x;
}

//hashing noise by IQ
float hash( int k ) {
    uint n = uint(k);
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    return uintBitsToFloat( (n>>9U) | 0x3f800000U ) - 1.0;
}

// Integer Hash - II by iq
// https://www.shadertoy.com/view/XlXcW4
const uint k = 1103515245U;  // GLIB C

vec3 hash3( uvec3 x )
{
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    
    return vec3(x)*(1.0/float(0xffffffffU));
}

float length2(vec2 v) { return dot(v, v); }
float length2(vec3 v) { return dot(v, v); }

// https://iquilezles.org/articles/spherefunctions/
float sphIntersect( in vec3 ro, in vec3 rd, in vec4 sph )
{
	vec3 oc = ro - sph.xyz;
	float b = dot( oc, rd );
	float c = dot( oc, oc ) - sph.w*sph.w;
	float h = b*b - c;
	if( h<0.0 ) return -1.0;
	return -b - sqrt( h );
}
