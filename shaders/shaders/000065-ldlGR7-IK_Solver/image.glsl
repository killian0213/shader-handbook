// Image (image) — IK Solver by iq
// https://www.shadertoy.com/view/ldlGR7

// The MIT License
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// An analytical IK solver for 2 segments, WITHOUT trigonometry - gven two
// base and tip white points at which the bones start and end, the red join
// (yellow) is computed automatically by the solver. You can read the
// derivation here:
//
// https://iquilezles.org/articles/simpleik/
//
// A 3D version of this is used in the Insect shader https://www.shadertoy.com/view/Mss3zM
//
// Move the mouse to see the behavior of the solver.



#if 1
// https://iquilezles.org/articles/simpleik/
vec2 solve( vec2 p, float r1, float r2 )
{
	vec2 q = p*(0.5+0.5*(r1*r1-r2*r2)/dot(p,p));

	float s = r1*r1/dot(q,q)-1.0;
	if( s<0.0 ) return vec2(-1.0); // no solution
	
    return q + vec2(-q.y,q.x)*sqrt(s);
}

#else

// alternative, single division
vec2 solve( vec2 p, float r1, float r2 )
{
    float h2 = dot(p,p);
    float w = h2 + r1*r1 - r2*r2;
    float s = 4.0*r1*r1*h2 - w*w;
    
	if( s<0.0 ) return vec2(-1.0); // no solution
    
    return (w*p + vec2(-p.y,p.x)*sqrt(s)) * 0.5/h2;
}
#endif

    

// https://iquilezles.org/articles/distfunctions2d/
float sdSegment( vec2 a, vec2 b, vec2 p )
{
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // pixel setup
    vec2 uv = (2.0*fragCoord-iResolution.xy) / iResolution.y;
	vec2 mo = (2.0*iMouse.xy-iResolution.xy) / iResolution.y;
	if( iMouse.z<=0.0001 ) { mo = vec2(0.8+0.3*sin(iTime),0.2+0.2*sin(iTime*1.31)+0.2*sin(iTime*2.11)); }
	

    // compute IK
	const float l1 = 0.8;        // length of first segment
	const float l2 = 0.4;        // length of second segment
	vec2 a = vec2(0.0,0.0);      // location of base
	vec2 c = mo;                 // location of tip
	vec2 b = solve( c, l1, l2 ); // compute location of join


    // draw background
	vec3 col = vec3(0.3)*(1.0-0.2*length(uv));

    // plot circles
	col = mix( col, vec3(0.5,0.5,0.5), 1.0-smoothstep( 0.0, 0.007, abs(length( a - uv )-l1) ) );
	col = mix( col, vec3(0.5,0.5,0.5), 1.0-smoothstep( 0.0, 0.007, abs(length( c - uv )-l2) ) );

    // plot segments and join
	if( b.x>-99.0 )
	{
	float f = min( sdSegment( a, b, uv ), sdSegment( b, c, uv ) ) - 0.002;
	col = mix( col, vec3(1.0,1.0,1.0), 1.0-smoothstep( 0.000, 0.005, f ) );
	col = mix( col, vec3(1.0,1.0,0.0), 1.0-smoothstep( 0.035, 0.040, length( b - uv ) ) );
	}

    // plot base and tip
	col = mix( col, vec3(1.0,1.0,1.0), 1.0-smoothstep( 0.035, 0.040, length( a - uv ) ) );
	col = mix( col, vec3(1.0,1.0,1.0), 1.0-smoothstep( 0.035, 0.040, length( c - uv ) ) );
	
    // dither to remove banding in the background
    col += fract(sin(fragCoord.x*vec3(13,17,11)+fragCoord.y*vec3(1,7,5))*158.391832)/255.0;

	fragColor = vec4( col, 1.0 );
}