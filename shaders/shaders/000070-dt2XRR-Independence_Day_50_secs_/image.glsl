// Image (image) — Independence Day (50 secs) by dean_the_coder
// https://www.shadertoy.com/view/dt2XRR

// 'Independence Day' dean_the_coder (Twitter: @deanthecoder)
// https://www.shadertoy.com/view/dt2XRR
// (YouTube: https://youtu.be/54QtASjzvBY)
//
// Processed by 'GLSL Shader Shrinker'
// (https://github.com/deanthecoder/GLSLShaderShrinker)
//
// Based on the Independence Day movie.
// I learnt a few more tricks in this one, and trying
// to improve my lighting and effects skills. (I'm no artist!)
// It's funny how adding a few barely noticeable effects can
// make such a difference when added together. (See the faint
// glow around the Earth. Subtle, but effective.)
//
// Tricks to aid performance:
//   - Precalculate function results and simplify calculations
//     when possible (see GLSL Shader Shrinker).
//     E.g. Precalculated rotation matrices, and SDF functions (cone())
//     that can have hard-coded constants in them.
//   - Check if the ray point is too far away from an object
//     to bother with modelling fine details.
//     (See the ship() SDF).
//   - Lots of domain repetition and axis mirroring.
//
// Thanks to Evvvvil, Flopine, Nusan, BigWings, Iq, Shane,
// totetmatt, Blackle, Dave Hoskins, byt3_m3chanic, tater,
// and a bunch of others for sharing their time and knowledge!

// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define MIN_DIST	2e-4
#define START_DIST	1.
#define MAX_DIST	3e2
#define MAX_STEPS	1e2
#define MAX_RDIST	10.
#define MAX_RSTEPS	40.
#define SHADOW_STEPS	30.
#define LIGHT_RGB	vec3(.4, 1, 1.5)
#define R	iResolution
#define Z0	min(iTime, 0.)
#define I0	min(iFrame, 0)
#define sat(x)	clamp(x, 0., 1.)
#define S(a, b, c)	smoothstep(a, b, c)
#define S01(a)	S(0., 1., a)

float t, // Global time.
      fade = 1.;
vec3 g; // 'Glow'

struct Hit {
	float d;
	int id;
	vec3 p;
};

void U(inout Hit h, float d, int id, vec3 p) { if (d < h.d) h = Hit(d, id, p); }

void minH(inout Hit h, Hit h2) { U(h, h2.d, h2.id, h2.p); }

float min2(vec2 v) { return min(v.x, v.y); }

float max2(vec2 v) { return max(v.x, v.y); }

float dot3(vec3 v) { return dot(v, v); }

float sum2(vec2 v) { return dot(v, vec2(1)); }

// Thnx Dave_Hoskins - https://www.shadertoy.com/view/4djSRW
float h11(float p) {
	p = fract(p * .1031);
	p *= p + 3.3456;
	return fract(p * (p + p));
}

vec2 h22(vec2 p) {
	vec3 v = fract(p.xyx * vec3(.1031, .103, .0973));
	v += dot(v, v.yzx + 333.33);
	return fract((v.xx + v.yz) * v.zy);
}

float h31(vec3 p3) {
	p3 = fract(p3 * .1031);
	p3 += dot(p3, p3.yzx + 333.3456);
	return fract(sum2(p3.xy) * p3.z);
}

float h21(vec2 p) { return h31(p.xyx); }

float n31(vec3 p) {
	const vec3 s = vec3(7, 157, 113);

	// Thanks Shane - https://www.shadertoy.com/view/lstGRB
	vec3 ip = floor(p);
	p = fract(p);
	p = p * p * (3. - 2. * p);
	vec4 h = vec4(0, s.yz, sum2(s.yz)) + dot(ip, s);
	h = mix(fract(sin(h) * 43758.545), fract(sin(h + s.x) * 43758.545), p.x);
	h.xy = mix(h.xz, h.yw, p.y);
	return mix(h.x, h.y, p.z);
}

// Two n31 results from two scales.
vec2 n331(vec3 p, vec2 s) {
	vec2 ns;
	for (int i = I0; i < 2; i++)
		ns[i] = n31(p * s[i]);

	return ns;
}

float n21(vec2 p) { return n31(vec3(p, 1)); }

float smin(float a, float b, float k) {
	float h = sat(.5 + .5 * (b - a) / k);
	return mix(b, a, h) - k * h * (1. - h);
}

mat2 rot(float a) {
	float c = cos(a),
	      s = sin(a);
	return mat2(c, s, -s, c);
}

vec3 rxy(vec3 p, float a) {
	p.xy *= rot(a);
	return p;
}

vec3 rxz(vec3 p, float a) {
	p.xz *= rot(a);
	return p;
}

vec3 ryz(vec3 p, float a) {
	p.yz *= rot(a);
	return p;
}

vec3 ax(vec3 p) { return vec3(abs(p.x) - .2, p.yz); }

vec3 ay(vec3 p, float d) { return vec3(p.x, abs(p.y) - d, p.z); }

float rep(float p) { return p - 48. * floor(p / 48. + .5); }

vec2 rep2(vec2 p) { return p - vec2(7, 10) * floor(p / vec2(7, 10) + .5); }

vec2 mody2(vec2 p) { return vec2(p.x, mod(p.y, 102.)); }

float box(vec3 p, vec3 b) { return length(max(abs(p) - b, 0.)); }

float box2d(vec2 p, vec2 b) {
	vec2 q = abs(p) - b;
	return length(max(q, 0.)) + min(max2(q), 0.);
}

float cap(vec3 p, float h, float r) {
	p.z -= clamp(p.z, 0., h);
	return length(p) - r;
}

float tor(vec3 p, float r1, float r2) { return length(vec2(length(p.xz) - r1, p.y)) - r2; }

float cone(vec3 p, float h) {
	vec2 q = vec2(length(p.xz), p.y),
	     k1 = vec2(2.4, h),
	     k2 = vec2(2.4, 2. * h),
	     ca = vec2(q.x - min(q.x, (q.y < 0.) ? 0. : 2.4), abs(q.y) - h),
	     cb = q - k1 + k2 * clamp(dot(k1 - q, k2) / dot(k2, k2), 0., 1.);
	return ((cb.x < 0. && ca.y < 0.) ? -1. : 1.) * sqrt(min(dot(ca, ca), dot(cb, cb)));
}

float sdOctahedron(vec3 p) {
	p = abs(p);
	return (p.x + p.y + p.z - 20.) * .57735027;
}

vec3 rayDir(vec3 ro, vec3 lookAt, vec2 uv) {
	vec3 f = normalize(lookAt - ro),
	     r = normalize(cross(vec3(0, 1, 0), f));
	return normalize(f + r * uv.x + cross(f, r) * uv.y);
}

float fakeEnv(vec3 n) {
	// Thanks Blackle.
	return length(sin(n * 2.5) * .35 + .6) / 1.7;
}

vec3 starz(vec3 rd) {
	float f,
	      st = t - 36.;
	rd.xy *= rot(st * .08);

	// Earth.
	vec2 s,
	     ns = n331(rd, vec2(67.821, 20.0948));
	rd.y += 15.55;

	// Land.
	f = length(rd.xy) - 15.;
	vec3 c = S(.1, .05, f + .05) * vec3(1, 1.8, 2);
	c *= .7 + S(.24, .7, dot(ns, vec2(.1, .4)));

	// Atmosphere/Glow
	c += (S(.1, -.2, abs(f)) + S(.5, -6., f)) * vec3(1.5, 1.5, 2.5);

	// Stars (faded out near Earth).
	rd *= 22.;
	s = h22(floor(rd.xy));
	c += vec3(s.y * S(.05 * s.x * s.y, 0., length(fract(rd.xy) - .1 - s * .8)) * S(0., .35, f));
	return c;
}

vec3 skyCol(vec3 rd) {
	float f = fakeEnv(rd);
	f *= .6 + .4 * S(40., 37., t);
	return vec3(.03, .13, .2) * f * f;
}

float scratches(vec3 p) {
	float f = 0.;
	for (float i = 1.; i <= 3.; i++)
		f = max(f, S(.01, 0., abs(fract(rxz(p + 10. + i, i * .31).z) - .5)));

	return f;
}

#define SKY_ID	0
#define METAL_ID	1
#define METAL_DARK_ID	2
#define LAZER_ID	3
#define BELOW_ARE_REFLECTIVE	7
#define GLASS_ID	8

Hit ship(vec3 p) {
	vec3 op,
	     oop = p;

	// Mirror on x - Half the work. :)
	p.x = abs(p.x);

	// Subtle glow around the ship.
	g.x += .003 / (.1 + dot(p, p)) * S(1., 0., p.z + 1.5);
	op = p;

	// Body.
	float d, b, x, l,
	      f = S(0., -3.6, p.z - 1.);
	p.z *= -.25 * f + 1. - .1 * sign(p.z);
	p.x += f * .4;
	p.x += S(-1., 2., p.z - 1.) * .4;
	d = length(p + vec3(0, 4.4, 0)) - 5.1;
	d = smin(d, length(p - vec3(0, 8.5, 0)) - 9., -.1);

	// Ray too far away? Skip the details...
	if (d > 2.) return Hit(d, METAL_ID, p);
	f = abs(abs(1.4 - op.x) - 1.5) + abs(op.z * .5);
	d += .02 * max(S(.06, .03, op.x), S(1.13, 1.1, f) - S(1., .97, f));

	// Nose cut-out.
	b = d;
	f = cone(ryz(op, -.15) - vec3(0, .64, -2.25), 1. - .02 * S(.7, .9, sin(atan(p.x, p.z + 2.5) * 32.)));
	d = smin(d, -f, -.05);

	// Sail thing.
	p = ryz(op - vec3(-.35 - .12 * p.z, 1.13, -.3), .25 + .01 * p.z * p.z);
	f = cap(p, 2.8, .7);
	f = smin(f, .15 - d, -.1);
	x = f;
	f = smin(f, .06 - op.x, -.02);

	// Sail side cut-outs.
	f = smin(f, -cap(rxz(p - vec3(.9, .1, 1), -.06), 2., .3), -.05);

	// Sail cut-out design.
	l = length(op.yz - vec2(1.3, -.28));
	f += .015 * S(0., -.03, abs(l - .2) - .04);
	f += .015 * S(-.03, -.1, op.z) * S(-.38, -.3, op.z) * step(op.y, 1.3) * S(.25, .3, l);
	d = min(d, f);

	// Scratch design.
	d -= .003 * scratches(oop);

	// Gun blisters.
	d = smin(d, cap(op - vec3(2, -.18, -.5), .5, .13), .1);

	// Grills.
	d = min(d, tor(ay(ay(op.yxz + vec3(.17, 0, 1.68), .12), .05), .15, .012));
	Hit h = Hit(d, METAL_ID, p);

	// Sail thing inner.
	x = max(x + .03, op.x - .08);
	x = min(x, max(abs(length(op.xy - vec2(0, 1)) - .025) - .001, abs(op.z) - 1.));

	// Gunz.
	p = op - vec3(2, -.23 + op.z * .15, -.6);
	x = min(x, cap(p, .5, .06 - .002 * abs(sin(p.z * 120.))));
	x = smin(x, .04 - length(p.xy), -.02);
	U(h, x, METAL_DARK_ID, op);

	// Cockpit window.
	f = tor(op + vec3(0, .56, -.3), 1., 1.18);
	d = smin(f, b + .02, -.1);
	U(h, d, GLASS_ID, op);
	if (h.id == GLASS_ID) {
		f = S(0., .15, abs(op.y - .25) - .16);
		f = max(f, S(.03, 0., abs(op.y - op.x * 1.5 + .1)) * .5);
		f = max(f, S(.05, .03, abs(op.x * .12 + .04 - op.y)) * 1.9);
		d = min(d, d - f * .01);
		U(h, d, METAL_DARK_ID, op);
	}

	// Sail mount.
	d = .03 - .07 * p.z;
	d += sat(sin(p.z * 40.) * .0125);
	d = box(op - vec3(0, .7, .6), vec3(d, .14, 1)) - .17;

	// Rear fins.
	p = op;
	p.x -= .65;
	p.y += .05;
	p.z -= 2.6 - .5 * p.x;
	x = .007 * sin(p.x * 73.);
	d = min(d, box(p, vec3(.5, .1 + x - .3 * p.z, .18 + x) - .03) - .03);
	U(h, d, METAL_DARK_ID, op);
	return h;
}

// Two combined twisting cubes with infinite length.
float twisty(vec2 p, float l, float s) {
	float d = box2d(p.xy * rot(l), vec2(s));
	return d < 3. ? smin(d, box2d(p.xy * rot(-l), vec2(s)), .3) : d;
}

float shipRack(vec3 p) {
	float d = length(ax(p - vec3(0, 1.8, -.5))) - .02;
	g.x += 3e-4 / (d * d);
	p.y -= 1.8;
	return min(d, twisty(p.xy, p.z, .1));
}

float backTower(vec3 p) {
	float d, f,
	      gy = dot(sin(p * 2.4), cos(p.yzx * 2.4));
	gy = S(0., .1, abs(gy) - 1.2);
	p.yz -= vec2(5, 50);
	p = ay(p, 13.);
	p = ay(p, 13.);
	p = ay(p, 13.);
	p.xz *= mat2(.96891, .2474, -.2474, .96891);
	d = sdOctahedron(p);

	// Lights.
	f = abs(p.y + 4.);
	f = max(d, abs(f - .4));
	f = max(f, -gy);
	g.y += gy * 5e-5 / (.005 + f * f);
	return d;
}

float columns(vec3 p) {
	p.z += 24. * sat(p.x);
	p.x = abs(p.x) - 20. - h11(floor(p.z / 48.)) * 20.;
	p.z = rep(p.z - 24.);
	return twisty(p.xz, p.y * .05, 3. + n21(p.xy) * .5) - 1.;
}

vec3 lazerP(vec3 p) {
	p.z += mod(t, 3.) * 220. - 30.;
	return p;
}

vec2 shipTunnelPos(vec2 p, float st) { return (.2 + .8 * S(10., 7.7, st)) * vec2(sin(st * -.765625 + 3.141) * 5. * S(0., 3., st), 3. + sin(st * -1.828125) * 2.125); }

Hit sdf(vec3 p) {
	// sr - Ship rotation.
	vec3 op = p,
	     sr = vec3(0);
	Hit h;
	h.d = 1e7;
	if (t < 16.) {
		//
		// Stage 1 - Racked scene.
		//
		U(h, backTower(p), METAL_DARK_ID, p);

		// We need ships. Lots of ships...
		p.xz = rep2(p.xz);

		// Ship racks.
		U(h, shipRack(p), METAL_DARK_ID, p);

		// Too far away from ships/racks - Squeeze a few more FPS...
		if (p.y > 3. || p.y < -9.) return h;

		// Add the ship(s).
		float x = floor((abs(op.x) - 3.5) / 7.),
		      z = floor((op.z - 5.) / 10.),
		      chaser = sat(x + z + 2.),
		      drop = S(9.5, 14., t - 2.5 * chaser + x * .4) * 3.2 * float(x <= z && z <= 0.);
		p.y += drop * drop * drop * 3.;
		p.z -= drop;
		sr = vec3(-.5 * drop, -2.5 * S(.3, 1.5, drop), .5 * S(.1, 1., drop));
		sr.x += (1. - chaser) * sin(t * 2.) * sin(t * 2.) * .1 * S(5.5, 6., t) * S(10., 9.5, t);
	}
	else if (t < 36.) {
		//
		// Stage 2,3 - Pillars.
		//
		float adv = 140. * t,
		      d = 1e7;
		U(h, columns(p - vec3(0, 0, adv)), METAL_DARK_ID, p);
		if (t > 17.5 && t < 34.) {
			d = cap(lazerP(op), 10., .01);
			U(h, d, LAZER_ID, p);
			g.y += .001 / (.001 + d * d);
		}

		sr.z += cos(t + 1.) * .2;
		p.xy += sin(t) * vec2(3, 2);
		p.yz += vec2(2, S(34., 37., t) * MAX_DIST);
	}
	else {
		//
		// Stage 4 - Escape tunnel.
		//
		float st = t - 36.,
		      d = 1e7;
		st *= 1.2;
		vec3 tp = rxy(p, st * .09 - .6);
		tp.z += 50. - st * 35.;
		for (float i = 0.; i < 3.; i++) {
			// Wall.
			float td = tp.y + 20.;

			// Cut-out trough.
			td = smin(td, -box2d(tp.xy + vec2(-10, 20), vec2(6, 2)), -.2);

			// Beams.
			vec2 cp = tp.xz + vec2(i * 4. + 4., 1e2 + 20. * i);
			cp.x += 10. * sin(12.9 * floor(cp.y / 102.));
			d = min(d, twisty(mody2(cp), tp.y * .2, 1.));
			tp.xy *= mat2(-.50485, .86321, -.86321, -.50485);
			d = smin(d, td, 2.);
		}

		d = max(d, -tp.z - 3e2);
		if (d < .2) d -= .025 * scratches(tp * .1);
		U(h, d, METAL_DARK_ID, tp);
		p.xy += shipTunnelPos(p.xy, st);
		p.z += 6.;
		sr.z += shipTunnelPos(p.xy, st + 2.).x * .05;
	}

	p = rxz(p, sr.y);
	p = ryz(p, sr.x);
	p = rxy(p, sr.z);
	minH(h, ship(p));

	// Nothing is perfectly sharp.
	h.d -= .01;
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
	if (dot(ld, n) < -.1) return 0.;
	float d,
	      s = 1.,
	      t = .01,
	      mxt = length(p - lp);
	for (float i = Z0; i < SHADOW_STEPS; i++) {
		d = sdf(t * ld + p).d;
		s = min(s, 15. * d / t);
		t += max(.01, d);
		if (mxt - t < .5 || s < .001) break;
	}

	return S01(s);
}

// Quick 2-level ambient occlusion.
float ao(vec3 p, vec3 n) {
	const vec2 h = vec2(.2, 1);
	vec2 ao;
	for (int i = I0; i < 2; i++)
		ao[i] = sdf(h[i] * n + p).d;

	return sat(min2(ao / h));
}

// Sub-surface scattering. (Thanks Evvvvil)
float sss(vec3 p, vec3 ld) { return S01(sdf(.05 * ld + p).d / .05); }

vec3 lights(vec3 p, vec3 ro, vec3 rd, vec3 n, Hit h) {
	vec3 lp, ld, c, l, col,
	     sky = skyCol(rd);
	if (h.id == SKY_ID) return t > 36. ? starz(rd) : sky;
	float fg,
	      ss = 0.,
	      shine = 1.;
	lp = t < 16. ? vec3(20, 8, -10) : vec3(-5, 1, -10);
	if (t > 36.) lp = vec3(30, -3.4, 35. * t - 1640.);
	ld = normalize(lp - p);
	c = vec3(.5, .4, .3);

	// Cache noise.
	vec2 ns = n331(h.p, vec2(20, 38));
	if (h.id == METAL_ID) {
		shine = 1. - sum2(ns) * .1;
		c *= shine;
		ss = sss(p, ld) * .5;
	}
	else if (h.id == METAL_DARK_ID) {
		shine = 1. - sum2(ns) * .1;
		c *= shine * .2;
		ss = sss(p, ld) * .5;
	}
	else if (h.id == GLASS_ID) {
		shine = 1. - sum2(ns) * .95;
		c *= shine * .02;
	}
	else c = vec3(9); // Lazer
	// Specular imperfections.
	shine = .2 + .8 * ns.x * ns.y;

	// Key light, reverse, sky.
	l = sat(vec3(dot(ld, n), dot(-ld.xz, n.xz), n.y));
	if (h.id != LAZER_ID) {
		// Subsurface scattering.
		l.x += ss;

		// Diffuse.
		l.xy = .1 + .9 * l.xy;

		// Ambient occlusion.
		l.yz *= .1 + .9 * ao(p, n);

		// Light contributions (key, reverse, sky).
		l *= vec3(1, .4, .2);

		// Specular (Blinn-Phong)
		l.x += pow(sat(dot(normalize(ld - rd), n)), 10.) * shine;

		// Shadow.
		l.x *= .1 + .9 * shadow(p, lp, ld, n);

		// Light falloff
		l.x *= dot(lp, lp) / (1. + dot3(lp - p));

		// Lazer light-up.
		if (t > 16. && t < 34.) {
			lp = lazerP(p) - vec3(0, 0, 5);
			c += S(20., 10., abs(lp.z - p.z)) * S(5., 0., abs(p.x)) * sat(.5 + dot(normalize(p - lp), n)) * vec3(.01, 1, .01);
		}
	}

	col = mix((sum2(l.xy) * LIGHT_RGB + l.z * sky) * c, sky, S(.7, 1., 1. + dot(rd, n)) * .2);
	fg = t < 36. ? 4e-4 : 2e-5;
	fg = exp(dot3(p - ro) * -fg); // Distance Fog.
	return mix(sky, col, fg);
}

float addFade(float a) { return min(1., 2. * abs(t - a)); }

vec4 march(vec3 ro, vec3 rd) {
	// March the scene.
	vec3 dv, n, col,
	     p = ro;
	float i,
	      d = START_DIST;
	Hit h;
	for (i = Z0; i < MAX_STEPS; i++) {
		if (d > MAX_DIST) {
			h.id = SKY_ID;
			break;
		}

		h = sdf(p);
		if (abs(h.d) < MIN_DIST * d) break;
		d += h.d;
		p += h.d * rd;
	}

	// Floaty particles.
	dv = rd;
	for (i = 1.5; i < d && t < 16.; i += 4.) {
		vec3 vp = ro + dv * i;
		vp.yz -= t * .05;
		g.x += .2 * (1. - S(0., mix(.05, .02, sat((i - 1.) / 19.)), length(fract(vp - ro) - .5)));
		dv.xz *= mat2(.87758, .47943, -.47943, .87758);
	}

	col = g.x * LIGHT_RGB + g.y * vec3(.1, 1.5, .3);
	col += lights(p, ro, rd, n = N(p, d), h);
	if (h.id > BELOW_ARE_REFLECTIVE) {
		// We hit a reflective surface, so march reflection.
		rd = reflect(rd, n);
		p += n * .01;
		ro = p;
		d = .01;
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
		col += .2 * lights(p, ro, rd, N(p, d), h);
	}

	col = pow(max(vec3(0), col), vec3(.4545));
    return vec4(col, (1. - sat(3. * d / MAX_DIST)) * 0.25);
}

#define rgba(col)	col * fade

void mainImage(out vec4 fragColor, vec2 fc) {
	t = mod(iTime, 50.);
	fade = addFade(0.) * addFade(16.) * addFade(36.) * addFade(50.);
	g = vec3(0);
	vec2 uv = (fc - .5 * R.xy) / R.y;
	vec3 lookAt = vec3(0),
	     ro = vec3(0, .001, -6);
	if (t < 16.) {
		// Stage 1 - Hanging.
		ro = mix(vec3(-4, 2, -1), vec3(-1, -1, -7), S(0., 7., t));
		float st = S(6.5, 13., t);
		ro = mix(ro, vec3(1, .8, -6), st);
		lookAt = vec3(0, st, 0);
	}
	else if (t < 22.)
        // Stage 2 - Pillar corridor.
        ro = vec3(sin(t), 6, 14);
	else if (t < 36.) {
		// Stage 3 - Side-on pillars.
		ro = vec3(8, 0, 3. * cos(t * .6) - 3.);
		ro += S(30., 34., t) * vec3(-9, 0, 15);
		lookAt.y = -1.;
	}
	else {
		// Stage 4 - Escape tunnel.
		ro.y++;
		ro.z += 15.;
	}
    
	// View bob.
	ro += .1 * sin(iTime * vec3(.9, .7, .3));
    
	vec4 col = march(ro, rayDir(ro, lookAt, uv));
    
	col.rgb *= 1. - .3 * dot(uv, uv); // Vignette.
	col.rgb += (h21(fc) - .5) / 64.; // Grain
    
	fragColor = rgba(col);
}