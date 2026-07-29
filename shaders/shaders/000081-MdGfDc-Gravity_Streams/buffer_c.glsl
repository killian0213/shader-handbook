// Buffer C (buffer) — Gravity Streams by Lorenzo_Vannuccini
// https://www.shadertoy.com/view/MdGfDc

// Compute Scene Normals

vec2 getParticlePosition(in int particleID)
{
    int iChannel0_width = int(iChannelResolution[0].x);
	ivec2 particleCoord = ivec2(particleID % iChannel0_width, particleID / iChannel0_width);
    
    return texelFetch(iChannel0, particleCoord, 0).xy;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{ 
    fragColor = texelFetch(iChannel1, ivec2(fragCoord) + cameraVelocity, 0);
    
	for(int i = 0; i < nParticles; ++i)
    {
        vec2 v = fragCoord - getParticlePosition(i);
        
        float l = length(v);
        float alpha = smoothstep(particlesSize, particlesSize * 0.5, l);
        
        float z = sqrt(abs(particlesSize * particlesSize - l * l));
        vec3 n = normalize(vec3(v, z));

        fragColor = mix(fragColor, vec4(n, 1.0), alpha);
    }
}
