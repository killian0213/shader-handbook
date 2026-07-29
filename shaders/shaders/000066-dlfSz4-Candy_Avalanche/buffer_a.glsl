// Buffer A (buffer) — Candy Avalanche by fenix
// https://www.shadertoy.com/view/dlfSz4

// ---------------------------------------------------------------------------------------
// Particle update
// ---------------------------------------------------------------------------------------

const vec3 GRAVITY = vec3(0,-.005,0);

void particleStep(inout fxParticle p, int id, fxState state)
{
    // init
    vec3 h = hash3( uvec3(id, id * iFrame, iFrame) );

    if (iFrame == 0 || state.resolution < 0.)
    {
        // init particles in the holding pen
        p.pos = vec3(0, -10, 0);
        p.rPos = p.pos;
        p.vel = vec3(0);
        
        return;
    }
    
    // deactivate particles off the screen until we want to drop them
    if (p.pos.y < -7.)
    {        
        if (h.x < .002)
        {
            // selected for being dropped from the chute
            p.pos = getChutePos(state) + vec3(h.y - .5, -.75, h.z - .5);
            p.vel = vec3(.5*state.chuteVel, -.01, .5*state.chuteVel);
        }
        else
        {
            // off-screen holding pen
            p.pos = vec3(0, -10, 0);
            p.vel = vec3(0);
        }
        
        return;
    }

    // particle update
    p.vel *= .99; // damping
    float velMag = length(p.vel);
    const float MAX_SPEED = .1; // clamping
    const float MIN_SPEED = .001;
    if (velMag > MAX_SPEED)
    {
        p.vel = p.vel * MAX_SPEED / velMag;
    }
    else if (velMag < MIN_SPEED)
    {
        p.vel = vec3(0);
    }
    p.vel += GRAVITY;
    p.pos += p.vel; // integrate (this is done before collision so that the rendered results are position-corrected)

    // collide with neighbors
    bool noColl = true;
    for (int i = 0; i < ((EIGHT_NBS == 1) ? 2 : 4); ++i)
    {
        for (int j = 0; j < 4; ++j)
        {
            int nid = p.nbs[i][j];
            if (nid < 0 ) break;
            fxParticle nb = fxGetParticle(nid);
            vec3 dir = p.pos - nb.pos;
            float dist = distance(nb.pos, p.pos) + 0.001;
            dir = normalize(dir);

            if (dist < PARTICLE_SIZE * 2.)
            {
                noColl = false;
                
                if (dist < PARTICLE_SIZE * .1)
                {
                    // we're overlapping another particle, emergency teleport; use id difference to decide direction
                    p.pos.x += 2. * PARTICLE_SIZE * (float(id < nid) - .5);
                    return;
                }

                float f = 1.; // relVel factor
                float r = 1.; // restitution
                if (nb.pos.y < p.pos.y + PARTICLE_SIZE * .3)
                {
                    // position correction (only applied on particles below us; stability hack)
                    p.pos = mix(p.pos, nb.pos + dir * PARTICLE_SIZE * 2., .5);
                }
                else
                {
                    // particles above us can barely move us (stability hack)
                    f = .8;
                    r = .1;
                }

                // velocity correction
                vec3 relVel = p.vel - nb.vel * f;
                p.vel -= dot(relVel, dir) * dir * r;
            }
        }
    }

    // collide with boundary
    float boundary = mapCubes(p.pos);
    if (boundary < PARTICLE_SIZE + .01) // add margin due to SDF_EPSILON, so render and physical boundaries match
    {
        vec3 normal = normCubes(p.pos);

        // position correction
        p.pos += normal * (PARTICLE_SIZE + .01 - boundary);

        // clip velocity
        p.vel -= min(0., dot(p.vel, normal)) * normal * 1.2;
    }
    
    // sleep particles that didn't move much (stability hack)
    if (noColl || distance(p.pos, p.rPos) > .05 || length(p.vel) > .01)
        p.rPos = mix(p.pos, p.rPos, .5);
}

bool iscoincidence(in ivec4 bestIds, int currentId, int id)
{
    return id == currentId || any(equal(bestIds,ivec4(id)));
}

void sort0(inout ivec4 bestIds, inout vec4 bestDists, int dataType, int currentId, int searchId, in fxParticle myParticle)
{
    if(iscoincidence(bestIds, currentId, searchId)) return; //particle already sorted
    
    vec3 nbX = fxGetParticleData(searchId, POS).xyz; 

    vec3 dx = nbX - myParticle.pos;
    
#if EIGHT_NBS
    int dir = int(float(dx.x > 0.) * .5 + .5);
#else
    int dir = int(2.*(atan(dx.z, dx.x)+PI)/PI); 
#endif
    if(dir != dataType) return; //not in this quadrant

    float t = length2(dx);
    
    insertion_sort(bestIds, bestDists, searchId, t);
}

vec4 neighborUpdate(fxParticle p, fxState state, int dataType, ivec2 ifc, int id)
{
    // nearest neighbors tracking
    // each particle tracks its 16 closest neighbors, 4 in each xz quadrant
    // dataType determines which quadrant we are computing
    ivec4 bestIds = ivec4(-1);
    vec4 bestDists = vec4(1e6);

    if (iFrame > 0 && state.resolution > 0.)
    {
        // consider existing neighbors
        for (int i = 0; i < ((EIGHT_NBS == 1) ? 2 : 4); ++i)
        {
            for (int j = 0; j < 4; ++j)
            {
                int nid = p.nbs[i][j];
                if (nid < 0) break;
                sort0(bestIds, bestDists, dataType, id, nid, p);

                // consider neighbors' neighbors
                int h = int(hash(uvec4(ifc.x * i, ifc.y * int(iResolution.x), iFrame, j)).x);
                int dir = h % ((EIGHT_NBS == 1) ? 2 : 4);
                ivec4 nbsNbs = ivec4(fxGetParticleData(nid, dir));

                for (int y = 0; y < 2; ++y)
                {
                    int nbNid = nbsNbs[y];
                    if (nbNid < 0) break;
                    sort0(bestIds, bestDists, dataType, id, nbNid, p);
                }
            }
        }

        // random search
        int searchIterations = 10;
        for(int k = 0; k < searchIterations; k++)
        {
            int h = int(hash(uvec4(ifc.x, ifc.y * int(iResolution.x), iFrame, k)).x);
            int hi = h % MAX_PARTICLES;
            sort0(bestIds, bestDists, dataType, id, hi, p);
        }
    }
    
    return vec4(bestIds);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 ifc = ivec2(fragCoord);
    int index = ifc.x + ifc.y * int(iResolution.x);
    int id = index / NUM_PARTICLE_DATA_TYPES; // which particle is this
    int dataType = index - id * NUM_PARTICLE_DATA_TYPES; // which field of this particle are we working on
    computeMaxParticles(iResolution);
    if(id>=MAX_PARTICLES) return;

    fxState state = fxGetState();
    fxParticle p = fxGetParticle(id);
    
    if (dataType < POS)
    {
        fragColor = neighborUpdate(p, state, dataType, ifc, id);
        return;
    }
    
    particleStep(p, id, state);
    fragColor = fxSaveParticle(p, dataType);
}