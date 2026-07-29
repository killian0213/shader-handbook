// Buffer B (buffer) — Space At Home by lz
// https://www.shadertoy.com/view/MXS3zy

/*
    Space at home. 
    Copyright © 2024 Leonid Zaides
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.   

    Buffer B - Main ray cast
             - output: trace t and normal.
*/

vec3 norm_forward(in vec3 _p, in int _trace_flags, in float _eps, in float _f, in bool _use_f) {
    vec2 e = vec2(_eps, 0.);
    vec3 n;
    #define ZERO (min(iFrame,0)) // non-constant zero
    for (int i = ZERO; i < 3 && iFrame > 0; i++) {
        n[i] = map(_p + vec3(i == 0, i == 1, i == 2)*_eps, _trace_flags, 
            iChannel3, true, false).x - _f;
    }
    
    return n;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (2.*fragCoord - iResolution.xy)/(iResolution.y);
    vec2 muv = (2.*iMouse.xy - iResolution.xy)/(iResolution.y);
    float scr_resolution = iResolution.x / iResolution.y;
    float half_pixel = 1./iResolution.y;
    vec3 col;
    vec2 raycast = vec2(0., FAR);
    vec3 norm;
    float fmtl;
    vec2 lshadows;
    float n_eps = N_EPS;
    
    // camera setup - defining o, d, trg (look at)
    CAMERA_SETUP(uv)

    float iter = MAX_ITER;
    float far = FAR;

    int trace_flags = (sign(d.y) < 0.) ? TRACE_ALL : TRACE_NO_FLOOR;
    raycast = trace(o, d, trace_flags, iChannel3, iter, far, T_EPS);

    if (bool(isHit(raycast, T_EPS))) {
        int i_mtl = int(map(o + raycast.x * d, trace_flags, 
            iChannel3, false, true).y);
        n_eps = mix(N_EPS*10., T_EPS, float(i_mtl == LAPTOP_SCREEN_MTL));
        norm = norm_forward(o + raycast.x * d, getNormMap(i_mtl), n_eps,raycast.y, !is_metal_mtl(i_mtl));
    }

    fragColor = vec4(raycast.x * float(isHit(raycast, T_EPS)),norm);
}