// Buffer B (buffer) — Bull by EvilRyu
// https://www.shadertoy.com/view/7sBGzK

// Created by evilryu
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// PC 4k exe graphics entry of Revision 2021

// Render the Bull


#define AA 1

float box(vec3 p, vec3 b)
{
	vec3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float cap(vec3 p, float h, float r)
{
	p.y -= clamp(p.y, 0.0, h);
	return length(p) - r;
}

float roundCone(vec3 p, float r1, float r2, float h)
{
	vec2 q = vec2(length(p.xz), p.y);

	float b = (r1 - r2) / h;
	float a = sqrt(1. - b *b);
	float k = dot(q, vec2(-b, a));

	if (k < 0.) return length(q) - r1;
	if (k > a *h) return length(q - vec2(.0, h)) - r2;

	return dot(q, vec2(a, b)) - r1;
}

float smin(float a, float b, float k)
{
	float h = clamp(0.5 + 0.5 *(b - a) / k, 0.0, 1.0);
	return mix(b, a, h) - k *h *(1.0 - h);
}

float smax(float a, float b, float k)
{
	return smin(a, b, -k);
}

float sabs(float x, float k)
{
	return sqrt(x *x + k) - 0.1;
}

vec3 bend(vec3 p, float k)
{
	float c = cos(k *p.x);
	float s = sin(k *p.x);
	return vec3(mat2(c, -s, s, c) *p.xy, p.z);;
}

float ellip(vec3 p, vec3 r)
{
	float k0 = length(p / r);
	return k0 *(k0 - 1.) / length(p / (r *r));
}

float cylinder(vec3 p, float h, float r)
{
	vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(h, r);
	return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

float hoof(vec3 p)
{
	p *= 6.;
	float d = cylinder(p *1.2, .7 - .4 *p.y, .4 + .2 *p.z) / 1.2 - .15;
	float d2 = box(p + vec3(0, 0, -.7), vec3(.08 - .04 *p.y, .6, .2));
	d = smax(d, -d2, .2) / 6.;
	return d;
}

float legs(vec3 op, float d, inout float mate)
{
    vec3 p=op;
    // front left
	{
		p = op + vec3(.6, .5, -.6);
		rot2d(p.xy, -1.6);
		float leg1 = cap(p, .8, .12 + .008* sin(p.x *40.));

		p.z += .01* sin(p.x *15. - 3.5) + .03* sin(p.y *20. - 2.);
		p.z *= 2.;
		p.z -= .1;
		rot2d(p.xy, 2.);
		rot2d(p.yz, -.6);
		float leg2 = roundCone(p + vec3(-.8, .2, 0), .2, .4, .5) / 2.;
		leg1 = smin(leg2, leg1, .16);

		p = op + vec3(.35, .85, -.6);
		rot2d(p.xy, 1.);
		leg2 = cap(p, .4, .07 - .004* sin(p.x *50. - .5));
		leg1 = smin(leg1, leg2, .15);
		d = smin(d, leg1, .06);

		p = op + vec3(.2, .9, -.6);
		rot2d(p.xy, 1.5);
		rot2d(p.xz, 1.2);
		float hoo = hoof(p);
		if (hoo < d) mate = HOOF;
		d = smin(d, hoo, .15);
	}

	// front right
	{
		p = op + vec3(-.6, 1., 0.6);
		rot2d(p.xy, .6);
		float leg1 = cap(p, .8, .12);

		p += vec3(.05, .64, 0);
		float leg2 = cap(p, .46, .08);
		leg1 = smin(leg1, leg2, .2);

		p += vec3(.1, .08, 0);
		rot2d(p.xy, -.7);
		rot2d(p.xz, 1.6);
		float hoo = hoof(p);
		if (hoo < d) mate = HOOF;
		d = smin(d, hoo, .4);

		p = op + vec3(.6, .5, .55);
		p.z += .01* sin(p.y *15. + 2.);
		p.z *= 2.;
		rot2d(p.xy, 0.4);
		rot2d(p.yz, -.7);
		leg2 = roundCone(p + vec3(-.8, .2, 0), .2, .4, .5) / 2.;

		leg1 = smin(leg2, leg1, .2);

		if (leg1 < d) mate = BODY;
		d = smin(d, leg1, .1);
	}

	// back legs
	{
		p = op;
		p.z *= 1.5;
		p += vec3(-2.3, 1., 0);
		rot2d(p.xy, .3);
		p.z = abs(p.z) - .8;
		rot2d(p.yz, -.3);
		p.z += .05* sin(p.x *15.) *(1. - smoothstep(1., 1.7, p.y)) +
			.02* sin(p.y *10. + 1.) *smoothstep(-1., 1., p.y);
		float leg2 = roundCone(p, .13, .5, 1.2) / 1.5;
		d = smin(d, leg2, .15);

		p.z *= .5;
		p += vec3(-.08, .6, 0);
		leg2 = roundCone(p, .06, .03, .35);
		d = smin(d, leg2, .3);
	}
    
    return d;
}

vec2 mapBull(vec3 p)
{
	vec3 op = p;
	float d = 1e5;
	float mate = BODY;

	float dis2 = smoothstep(.0, 1., fbm(vec2(p.x *3., p.y *.3) *15.)) *.01 *
		smoothstep(-.1, .2, p.y) *smoothstep(-2., -1.5, p.x) *smoothstep(3., 0., p.x);

	p.z *= 1.6;
	p.y -= .2;
	rot2d(p.xy, -0.2);
	p.x += .03* sin(p.z *16. - 4.);
	p.z += .07* sin(p.x *15.) + .03* sin(p.y *15.);;
	float body = roundCone(p.yxz, 1., .6, 1.9) / 1.6;
	d = body;

	p = op;
	p.z *= 1.4;
	p += vec3(1.4, -.2, 0);
	rot2d(p.xy, 0.2);
	p.y -= .05 *(sin(p.x *6. - 1.));
	p.z += .1* sin(p.x *30. + 3.) *smoothstep(.5, -1., p.y);
	float neck = roundCone(p.yxz, .32, .8, 1.5) / 1.4;
	d = smin(d, neck, .2);

	p = op + vec3(1.1, .5, 0);
	rot2d(p.xy, 2.2);
	float head = roundCone(p.yxz - vec3(.02* sabs(sin(p.z *20.), .1) + .03, 0, 0), .12, .3, .58) / 2.;
	head = smin(head, cylinder(p.yzx + vec3(-.2, 0, -.65), .13, .17) / 2., .1);
	head = smin(head, length(vec3(p.x - .35, p.y + .05, abs(p.z) - .16)) - .1, .1);
	head = smin(head, length(vec3(p.x - .33, p.y - .1, abs(p.z) - .13)) - .1, .05);
	head = smax(head, -length(vec3(p.x - .1, p.y *2. - 0., abs(p.z) - .31)) + .1, .12);

	rot2d(p.xy, -1.2);
	p.x *= 1.5;

	float jaw = roundCone(p.xyz + vec3(-.1, 0, .0), .12, .12, .5) / 2.;
	head = smin(head, jaw, .015);
	d = smin(d, head, .1);

	p = op;
	p.z = abs(p.z) + .15;
	p += vec3(1.2, .62, -.24);
	rot2d(p.xy, .7);
	float nose = roundCone(p, .04, .02, .2);
	d = smin(d, nose, .07);
	d = smax(d, -nose, .027);

	p = op;
	p.z = abs(p.z) + .13;
	p = p + vec3(1.45, .3, -.25);
	float eyes = (length(p* vec3(2., 1., 2.) + vec3(.2, -.2, 0)) - .3) / 2.;
	d = smin(d, eyes, .05);
	p.z = abs(op.z) - .25;
	rot2d(p.xy, .3);
	rot2d(p.yz, .3);
	eyes = (length(vec3(abs(p.x + .05) + .11, p.y + 0., p.z *3. + .1)) - .15) / 3.;
	d = smax(d, -eyes, .001);
	eyes = length(p + vec3(.04, .02, .09)) - .05;
	if (eyes < d) mate = EYES;
	d = smin(d, eyes, .0);

	p = op;
	p.z = abs(p.z) - .14;
	p += vec3(1.5, .1, -.25);
	rot2d(p.xy, 1.4);
	p = bend(p.yxz, -10.);
	p.x -= .1* sin(p.z *6.);
	float ears = ellip(p, vec3(.1 + .06* sin(p.z *20.), .02, .15));

	if (ears < d) mate = BODY;
	d = smin(d, ears, 0.01);

	p = op + vec3(2.45, .1, 0);
	rot2d(p.xy, .1);
	p.z = sabs(p.z, .1) - .7;
	rot2d(p.xz, 1.);
	p.x += .3* sin(p.z *5. + 7.5);
	p.y -= .06* sin(p.z *7.);
	float horn = roundCone(vec3(p.x, -p.z, p.y + .1), .013, .15, .9) / 2.5;
	if (horn < d) mate = HORN;
	d = min(d, horn) / 1.5;

	d = legs(op,d,mate);

	p = op + vec3(-.9, .15, 0);
	p.z -= 0.02* sin(p.y *15. - 5.) - .02* sin(p.x *8. - 2.);
	float belly = length(p) - .7;
	d = smin(d, belly, .3);

	float k = smoothstep(2.95, 3.2, op.x) *smoothstep(3.7, 3.2, op.x);
	p = op + vec3(-3.5, .2, -.32);
	rot2d(p.xy, 1.2);
	p.x += .4* sin(p.y *4.5);
	p.z += .3* sin(p.y *3. + 4.);
	p.y += .1* sin(p.z *200.);
	float tail = roundCone(p, .023 + .06 *k, .05, 1.5) / 2.;
	d = smin(d, tail, .1);

	p = op + vec3(-2.55, 1.7, 0);
	p.z = abs(p.z) - .66;
	rot2d(p.xz, 1.3);
	float hoo = hoof(p);
	if (hoo < d) mate = HOOF;
	d = smin(d, hoo, .15);

	if (mate == BODY) d -= dis2;

	return vec2(d, mate);
}

vec2 map(vec3 p)
{
	rot2d(p.xy, -.11);
	vec2 res = mapBull((p - vec3(0, 2.68, 0)));
	return res;
}

float shadow(vec3 ro, vec3 rd, float k)
{
	float res = 1.;
	float t = .01;
	for (int i = 0; i < 128 + min(0, iFrame); i++)
	{
		float h = map(ro + rd *t).x;
		res = min(res, k *h / t);
		t += clamp(h, .005, .1);
		if (res < .002 || t > 100.) break;
	}

	return max(res, .0);
}

vec3 getNormal(vec3 p, float t)
{
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=0; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(p+0.001*e*t).x;
    }
    return normalize(n);
}

vec2 intersect(vec3 ro, vec3 rd)
{
	float t = .01;
	vec2 res = vec2(1e5, 0);
	for (int i = 0; i < 256 + min(0, iFrame); ++i)
	{
		if (res.x < .002 || t > 100.) break;
		res = map(ro + t *rd);
		t += res.x;
	}

	return vec2(t, res.y);
}

float getAO(vec3 p, vec3 n)
{
	float occ = .0;
	float sca = 1.;
	for (int i = 0; i < 5 + min(0, iFrame); i++)
	{
		float h = .01 + .12* float(i) / 4.;
		float d = map(p + h *n).x;
		occ += (h - d) *sca;
		sca *= .95;
		if (occ > .35) break;
	}

	return clamp(1. - 3. *occ, 0., 1.) *(.5 + .5 *n.y);
}

float bump(vec3 p, vec3 n)
{
	p *= iResolution.x / 20.;
	p.y *= .5;
	p.xz *= 3.;
	return (fbm(p.xy) *abs(n.z) + noise(p.xz) *abs(n.y) + noise(p.yz) *abs(n.x)) / 3.;
}

vec3 bump_mapping(vec3 p, vec3 n, float weight)
{
	vec2 e = vec2(2. / iResolution.y, 0);
	vec3 g = vec3(bump(p - e.xyy, n) - bump(p + e.xyy, n),
		bump(p - e.yxy, n) - bump(p + e.yxy, n),
		bump(p - e.yyx, n) - bump(p + e.yyx, n)) / (e.x *2.);
	g = (g - n* dot(g, n));
	return normalize(n + g *weight);
}

vec3 BRDF(vec3 n, vec3 v, vec3 l, vec3 diffuse)
{
	vec3 h = normalize(v + l);
	// biased a little to workaround shiny pixels on the contour
	vec3 b = normalize(cross(n, vec3(0, 1, -.3))),
		t = normalize(cross(b, n));
	//t+=.2*n;
	float NoV = abs(dot(n, v)) + 1e-2,
		NoL = max(dot(n, l), 0.),
		NoH = max(dot(n, h), 0.),
		LoH = max(dot(l, h), 0.),
		ToV = max(dot(t, v), 0.),
		BoV = max(dot(b, v), 0.),
		ToL = max(dot(t, l), 0.),
		BoL = max(dot(b, l), 0.);

	float at = .1688, ab = .956;
	float a2 = at * ab;
	highp vec3 w = vec3(ab* dot(t, h), at* dot(b, h), a2 *NoH);
	highp float v2 = dot(w, w);
	float w2 = a2 / v2;

	float vi = 0.5 / (NoL* length(vec3(at *ToV, ab *BoV, NoV)) +
		NoV* length(vec3(at *ToL, ab *BoL, NoL)));

	return vec3(a2 *w2 *w2 *.318 *
		min(vi, 65504.) *
		(.046 + .954* pow(1.0 - LoH, 5.0))) + diffuse *.318;
}

vec3 shading(vec3 pos, vec3 rd, vec3 n, float mateid)
{
	vec3 baseCol;
	float bump = 100. / max(iResolution.x, iResolution.y);

	if (mateid == BODY)
	{
		float top = smoothstep(2.3, 3., pos.y);
		baseCol = mix(vec3(.08) *(.5 + smoothstep(0., 1., pos.x) *smoothstep(1., 2., pos.y)), vec3(.098, .059, .004),
			smoothstep(.1, .5, fbm(pos.xy *6.) *top)) *1.5;
        // Pure black looks better?
		//baseCol = vec3(.01)*(.5+smoothstep(0.,1.,pos.x))*1.5;

		bump *= .3* smoothstep(3.5, 2.4, pos.y);
	}
	else if (mateid == HORN)
	{
		baseCol = mix(vec3(.969, .89, .831), vec3(.216, .118, .004), fbm(vec2(pos.x *20., pos.y *30.))) *
			smoothstep(-2.3, -1.9, pos.x);
		bump *= .05;
	}
	else if (mateid == HOOF)
	{
		baseCol = noise(pos.xy *30.) *vec3(.506, .459, .416);
		bump *= 0.08;
	}

	n = bump_mapping(pos, n, bump);

	float ao = getAO(pos + .1 *n, n), sha = shadow(pos, sunDir, 10.);

	vec3 col = BRDF(n, -rd, sunDir, baseCol) *ao *sunCol* max(0., dot(sunDir, n)) *8. *sha +
		sunCol* max(0., dot(-sunDir, n)) *.015;

	if (mateid == EYES) col = vec3(1, .435, 0);
	return col;
}

vec3 scene(vec3 ro, vec3 rd, vec2 uv)
{
	vec4 col = texture(iChannel0, uv);

	vec2 res = intersect(ro, rd);
	float t = res.x;
	if (t < col.w)
	{
		vec3 pos = ro + t * rd;

		vec3 n = getNormal(pos, 1.);
		col.xyz = shading(pos, rd, n, res.y);
	}

	t = min(t, col.w);
	if (t < 10.)
		col.xyz = mix(col.xyz, vec3(.82), 1.0 - exp(-.002 *t *t));

	return col.xyz;
}

vec3 tonemap(vec3 x)
{
	const float a = 2.51,
		b = .03,
		c = 2.43,
		d = .59,
		e = .14;
	return (x *(a *x + b)) / (x *(c *x + d) + e);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	vec2 uv = fragCoord.xy / iResolution.xy;

	vec3 ta = vec3(-.7, 2.6, 0),
		ro = vec3(-2.96, 1.21, 3.8),
		rd, col = vec3(0);

	#if AA > 1
	for (int m = 0; m < AA; m++)
		for (int n = 0; n < AA; n++)
		{
			vec2 o = vec2(float(m), float(n)) / float(AA) - .5;
			Q = (-iResolution.xy + 2. *(fragCoord + o)) / iResolution.y;
    #else
			Q = (-iResolution.xy + 2. *fragCoord) / iResolution.y;
    #endif
			rd = cam(ro, ta) *normalize(vec3(Q.xy, 1.8));
			col += scene(ro, rd, uv);
    #if AA > 1
		}

	col /= float(AA *AA);
    #endif

	col = tonemap(col);
	col = pow(clamp(col, 0., 1.), vec3(.45));
	col.z = (col.z + .1) / 1.1;
	col = clamp(col *.5 + .5 *col *col *1.3, 0., 1.);
	col *= .5 + .5* pow(16. *uv.x *uv.y *(1. - uv.x) *(1. - uv.y), .15);
	fragColor = vec4(col, 0);
}