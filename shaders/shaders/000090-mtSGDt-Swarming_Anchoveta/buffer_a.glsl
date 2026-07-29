// Buffer A (buffer) — Swarming Anchoveta by fenix
// https://www.shadertoy.com/view/mtSGDt

// ---------------------------------------------------------------------------------------
// Particle update
// ---------------------------------------------------------------------------------------

void particleStep(inout fxParticle p, fxState state, int id)
{
    if (iFrame == 0 || state.resolution < 0.)
    {
        // init
        for (int i = 0; i < 100; ++i) // kinda dumb, but just keep trying until it's in a sphere (relax it's just init)
        {
            vec3 h = hash3( uvec3(id, iFrame, i) );

            p.pos = h * 2. - 1.;
            p.vel = vec3(0);
            
            if (length(p.pos) < 1.)
            {
                p.pos *= 1.2; // expand a bit
                p.vel.xz = p.pos.zx * vec2(1, -1) * .01; // initial swarm rotation
                return;
            }
        }
        
        return;
    }

    // particle update
    p.vel.xz += p.vel.zx * vec2(1, -1) * sin(iTime * 15. + float(id)) * .04; // swim
    p.vel.xz += p.pos.zx * vec2(1, -1) / sqrt(length(p.pos.xz)) * .0001; // swarm rotation
    p.vel.xz -= p.pos.xz * .00015; // attract to swarm center
    p.vel.y -= p.pos.y * .0001; // attract to swarm center
    
    vec3 attractPos;
    float attractStrength;
    if (iMouse.z > 0.)
    {
        // mouse interact
        attractPos = (iMouse.xy - .5 * iResolution.xy).xyy * vec3(1, 1, 0) / iResolution.y;
        attractStrength = .0005;
    }
    else
    {
        // drag the swarm around a bit more gently if no mouse, to keep it changing
        attractPos = sin(iTime * vec3(.2, 0, .2));
        attractStrength = .0001;
    }
    p.vel += (attractPos - p.pos) / length(attractPos - p.pos) * attractStrength;
    
    // collide with neighbors (only as sphere)
    for (int i = 0; i < 4; ++i)
    {
        for (int j = 0; j < 4; ++j)
        {
            int nid = p.nbs[i][j];
            if (nid < 0) break;
            fxParticle nb = fxGetParticle(nid);
            vec3 delta = nb.pos - p.pos;

            if (length(delta) > 1e-6 && length(delta) < PARTICLE_SIZE * 2.)
            {
                vec3 dir = normalize(p.pos - nb.pos);

                // position correction
                p.pos = mix(p.pos, nb.pos + dir * PARTICLE_SIZE * 2., .25);

                // clip velocity
                vec3 relVel = p.vel - nb.vel;
                p.vel -= dot(relVel, dir) * dir;
            }
        }
    }

    p.vel *= .99; // damping
    const float MAX_SPEED = .2; // clamping
    if (length(p.vel) > MAX_SPEED)
    {
        p.vel = normalize(p.vel) * MAX_SPEED;
    }

    p.pos += p.vel; // integrate
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
    
    int dir = int(2.*(atan(dx.z, dx.x)+PI)/PI); 
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
        for (int i = 0; i < 4; ++i)
        {
            for (int j = 0; j < 4; ++j)
            {
                int nid = p.nbs[i][j];
                if (nid < 0) break;
                sort0(bestIds, bestDists, dataType, id, nid, p);

                // consider neighbors' neighbors
                for (int x = 0; x < 4; ++x)
                {
                    ivec4 nbsNbs = ivec4(fxGetParticleData(nid, x));
                    for (int y = 0; y < 2; ++y)
                    {
                        int nbNid = nbsNbs[y];
                        if (nbNid < 0) break;
                        sort0(bestIds, bestDists, dataType, id, nbNid, p);
                    }
                }
            }
        }

        // random search
        int searchIterations = 3;
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
    
    particleStep(p, state, id);
    fragColor = fxSaveParticle(p, dataType);
}