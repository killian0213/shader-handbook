// Common (common) — Wait.. what? CyberTruck! by BigWIngs
// https://www.shadertoy.com/view/wdGXzK

float sabs(float x,float k) {
    float a = (.5/k)*x*x+k*.5;
    float b = abs(x);
    return b<k ? a : b;
}
vec2 sabs(vec2 x,float k) { return vec2(sabs(x.x, k), sabs(x.y,k)); }
vec3 sabs(vec3 x,float k) { return vec3(sabs(x.x, k), sabs(x.y,k), sabs(x.z,k)); }

mat2 Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.0-h);
}

// From http://mercury.sexy/hg_sdf
vec2 pModPolar(inout vec2 p, float repetitions, float fix) {
	float angle = 6.2832/repetitions;
	float a = atan(p.y, p.x) + angle/2.;
	float r = length(p);
	float c = floor(a/angle);
	a = mod(a,angle) - (angle/2.)*fix;
	p = vec2(cos(a), sin(a))*r;

	return p;
}

float sdCylinder(vec3 p, vec3 a, vec3 b, float r) {
	vec3 ab = b-a;
    vec3 ap = p-a;
    
    float t = dot(ab, ap) / dot(ab, ab);
    //t = clamp(t, 0., 1.);
    
    vec3 c = a + t*ab;
    
    float x = length(p-c)-r;
    float y = (abs(t-.5)-.5)*length(ab);
    float e = length(max(vec2(x, y), 0.));
    float i = min(max(x, y), 0.);
    
    return e+i;
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
	return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

float LineDist(vec2 a, vec2 b, vec2 p) {
	vec2 ab=b-a, ap=p-a;
    float h = dot(ab, ap)/dot(ab, ab);
    float d = length(ap - ab * h);
    float s = sign(ab.x * ap.y - ab.y * ap.x);
    return d*s;
}

float LineDist(float ax,float ay, float bx,float by, vec2 p) {
    return LineDist(vec2(ax, ay), vec2(bx, by), p);
}
float map01(float a, float b, float t) {
	return clamp((t-a)/(b-a), 0., 1.);
}
float map(float t, float a, float b, float c, float d) {
	return (d-c)*clamp((t-a)/(b-a), 0., 1.)+c;
}

vec2 RayLineDist(vec3 ro, vec3 rd, vec3 a, vec3 b) {
    
    b -= a;
    vec3 rdb = cross(rd,b);
    vec3 rop2 = a-ro;
    
	float t1 = dot( cross(rop2, b), rdb ); 
    float t2 = dot( cross(rop2, rd), rdb );
    
    return vec2(t1, t2) / dot(rdb, rdb);
}

float RayPlane(vec3 ro, vec3 rd, vec3 n, float d) {
	return (d-dot(ro, n)) / dot(rd, n);
}

float N21(vec2 p) {
    p = fract(p*vec2(123.34,456.23));
    p += dot(p, p+34.23);
    return fract(p.x*p.y);
    //return fract(sin(p.x*100.+p.y*6574.)*5647.);
}

float SmoothNoise(vec2 uv) {
    vec2 lv = fract(uv);
    vec2 id = floor(uv);
    
    lv = lv*lv*(3.-2.*lv);
    
    float bl = N21(id);
    float br = N21(id+vec2(1,0));
    float b = mix(bl, br, lv.x);
    
    float tl = N21(id+vec2(0,1));
    float tr = N21(id+vec2(1,1));
    float t = mix(tl, tr, lv.x);
    
    return mix(b, t, lv.y);
}

float SmoothNoise2(vec2 uv) {
    float c = SmoothNoise(uv*4.);
    
    // don't make octaves exactly twice as small
    // this way the pattern will look more random and repeat less
    c += SmoothNoise(uv*8.2)*.5;
    c += SmoothNoise(uv*16.7)*.25;
    c += SmoothNoise(uv*32.4)*.125;
    c += SmoothNoise(uv*64.5)*.0625;
    
    c /= 2.;
    
    return c;
}

float Tonemap_ACES(float x) {
    // Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}

vec3 Tonemap_ACES(vec3 x) {
    return vec3(Tonemap_ACES(x.r),Tonemap_ACES(x.g),Tonemap_ACES(x.b));
}






