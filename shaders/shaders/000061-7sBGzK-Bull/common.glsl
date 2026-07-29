// Common (common) — Bull by EvilRyu
// https://www.shadertoy.com/view/7sBGzK

// Created by evilryu
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// PC 4k exe graphics entry of Revision 2021
#define PI 3.1415926535
#define BODY 0.
#define HOOF 1.
#define HORN 2.
#define EYES 3.
#define GRASS_H 0.1
#define GRASS_DENSITY 540.

vec3 sunDir = normalize(vec3(1, 1, 1.5));
vec3 sunCol = vec3(1, .9, .62) *1.3;
vec3 sky = vec3(.071, .102, .129);
vec2 Q;

void rot2d(inout vec2 p, float t)
{
	float ct = cos(t), st = sin(t);
	vec2 q = p;
	p.x = ct *q.x + st *q.y;
	p.y = -st *q.x + ct *q.y;
}

float hash11(float p)
{
	vec2 p2 = fract(vec2(p *5.3983, p *5.4427));
	p2 += dot(p2.yx, p2.xy + vec2(21.5351, 14.3137));
	return fract(p2.x *p2.y *95.4337) *0.5 + 0.5;
}

float noise(vec2 x)
{
	vec2 p = floor(x);
	vec2 f = fract(x);
	f = f *f *(3.0 - 2.0 *f);
	float n = p.x + p.y *57.0;
	return mix(mix(hash11(n + 0.0), hash11(n + 1.0), f.x),
		mix(hash11(n + 57.0), hash11(n + 58.0), f.x), f.y);
}

float noise(vec3 p)
{
	const vec3 s = vec3(7, 157, 113);
	vec3 ip = floor(p);
	vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
	p -= ip;
	p = p *p *(3. - 2. *p);
	h = mix(fract(sin(h) *43758.5453), fract(sin(h + s.x) *43758.5453), p.x);
	h.xy = mix(h.xz, h.yw, p.y);
	return mix(h.x, h.y, p.z);
}

float fbm(vec2 q)
{
	float f = 0.0;
	vec3 p = vec3(q, 0);
	f += .5* noise(p);
	p = p *2.01;
	f += .25* noise(p);
	p = p *2.02;
	f += .125* noise(p);
	p = p *2.03;
	return f;
}

float fbm2(vec3 p)
{
	mat3 m = mat3(.0, .8, .6,
		-.8, .36, -.48,
		-.6, -.48, .64);
	float f = 0., s = .5;
	for (int i = 0; i < 4; ++i)
	{
		f += s* noise(p);
		p = m *p *2.01;
		s *= .5;
	}

	return f;
}

mat3 cam(vec3 ro, vec3 ta)
{
	vec3 f = normalize(ta - ro);
	vec3 r = normalize(cross(f, vec3(0, 1, 0)));
	vec3 u = normalize(cross(r, f));
	return mat3(r, u, f);
}