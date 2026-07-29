// Buffer A (buffer) — Large Mountains Erosion Terrain by Hatchling
// https://www.shadertoy.com/view/cd2GDz

float getOccupancy(vec2 uv)
{
    return texture(iChannel0, uv).r;
}

bool isIn(vec2 uv, float threshold)
{
	return getOccupancy(uv) > threshold;
}

float squaredDistanceBetween(vec2 uv1, vec2 uv2)
{
    vec2 difference = uv1 - uv2;
    return dot(difference, difference);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = (fragCoord.xy) / iResolution.xy;
    vec4 oldColor = texture(iChannel2, uv);
    
    // This block of code was to make the terrain
    // "grow" instead of expose the poorly resolved
    // initial state with few samples.
    if(oldColor.a == 0. || iMouse.z > 0.)
    {
        oldColor.rgb = vec3(25.);
        oldColor.a = 50.;
    }
    
    // Stop after enough iterations.
    if(oldColor.a > 512.)
    {
        fragColor = oldColor;
        return;
    }
        
    
    //fragColor = vec4(vec3(getOccupancy(uv)), 1);
    //return;
    
    // Compute the noise.
    vec3 noise;
    {
        
        // Cycle the noise.
        // We do the cycling FIRST to prevent
        // loss of precision that might
        // round away the noise values.
        //   - Use the golden ratio as it should land
        //     on all fractional values eventually.
        noise = vec3(iFrame, iFrame+1, iFrame+2);
        noise *= 1.618033;
        noise -= floor(noise);
    
        // Noise is added to vary the threshold
        // per pixel to speed up apparent convergence,
        // but the converged result shouldn't change.
        // (Disable to prevent gradient noise).
        //vec2 noiseUV = fragCoord.xy / iChannelResolution[1].xy;
        //noise += texture(iChannel1, noiseUV).r;
        //noise -= floor(noise);
        
        noise.xy -= 0.5f;
    }
    
    // Compare with and without fuzziness.
    //if(uv.x > 0.5)
    //    noise.z = 0.5;
       
    vec2 samplingCenter = fragCoord + noise.xy;
    vec2 samplingCenterUV = samplingCenter / iResolution.xy;
    
    const float halfRange = 32.0;
    const int iRange = int(halfRange);
    const float maxSqrDist = halfRange*halfRange;
    vec2 startPosition = samplingCenter;
    
    bool fragIsIn = isIn(samplingCenterUV, noise.z);
    float squaredDistanceToEdge = maxSqrDist*2.;
    
    for(int dx=-iRange; dx <= iRange; dx++)
    {
        for(int dy=-iRange; dy <= iRange; dy++)
        {
            vec2 delta = vec2(dx, dy);
            vec2 circlizer = abs(delta);
            circlizer /= max(circlizer.x, circlizer.y);
            delta /= length(circlizer);
            vec2 scanPosition = startPosition + vec2(dx, dy);
            float scanDistance = squaredDistanceBetween(samplingCenter, scanPosition);
                
            //if(scanDistance > maxSqrDist)
            //    continue;
                
            bool scanIsIn = isIn(scanPosition / iResolution.xy, noise.z);
            if (scanIsIn != fragIsIn)
            {
                if (scanDistance < squaredDistanceToEdge)
                    squaredDistanceToEdge = scanDistance;
            }
        }
    }
    
    float distanceToEdge = sqrt(squaredDistanceToEdge);

    if (fragIsIn)
    {
        // We add 1.0 here since the edge is on the inside
        // of the boundary.
        distanceToEdge = 1.0-distanceToEdge;
    }
        
    distanceToEdge /= halfRange * 2.;
        
    distanceToEdge = 0.5 - distanceToEdge;
    
    distanceToEdge = smoothstep(0., 1., distanceToEdge);
    //distanceToEdge = smoothstep(0., 1., distanceToEdge);
    
    fragColor = vec4(distanceToEdge, distanceToEdge, distanceToEdge, 1.0);

    
   
    fragColor += oldColor;
}
