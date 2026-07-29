// Image (image) — Hash without Sine by Dave_Hoskins
// https://www.shadertoy.com/view/4djSRW

// Hash without Sine
// MIT License...
/* Copyright (c)2014 David Hoskins.
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.*/



// All hashes are in the 'COMMON' tab

/*     *NOTE*
This was made because I noticed a the sin() hash function was inconsistent between
different GPUs on a landscape I was making - I spent ages tweaking a mountain range,
only to find it was different on a Mac and different again on a mobile.
Nightmare! Something was needed to fix this.
I realised shaders are designed for shading, not putting a rocket on the moon,
so I'm not surprised something like sin(50000.0) be a little inconsistent between manufacturers,
they all want to be the fastest so different approaches were used it seems.
If you're using P5, GLSLsandbox or any WebGL1 locked library, then this is for you.
Otherwise just use an ancient integer hash! 😁
*/

// New one on the left, sine function on the right.
// *NB: This is for integer scaled floats only! i.e. Standard noise functions.

#define ITERATIONS 1
//#define COLOUR


//----------------------------------------------------------------------------------------
float hashOld12(vec2 p)
{
    // Two typical hashes...
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
    
    // This one is better, but it still stretches out quite quickly...
    // But it's really quite bad on my Mac(!)
    //return fract(sin(dot(p, vec2(1.0,113.0)))*43758.5453123);

}

vec3 hashOld33( vec3 p )
{
	p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
			  dot(p,vec3(269.5,183.3,246.1)),
			  dot(p,vec3(113.5,271.9,124.6)));

	return fract(sin(p)*43758.5453123);
}

//----------------------------------------------------------------------------------------
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 position = fragCoord.xy;
    vec2 uv = fragCoord.xy / iResolution.xy;
#ifndef COLOUR
	float a = 0.0, b = a;
    for (int t = 0; t < ITERATIONS; t++)
    {
        float v = float(t+1)*.152;
        vec2 pos = (position * v + iTime * 1500. + 50.0);
        a += hash12(pos.xy);
    	b += hashOld12(pos);
    }
    vec3 col = vec3(mix(b, a, step(uv.x, .5))) / float(ITERATIONS);
#else
	vec3 a = vec3(0.0), b = a;
    for (int t = 0; t < ITERATIONS; t++)
    {
        float v = float(t+1)*.132;
        vec3 pos = vec3(position, iTime*.3) + iTime * 500. + 50.0;
        a += hash33(pos);
        b += hashOld33(pos);
    }
    vec3 col = vec3(mix(b, a, step(uv.x, .5))) / float(ITERATIONS);
#endif

    col = mix(vec3(.4, 0.0, 0.0), col, smoothstep(.5, .495, uv.x) + smoothstep(.5, .505, uv.x));
	fragColor = vec4(col, 1.0);
}