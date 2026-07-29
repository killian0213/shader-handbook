// Common (common) — Straight Flagstone Tiles by gelami
// https://www.shadertoy.com/view/7tKGRc


#define PI (acos(-1.))
#define TAU (2.*PI)

#define sat(x) clamp(x, 0., 1.)

mat2 rot2D(float a)
{
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

// Cubic smin function
// https://iquilezles.org/articles/smin
float smin( float a, float b, float k )
{
    float h = max(k - abs(a - b), 0.0 ) / k;
    return min(a, b) - h*h*h*k * (1.0 / 6.0);
}

float smax( float a, float b, float k )
{
    return -smin(-a, -b, k);
}

// Cosine Color Palette
// https://iquilezles.org/articles/palettes
vec3 palette( float t )
{
    return 0.52 + 0.48*cos( TAU * (vec3(.9, .8, .5) * t + vec3(0.1, .05, .1)) );
}


// Hash without Sine
// https://www.shadertoy.com/view/4djSRW
// MIT License...
/* Copyright (c) 2014 David Hoskins.

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

float hash12(vec2 p)
{
    p = p * 1.1213;
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
