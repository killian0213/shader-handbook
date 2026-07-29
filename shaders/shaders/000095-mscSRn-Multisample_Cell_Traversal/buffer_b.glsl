// Buffer B (buffer) — Multisample Cell Traversal by Shane
// https://www.shadertoy.com/view/mscSRn

// I didn't feel like writing my own denoising routine, so did a quick search
// and came up with BrutPitt's exaple, here: https://www.shadertoy.com/view/3dd3Wr
//
// I chose it because it works reasonably well and is simple. I made some minor, 
// but necessary changes. There really is no substitute for increased sample count, 
// but denoisers have their place. At some stage, I'll get in amongst it and write 
// my own... or I'll cross my fingers and hope that someone else writes a really 
// good one.

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//  Copyright (c) 2018-2019 Michele Morrone
//  All rights reserved.
//
//  https://michelemorrone.eu - https://BrutPitt.com
//
//  me@michelemorrone.eu - brutpitt@gmail.com
//  twitter: @BrutPitt - github: BrutPitt
//  
//  https://github.com/BrutPitt/glslSmartDeNoise/
//
//  This software is distributed under the terms of the BSD 2-Clause license
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#define INV_SQRT_OF_2PI .3989422804  // 1/SQRT_OF_2PI
#define INV_PI .31830988618379 // 1/PI

//  smartDeNoise - parameters
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//  sampler2D tex     - sampler image / texture
//  vec2 uv           - actual fragment coord
//  float sigma  >  0 - sigma Standard Deviation
//  float kSigma >= 0 - sigma coefficient 
//  kSigma * sigma  -->  radius of the circular kernel
//  float threshold   - edge sharpening threshold 

vec4 smartDeNoise(sampler2D tex, vec2 uv, float sigma, float kSigma, float threshold){
 
    float radius = round(kSigma*sigma);
    float radQ = radius*radius;
    
    float invSigmaQx2 = .5/(sigma*sigma);     // 1/(sigma^2*2)
    float invSigmaQx2PI = INV_PI*invSigmaQx2; // 1/(2*PI*sigma^2)
    
    float invThresholdSqx2 = .5/(threshold*threshold);     // 1./(sigma^2*2x)
    float invThresholdSqrt2PI = INV_SQRT_OF_2PI/threshold;   // 1/(sqrt(2*PI)*sigma)
    
    vec4 centrPx = texture(tex, uv);
    
    float zBuff = 0.;
    vec3 aBuff = vec3(0);
    //vec2 size = vec2(textureSize(tex, 0));
    
    for(float x = -radius; x <= radius; x++) {
        float pt = sqrt(radQ - x*x);  // pt = yRadius: have circular trend
        for(float y = -pt; y <= pt; y++) {
            
            vec2 d = vec2(x,y);

            float blurFactor = exp(-dot(d, d)*invSigmaQx2)*invSigmaQx2PI; 
            
            vec3 walkPx = texture(tex, uv + d/iResolution.xy).xyz;

            vec3 dC = walkPx - centrPx.xyz;
            float deltaFactor = exp(-dot(dC, dC)*invThresholdSqx2)*invThresholdSqrt2PI*blurFactor;
                                 
            zBuff += deltaFactor;
            aBuff += deltaFactor*walkPx;
        }
    }
    
    return vec4(aBuff/zBuff, centrPx.w);
}
 

void mainImage(out vec4 fragColor, in vec2 fragCoord){


    // Coordinates.
    vec2 uv = fragCoord/iResolution.xy;
     
    // Retrieving the stored color.
    vec4 col = smartDeNoise(iChannel0, uv, 4., 1., .08);
  
    // Rough gamma correction and screen presentation.
    fragColor = col;
    
}