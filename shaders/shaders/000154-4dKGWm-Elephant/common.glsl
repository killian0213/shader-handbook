// Common (common) — Elephant by iq
// https://www.shadertoy.com/view/4dKGWm

// The MIT License
// Copyright © 2016 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// https://iquilezles.org/articles/smin
float smin( float a, float b, float k )
{
    //return min(a,b);
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}

// https://iquilezles.org/articles/smin
float smax( float a, float b, float k )
{
    return -smin(-a,-b,k);
}

// https://iquilezles.org/articles/distfunctions
vec2 sdSegment( in vec3 p, vec3 a, vec3 b )
{
	vec3 pa = p - a, ba = b - a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return vec2( length( pa - ba*h ), h );
}

// https://iquilezles.org/articles/distfunctions
float sdEllipsoid( in vec3 p, in vec3 c, in vec3 r )
{
#if 1   
    return (length( (p-c)/r ) - 1.0) * min(min(r.x,r.y),r.z);
#else
    p -= c;
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
#endif    
}

// http://research.microsoft.com/en-us/um/people/hoppe/ravg.pdf
float det( vec2 a, vec2 b ) { return a.x*b.y-b.x*a.y; }
vec3 getClosest( vec2 b0, vec2 b1, vec2 b2 ) 
{
  float a =     det(b0,b2);
  float b = 2.0*det(b1,b0);
  float d = 2.0*det(b2,b1);
  float f = b*d - a*a;
  vec2  d21 = b2-b1;
  vec2  d10 = b1-b0;
  vec2  d20 = b2-b0;
  vec2  gf = 2.0*(b*d21+d*d10+a*d20); gf = vec2(gf.y,-gf.x);
  vec2  pp = -f*gf/dot(gf,gf);
  vec2  d0p = b0-pp;
  float ap = det(d0p,d20);
  float bp = 2.0*det(d10,d0p);
  float t = clamp( (ap+bp)/(2.0*a+b+d), 0.0 ,1.0 );
  return vec3( mix(mix(b0,b1,t), mix(b1,b2,t),t), t );
}

vec2 sdBezier( vec3 a, vec3 b, vec3 c, vec3 p, out vec2 pos )
{
	vec3 w = normalize( cross( c-b, a-b ) );
	vec3 u = normalize( c-b );
	vec3 v = normalize( cross( w, u ) );

	vec2 a2 = vec2( dot(a-b,u), dot(a-b,v) );
	vec2 b2 = vec2( 0.0 );
	vec2 c2 = vec2( dot(c-b,u), dot(c-b,v) );
	vec3 p3 = vec3( dot(p-b,u), dot(p-b,v), dot(p-b,w) );

	vec3 cp = getClosest( a2-p3.xy, b2-p3.xy, c2-p3.xy );

    pos = cp.xy;
    
	return vec2( sqrt(dot(cp.xy,cp.xy)+p3.z*p3.z), cp.z );
}

// https://iquilezles.org/articles/distfunctions
float sdSphere( in vec3 p, in vec3 c, in float r )
{
    return length(p-c) - r;
}

// https://iquilezles.org/articles/intersectors
vec2 iCylinderY( in vec3 ro, in vec3 rd, in vec4 sph )
{
	vec3 oc = ro - sph.xyz;
    float a = dot( rd.xz, rd.xz );
	float b = dot( oc.xz, rd.xz );
	float c = dot( oc.xz, oc.xz ) - sph.w*sph.w;
	float h = b*b - a*c;
	if( h<0.0 ) return vec2(-1.0);
    h = sqrt(h);
	return vec2(-b-h, -b+h )/a;
}

// https://www.shadertoy.com/view/llsSzn
float eliSoftShadow( in vec3 ro, in vec3 rd, in vec3 sphcen, in vec3 sphrad, in float k )
{
    vec3 oc = ro - sphcen;
    
    vec3 ocn = oc / sphrad;
    vec3 rdn = rd / sphrad;
    
    float a = dot( rdn, rdn );
	float b = dot( ocn, rdn );
	float c = dot( ocn, ocn );
	float h = b*b - a*(c-1.0);

    float t = (-b - sqrt( max(h,0.0) ))/a;

    return (h>0.0) ? step(t,0.0) : smoothstep(0.0, 1.0, -k*h/max(t,0.0) );
}

// https://iquilezles.org/articles/biplanar
vec4 texcube( sampler2D sam, in vec3 p, in vec3 n, in float k, in vec3 g1, in vec3 g2 )
{
    vec3 m = pow( abs( n ), vec3(k) );
	vec4 x = textureGrad( sam, p.yz, g1.yz, g2.yz );
	vec4 y = textureGrad( sam, p.zx, g1.zx, g2.zx );
	vec4 z = textureGrad( sam, p.xy, g1.xy, g2.xy );
	return (x*m.x + y*m.y + z*m.z) / (m.x + m.y + m.z);
}

float hash1( float n )
{
    return fract(sin(n)*43758.5453123);
}

vec2 hash2( in vec2 f ) 
{ 
    float n = f.x+131.1*f.y;
    return fract(sin(vec2(n,n+113.0))*43758.5453123); 
}

vec2 hash2( float n )
{
    return fract(sin(vec2(n,n+1.0))*vec2(43758.5453123,22578.1459123));
}

vec3 hash3( float n )
{
    return fract(sin(n+vec3(0.0,13.1,31.3))*158.5453123);
}

vec3 forwardSF( float i, float n) 
{
    const float PI  = 3.141592653589793238;
    const float PHI = 1.618033988749894848;
    float phi = 2.0*PI*fract(i/PHI);
    float zi = 1.0 - (2.0*i+1.0)/n;
    float sinTheta = sqrt( 1.0 - zi*zi);
    return vec3( cos(phi)*sinTheta, sin(phi)*sinTheta, zi);
}

mat3 base( in vec3 ww )
{
    vec3  vv = vec3(0.0,0.0,1.0);
    vec3  uu = normalize( cross( vv, ww ) );
    return mat3(uu.x,ww.x,vv.x,
                uu.y,ww.y,vv.y,
                uu.z,ww.z,vv.z);
}

mat3 setCamera( in vec3 ro, in vec3 rt, in float cr )
{
	vec3 cw = normalize(rt-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, -cw );
}

#define ZERO (min(iFrame,0))
