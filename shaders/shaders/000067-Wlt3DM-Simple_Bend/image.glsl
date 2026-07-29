// Image (image) — Simple Bend by iq
// https://www.shadertoy.com/view/Wlt3DM

// The MIT License
// Copyright © 2020 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// A way to bend 2D space
vec2 bend( in vec2 p, in float l, in float a )
{
    if( p.y<0.0 ) return p;

    a *= smoothstep(l*1.5,l*0.5,length(p));

    if( abs(a)<0.001 ) return p;

    float ra = 0.5*l/a;
    p.x -= ra;
    float s = sign(a);
    return vec2( ra-s*length(p), ra*atan(s*p.y,-s*p.x) );
}

// https://iquilezles.org/articles/checkerfiltering
float checker( in vec2 p )
{
    vec2 w = fwidth(p) + 0.01;  
    vec2 i = 2.0*(abs(fract((p-0.5*w)/2.0)-0.5)-abs(fract((p+0.5*w)/2.0)-0.5))/w;
    return 0.5 - 0.5*i.x*i.y;                  
}

// https://iquilezles.org/articles/distfunctions2d
float sdArc( in vec2 p, in vec2 scb, in float ra, in float rb )
{
    p.x = abs(p.x);
    float k = (scb.y*p.x>scb.x*p.y) ? dot(p.xy,scb) : length(p.xy);
    return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

// https://iquilezles.org/articles/distfunctions2d
float sdStar(in vec2 p, in float r, in int n, in float m) // m=[2,n]
{
    // these 4 lines can be precomputed for a given shape
    float an = 3.141593/float(n);
    float en = 3.141593/m;
    vec2  acs = vec2(cos(an),sin(an));
    vec2  ecs = vec2(cos(en),sin(en)); // ecs=vec2(0,1) and simplify, for regular polygon,
    // reduce to first sector
    float bn = mod(atan(p.x,p.y),2.0*an) - an;
    p = length(p)*vec2(cos(bn),abs(sin(bn)));
    // line sdf
    p -= r*acs;
    p += ecs*clamp( -dot(p,ecs), 0.0, r*acs.y/ecs.y);
    return length(p)*sign(p.x);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // normalized pixel coordinates
    vec2 q = (fragCoord*2.0-iResolution.xy)/iResolution.y;
   
    // recenter
    vec2 p = q; p.y += 0.4;
    // space bend
    float le = 2.0;                // length
    float an = 0.6*sin(iTime*3.0); // angle
    p = bend(p,le,an);

    // star
    float d = sdStar(p-vec2(0.0,0.4), 0.8, 5, 3.0 ) - 0.05;
    d = max( d, -sdArc( vec2(abs(p.x)-0.2,p.y-0.44), vec2(0.8,0.6), 0.15, 0.02 ) );
	d = max( d, -sdArc( vec2(p.x,0.45-p.y), vec2(0.8,0.6), 0.25, 0.05 ) );
        
    // coloring
	vec3 col = texture(iChannel0,q+0.5).xyz;
	if( sin(iTime)<0.0 )
    {
        col = vec3(0.6+0.1*checker(p*6.0));
        col *= 1.0 + 0.1*cos(128.0*d);
    }
    col *= 1.0 - 0.75*exp(-10.0*d);
    if( d<0.0 )
        col = texture(iChannel0,p+0.5).xyz;
	col = mix( col, vec3(1.0), 1.0-smoothstep(0.0,0.01,abs(d)) );
    col = sqrt(col);

	fragColor = vec4(col, 1.0);
}