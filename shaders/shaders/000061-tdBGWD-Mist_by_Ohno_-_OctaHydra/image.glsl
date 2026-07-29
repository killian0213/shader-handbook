// Image (image) — Mist by Ohno! - OctaHydra by Flopine
// https://www.shadertoy.com/view/tdBGWD

// Code by Flopine

// From Mist by Ohno!
// 4k demo released at Cookie 2018 with a music by Triace from Desire
// Pouet : http://www.pouet.net/prod.php?which=79350
// Youtube : https://www.youtube.com/watch?v=UUtU3WVB144&t=3s

// Thanks to wsmind, leon, XT95, lsdlive, lamogui, Coyhot and Alkama for teaching me
// Thanks LJ for giving me the love of shadercoding :3

// Cookie Collective rulz


float time = 0.;
#define PI 3.141592
#define tempo_sin (time * 2.62)
#define tempo (mix(4.5/6., 9./6., step(87., time)))


vec2 hash(vec2 x)
{
	vec2 k = vec2(0.3183099, 0.3678794);
	x = x * k + k.yx;
	return -1.0 + 2.0 * fract(16.0 * k * fract(x.x * x.y * (x.x + x.y)));
}


float random(vec2 uv)
{return fract(sin(dot(uv, vec2(12.2544, 35.1571)))*5418.548416);}


float noise(in vec2 p)
{
	vec2 i = floor(p);
	vec2 f = fract(p);

	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(mix(dot(hash(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
		dot(hash(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
		mix(dot(hash(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
			dot(hash(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x),
		u.y);
}


float fbm(vec2 uv)
{
	float f;
	mat2 m = mat2(1.6, 1.2, -1.2, 1.6);
	f = 0.5000 * noise(uv);
	uv = m * uv;
	f += 0.2500 * noise(uv);
	uv = m * uv;
	f += 0.1250 * noise(uv);
	return f;
}


mat2 r2d(float a) 
{
	float c = cos(a), s = sin(a);
	return mat2(c, s, -s, c);
}


float smin(float a, float b, float k)
{
	float h = clamp(0.5 + 0.5*(b - a) / k, 0.0, 1.0);
	return mix(b, a, h) - k * h*(1.0 - h);
}


vec3 re(vec3 p, float d) 
{return mod(p - d * .5, d) - d * .5;}


void amod(inout vec2 p, float d) 
{
	float a = re(vec3(atan(p.y, p.x)), d).x;
	p = vec2(cos(a), sin(a)) * length(p);
}


vec3 get_cam(vec3 ro, vec3 ta, vec2 uv)
{
	vec3 fwd = normalize(ta - ro);
	vec3 right = normalize(cross(fwd, vec3(0, 1, 0)));
	return normalize(fwd + right * uv.x + cross(right, fwd) * uv.y);
}


float sphe(vec3 p, float r)
{return length(p) - r;}


float od(vec3 p, float d)
{return dot(p, normalize(sign(p))) - d;}


float sc(vec3 p, float d) {
	p = abs(p);
	p = max(p, p.yzx);
	return min(p.x, min(p.y, p.z)) - d;
}


float torus(vec3 p, vec2 d)
{
	vec2 q = vec2(length(p.xz) - d.x, p.y);
	return length(q) - d.y;
}



////////// SCENE CONSTRUCTION //////////////////////////////////////////////////////////
float pool(vec3 p)
{return abs(p.y + fbm(p.xz*0.1 + time * 0.1 + fbm(p.xz*0.1 - time * 0.2)) + 0.5) - 0.05;}


float g1 = 0.;
float g2 = 0.;
float tubes(vec3 p)
{
	p.xz = re(p.xzz + 9., 18.).xy;
	p.xz *= r2d(time*0.4);
	p.xz *= r2d(p.y*0.3);
	amod(p.xz, 2.*PI / 5.);
	p.x -= 2.;
	p.x += sin(p.y*0.5 + time);
	float d = length(p.xz) - 0.2;

	g2 += (0.01 / (0.01 + d * d))*0.15;

	return d;
}


float ball(vec3 p)
{
	p.y -= mix(-2., 5., smoothstep(4., 10., time) * (1. - smoothstep(112., 115., time)));
	float d = sphe(p, .8 + sin(tempo_sin)*0.1);
	g1 += 0.01 / (0.01 + d * d);
	return d;
}


float cage(vec3 p)
{
	p.y -= 5.;
	p.xz *= r2d(time);
	p.yz *= r2d(time*0.5);
	float od_size = mix(-.1, 1., smoothstep(14., 19., time));
	float sphe_r1 = mix(1.14, 0.1, smoothstep(41., 42., time));
	float sphe_r = mix(sphe_r1, 3., pow(fract(time), 6.) * step(110., time) + (step(111., time)));
	return max(-sphe(p, sphe_r), od(p, od_size));
}


float ring(vec3 p)
{
	float anim = (PI / 2.)*(floor(time*tempo) + pow(fract(time*tempo), 3.));

	vec2 torus_size1 = mix(vec2(1.5, -0.5), vec2(2., 0.05), smoothstep(25., 28., time)*(1. - smoothstep(109., 110., time)));
	vec2 torus_size2 = mix(vec2(2.5, -0.5), vec2(3., 0.09), smoothstep(31., 34., time)*(1. - smoothstep(109., 110., time)));


	p.y -= 5.;
	p.xy *= r2d(PI / 4.);
	p.xz *= r2d(PI / 4.);

	vec3 pp = p;
	p.xz *= r2d(-anim);
	float r1 = max(-sc(p, 1.), torus(p, torus_size1));

	p = pp;
	p.xy *= r2d(anim);
	p.yz *= r2d(PI / 2.);
	float d = min(r1, max(-sc(p, 1.), torus(p, torus_size2)));
	g1 += 0.01 / (0.01 + d * d);
	return d;
}


float balls(vec3 p)
{
	float d = sphe(vec3(p.x, p.y + 2., p.z), 0.5);
	p.y += mix(2., (sin(time) + 1.), smoothstep(35., 37., time));
	if (time > 88.) p.y = mix(2., 0., smoothstep(89., 92., time) * (1. - smoothstep(113., 115., time)));

	for (int i = 0; i < 3; i++)
	{
		amod(p.xz, 2.*PI / 5.);
		p.x -= mix(6., 0.1, clamp(pow(fract(time), 3.) * step(95., time) + step(96., time), 0., 1.));
		d = min(d, sphe(p, 0.5));
	}
	g1 += 0.01 / (0.01 + d * d);
	return d;
}


float SDF(vec3 p)
{
	return time < 24. ? smin(tubes(p), smin(pool(p), min(ball(p), cage(p)), 2.), 1.5) :
		min(min(ring(p), min(cage(p), ball(p))), smin(tubes(p), smin(pool(p), balls(p), 2.), 1.5));
}



////////// RAYMARCHING FUNCTION ////////////////
vec3 raymarch_flopine(vec3 ro, vec3 rd, vec2 uv)
{
	vec3 col;
	float dither = random(uv);
	float t = 0.;
	vec3 p;// = ro;
	for (float i = 0.; i < 80.; i++)
	{
		p = ro + t * rd;
		float d = SDF(p);
		if (d < 0.001)
		{
			col = vec3(i / 80.);
			break;
		}
		d *= 1. + dither * 0.1;

		t += d * .8;
	}

	float g2_force = mix(0., 0.8, smoothstep(10., 14., time) * (1. - smoothstep(116., 120., time)));
	col += g1 * vec3(0.2, 0.4, 0.);
	col += (g2* g2_force) * vec3(0., 0.5, 0.5);
	col = mix(col, vec3(0., 0.3, 0.4), 1. - exp(-0.001*t*t));

	return col;
}


// Glitch function borrowed from mmerchante shader : https://www.shadertoy.com/view/MltcWs
void glitch(inout vec2 uv, float start_time_stamp, float end_time_stamp)
{
	int offset = int(floor(time)*2.) + int((uv.x + uv.y) * 8.0);
	float res = mix(10., 100.0, random(vec2(offset)));

	// glitch pixellate
	if (time > start_time_stamp && time <= end_time_stamp) uv = floor(uv * res) / res;

	int seedX = int(gl_FragCoord.x + time) / 32;
	int seedY = int(gl_FragCoord.y + time) / 32;
	int seed = mod(time, 2.) > 1. ? seedX : seedY;


	// glitch splitter
	uv.x += (random(vec2(seed)) * 2.0 - 1.0)
		* step(random(vec2(seed)), pow(sin(time * 4.), 7.0))
		* random(vec2(seed))
		* step(start_time_stamp, time)
		* (1. - step(end_time_stamp, time));
}



///////// MAIN FUNCTION //////////////////////////////
void mainImage(out vec4 fragColor, in vec2 fragCoord) {

	vec2 q = fragCoord.xy / iResolution.xy;
	vec2 uv = q - .5;
	uv.x *= iResolution.x / iResolution.y;
    
    
	/* just code for the shadertoy port */
	time = mod(iTime, 45. + 10.6 + 17.);
    if (time > 45. && time <= 88.)
		time += 43.;
    if (time > 98.6)
		time += 10.4;
   
	glitch(uv, 0., 2.);
	glitch(uv, 91., 92.);
	glitch(uv, 94.5, 95.5);
	glitch(uv, 98., 99.);

	vec3 flo_ro1 = vec3(-20. * cos(time*0.06), 10., -20.*sin(time*0.06));
	vec3 flo_ro2 = vec3(-5., 18., 0.);
	vec3 flo_ro3 = vec3(-5., 20., 12.);
	vec3 flo_ro = mix(mix(flo_ro1, flo_ro2, step(24., time)), flo_ro3, step(88., time));
	vec3 flo_target = vec3(0.);
	vec3 flo_cam = get_cam(flo_ro, flo_target, uv);


	vec3 col = vec3(0.);
	if (time <= 45.)
		col = raymarch_flopine(flo_ro, flo_cam, uv);
	if (time > 88. && time <= 98.6) // 98.
		col = raymarch_flopine(flo_ro, flo_cam, uv);
	if (time > 109. && time <= 126.)
		col = raymarch_flopine(flo_ro, flo_cam, uv);


	// vignetting from iq
	col *= 0.5 + 0.5*pow(16.0*q.x*q.y*(1.0 - q.x)*(1.0 - q.y), 0.25);

	// fading out - end of the demo
	col *= 1. - smoothstep(120., 125., time);

	fragColor = vec4(col, 1.);
}
