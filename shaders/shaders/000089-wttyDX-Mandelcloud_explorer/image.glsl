// Image (image) — Mandelcloud explorer by michael0884
// https://www.shadertoy.com/view/wttyDX

//Volumetric fractal explorer 

//MIT License
//Copyright 2020 Mykhailo Moroz

//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

//assume as "Do whatever you want" License

//Features:
//Multiple light sources(importance sampled)
//Anisotripic scatteringw
//Multibounce scattering
//Camera controls
//Light position control
//Approximate volumetric reprojection for temporal denoising

//Instructions
//WASD/Arrows and mouse to move camera. Q/E regulate camera speed. 
//Press P/L to set light 1/2 position around camera.
//Change parameters in Common tab
//TAA regulates denoising
//Set AMBIENT_FOG to 0.0 to disable fog(improves performace)
//comment LOW_QUALITY for longer light paths
void mainImage( out vec4 c, in vec2 p )
{
    vec4 data = texture(iChannel0, p/iResolution.xy);
    c = 1.07*tanh(pow(data/data.w, vec4(0.6)));
}