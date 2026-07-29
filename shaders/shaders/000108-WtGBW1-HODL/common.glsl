// Common (common) — HODL by BigWIngs
// https://www.shadertoy.com/view/WtGBW1

float remap01(float a, float b, float t) {
	return (t-a)/(b-a);
}

float remap(float a, float b, float c, float d, float t) {
    return ((t-a)/(b-a))*(d-c)+c;
}

vec2 local(vec2 uv, float x1, float y1, float x2, float y2) {
	return vec2(uv.x-x1, uv.y-y1)/vec2(x2-x1, y2-y1);
}
vec2 local(vec2 uv, vec4 p) { return local(uv, p.x, p.y, p.z, p.w);}

bool within(vec2 uv, float x1, float y1, float x2, float y2) {
	return uv.x>x1&&uv.x<x2&&uv.y>y1&&uv.y<y2;
}
bool within(vec2 uv, vec4 p) {
    return within(uv, p.x, p.y, p.z, p.w);
}
float Line(in vec2 p, in vec2 a, in vec2 b) {
    vec2 
        pa = p - a, 
        ba = b - a;
        
	float h = clamp(dot(pa,ba) / dot(ba,ba), 0., 1.);
	
    return length(pa - ba * h);
}

float N21(vec2 p) {
	vec3 a = fract(vec3(p.xyx) * vec3(213.897, 653.453, 253.098));
    a += dot(a, a.yzx + 79.76);
    return fract((a.x + a.y) * a.z);
}

vec2 RaySphere(vec3 ro, vec3 rd, vec3 s, float r) {
    float t = dot(s-ro, rd);
    vec3 p = ro+rd*t;
    float y = length(s-p);
    if(y<r) {
        float x = sqrt(r*r-y*y);
        return vec2(t-x, t+x);
    }
    return vec2(-1, -1);
}

vec4 GetProgress(float T, vec2 M) {
    T += M.x/.03; 
    float 
        t = fract(T*.03),
        y = t*(1.-t)*4.;
    return vec4(t, 1.-abs(t-.5)*2., y, y*75.);
}

vec3 GetBgCol(float T) {
    return vec3(1., .7, .2).brg;
}

float WaveletNoise(vec2 p, float z, float k) {
    // https://www.shadertoy.com/view/wsBfzK
    float d=0.,s=1.,m=0., a;
    for(float i=0.; i<4.; i++) {
        vec2 q = p*s, g=fract(floor(q)*vec2(123.34,233.53));
    	g += dot(g, g+23.234);
		a = fract(g.x*g.y)*1e3;// +z*(mod(g.x+g.y, 2.)-1.); // add vorticity
        q = (fract(q)-.5)*mat2(cos(a),-sin(a),sin(a),cos(a));
        d += sin(q.x*10.+z)*smoothstep(.25, .0, dot(q,q))/s;
        p = p*mat2(.54,-.84, .84, .54)+i;
        m += 1./s;
        s *= k; 
    }
    return d/m;
}

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

float Min(float a, float b, float c) {
  return min(a, min(b, c));
}