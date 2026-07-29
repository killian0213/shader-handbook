// Common (common) — Tearable 3D Fishnet by fenix
// https://www.shadertoy.com/view/NlKBW3

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

void fxCalcCamera(out vec3 cameraLookAt, out vec3 cameraPos, out vec3 cameraFwd, out vec3 cameraLeft, out vec3 cameraUp)
{
    cameraLookAt = vec3(0.0, 0.0f, 0.0);
    cameraPos	= vec3(0, 1, 3);

    cameraFwd  = normalize(cameraLookAt - cameraPos);
    cameraLeft  = -normalize(cross(cameraFwd, vec3(0.0,1.0,0.0)));
    cameraUp   = normalize(cross(cameraLeft, cameraFwd)) * 0.5;
}

mat4 fxCalcCameraMat(vec3 resolution, vec3 cameraLeft, vec3 cameraUp, vec3 cameraFwd, vec3 cameraPos)
{
    return mat4(vec4(-0.5*resolution.y / resolution.x * cameraLeft, 0.0),
        vec4(-0.5*cameraUp, 0.0),
        vec4(cameraFwd, 0.0),
        vec4(cameraPos, 1.0));
}

vec3 fxCalcRay(in vec2 fragCoord, in vec3 iResolution, in vec3 cameraFwd, in vec3 cameraUp, in vec3 cameraLeft)
{
	vec2 screenPos = (fragCoord.xy / iResolution.xy) * 1.0 - 0.5;
	return normalize(cameraFwd - screenPos.x * cameraLeft - screenPos.y * cameraUp);
}

const float MAX_TEMP = 1000.0;

float length2(vec2 v)
{
    return dot(v, v);
}

float fxLinePointDist2(vec2 a, vec2 b, vec2 p)
{
    p -= a, b -= a;
    float h = clamp(dot(p, b) / dot(b, b), 0., 1.);// proj coord on line
    return length2(p - b * h); // squared dist to segment
}

//returns the ids of the four closest particles from the input
ivec4 fxGetClosestInternal(sampler2D sampler, ivec2 xy)
{
    return ivec4(texelFetch(sampler, xy, 0));
}

#define fxGetClosest(X) fxGetClosestInternal(iChannel1, X)

#define POS 0
#define PREV 1
#define NUM_PARTICLE_DATA_TYPES 2

//returns the location of the particle within the particle buffer corresponding with the input id 
ivec2 fxLocFromIDInternal(int width, int id, int dataType)
{
    int index = id * NUM_PARTICLE_DATA_TYPES + dataType;
    return ivec2( index % width, index / width);
}

#define fxLocFromID(X, Y) fxLocFromIDInternal(int(iResolution.x), X, Y)

struct fxParticle
{
    vec3 pos;
    vec3 prev;
    bool pinned;
    bool disabled;
};

//get the particle corresponding to the input id
fxParticle fxGetParticleInternal(sampler2D sampler, int resolutionWidth, int id)
{
    vec4 particleData0 = texelFetch(sampler, fxLocFromIDInternal(resolutionWidth, id, POS), 0);
    vec4 particleData1 = texelFetch(sampler, fxLocFromIDInternal(resolutionWidth, id, PREV), 0);

    fxParticle particle;
    particle.pos = particleData0.xyz;
    particle.disabled = particleData0.w != 0.;
    particle.prev = particleData1.xyz;
    particle.pinned = particleData1.w != 0.;
    
    return particle;
}

vec4 fxSaveParticle(fxParticle p, int dataType)
{    
    switch(dataType)
    {
    case POS:  
        return vec4(p.pos, p.disabled ? 1. : 0.);
    case PREV:  
        return vec4(p.prev, p.pinned ? 1. : 0.);
    }
}

#define fxGetParticle(X) fxGetParticleInternal(iChannel0, int(iResolution.x), X)

vec4 fxGetParticleDataInternal(sampler2D sampler, int resolutionWidth, int id, int dataType)
{
    return texelFetch(sampler, fxLocFromIDInternal(resolutionWidth, id, dataType), 0);
}

#define fxGetParticleData(X, Y) fxGetParticleDataInternal(iChannel0, int(iResolution.x), X, Y)

#define keyDown(ascii)    ( texelFetch(iChannel3,ivec2(ascii,0),0).x > 0.)

#define KEY_SPACE 32

const float SIDE_LEN = 4.;

// global variables, initialized via computeClothSide
int CLOTH_SIDE = 0; // how many particles along each side of the square
int MAX_PARTICLES = 0; // how many particles, total

// computes the size of the cloth grid relative to the current resolution
void computeClothSide(vec3 res)
{
    float particleUse = 0.7 * (1. - 0.6 * smoothstep(1000., 1200., res.y));
    CLOTH_SIDE = int(sqrt(res.x * res.y / float(NUM_PARTICLE_DATA_TYPES)) * particleUse);
    MAX_PARTICLES = CLOTH_SIDE * CLOTH_SIDE;
}

// These functions compute the neighbors from each particle, and -1 if there is
// no neighbor in that direction. Crucially, they must continue to return -1 if
// -1 is passed in, since we do not terminate the loop right away.

int above(int i)
{
    return i >= 0 && i >= CLOTH_SIDE ? i - CLOTH_SIDE : -1;
}

int below(int i)
{
    return i >= 0 && i < (CLOTH_SIDE * (CLOTH_SIDE - 1)) ? i + CLOTH_SIDE : -1;
}

int left(int i)
{
    return i >= 0 && (i % CLOTH_SIDE) != 0 ? i - 1 : -1;
}

int right(int i)
{
    return i >= 0 && (i % CLOTH_SIDE) != CLOTH_SIDE - 1 ? i + 1 : -1;
}
