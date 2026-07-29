// Common (common) — Local Light Source Ball Pit by fenix
// https://www.shadertoy.com/view/mt23R3

// constants
const float PI = 3.141592653589793;
const float PARTICLE_SIZE = .03;
const float FAR_CLIP = 1e6;
const int LIGHT_RATIO = 25;

// PARTICLES

// returns the ids of the four closest particles from the input
ivec4 fxGetClosestImpl(sampler2D sampler, ivec2 xy)
{
    return ivec4(texelFetch(sampler, xy, 0));
}

#define fxGetClosest(X) fxGetClosestImpl(iChannel1, X)
#define fxGetClosestLights(X) fxGetClosestImpl(iChannel2, X)

#define UL_NEIGHBORS 0
#define UR_NEIGHBORS 1
#define LL_NEIGHBORS 2
#define LR_NEIGHBORS 3
#define POS 4
#define VEL 5
#define NUM_PARTICLE_DATA_TYPES 6

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
    ivec4 nbs[4];
};

// get the particle corresponding to the id
fxParticle fxGetParticleImpl(sampler2D sampler, int resolutionWidth, int id)
{
    vec4 particleData0 = texelFetch(sampler, fxLocFromID(resolutionWidth, id, UL_NEIGHBORS), 0);
    vec4 particleData1 = texelFetch(sampler, fxLocFromID(resolutionWidth, id, UR_NEIGHBORS), 0);
    vec4 particleData2 = texelFetch(sampler, fxLocFromID(resolutionWidth, id, LL_NEIGHBORS), 0);
    vec4 particleData3 = texelFetch(sampler, fxLocFromID(resolutionWidth, id, LR_NEIGHBORS), 0);
    vec4 particleData4 = texelFetch(sampler, fxLocFromID(resolutionWidth, id, POS), 0);
    vec4 particleData5 = texelFetch(sampler, fxLocFromID(resolutionWidth, id, VEL), 0);

    fxParticle particle;
    particle.nbs[0] = ivec4(particleData0);
    particle.nbs[1] = ivec4(particleData1);
    particle.nbs[2] = ivec4(particleData2);
    particle.nbs[3] = ivec4(particleData3);
    particle.pos = particleData4.xyz;
    particle.vel = particleData5.xyz;
    
    return particle;
}

#define fxGetParticle(X) fxGetParticleImpl(iChannel0, int(iResolution.x), X)

vec4 fxSaveParticle(fxParticle p, int dataType)
{    
    switch(dataType)
    {
    case UL_NEIGHBORS:
        return vec4(p.nbs[0]);
    case UR_NEIGHBORS:
        return vec4(p.nbs[1]);
    case LL_NEIGHBORS:
        return vec4(p.nbs[2]);
    case LR_NEIGHBORS:
        return vec4(p.nbs[3]);
    case POS:  
        return vec4(p.pos, 0);
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
const int IDEAL_MAX_PARTICLES = 5000;
int MAX_PARTICLES = IDEAL_MAX_PARTICLES; // how many particles, total

// computes the real number of particles that we can simulate in case our buffer isn't big enough
void computeMaxParticles(vec3 res)
{
    MAX_PARTICLES = IDEAL_MAX_PARTICLES;
    MAX_PARTICLES = min(MAX_PARTICLES, int(res.x * res.y) / NUM_PARTICLE_DATA_TYPES);
}

// CAMERA

void fxCalcCamera(out vec3 cameraLookAt, out vec3 cameraPos, out vec3 cameraFwd, out vec3 cameraLeft, out vec3 cameraUp)
{
    cameraLookAt = vec3(0, -.5, 0);
    cameraPos	 = vec3(0, 1, 1);

    cameraFwd  = normalize(cameraLookAt - cameraPos);
    cameraLeft = -normalize(cross(cameraFwd, vec3(0.0,1.0,0.0)));
    cameraUp   = normalize(cross(cameraLeft, cameraFwd));
}

mat4 fxCalcCameraMat(vec3 resolution, vec3 cameraLeft, vec3 cameraUp, vec3 cameraFwd, vec3 cameraPos)
{
    return mat4(vec4(-0.5 * cameraLeft, 0.0),
        vec4(-0.5*cameraUp, 0.0),
        vec4(cameraFwd, 0.0),
        vec4(cameraPos, 1.0));
}

vec3 fxCalcRay(in vec2 fragCoord, in vec3 iResolution, in vec3 cameraFwd, in vec3 cameraUp, in vec3 cameraLeft)
{
	vec2 screenPos = (fragCoord.xy - .5 * iResolution.xy) / iResolution.y;
	return normalize(cameraFwd - screenPos.x * cameraLeft - screenPos.y * cameraUp);
}

// PERSISTENT STATE

struct fxState
{
    vec2 boxRot;
    vec2 boxVel;
    vec2 lastMouse;
    float resolution;
    bool autoRotate;
};

void fxInitStateImpl(inout fxState state, vec3 iResolution)
{
    state.boxRot = vec2(0);
    state.boxVel = vec2(0);
    state.lastMouse = vec2(0);
    state.resolution = -iResolution.x * iResolution.y;
    state.autoRotate = true;
}

#define fxInitState(state) fxGetStateImpl(state, iResolution)

fxState fxGetStateImpl(sampler2D sampler, int iFrame, vec3 iResolution)
{
    vec4 data0 = texelFetch(sampler, ivec2(0, 0), 0);
    vec4 data1 = texelFetch(sampler, ivec2(1, 0), 0);
    
    fxState state;
    state.boxRot = data0.xy;
    state.boxVel = data0.zw;
    state.lastMouse = data1.xy;
    state.resolution = data1.z;
    state.autoRotate = data1.w != 0.;
    
    if (iFrame == 0 || abs(state.resolution) != iResolution.x * iResolution.y)
        fxInitStateImpl(state, iResolution);
        
    return state;
}

#define fxGetState() fxGetStateImpl(iChannel1, iFrame, iResolution)

vec4 fxPutState(fxState state, ivec2 ifc)
{
    if (ifc == ivec2(0, 0))
        return vec4(state.boxRot, state.boxVel);
    else
        return vec4(state.lastMouse, state.resolution, state.autoRotate ? 1. : 0.);
}

// PHYSICS BOUNDARY SCENE

float sdBox(vec3 p, vec3 s)
{
    p = abs(p) - s;
	return length(max(p, 0.)) + min(max(p.x, max(p.y, p.z)), 0.);
}

// compute a matrix from the boxRot euler angles
mat4 boxMat(vec2 boxRot)
{
    const float ROTATE_SPEED = .2;
    vec2 scA = vec2(sin(boxRot.x * ROTATE_SPEED), cos(boxRot.x * ROTATE_SPEED));
    vec2 scB = vec2(sin(boxRot.y * ROTATE_SPEED), cos(boxRot.y * ROTATE_SPEED));
    vec2 scC = vec2(sin(.001 * ROTATE_SPEED), cos(.001 * ROTATE_SPEED));
    mat4 matA = mat4(scA.y, -scA.x, 0, 0, scA.x, scA.y, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
    mat4 matB = mat4(scB.y, 0, scB.x, 0, 0, 1, 0, 0, -scB.x, 0, scB.y, 0, 0, 0, 0, 1);
    mat4 matC = mat4(0, scC.y, -scC.x, 0, 1, 0, 0, 0, 0, scC.x, scC.y, 0, 0, 0, 0, 1);
    
    return matA * matB * matC;
}

void rotateBox(inout vec3 p, vec2 boxRot)
{
    p = (vec4(p, 1) * boxMat(boxRot)).xyz;
}

float scene(vec3 p, fxState state)
{
    rotateBox(p, state.boxRot);
    return -sdBox(p - vec3(0, 0, 0), vec3(1, 1, 1));
}

// https://iquilezles.org/articles/normalsSDF
vec3 sceneNormal(vec3 p, fxState state)
{
    const vec2 e = vec2(1.0,-1.0)*0.000005773;
    return normalize( e.xyy*scene(p + e.xyy, state) + 
					  e.yyx*scene(p + e.yyx, state) + 
					  e.yxy*scene(p + e.yxy, state) + 
					  e.xxx*scene(p + e.xxx, state) );
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
    pix.n.z = sqrt(max(0., 1. - (pix.n.x * pix.n.x + pix.n.y * pix.n.y))) * sign(fragColor.z);
    
    pix.m = abs(fragColor.z);
    pix.t = fragColor.w;
    return pix;
}

// MISC

#define keyDown(ascii)    ( texelFetch(iChannel3,ivec2(ascii,0),0).x > 0.)

#define KEY_SHIFT 16
#define KEY_SPACE 32

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


