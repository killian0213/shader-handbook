// Buffer A (buffer) — Phoenix Ascending by igneus
// https://www.shadertoy.com/view/WclSWl

// *******************************************************************************************************
//    Lattice gas automaton with FLIP-based pressure solver
// *******************************************************************************************************

#define kLGASearchRadius 8
#define kLGASearchArea ((1 + 2 * kLGASearchRadius) * (1 + 2 * kLGASearchRadius))    
#define kMaxParticleVelocity (5. * kLGAGridCellSize)    
#define kInitialDensity 0.01

vec2 ClampVelocity(vec2 v0)
{
    #define kDamping 5.
    float v0Len = length2(v0);
    if(v0Len > sqr(1e-3))
    {        
        // Normalise the velocity
        v0Len = sqrt(v0Len);
        v0 /= (1e-10 + v0Len);
            
        // Smoothly damp larger velocities to avoid clipping them
        v0Len = log(1. + v0Len * kDamping) / kDamping;
                        
        if(v0Len > kMaxParticleVelocity) { v0Len = kMaxParticleVelocity; }
        v0 *= v0Len;
    }
    return v0;
}

void mainImage( out vec4 state0, in vec2 xyFrag )
{   
    state0 = vec4(0.);
    ivec2 gridDims = GetLGAGridDims(iResolution.xy);
    ivec2 gridIdx = ivec2(xyFrag);
    int gridArea = gridDims.x * gridDims.y;
    
    // x: Packed position relative to cell
    // y: Packed velocity relative to cell
    // z: Mass of cell
    // w: Particle status    
        
    if(gridIdx.x < gridDims.x && gridIdx.y < gridDims.y)
    {
        ivec2 ij0 = ivec2(xyFrag);     
        vec2 cellPos0 = LGAGridIdxToView(ij0, gridDims, iResolution.xy);
                
        vec2 vHawk = SampleHawk(cellPos0, iResolution.xy, kTime, iChannel1).xy;
        
        // Initialisation
        if(iFrame == 0)
        {
            state0 = vec4(0., 0., 0., kParticleDormant); return;
        }
            
        bool wasInitialised = false;
        RNGCtx rng = PCGInitialise(HashOf(uint(ij0.x), uint(ij0.y), uint(iFrame)));
        vec4 xi = Rand4(rng);
        
        // Seed particles from the hawk's body using the velocity vectors to set its initial direction
        if(cwiseMax(abs(vHawk.xy)) > 1e-3)
        {
            int hawkInterval; float hawkPhase;
            vec4 hawkCtx = GetHawkHoverCtx(kTime); 
            float mag = length(vHawk.xy) * kInitialDensity * mix(0.3, 1.3, sin01(hawkCtx.w)) * float(iMouse.z <= 0.);
            if(xi.x < mag)
            {
                PackNormalisedLGAState(vec2(0.5), vHawk, 1., state0);   
                MakeActive(state0); 
                wasInitialised = true;
            }
        }
        
        // If this cell's state wasn't pre-initialised, load it in now
        if(!wasInitialised)
        {
            state0 = texelFetch(iChannel0, ij0, 0);        
        }
       
        #define kDiffusionRadius 2      
        #define kDiffusionSize (1 + 2*kDiffusionRadius) 
        #define kDiffusionArea (kDiffusionSize * kDiffusionSize)
        #define kDiffusionRate kTimeStep
        
        vec2 p0, v0;
        float mass0;   
        
        // If the state isn't stable, it's either dormant or migrated in the previous frame. Either way, 
        // it's dormant now so zero its position, velocity and mass.
        if(!IsActive(state0)) 
        {
            p0 = v0 = vec2(0.); 
            mass0 = 0.;
            state0.w = kParticleDormant;
        }
        else
        {
            // Otherwise, unpack the data
            UnpackLGAState(state0, cellPos0, p0, v0, mass0);
            
            // Particles with masses greater than 1 will lose the excess by diffusing it to other particles.
            float diffusedMass = 1.;
            if(mass0 > 1.)
            {
                diffusedMass += mass0 / float(sqr(1 + 2 * kDiffusionRadius));
            }
            mass0 = mix(mass0, diffusedMass, kDiffusionRate);
        }        
        
        p0 *= mass0;
        v0 *= mass0;
        
        vec2[kLGASearchArea] P;
        vec2[kLGASearchArea] V;
        float[kLGASearchArea] M;
        int numK = 0;          

        for(int v = -kLGASearchRadius, idx = 0; v <= kLGASearchRadius; ++v)
        {
            for(int u = -kLGASearchRadius; u <= kLGASearchRadius; ++u, ++idx)
            {
                if(u != 0 || v != 0)
                {
                    ivec2 ijK = ij0 + ivec2(u, v);
                    if(ijK.x < 0 || ijK.x >= gridDims.x || ijK.y < 0 || ijK.y >= gridDims.y) { continue; }

                    vec4 stateK = texelFetch(iChannel0, ijK, 0);                   

                    // Skip over boundary cells
                    if(IsBoundary(stateK)) { continue; }
                    
                    if(!IsDormant(stateK))
                    {
                        vec2 cellPosK = cellPos0 + vec2(u, v) * kLGAGridCellSize;
                        UnpackLGAState(stateK, cellPosK, P[numK], V[numK], M[numK]);
                        ++numK;
                        
                        // If a particle migrated directly into this cell, assimilate +1 of its mass and knock it off the list of K neighbours
                        if(IsMigrating(stateK) && LGACellContains(P[numK-1], cellPos0))
                        {                           
                            --numK;
                            float advectedMass = mix(M[numK], 1., kDiffusionRate);
                            p0 += P[numK] * advectedMass;
                            v0 += V[numK] * advectedMass;
                            mass0 += advectedMass;
                            MakeActive(state0);
                        }
                        
                        #define kUseMassConservation 1
                        #if kUseMassConservation == 1
                        
                            if(M[numK-1] > 1. && max(abs(u), abs(v)) <= kDiffusionRadius)
                            {
                                uint seed = HashOf(HashOf(ijK), uint(iFrame));
                                float diffusedMass = kDiffusionRate * (M[numK-1] - 1.) / (/*M[numK-1].y * */float(kDiffusionArea));
                                int offset = kDiffusionSize * (kDiffusionRadius + ijK.y - ij0.y) + (kDiffusionRadius + ijK.x - ij0.x);
                                
                                // If this cell isn't active and its mass is less than 1, stochastically activate it. 
                                // NOTE: No particle should ever have a mass < 1
                                if(!IsActive(state0) && diffusedMass < 1.)
                                {
                                    diffusedMass = float(HaltonBase2(seed + uint(offset)) < diffusedMass);
                                }
                                if(diffusedMass > 0.)
                                {
                                    //rng = PCGInitialise(seed);
                                    //vec2 xi = Rand4(rng).xy;
                                    vec2 xi = vec2(0.5); // Seed the particle in the centre of the cell
                                    p0 += (cellPos0 + xi * kLGAGridCellSize) * diffusedMass;
                                    v0 += V[numK-1] * diffusedMass;
                                    mass0 += diffusedMass;
                                    MakeActive(state0);
                                }                             
                            }
                        
                        #endif
                    }
                }
            }
        }                  
        
        // If this cell is inactive, there's nothing left to do.
        if(!IsActive(state0))
        {        
            MakeDormant(state0);            
            return;
        }   
        
        // Normalise position and velocity based on accumulated mass
        p0 /= max(1., mass0);
        v0 /= max(1., mass0);
        
        #define kUseFLIP 1 
        #define kFLIPSize 3
        #define kFLIPArea (kFLIPSize * kFLIPSize)
        #define kFLIPPadding 1.1
        #define kFLIPMinK 1
        #define kFLIPMaxK 2        
        #define kFLIPIterations 3
        #define kFLIPRelaxation 0.2
        #define kFLIPPICRatio 0.53
    
        #if kUseFLIP == 1
        if(numK > kFLIPMinK)
        {
            // Add state0 onto the end of the list so we can run it through FLIP with the others
            P[numK] = p0;
            V[numK] = v0;
            ++numK;               
            
            
            vec2[kFLIPArea*2] G;
            float[kFLIPArea] W;
            vec2[kFLIPArea] G0;

            // Zero the FLIP grid
            for(int i = 0; i < kFLIPArea; ++i) { G[i] = vec2(0.); W[i] = 0.; }

            // Project each particle onto the grid
            vec2 gridLower = p0 - float(kLGASearchRadius) * kLGAGridCellSize * kFLIPPadding;
            float gridDelta = float(2 * kLGASearchRadius + 1) * kLGAGridCellSize * kFLIPPadding;
            for(int i = 0; i < numK; ++i)
            {                
                vec2 pG = float(kFLIPSize - 1) * clamp((P[i] - gridLower) / float(gridDelta), vec2(0.), vec2(0.9999));            
                ivec2 pGi = ivec2(pG);
                vec2 pGd = fract(pG);              

                int j; float w;                
                #define Project(dx, dy, weight) j = (pGi.y + dy) * kFLIPSize + (pGi.x + dx);  w = weight;  W[j] += w; G[j] += V[i] * w;
                    
                Project(0, 0, (1. - pGd.x) * (1. - pGd.y))
                Project(1, 0, pGd.x * (1. - pGd.y))
                Project(0, 1, (1. - pGd.x) * pGd.y)
                Project(1, 1, pGd.x * pGd.y)
                
                #undef Project
            }

            // Normalize eacah element in the grid by the accumulated weights
            for(int i = 0; i < kFLIPArea; ++i) 
            { 
                G[i] /= 1e-10 + W[i];
                G0[i] = G[i];
            }        
            
            // Solve Poisson's equation
            int srcBuf = 0, destBuf = 1;
            for(int iterIdx = 0; iterIdx < kFLIPIterations; ++iterIdx)
            {
                int srcOffset = srcBuf * kFLIPArea, destOffset = destBuf * kFLIPArea;
                for(int v = 0, cellIdx = 0; v < kFLIPSize; ++v)
                {
                    for(int u = 0; u < kFLIPSize; ++u, ++cellIdx)
                    {
                        if(W[cellIdx] > 0.)
                        {
                            int srcIdx = srcOffset + cellIdx;
                            vec2 m = G[srcIdx].xy;
                            float div = 0.;
                            for(int d = 0; d < 2; ++d)
                            {
                                for(int sgn = -1; sgn <= 1; sgn+=2)
                                {
                                    ivec2 uvK = ivec2(u, v);
                                    uvK[d] = clamp(uvK[d] + sgn, 0, kFLIPSize - 1);
                                    int k = uvK.y * kFLIPSize + uvK.x;                                    
                                    vec2 x = (W[k] == 0.) ? G[srcIdx] : G[srcOffset + k];
                                    
                                    m += x; // Accumulate the mean direction
                                    div += x[d] * float(sgn); // Accumulate the divergence
                                }
                            }
                            
                            // Relax the velocity based on the computed divergence
                            G[destOffset + cellIdx] = G[srcIdx] + kFLIPRelaxation * SafeNormalize(m) * div;                            
                        }
                    }
                }
                // Flip the buffer indices
                srcBuf = (srcBuf + 1) & 1; destBuf = (destBuf + 1) & 1;
            }            
      
            // Inverse project
            /*vec2 pG = float(kFLIPSize - 1) * clamp((p0 - gridLower) / float(gridDelta), vec2(0.), vec2(0.9999));            
            ivec2 pGi = ivec2(pG);
            vec2 pGd = fract(pG);
            vec2 vj = G[pGi.y * kFLIPSize + pGi.x].xy * ((1. - pGd.x) * (1. - pGd.y)) +
                      G[pGi.y * kFLIPSize + (pGi.x+1)].xy * (pGd.x * (1. - pGd.y)) +
                      G[(pGi.y+1) * kFLIPSize + pGi.x].xy * ((1. - pGd.x) * pGd.y) +
                      G[(pGi.y+1) * kFLIPSize + (pGi.x+1)].xy * (pGd.x * pGd.y);

            vec2 vj0 = G0[pGi.y * kFLIPSize + pGi.x].xy * ((1. - pGd.x) * (1. - pGd.y)) +
                      G0[pGi.y * kFLIPSize + (pGi.x+1)].xy * (pGd.x * (1. - pGd.y)) +
                      G0[(pGi.y+1) * kFLIPSize + pGi.x].xy * ((1. - pGd.x) * pGd.y) +
                      G0[(pGi.y+1) * kFLIPSize + (pGi.x+1)].xy * (pGd.x * pGd.y);*/
                      
            // For FLIP grids with odd numbers of cells, the out-projected velocity is simply the median cell
            vec2 vj = G[srcBuf * kFLIPArea + kFLIPArea / 2].xy;
            vec2 vj0 = G0[kFLIPArea / 2].xy;

            vec2 vPIC = mix(v0, vj, 1.);
            vec2 vFLIP = (v0 + vj - vj0);// * momentum0 / max(1e-10, momentumN);
            
            float simWeight = saturate(float(numK - kFLIPMinK) / float(kFLIPMaxK - kFLIPMinK));
            v0 = mix(v0, mix(vPIC, vFLIP, kFLIPPICRatio), kTimeStep * simWeight);
        }
        #endif
        
        #define kUseRepulsion 1    
        
        if(kUseRepulsion != 0)
        {
            #define kElasticRepulsion 1.            
            #if kUseFLIP == 1
                // Repulsion (last particle is state0 which can't repel itself)
                #define kReplusionK (numK - 1)
            #else
                #define kReplusionK numK
            #endif            
            
            // Elastically repel this particle from its neighbours
            for(int k = 0; k < kReplusionK; ++k)
            {           
                // The margin inside which repulsion is maximised (relative to the radius of the particle)
                #define kRepulsionBias 1.
                // The influence of the repulsion force
                #define kRepulsionGain 1.
                // The falloff of the Gaussian (2 = standard Gaussian)
                #define kRepulsionFalloff 2.                
                float d = max(0., length(p0 - P[k]) / kLGAParticleRadius - kRepulsionBias);
                float f = kElasticRepulsion * kLGAParticleRadius * max(0., exp(-pow(abs(d / (kRepulsionGain * sqrt(M[k] * mass0))), kRepulsionFalloff)));

                v0 += SafeNormalize(p0 - P[k]) * f;
            }
        }       
        
        // Apply advection from the hawk
        v0 += vHawk * kHawkAdvection;

        // Apply gravity
        #define kGravity -0.0005
        #define kGravityShift 0.
        float gTheta = kHalfPi + kHalfPi * kGravityShift * mix(-1., 1., sin01(kTime * 0.5));
        v0 += kGravity * vec2(cos(gTheta), sin(gTheta)) * kTimeStep;
                
        // Clamp the velocity to the limits of the sim
        v0 = ClampVelocity(v0);      
        
        // Clip to bounds
        //p0 += v0;
        vec2 kMargin = 0.99 * vec2(iResolution.x / iResolution.y, 1.);
        for(int d = 0; d < 2; ++d)
        {
            if(abs(p0[d] + v0[d]) > kMargin[d]) 
            { 
                p0[d] = sign(p0[d]) * kMargin[d] * 1.;
                v0[d] *= -0.;
            }
            else 
            {
                // Advect
                p0[d] += v0[d] * kTimeStep;
            }
           
        }
        
        PackLGAState(p0, v0, mass0, cellPos0, state0);    
        
        if(!LGACellContains(p0, cellPos0))
        {
            MakeMigrating(state0);            
        }     
    }    
}