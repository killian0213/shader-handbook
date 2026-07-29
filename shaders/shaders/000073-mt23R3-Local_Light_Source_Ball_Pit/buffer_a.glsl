// Buffer A (buffer) — Local Light Source Ball Pit by fenix
// https://www.shadertoy.com/view/mt23R3

// ---------------------------------------------------------------------------------------
// Particle update
// ---------------------------------------------------------------------------------------

const vec3 GRAVITY = vec3(0,-.0005,0);

void particleStep(inout fxParticle p, fxState state, vec2 fragCoord)
{
    if (iFrame == 0 || state.resolution < 0.)
    {
        // init
        vec3 h = hash3( uvec3(fragCoord, iFrame) );

        p.pos = h * 2. - 1.;
        p.vel = vec3(0);
        
        return;
    }

    // particle update
    p.vel *= .995; // damping
    const float MAX_SPEED = .025; // clamping
    if (length(p.vel) > MAX_SPEED)
    {
        p.vel = normalize(p.vel) * MAX_SPEED;
    }
    p.vel += GRAVITY;

    for (int iter = 0; iter < 3; ++iter)
    {
        // collide with neighbors
        for (int i = 0; i < 4; ++i)
        {
            for (int j = 0; j < 4; ++j)
            {
                int nid = p.nbs[i][j];
                if (nid < 0) break;
                fxParticle nb = fxGetParticle(nid);

                if (nb.pos.y < p.pos.y && // only react to particles below us (stability hack)
                    distance(nb.pos, p.pos) < PARTICLE_SIZE * 2.)
                {
                    vec3 dir = normalize(p.pos - nb.pos);

                    // position correction
                    p.pos = mix(p.pos, nb.pos + dir * PARTICLE_SIZE * 2., .05);

                    // clip velocity (stability hack, should be relative velocity)
                    p.vel -= dot(p.vel, dir) * dir;
                }
            }
        }

        // collide with boundary
        float boundary = scene(p.pos, state);
        if (boundary < PARTICLE_SIZE)
        {
            vec3 normal = sceneNormal(p.pos, state);

            // position correction
            p.pos += normal * (PARTICLE_SIZE - boundary);

            // clip velocity
            vec3 boxVel = .01*cross(p.pos, vec3(-state.boxVel.y, 0, state.boxVel.x));
            p.vel -= min(0., dot(p.vel - boxVel, normal)) * normal;
        }
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

                // randomly consider one of the neighbors' neighbors
                int h = int(hash(uvec4(ifc.x * i, ifc.y * int(iResolution.x), iFrame, j)).x);
                int dir = h % 4;
                ivec4 nbsNbs = ivec4(fxGetParticleData(nid, dir));
                for (int y = 0; y < 4; ++y)
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
    
    particleStep(p, state, fragCoord);
    fragColor = fxSaveParticle(p, dataType);
}