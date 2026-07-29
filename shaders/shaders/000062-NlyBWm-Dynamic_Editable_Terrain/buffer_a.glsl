// Buffer A (buffer) — Dynamic Editable Terrain by fenix
// https://www.shadertoy.com/view/NlyBWm

// --------------------------------------------------------------------------------------------
// Computes the terrain height by attempting to match nearby pixels when near the camera.
// This buffer is set up for wrapping, and hopefully there are no visible artifacts when
// the camera wraps around.
// --------------------------------------------------------------------------------------------

const int MAX_DIRECTIONS = 13;

void updateState(inout vec4 state)
{
    if (iFrame == 0)
    {
        state = vec4(0, 0, 0, 1);
    }
    else
    {
        state.xy = iMouse.xy;
        
        if (keyClick(KEY_SPACE) || abs(state.z) != iResolution.x * iResolution.y)
        {
            state.z = -iResolution.x * iResolution.y;
            
            // Automatically disable shadows when switching to very high resolutions
            if (iResolution.y > 1000.) state.w = -1.;
            else state.w = 1.;
        }
        else
        {
            state.z = abs(state.z);
        }
        
        if (state.w == 0.) state.w = 1.;
        state.w += sign(state.w);
        
        if (keyClick(KEY_SHIFT))
        {
            state.w = -state.w;
        }
    }
}

float melt(float h)
{
    h = floor(h*(float(MAX_DIRECTIONS)));
    return h;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 ifc = ivec2(fragCoord);

    vec3 h = hash(uvec3(ifc.y, ifc.x, iFrame + int(iDate.w)));
    
    fragColor = texelFetch(iChannel0, ifc, 0);
    
    if (ifc == ivec2(0))
    {
        updateState(fragColor);
        return;
    }
    
    vec4 state = texelFetch(iChannel0, ivec2(0), 0);
    float directions = float(MAX_DIRECTIONS);
    
    if (iFrame == 0 || state.z < 0.)
    {
        fragColor.x = melt(h.x);
        fragColor.yzw = vec3(0);
    }
    else
    {
        float time = float(iTime);
        vec2 mouse = iMouse.xy;

        // Apply heat everywhere but a circle around the camera position
        vec3 cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp;
        fxCalcCamera(time, mouse, cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp);
        
        vec2 p = mod(cameraPos.xz * iResolution.y * 0.1, iResolution.xy);

        float TEMP_SCALE = 3.0 / iResolution.y;
        float t = distance(p, fragCoord)*TEMP_SCALE;
        
        // Copy the circle multiple times to handle wraparound conditions
        t = min(t, distance(p + iResolution.xy*vec2(1, 0), fragCoord)*TEMP_SCALE);
        t = min(t, distance(p + iResolution.xy*vec2(0, 1), fragCoord)*TEMP_SCALE);
        t = min(t, distance(p + iResolution.xy*vec2(-1, 0), fragCoord)*TEMP_SCALE);
        t = min(t, distance(p + iResolution.xy*vec2(0, -1), fragCoord)*TEMP_SCALE);
        t = min(t, distance(p + iResolution.xy*vec2(1, 1), fragCoord)*TEMP_SCALE);
        t = min(t, distance(p + iResolution.xy*vec2(-1, -1), fragCoord)*TEMP_SCALE);
        t = min(t, distance(p + iResolution.xy*vec2(-1, 1), fragCoord)*TEMP_SCALE);
        t = min(t, distance(p + iResolution.xy*vec2(1, -1), fragCoord)*TEMP_SCALE);
        
        // Handle mouse input
        if (iMouse.z > 0. && iMouse.w < 0. && state.xy != vec2(0))
        {
            vec3 fromLookAt, fromPos, fromFwd, fromLeft, fromUp;
            fxCalcCamera(time - iTimeDelta, mouse, fromLookAt, fromPos, fromFwd, fromLeft, fromUp);

        	vec3 rayFrom = fxCalcRay(state.xy, iResolution, fromFwd, fromUp, fromLeft);
        	vec3 rayTo = fxCalcRay(iMouse.xy, iResolution, cameraFwd, cameraUp, cameraLeft);
            float fromT = cameraPos.y / rayFrom.y;
            vec3 fromHit = cameraPos - fromT * rayFrom;
            vec2 projFrom = mod(fromHit.xz * iResolution.y * 0.1, iResolution.xy);
            float toT = cameraPos.y / rayTo.y;
            vec3 toHit = cameraPos - toT * rayTo;
            vec2 projTo = mod(toHit.xz * iResolution.y * 0.1, iResolution.xy);
            
            if (distance(projFrom, projTo) < iResolution.y * 0.3)
            {
                float dist = linePointDist2(projFrom, projTo, fragCoord);

                float targetHeight = 0.;
                for (int i = 1; i <= 9; ++i)
                {
                    if (keyDown(KEY_0 + i))
                    {
                        targetHeight = float(i) + 2.;
                    }
                }

                if (dist < iResolution.y*0.25)
                {
                    if (fragColor.r > targetHeight)
                    {
                        fragColor.r -= 0.01 * iResolution.y / (dist + 1.0);
                    }
                    else if (fragColor.r < targetHeight)
                    {
                        fragColor.r +=  0.01 * iResolution.y / (dist + 1.0);
                    }
                }
            }
        }
        fragColor.r = clamp(fragColor.r, 0., float(MAX_DIRECTIONS));
    
        float annealChance = mix(0.02, 0.5, smoothstep(1800., 3000., iResolution.y));
        if (abs(state.w) < 20.) annealChance *= 10.;
        if (t > 1.1 + 0.9 * h.x)
        {
            // Melting temp
            fragColor.x = melt(h.y);            
        }
        else if (h.y < annealChance)
        {
            // Count how many neighbors in range have each possible direction
            int counts[MAX_DIRECTIONS];
            for (int i = 0; i < int(directions); ++i)
            {
                counts[i] = 0;
            }

            const int RANGE = 2;
            for (int x = -RANGE; x <= RANGE; ++x)
            {
                for (int y = -RANGE; y <= RANGE; ++y)
                {
                    ivec2 ni = ifc + ivec2(x, y);
                    if (ni == ivec2(0)) continue; // Ignore state pixel
                    vec4 n = texture(iChannel0, (vec2(ni) + 0.5) / iResolution.xy);
                    counts[int(n.x)]++;
                }
            }

            // Find the direction most popular among neighbors
            int bestCount = -1;
            int bestDir;
            bool unique;

            for (int d = 0; d < int(directions); ++d)
            {
                if (counts[d] > bestCount)
                {
                    bestCount = counts[d];
                    bestDir = d;
                    unique = true;
                }
                else if (counts[d] == bestCount)
                {
                    unique = false;
                }
            }

            if (unique)
            {
                if (abs(fragColor.x - float(bestDir)) > h.x * directions*0.001)
                    fragColor.x = float(bestDir);
            }
        }
    }
}