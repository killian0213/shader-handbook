// Common (common) — Piranha Plant by PixelPhil
// https://www.shadertoy.com/view/3tKGDW

#define pi 3.14159265359
#define pi2 (pi * 2.0)
#define halfPi (pi * 0.5)

mat4 scaleMatrix( in vec3 sc ) {
	return mat4(sc.x, 0,	0,	0,
			 	0, 	 sc.y,	0,	0,
				0, 	 0,	 sc.z,	0,
				0, 	 0,  0,	1);
}

mat4 rotationX( in float angle ) {
    
    float c = cos(angle);
    float s = sin(angle);
    
	return mat4(1.0, 0,	 0,	0,
			 	0, 	 c,	-s,	0,
				0, 	 s,	 c,	0,
				0, 	 0,  0,	1);
}

mat4 rotationY( in float angle ) {
    
    float c = cos(angle);
    float s = sin(angle);
    
	return mat4( c, 0,	 s,	0,
			 	 0,	1.0, 0,	0,
				-s,	0,	 c,	0,
				 0, 0,	 0,	1);
}

mat4 rotationZ( in float angle ) {
    float c = cos(angle);
    float s = sin(angle);
    
	return mat4(c, -s,	0,	0,
			 	s,	c,	0,	0,
				0,	0,	1,	0,
				0,	0,	0,	1);
}

mat4 translate( in vec3 p) {

	return mat4(1,  0,	0,	0,
			 	0,	1,	0,	0,
				0,	0,	1,	0,
				p.x, p.y, p.z, 1);
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
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
}

// https://iquilezles.org/articles/distfunctions
float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float sdSphere(vec3 pos, vec3 center, float radius)
{
    return length(pos - center) - radius;
}


// https://iquilezles.org/articles/distfunctions
float sdRoundedCylinder( vec3 p, float ra, float rb, float h )
{
  vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}


// https://iquilezles.org/articles/distfunctions
float sdRoundCone( vec3 p, float r1, float r2, float h )
{
  vec2 q = vec2( length(p.xz), p.y );
    
  float b = (r1-r2)/h;
  float a = sqrt(1.0-b*b);
  float k = dot(q,vec2(-b,a));
    
  if( k < 0.0 ) return length(q) - r1;
  if( k > a*h ) return length(q-vec2(0.0,h)) - r2;
        
  return dot(q, vec2(a,b) ) - r1;
}

float sdCappedTorus(in vec3 p, in vec2 sc, in float ra, in float rb)
{
  p.x = abs(p.x);
    
  float edge = dot(p.xy,sc);
  float k = (sc.y*p.x>sc.x*p.y) ? edge : length(p.xy);
  float ratio = max(0.5, 1.0 - edge * edge * 0.055);
  return (sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb * ratio) * ratio;
}

float dot2( vec2 v ) { return dot(v,v); }


vec2 combineMin(vec2 a, vec2 b)
{
    return (a.x < b.x)? a : b;
}

vec2 combineMax(vec2 a, vec2 b)
{
    return (a.x > b.x)? a : b;
}

// returns distance in .x and UVW parametrization in .yzw
float sdJoint3DSphere( in vec3 p, in float l, in float a, in float w)
{
  if( abs(a)<0.001 )
  {
      return length(p-vec3(0,clamp(p.y,0.0,l),0))-w;
  }
    
  vec2  sc = vec2(sin(a),cos(a));
  float ra = 0.5 * l / a;
  p.x -= ra;
  vec2 q = p.xy - 2.0*sc*max(0.0,dot(sc,p.xy));
  float u = abs(ra)-length(q);
  float d2 = (q.y<0.0) ? dot2( q + vec2(ra,0.0) ) : u*u;

  return sqrt(d2+p.z*p.z)-w;
}

// A matrix to the tip of a sdJoint3DSphere
// Could probably use some optimisations
mat4 joint3DMatrix(in float l, in float a)
{
  if( abs(a)<0.001 )
  {
      return translate(vec3(0, -l, 0));
  }
    
  float ra = 0.5 * l / a;
  float ara = abs(ra);
  return  rotationZ(-a * 2.0) * translate(vec3(-ra + cos(2.0 * a) * ra, -sin(2.0 * a) * ra, 0.0));
}



// https://iquilezles.org/articles/distfunctions
float sdEllipsoid( in vec3 p, in vec3 r ) // approximated
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}


// Some hash function 2->1
float N2(vec2 p)
{	// Dave Hoskins - https://www.shadertoy.com/view/4djSRW
    p = mod(p, vec2(1456.2346));
	vec3 p3  = fract(vec3(p.xyx) * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// A 2d Noise
float Noise2(vec2 uv)
{
    vec2 corner = floor(uv);
	float c00 = N2(corner + vec2(0.0, 0.0));
	float c01 = N2(corner + vec2(0.0, 1.0));
	float c11 = N2(corner + vec2(1.0, 1.0));
	float c10 = N2(corner + vec2(1.0, 0.0));
    
    vec2 diff = fract(uv);
    
    diff = diff * diff * (vec2(3) - vec2(2) * diff);
    //diff = smoothstep(vec2(0), vec2(1), diff);
    
    return mix(mix(c00, c10, diff.x), mix(c01, c11, diff.x), diff.y);
}

// 1d Noise, y is seed
float Noise1(float x, float seed)
{
    vec2 uv = vec2(x, seed);
    vec2 corner = floor(uv);
	float c00 = N2(corner + vec2(0.0, 0.0));
	float c10 = N2(corner + vec2(1.0, 0.0));
    
    float diff = fract(uv.x);
    
    diff = diff * diff * (3.0 - 2.0 * diff);
    
    return mix(c00, c10, diff) - 0.5;
}

