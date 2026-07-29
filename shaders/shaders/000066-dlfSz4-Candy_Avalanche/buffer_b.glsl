// Buffer B (buffer) — Candy Avalanche by fenix
// https://www.shadertoy.com/view/dlfSz4

// ---------------------------------------------------------------------------------------
// Voronoi particle tracking buffer
// ---------------------------------------------------------------------------------------

// Originally derived, many shaders ago, from:
// Gijs's Basic : Voronoi Tracking: https://www.shadertoy.com/view/WltSz7

// Voronoi Buffer
// every pixel stores the 4 closest particles to it
// every frame this data is shared between neighbours

float distance2Particle(int id, vec2 fragCoord, vec3 ro, vec3 rd)
{
    if(id < 0) return FAR_CLIP;
    
    // compute screen space position
    vec3 worldPos = fxGetParticleData(id, RPOS).xyz;
    float t = sphIntersect(ro, rd, vec4(worldPos, PARTICLE_SIZE));
        
    if (t > 0. && worldPos != vec3(0))
    {
        return t;
    }
    
    return FAR_CLIP;
}

void mainImage( out vec4 fragColor, vec2 fragCoord)
{
   	ivec2 ifc = ivec2(fragCoord);
    computeMaxParticles(iResolution);
    fxState state = fxGetState();
    if(ifc == ivec2(0) || ifc == ivec2(1, 0))
    {
        // update persistent state
        state.resolution = abs(state.resolution);
        
        if (iMouse.z > 0.)
        {
            float m = .5 - iMouse.x / iResolution.x;
            if (iMouse.w < 0.)
            {
                state.chuteX = m * 16.;
                state.chuteVel = m - state.lastMouseX;
            }
            
            state.lastMouseX = m;
        }
        else
        {
            state.chuteVel -= state.chuteX * .00005;
            state.chuteX += state.chuteVel;
        }
        
        state.chuteVel *= float(abs(state.chuteX) < 8.);
        state.chuteX = clamp(state.chuteX, -8., 8.);
        
        if (keyDown(KEY_UP)) state.camDist -= .1;
        if (keyDown(KEY_DOWN)) state.camDist += .1;
        if (keyDown(KEY_SPACE)) fxInitState(state);
        
        state.camDist = clamp(state.camDist, 2., 10.);
        
        fragColor = fxPutState(state, ifc);
        return;
    }
    
	vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;

    vec3 cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp;
    fxCalcCamera(state, cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp);

    vec3 rayDir = fxCalcRay(fragCoord, iResolution, cameraFwd, cameraUp, cameraLeft);

    // in this vector the four new closest particles' ids will be stored
    ivec4 new = ivec4(-1);
    // in this vector the distance to these particles will be stored 
    vec4 dis = vec4(1e6);

    if (iFrame > 0)
    {
        ivec4 old = fxGetClosest(ifc);      
        for (int j = 0; j < 4; j++)
        {
            int id = old[j];
            if (id < 0) break;
            float dis2 = distance2Particle(id, p, cameraPos, rayDir);
            insertion_sort( new, dis, id, dis2 );

            // randomly check one of the physics neighbors of the particle, it's likely to be of interest
            ivec4 h = ivec4(hash(uvec4(ifc.x, ifc.y * 3, iFrame, j)));
            ivec4 nbs = ivec4(fxGetParticleData(id, h.x % 4));
            int nid = nbs[h.y % 4];

            if (nid >= 0)
            {
                float dis2 = distance2Particle(nid, p, cameraPos, rayDir);
                insertion_sort( new, dis, nid, dis2 );
            }
        }

        // search nearby voronoi cells for particles that should move into our cell
        uint searchRange = 31u;
        uint searchCount = 24u;

        for(uint i=0u; i<searchCount; ++i)
        {
            uvec4 h0 = hash(uvec4(fragCoord, iFrame, i) * i);
            ivec4 old = fxGetClosest( ifc + ivec2( h0.xy % searchRange - searchRange / 2u) );      

            for (int j = 0; j < 1; j++)
            {
                int id = old[j];
                if (id < 0) break;
                float dis2 = distance2Particle(id, p, cameraPos, rayDir);
                insertion_sort( new, dis, id, dis2 );
            }        
        }

        // random searching to kick start the process
        int searchIterations = iFrame < 5 ? 20 : 5;
        for(int k = 0; k < searchIterations; k++)
        {
            int id = int(hash(uvec4(ifc.x, ifc.y * 3, iFrame, k)).x) % MAX_PARTICLES;
            insertion_sort(new, dis, id, distance2Particle(id, p, cameraPos, rayDir));
        }
    }
    
    fragColor = vec4(new);
}