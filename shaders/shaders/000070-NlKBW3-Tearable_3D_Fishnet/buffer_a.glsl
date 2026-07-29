// Buffer A (buffer) — Tearable 3D Fishnet by fenix
// https://www.shadertoy.com/view/NlKBW3

// ---------------------------------------------------------------------------------------
// Computes the position of each particle.
// ---------------------------------------------------------------------------------------

const vec3 GRAVITY = vec3(0,-1,0);

const float WIND_SPEED = 100.; // wind strength
const float WIND_CHANGE_RATE = .5; // wind change speed
const float WIND_RIPPLE = .01; // wind variance
const float EDGE_BREAK_LEN = 5.; // length over rest length before breaking
const float COMPRESSION_RESIST = .005; // stiffness

void constraint(inout int nid, inout fxParticle p, float edgeLen)
{
    if (nid < 0) return;
    
    fxParticle n = fxGetParticle(nid);
    
    if (n.disabled)
    {
        nid = -1;
        return;
    }
    
    vec3 deltaPos = n.pos - p.pos;
    float len = length(deltaPos);
    vec3 dir = deltaPos / len;
    
    float error = len - edgeLen;
    
    if (error < 0.) error *= COMPRESSION_RESIST;
    if (distance(p.prev, n.pos) > edgeLen * EDGE_BREAK_LEN) p.disabled = true; // fragile cloth
    
    float f = n.pinned ? 1.0 : .7;
    p.pos += dir * error * f;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 iFragCoord = ivec2(fragCoord);
    int index = iFragCoord.x + iFragCoord.y*int(iResolution.x);
    int id = index / NUM_PARTICLE_DATA_TYPES;
    int dataType = index - id * NUM_PARTICLE_DATA_TYPES;
    computeClothSide(iResolution);
    if(id>=MAX_PARTICLES) return;

    vec4 state = texelFetch(iChannel1, ivec2(0), 0);

    fxParticle p = fxGetParticle(id);
    
    if (!p.pinned && !p.disabled)
    {
        p.prev = p.pos;
        p.pos += p.pos - p.prev + GRAVITY; // verlet
        p.pos.z += WIND_SPEED * sin((float(id % CLOTH_SIDE) * WIND_RIPPLE + iTime * WIND_CHANGE_RATE)); // wind

        // edge constraints
        int a, b, l, r;
        a = b = l = r = id;
        
        float EDGE_LEN = SIDE_LEN / float(CLOTH_SIDE);
        float CARDINAL_ITERATIONS = 45.;
        for (float i = 1.; i < CARDINAL_ITERATIONS; ++i)
        {
            a = above(a);
            b = below(b);
            r = right(r);
            l = left(l);

            float sLen = EDGE_LEN * i;
            constraint(a, p, sLen);
            constraint(b, p, sLen);
            constraint(r, p, sLen);
            constraint(l, p, sLen);
        }

#define DIAGONAL_CONSTRAINTS 1

#if DIAGONAL_CONSTRAINTS
        int al, ar, bl, br;
        al = ar = bl = br = id;
        
        float DIAGONAL_ITERATIONS = 25.;
        for (float i = 1.; i < DIAGONAL_ITERATIONS; ++i)
        {
            ar = above(right(ar));
            al = above(left(al));
            br = below(right(br));
            bl = below(left(bl));

            float dLen = EDGE_LEN * i * sqrt(2.);
            constraint(al, p, dLen);
            constraint(ar, p, dLen);
            constraint(bl, p, dLen);
            constraint(br, p, dLen);
        }
#endif // DIAGONAL_CONSTRAINTS
    }
    
    // Reset particles that have gotten too old
    if (iFrame == 0 || state.x < 0.)
    {   
        float x = float(id % CLOTH_SIDE) / float(CLOTH_SIDE) - 0.5;
        float y = 0.5 - float(id)/float(CLOTH_SIDE*CLOTH_SIDE);
        p.pos = vec3(x + y, x - y, 0.) * SIDE_LEN / sqrt(2.);
        p.prev = p.pos;
        
        // pin sides
        p.pinned = id < CLOTH_SIDE || id >= (CLOTH_SIDE - 1) * CLOTH_SIDE || (id % CLOTH_SIDE) == 0 || (id % CLOTH_SIDE) == (CLOTH_SIDE - 1);
        //if (id % (CLOTH_SIDE / 10) == 0 && (id / CLOTH_SIDE) % (CLOTH_SIDE / 10) == 0) p.pinned = true; // quilt pinning
        p.disabled = false;
    }
    
    bool del = false;
    vec2 from, to;
    if (iMouse.z > 0. && iMouse.w < 0.)
    {
        // mouse input
        from = vec2(2.*iResolution.x/iResolution.y, 2.) * state.yz / iResolution.xy - vec2(iResolution.x/iResolution.y, 1.);
        to = vec2(2.*iResolution.x/iResolution.y, 2.) * iMouse.xy / iResolution.xy - vec2(iResolution.x/iResolution.y, 1.);
        del = true;
    }
    else if (state.yz == vec2(0) && state.w > 0.5)
    {
        // attract mode
        from = vec2(sin((iTime - iTimeDelta) * 2.), cos((iTime - iTimeDelta) * 5.2)) * vec2(iResolution.x / iResolution.y, 1.) * 0.9;
        to = vec2(sin(iTime * 2.), cos(iTime * 5.2)) * vec2(iResolution.x / iResolution.y, 1.) * 0.9;
        del = sin(iTime * 23.) > 0.2;
    }

    if (del)
    {
        vec3 cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp;
        fxCalcCamera(cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp);

        mat4 c2w = fxCalcCameraMat(iResolution, cameraLeft, cameraUp, cameraFwd, cameraPos);
        mat4 w2c = inverse(c2w);
        
        vec3 posCamera = (w2c * vec4(p.pos,1.0)).xyz;
        posCamera.xy = posCamera.xy / posCamera.z;     
        
        float dist2 = fxLinePointDist2(from, to, posCamera.xy);

        if (dist2 < 0.0005) p.disabled = true;
    }

    fragColor = fxSaveParticle(p, dataType);
}