// Image (image) — Noise - Gradient - 3D - Deriv by iq
// https://www.shadertoy.com/view/4dffRH

// The MIT License
// Copyright © 2017 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org/

// Computes the analytic derivatives of a 3D Gradient Noise. This can be used for example to compute normals to a
// 3d rocks based on Gradient Noise without approximating the gradient by having to take central differences.
//
// More info here: https://iquilezles.org/articles/gradientnoise

// All noise functions here:
//
// https://www.shadertoy.com/playlist/fXlXzf&from=0&num=12


// 0: integer hash
// 1: float hash (aliasing based)
#define METHOD 0

// 0: cubic
// 1: quintic
#define INTERPOLANT 1


#if METHOD==0
vec3 hash( ivec3 p )     // this hash is not production ready, please
{                        // replace this by something better
	ivec3 n = ivec3( p.x*127 + p.y*311 + p.z*74,
                     p.x*269 + p.y*183 + p.z*246,
                     p.x*113 + p.y*271 + p.z*124);

	// 1D hash by Hugo Elias
	n = (n << 13) ^ n;
    n = n * (n * n * 15731 + 789221) + 1376312589;
    return -1.0+2.0*vec3( n & ivec3(0x0fffffff))/float(0x0fffffff);
}
#else
vec3 hash( vec3 p )      // this hash is not production ready, please
{                        // replace this by something better
	p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
			  dot(p,vec3(269.5,183.3,246.1)),
			  dot(p,vec3(113.5,271.9,124.6)));

	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}
#endif


// return value noise (in x) and its derivatives (in yzw)
vec4 noised( in vec3 x )
{
    // grid
    #if METHOD==0
    ivec3 i = ivec3(floor(x));
    #else
    vec3 i = floor(x);
    #endif
    vec3 f = fract(x);
    
    #if INTERPOLANT==1
    // quintic interpolant
    vec3 u = f*f*f*(f*(f*6.0-15.0)+10.0);
    vec3 du = 30.0*f*f*(f*(f-2.0)+1.0);
    #else
    // cubic interpolant
    vec3 u = f*f*(3.0-2.0*f);
    vec3 du = 6.0*f*(1.0-f);
    #endif    
    
    // gradients
    #if METHOD==0
    vec3 ga = hash( i+ivec3(0,0,0) );
    vec3 gb = hash( i+ivec3(1,0,0) );
    vec3 gc = hash( i+ivec3(0,1,0) );
    vec3 gd = hash( i+ivec3(1,1,0) );
    vec3 ge = hash( i+ivec3(0,0,1) );
	vec3 gf = hash( i+ivec3(1,0,1) );
    vec3 gg = hash( i+ivec3(0,1,1) );
    vec3 gh = hash( i+ivec3(1,1,1) );
    #else
    vec3 ga = hash( i+vec3(0.0,0.0,0.0) );
    vec3 gb = hash( i+vec3(1.0,0.0,0.0) );
    vec3 gc = hash( i+vec3(0.0,1.0,0.0) );
    vec3 gd = hash( i+vec3(1.0,1.0,0.0) );
    vec3 ge = hash( i+vec3(0.0,0.0,1.0) );
	vec3 gf = hash( i+vec3(1.0,0.0,1.0) );
    vec3 gg = hash( i+vec3(0.0,1.0,1.0) );
    vec3 gh = hash( i+vec3(1.0,1.0,1.0) );
    #endif
    
    // projections
    float va = dot( ga, f-vec3(0.0,0.0,0.0) );
    float vb = dot( gb, f-vec3(1.0,0.0,0.0) );
    float vc = dot( gc, f-vec3(0.0,1.0,0.0) );
    float vd = dot( gd, f-vec3(1.0,1.0,0.0) );
    float ve = dot( ge, f-vec3(0.0,0.0,1.0) );
    float vf = dot( gf, f-vec3(1.0,0.0,1.0) );
    float vg = dot( gg, f-vec3(0.0,1.0,1.0) );
    float vh = dot( gh, f-vec3(1.0,1.0,1.0) );
	
    // interpolations
    float k0 = va-vb-vc+vd;
    vec3  g0 = ga-gb-gc+gd;
    float k1 = va-vc-ve+vg;
    vec3  g1 = ga-gc-ge+gg;
    float k2 = va-vb-ve+vf;
    vec3  g2 = ga-gb-ge+gf;
    float k3 = -va+vb+vc-vd+ve-vf-vg+vh;
    vec3  g3 = -ga+gb+gc-gd+ge-gf-gg+gh;
    float k4 = vb-va;
    vec3  g4 = gb-ga;
    float k5 = vc-va;
    vec3  g5 = gc-ga;
    float k6 = ve-va;
    vec3  g6 = ge-ga;
    
    return vec4( va + k4*u.x + k5*u.y + k6*u.z + k0*u.x*u.y + k1*u.y*u.z + k2*u.z*u.x + k3*u.x*u.y*u.z,    // value
                 ga + g4*u.x + g5*u.y + g6*u.z + g0*u.x*u.y + g1*u.y*u.z + g2*u.z*u.x + g3*u.x*u.y*u.z +   // derivatives
                 du * (vec3(k4,k5,k6) + 
                       vec3(k0,k1,k2)*u.yzx +
                       vec3(k2,k0,k1)*u.zxy +
                       k3*u.yzx*u.zxy ));
}

//===============================================================================================
//===============================================================================================
//===============================================================================================
//===============================================================================================
//===============================================================================================

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 p = (-iResolution.xy + 2.0*fragCoord) / iResolution.y;

     // camera movement	
	float an = 0.5*iTime;
	vec3 ro = vec3( 2.5*cos(an), 1.0, 2.5*sin(an) );
    vec3 ta = vec3( 0.0, 1.0, 0.0 );
    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
	// create view ray
	vec3 rd = normalize( p.x*uu + p.y*vv + 1.5*ww );

    // sphere center	
	vec3 sc = vec3(0.0,1.0,0.0);

    // raytrace
	float tmin = 10000.0;
	vec3  nor = vec3(0.0);
	float occ = 1.0;
	vec3  pos = vec3(0.0);
	
	// raytrace-plane
	float h = (0.0-ro.y)/rd.y;
	if( h>0.0 ) 
	{ 
		tmin = h; 
		nor = vec3(0.0,1.0,0.0); 
		pos = ro + h*rd;
		vec3 di = sc - pos;
		float l = length(di);
		occ = 1.0 - dot(nor,di/l)*1.0*1.0/(l*l); 
	}

	// raytrace-sphere
	vec3  ce = ro - sc;
	float b = dot( rd, ce );
	float c = dot( ce, ce ) - 1.0;
	h = b*b - c;
	if( h>0.0 )
	{
		h = -b - sqrt(h);
		if( h<tmin ) 
		{ 
			tmin=h; 
			nor = normalize(ro+h*rd-sc); 
			occ = 0.5 + 0.5*nor.y;
		}
	}

    // shading/lighting	
	vec3 col = vec3(0.9);
	if( tmin<100.0 )
	{
	    pos = ro + tmin*rd;

        vec4 n = noised( 12.0*pos );
        col = 0.5 + 0.5*((p.x>0.0)?n.yzw:n.xxx);
		
		col = mix( col, vec3(0.9), 1.0-exp( -0.003*tmin*tmin ) );
	}
	
	
	fragColor = vec4( col, 1.0 );
}