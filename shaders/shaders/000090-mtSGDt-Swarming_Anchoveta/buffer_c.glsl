// Buffer C (buffer) — Swarming Anchoveta by fenix
// https://www.shadertoy.com/view/mtSGDt

// ---------------------------------------------------------------------------------------
// G buffer render
// ---------------------------------------------------------------------------------------

// draw one fish
bool renderParticle(int id, fxParticle p, vec3 ro, vec3 rd, inout fxGBufferPixel pix)
{
    vec3 normal;
    float t = fishIntersect(p, ro, rd, normal);
    if (t > 0. && t < pix.t)
    {
        pix.n = normal;
        pix.t = t;
        return true;
    }
    return false;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fxState state = fxGetState();
   
    vec3 cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp;
    fxCalcCamera(cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp);

    vec3 rayDir = fxCalcRay(fragCoord, iResolution, cameraFwd, cameraUp, cameraLeft);

    fxGBufferPixel pix;
    pix.t = FAR_CLIP;

    // render particles
    ivec4 old = fxGetClosest( ivec2(fragCoord) );      
    for (int j = 0; j < 4; j++)
    {
        int id = old[j];
        if (id < 0) break;
        fxParticle data = fxGetParticle(id);
        if (!renderParticle(id, data, cameraPos, rayDir, pix)) break;
    }
    
    fragColor = fxPackGBuffer(pix);
}
