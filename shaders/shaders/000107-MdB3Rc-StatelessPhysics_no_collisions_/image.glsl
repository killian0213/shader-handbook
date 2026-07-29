// Image (image) — StatelessPhysics (no collisions) by iq
// https://www.shadertoy.com/view/MdB3Rc

// The MIT License
// Copyright © 2014 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// draw a disk with motion blur
vec3 diskWithMotionBlur( vec3 col, in vec2 uv, in vec3 sph, in vec2 cd, in vec3 sphcol, in float alpha )
{
	vec2 xc = uv - sph.xy;
	float a = dot(cd,cd);
	float b = dot(cd,xc);
	float c = dot(xc,xc) - sph.z*sph.z;
	float h = b*b - a*c;
	if( h>0.0 )
	{
		h = sqrt( h );
		
		float ta = max( 0.0, (-b - h)/a );
		float tb = min( 1.0, (-b + h)/a );
		
        col = mix( col, sphcol, alpha*clamp(2.0*(tb-ta),0.0,1.0) );
	}
	return col;
}

// intersect a disk moving in a parabolic trajecgory with a line/plane. 
// sphere is |x(t)|-R²=0, with x(t) = p + v·t + ½·a·t²
// plane is <x,n> + k = 0
float iPlane( in vec2 p, in vec2 v, in vec2 a, float rad, vec3 pla )
{
	float k2 = dot(a,pla.xy);
	float k1 = dot(v,pla.xy);
	float k0 = dot(p,pla.xy) + pla.z - rad;
	float h = k1*k1 - 2.0*k2*k0;
	if( h>0.0 )
		h = (-k1-sqrt(h))/k2;
	return h;
}

vec2 GetPos( in vec2 p, in vec2 v, in vec2 a, float t )
{
	return p + v*t + 0.5*a*t*t;
}
vec2 GetVel( in vec2 p, in vec2 v, in vec2 a, float t )
{
	return v + a*t;
}

float hash1( float p ) { return fract(sin(p)*43758.5453); }
vec2  hash2( float p ) { vec2 q = vec2( p, p+123.123 ); return fract(sin(q)*43758.5453); }

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2  p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
	float w = iResolution.x/iResolution.y;

    vec3 pla0 = vec3( 0.0,1.0,1.0);
    vec3 pla1 = vec3(-1.0,0.0,  w);	
    vec3 pla2 = vec3( 1.0,0.0,  w);
		
	vec3 col = vec3(0.15 + 0.05*p.y);
	
	for( int i=0; i<8; i++ )
    {
        // start position		
		float id = float(i);

	    float time = mod( iTime + id*0.5, 4.8 );
	    float sequ = floor( (iTime+id*0.5)/4.8 );
		float life = time/4.8;

		float rad = 0.05 + 0.1*hash1(id*13.0 + sequ);
		vec2 pos = vec2(-w,0.8) + vec2(2.0*w,0.2)*hash2( id + sequ );
		vec2 vel = (-1.0 + 2.0*hash2( id+13.76 + sequ ))*vec2(8.0,1.0);
        const vec2 acc = vec2(0.01,-9.0);

        // integrate 10 bounces. after the loop, pos and vel contain the
        // position and velocity of the ball at the current time. h
        // contains the time since hat collision.
		float h = 0.0;
	    for( int j=0; j<10; j++ )
	    {
			float ih = 100000.0;
			vec2 nor = vec2(0.0,1.0);

			// intersect planes
			float s;
			s = iPlane( pos, vel, acc, rad, pla0 ); if( s>0.0 && s<ih ) { ih=s; nor=pla0.xy; }
			s = iPlane( pos, vel, acc, rad, pla1 ); if( s>0.0 && s<ih ) { ih=s; nor=pla1.xy; }
			s = iPlane( pos, vel, acc, rad, pla2 ); if( s>0.0 && s<ih ) { ih=s; nor=pla2.xy; }
			
            if( ih<1000.0 && (h+ih)<time )		
			{
				vec2 npos = GetPos( pos, vel, acc, ih );
				vec2 nvel = GetVel( pos, vel, acc, ih );
				pos = npos;
				vel = nvel;
				vel = 0.75*reflect( vel, nor );
				pos += 0.01*vel;
                h += ih;
			}
        }
		
        // last parabolic segment
		h = time - h;
		vec2 npos = GetPos( pos, vel, acc, h );
		vec2 nvel = GetVel( pos, vel, acc, h );
		pos = npos;
		vel = nvel;

        // render
		vec3  scol = 0.5 + 0.5*sin( hash1(id)*2.0 - 1.0 + vec3(0.0,2.0,4.0) );
		float alpha = smoothstep(0.0,0.1,life)-smoothstep(0.8,1.0,life);
		col = diskWithMotionBlur( col, p, vec3(pos,rad), vel/24.0, scol, alpha );
    }

    col += (1.0/255.0)*hash1(p.x+13.0*p.y);

	fragColor = vec4(col,1.0);
}