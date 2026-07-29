// Buffer A (buffer) — 3D Monte Carlo Geometry test by rreusser
// https://www.shadertoy.com/view/wdffWj

#define MARCH 1
#define MARCH_ITERATIONS 10
#define ANIMATE 0
#define DEBUG_SDF 0

const vec3 color1 = vec3(1.0, 1.0, 0.28);
const vec3 color2 = vec3(0.03, 0.02, 0.2);

// The boundary function
float f (vec3 pos) {
    return fract(pos.x * 3.66 + 0.25) > 0.5 ? 1.0 : 0.0;
}

vec3 colorscale (float x) {
    return mix(color1, color2, x);
}

// This function adds a bit more red instead of direct interpolation
vec3 hsvColorscale (float x) {
    vec3 c1 = rgb2hsv(1.0 - color1);
    vec3 c2 = rgb2hsv(1.0 - color2);
    return 1.0 - hsv2rgb(mix(c1, c2, x));
}

// This function returns the negative distance, which we then negate after the fact.
// We do this because the important difference is that the `map` function returns the
// exterior difference *without the cutting plane*.
vec2 interiorMap( in vec3 pos ) {
    float r1 = 0.4;
    float r2 = 0.19;
    float k = 16.0; 
    return vec2(-smin(
        sdTorus((pos - vec3( r1 + r2 * 0.8, r1 + r2, 0.0)).yzx, vec2(r1, r2)),
        sdTorus(pos - vec3( -r1 - r2 * 0.8, r1 + r2, 0.0), vec2(r1, r2)),
    k), f(pos));
}

vec2 map( in vec3 pos, in float cuttingPlane ) {
	vec2 res = vec2(-interiorMap(pos).x, 2.0);
#if MARCH
    res = opD(res, vec2(-sdPlane(pos.xzx - cuttingPlane), 3.0));
#endif
    return res;
}

// A bounding box, I think.
// https://iquilezles.org/articles/boxfunctions
vec2 iBox( in vec3 ro, in vec3 rd, in vec3 rad ) {
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*rad;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
	return vec2( max( max( t1.x, t1.y ), t1.z ),
	             min( min( t2.x, t2.y ), t2.z ) );
}

// This affects the shadowing, I think.
const float maxHei = 2.2;

// https://iquilezles.org/articles/rmshadows
float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax, in float cuttingPlane) {
    // bounding volume
    float tp = (maxHei - ro.y) / rd.y;
    if (tp > 0.0) tmax = min(tmax, tp);

    float res = 1.0;
    float t = mint;
    for (int i=0; i < 16; i++) {
		float h = map(ro + rd * t, cuttingPlane).x;
        float s = clamp(4.0 * h / t, 0.0, 1.0);
        res = min(res, s * s * (3.0 - 2.0 * s));
        t += clamp( h, 0.02, 0.10 );
        if (res < 0.005 || t > tmax) break;
    }
    return clamp( res, 0.0, 1.0 );
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos, in float cuttingPlane ) {
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for (int i = 0; i < 4; i++) {
        vec3 e = 0.5773 * (2.0 * vec3((((i + 3) >> 1) & 1), ((i >> 1) & 1), (i & 1)) - 1.0);
        n += e * map(pos + 0.0005 * e, cuttingPlane).x;
    }
    return normalize(n);
}

float calcAO(in vec3 pos, in vec3 nor, in float cuttingPlane) {
	float occ = 0.0;
    float sca = 1.0;
    for (int i = 0; i < 5; i++) {
        float hr = 0.01 + 0.12 * float(i) / 4.0;
        vec3 aopos = nor * hr + pos;
        float dd = map( aopos, cuttingPlane).x;
        occ += -(dd - hr) * sca;
        sca *= 0.95;
    }
    return clamp(1.0 - 3.0 * occ, 0.0, 1.0) * (0.5 + 0.5 * nor.y);
}

vec2 castRay(in vec3 ro, in vec3 rd, in float cuttingPlane) {
    vec2 res = vec2(-1.0,-1.0);

    float tmin = 1.0;
    float tmax = 20.0;

    // raytrace floor plane
    float tp1 = (0.0 - ro.y) / rd.y;
    if( tp1>0.0 ) {
        tmax = min( tmax, tp1 );
        res = vec2( tp1, 1.0 );
    }
    
    // raymarch primitives   
    vec2 tb = iBox(ro - vec3(0,0.6,0), rd, vec3(1.2, 0.6, 0.6));
    if (tb.x < tb.y && tb.y > 0.0 && tb.x < tmax) {
        tmin = max(tb.x,tmin);
        tmax = min(tb.y,tmax);

        float t = tmin;
        for (int i = 0; i < 80 && t < tmax; i++) {
            vec2 h = map( ro+rd*t, cuttingPlane );
            if (abs(h.x) < (0.0001 * t)) { 
                res = vec2(t,h.y); 
                break;
            }
            t += h.x;
        }
    }
    
    return res;
}

vec3 render( in vec3 ro, in vec3 rd, in vec3 rdx, in vec3 rdy, in float cuttingPlane, out bool isInterior, out vec3 pos ) { 
    vec3 col = vec3(0.9);
    vec2 res = castRay(ro,rd, cuttingPlane);
    float t = res.x;
	float m = res.y;
    if (m > 0.5) {
        pos = ro + t*rd;
        vec3 nor = (m < 1.5) ? vec3(0, 1, 0) : calcNormal(pos, cuttingPlane);
        
        // material
        if (m > 2.5) {
            isInterior = true;
        } else if (m > 1.5) {
            col = colorscale(f(pos));
        } else {
            isInterior = false;
        }
        
        // lighting
        float occ = 0.5 + 0.5 * calcAO(pos, nor, cuttingPlane);
		vec3  lig = normalize(vec3(-0.2, 0.4, -0.3));
        vec3  hal = normalize(lig - rd);
		float amb = sqrt(clamp(0.5 + 0.5 * nor.y, 0.0, 1.0));
        float dif = clamp(dot(nor, lig), 0.0, 1.0);
        
        dif *= 0.2 + 0.8 * calcSoftshadow(pos, lig, 0.2, 2.0, cuttingPlane);

		float spe = pow(clamp(dot(nor, hal), 0.0, 1.0), 16.0)*
                    dif * (0.04 + 0.96 * pow(clamp(1.0 + dot(hal, rd), 0.0, 1.0), 5.0));

		vec3 lin = vec3(0.0);
        lin += 0.25 * dif;
        lin += 1.0 * amb * occ;
		col = col * lin;
		col += 6.0 * spe;
    }

	return col;
}

// --------------------------------------
// oldschool rand() from Visual Studio
// --------------------------------------
int  seed = 1;
void srand(int s ) {
    seed = s;
}
int rand(void) {
    seed = seed * 0x343fd + 0x269ec3;
    return (seed >> 16) & 32767;
}
// --------------------------------------

// --------------------------------------
// hash to initialize the random sequence (copied from Hugo Elias)
// --------------------------------------
int hash( int n ) {
	n = (n << 13) ^ n;
    return n * (n * n * 15731 + 789221) + 1376312589;
}

// --------------------------------------

vec3 randomOnSphere( void ) {
    float theta = (6.283185 / 32767.0) * float(rand());
    float u = (2.0 / 32767.0) * float(rand()) - 1.0;
    return vec3(sqrt(max(0.0, 1.0 - u * u)) * vec2(cos(theta), sin(theta)), u);
}
 
// WoS! Walk-on-spheres. This the heart of the whole thing. Remarkably concise.
float march (in vec3 p) {
    vec2 h = vec2(0.0);
	for (int i = 0; i < 32; i++) {
        h = interiorMap(p);
        if (h.x < 0.001) break;
        p = p + h.x * randomOnSphere();
    }
    return h.y;
}
   
void mainImage (out vec4 fragColor, in vec2 fragCoord) {   

#if ANIMATE
    float cuttingPlane = 0.6 * cos(iTime);
#else
    float cuttingPlane = iMouse.x < 1.0 ? 0.0 : mix(0.7, -0.7, iMouse.x / iResolution.x);
#endif
    
	// init randoms
    ivec2 q = ivec2(fragCoord);
    srand(hash(q.x + hash(q.y + hash(iFrame))));
    
    // camera	
    vec3 ta = vec3(0.0, 0.5, 0.0 );
    vec3 ro = vec3(1.7, 2.4, -2.8);
    
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );

    // pixel coordinates
    vec2 o = vec2(float(rand()), float(rand())) / 32767.0 - 0.5;
    vec2 p = (2.0*(fragCoord+o)-iResolution.xy)/iResolution.y;

    // ray direction
    vec3 rd = ca * normalize(vec3(p, 4.5));

    // ray differentials
    vec2 px = (2.0 * (fragCoord + vec2(1.0, 0.0)) - iResolution.xy) / iResolution.y;
    vec2 py = (2.0 * (fragCoord + vec2(0.0, 1.0)) - iResolution.xy) / iResolution.y;
    vec3 rdx = ca * normalize(vec3(px, 2.5));
    vec3 rdy = ca * normalize(vec3(py, 2.5));

    // render
    bool isInterior = false;
    vec3 pos;
    vec3 col = render(ro, rd, rdx, rdy, cuttingPlane, isInterior, pos);
    
    if (isInterior) {
#if DEBUG_SDF
        col = hsvColorscale(fract(interiorMap(pos).x * 30.0));
#else
        float sum = 0.0;
        for (int i = 0; i < MARCH_ITERATIONS; i++) {
            sum += march(pos);
        }
        sum /= float(MARCH_ITERATIONS);
        col = hsvColorscale(sum);
#endif
    }
 
#if ANIMATE
    bool redraw = true;
#else
    bool redraw = iMouse.z > 0.0;
#endif
    
    vec4 data = texelFetch(iChannel0, ivec2(fragCoord), 0);
    if (redraw) {
      fragColor = vec4(col, 1.0);
    } else {
      fragColor = data + vec4(col, 1.0);
    }
}