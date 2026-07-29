// Image (image) — SH - visualizer by iq
// https://www.shadertoy.com/view/lsfXWH

// The MIT License
// Copyright © 2014 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org

// Four bands of Spherical Harmonics functions (or atomic orbitals if you want).

// uncomment to show spheres instead
//#define SHOW_SPHERES


#if HW_PERFORMANCE==0
#define AA 1
#else
#define AA 2   // antialias level (try 1, 2, 3, ...)
#endif

//---------------------------------------------------------------------------------

// Constants, see here: http://en.wikipedia.org/wiki/Table_of_spherical_harmonics
const float k01 = 0.2820947918; // sqrt(  1/PI)/2
const float k02 = 0.4886025119; // sqrt(  3/PI)/2
const float k03 = 1.0925484306; // sqrt( 15/PI)/2
const float k04 = 0.3153915652; // sqrt(  5/PI)/4
const float k05 = 0.5462742153; // sqrt( 15/PI)/4
const float k06 = 0.5900435860; // sqrt( 70/PI)/8
const float k07 = 2.8906114210; // sqrt(105/PI)/2
const float k08 = 0.4570214810; // sqrt( 42/PI)/8
const float k09 = 0.3731763300; // sqrt(  7/PI)/4
const float k10 = 1.4453057110; // sqrt(105/PI)/4

// Y_l_m(s), where l is the band and m the range in [-l..l] 
float SH_0_0( in vec3 s ) { vec3 n = s.zxy; return  k01; }
float SH_1_0( in vec3 s ) { vec3 n = s.zxy; return -k02*n.y; }
float SH_1_1( in vec3 s ) { vec3 n = s.zxy; return  k02*n.z; }
float SH_1_2( in vec3 s ) { vec3 n = s.zxy; return -k02*n.x; }
float SH_2_0( in vec3 s ) { vec3 n = s.zxy; return  k03*n.x*n.y; }
float SH_2_1( in vec3 s ) { vec3 n = s.zxy; return -k03*n.y*n.z; }
float SH_2_2( in vec3 s ) { vec3 n = s.zxy; return  k04*(3.0*n.z*n.z-1.0); }
float SH_2_3( in vec3 s ) { vec3 n = s.zxy; return -k03*n.x*n.z; }
float SH_2_4( in vec3 s ) { vec3 n = s.zxy; return  k05*(n.x*n.x-n.y*n.y); }
float SH_3_0( in vec3 s ) { vec3 n = s.zxy; return -k06*n.y*(3.0*n.x*n.x-n.y*n.y); }
float SH_3_1( in vec3 s ) { vec3 n = s.zxy; return  k07*n.z*n.y*n.x; }
float SH_3_2( in vec3 s ) { vec3 n = s.zxy; return -k08*n.y*(5.0*n.z*n.z-1.0); }
float SH_3_3( in vec3 s ) { vec3 n = s.zxy; return  k09*n.z*(5.0*n.z*n.z-3.0); }
float SH_3_4( in vec3 s ) { vec3 n = s.zxy; return -k08*n.x*(5.0*n.z*n.z-1.0); }
float SH_3_5( in vec3 s ) { vec3 n = s.zxy; return  k10*n.z*(n.x*n.x-n.y*n.y); }
float SH_3_6( in vec3 s ) { vec3 n = s.zxy; return -k06*n.x*(n.x*n.x-3.0*n.y*n.y); }

vec3 map( in vec3 p )
{
    vec3 p00 = p - vec3( 0.00, 2.5,0.0);
	vec3 p01 = p - vec3(-1.25, 1.0,0.0);
	vec3 p02 = p - vec3( 0.00, 1.0,0.0);
	vec3 p03 = p - vec3( 1.25, 1.0,0.0);
	vec3 p04 = p - vec3(-2.50,-0.5,0.0);
	vec3 p05 = p - vec3(-1.25,-0.5,0.0);
	vec3 p06 = p - vec3( 0.00,-0.5,0.0);
	vec3 p07 = p - vec3( 1.25,-0.5,0.0);
	vec3 p08 = p - vec3( 2.50,-0.5,0.0);
	vec3 p09 = p - vec3(-3.75,-2.0,0.0);
	vec3 p10 = p - vec3(-2.50,-2.0,0.0);
	vec3 p11 = p - vec3(-1.25,-2.0,0.0);
	vec3 p12 = p - vec3( 0.00,-2.0,0.0);
	vec3 p13 = p - vec3( 1.25,-2.0,0.0);
	vec3 p14 = p - vec3( 2.50,-2.0,0.0);
	vec3 p15 = p - vec3( 3.75,-2.0,0.0);
	
	float r, d; vec3 n, s, res;
	
    #ifdef SHOW_SPHERES
	#define SHAPE (vec3(d-0.35, -1.0+2.0*clamp(0.5 + 16.0*r,0.0,1.0),d))
	#else
	#define SHAPE (vec3(d-abs(r), sign(r),d))
	#endif
	d=length(p00); n=p00/d; r=SH_0_0( n ); s=SHAPE;                 res=s;
	d=length(p01); n=p01/d; r=SH_1_0( n ); s=SHAPE; if( s.x<res.x ) res=s;
	d=length(p02); n=p02/d; r=SH_1_1( n ); s=SHAPE; if( s.x<res.x ) res=s;
	d=length(p03); n=p03/d; r=SH_1_2( n ); s=SHAPE; if( s.x<res.x ) res=s;
	d=length(p04); n=p04/d; r=SH_2_0( n ); s=SHAPE; if( s.x<res.x ) res=s;
	d=length(p05); n=p05/d; r=SH_2_1( n ); s=SHAPE; if( s.x<res.x ) res=s;
	d=length(p06); n=p06/d; r=SH_2_2( n ); s=SHAPE; if( s.x<res.x ) res=s;
	d=length(p07); n=p07/d; r=SH_2_3( n ); s=SHAPE; if( s.x<res.x ) res=s;
	d=length(p08); n=p08/d; r=SH_2_4( n ); s=SHAPE; if( s.x<res.x ) res=s;
	d=length(p09); n=p09/d; r=SH_3_0( n ); s=SHAPE; if( s.x<res.x ) res=s;
	d=length(p10); n=p10/d; r=SH_3_1( n ); s=SHAPE; if( s.x<res.x ) res=s;
	d=length(p11); n=p11/d; r=SH_3_2( n ); s=SHAPE; if( s.x<res.x ) res=s;
	d=length(p12); n=p12/d; r=SH_3_3( n ); s=SHAPE; if( s.x<res.x ) res=s;
	d=length(p13); n=p13/d; r=SH_3_4( n ); s=SHAPE; if( s.x<res.x ) res=s;
	d=length(p14); n=p14/d; r=SH_3_5( n ); s=SHAPE; if( s.x<res.x ) res=s;
	d=length(p15); n=p15/d; r=SH_3_6( n ); s=SHAPE; if( s.x<res.x ) res=s;
	
	return vec3( res.x, 0.5+0.5*res.y, res.z );
}

// https://iquilezles.org/articles/boxfunctions
vec2 iBox( in vec3 ro, in vec3 rd, in vec3 rad ) 
{
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*rad;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
	return vec2( max(max(t1.x,t1.y),t1.z), min(min(t2.x,t2.y),t2.z) );
}

vec3 intersect( in vec3 ro, in vec3 rd )
{
	vec3 res = vec3(1e10,-1.0, 1.0);

    float tmin = 0.0;
    float tmax = 10.0;
    
    // bounding volume
    vec2 tb = iBox( ro, rd, vec3(5.0,3.0,0.6) ); 
    if( tb.x<tb.y && tb.y>0.0 )
    {
        tmin = max(tb.x,tmin); // clip raymarch to 
        tmax = min(tb.y,tmax); // bounding box extents

        // raymarch
        float t = tmin;
        vec2  m = vec2(-1.0);
        for( int i=0; i<100 && t<tmax; i++ )
        {
            vec3 res = map( ro+rd*t );
            if( res.x<0.001 ) break;
            m = res.yz;
            t += res.x*0.3;
        }
        if( t<tmax ) res=vec3(t,m);
    }
    
	return res;
}

// https://iquilezles.org/articles/normalsSDF/
vec3 calcNormal( in vec3 pos )
{
    const vec2 eps = vec2(0.001,0.0);

	return normalize( vec3(
           map(pos+eps.xyy).x - map(pos-eps.xyy).x,
           map(pos+eps.yxy).x - map(pos-eps.yxy).x,
           map(pos+eps.yyx).x - map(pos-eps.yyx).x ) );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // camera
    float an = 0.314*iTime - 10.0*iMouse.x/iResolution.x;
    vec3  ro = vec3(6.0*sin(an),0.0,6.0*cos(an));
    vec3  ta = vec3(0.0,0.0,0.0);

    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    
    vec3 tot = vec3(0.0);

    #define ZERO min(iFrame,0)
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {        
        vec2 p = (2.0*(fragCoord+vec2(float(m),float(n))/float(AA))-iResolution.xy)/iResolution.y;

        // create view ray
        vec3 rd = normalize( p.x*uu + p.y*vv + 2.0*ww );

        // background 
        vec3 col = vec3(0.3) * clamp(1.0-length(p)*0.45,0.0,1.0);

        // raymarch
        vec3 tmat = intersect(ro,rd);
        if( tmat.y>-0.5 )
        {
            // geometry
            vec3 pos = ro + tmat.x*rd;
            vec3 nor = calcNormal(pos);
            vec3 ref = reflect( rd, nor );

            // material		
            vec3 mate = 0.5*mix( vec3(1.0,0.6,0.15), vec3(0.2,0.4,0.5), tmat.y );

            float occ = clamp( 2.0*tmat.z, 0.0, 1.0 );
            float sss = pow( clamp( 1.0 + dot(nor,rd), 0.0, 1.0 ), 1.0 );

            // lights
            vec3 lin  = 2.5*occ*vec3(1.0,1.00,1.00)*(0.6+0.4*nor.y);
                 lin += 1.0*sss*vec3(1.0,0.95,0.70)*occ;		

            // surface-light interaction
            col = mate.xyz * lin;
        }

        // gamma (yes, before accumulation!)
        col = pow( clamp(col,0.0,1.0), vec3(0.4545) );
        tot += col;
    }
    tot /= float(AA*AA);

    // bad dither
    tot += (1.0/255.0)*fract(sin(fragCoord.x+1111.0*fragCoord.y)*1111.0);
    
    fragColor = vec4( tot, 1.0 );
}
