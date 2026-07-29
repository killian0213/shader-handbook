// Image (image) — Gravity Streams by Lorenzo_Vannuccini
// https://www.shadertoy.com/view/MdGfDc

// Final Compositing (Deferred Lighting + Bloom)

vec2 getParticlePosition(in int particleID)
{
    int iChannel0_width = int(iChannelResolution[0].x);
	ivec2 particleCoord = ivec2(particleID % iChannel0_width, particleID / iChannel0_width);
    
    return texelFetch(iChannel0, particleCoord, 0).xy;
}

vec3 computeLighting( in vec3 surfaceAlbedo,
                      in vec3 surfaceNormal,
                      in float surfaceGloss,
                      in vec3 lightCol,
                      in vec3 lightDir,
                      in float lightSpec,
                      in float lightAmb )
{
    float dot_n  = clamp(dot(surfaceNormal, lightDir), 0.0, 1.0);
    
    vec3 diffuse  = lightCol * surfaceAlbedo * clamp(dot_n, lightAmb, 1.0);
    vec3 specular = lightCol * float(dot_n > 0.0) * pow(clamp(dot(reflect(-lightDir, surfaceNormal), vec3(0.0, 0.0, 1.0)), 0.0, 1.0), surfaceGloss);
    
    return diffuse + specular * lightSpec;
}

vec3 computeSpotLight( in vec3 surfaceAlbedo,
                       in vec3 surfaceNormal,
                       in float surfaceGloss,
                       in vec3 surfacePos,  
                       in vec3 lightCol,
                       in vec3 lightPos,
                       in float lightRadius )
{
    vec3 lightVec = lightPos - surfacePos;
    float contribution = 1.0 / max(dot(lightVec, lightVec) * 0.08 / (lightRadius * lightRadius), 1.0);
    
    return computeLighting(surfaceAlbedo, surfaceNormal, surfaceGloss, lightCol, normalize(lightVec), 0.066667 * surfaceGloss, 0.0) * contribution;
}

vec3 computeLightGlow(in vec3 position, in vec3 lightCol, in vec3 lightPos, in float lightRadius)
{
    vec3 glare = spotlightsGlare * lightCol * smoothstep(lightRadius * 10.0, 0.0, length((lightPos.xy - position.xy) * vec2(1.0, 16.0)));
    vec3 innerGlow = vec3(0.8) * smoothstep(lightRadius, lightRadius * 0.5, distance(lightPos.xy, position.xy));
    vec3 outerGlow = 0.25 * lightCol * smoothstep(lightRadius * 2.5, 0.0, distance(lightPos.xy, position.xy));
  
    return innerGlow + outerGlow + glare;
}

vec3 computeVignetting(in vec2 fragCoord, in vec3 src) // https://www.shadertoy.com/view/4lSXDm
{
	vec2 coord = ((fragCoord.xy / iResolution.xy) - 0.5) * (iResolution.x / iResolution.y) * 2.0;
    float rf = sqrt(dot(coord, coord)) * 0.25;
    float rf2_1 = rf * rf + 1.0;
    
	return src * pow((1.0 / (rf2_1 * rf2_1)), 2.24);
}    

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec4 albedo = texelFetch(iChannel1, ivec2(fragCoord), 0);
	vec3 normal = normalize(texelFetch(iChannel2, ivec2(fragCoord), 0).xyz);
    vec3 position = vec3(fragCoord, -(1.0 - albedo.a) * 384.0 / particlesSize); // fake Z-depth from fade level
        
    fragColor = vec4(vec3(0.0), albedo.a); 
    fragColor.rgb += computeLighting(albedo.rgb, normal, streamsGlossExp, ambientLightCol, ambientLightDir, 0.5, 0.175);
    
    for(int i = 0; i < nParticles; ++i)
    {
        vec3 particlePos = vec3(getParticlePosition(i), 0.0);
        vec3 particleCol = texelFetch(iChannel1, ivec2(particlePos.xy), 0).rgb;
            
        fragColor.rgb += computeSpotLight(albedo.rgb, normal, streamsGlossExp, position, particleCol, particlePos, particlesSize);
    }
    
    fragColor.rgb = 1.25 * fragColor.rgb - vec3(0.075);
    fragColor.rgb = mix(backgroundColor, fragColor.rgb, min(fragColor.a * 1.125, 1.0));
    fragColor.rgb = computeVignetting(fragCoord, fragColor.rgb);
    
    for(int i = 0; i < nParticles; ++i)
    {
        vec3 particlePos = vec3(getParticlePosition(i), 0.0);
        vec3 particleCol = texelFetch(iChannel1, ivec2(particlePos.xy), 0).rgb;
        
        fragColor.rgb += computeLightGlow(position, particleCol, particlePos, particlesSize);
    }
    
    fragColor = vec4(pow(fragColor.rgb, vec3(1.0 / 2.24)), 1.0); // gamma correction
}
