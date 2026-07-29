// Common (common) — The Great Gatsby Fractal by Yusef28
// https://www.shadertoy.com/view/lXXSz7

#define PI 3.1415926
#define addH t = t.x < h.x ? t : h;
#define S smoothstep
float smin( float a, float b, float k )
{
	float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
	return mix( b, a, h ) - k*h*(1.0-h);
}
float smax(float a, float b, float k)
{
    return smin(a, b, -k);
}
float rnd(vec2 p){
    vec2 seed = vec2(13.234, 72.1849);
    return fract(sin(dot(p,seed))*43251.1234);    
}
//  1 out, 1 in...
float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}
float rb(vec3 p, vec3 s, float r) {
    p = abs(p)-s;
	return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.) - r;
}
float rbEdge(vec3 p, vec3 s, float r, float start, float end) {
    vec2 xzEdge = abs(p.xz)/s.xz;
    s.y -= S(start,end,xzEdge.x)*S(start,end,xzEdge.y)*s.y;
    p = abs(p)-s;
	return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.) - r;
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
float cc( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - 0.03;
}

float ccEdge( vec3 p, float h, float r )
{
  float rEdge = r-smoothstep(0.9,0.8,abs(p.y)/h)*0.1;
  
 
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(rEdge,h);
  float f = min(max(d.x,d.y),0.0) + length(max(d,0.0));
  
  return f-0.01;
  
}

mat2 rot(float a){
     float c = cos(a),s = sin(a);
     return mat2(c, -s, s, c);
}
        