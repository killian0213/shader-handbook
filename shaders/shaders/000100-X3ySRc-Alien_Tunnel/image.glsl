// Image (image) — Alien Tunnel by lz
// https://www.shadertoy.com/view/X3ySRc

/*
 * Creator: Leonid Zaides
 *
 * Alien Tunnel
 *
 * Copyright © 2024 Leonid Zaides
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *   
 *  --------------------------------------------------------
 *
 */

#define TFC(CRD) texelFetch(iChannel0, ivec2(CRD),0)
#define TEX(UV)  texture(iChannel0, UV)
#define MAX_KRN_SIZE 5.

vec3 dofSimple(in float _dist, in vec4 _col, in ivec2 frag, in vec2 _uv)
{
  float krnSize = floor(smoothstep(0., 0.75, _dist) * MAX_KRN_SIZE);
  vec3 scol;
  float sw = 0.;
  float w = 0.;
  float shift_w = 0.;//5.*PULSE_T(mod(iTime, 50.), 0.5, 4., 23.)*smoothstep(0., 1., pow(_col.w, 2.));
  for (int i = -int(krnSize); i <= int(krnSize); i++)
  {
      for (int j = -int(krnSize); j <= int(krnSize); j++)
      {
         vec2 shift = vec2(hash(123.9*_col.x + 11.3*float(i)), hash(17.*_col.y + 23.1*float(j))) - vec2(0.5);
         vec4 ncol = TEX(_uv + (shift_w*shift.xy + vec2(ivec2(i, j)))/iResolution.y);
         //vec4 ncol = TFC(frag + ivec2(i, j));
         float dist_diff = 50.*(_col.w - ncol.w);
         w = exp(-(dist_diff * dist_diff)) * step(float(i*i + j*j), krnSize * krnSize);
         sw += w;
         scol += w * ncol.rgb;
      }
  }
  
  scol /= sw;
  
  vec3 res = mix(_col.rgb, scol.rgb, krnSize/MAX_KRN_SIZE);
  //res = vec3(krnSize/MAX_KRN_SIZE);
  //res = _col;
  return scol;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    vec4 col = texture(iChannel0, uv);

    // post processing
    col.rgb = dofSimple(col.w*col.w, col, ivec2(fragCoord), uv);
    col.rgb = mix(2.*mix(col.rgb, vec3(0.05, 0.15, 0.3) * (col.w*col.w), col.w * col.w), vec3(0.01, 0.1, 0.24), sqrt(col.w));
    col *= 2.;
    col /= (1. + col);
    col.rgb = pow(col.rgb, vec3(1.6));
    
    fragColor = vec4(col);
}