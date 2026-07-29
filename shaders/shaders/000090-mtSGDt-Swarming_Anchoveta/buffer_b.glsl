// Buffer B (buffer) — Swarming Anchoveta by fenix
// https://www.shadertoy.com/view/mtSGDt

// ---------------------------------------------------------------------------------------
// Voronoi particle tracking buffer
// ---------------------------------------------------------------------------------------

// Originally derived, many shaders ago, from:
// Gijs's Basic : Voronoi Tracking: https://www.shadertoy.com/view/WltSz7

// Voronoi Buffer
// every pixel stores the 4 closest particles to it
// every frame this data is shared between neighbours

float distance2Particle(int id, vec3 ro, vec3 rd)
{
    if(id < 0) return FAR_CLIP;
    
    fxParticle p = fxGetParticle(id);
    vec3 hitPos;
    float t = fishIntersect(p, ro, rd, hitPos);

    if (t == -1.) return FAR_CLIP;
    return t;
}

void mainImage( out vec4 fragColor, vec2 fragCoord)
{
   	ivec2 ifc = ivec2(fragCoord);
    computeMaxParticles(iResolution);
    fxState state = fxGetState();
    if(ifc == ivec2(0))
    {
        // update persistent state
        state.resolution = abs(state.resolution);
        
        fragColor = fxPutState(state);
        return;
    }
    
    vec3 cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp;
    fxCalcCamera(cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp);

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
            float dis2 = distance2Particle(id, cameraPos, rayDir);
            insertion_sort( new, dis, id, dis2 );

            // randomly check one of the physics neighbors of the particle, it's likely to be of interest
            for (int i = 0; i < 3; ++i)
            {
                ivec4 h = ivec4(hash(uvec4(ifc.x, ifc.y * 3, iFrame, j * 4 + i)));
                ivec4 nbs = ivec4(fxGetParticleData(id, h.x % 4));
                int nid = nbs[h.y % 4];

                if (nid >= 0)
                {
                    float dis2 = distance2Particle(nid, cameraPos, rayDir);
                    insertion_sort( new, dis, nid, dis2 );
                }
            }
        }

        // search nearby voronoi cells for particles that should move into our cell
        uint searchRange = 31u;
        uint searchCount = 16u;

        for(uint i=0u; i<searchCount; ++i)
        {
            uvec4 h0 = hash(uvec4(fragCoord, iFrame, i) * i);
            ivec4 old = fxGetClosest( ifc + ivec2( h0.xy % searchRange - searchRange / 2u) );      

            for (int j = 0; j < 4; j++)
            {
                int id = old[j];
                if (id < 0) break;
                float dis2 = distance2Particle(id, cameraPos, rayDir);
                insertion_sort( new, dis, id, dis2 );
            }        
        }

        // random searching to kick start the process
        int searchIterations = iFrame < 5 ? 20 : 5;
        for(int k = 0; k < searchIterations; k++)
        {
            int id = int(hash(uvec4(ifc.x, ifc.y * 3, iFrame, k)).x) % MAX_PARTICLES;
            insertion_sort(new, dis, id, distance2Particle(id, cameraPos, rayDir));
        }
    }
    
    fragColor = vec4(new);
}