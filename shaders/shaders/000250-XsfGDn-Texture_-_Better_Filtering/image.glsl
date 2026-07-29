// Image (image) — Texture - Better Filtering by iq
// https://www.shadertoy.com/view/XsfGDn

// The MIT License
// Copyright © 2013 Inigo Quilez
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org/
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// This is the implementation for my article "improved texture interpolation"
// 
// https://iquilezles.org/articles/texture
//
// It shows how to get some smooth texture interpolation without resorting to the regular
// bicubic filtering, which is pretty expensive because it needs 9 texels instead of the 
// 4 the hardware uses for bilinear interpolation.
//
// With this techinque here, you can get smooth interpolation while still using only
// 1 bilinear fetch, by tricking the hardware. The idea is to get the fractional part
// of the texel coordinates and apply a smooth curve to it such that the derivatives are
// zero at the extremes. The regular cubic or quintic smoothstep functions are just
// perfect for this task.

vec4 textureNice( sampler2D sam, vec2 uv )
{
    float textureResolution = float(textureSize(sam,0).x);
    uv = uv*textureResolution + 0.5;
    vec2 iuv = floor( uv );
    vec2 fuv = fract( uv );
    uv = iuv + fuv*fuv*(3.0-2.0*fuv);
    uv = (uv - 0.5)/textureResolution;
    return texture( sam, uv );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = fragCoord/iResolution.x;
    vec2 uv = p*0.1;	
	
    //---------------------------------------------	
	// regular texture map filtering
    //---------------------------------------------	
	vec3 colA = texture( iChannel0, uv ).xyz;

    //---------------------------------------------	
	// my own texture map filtering (magnif. only)
    //---------------------------------------------	
	vec3 colB = textureNice( iChannel0, uv ).xyz;
	
    //---------------------------------------------	
    // final color
    //---------------------------------------------	
	float f = sin(3.1415927*p.x + 0.7*iTime);
	vec3 col = (f>=0.0) ? colA : colB;
	col *= smoothstep( 0.0, 0.01, abs(f-0.0) );
	
    fragColor = vec4( col, 1.0 );
}