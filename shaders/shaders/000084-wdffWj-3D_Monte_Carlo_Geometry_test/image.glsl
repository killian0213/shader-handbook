// Image (image) — 3D Monte Carlo Geometry test by rreusser
// https://www.shadertoy.com/view/wdffWj

// 3D Monte Carlo Geometry Test
//
// This example is motivated by Inigo Quilez' implementation of the Monte Carlo Geometry Processing
// paper of Rohan Sawhney and Keenan Crane. I believe the interior SDF field using the smooth
// mininum is slightly incorrect. If the distance returned is too large, it may yield an invalid
// solution but if the distance is too small, I believe it's only suboptimal. This is my first foray
// into SDF rendering, so I'm not entirely sure which is the case.
//
// http://www.cs.cmu.edu/~kmcrane/Projects/MonteCarloGeometryProcessing/paper.pdf

// This Shadertoy is heavily based on the template code here: https://www.shadertoy.com/view/Xds3zN
// The MIT License
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//------------------------------------------------------------------


void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec4 data = texelFetch(iChannel0, ivec2(fragCoord), 0);
    fragColor = vec4(pow(data.xyz / data.w, vec3(0.4545)), 1.0 );
}