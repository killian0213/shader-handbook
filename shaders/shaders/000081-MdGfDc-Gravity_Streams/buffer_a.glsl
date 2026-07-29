// Buffer A (buffer) — Gravity Streams by Lorenzo_Vannuccini
// https://www.shadertoy.com/view/MdGfDc

// Compute Physics (Verlet Integration)

float rand(in vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec2 randVec2(in vec2 co) {
	return vec2(rand(co.xy + generationSeed * 0.0001), rand(-co.yx + generationSeed * 0.0001));
}

vec2 randNrm2(in vec2 fragCoord)
{
	vec2 n = vec2(-1.0) + randVec2(fragCoord) * 2.0;
    
    float l = length(n);   
    if(l <= 0.0000001) n = vec2(0.0, (l = 1.0));
    
    return (n / l);
}

void initParticle(in vec2 fragCoord, inout vec2 particlePrevPosition, inout vec2 particleCurrPosition)
{
	particleCurrPosition = randVec2(fragCoord) * iResolution.xy;
    particlePrevPosition = particleCurrPosition - randNrm2(fragCoord) * particlesSize * 0.0625;
}

vec2 getParticlePosition(in int particleID)
{
    int iChannel0_width = int(iChannelResolution[0].x);
	ivec2 particleCoord = ivec2(particleID % iChannel0_width, particleID / iChannel0_width);
    
    return texelFetch(iChannel0, particleCoord, 0).xy;
}

vec2 computeGravitation(in int particleID, in vec2 particlePosition)
{
    vec2 acceleration = vec2(0.0);
        
	for(int i = 0; i < nParticles; ++i) if(i != particleID)
    {
        vec2 v = (getParticlePosition(i) - particlePosition);
        float d = length(v);
        
        if(d > 0.0000001) acceleration += (v / d) / pow(max(d, particlesSize * 2.0) * gravityStrength, 2.0);
    }
    
    return acceleration;
}

void solveCollisions(inout vec2 particlePrevPosition, inout vec2 particleCurrPosition)
{
    vec2 particleInertia = (particleCurrPosition - particlePrevPosition);
    
	if(particleCurrPosition.x < particlesSize || particleCurrPosition.x > iResolution.x - particlesSize)
    {
    	particleCurrPosition.x = clamp(particleCurrPosition.x, particlesSize, iResolution.x - particlesSize);
        particlePrevPosition.x = particleCurrPosition.x + particleInertia.x * collisionDamping;
    }
    
    if(particleCurrPosition.y < particlesSize || particleCurrPosition.y > iResolution.y - particlesSize)
    {
    	particleCurrPosition.y = clamp(particleCurrPosition.y, particlesSize, iResolution.y - particlesSize);
        particlePrevPosition.y = particleCurrPosition.y + particleInertia.y * collisionDamping;
    }
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    int particleID = int(floor(fragCoord.x) + iResolution.x * floor(fragCoord.y));
    if(particleID >= nParticles) return;
    
    vec4 particleData = texelFetch(iChannel0, ivec2(fragCoord), 0);
    vec2 particlePrevPosition = particleData.zw;
    vec2 particleCurrPosition = particleData.xy;
     
    if(iFrame == 0) initParticle(fragCoord, particlePrevPosition, particleCurrPosition);
   
    vec2 particleAcceleration = computeGravitation(particleID, particleCurrPosition);
    vec2 particleInertia = particleCurrPosition - particlePrevPosition;
    vec2 particleVelocity = particleInertia + particleAcceleration;
    
    particlePrevPosition = particleCurrPosition;
    particleCurrPosition += particleVelocity;
    
    solveCollisions(particlePrevPosition, particleCurrPosition);
    
    fragColor = vec4(particleCurrPosition, particlePrevPosition);
}
