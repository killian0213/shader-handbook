// Buffer B (buffer) — Gravity Streams by Lorenzo_Vannuccini
// https://www.shadertoy.com/view/MdGfDc

// Compute Scene Albedo

vec2 getParticlePosition(in int particleID)
{
    int iChannel0_width = int(iChannelResolution[0].x);
	ivec2 particleCoord = ivec2(particleID % iChannel0_width, particleID / iChannel0_width);
    
    return texelFetch(iChannel0, particleCoord, 0).xy;
}

vec3 getParticleColor(in vec2 p) {
    return normalize(vec3(0.1) + texture(iChannel2, p * 0.0001 + iTime * 0.005).rgb);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{ 
    fragColor = texelFetch(iChannel1, ivec2(fragCoord) + cameraVelocity, 0);
    fragColor.a *= (1.0 - streamsFadingExp);
        
	for(int i = 0; i < nParticles; ++i)
    {
        vec2 particlePos = getParticlePosition(i);
        vec3 particleCol = getParticleColor(particlePos);
        
        float alpha = smoothstep(particlesSize, particlesSize * 0.5, distance(fragCoord, particlePos));
        fragColor = mix(fragColor, vec4(particleCol , 1.0), alpha);
    }
}
