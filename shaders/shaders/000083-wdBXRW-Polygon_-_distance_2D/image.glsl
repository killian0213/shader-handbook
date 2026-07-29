// Image (image) — Polygon - distance 2D by iq
// https://www.shadertoy.com/view/wdBXRW

// The MIT License
// Copyright © 2019 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Distance to a regular pentagon, without trigonometric functions. 

// List of some other 2D distances:
//    https://www.shadertoy.com/playlist/MXdSRf
// and
//    iquilezles.org/articles/distfunctions2d

const int N = 5;

float sdPolygon( in vec2 p, in vec2[N] v )
{
    const int num = v.length();
    float d = dot(p-v[0],p-v[0]);
    float s = 1.0;
    for( int i=0, j=num-1; i<num; j=i, i++ )
    {
        // distance
        vec2 e = v[j] - v[i];
        vec2 w =    p - v[i];
        vec2 b = w - e*clamp( dot(w,e)/dot(e,e), 0.0, 1.0 );
        d = min( d, dot(b,b) );

        // winding number from http://geomalgorithms.com/a03-_inclusion.html
        bvec3 cond = bvec3( p.y>=v[i].y, 
                            p.y <v[j].y, 
                            e.x*w.y>e.y*w.x );
        if( all(cond) || all(not(cond)) ) s=-s;  
    }
    
    return s*sqrt(d);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
    vec2 m = (2.0*iMouse.xy-iResolution.xy)/iResolution.y;
    
	vec2 v0 = 0.8*cos( 0.40*iTime + vec2(0.0,2.00) + 0.0 );
	vec2 v1 = 0.8*cos( 0.45*iTime + vec2(0.0,1.50) + 1.0 );
	vec2 v2 = 0.8*cos( 0.50*iTime + vec2(0.0,3.00) + 2.0 );
	vec2 v3 = 0.8*cos( 0.55*iTime + vec2(0.0,2.00) + 4.0 );
    vec2 v4 = 0.8*cos( 0.60*iTime + vec2(0.0,1.00) + 5.0 );
    
    // add more points
    vec2[] polygon = vec2[](v0,v1,v2,v3,v4);
    
	float d = sdPolygon(p, polygon);

    vec3 col = (d>0.0) ? vec3(0.9,0.6,0.3) : vec3(0.65,0.85,1.0);
	col *= 1.0 - exp(-6.0*abs(d));
	col *= 0.8 + 0.2*cos(140.0*d);
	col = mix( col, vec3(1.0), 1.0-smoothstep(0.0,0.015,abs(d)) );
    
    if( iMouse.z>0.001 )
    {
    d = sdPolygon( m, polygon );
    col = mix(col, vec3(1.0,1.0,0.0), 1.0-smoothstep(0.0, 0.005, abs(length(p-m)-abs(d))-0.0025));
    col = mix(col, vec3(1.0,1.0,0.0), 1.0-smoothstep(0.0, 0.005, length(p-m)-0.015));
    }
    
    fragColor = vec4(col,1.0);
}