// Buffer D (buffer) — Candy Avalanche by fenix
// https://www.shadertoy.com/view/dlfSz4

// ---------------------------------------------------------------------------------------
// Main render
// ---------------------------------------------------------------------------------------

// decode color from G buffer material
#define RGB(R, G, B) vec3(float(R), float(G), float(B)) / 255.0
vec3 materialColor(float c)
{
    if (c <= .5) return vec3(1);
    if (c <= 1.5) return vec3(.25);
    
    // sphere colors
    switch(int(c - 2.) % 5)
    {
        case 0: return RGB(255,46,0);
        case 1: return RGB(221,150,2);
        case 2: return RGB(4,150,7);
        case 3: return RGB(48,11,53);
        case 4: return RGB(140,4,12); 
    }
}

float calcAO(fxGBufferPixel pix, vec2 fragCoord, vec3 sNorm)
{
    if (pix.m == 1.) return 1.;// chute doesn't get occluded
    if (keyDown(KEY_SHIFT)) return 1.;
    
    // sample neighbor pixels
    float ao = 0.;
    const float SAMPLES = 20.; // increase for higher quality if your GPU can handle it
    for( float i=0.; i<SAMPLES; i++ )
    {
        // compute an offset in a spiral pattern
        vec2 off = vec2(.2 + i * 40. / SAMPLES, 0) * rotMat(i * 20. / SAMPLES) / pix.t;
        off += .1 * sNorm.xy / sNorm.z; // search more in the diretion of surface normal

        // sample the zbuffer at a neightbor pixel		
        fxGBufferPixel nbPix = fxUnpackGBuffer(texture(iChannel0, (fragCoord.xy) / iResolution.xy + off * .015));

        if (nbPix.m != 1.) // chute doesn't cause occlusion (prevents black halo)
        {
            vec2 td = min(vec2(0), 2. * sNorm.xy * off / sNorm.z);
            float xt = pix.t + td.x + td.y - PARTICLE_SIZE * .0; // expected t based on plane determined by initial point and slope

            // accumulate occlusion	
            float dt = xt - nbPix.t;
            ao += smoothstep(0., .1, dt) * smoothstep(1., .5, dt); // blend out below .1 (not taller) and above .5 (foreground object)
        }
    }
    
    // average down the occlusion	
    return clamp(1. - pow(ao,1.4)/SAMPLES, 0., 1.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fxState state = fxGetState();
    fxGBufferPixel pix = fxUnpackGBuffer(texture(iChannel0, fragCoord/iResolution.xy));
    if (pix.t >= FAR_CLIP)
    {
        // background
        fragColor = vec4(.2);
    }
    else
    {    
        vec3 cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp;
        fxCalcCamera(state, cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp);

        vec3 rayDir = fxCalcRay(fragCoord, iResolution, cameraFwd, cameraUp, cameraLeft);

        // construct basis for screen-space normal
        vec3 left = -normalize(cross(rayDir, vec3(0, 1, 0)));
        vec3 up = normalize(cross(left, rayDir));
        mat3 basis = mat3(left, up, rayDir);

        // screen-space normal
        vec3 sNorm = pix.n * basis;
        
        float ao = calcAO(pix, fragCoord, sNorm);
        
        // lighting
        const vec3 LIGHT_DIR = normalize(vec3(.5, 1, -.7));
        float nDotL = max(dot(pix.n, LIGHT_DIR), .0);
        float dif = ao * (nDotL * .9 + .1) + .1;
        vec3 reflection = reflect(-LIGHT_DIR, pix.n);
        float spec = ao * pow(max(dot(pix.n, reflection), 0.), 50.0);
        fragColor.xyz = materialColor(pix.m) * dif + spec;
    }
    
    // Simple vignette effect by Ippokratis
    // https://www.shadertoy.com/view/lsKSWR
	vec2 uv = fragCoord.xy / iResolution.xy;
    uv *=  1.0 - uv.yx;   //vec2(1.0)- uv.yx; -> 1.-u.yx; Thanks FabriceNeyret 
    float vig = uv.x*uv.y * 5.; // multiply with sth for intensity
    vig = sqrt(vig); // change pow for modifying the extend of the  vignette
    fragColor *= vig;

    fragColor.a = 1.;
}