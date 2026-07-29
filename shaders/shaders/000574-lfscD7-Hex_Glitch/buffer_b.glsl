// Buffer B (buffer) — Hex Glitch by igneus
// https://www.shadertoy.com/view/lfscD7

void mainImage( out vec4 rgba, in vec2 xyScreen )
{
    rgba *= 0.;
    
    // Apply first pass of separable bloom filter
    if(kApplyBloom)
    {    
        rgba = vec4(SeparableBlurDown(ivec2(xyScreen), ivec2(iResolution.xy), iChannel0), 1.);
    }
}