// Common (common) — Gravity Streams by Lorenzo_Vannuccini
// https://www.shadertoy.com/view/MdGfDc


// #define USE_CINEMATIC_MODE      // Uncomment this line for a more cinematic view (camera will side-scroll)
// #define USE_BUMPY_STREAMS_MODE  // Uncomment this line to make streams bumpy (sausages-like)
// #define USE_GENERATION_SEED 123 // Uncomment this line to use a fixed generation seed (then reset the simulation to apply the changes)
    
const int nParticles = 20;
const float particlesSize = 8.0;
const float collisionDamping = 0.5;
const float streamsFadingExp = 0.001;
const float gravityStrength = 1.6 / particlesSize;

const vec3 ambientLightDir = normalize(vec3(1.0, 2.0, 0.0));
const vec3 ambientLightCol = vec3(1.1, 1.0, 0.9);
const vec3 backgroundColor = vec3(0.65);
const float streamsGlossExp = 120.0;
const float spotlightsGlare = 0.0;

#ifdef USE_BUMPY_STREAMS_MODE
#define particlesSize mix(particlesSize, particlesSize * 0.5, (1.0 + sin(1.85 + iTime * 11.93805208)) * 0.5)
#endif

#ifdef USE_GENERATION_SEED
#define generationSeed float(USE_GENERATION_SEED) // a fixed seed will generate the same output (in respect of the viewport size)
#else
#define generationSeed iDate.w // if no custom seed is provided, POSIX time is used instead (producing different results every time)
#endif

const ivec2 cameraVelocity =
#ifdef USE_CINEMATIC_MODE
ivec2(1, 0);
#else
ivec2(0);
#endif

// Buf A: particles positions and inertia
// Buf B: scene albedo  (accumulated)
// Buf C: scene normals (accumulated)
// Image: final compositing
