// Image (image) — Fast Separable Blur by iq
// https://www.shadertoy.com/view/Xd33Rf

// The MIT License
// Copyright © 2015 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


//
// Vertical blur pass + composit
//

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord;

    // vertical blur (since fragCoord samples at pixel centers it has a 0.5 added to it)
    // hence, i added an extra 0.5 to the texel coordinates to sample not at texel centers
    // but right between texels. the bilinear filtering hardware will average two texels
    // in each sample for me).

    vec3 blr  = vec3(0.0);
    //blr += 0.013658*texture( iChannel0, (uv+vec2(0.0,-19.5))/iResolution.xy ).xyz;
    //blr += 0.019227*texture( iChannel0, (uv+vec2(0.0,-17.5))/iResolution.xy ).xyz;
    blr += 0.026109*texture( iChannel0, (uv+vec2(0.0,-15.5))/iResolution.xy ).xyz;
    blr += 0.034202*texture( iChannel0, (uv+vec2(0.0,-13.5))/iResolution.xy ).xyz;
    blr += 0.043219*texture( iChannel0, (uv+vec2(0.0,-11.5))/iResolution.xy ).xyz;
    blr += 0.052683*texture( iChannel0, (uv+vec2(0.0, -9.5))/iResolution.xy ).xyz;
    blr += 0.061948*texture( iChannel0, (uv+vec2(0.0, -7.5))/iResolution.xy ).xyz;
    blr += 0.070266*texture( iChannel0, (uv+vec2(0.0, -5.5))/iResolution.xy ).xyz;
    blr += 0.076883*texture( iChannel0, (uv+vec2(0.0, -3.5))/iResolution.xy ).xyz;
    blr += 0.081149*texture( iChannel0, (uv+vec2(0.0, -1.5))/iResolution.xy ).xyz;
    blr += 0.041312*texture( iChannel0, (uv+vec2(0.0,  0.0))/iResolution.xy ).xyz;
    blr += 0.081149*texture( iChannel0, (uv+vec2(0.0,  1.5))/iResolution.xy ).xyz;
    blr += 0.076883*texture( iChannel0, (uv+vec2(0.0,  3.5))/iResolution.xy ).xyz;
    blr += 0.070266*texture( iChannel0, (uv+vec2(0.0,  5.5))/iResolution.xy ).xyz;
    blr += 0.061948*texture( iChannel0, (uv+vec2(0.0,  7.5))/iResolution.xy ).xyz;
    blr += 0.052683*texture( iChannel0, (uv+vec2(0.0,  9.5))/iResolution.xy ).xyz;
    blr += 0.043219*texture( iChannel0, (uv+vec2(0.0, 11.5))/iResolution.xy ).xyz;
    blr += 0.034202*texture( iChannel0, (uv+vec2(0.0, 13.5))/iResolution.xy ).xyz;
    blr += 0.026109*texture( iChannel0, (uv+vec2(0.0, 15.5))/iResolution.xy ).xyz;
    //blr += 0.019227*texture( iChannel0, (uv+vec2(0.0, 17.5))/iResolution.xy ).xyz;
    //blr += 0.013658*texture( iChannel0, (uv+vec2(0.0, 19.5))/iResolution.xy ).xyz;
    
    blr /= 0.93423; // renormalize to compensate for the 4 taps I skipped

    
    blr = mix( blr, 
               texture( iChannel1, (uv+vec2(0.0,  0.0))/iResolution.xy ).xyz,
               smoothstep(0.3,0.5,sin(iTime)) );
                    


    fragColor = vec4( blr, 1.0 );
}