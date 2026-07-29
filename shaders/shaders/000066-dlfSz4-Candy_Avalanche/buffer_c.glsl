// Buffer C (buffer) — Candy Avalanche by fenix
// https://www.shadertoy.com/view/dlfSz4

// ---------------------------------------------------------------------------------------
// G buffer render
// ---------------------------------------------------------------------------------------


// draw one ball
void renderParticle(int id, fxParticle p, vec3 ro, vec3 rd, inout fxGBufferPixel pix)
{
    float t = sphIntersect(ro, rd, vec4(p.rPos, PARTICLE_SIZE));
    if (t > 0. && t <= pix.t && p.pos != vec3(0))
    {
        vec3 hitPos = ro + rd * t;
        vec3 normal = normalize(hitPos - p.rPos);

        pix.n = normal;
        pix.m = float(id + 2); // materials 0...1 are for box
        pix.t = t;
    }
}

vec3 marchCubes(vec3 p, vec3 rd, out float t)
{
    const int MAX_STEPS = 25;
    const float SDF_EPS = .01;
    t = dot(p, vec3(1));
    p += rd * t;
    for (int i = 0; i < MAX_STEPS; ++i)
    {
        float d = mapCubes(p);
        if (abs(d) < SDF_EPS) break;
        d *= .6;
        p += d * rd;
        t += d;
    }
    return p;
}

vec3 marchChute(vec3 p, vec3 rd, out float t, fxState state)
{
    const int MAX_STEPS = 15;
    const float SDF_EPS = .01;
    t = 0.;
    p += rd * t;
    for (int i = 0; i < MAX_STEPS; ++i)
    {
        float d = mapChute(p, state);
        if (abs(d) < SDF_EPS) break;
        p += d * rd;
        t += d;
    }
    return p;
}

void renderScene(vec3 cameraPos, vec3 rayDir, fxState state, inout fxGBufferPixel pix)
{
    // march cubes and chute separately, otherwise it takes a lot of steps to get around the chute
    float cubeT;
    vec3 cubeHitPos = marchCubes(cameraPos, rayDir, cubeT);
    vec3 cubeNormal = normCubes(cubeHitPos);
    
    float chuteT;
    vec3 chuteHitPos = marchChute(cameraPos, rayDir, chuteT, state);
    vec3 chuteNormal = normChute(chuteHitPos, state);
    
    if (cubeT < chuteT)
    {
        pix.n = cubeNormal;
        pix.t = cubeT;
        pix.m = 0.;
    }
    else
    {
        pix.n = chuteNormal;
        pix.t = chuteT;
        pix.m = 1.;
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fxState state = fxGetState();
   
    vec3 cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp;
    fxCalcCamera(state, cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp);

    vec3 rayDir = fxCalcRay(fragCoord, iResolution, cameraFwd, cameraUp, cameraLeft);

    fxGBufferPixel pix;
    pix.t = FAR_CLIP;
    
    // render box
    renderScene(cameraPos, rayDir, state, pix);

    // render particles
    ivec4 old = fxGetClosest( ivec2(fragCoord) );      
    for (int j = 0; j < 4; j++)
    {
        int id = old[j];
        if (id < 0) break;
        fxParticle data = fxGetParticle(id);
        renderParticle(id, data, cameraPos, rayDir, pix);
    }
    
    fragColor = fxPackGBuffer(pix);
}
