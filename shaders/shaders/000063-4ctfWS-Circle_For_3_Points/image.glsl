// Image (image) — Circle For 3 Points by iq
// https://www.shadertoy.com/view/4ctfWS

// The MIT License
// Copyright © 2024 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Computes the circle that passes through 3 points
//   .xy = center
//   .z  = radius
//   .w  = orientation (sign only)
vec4 getCircle( vec2 a, vec2 b, vec2 c )
{
  vec2  ba = b-a;
  vec2  cb = c-b;
  vec2  ac = a-c;
  float de = ba.x*cb.y-ba.y*cb.x; // zero if points are colinear
  vec2  ce = 0.5*(a+b+vec2(ba.y,-ba.x)*dot(ac,cb)/de);
  return vec4( ce, length(a-ce), de );
}

//-------------------------------------------------------------

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // normalized pixel coordinates
    vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
    float px = 2.0/iResolution.y;

    // animate three points (15 second loop)
    vec2 p0 = vec2(0.3,0.0)+vec2(0.8,0.5)*sin( iTime*vec2(1.0,2.0)*6.283185/15.0 + vec2(5.0,1.0) );
    vec2 p1 = vec2(0.3,0.0)+vec2(0.8,0.5)*sin( iTime*vec2(1.0,1.0)*6.283185/15.0 + vec2(2.0,0.0) );
    vec2 p2 = vec2(0.3,0.0)+vec2(0.8,0.5)*sin( iTime*vec2(2.0,1.0)*6.283185/15.0 + vec2(3.0,4.0) );

    // compute circle from the three points
    vec4 cir = getCircle( p0, p1, p2 );

    // draw background
    vec3 col = vec3(1.0 - 0.1*length(p));

    // draw circle
    {
    float d = length(p-cir.xy)-cir.z;
    col *= 1.0 - 0.5/(1.0+64.0*max(0.0,d));
    col = mix(col, vec3(1.0,cir.w>0.0?0.5:0.0,cir.w>0.0?0.0:0.5), smoothstep(1.5*px,0.0,d));
    }
    
    // draw the three points
    {
    float d = min(min(length(p-p0),length(p-p1)),length(p-p2))-0.03;
    col *= 1.0 - 0.5/(1.0+128.0*max(d,0.0));
    col = mix(col, vec3(1.0), 1.0-smoothstep(0.0, 1.5*px, d));
    }

    // add a bit of texture
    col += 0.02*sin(150.0*p.x)*sin(150.0*p.y);
    
    fragColor = vec4(col, 1.0);
}