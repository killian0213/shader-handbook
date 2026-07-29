// Buffer D (buffer) — Local Light Source Ball Pit by fenix
// https://www.shadertoy.com/view/mt23R3

// ---------------------------------------------------------------------------------------
// Voronoi light tracking buffer
// ---------------------------------------------------------------------------------------

// Originally derived, many shaders ago, from:
// Gijs's Basic : Voronoi Tracking: https://www.shadertoy.com/view/WltSz7

// Voronoi Buffer
// every pixel stores the 4 closest particles to it
// every frame this data is shared between neighbours

float distance2Particle(int id, vec2 fragCoord, mat4 w2cNew)
{
    if(id < 0) return FAR_CLIP;
    if ((id % LIGHT_RATIO) != 0) return 1e6; // Don't allow particles that are not lights
    // compute screen space position
    vec3 worldPos = fxGetParticleData(id, POS).xyz;
    vec3 screenPos = (w2cNew * vec4(worldPos,1.0)).xyz;
    screenPos.xy = screenPos.xy / screenPos.z;
    
    // throw away particles too far away
    vec2 delta = screenPos.xy-fragCoord;
    //if (length2(delta) > (PARTICLE_SIZE * PARTICLE_SIZE * 10.0)) return 1e6;
    
    // favor particles in the front
    return length2(delta) + screenPos.z * .1;
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
            state.autoRotate = false;
            
            if (iMouse.w < 0.)
            {
                vec2 delta = 3. * (iMouse.xy - state.lastMouse) / iResolution.y;;
                state.boxVel = delta;
            }
            
            state.lastMouse = iMouse.xy;
        }
        else if (state.autoRotate)
        {
            state.boxVel = mix(state.boxVel, vec2(-.01), .01);
        }
        
        state.boxVel = clamp(state.boxVel, -.1, .1);
        
        if (keyDown(KEY_SPACE)) state.autoRotate = true;
        
        state.boxRot += state.boxVel;
        
        fragColor = fxPutState(state, ifc);
        return;
    }
    
	vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;

    vec3 cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp;
    fxCalcCamera(cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp);

    // camera-to-world and world-to-camera transform
    mat4 c2w = fxCalcCameraMat(iResolution, cameraLeft, cameraUp, cameraFwd, cameraPos);
    mat4 w2c = inverse(c2w);

    // in this vector the four new closest particles' ids will be stored
    ivec4 new = ivec4(-1);
    // in this vector the distance to these particles will be stored 
    vec4 dis = vec4(1e6);

    if (iFrame > 0)
    {
        ivec4 old = fxGetClosestLights(ifc);      
        for (int j = 0; j < 4; j++)
        {
            int id = old[j];
            if (id < 0) break;
            float dis2 = distance2Particle(id, p, w2c);
            insertion_sort( new, dis, id, dis2 );

            // randomly check one of the physics neighbors of the particle, it's likely to be of interest
            ivec4 h = ivec4(hash(uvec4(ifc.x, ifc.y * 3, iFrame, j)));
            ivec4 nbs = ivec4(fxGetParticleData(id, h.x % 4));
            int nid = nbs[h.y % 4];

            if (nid >= 0 && (nid + 1) % LIGHT_RATIO == 0)
            {
                float dis2 = distance2Particle(nid, p, w2c);
                insertion_sort( new, dis, nid, dis2 );
            }
        }

        // search nearby voronoi cells for particles that should move into our cell
        uint searchRange = 8u;
        uint searchCount = 48u;

        for(uint i=0u; i<searchCount; ++i)
        {
            uvec4 h0 = hash(uvec4(fragCoord, iFrame, i) * i);
            ivec4 old = fxGetClosestLights( ifc + ivec2( h0.xy % searchRange - searchRange / 2u) );      

            for (int j = 0; j < 1; j++)
            {
                int id = old[j];
                if (id < 0) break;
                float dis2 = distance2Particle(id, p, w2c);
                insertion_sort( new, dis, id, dis2 );
            }        
        }

        // random searching to kick start the process
        int searchIterations = iFrame < 2 ? 20 : 5;
        for(int k = 0; k < searchIterations; k++)
        {
            int id = (int(hash(uvec4(ifc.x, ifc.y * 3, iFrame, k)).x) % (MAX_PARTICLES / LIGHT_RATIO)) * LIGHT_RATIO; // search only lights
            insertion_sort(new, dis, id, distance2Particle(id, p, w2c));
        }
    }
    
    fragColor = vec4(new);
}