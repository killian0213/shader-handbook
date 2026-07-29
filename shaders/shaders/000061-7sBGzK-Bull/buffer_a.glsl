// Buffer A (buffer) — Bull by EvilRyu
// https://www.shadertoy.com/view/7sBGzK

// Created by evilryu
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// PC 4k exe graphics entry of Revision 2021

// Render cloud and grass

float mapCloud(vec3 p)
{
	p += vec3(4., 2., 20.);
	rot2d(p.xz, .9);
	float d = 6. - length(vec3(mod(p.x, 6.) - 3., p.y, p.z)) - 3. *fbm2(p) + 2. *fbm2(p *.3);
	d *= 1. - smoothstep(3., 6., p.y);
	return clamp(d, 0., 1.);
}

vec3 renderCloud(vec3 ro, vec3 rd)
{
	float rnd = .95 + .05* fract(sin(dot(Q, vec2(12.9898, 78.233))) *43758.5453);

	vec4 sum = vec4(rnd *sky *(exp(-length(rd.xy - vec2(.4, .4)))), 1);

	float t = 8.;
	float dt = .2;
	for (int i = 0; i < 64 + min(0, iFrame); ++i)
	{
		vec3 p = ro + t * rd;
		float d = mapCloud(p);

		if (d > 0.)
		{
			float s = 0.;
			vec3 st = normalize(p + sunDir);
			vec3 sp = p;
			for (int j = 0; j < 10; j++)
				s += mapCloud(sp += st);

			sum.xyz += exp(-s *.15) *d* vec3(1.5) *sunCol *(1. - d) *sum.a;
			sum.a *= 1. - d;
		}

		if (sum.a < .1 || t > 500.) break;

		t += dt;
		dt = max(.2, .02 *t);
	}

	return sum.xyz;
}

float mapTerrian(vec3 p)
{
	vec2 q = p.xz *.5 + vec2(3);
	float f = (.9 - 1.5* sin(p.x *.1)) *noise(q);
	q = q *2.11;
	f += .5* noise(q);
	q = q *2.2;
	return f - .3;
}

float blades[8];

// grass based on kuvkar's Windyplains: https://www.shadertoy.com/view/ltXXRM
float mapGrass(vec3 p)
{
	p.xy = vec2(p.x, p.y);
	float d = noise(p.xz *(GRASS_DENSITY + 100. *smoothstep(2.5, 3., p.z)));
	d *= mix(1., noise(p.xz *30. - 27.), .6);
	int i = 7;
	for (; i > 0 + min(0, iFrame); --i) blades[i] = blades[i - 1];
	blades[0] = d;
	for (; i < 8 + min(0, iFrame); ++i) d += blades[i];
	d /= float(i + 1);
	d *= GRASS_H* min(1., exp(-(p.z) *.08));
	return d;
}

float intersectGrass(vec3 ro, vec3 rd)
{
	float t = .01;
	vec3 p = ro + t * rd;
	for (int i = 0; i < 1000 + min(0, iFrame); ++i)
	{
		float d = p.y - mapGrass(p) - mapTerrian(p);
		if (d < .005 || t >= 10.) break;
		d = max(1e-4, .04 *d* exp(t *.4));
		p += d * rd;
		t += d;
	}

	return t;
}

vec3 renderGrass(vec3 ro, vec3 rd, float t, vec3 col)
{
	if (t < 10.)
	{
		vec3 p = ro + t * rd;
		col = vec3(4.82, 2.75, 1.18) *max(0., dot(sunDir, vec3(0, .4, 1))) *2.;
		col = mix(col, vec3(1.2, 1, 0.5), fbm(p.xz *2.));
		col *= smoothstep(GRASS_H *.45, GRASS_H *2., p.y - mapTerrian(p));
		col *= pow(smoothstep(-.7, 1., fbm(p.xz)), 4.);
		float d = p.y - mapGrass(p) - mapTerrian(p);
		col *= .8* clamp(d / GRASS_H, .0, 1.) + .2;
		col *= 20.;
	}

	return col;
}

vec4 scene(vec3 ro, vec3 rd)
{
	vec3 col = renderCloud(ro, rd);

	float t = intersectGrass(ro, rd);

	col = renderGrass(ro, rd, t, col);

	if (t < 10.)
		col = mix(col, vec3(.82), 1.0 - exp(-.002 *t *t));

	return vec4(col, t);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	vec3 ta = vec3(-.7, 2.6, 0),
		ro = vec3(-2.96, 1.21, 3.8),
		rd;
	Q = (-iResolution.xy + 2. *fragCoord) / iResolution.y;
	rd = cam(ro, ta) *normalize(vec3(Q.xy, 1.8));
	fragColor = scene(ro, rd);
}