// Buffer B (buffer) — Crude by igneus
// https://www.shadertoy.com/view/73fXDH

/*
    SEPARABLE DEFOCUS BLUR OPTIMIZER
    -------------------------------------------------------------------------------------------------------
    
    By computing the singular value decomposition (SVD) of a filter expressed as an NxN matrix, arbitrary 
    kernels can be approximated as separable blurs. This reduces the average complexity from O(n^2)
    to O(n) texture taps. 
    
    The SVD of matrix M is defined as
    
        M = U ⋅ S ⋅ V^T
    
    where U and V are orthonormal bases and S is a diagonal matrix where the number of non-zero values 
    corresponds to the rank of the filter kernel. M can be completely reconstructed from these components by summing over 
    the outer products of successive pairs of rows and columns of U and V^T, then multiplying them by their
    respective singular value on the diagonal in S. 
    
        M = Σ_i [S_i ⋅ U_i ⊗ V_i]
    
    For simple convolution kernels, we can accumulate the products of only a handful of the largest values 
    of S and still get a reasonable reconstruction of M. Instead of computing the full SVD of the filter 
    kernel, this code relies on stochastic gradient descent to find pairs of vectors corresponding to the 4
    largest singular values.
    
    Modify the aperture parameters in the Common source file to adjust the appearance filter. If the optimizer becomes
    unstable (e.g. strobing or flickering), try reducing the learning rate. Note that the kernel is not automatically 
    normalized, so it may be necessary to increase the gain if the image appears too dark.
    
    
    HEIGHTFIELD AND WETMAP EVALUATOR
    -------------------------------------------------------------------------------------------------------
    
    In addition to the optimizer, the pass is divided up into two planes: the heightfield and the wetmap.
    
    The heightfield is a procedural function that's sampled by the renderer to simulate a moving fluid. Fractal
    noise is used to define both the height and motion of the field over time.
    
    The wetmap is used to simulate the effect of the fluid sticking to, and flowing from the head as the waves wash
    over it. This requires finding the set of points at the surface of the SDF then determining whether each one
    is above or below the surface of the heightfield. The map is also used by the renderer to create a mask that
    determines the appearance of the shader.
*/

#define kStateBlockWidth (kDoFKernelSize * 2)

int TexelXYToStateIdx(ivec2 xy)
{
    return kStateBlockWidth * (xy.y - kDoFParamsY) + (xy.x - kDoFParamsX);
}

ivec2 StateIdxToTexelXY(int idx)
{
    return ivec2(kDoFParamsX + (idx % kStateBlockWidth), kDoFParamsY + idx / kStateBlockWidth);
}

vec4 TapParams(sampler2D sampler, int sampleIdx, int passIdx, int weightIdx) 
{ 
    return texelFetch(sampler, StateIdxToTexelXY((sampleIdx * 2 + passIdx) * kDoFKernelSize + weightIdx), 0); 
}

void EvaluateKernelOptimizer(inout vec4 state, ivec2 xy)
{
    if(xy.x - kDoFParamsX >= kDoFKernelSize * 2) return;
    
    #define kLearningRate 0.1
    #define kBatchSize 64
    
    state *= 0.;       
    
    int stateIdx = TexelXYToStateIdx(xy);
    int sampleIdx = stateIdx / (kDoFKernelSize * 2);
    int passIdx = (stateIdx / kDoFKernelSize) & 1;
    int weightIdx = stateIdx % kDoFKernelSize;
    
    if(sampleIdx >= kBatchSize) { return; }
    
    RNGCtx rng = InitRNG(HashOf(uvec2(stateIdx, iFrame)));

    // Initialize weights from uniform distribution
    if(iFrame == 0)
    {
        state = Rand4(rng); 
    }
    else
    {    
        state = texelFetch(iChannel0, xy, 0); // Load previous state
        
        // Compute gradients
        if(sampleIdx != 0)
        {  
            vec4 vK;
            vec4 wK;
            float f;
            int randIdx = ivec4(URand4(rng) % uvec4(kDoFKernelSize)).x;

            if(passIdx == 0)
            {   
                vK = TapParams(iChannel0, 0, 0, weightIdx);         
                f = EvaluateAperture(vec2(randIdx, weightIdx), float(kDoFKernelRadius));
                wK = TapParams(iChannel0, 0, 1, randIdx);
            }
            else
            {
                vK = TapParams(iChannel0, 0, 1, weightIdx);
                f = EvaluateAperture(vec2(weightIdx, randIdx), float(kDoFKernelRadius));
                wK = TapParams(iChannel0, 0, 0, randIdx);
            }                 
   
            state = 2. * wK * (dot(vK, wK) - f); // L2 loss                
            
        }
        // Optimise and update
        else if(sampleIdx == 0)
        {
            vec4 dLdv = vec4(0);
            for(int i = 1; i < kBatchSize; ++i)
            {
                dLdv += TapParams(iChannel0, i, passIdx, weightIdx);
            }
            dLdv /= float(kBatchSize - 1);
            state -= dLdv * kLearningRate;            
        }
    }  
}

void EvaluateWetmap(inout vec4 rgbaFrag, vec2 xyFrag, float time)
{
 #define kNumFitIterations 5          
            
            // We want to the fluid to run off unevenly as it flows down
            float drip = SmoothNoise(vec2(xyFrag.x * kRunoffDripScale / kReferenceRatio, time * 2.), 1., 0x198ab87eu);
            drip = kSpeed * kReferenceRatio * kRunoffRate * mix(kRunoffDripMin, kRunoffDripMax, sqr(drip));
           
            // Retrieve the previous frame's value, shifted vertically according to the runoff rate
            float f = (1. - kDryRate) * texture(iChannel0, (xyFrag + vec2(0., kSpeed * kReferenceRatio * mix(kRunoffDripMin, kRunoffDripMax, sqr(drip)))) / iRes.xy, 0.).w;
                  
            // Since the head is topologically equivalent to a sphere, fit a spherical distribution onto it by evaluating 
            // the SIREN and displacing the vectors for a few frames on start-up
            vec3 n;
            if(iFrame == 0)
            {               
                float phi = kTwoPi * (xyFrag.x - iResolution.y - 1.0) / (iResolution.x - iResolution.y - 1.0) + kPi;
                float theta = kPi - kPi * 2. * xyFrag.y / (iResolution.x - iResolution.y - 1.0);
                n = vec3(cos(phi) * sin(theta), cos(theta), sin(phi) * sin(theta)) * 0.8;// * ( * 0.55) * vec3(0.75, 1., 1.0);
                rgbaFrag.xyz = n; return;
            }
            else
            {
                n = texelFetch(iChannel0, ivec2(xyFrag), 0).xyz;
                if(iFrame < kNumFitIterations)
                {
                    float g = EvaluateSiren(n);
                    float len = length(n);
                    n *= (len - g) / len;                    
                }
            }
            rgbaFrag.xyz = n;
            
            // Transform the sample point from object space into world space
            n = (n * kHeadScale) * ComposeHeadMatrix(iChannel0, iRes.xy); 
            n.xz += kHeadPos.xz;
            n.y += texelFetch(iChannel0, ivec2(iResolution.y, 4), 0).w + kHeadPos.y + 0.005;
            
            // If the point is below the surface of the heightfield, mark it as "wet"
            if(n.y < texture(iChannel0, (n.xz + 0.5) * vec2(iResYXRatio, 1), 0.).w)
            {
               f += 1.;
            }              
            
            rgbaFrag.w = f;
}

float FBM(vec2 p, float time, int harmonics, vec2 shift)
{       
    vec3 uvw = vec3(p, time);
    
    float f = 0., sum = 0.;
    uint seed = 0x7f8a8101u;
    float w = 1.;
    float scale = kWaterNoiseScale;
    float harmonicExp = mix(5., 1.7, shift.x);
    for(int h = 1; h <= harmonics && w > 1e-6; ++h, scale *= kWaterScaleExp)
    {        
        f += SmoothXYCubicZNoise(uvw + 1., scale, seed) * w;
        sum += w;
        seed = HashCombine(seed, 0x01000193u);
        w /= harmonicExp;
    }
    f = kWaterBias + kWaterAmplitude * f / sum;

    return mix(.05, .95, saturate((f - kHFRange.x) / (kHFRange.y - kHFRange.x)));
}

void EvaulateHeightfield(inout vec4 rgbaFrag, in vec2 xyFrag, float time)
{
        vec2 p = kHeadPos.xz;

    int harmonics;
    if(int(xyFrag.x) == int(iResolution.y))
    {
        int y = int(xyFrag.y);

        // Compute a basis frame from the heightfield to allow the head to pitch and roll with the waves
        if(y < 4)
        {
            float f0 = texelFetch(iChannel0, ivec2(iResolution.y, 4), 0).w;                    
            vec3 fx0 = vec3(-0.05, 0, texelFetch(iChannel0, ivec2(iResolution.y, 5), 0).w);
            vec3 fx1 = vec3(0.05, 0, texelFetch(iChannel0, ivec2(iResolution.y, 6), 0).w);
            vec3 fy0 = vec3(0, -0.05, texelFetch(iChannel0, ivec2(iResolution.y, 7), 0).w);
            vec3 fy1 = vec3(0, 0.05, texelFetch(iChannel0, ivec2(iResolution.y, 8), 0).w);
            vec3 dfdx = 0.5 * (fx1 - fx0) * vec3(1, 1, 0.7);
            vec3 dfdy = 0.5 * (fy1 - fy0) * vec3(1, 1, 0.7);
            mat3 m;
            m[2] = normalize(cross(dfdx, dfdy));
            m[1] = normalize(cross(m[2], dfdx));
            m[0] = cross(m[1], m[2]);            
            switch(y)
            {
                case 0: rgbaFrag.w = f0; break;
                case 1: rgbaFrag.xyz = m[0]; break;
                case 2: rgbaFrag.xyz = m[1]; break;
                case 3: rgbaFrag.xyz = m[2]; break;
            }
            return;
        }
        // Evaulate the heightfield at the 5 points needed to compute the basis frame
        else if(y < 9)
        {
            harmonics = 2;
            p = vec2(0.4);
            if(y >= 5)
            {
                p[(y-5)>>1] += 0.05 * (float((y-5)&1) * 2. - 1.);
            }             
        }
        
    }
    // Evaulate the full field for the renderer
    else if(int(xyFrag.x) < int(iResolution.y))
    {
        harmonics = kWaterHarmonics;
        p = xyFrag / iResolution.y;
    }
        p += kWaterFlowDirection * time;

    // Use noise to create a low-divergence vector field to mimic fake advection and incompressibility
    vec2 dp = vec2(SmoothNoise(p * kWaterAdvectionScale + time * 0.2, 1., 0x01000193u), 
                   SmoothNoise(p  * kWaterAdvectionScale + time * 0.2, 1., 0x51000193u));
    p += kWaterAdvectionSpeed * (dp - 0.5);
    
    time *= kWaterWaveSpeed;
    
    // Evaluate the scalar component of the field
    rgbaFrag.w = FBM(p, time, harmonics, dp);

    #if kNormalMode == 1 || kNormalMode == 2
    
        #define kHFDeltaNorm (1.5 / kReferenceResolution)
        #if kNormalMode == 1
            
            // Compute the surface normal explicitly
            float fx0 = FBM(p.xy + vec2(-1., 0.) * 0.5 * kHFDeltaNorm, time, harmonics, dp);
            float fx1 = FBM(p.xy + vec2(1., 0.) * 0.5 *  kHFDeltaNorm, time, harmonics, dp);
            float fy0 = FBM(p.xy + vec2(0., -1.) * 0.5 * kHFDeltaNorm, time, harmonics, dp);
            float fy1 = FBM(p.xy + vec2(0., 1.) * 0.5 *  kHFDeltaNorm, time, harmonics, dp);
            
        #elif kNormalMode == 2
            
            // Compute the surface normal from the previous frame. Less accurate, but much faster.
            float fx0 = texelFetch(iChannel0, ivec2(xyFrag) + ivec2(-1, 0), 0).w;
            float fx1 = texelFetch(iChannel0, ivec2(xyFrag) + ivec2(1, 0), 0).w;
            float fy0 = texelFetch(iChannel0, ivec2(xyFrag) + ivec2(0, -1), 0).w;
            float fy1 = texelFetch(iChannel0, ivec2(xyFrag) + ivec2(0, 1), 0).w;
            
        #endif    
        
        vec2 n2 = vec2(fx1 - fx0, fy1 - fy0) / kHFDeltaNorm;
        n2 = -n2 / sqrt(n2*n2 + 1.);
        rgbaFrag.xyz = normalize(vec3(n2, sqrt(max(0., 1. - sqr(n2.x) - sqr(n2.y)))));    
        
    #endif
}

float EncodeKeyboardStates()
{
    uint states = ~((1u << 4) - 1u);
    states |= (uint(texelFetch(iChannel1, ivec2(81, 0), 0).x > 0.) << 0);
    states |= (uint(texelFetch(iChannel1, ivec2(87, 0), 0).x > 0.) << 1);
    states |= (uint(texelFetch(iChannel1, ivec2(69, 0), 0).x > 0.) << 2);
    states |= (uint(texelFetch(iChannel1, ivec2(82, 0), 0).x > 0.) << 3);
    return uintBitsToFloat(states);
}

void mainImage( out vec4 rgbaFrag, in vec2 xyFrag )
{
    //rgbaFrag = texelFetch(iChannel0, ivec2(xyFrag), 0); return;
    
    rgbaFrag *= 0.;
    
    float time = GetTime();
    ivec2 xy = ivec2(xyFrag);
    
    /***********************************************************************************************************************/
    
    if(xy.x == int(iRes.y) && xy.y == int(iRes.y) - 1)
    {
        rgbaFrag.x = EncodeKeyboardStates();
        return;
    }
    
    if(xy.x >= kDoFParamsX && xy.y >= kDoFParamsY)
    {
        EvaluateKernelOptimizer(rgbaFrag, xy);
        return;
    }
    
    ivec2 wetMapBound = ivec2(int(iResolution.y) + 1, int((iResolution.x - iResolution.y - 1.) / 2.));
    if(int(xyFrag.x) >= wetMapBound.x)
    {
        if(int(xyFrag.y) < wetMapBound.y)
        {            
            EvaluateWetmap(rgbaFrag, xyFrag, time);
        }
        return;
    }
    
    EvaulateHeightfield(rgbaFrag, xyFrag, time);
    
    /***********************************************************************************************************************/
    
    
    
    //rgbaFrag = mix(rgbaFrag, texelFetch(iChannel0, ivec2(xyFrag), 0), 0.99);
    //rgbaFrag.xyz = normalize(rgbaFrag.xyz);
    
    }