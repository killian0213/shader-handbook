// Common (common) — A cup of coffee (Progressive) by PixelPhil
// https://www.shadertoy.com/view/3ltXR8


#define pi 3.14159265359
#define pi2 (pi * 2.0)
#define halfPi (pi * 0.5)


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

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}


float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

vec2 combineMin(vec2 a, vec2 b)
{
    return (a.x < b.x)? a : b;
}

vec2 combineMax(vec2 a, vec2 b)
{
    return (a.x > b.x)? a : b;
}


// Some hash function 2->1
float N2(vec2 p)
{	// Dave Hoskins - https://www.shadertoy.com/view/4djSRW
    p = mod(p, vec2(1456.2346));
	vec3 p3  = fract(vec3(p.xyx) * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 hash3( vec2 p )
{
    vec3 q = vec3( dot(p,vec2(127.1,311.7)), 
				   dot(p,vec2(269.5,183.3)), 
				   dot(p,vec2(419.2,371.9)) );
	return fract(sin(q)*43758.5453);
}

// https://iquilezles.org/articles/voronoise
float VoroNoise( in vec2 x, float u, float v )
{
    vec2 p = floor(x);
    vec2 f = fract(x);

    float k = 1.0 + 63.0*pow(1.0-v,4.0);
    float va = 0.0;
    float wt = 0.0;
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        vec2  g = vec2( float(i), float(j) );
        vec3  o = hash3( p + g )*vec3(u,u,1.0);
        vec2  r = g - f + o.xy;
        float d = dot(r,r);
        float w = pow( 1.0-smoothstep(0.0,1.414,sqrt(d)), k );
        va += w*o.z;
        wt += w;
    }

    return va/wt;
}

float Voronoi( in vec2 x, float u)
{
    vec2 p = floor(x);
    vec2 f = fract(x);

    float va = 1000.0;
    
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        vec2  g = vec2( float(i), float(j) );
        vec3  o = hash3( p + g )*vec3(u,u,1.0);
        vec2  r = g - f + o.xy;
        float d = dot(r,r);
        float w = sqrt(d);
        va = min(va, w);
    }

    return va;
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


