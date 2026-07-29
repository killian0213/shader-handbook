// Image (image) — RetroVision (Revision 2023) by dean_the_coder
// https://www.shadertoy.com/view/DdVSzR

// 'RetroVision' dean_the_coder (Twitter: @deanthecoder)
// https://www.shadertoy.com/view/DdVSzR
// https://demozoo.org/graphics/322475/
//
// Processed by 'GLSL Shader Shrinker'
// (https://github.com/deanthecoder/GLSLShaderShrinker)
//
// Based on my entry for the 4Kb Executable Graphics compo at Revision 2023.
//
// Thanks to Evvvvil, Flopine, Nusan, BigWings, Iq, Shane,
// totetmatt, Blackle, Dave Hoskins, byt3_m3chanic, tater,
// and a bunch of others for sharing their time and knowledge!

// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define MIN_DIST	.0002
#define START_DIST	1.0
#define MAX_STEPS	100.
#define MAX_RDIST	5.
#define MAX_RSTEPS	32.
#define SHADOW_STEPS	20.0

#define LIGHT_RGB	vec3(2, 1.32, 1.16)
#define R	iResolution
#define Z0	min(iTime, 0.)
#define I0	min(iFrame, 0)
#define sat(x)	clamp(x, 0., 1.)
#define S(a, b, c)	smoothstep(a, b, c)
#define S01(a)	S(0.0, 1.0, a)

bool hitGlass;
struct Hit {
	float d;
	int id;
	vec3 p;
};

void U(inout Hit h, float d, int id, vec3 p) { if (d < h.d) h = Hit(d, id, p); }

float min2(vec2 v) { return min(v.x, v.y); }

float max2(vec2 v) { return max(v.x, v.y); }

float max3(vec3 v) { return max(v.x, max(v.y, v.z)); }

float dot3(vec3 v) { return dot(v, v); }

float sum2(vec2 v) { return dot(v, vec2(1)); }

///////////////////////////////////////////////////////////////////////////////
float h31(vec3 p3) {
	p3 = fract(p3 * .1031);
	p3 += dot(p3, p3.yzx + 333.3456);
	return fract(sum2(p3.xy) * p3.z);
}

float h21(vec2 p) { return h31(p.xyx); }

float n31(vec3 p) {
	// Thanks Shane - https://www.shadertoy.com/view/lstGRB
	const vec3 s = vec3(7, 157, 113);
	vec3 ip = floor(p);
	p = fract(p);
	p = p * p * (3. - 2. * p);
	vec4 h = vec4(0, s.yz, sum2(s.yz)) + dot(ip, s);
	h = mix(fract(sin(h) * 43758.545), fract(sin(h + s.x) * 43758.545), p.x);
	h.xy = mix(h.xz, h.yw, p.y);
	return mix(h.x, h.y, p.z);
}

// roughness: (0.0, 1.0], default: 0.5
// Returns unsigned noise [0.0, 1.0]
float fbm(vec3 p, int octaves, float roughness) {
	float sum = 0.0,
	      amp = 1.,
	      tot = 0.0;
	roughness = sat(roughness);
	while (octaves-- > 0) {
		sum += amp * n31(p);
		tot += amp;
		amp *= roughness;
		p *= 2.0;
	}
	return sum / tot;
}

vec3 randomPos(float seed) {
	vec4 s = vec4(seed, 0, 1, 2);
	return vec3(h21(s.xy), h21(s.xz), h21(s.xw)) * 100.0 + 100.;
}

// Returns unsigned noise [0.0, 1.0]
float fbmDistorted(vec3 p, int octaves, float roughness, float distortion) {
	p += (vec3(n31(p + randomPos(0.0)), n31(p + randomPos(1.0)), n31(p + randomPos(2.0))) * 2. - 1.) * distortion;
	return fbm(p, octaves, roughness);
}

// vec3: detail(/octaves), dimension(/inverse contrast), lacunarity
// Returns signed noise.
float musgraveFbm(vec3 p, float octaves, float dimension, float lacunarity) {
	float sum = 0.0,
	      amp = 1.0;
	float pwMul = pow(lacunarity, -dimension);
	while (octaves-- > 0.0) {
		float n = n31(p) * 2. - 1.;
		sum += n * amp;
		amp *= pwMul;
		p *= lacunarity;
	}
	return sum;
}

// Wave noise along X axis.
vec3 waveFbmX(vec3 p, float distort, int detail, float detailScale, float roughness) {
	float n = p.x * 20.0;
	n += distort != 0.0 ? distort * fbm(p * detailScale, detail, roughness) : 0.0;
	return vec3(sin(n) * 0.5 + 0.5, p.yz);
}

///////////////////////////////////////////////////////////////////////////////
// Math
// Smooth min()
float smin(float a, float b, float k) {
	float h = sat(.5 + .5 * (b - a) / k);
	return mix(b, a, h) - k * h * (1. - h);
}

float remap01(float f, float in1, float in2) { return sat((f - in1) / (in2 - in1)); }

///////////////////////////////////////////////////////////////////////////////
// Space manipulation.
mat2 rot(float a) {
	float c = cos(a),
	      s = sin(a);
	return mat2(c, s, -s, c);
}

vec3 dx(vec3 p, float e) {
	p.x += e;
	return p;
}

vec3 dy(vec3 p, float e) {
	p.y += e;
	return p;
}

vec3 dz(vec3 p, float e) {
	p.z += e;
	return p;
}

// Return abs(p.x) with offset.
vec3 ax(vec3 p, float d) { return vec3(abs(p.x) - d, p.yz); }

// Return abs(p.y) with offset.
vec3 ay(vec3 p, float d) { return vec3(p.x, abs(p.y) - d, p.z); }

// Return abs(p.z) with offset.
vec3 az(vec3 p, float d) { return vec3(p.xy, abs(p.z) - d); }

// Polar/circular repeat.
vec3 opModPolar(vec3 p, float n, float o) {
	float angle = 3.141 / n,
	      a = mod(atan(p.x, p.y) + angle + o, 2. * angle) - angle;
	p.xy = length(p.xy) * vec2(cos(a), sin(a));
	return p;
}

// Convert 2D sdf into 3D sdf.
float insulate(vec3 p, float sdf2d) {
	float dp = p.x; // distance to plane
	return sqrt(dp * dp + sdf2d * sdf2d);
}

// Bend space along the x axis.
vec3 bend(vec3 p, float k) {
	float c = cos(k * p.x);
	float s = sin(k * p.x);
	p.xy *= mat2(c, s, -s, c);
	return p;
}

///////////////////////////////////////////////////////////////////////////////
// SDFs
float box(vec3 p, vec3 b) {
	vec3 q = abs(p) - b;
	return length(max(q, 0.)) + min(max3(q), 0.);
}

float box2d(vec2 p, vec2 b) {
	vec2 q = abs(p) - b;
	return length(max(q, 0.)) + min(max2(q), 0.);
}

float cyl(vec3 p, vec2 hr) {
	vec2 d = abs(vec2(length(p.xy), p.z)) - hr;
	return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

float cap(vec3 p, float h, float r) {
	p.x -= clamp(p.x, 0., h);
	return length(p) - r;
}

float tor(vec3 p, vec2 t) {
	vec2 q = vec2(length(p.xy) - t.x, p.z);
	return length(q) - t.y;
}

float arc(vec3 p, float l, float a) {
	vec2 sc = vec2(sin(a), cos(a));
	float ra = 0.5 * l / a;
	p.x -= ra;
	vec2 q = p.xy - 2.0 * sc * max(0.0, dot(sc, p.xy));
	float u = abs(ra) - length(q);
	float d2 = (q.y < 0.0) ? dot(q + vec2(ra, 0.0), q + vec2(ra, 0.0)) : u * u;
	float s = sign(a);
	return sqrt(d2 + p.z * p.z);
}

float hex3D(vec3 p, vec2 h) {
	const vec3 k = vec3(-.8660254, .5, .57735);
	p = abs(p);
	p.zy -= 2. * min(dot(k.xy, p.zy), 0.) * k.xy;
	vec2 d = vec2(length(p.zy - vec2(clamp(p.z, -k.z * h.x, k.z * h.x), h.x)) * sign(p.y - h.x), p.x - h.y);
	return min(max2(d), 0.) + length(max(d, 0.));
}

vec3 rayDir(vec3 ro, vec2 uv) {
	vec3 f = normalize(-ro),
	     r = normalize(cross(vec3(0, 1, 0), f));
	return normalize(f + r * uv.x + cross(f, r) * uv.y);
}

///////////////////////////////////////////////////////////////////////////////
// Environment/textures/materials.
vec3 skyCol(float y) {
    return pow(vec3(max(1.0 - y * 0.5, 0.0)), vec3(6, 3, 1.5)) * vec3(1, 0.7, 0.6);
}

// Sky with clouds.
vec3 sky(vec3 rd) {
	return skyCol(rd.y);
}

float fakeEnv(vec3 n) {
	// Thanks Blackle.
	return length(sin(n * 2.5) * 0.5 + 0.5) * 0.8;
}

// Wood material. Returns rgb, depth
vec4 matWood(vec3 p) {
	float n1 = fbmDistorted(p * vec3(1, .15, .15) * 8., 8, .5, 1.12);
	n1 = mix(n1, 1., 0.2);
	float n2 = musgraveFbm(vec3(n1 * 4.6), 8., 0., 2.5);
	float n3 = mix(n2, n1, 0.85);
	vec3 q = waveFbmX(p * vec3(0.01, .15, .15), .4, 3, 3., 3.);
	float dirt = 1. - musgraveFbm(q, 15., 0.26, 2.4) * .4;
	float grain = 1. - S(0.2, 1.0, musgraveFbm(p * vec3(500, 6, 1), 2., 2., 2.5)) * 0.2;
	n3 *= dirt * grain;
	vec3 c1 = vec3(.032, .012, .004);
	vec3 c2 = vec3(.25, .11, .037);
	vec3 c3 = vec3(.52, .32, .19);
	float depth = grain * n3;
	vec3 col = mix(c1, c2, remap01(n3, 0.185, 0.565));
	col = mix(col, c3, remap01(n3, 0.565, 1.));
	return vec4(col, depth);
}

#define SKY_ID	0
#define PLANK_ID	1
#define CAM_WOOD_ID	2
#define LEATHER_ID	3
#define LENS_COLOR_BACK_ID	4
#define BELOW_ARE_REFLECTIVE	5
#define BRASS_ID	6
#define DARKER_BRASS_ID	7
#define GLASS_ID	8
#define INLAY_ID	9

float screw(vec3 p) {
	p.xy *= rot(0.6);
	return cyl(p, vec2(.02, 0.01 * S(0.001, 0.003, abs(p.x))));
}

float nutCap(vec3 p) { return min(cap(p, .02, .015), hex3D(p, vec2(.02))); }

float knob(vec3 p, float r, float w) {
	p.z = abs(p.z + w);
	float l = length(p.xy),
	      a = atan(p.y, p.x);
	float d = l - r;
	d += S(0.8, 1., sin(a * 400. * r)) * 0.002 * S(1.5, 0.5, p.z / w);
	p.z -= w;
	d = smin(d, p.z, -0.01);
	r *= 0.7;
	d = min(d, tor(p, vec2(r, r * 0.1)));
	p.z -= w * 3.;
	d = smin(min(d, l - r), p.z, -0.01);
	r *= .85;
	d = smin(d, tor(p, vec2(r, r * 0.05)), 0.01);
	return min(d, length(p) - r * 0.2);
}

float s(vec3 p) {
	p = dy(dx(p.zyx, .04), .08);
	p.xy *= rot(-0.4);
	p.y = p.x < 1.0 ? p.y : -p.y;
	p.x = abs(p.x);
	p.xy *= rot(-0.707);
	return arc(p, .18, 0.85);
}

Hit sdf(vec3 p) {
	p.y -= 0.1;

	// Planks.
	vec3 q = p + vec3(0, 1.5, 0), v3;
	q.xz *= rot(0.15);
	float f = floor(q.x);
	q.x = fract(q.x) - 0.5;
	q = bend(q, .1 * n31(p * .5));
	float d = box(q, vec3(0.485, .5, 99));
    q = p * .016;
    q.z += f;

	Hit h = Hit(d, PLANK_ID, q);

	// Camera front box.
	p.y += 0.15;
	f = .85 - step(0.0, p.y) * (1. - cos(p.z)) * 0.6;
	v3 = vec3(0.45, f, 0.64);
	d = box(p, v3 - .044) - .044;
	q = dx(p, -0.83);
	d = smin(d, -box(q, v3 - 0.06), -0.1);
	U(h, d * 0.95, CAM_WOOD_ID, p);

	// Front box top brass pattern.
	d = box2d(p.xz, vec2(.23, .5));
	d = max(d, .17 - length(az(ax(p, .24), .52).xz));
	d = abs(d) - 0.005;
	f = p.y - f - 0.01;
	d = smin(d, f, -0.01);
	f -= abs(sin(atan(p.z, p.x) * 14.)) * 0.006 * S(.07, .09, length(p.xz));
	d = min(d, box2d(p.xz, vec2(0.07, .28)) - 0.03);
	d = smin(d, f, -0.005);
	U(h, d, BRASS_ID, p);

	// Front box inlay.
	q.x += .78;
	d = box(q, v3 - 0.08) - 0.02;
	U(h, d * 0.94, INLAY_ID, p);

	// Front box nuts.
	v3 = dx(q, -.41);
	v3 = az(ay(v3, .65), .53);
	v3.yz *= rot(0.5);
	d = nutCap(v3);
	d = min(d, s(dx(v3, .017)));
	U(h, d, BRASS_ID, p);

	// Camera back box.
	q.zxy = bend(p.zxy, 0.2);
	q.x += 0.7;
	v3 = vec3(0.2405, .9, 0.6505);
	d = smin(box(q, v3) - .02, box(q, vec3(.18, .98, .46)), .025);
	d -= S(0., 1., abs(f)) * 0.001;
	U(h, d, LEATHER_ID, q);

	// Back box dials.
	q.y -= .885;
	d = box(ay(q, 0.014), vec3(0.265, -.002, .675));
	d = min(d, knob(p.xzy + vec3(.65, .38, -1.025), .1, .01));

	// Strap bolt.
	d = min(d, cyl(p + vec3(.5, -.73, 0), vec2(.04 - 0.008 * S(0., 0.02, p.z + .82), .85)));

	// Side focus wheel.
	d = min(d, knob(dz(p - vec3(.05, -.1, 0), .67), .25, .01));
	U(h, d, BRASS_ID, p);

	// Main lens barrel.
	q = dy(ax(p, 0.), 0.2);
	float l = length(q.yz);
	f = S(.0, .01, p.x - .62);
	f -= S(.06, 0., abs(p.x - .69)) * 0.2 * abs(sin(atan(q.y, q.z) * 60.));
	d = max(l - .3 + 0.01 * f, .23 - l);
	d = max(d, q.x - .75);
	U(h, d, DARKER_BRASS_ID, p);
	q.x -= .756;
	d = min(d, tor(q.zyx, vec2(.21 + 0.096 * step(.25, l), 0)));
	U(h, d, BRASS_ID, p);

	// Lens inside.
	d = max(l - .2, .15 - l);
	d = max(d, q.x + 0.16);
	U(h, d, DARKER_BRASS_ID, p);
	d = min(d, q.x + .2);
	d = max(d, l - .25);
	U(h, d, LENS_COLOR_BACK_ID, p);

	// Lens screws.
	d = screw(dx(opModPolar(q.zyx, 6., .3), -0.255)) + 0.012;
	U(h, d, BRASS_ID, p);

	// Lens.
	if (!hitGlass) {
		q = dx(q, 1.04);
		d = max(length(q) - 1., l - .21);
		U(h, d, GLASS_ID, q);
	}

	// Main lens brass surround.
	q = dy(dx(p, -0.466), 0.2);
	v3 = q;
	l = length(q.yz);
	d = l - .44;
	float a = atan(q.y, q.z);
	f = tor(q.zyx, vec2(.3, 0.03 - 0.0005 * abs(sin(a * 50.)))); // Weld ring.
	q = ay(az(q, .3), .3);
	d = min(d, length(q.yz) - 0.1);
	f = min(f, max(insulate(q, d) - 0.008, abs(q.x) - 0.006));
	a = sin(a * 8.) * 0.015;
	l -= .39;
	f = min(f, insulate(v3, abs(l) - abs(a)) - 0.0011); // Intertwines.
	f = min(f, nutCap(q - .03));
	U(h, f, BRASS_ID, p);
	d = max(d + 0.01, abs(q.x) - 0.0005);
	U(h, d, DARKER_BRASS_ID, p);

	// View lens barrel.
	q = dy(dx(p.zyx, .26), -.5);
	l = length(q.xy);
	d = abs(l - .13) + .005;
	d = max(d, abs(q.z) - .6);
	U(h, d, BRASS_ID, p);
	d = max(l - .11, abs(q.z) - .46);
	U(h, d, LENS_COLOR_BACK_ID, q);
	if (!hitGlass) {
		d = max(length(q) - .56, l - .115);
		U(h, d, GLASS_ID, q);
	}

	h.d -= 0.01;
	return h;
}

vec3 N(vec3 p, float t) {
	float h = t * .1;
	vec3 n = vec3(0);
	for (int i = I0; i < 4; i++) {
		vec3 e = .005773 * (2. * vec3(((i + 3) >> 1) & 1, (i >> 1) & 1, i & 1) - 1.);
		n += e * sdf(p + e * h).d;
	}

	return normalize(n);
}

float shadow(vec3 p, vec3 lp, vec3 ld, vec3 n) {
	// Quick abort if light is behind the normal.
	if (dot(ld, n) < -.1) return 0.0;
	float s = 1.,
	      t = .002, d;
	for (float i = Z0; i < SHADOW_STEPS; i++) {
		d = sdf(t * ld + p).d;
		s = min(s, 2.5 * d / t); // tweak sharpness.
		t += max(0.01, d);
		if (s < 0.01) break;
	}

	return sat(s);
}

// Quick 2-level ambient occlusion.
float ao(vec3 p, vec3 n, vec2 h) {
	vec2 ao;
	for (int i = I0; i < 2; i++)
		ao[i] = sdf(h[i] * n + p).d;

	return sat(min2(ao / h));
}

// Sub-surface scattering. (Thanks Evvvvil)
float sss(vec3 p, vec3 ld, float h) { return S01(sdf(h * ld + p).d / h); }

vec3 lights(vec3 p, vec3 ro, vec3 rd, vec3 n, Hit h) {
	if (h.id == SKY_ID) return sky(rd);
	vec3 lp = vec3(6, 6, 7),
	     ld = normalize(lp - p),
	     c = vec3(0.06);
	float spe = 10.0,
	      shine = 3.;

	if (h.id == PLANK_ID) {
        vec4 m = matWood(h.p * 3.2);
		c = m.rgb * 0.3;
        n += (m.w - 0.5) * 0.15;
		spe = 10.;
	}
	else {
        float g = musgraveFbm(p * vec3(700, 70, 70), 2., 1.0, .5);
        if (h.id == CAM_WOOD_ID) {
            c = vec3(0.15, .1, .1);
            n += g * 0.015;
            shine = 5.;
            spe = 33.;
        } else if (h.id == INLAY_ID) {
            c = vec3(0.7, .7, .6);
            n += g * 0.01;
            shine = 1.;
        }
        else {
            if (h.id == BRASS_ID) 
                c = vec3(0.7, 0.6, 0.2);
            else if (h.id == DARKER_BRASS_ID)
                c = vec3(0.35, 0.3, 0.1);
            else shine = 1.;
            c *= .7 + .3 * n31(p * vec3(300, 25, 25));
        }
    }

	vec3 l = sat(vec3(dot(ld, n),  // Key light.
	dot(-ld.xz, n.xz),  // Reverse light.
	n.y // Sky light.
	));
    
	l *= fakeEnv(ld * 8.);
	l.xy = 0.1 + 0.9 * l.xy; // Diffuse.
	l.yz *= 0.1 + 0.9 * ao(p, n, vec2(.2, 1)); // Ambient occlusion.
	l *= vec3(1., .03, .3); // Light contributions (key, reverse, sky).
	l.x += pow(sat(dot(normalize(ld - rd), n)), spe) * shine; // Specular (Blinn-Phong)
    l.x *= 0.3 + 0.7 * S(3.5, 1.8, length(p.xz));
	l.x *= 0.05 + 0.95 * shadow(p, lp, ld, n); // Shadow.
    l.x *= 0.2 + 0.8 * S(2.8, 2., length(p.xz)); // Spotlight.
	l.x *= dot(lp, lp) / (5. + dot(lp - p, lp - p)); // Light falloff
	float fre = S(.7, 1., 1. + dot(rd, n)) * 0.02;
	vec3 sky = skyCol(1.0);
	vec3 col = mix((sum2(l.xy) * LIGHT_RGB + l.z * sky) * c, sky, fre);

	// Distance Fog.
	float fg = 1.0 - exp(dot3(p - ro) * -0.001);

	return mix(vec3(.06, .04, .04), col, 1.0 - sat(fg));
}

vec3 march(vec3 ro, vec3 rd) {
	// March the scene.
	vec3 p = ro;
	float d = START_DIST, i;
	Hit h;
	vec3 n,
	     col = vec3(0),
	     glassP = col, glassN;
	hitGlass = false;
	for (i = Z0; i < MAX_STEPS; i++) {
		h = sdf(p);
		if (abs(h.d) < MIN_DIST * d) {
			if (!hitGlass && h.id == GLASS_ID) {
				hitGlass = true;
				glassP = p;
				glassN = normalize(h.p);
				vec3 v = normalize(refract(rd, glassN, .65));
				p += v * min(sdf(p + v * .02).d, .02);
				col += 0.003;
				continue;
			}

			break;
		}

		d += h.d;
		p += h.d * rd;
	}

	col += lights(p, ro, rd, n = N(p, d), h);
	if (h.id > BELOW_ARE_REFLECTIVE || hitGlass) {
		if (hitGlass) {
			p = glassP;
			n = glassN;
			col += vec3(10, 7, 10) * 100. * pow(sat(dot(normalize(vec3(8.86, 4, 8) - rd), n)), 50.);
			col += vec3(1, 1, 2.5) * .02 * S(0., .01, pow(sat(dot(normalize(vec3(8.86, 4.38, 10) - rd), n)), 35.) * 200.);
			col += vec3(10, 7, 10) * 50. * pow(sat(dot(normalize(vec3(8.86, -4, -7) - rd), n)), 50.);
		}

		// We hit a reflective surface, so march reflection.
		rd = reflect(rd, n);
		p += n * 0.01;
		ro = p;
		d = 0.01;
		for (i = Z0; i < MAX_RSTEPS; i++) {
			if (d > MAX_RDIST) {
				h.id = SKY_ID;
				break;
			}
			
			h = sdf(p);
			if (abs(h.d) < MIN_DIST * d) break;
			d += h.d;
			p += h.d * rd;
		}

		// Add a hint of the reflected color.
		col = col + (1. - col) * 0.03 * lights(p, ro, rd, N(p, d), h);
	}

	return pow(max(vec3(0), col), vec3(0.45));
}

void mainImage(out vec4 fragColor, vec2 fc) {
	vec2 uv = (fc - .5 * R.xy) / R.y;
	vec3 ro = vec3(1.85 + sin(iTime * 0.2) * 0.2, 1.3, -1.2);
	vec3 col = march(ro, rayDir(ro, uv));

    // Vignette.
	col *= 1.0 - 0.5 * dot(uv, uv);
	
	// Grain
	col += (h21(fc) - 0.5) / 50.;
	fragColor = vec4(col, 1);
}