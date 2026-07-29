// Common (common) — Swarming Anchoveta by fenix
// https://www.shadertoy.com/view/mtSGDt

// constants
const float PI = 3.141592653589793;
const float PARTICLE_SIZE = .025;
const vec3 FISH_SIZE = vec3(4, .4, .8)*PARTICLE_SIZE;
const float FAR_CLIP = 1e6;

// PARTICLES

// returns the ids of the four closest particles from the input
ivec4 fxGetClosestImpl(sampler2D sampler, ivec2 xy)
{
    return ivec4(texelFetch(sampler, xy, 0));
}

#define fxGetClosest(X) fxGetClosestImpl(iChannel1, X)

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
const int IDEAL_MAX_PARTICLES = 75000;
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
    cameraLookAt = vec3(0, 0., 0);
    cameraPos	 = vec3(0, -1, 3.5);

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
    float resolution;
};

void fxInitStateImpl(inout fxState state, vec3 iResolution)
{
    state.resolution = -iResolution.x * iResolution.y;
}

#define fxInitState(state) fxGetStateImpl(state, iResolution)

fxState fxGetStateImpl(sampler2D sampler, int iFrame, vec3 iResolution)
{
    vec4 data0 = texelFetch(sampler, ivec2(0, 0), 0);
    
    fxState state;
    state.resolution = data0.x;
    
    if (iFrame == 0 || abs(state.resolution) != iResolution.x * iResolution.y)
        fxInitStateImpl(state, iResolution);
        
    return state;
}

#define fxGetState() fxGetStateImpl(iChannel1, iFrame, iResolution)

vec4 fxPutState(fxState state)
{
    return vec4(state.resolution, 0, 0, 0);
}

// G BUFFER

struct fxGBufferPixel
{
    vec3 n;  // normal
    float t; // scene depth (not actually z depth)
};

vec4 fxPackGBuffer(fxGBufferPixel pix)
{
    // material is tucked away in where the normal's z is, so record the sign there
    return vec4(pix.n, pix.t);
}

fxGBufferPixel fxUnpackGBuffer(vec4 fragColor)
{
    fxGBufferPixel pix;
    pix.n = fragColor.xyz;
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

// https://iquilezles.org/articles/intersectors/
// ellipsoid centered at the origin with radii ra
float eliIntersect( in vec3 ro, in vec3 rd, in vec3 ra )
{
    vec3 ocn = ro/ra;
    vec3 rdn = rd/ra;
    float a = dot( rdn, rdn );
    float b = dot( ocn, rdn );
    float c = dot( ocn, ocn );
    float h = b*b - a*(c-1.0);
    if( h<0.0 ) return -1.; //no intersection
    h = sqrt(h);
    return (h - b) / a;
}

vec3 eliNormal( in vec3 pos, in vec3 ra )
{
    return normalize( pos/(ra*ra) );
}

float fishIntersect(fxParticle p, vec3 ro, vec3 rd, out vec3 normal)
{
    vec3 front = normalize(p.vel);
    vec3 left = -normalize(cross(vec3(0, 1, 0), front));
    vec3 up = -normalize(cross(left, front));
    mat3 m = mat3(front, left, up);
    mat3 mi = inverse(m);
    
    vec3 ero = mi * (ro - p.pos);
    vec3 erd = mi * rd;
    
    float t = eliIntersect(ero, erd, FISH_SIZE);
    vec3 hitPos = ero + erd * t;
    normal = m * eliNormal(hitPos, FISH_SIZE);

    return t;
}