// Buffer D (buffer) — Phoenix Ascending by igneus
// https://www.shadertoy.com/view/WclSWl

// *******************************************************************************************************
//    Bloom pass
// *******************************************************************************************************

void mainImage( out vec4 rgba, in vec2 xyFrag )
{      
    vec2 xyView = ScreenToNormalisedScreen(xyFrag * float(kBloomDownsample), iResolution.xy);    
    vec4 hawkTex = SampleHawk(xyView, iResolution.xy, kTime, iChannel1);    
    
    float radius = mix(0.02, 0.3, hawkTex.w);
    
    vec3 L0 = SeparableBlurDown(ivec2(xyFrag), ivec2(iResolution), vec2(0.2), vec3(1., 1., 1.), iChannel0); 
    vec3 L1 = SeparableBlurDown(ivec2(xyFrag), ivec2(iResolution), vec2(radius), vec3(2.0, 2.8, 2.4), iChannel0) * 0.5; 

    rgba.x = uintBitsToFloat(_packHalf2x16(L0.xy));
    rgba.y = L0.z;
    rgba.z = uintBitsToFloat(_packHalf2x16(L1.xy));
    rgba.w = L1.z;
}