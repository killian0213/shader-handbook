// Common (common) — Surfer Boy by iq
// https://www.shadertoy.com/view/ldd3DX

// antialiasing - make AA 2, meaning 4x AA, if you have a fast machine
#define AA 1

const vec3 sunDir = normalize( vec3(1.0,0.5,0.7) );


void computeCamera( in float time, out mat3 rCam, out vec3 rRo, out float rFl )
{
    vec3 ro = vec3(-0.045+0.05*sin(0.25*time),-0.04,1.3);
	vec3 ta = vec3(-0.19,-0.08,0.0);
	float fl = 2.45;
    
    vec3 w = normalize(ta-ro);
	float k = inversesqrt(1.0-w.y*w.y);
    rCam = mat3( vec3(-w.z,0.0,w.x)*k, 
                 vec3(-w.x*w.y,1.0-w.y*w.y,-w.y*w.z)*k,
                 -w);
    rRo = ro;
    rFl = fl;
}

//------------------------------------------------------

// https://iquilezles.org/articles/texture
float textureGood( sampler2D sam, in vec2 x )
{
	ivec2 p = ivec2(floor(x));
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float a = texelFetch(sam,(p+ivec2(0,0))&255,0).x;
	float b = texelFetch(sam,(p+ivec2(1,0))&255,0).x;
	float c = texelFetch(sam,(p+ivec2(0,1))&255,0).x;
	float d = texelFetch(sam,(p+ivec2(1,1))&255,0).x;
	return mix(mix( a, b,f.x), mix( c, d,f.x), f.y);
}

//------------------------------------------------------

// https://iquilezles.org/articles/functions
float almostIdentity( float x, float m, float n )
{
    if( x>m ) return x;
    float a = 2.0*n - m;
    float b = 2.0*m - 3.0*n;
    float t = x/m;
    return (a*t + b)*t*t + n;
}

// https://iquilezles.org/articles/smin
float smin( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}

// https://iquilezles.org/articles/smin
float smax( float a, float b, float k )
{
	float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
	return mix( a, b, h ) + k*h*(1.0-h);
}

//------------------------------------------------------

// https://iquilezles.org/articles/distfunctions
float sdEllipsoid( in vec3 p, in vec3 c, in vec3 r )
{
  p = p-c;
  float k0 = length(p/r);
  float k1 = length(p/(r*r));
  return k0*(k0-1.0)/k1;
}

// https://iquilezles.org/articles/distfunctions
float sdCapsule( in vec3 p, in vec3 a, in vec3 b, in float r )
{
  vec3 pa = p-a, ba = b-a;
  float h = clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);
  return length(pa-ba*h) - r;
}

// https://iquilezles.org/articles/distfunctions
vec2 sdCapsule( in vec3 p, in vec4 a, in vec4 b )
{
  vec3 pa = p-a.xyz, ba = b.xyz-a.xyz;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return vec2( length(pa-ba*h) - mix(a.w,b.w,h), h );
}

// https://iquilezles.org/articles/distfunctions
float sdSphere( in vec3 p, in vec3 c, in float r )
{
  return length(p-c)-r;
}

float sdEllipsoidXY2Z( in vec3 p, in vec3 r )
{
  vec3 d = p/r;
  float h = pow(d.x*d.x + abs(d.y*d.y*d.y) + d.z*d.z, 1.0/3.0); 
  return (h-1.0)*min(r.x,min(r.y,r.z));
}

// https://iquilezles.org/articles/distfunctions
float sdCappedCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

// https://iquilezles.org/articles/distfunctions
float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

// https://iquilezles.org/articles/distfunctions
float sdCone( in vec3 p, in vec2 c )
{
  vec2 q = vec2( length(p.xz), p.y );

  vec2 a = q - c*clamp( (q.x*c.x+q.y*c.y)/dot(c,c), 0.0, 1.0 );
  vec2 b = q - c*vec2( clamp( q.x/c.x, 0.0, 1.0 ), 1.0 );
  
  float s = -sign( c.y );
  vec2 d = min( vec2( dot( a, a ), s*(q.x*c.y-q.y*c.x) ),
			    vec2( dot( b, b ), s*(q.y-c.y)  ));
  return -sqrt(d.x)*sign(d.y);
}

// http://research.microsoft.com/en-us/um/people/hoppe/ravg.pdf
float det( vec2 a, vec2 b ) { return a.x*b.y-b.x*a.y; }
vec3 getClosest( vec2 b0, vec2 b1, vec2 b2 ) 
{
  float a =     det(b0,b2);
  float b = 2.0*det(b1,b0);
  float d = 2.0*det(b2,b1);
  float f = b*d - a*a;
  vec2 d21 = b2-b1;
  vec2 d10 = b1-b0;
  vec2 d20 = b2-b0;
  vec2 gf = 2.0*(b*d21+d*d10+a*d20); gf = vec2(gf.y,-gf.x);
  vec2 pp = -f*gf/dot(gf,gf);
  vec2 d0p = b0-pp;
  float ap = det(d0p,d20);
  float bp = 2.0*det(d10,d0p);
  float t = clamp( (ap+bp)/(2.0*a+b+d), 0.0 ,1.0 );
  return vec3( mix(mix(b0,b1,t), mix(b1,b2,t),t), t );
}

// https://iquilezles.org/articles/distfunctions
vec4 sdBezier2( vec3 a, vec3 b, vec3 c, vec3 p, out vec3 resP )
{
  vec3 w = normalize( cross( c-b, a-b ) );
  vec3 u = normalize( c-b );
  vec3 v =          ( cross( w, u ) );

  vec2 m = vec2( dot(a-b,u), dot(a-b,v) );
  vec2 n = vec2( dot(c-b,u), dot(c-b,v) );
  vec3 q = vec3( dot(p-b,u), dot(p-b,v), dot(p-b,w) );

  vec3 cp = getClosest( m-q.xy, -q.xy, n-q.xy );

  resP = mix( mix(a,b,cp.z), mix(b,c,cp.z), cp.z );

  return vec4( sqrt(dot(cp.xy,cp.xy)+q.z*q.z), cp.z, length(cp.xy), q.z );
}

vec4 sdBezier( vec3 a, vec3 b, vec3 c, vec3 p )
{
  vec3 kk;
  return sdBezier2(a,b,c,p,kk);
}

// trick by klems
#define ZERO (min(iFrame,0))
