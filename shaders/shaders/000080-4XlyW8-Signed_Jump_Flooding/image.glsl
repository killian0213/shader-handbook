// Image (image) — Signed Jump Flooding by iq
// https://www.shadertoy.com/view/4XlyW8

// The MIT License
// Copyright © 2024 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// SIGNED Jump Flooding creates a discretized SDFs for shapes for which
// we only know the interior and exterior pixels.
//
// Similar to https://www.shadertoy.com/view/lXscDH it doesn't need to
// keep track of distances so in the end all fits into a 32 bit integer
// buffer. Because Shadertoy doesn't support that yet, we use encode/decode
// the bits into the red channel of the RGBA32F buffer. This doesn't work
// if the 32 bit pattern happens to be a IEEE754 denormal pattern, as
// user "timestamp" noted.
//
// With the current buffer size and packing strategy, he largest image
// it can compute the SDF for is 32,768 x 65,534.
//
// See also https://www.shadertoy.com/view/ct2cDV and https://www.shadertoy.com/view/McByRd


// .x  = distance
// .yz = closet point
vec3 map( in vec2 p )
{
    uint b = floatBitsToUint(texelFetch(iChannel0, ivec2(p), 0).x);
    uint x = b & 0x7fffu;
    uint y = b >> 16;
    uint s = b & 0x8000u;
    
    float d = length(p-vec2(x,y));
    return vec3( (s==0u)?d:-d, x, y );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = fragCoord;
    vec2 m = iMouse.z>0.001 ? iMouse.xy : iResolution.xy*(0.5+0.4*sin(iTime*vec2(0.3,0.5)+vec2(0.0,2.0)));
    
    // distance
    vec3 dce = map(p);

    // colorize
    vec3 col = (dce.x>0.0) ? vec3(0.9,0.6,0.3) : vec3(0.65,0.85,1.0);
    
    if( iFrame>0 )
    {
    vec2  g = (p-dce.yz)/dce.x; // gradient
    float d = 2.0*dce.x/iResolution.y;
    col *= 1.0 + vec3(0.5*g,0.0)*smoothstep(0.1,-0.1,sin(6.283185*iTime/8.0));
    col *= 1.0 - exp2(-24.0*abs(d));
    col *= 0.8 + 0.2*smoothstep(-0.5,0.5,cos(128.0*d));
    col = mix( col, vec3(1.0), 1.0-smoothstep(1.0,3.0,abs(dce.x)) );

    // mouse probe
    dce = map(m);
    float ra = iResolution.y*0.01;
    float dp = min(min(abs(length(p-m)-abs(dce.x)),
                       length(p-m)-ra),
                       length(p-dce.yz)-ra);
    col = mix(col, vec3(1.0,1.0,0.0), 1.0-smoothstep(1.5, 2.5, dp));
    }
    
    fragColor = vec4(col,1.0);
}