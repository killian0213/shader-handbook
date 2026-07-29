// Common (common) — Space curvature by iapafoto
// https://www.shadertoy.com/view/tdyBDh


float hash13( const in vec3 p ) {
	float h = dot(p,vec3(127.1,311.7,758.5453123));	
    return fract(sin(h)*43758.5453123);
}


// [iq] https://www.shadertoy.com/view/llGSzw
vec3 hash3( uint n ) 
{
    // integer hash copied from Hugo Elias
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    uvec3 k = n * uvec3(n,n*16807U,n*48271U);
    return vec3( k & uvec3(0x7fffffffU))/float(0x7fffffff);
}

float hash1( uint n ) 
{
    // integer hash copied from Hugo Elias
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    return float( n & uvec3(0x7fffffffU))/float(0x7fffffff);
}


// --------------------------------------------------------
// [iq] https://iquilezles.org/articles/distfunctions
// --------------------------------------------------------

float opExtrussion( in vec3 p, in float sdf, in float h) {
    vec2 w = vec2(sdf, abs(p.z) - h);
  	return min(max(w.x,w.y),0.) + length(max(w,0.));
}

float sdCircle( in vec2 p, in vec2 w) {
    float d = length(p)- w.x;
    return max(d, -w.y-d);
}

float sdRoundedX( in vec2 p, in float w, in float r ) {
    p = abs(p);
    return length(p-min(p.x+p.y,w)*0.5) - r;
}

float sdVerticalCapsule( vec3 p, float h, float r ) {
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}

float sdBox( in vec2 p, in vec2 b ) {
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sdBox2( in vec2 p, in vec2 b ) {
    float d = sdBox(p, vec2(.8*b.x))-.01;
    return max(d, -b.y-d);
}

float sdBox3( vec3 p, vec3 b ) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

