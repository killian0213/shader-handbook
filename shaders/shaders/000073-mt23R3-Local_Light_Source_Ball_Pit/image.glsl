// Image (image) — Local Light Source Ball Pit by fenix
// https://www.shadertoy.com/view/mt23R3

// ---------------------------------------------------------------------------------------
//	Created by fenix in 2023
//	License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
//  5000 particles lit by 200 local light sources. This is very nearly the same particle
//  sim as its predecessor, just with new lighting.
//
//    SSAO Rotating Ball Pit            https://shadertoy.com/view/cl23Ww
//
//  Deferred rendering can do more than just screen space ambient occlusion! It's good
//  for rendering lots of lights as well. I've done that before in other shaders like
//
//    Arctic Fireflies                  https://shadertoy.com/view/cssSRs
//    Sparks on Swiss Cheese Mountain   https://shadertoy.com/view/7tyyW1
//    Spark Volcano 2                   https://shadertoy.com/view/7lKczD
//
//  The new thing in this shader is screen-space shadows. Press shift to disable to see
//  the difference. I'm doing a DDA-type traversal of the screen between each light
//  source and each rendered pixel, looking for depth that should occlude some or all of
//  the light. This results in passable soft shadows that can be cast quite a distance.
//
//  Buffer A simulates particles and tracks particle neighbors in 3D
//  Buffer B computes nearest particles to each screen pixel
//  Buffer C renders G buffer
//  Buffer D computes nearest lights to each screen pixel
//  Image performs lighting and occlusion
//
//  Update 1/15/23: fixed normals on two walls, doubled light sources
// ---------------------------------------------------------------------------------------

// decode color from G buffer material
vec3 materialColor(float c)
{
    if (c <= 1.) return mix(vec3(1), vec3(.5), c); // color between 0 and 1 is the box
    switch(int(c / float(LIGHT_RATIO)) % 2)
    {
        case 0: return vec3(.5);
        case 1: return vec3(1);
    }
}

// decode emissivity from G buffer material
vec3 materialEmis(float c)
{
    if ((int(c) % LIGHT_RATIO) != 2) return vec3(0);
    switch(int(c / float(LIGHT_RATIO)) % 3)
    {
        case 0: return vec3(1,.5,.1);
        case 1: return vec3(1,.3,1);
        case 2: return vec3(0,1,.5);
    }
}

// From https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm(vec3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return clamp((x*(a*x+b))/(x*(c*x+d)+e), 0., 1.);
}

vec2 intersectXY(ivec2 xy, vec2 from, vec2 dir) { return (vec2(xy) - from) / dir; }
float sum(vec2 x) { return x.x + x.y; }

float occluded(fxParticle light, vec2 fragCoord, float t, mat4 w2c)
{
	vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;

    vec3 lc = (w2c * vec4(light.pos,1.0)).xyz;
    lc.xy = ((lc.xy / lc.z) * iResolution.y + iResolution.xy) * .5;
    
    // account for particle size 
    t += PARTICLE_SIZE;
    
    // get the depth at light source
    fxGBufferPixel lp = fxUnpackGBuffer(texture(iChannel1, (lc.xy) / iResolution.xy));
    
    // compute the gradient of t
    float tDelta = (lp.t - t) / length(fragCoord - lc.xy);
    
    // don't bother searching past some distance, light will be very dim anyway
    if (distance(lc.xy, fragCoord) > 500.) return 1.;

    // setup traversal
    vec2 rayDir = lc.xy - fragCoord;
    vec2 cur = fragCoord;
	ivec2 mapPos = ivec2(floor(fragCoord));
	ivec2 finalMapPos = ivec2(floor(lc.xy));
	vec2 deltaDist = abs(length(rayDir) / rayDir);
    ivec2 rayStep = ivec2(sign(rayDir));
    vec2 fixup = sign(rayDir) * 0.5 + 0.5;
	vec2 sideDist = (sign(rayDir) * (vec2(mapPos) - fragCoord) + fixup) * deltaDist; 
	
    float occ = 0.;

    const int MAX_RAY_STEPS = 64;
	for (int i = 0; i < MAX_RAY_STEPS; i++)
    {
		if (mapPos == finalMapPos)
        {
            break;
        }
        
        bvec2 mask = lessThanEqual(sideDist.xy, sideDist.yx);

        vec2 ts = intersectXY(mapPos + ivec2(fixup), fragCoord, rayDir);
        vec2 next = fragCoord + rayDir * sum(vec2(mask) * ts);
        
        fxGBufferPixel pix = fxUnpackGBuffer(texelFetch(iChannel1, mapPos, 0));
        
        // compute curent t
        t += length(cur - next) * tDelta;

        // add up occlusion
        occ += t - pix.t;
        
        // go to the next pixel
        cur = next;
		sideDist += vec2(mask) * deltaDist;
		mapPos += ivec2(vec2(mask)) * rayStep;
	}

    return 1. - clamp(occ, 0., 1.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fxGBufferPixel pix = fxUnpackGBuffer(texture(iChannel1, fragCoord/iResolution.xy));
    
    vec3 cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp;
    fxCalcCamera(cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp);
    
    vec3 rayDir = fxCalcRay(fragCoord, iResolution, cameraFwd, cameraUp, cameraLeft);

    if (pix.t >= FAR_CLIP)
    {
        // background
        fragColor = vec4(.2);
    }
    else
    {
        // ssao model inspired by SSAO (basic) by iq: https://www.shadertoy.com/view/Ms23Wm
        // sample neighbor pixels
        mat4 c2w = fxCalcCameraMat(iResolution, cameraLeft, cameraUp, cameraFwd, cameraPos);
        mat4 w2c = inverse(c2w);

        vec3 pixelPos = cameraPos + rayDir * pix.t;
        //vec3 lightColor = vec3(0);
        vec3 pixel = materialEmis(pix.m);
        
        // lighting
        ivec4 old = fxGetClosestLights( ivec2(fragCoord) );
        for (int j = 0; j < 4; j++)
        {
            int id = old[j];
            if (id < 0) break;
            fxParticle light = fxGetParticle(id);
            
            float occ = occluded(light, fragCoord, pix.t, w2c);
            if (keyDown(KEY_SHIFT)) occ = 1.;
            
            //renderParticle(id, data, cameraPos, rayDir, pix);
            vec3 lightDelta = light.pos - pixelPos;
            vec3 lightColor = .5 * materialEmis(float(id + 2)) / pow(length2(lightDelta), .8);
            
            float nDotL = max(dot(pix.n, normalize(lightDelta)), .0);
            float dif = occ * (nDotL * nDotL * .05 + .001) + .002;
            pixel += (lightColor * dif + .01) * materialColor(pix.m);
        }

        fragColor.xyz = pixel;
    }
    
    // Simple vignette effect by Ippokratis
    // https://www.shadertoy.com/view/lsKSWR
	vec2 uv = fragCoord.xy / iResolution.xy;
    uv *=  1.0 - uv.yx;   //vec2(1.0)- uv.yx; -> 1.-u.yx; Thanks FabriceNeyret 
    float vig = uv.x*uv.y * 5.; // multiply with sth for intensity
    vig = sqrt(vig); // change pow for modifying the extend of the  vignette
    fragColor *= vig;

    fragColor.xyz = pow(ACESFilm(fragColor.xyz), vec3(1./2.2));
    fragColor.a = 1.;
}
