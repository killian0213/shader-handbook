// Image (image) — 2D Cloth by iq
// https://www.shadertoy.com/view/4dG3R1

// The MIT License
// Copyright © 2016 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


float hash1( ivec2 p ) { float n = dot(vec2(p),vec2(127.1,311.7)); return fract(sin(n)*153.4353); }

float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
	vec2 pa = p-a, ba = b-a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h );
}

vec4 getParticle( ivec2 id )
{
    return texelFetch( iChannel0, id, 0 );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.y;
    
    vec3 f = vec3(0.0);
    for( int j=0; j<10; j++ )
    for( int i=0; i<10; i++ )
    {
        ivec2 id = ivec2( i, j );
        vec4 p = getParticle( id );

        float d = 1.0;
        
        #if 1
        if( i<9 )        d = min(d, sdSegment( uv, p.xy, getParticle( id+ivec2(1,0) ).xy ));
        if( j<9 )        d = min(d, sdSegment( uv, p.xy, getParticle( id+ivec2(0,1) ).xy ) );
        if( i<9 && j<9 ) d = min(d, sdSegment( uv, p.xy, getParticle( id+ivec2(1,1) ).xy ));
        if( i>0 && j<9 ) d = min(d, sdSegment( uv, p.xy, getParticle( id+ivec2(-1,1) ).xy ) );
        f = mix( f, vec3(0.4,0.6,0.8), 1.0-smoothstep( 0.0, 0.005, d ) );
        #endif
        
        d = length(uv-p.xy)-0.035;
        vec3 col = 0.6 + 0.4*sin( hash1(id)*30.0 + vec3(0.0,1.0,2.0) );
        col *= 0.8 + 0.2*smoothstep( -0.1, 0.1, sin(d*400.0) );
        f = mix( f, col, 1.0-smoothstep( -0.001, 0.001, d ) );
            
    }
    
    fragColor = vec4(f,1.0);
}