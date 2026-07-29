// Buffer C (buffer) — Phoenix Ascending by igneus
// https://www.shadertoy.com/view/WclSWl

// *******************************************************************************************************
//    Level set rendering of the fluid lattice 
// *******************************************************************************************************

vec3 RenderFlow(vec2 xyView)
{
    ivec2 gridDims = GetLGAGridDims(iResolution.xy);
    int gridArea = gridDims.x*gridDims.y;
    ivec2 ij = ivec2(ViewToLGAGridPos(xyView, gridDims, iResolution.xy));
        
    if(!IsValidLGAGridIdx(ij, gridDims)) return kZero;
        
    #define kSearchRadius 10
    float F = 0.;
    float d2Near = kFltMax;
    float massNear = 0.;
    float spreadNear = 0.;
    vec2 vNear, vAccum = vec2(0.);
    float sumWeights = 0.;
    vec3 L = kZero;
    for(int v = -kSearchRadius; v <= kSearchRadius; ++v)
    {
        for(int u = -kSearchRadius; u <= kSearchRadius; ++u)
        {
            if(ij.x + u < 0 || ij.x + u >= gridDims.x || ij.y + v < 0 || ij.y + v >= gridDims.y) { continue; }
 
            vec4 state = texelFetch(iChannel0, ij + ivec2(u, v), 0);
            if(!IsDormant(state))
            {
                vec2 pK, vK;
                float massK;
                UnpackLGAState(state, LGAGridIdxToView(ij + ivec2(u, v), gridDims, iResolution.xy), pK, vK, massK);
                pK -= vK;
                
                //float d = length(uvView - pK/* + vK*/);
                vK *= 2.;
                float t = saturate((dot(xyView, vK) - dot(pK, vK)) / dot(vK, vK));
                float d2 = length2(pK + t * vK - xyView) * 0.25;
                F += pow(kLGAParticleRadius, 2.) / (1e-10 + d2);
                
                if(d2 < d2Near)
                {
                    massNear = massK;
                    d2Near = d2;
                    vNear = vK;
                }
                
                float weight = 1.;                
                vAccum += vK * weight;
                sumWeights += weight;                
              
                L = mix(L, kOne, SDFLine(xyView, pK, pK + vK, 0.003, 2. / iResolution.y));
            }
        }
    }   
    
    vAccum /= max(1., sumWeights);
    
    vec2 vNearNorm = SafeNormalize(vAccum);
    vec3 colour = mix(Hue(mix(0.95, 1.15, sin01(kTime + 3. * atan2(vNearNorm.x, vNearNorm.y)))), kOne, 0.2);   
    
    float gamma = exp(-sqr(sumWeights * 0.1));
    //colour = mix(kGreen, kRed, gamma);
    F = saturate((F - mix(0.5, 2., gamma)) / (10. * mix(0.1, 5.5, gamma)));
    vec3 rgb = kZero;//kOne * 0.2;
    rgb = mix(rgb, colour, F);
    rgb += L * 0.3;        
    
    return saturate(rgb);
}

void mainImage( out vec4 rgbaFrag, in vec2 xyFrag )
{
    vec2 xyView = ScreenToNormalisedScreen(xyFrag, iResolution.xy) * 1.;
    
    // Render the particle flow field
    vec3 L = RenderFlow(xyView);  
    
    // Sample the properties of the hawk and overlay to enhance the glass and bloom effects on the next pass
    vec4 hawk = SampleHawk(xyView, iResolution.xy, kTime, iChannel1);
    L = max(L, kOne * tanh(hawk.y) * 0.7 * hawk.w);
    
    // Apply accumulation motion blur
    #define kParticleMotionBlur 0.  
    if(kParticleMotionBlur <= 0.)
    {
       rgbaFrag = vec4(L, 1.);
    }
    else
    {    
        vec4 L0 = vec4(0.);
        float sumW = 0.;
        for(int j = -1; j <= 1; ++j)
        {
            for(int i = -1; i <= 1; ++i)
            {
                float w = 1.;// - (length(float(i*i + j*j)) - 0.5);
                if(w > 0.)
                {
                    vec2 xi =  texelFetch(iChannel3, ivec2(xyFrag) + ivec2(i, j), 0).xy; 
                    L0 += texture(iChannel2, (xyFrag + (vec2(i, j) + xi) * 2.) / iResolution.xy, 0.) * w;
                    sumW += w;
                }
            }
        }

        rgbaFrag.xyz = max(kParticleMotionBlur * L0.xyz / sumW, L);
        rgbaFrag.w = 1.;
    }

}