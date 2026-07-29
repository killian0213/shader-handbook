// Common (common) — Leopard Fur by BigWIngs
// https://www.shadertoy.com/view/4dcBRB

#define S(a, b, t) smoothstep(a, b, t)
#define sat(x) clamp(x, 0., 1.)
#define PI 3.14159265
#define R3 1.732051

// Returns hexagonal coordinates. 
// XY = polar uv coords,  ZW = hex id 
vec4 HexCoords(vec2 uv) {
    vec2 s = vec2(1, R3);
    vec2 h = .5*s;

    vec2 gv = s*uv;
    
    vec2 a = mod(gv, s)-h;
    vec2 b = mod(gv+h, s)-h;
    
    vec2 ab = dot(a,a)<dot(b,b) ? a : b;
    vec2 st = vec2(atan(ab.x, ab.y), length(ab));
    vec2 id = gv-ab;
    
    return vec4(st, id);
}

float GetT(vec2 p, vec2 a, vec2 b) {
	vec2 ba = b-a;
    vec2 pa = p-a;
    
    float t = dot(ba, pa)/dot(ba, ba);
    
    return t;
}

vec2 ClosestPointSeg2D(vec2 p, vec2 a, vec2 b) {
	vec2 ba = b-a;
    vec2 pa = p-a;
    
    float t = dot(ba, pa)/dot(ba, ba);
    t = sat(t);
    
    return a + ba*t;
}

float DistSeg2d(vec2 uv, vec2 a, vec2 b) {
	return length(uv-ClosestPointSeg2D(uv, a, b));
}

float N(float p) {
	return fract(sin(p*6453.2)*3425.2);
}



vec3 N23(vec2 p) {
    return fract(sin(vec3(p.x*6454., p.y*746., (p.x+p.y)*64.2))*vec3(876.4, 997.4, 654.2));
}

float N21(vec2 p) {
    p = fract(p*vec2(123.45,234.56));
    p += dot(p, p+56.57);
    return fract(p.x*p.y);
    
    //p = p*1342.3+vec2(345.45,2345.3);
	//return fract(sin(p.x+p.y*1534.2)*7363.2);
}

vec2 N22(vec2 p) {
    float n = N21(p);
    return vec2(n, N21(p+n));
}

vec2 N12(float p) {
    float x = N(p);
	return vec2(x, N(p*100.*x));
}



float N2(vec2 p)
{	// Dave Hoskins - https://www.shadertoy.com/view/4djSRW
	vec3 p3  = fract(vec3(p.xyx) * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}
float N2(float x, float y) { return N2(vec2(x, y)); }

float SmoothNoise2(vec2 uv) {
    // noise function I came up with
    // ... doesn't look exactly the same as what i've seen elswhere
    // .. seems to work though :)
    vec2 id = floor(uv);
    vec2 m = fract(uv);
    m = 3.*m*m - 2.*m*m*m;
    
    float top = mix(N2(id.x, id.y), N2(id.x+1., id.y), m.x);
    float bot = mix(N2(id.x, id.y+1.), N2(id.x+1., id.y+1.), m.x);
    
    return mix(top, bot, m.y);
}

float Hash(in vec2 p, in float scale) {
	// This is tiling part, adjusts with the scale...
	p = mod(p, scale);
	return fract(sin(dot(p, vec2(27.16898, 38.90563))) * 5151.5473453);
}

//----------------------------------------------------------------------------------------
float SmoothNoise(in vec2 p, in float scale ){
	vec2 f;
	
	p *= scale;

	
	f = fract(p);		// Separate integer from fractional
    p = floor(p);
	
    f = f*f*(3.0-2.0*f);	// Cosine interpolation approximation
	
    float res = mix(mix(Hash(p, 				 scale),
						Hash(p + vec2(1.0, 0.0), scale), f.x),
					mix(Hash(p + vec2(0.0, 1.0), scale),
						Hash(p + vec2(1.0, 1.0), scale), f.x), f.y);
    return res;
}

vec2 Rot2d(vec2 p, float a) {
	float s = sin(a);
    float c = cos(a);
    return vec2(p.x*s-p.y*c, p.x*c+p.y*s);
}