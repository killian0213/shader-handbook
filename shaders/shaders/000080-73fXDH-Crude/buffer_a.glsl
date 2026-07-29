// Buffer A (buffer) — Crude by igneus
// https://www.shadertoy.com/view/73fXDH

/*
    RENDERER
    -------------------------------------------------------------------------------------------------------
    
    Both the heightfield and head are implicit surfaces, so the renderer uses ray marching to test against their geometry.
    The scalar heightfield is generatated procedurally in buffer B while the head is encoded as an SDF in a SIREN neural network.
    
    Evaluating a neural network is an expensive operation, particularly when computing multiple bounces of global illumination.
    To avoid long compile times and slow rendering, we use a trick to allow the reflection of the head to appear in the
    liquid without having to test either primitive more than once. This works by testing the heightfield first, reflecting the 
    ray, then testing the head. To account for camera rays intersecting the head but not the fluid, rays are prevented from 
    reflecting off the heighfield if:
    
        F(x) < 0 || ΔF(x) ⋅ d > 0
        
    where F and ΔF are the signed distance function and its vector derivative, x is the intersected position of the camera ray 
    with the heighfield, and d is the camera ray direction. This hack means the head can't reflect the fluid, not can the fluid
    reflect the head if it's behind it relative to the camera. Fortunately, the dynamic motion of the fluid and camera lens effects
    mean these omissions aren't especially noticable. 
    
*/

float D_GGX(vec3 m, vec3 n, float alpha)
{
    alpha *= alpha;
    float cosThetaM = clamp(dot(m, n), -1., 1.);
    float tan2ThetaM = 1. / sqr(cosThetaM) - 1.;
    return alpha * step(0.0f, cosThetaM) / 
           (kPi * pow4(cosThetaM) * sqr(alpha + tan2ThetaM));
}

float G1_GGX(vec3 v, vec3 m, vec3 n, float alpha)
{
    float cosThetaV = max(1e-10, dot(v, n));
    float tan2ThetaV = 1. / sqr(cosThetaV) - 1.;
    return step(0.0f, dot(v, m) / cosThetaV) * 2. /
           (1.0f + sqrt(1.0 + sqr(alpha) * tan2ThetaV));
}

float G_GGX(vec3 i, vec3 o, vec3 m, vec3 n, float alpha)
{
     return G1_GGX(i, m, n, alpha) * G1_GGX(o, m, n, alpha);
}

float Weight_GGX(vec3 i, vec3 o, vec3 m, vec3 n, float alpha)
{
    #define kGGXWeightClamp 1e3
    return min(kGGXWeightClamp, abs(dot(i, m)) * G_GGX(i, o, m, n, alpha) / (abs(dot(i, n) * dot(m, n))));
}

float EvaluateMicrofacetReflectorGGX(in vec3 i, in vec3 o, in vec3 n, float alpha)
{
    #define kGGXPDFClamp 50.
    
    vec3 hr = normalize(sign(dot(i, n)) * (i + o));
            
    float pdf = G_GGX(i, o, hr, n, alpha) * D_GGX(hr, n, alpha) / (4. * abs(dot(i, n) * dot(o, n)));
    return min(kGGXPDFClamp, pdf);
}

bool RayBBox(inout RayBasic localRay, out vec2 tNearFar, in vec3 lowerBound, vec3 upperBound)
{   
    tNearFar = vec2(-kFltMax, kFltMax);
    for(int dim = 0; dim < 3; dim++)
    {
        if(abs(localRay.d[dim]) > 1e-20)
        {
            float t0 = (upperBound[dim] - localRay.o[dim]) / localRay.d[dim];
            float t1 = (lowerBound[dim] - localRay.o[dim]) / localRay.d[dim];
            if(t0 < t1) { tNearFar.x = max(tNearFar.x, t0);  tNearFar.y = min(tNearFar.y, t1); }
            else { tNearFar.x = max(tNearFar.x, t1);  tNearFar.y = min(tNearFar.y, t0); }
        }
    }       
    return (tNearFar.y > tNearFar.x);
}

// Generic ray-SDF intersector
bool RayHead(inout Ray ray, inout HitCtx hit, in Transform transform)
{
    #define kSDFMaxIters 50
    #define kSDFCutoffThreshold 1e-3
    #define kSDFFailThreshold   1e-3
    #define kSDFEscapeThreshold 1.
    #define kSDFNewtonStep 1. 
    #define kSDFIsosurface 0.0
    #define kSDFBound vec3(0.76411897, 0.8099333, 1.)
            
    RayBasic localRay = RayToObjectSpace(ray.od, transform);
    float localMag = length(localRay.d);
    localRay.d /= localMag;    
    
    vec2 tNearFar;
    if(!RayBBox(localRay, tNearFar, -kSDFBound, kSDFBound)) return false;
                    
    int iterIdx;
    bool isSubsurface;
    float t = max(0., tNearFar.x);
    vec3 p = localRay.o + t * localRay.d;  
    float sdfMin = kFltMax;
     
    vec4 F;
    for(iterIdx = 0; iterIdx < kSDFMaxIters; ++iterIdx)
    {                         
        F.x = EvaluateSiren(p);       
        
        // On the first iteration, simply determine whether we're inside the isosurface or not
        if(iterIdx == 0) { isSubsurface = F.x < 0.0; }
        // Otherwise, check to see if we're at the surface
        else if(F.x > 0.0 && F.x < kSDFCutoffThreshold) { break; }        

        if(F.x > kSDFEscapeThreshold) { return false; }        
        t += isSubsurface ? -F.x : F.x;
        if(t / localMag > ray.tNear || t > tNearFar.y) { /*debug += kOne * sdfMin;*/ return false; }       
        
        p = localRay.o + t * localRay.d;
    }  
        
    // If the ray didn't find the isosurface before running out of iterations, discard it
    if(F.x > kSDFFailThreshold) { return false; }    
    ray.tNear = t / localMag;
    hit.pObj = p;
    hit.n = EvaluateSirenNormal(p).xyz * transform.rot;
    hit.kickoff = 1e-3;
    SetRayFlag(ray, kFlagsBackfacing, isSubsurface);    
    
    return true;
}

vec4 TapHeightfield(vec2 p)
{
    vec2 uv = saturate(vec2(iResolution.y / iResolution.x, 1.) * (p - kHFBBoxLower.xz) / (kHFBBoxUpper.xz - kHFBBoxLower.xz));
    vec4 texel = texture(iChannel0, uv, 0.);
    return vec4(texel.xzy, mix(kHFBBoxLower.y, kHFBBoxUpper.y, texel.w));
}

bool RayHeightfield(inout Ray ray, inout HitCtx hit)
{
    #define kHFInitStepSize .1
    #define kHFCutoffThreshold 5e-5
    #define kHFMaxIters 50
        
    vec2 tNearFar;
    if(!RayBBox(ray.od, tNearFar, kHFBBoxLower, kHFBBoxUpper)) return false;
    
    float t = max(0., tNearFar.x); 
    float dt = kHFInitStepSize;
    float y, yLast;
    int iterIdx;
    vec4 f, fLast; 
    vec3 p;
    for(iterIdx = 0; iterIdx < kHFMaxIters; ++iterIdx)
    {         
        p = ray.od.o + ray.od.d * t;
        
        f = TapHeightfield(p.xz);        
        y = p.y - f.w;
        
        if(iterIdx == 0 && y < 0.) { return false; }        
        
        if(y > 0. && y < kHFCutoffThreshold) { break; }
                
        if(iterIdx != 0 && y * yLast < 0.) { dt *= -0.5; }
        
        yLast = y; t += dt;
    }   
    if(t > ray.tNear || t > tNearFar.y) { return false; }
            
    #if kNormalMode == 0
        #define kHFDeltaNorm (1.5 / iResolution.y)
        float fx0 = TapHeightfield(p.xz + vec2(-1., 0.) * 0.5 * kHFDeltaNorm).w;
        float fx1 = TapHeightfield(p.xz + vec2(1., 0.) * 0.5 *  kHFDeltaNorm).w;
        float fy0 = TapHeightfield(p.xz + vec2(0., -1.) * 0.5 * kHFDeltaNorm).w;
        float fy1 = TapHeightfield(p.xz + vec2(0., 1.) * 0.5 *  kHFDeltaNorm).w;
        vec2 n2 = vec2(fx1 - fx0, fy1 - fy0) / kHFDeltaNorm;
        n2 = -n2 / sqrt(n2*n2 + 1.);
        hit.n = normalize(vec3(n2, sqrt(max(0., 1. - sqr(n2.x) - sqr(n2.y))))).xzy;
    #else        
        hit.n = f.xyz;
    #endif
      
    ray.tNear = t;
    hit.kickoff = 1e-3;
    return true;
}

// Evaluates the texture using a triplanar mapping
vec3 Triplanar(vec3 p, vec3 n, float scale, int type, sampler2D sampler)
{
    p *= scale;
    vec3 rgbX = texture(sampler, mod(abs(p.yz), vec2(1.)), 0.).xyz;
    vec3 rgbY = texture(sampler, mod(abs(p.xz), vec2(1.)), 0.).xyz;
    vec3 rgbZ = texture(sampler, mod(abs(p.xy), vec2(1.)), 0.).xyz;
    
    vec3 w = pow(abs(n), vec3(2.));
    w /= sum(w);    
    
    if(type == 0)
    {
        return (rgbX * w.x + rgbY * w.y + rgbZ * w.z);
    }
    else
    {    
        float L = sin01(kTwoPi * 2. * luminance(rgbX * w.x + rgbY * w.y + rgbZ * w.z));
        return kOne * L / (1. + exp(-8. * mix(-1., 1., L)));
    }
}

// Perturbs the surface normal using a triplanar texture
vec3 PerturbNormalTriplanar(vec3 p, inout HitCtx hit, float alpha, float delta, float scale, int type, sampler2D sampler)
{    
    alpha = sign(alpha) * sqr(alpha);
    delta /= scale;
 
    mat3 basis = CreateBasis(hit.n);
    float dpdu = luminance(Triplanar(p + basis[0] * -delta, hit.n, scale, type, sampler) - 
                           Triplanar(p + basis[0] * delta, hit.n, scale, type, sampler)) / (2. * delta);
    float dpdv = luminance(Triplanar(p + basis[1] * -delta, hit.n, scale, type, sampler) - 
                           Triplanar(p + basis[1] * delta, hit.n, scale, type, sampler)) / (2. * delta);

    return normalize(hit.n + (basis[0] * dpdu + basis[1] * dpdv) * alpha);    
}

struct ShadingCache
{
    vec3 i;
    vec3 n;
    vec3 r;
};

void CacheHit(Ray ray, HitCtx hit, out ShadingCache cache)
{
    cache.r = reflect(ray.od.d, hit.n);
    cache.n = hit.n;
    cache.i = ray.od.d;
}

void mainImage( out vec4 rgbaFrag, in vec2 xyFrag )
{  
    if(kApplyJPEGDamage && iFrame > 0)
    {
        #define kLevels 3
        for(int i = kLevels; i >= 0; --i)
        {
             ivec2 ij = ((ivec2(xyFrag) + (1 << max(0, i - 1))) >> i) << i;
             vec3 L = texelFetch(iChannel3, ij, 0).xyz;  
             if(pow(saturate(luminance(L) * 1.5), 0.3) >= float(i) / float(kLevels))
             {
                 xyFrag = vec2(ij);
                 break;
             }
        }
    }
            
    vec2 uvView = ScreenToNormalisedScreen(xyFrag, iResolution.xy);    
  
    float time = GetTime();
    CameraCtx camera = GetCameraCtx(time);
    
    rgbaFrag *= 0.;   
    
    // Construct the ray
    Ray ray;
    ray.od.o = camera.position;
    ray.od.d = transpose(camera.basis) * normalize(vec3(uvView, -1. / tan(toRad(camera.fov))));
    ray.tNear = kFltMax;
    ray.weight = kOne;
    ray.flags = kFlagsCausticPath;
    ray.depth = 0;
      
    HitCtx hit;  
    int hitId = 0;  
    ray.tNear = kFltMax;
    ShadingCache cache;
    
    bool showHeightfield = !IsKeyDown(iChannel0, iRes.xy, 3);
   
    // Test the heightfield    
    if(showHeightfield && RayHeightfield(ray, hit)) 
    {   
        ray.weight *= FresnelApprox(dot(-ray.od.d, hit.n), 1., 3.) * 0.7;
        CacheHit(ray, hit, cache);
        hitId |= 1;
    }           
    
    // Construct the transform for the head
    Transform transform = ComposeHeadTransform(iChannel0, iResolution.xy);
    
    // Focal plane reticule
    //if(abs(length(uvView - PointToCameraSpace(transform.pos, camera)) - 0.02) < 0.003) { rgbaFrag = vec4(kRed, 1.); return; }
                                           
    // Check whether the intersection point on the heightfield can be excluded from reflection
    bool exclude = false;
    if(hitId == 1)
    {        
        vec3 p = PointToObjectSpace(PointAt(ray), transform);
        RayBasic localRay = RayToObjectSpace(ray.od, transform);
        vec2 tNearFar;
        if(dot(normalize(p.xz), localRay.d.xz * transform.sca) > 0.)
        {
            exclude = true;
        }
        if(RayBBox(localRay, tNearFar, -kSDFBound, kSDFBound) )          
        {   
            if(ray.tNear > tNearFar.x && ray.tNear < tNearFar.y)
            {
                // NOTE: The quality of the NN reconstruction is very crappy away from |f| = 0. The dot product below is a hack to make it work
                vec4 sn = EvaluateSirenNormal(p);                
                if(sn.w <= 0.001 || dot(sn.xz, localRay.d.xz) > 0.)
                {
                    exclude = true;
                }
                
                // Blend the heightfield and SDF normals to create the illusion of surface tension
                sn.w = cub(1. - saturate(8. * abs(sn.w)));
                hit.n = normalize(mix(hit.n, sn.xyz * transform.rot, .7 * sn.w));
                CacheHit(ray, hit, cache);

                //rgbaFrag = vec4(hit.n * 0.5 + 0.5, 1.); return;
            }
            else if(ray.tNear > tNearFar.y) exclude = true;
        }
    }
            
    if(showHeightfield && !exclude)
    {
        ray.od.o = PointAt(ray) + hit.n * 1e-4;
        ray.od.d = reflect(ray.od.d, hit.n);
        ray.tNear = kFltMax;
    }
    
    float wetness = 1.;
    if(RayHead(ray, hit, transform))
    {                
        hitId |= 2;   
        
        if(exclude) hitId = 2;
        
        vec3 i = normalize(PointToObjectSpace(PointAt(ray), transform));
        float phi = atan(i.z, i.x) / kTwoPi + 0.5;
        float theta = 1. - acos(i.y) / kPi;
        vec2 uv = vec2(mix((iResolution.y + 3.) / iResolution.x, 1., phi),
                       theta * 0.5 * (iResXYRatio - 1.));
        vec4 texel = texture(iChannel0, uv, -1.);
        wetness = sqr(saturate(texel.w));
        
        hit.n = mix(PerturbNormalTriplanar(hit.pObj, hit, 0.2, 0.001, .7, 1, iChannel2), hit.n, mix(.0, 1., wetness));
        CacheHit(ray, hit, cache);

        ray.weight = kOne;
        //ray.weight *= saturate(1. * sqrt(Triplanar(hit.pObj, hit.n, 0.7, 0, iChannel2).x));

    }  
    
    vec3 L = kZero;
    if(wetness > 0.)
    {        
        float LEnv = luminance(texture(iChannel1, cache.r, -1.).xyz);
        
        #if kColourfulMode != 0
            LEnv = pow(LEnv, 0.65);
        #endif
        
        L = vec3(pow(1. * LEnv, 1.5) + pow(4.0 * max(0., 1.4 * LEnv - 0.5), 2.)) * ray.weight;  
        
        if((hitId & 2) != 0)
        {
            L *= FresnelApprox(dot(-ray.od.d, hit.n), 1., 3.) * 0.7 * wetness;
        }
    }    
    
    if((hitId & 2) != 0)
    {
        vec3 lightPos = normalize(vec3(-0.6, 1, 0.5) - PointAt(ray));
        float cosTerm = dot(hit.n, lightPos); 
        if(cosTerm > 0.)
        {
            float LGGX = max(0., EvaluateMicrofacetReflectorGGX(-ray.od.d,lightPos, hit.n, mix(0.3, 0.05, wetness)));
            LGGX *= Smoothstep(saturate(2. * cosTerm));
    
            L += .8 * (1. - wetness) * (0.5 * LGGX + 
                                        0.3 * ray.weight * cosTerm);                
        }
    }        
    
    #if kColourfulMode != 0
        L *= 2.5 * ThinFilm(cache.i, cache.n, cache.r, mix(0.52, 0.3, wetness), ivec2(xyFrag));
    #endif
    
    rgbaFrag.xyz = L;
    rgbaFrag.w = 1.; 
}