// Image (image) — Face Generator  by Pidhorskyi
// https://www.shadertoy.com/view/WtXfDs

// The MIT License
// Copyright © 2020 Stanislav Pidhorskyi
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// FFHQ generator. Trained on FFHQ downsampled to 32x32

// Generator network:
// input: z - sampled from normal distibution, 32
// dense layer, in: 32, out: 64
// reshape to 4, 4, 4
// upscale 2x
// conv2d, kernel 3x3, in channels 4, out channels 4
// relu
// upscale 2x
// conv2d, kernel 3x3, in channels 4, out channels 4
// relu
// upscale 2x
// conv2d, kernel 3x3, in channels 4, out channels 4
// relu
// conv2d, kernel 1x1, in channels 4, out channels 3

    
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{    
    fragCoord.y = iResolution.y - fragCoord.y;

    if (_skip(fragCoord, iResolution, 5))
    {
        fragColor = vec4(0.3);
    	return;
    }
 
    vec4 x = conv2d(ivec2(fragCoord), iChannel0, w3, 2);

    //relu
    x = max(x, 0.2 * x);
    
    //to rgb, 1x1 convolution
    for (int c = 0; c < 3; ++c)
    {	
        fragColor[c] = dot(x, to_rgb[c]);
    }
    fragColor.rgb += to_rgb_bias;
    fragColor.rgb = fragColor.rgb * 0.5 + vec3(0.5);
    fragColor.a = 1.0;
}
