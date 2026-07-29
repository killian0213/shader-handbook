// Image (image) — Inessentials 2019 by adx
// https://www.shadertoy.com/view/wsX3RB

/*
	Shadertoy Inessentials 2019 Home Edition
	A small, cheekily named collection of Shadertoy mods
	================================================================

	UPDATE (2019-02-14): Half of the initial scripts are now redundant,
	since their functionality is now built-in! The other two scripts,
	plus a new one adding comment preview support, are now here:
	
	https://github.com/andrei-drexler/shadertoy-userscripts/

	For other ways to extend Shadertoy, check out @FabriceNeyret2's blog
	https://shadertoyunofficial.wordpress.com/2017/07/25/extending-shadertoy/

	For a frame exporter add-on, check out @tdhooper's repository
	https://github.com/tdhooper/shadertoy-frame-exporter

	--- original text below ---


	First things first, these tweaks come in the form of so-called "userscripts".
	They're like mini browser extensions, except you can't use them on their own,
	you need a "userscript manager" extension to run them.
	Personally, I use Tampermonkey (on Chrome/Firefox), but Greasemonkey + Firefox,
	for example, should also work.

    Tampermonkey website:
    https://tampermonkey.net/

    Tampermonkey on the Chrome web store (10M+ downloads):
    https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo

	Once you have Tampermonkey, the easiest way to install these scripts
	from Github is to go to the "Raw" view - Tampermonkey should detect
	the .user.js suffix and bring up a confirmation screen.

	I've also looked into packaging the scripts into a standalone extension,
	so if you prefer that solution, let me know.

	On to the actual mods:


	1. Compilation timing (OBSOLETE):
	------------------------

	When working on large shaders compile times can become a major issue.
    Being able to time compilation more precisely than counting Mississippi's
	allows you to compare different approaches and make informed decisions
	regarding potential optimizations.

	Demo (14 sec):
	https://youtu.be/N2Ai8Fdi7ec
	
	Script:
	https://gist.github.com/andrei-drexler/98754c911e6d9be05086a03e94547430

	TODO (maybe):
	- replace timing info with next/prev error controls if compilation was
	  unsuccessful


	2. FPS mode (as in First-Person-Shooter, not Frames-Per-Second):
	------------------------

	This adds a new button to the player bar which toggles the new FPS mode.
	When it is enabled, you only have to click once on the canvas and then
	you can move the mouse freely, without the need to keep the mouse button
	pressed, or worry about going out of bounds. It's meant primarily for
	FPS-like shaders, of course, but it works nicely with pretty much any
	shader where you use the mouse to look around or scroll.

	Demo (41 sec) - note the absence of fast and furious clicking in FPS mode:
	https://youtu.be/Ecl2wHdDm3M
	
	Script:
	https://gist.github.com/andrei-drexler/7b5829750e41650173bfb7add9ecc61c

	TODO (maybe):
	- add sensitivity control


	3. Page titles (OBSOLETE)
	------------------------

	If you have multiple Shadertoy tabs open it can be pretty hard to tell them apart.
	This script replaces the familiar 'Shadertoy BETA' tab title with ones such as
	'Profile - Shadertoy', 'Page 3 - Shadertoy', or 'Shane - Shadertoy'.

	Script:
	https://gist.github.com/andrei-drexler/b383896268f5e9a1ce21259848706540


	4. Video capture
	------------------------

	The built-in video recording feature is pretty handy, but the default settings
	don't work well with noisy shaders (e.g. ones with unfiltered SSAO with low sample
	counts). Also, if the shader runs at 144 Hz, so will the video recording, and that's
	somewhat overkill. This script adds an explicit (high) bitrate, limits the recording
	framerate to 60 fps (shader still running at full speed), changes the codec to H264
	if available (for better compatibility with video editing/playback software), generates
	a more descriptive output file name (e.g. Quake_Introduction-20190130-1948.webm), and
	also resumes the shader (if paused) when you begin recording and pauses it when you're
	done.

	Script:
	https://gist.github.com/andrei-drexler/0898fb9753e5a60240bd72be0e95f3cb

	----

	That is all, for now. Nothing groundbreaking, just some minor tweaks -
	hence the name, "Shadertoy Inessentials".

	I have some ideas for a few more of these, such as line bookmark support (F2/Ctrl+F2)
	for easier navigation in larger shaders and GPU query-based timing (for some basic
	buffer profiling), but I can't promise anything right now. We'll see :)
*/

////////////////////////////////////////////////////////////////

const int ANTIALIAS			= 4;

#define ENABLE_REFLECTION	1
#define CREEPY_EYE			0

////////////////////////////////////////////////////////////////

#define COLOR_SCHEME 1

#if COLOR_SCHEME == 1
const vec4
    BACKGROUND_COLOR		= vec4(.15, .15, .4, 1),
    SPOTLIGHT_COLOR			= vec4(.4, .4, 1., 1),
    GROUND_TEXT_COLOR		= vec4(1),
    OVERLAY_COLOR			= vec4(.2, .2, .5, 1),
	OVERLAY_TEXT_COLOR		= vec4(0, 0, 0, 1),
	OVERLAY_TEXT2_COLOR		= vec4(0, 0, 0, .75),
    OVERLAY_ICON_COLOR		= vec4(0, 0, 0, 1),
    BOX_COLOR1				= vec4(.01, .01, .01, 1),
    BOX_COLOR2				= vec4(.015, .015, .06, 1),
    BOX_LINE_COLOR			= vec4(.75, .25, 0, 1),
    BOX_TITLE_COLOR			= vec4(1),
    HOME_EDITION_COLOR		= vec4(1, 1, 1, .125),
    TAMPERMONKEY_TEXT_COLOR	= vec4(.3, .3, .3, 1),
    BLURB_TEXT_COLOR		= vec4(1),
    USER_QUOTE_COLOR		= vec4(.3, .3, .3, 1)
;
#else
const vec4
    BACKGROUND_COLOR		= vec4(.6, .2, .1, 1),
    SPOTLIGHT_COLOR			= vec4(1, .4, .2, 1),
    GROUND_TEXT_COLOR		= vec4(1),
    OVERLAY_COLOR			= vec4(.75, .25, .12, 1),
	OVERLAY_TEXT_COLOR		= vec4(0, 0, 0, 1),
	OVERLAY_TEXT2_COLOR		= vec4(0, 0, .02, .75),
    OVERLAY_ICON_COLOR		= vec4(0, 0, 0, 1),
    BOX_COLOR1				= vec4(vec3(.875), 1),
    BOX_COLOR2				= vec4(.015, .015, .06, 1),
    BOX_LINE_COLOR			= vec4(.75, .25, 0, 1),
    BOX_TITLE_COLOR			= vec4(1),
    HOME_EDITION_COLOR		= vec4(1, 1, 1, .125),
    TAMPERMONKEY_TEXT_COLOR	= vec4(0, 0, 0, 1),
    BLURB_TEXT_COLOR		= vec4(1),
    USER_QUOTE_COLOR		= vec4(0, 0, 0, 1)
;
#endif

////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////

// Yes, this shader could be MUCH smaller, just that
// I like long names and I cannot lie

#define SETTINGS_CHANNEL iChannel1
#define NO_UNROLL min(0, iFrame)

const float
    PHI	= 1.61803408,
    PI	= 3.14159265,
    TAU	= 2. * PI
;

float min_component(vec2 v)		{ return min(v.x, v.y); }
float min_component(vec3 v)		{ return min(v.x, min(v.y, v.z)); }
float min_component(vec4 v)		{ return min(min(v.x, v.y), min(v.z, v.w)); }

float max_component(vec2 v)		{ return max(v.x, v.y); }
float max_component(vec3 v)		{ return max(v.x, max(v.y, v.z)); }
float max_component(vec4 v)		{ return max(max(v.x, v.y), max(v.z, v.w)); }

float smoothen(float f)			{ return f * f * (3. - 2. * f); }
vec2  smoothen(vec2 f)			{ return f * f * (3. - 2. * f); }

float linear_step(float low, float high, float value) {
    return clamp((value-low)*(1./(high-low)), 0., 1.);
}

float fadeinout(float in0, float in1, float out1, float out0, float x) {
    return min(linear_step(in0, in1, x), linear_step(out0, out1, x));
}

float around(float peak, float range, float x) {
    return clamp(1.-abs(x-peak)*(1./range), 0., 1.);
}

float elastic(float cycles, float x) {
#if 0 // faster, does not reach 1.0 at the end
	// https://joshondesign.com/2013/03/01/improvedEasingEquations
    // http://shader-playground.timjones.io/b23ffee8f0686827dd9a907fcdc8e015
    return 1. - exp2(x*-10.) * cos(x * cycles * TAU);
#else // slightly slower, hits 1.0 at the end
    return 1. - pow(max(0., 1.-x), 6.) * cos(x * cycles * TAU);
#endif
}

float bounce(float cycles, float x) {
    x = elastic(cycles, x);
    return x - max(0., x - 1.) * 2.;
}

float repeat(float div, float x) {
    return fract(x / div + .5) * div - .5 * div;
}

vec2 repeat(float div, float minval, float maxval, float x) {
    x = x / div + .5;
    float y = clamp(floor(x), minval, maxval);
    return vec2((x - y) * div - .5 * div, y);
}

float alternate(float speed, float bias, float x) {
    return clamp(abs(fract(x) - .5) * speed - speed * .25 + bias + .5, 0., 1.);
}

float alternate(float speed, float x) {
    return alternate(speed, 0., x);
}

////////////////////////////////////////////////////////////////

// Dave Hoskins/Hash without Sine
// https://www.shadertoy.com/view/4djSRW

const vec4 HASHSCALE = vec4(.1031, .1030, .0973, .1099);

float hash(float p) {
    p = fract(p * HASHSCALE.x);
    p += 3. * p * (p + 19.19);
    return fract(2. * p * p);
}

float hash(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * HASHSCALE.x);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash2(float p) {
	vec3 p3 = fract(p * HASHSCALE.xyz);
	p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx + p3.yz) * p3.zy);
}

vec3 hash3(float p) {
   vec3 p3 = fract(p * HASHSCALE.xyz);
   p3 += dot(p3, p3.yzx + 19.19);
   return fract((p3.xxy + p3.yzz) * p3.zyx);
}

////////////////////////////////////////////////////////////////

float smooth_noise(float f) {
    float i = floor(f);
    return mix(hash(i), hash(i + 1.), smoothen(f - i));
}

float smooth_noise(vec2 p) {
    vec2 i = floor(p);
    p = smoothen(p - i);
    float s00 = hash(i),
    	  s01 = hash(i + vec2(1, 0)),
    	  s10 = hash(i + vec2(0, 1)),
    	  s11 = hash(i + vec2(1, 1));
    return mix(mix(s00, s01, p.x), mix(s10, s11, p.x), p.y);
}

vec2 smooth_noise2(float f) {
    float i = floor(f);
    return mix(hash2(i), hash2(i + 1.), smoothen(f - i));
}

// SDF operations //////////////////////////////////////////////

float sdf_exclude(float from, float what) {
    return max(from, -what);
}

float sdf_union(float a, float b) {
    return min(a, b);
}

float sdf_intersection(float a, float b) {
    return max(a, b);
}

float sdf_overlay_wire(float dist, float over, float thickness) {
    return sdf_union(sdf_exclude(dist, over), abs(over) - thickness);
}

// SDF generators //////////////////////////////////////////////

float line(vec2 p, vec2 a, vec2 b, float thickness) {
    vec2 ab = b-a, ap = p-a;
    float t = clamp(dot(ap, ab)/dot(ab, ab), 0., 1.);
    return length(ap - ab*t) - thickness*.5;
}

float disk(vec2 p, float radius) {
    return length(p) - radius;
}

float circle(vec2 p, float radius, float thickness) {
    return abs(length(p) - radius) - thickness * .5;
}

float box(vec2 p, vec2 size) {
    p = abs(p) - size;
    return min(0., max(p.x, p.y)) + length(max(p, 0.));
}

// signed distance to a 2D triangle
// https://www.shadertoy.com/view/XsXSz4
float sdTriangle(vec2 p, vec2 p0, vec2 p1, vec2 p2) {
	vec2 e0 = p1 - p0;
	vec2 e1 = p2 - p1;
	vec2 e2 = p0 - p2;

	vec2 v0 = p - p0;
	vec2 v1 = p - p1;
	vec2 v2 = p - p2;

	vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
	vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
	vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
    
    float s = sign( e0.x*e2.y - e0.y*e2.x );
    vec2 d = min( min( vec2( dot( pq0, pq0 ), s*(v0.x*e0.y-v0.y*e0.x) ),
                       vec2( dot( pq1, pq1 ), s*(v1.x*e1.y-v1.y*e1.x) )),
                       vec2( dot( pq2, pq2 ), s*(v2.x*e2.y-v2.y*e2.x) ));

	return -sqrt(d.x)*sign(d.y);
}

////////////////////////////////////////////////////////////////

mat2 rotation(float angle) {
    angle = radians(angle);
    float c = cos(angle), s = sin(angle);
    return mat2(c, s, -s, c);
}

vec2 mod_polar(float divs, vec2 p) {
    float angle = repeat(TAU/divs, atan(p.y, p.x));
    return vec2(cos(angle), sin(angle)) * length(p);
}

float mask(float dist) {
    return clamp(.5-dist, 0., 1.);
}

// Icons ///////////////////////////////////////////////////////

float comment_preview(vec2 p, float time) {
    float bubble = disk(p - vec2(3.4, 2.1), 4.);
    bubble = sdf_exclude(bubble, disk(p-vec2(4.5, .5), 4.));
    bubble = sdf_intersection(bubble, p.y - .25);
    bubble = sdf_union(bubble, box(p - vec2(0, .5), vec2(.875, .5)) - .25);
    bubble = abs(bubble) - .0625;
    
#if CREEPY_EYE
    float which = step(.975, hash(floor(time*14.)));

    vec2 p2 = vec2(p.x, abs(p.y - .5));
    float interior = circle(p2 - vec2(0, -.5), .875, .125);
    interior = sdf_union(interior, disk(p2, .25));
    interior = mix(interior, line(p, vec2(-.75, .5), vec2(.75, .5), .125), which);
#else
    p.y -= .5;
    const float
        LINE_SPACING = .375,
        LINE_HSIZE = .75;
    const vec2 CHECKMARK[] = vec2[3](vec2(-.5, 0.), vec2(-.25, -.375), vec2(.5, .375));
    const vec4 LINES[] = vec4[2*3](
        vec4(CHECKMARK[0],	CHECKMARK[1]),
        vec4(CHECKMARK[1],  CHECKMARK[2]),
        vec2(CHECKMARK[1]).xyxy,
        vec4(-LINE_HSIZE, -LINE_SPACING,	LINE_HSIZE, -LINE_SPACING),
        vec4(-LINE_HSIZE,  0.,				LINE_HSIZE,  0.),
        vec4(-LINE_HSIZE,  LINE_SPACING,	LINE_HSIZE,  LINE_SPACING)
    );
    
    float which = alternate(4., -.25, time/4.);
    which = elastic(2., smoothen(which));
	
    #define LINE(idx) line(p, mix(LINES[idx].xy, LINES[idx+3].xy, which), mix(LINES[idx].zw, LINES[idx+3].zw, which), .125)
    
    float interior = sdf_union(LINE(0), LINE(1));
    if (which > 0.)
        interior = sdf_union(interior, LINE(2));
#endif
    return sdf_union(bubble, interior);
}

float compilation_timing(vec2 p, float time) {
    p.x -= .5;
    float dist = circle(p, 1., 1./8.);
    float angle = -fract(time) * TAU + PI*.5;
    vec2 hand = vec2(cos(angle), sin(angle)) * .625;
    dist = sdf_union(dist, disk(p, 1./8.));
    dist = sdf_union(dist, disk(mod_polar(12., p)-vec2(.75,0.), 1./16.));
    dist = sdf_union(dist, line(p, vec2(0), hand, 1./8.));
    
    dist = sdf_union(dist, line(p, vec2(-.25, 1.25), vec2(.25, 1.25), .25));
    //dist = sdf_union(dist, line(p, vec2(0., 1.), vec2(0., 1.25), 1./4.));
    dist = sdf_union(dist, line(p * rotation(-45.), vec2(-1./12., 1.25), vec2(1./12., 1.25), 1.5/8.));
    //dist = sdf_union(dist, line(p * rotation(-45.), vec2(0., 1.15), vec2(0., 1.), 1.5/8.));
    
    const float LINES = 3.;
    float y = clamp(floor(p.y * LINES), -LINES, LINES - 1.) + .5;
    float len = hash(y - floor(time * 6.));
    dist = sdf_union(dist, line(p, vec2(-2., y/LINES), vec2(mix(-1.875, -1.25, len), y/LINES), 1./8.));
    //float len = mix(.0625, .375, hash(y - floor(time * 6.)));
    //dist = sdf_union(dist, box(p - vec2(-2.+len, y/LINES), vec2(len, 1./16.)));
    
    return dist;
}

float target(vec2 p, float time) {
    p = abs(p);
    if (p.y > p.x)
        p = p.yx;
    float dist = disk(p, 1./8.);
    dist = sdf_union(dist, line(p, vec2(3./8., 0), vec2(1, 0), 1./8.));
    return dist;
}

float mouse(vec2 p, float time) {
    float dist = box(p, vec2(.2, .5)) - .25;
    dist = sdf_exclude(dist, box(p - vec2(0, .5), vec2(.0625, .3)));
    dist = sdf_exclude(dist, abs(p.y - .25) - .0625);
    if (hash(floor(time*7.)) > .75 && p.x < 0. && p.y > .25)
        dist += .0625;
    return dist;
}

float fps_mode(vec2 p, float time) {
    p += smooth_noise2(time * 2.) - .5;
    float which = alternate(32., time/8.);
    return mix(target(p, time), mouse(p, time), which);
}

float page_title(vec2 p, float time) {
    const float
        THICKNESS		= .0625,
        MAX_TITLE_LEN	= .375;
    const vec2
        PAGE_SIZE		= vec2(.75, 1),
        SHADOW			= .25 * vec2(1,-1);

    float
        loop			= time / 2.,
        t				= fract(loop),
        fadein			= elastic(1., linear_step(.5, 1., t)),
        fadeout			= linear_step(0., .75, t),
        dist			= abs(box(p - SHADOW, PAGE_SIZE)) - THICKNESS,
        title_length	= elastic(2., linear_step(0., .25, t)) * MAX_TITLE_LEN * mix(.25, 1., hash(floor(loop)));

    dist = sdf_overlay_wire(dist, box(p - SHADOW * fadeout, PAGE_SIZE), THICKNESS);
	dist = sdf_union(dist, line(p - SHADOW * fadeout, vec2(-title_length, .75), vec2(title_length, .75), .125));
    if (fadein > 0.)
    	dist = sdf_overlay_wire(dist, box(p, PAGE_SIZE*fadein), THICKNESS);
    
    return dist;
}

float video(vec2 p, float time) {
    float dist = box(p, vec2(.625, .5)) - .25;
    dist = sdf_union(dist, sdTriangle(p, vec2(.75,0), vec2(1.25,.375), vec2(1.25,-.375)) - .125);
    dist = sdf_exclude(dist, circle(p, .3125, .125));
    p *= rotation(-45. * elastic(2., fract(time)));
    dist = sdf_exclude(dist, line(mod_polar(8., p), vec2(.375, 0), vec2(.4375, 0), 1.5/8.));
    return dist;
}

float tampermonkey(vec2 p) {
    p.x = abs(p.x);
    float dist = box(p, vec2(.5)) - .25;
    dist = sdf_exclude(dist, disk(p - vec2(.35, -.35), .3));
    return dist;
}

// Text handling ///////////////////////////////////////////////

// Keeping all string data in a giant table leads to a very compact representation
// for arbitrary length strings and even multi-line strings.
// Downside: long compilation times on Angle/DX

// TODO: some kind of compression, 2.75 bytes per char is... not good
const int STRING_DATA[]=int[637](0x98a7d0d0,0xd0959c99,0x9b829f87,0xd0979e99,0x9dd09e9f,0x85a1d089,0xd0959b91,0x94919883,
0xd0dc8295,0x81d0b9d0,0x9b939985,0x82d0899c,0x999c9195,0xd094958a,0x84919884,0x9d9f93d0,0x959c9980,0x9d9984d0,0x95878395,
0x97d09582,0x979e999f,0xd09f84d0,0x91d09592,0x9a919dd0,0x99d0829f,0x95858383,0x9f83d0dc,0x9ed0b9d0,0x95949595,0x9f84d094,
0xd09592d0,0x959c9291,0xd09f84d0,0x9984809f,0x958a999d,0xd09e9fd0,0x84919884,0x83998891,0x99a3d0de,0xd095939e,0xd0859f89,
0xd79e9193,0x809fd084,0x999d9984,0x87d0958a,0xd0849198,0xd0859f89,0xd79e9193,0x959dd084,0x82858391,0xb9d0dc95,0x94919dd0,
0xd091d095,0x93998581,0x9e91dd9b,0x9994dd94,0xd0898482,0x99829383,0x96d08480,0xa4d0829f,0x95809d91,0x9e9f9d82,0xd089959b,
0x84919884,0x918284d0,0x94959b93,0x9d9f93d0,0x919c9980,0x9e9f9984,0x9d9984d0,0xa7d0de95,0xd0988499,0x84919884,0x989e99d0,
0xdc949e91,0x87d0b9d0,0x91d08391,0xd0959c92,0x95d09f84,0x82958088,0x9e959d99,0x9987d084,0x86d09884,0x9f998291,0x93d08385,
0xd095949f,0x839e9f93,0x93858284,0xd0dc8384,0x8291959c,0x979e999e,0x879f98d0,0x9bd09f84,0xd0809595,0x809d9f93,0xd0959c99,
0x959d9984,0x9e99d083,0x959893d0,0xd0de9b93,0x8496b1d0,0x91d08295,0x999887d0,0xd0dc959c,0x8483d0b9,0x95848291,0x9f87d094,
0x8295949e,0xd0979e99,0x84959887,0xd0829598,0x9ed0829f,0x84d0849f,0x99d09598,0x8485809e,0x84959dd0,0xd0949f98,0x9c859f93,
0x839c9194,0x9592d09f,0x809d99d0,0x95869f82,0x83d0dc94,0x95939e99,0x9d9983d0,0xd0899c80,0x9b9f9f9c,0xd0979e99,0x859f8291,
0x99d0949e,0x9884d09e,0x9986d095,0x91858482,0x9f87d09c,0xd0949c82,0x9f869e99,0x9495869c,0x9f9cd091,0x969fd084,0x999c93d0,
0x9e999b93,0x9e91d097,0x8294d094,0x99979791,0x91d0979e,0x96d0949e,0xd0849c95,0x99949584,0xd083859f,0x809d9f93,0x94958291,
0xd09f84d0,0x91d09e91,0x91858493,0x9197d09c,0xb5de959d,0x8295849e,0xd0899dd0,0x9f939583,0xa4d0949e,0x95809d91,0x9e9f9d82,
0xd089959b,0x99829383,0xd0dc8480,0x99949491,0x91d0979e,0x998783d0,0x91989384,0xd0959c92,0xd0a3a0b6,0x95949f9d,0x919884d0,
0x87d0dc84,0x959e9598,0x9c92919e,0xd0dc9495,0x9f9c9c91,0xd0949587,0x84d0959d,0x9983d09f,0x899c809d,0x999c93d0,0x9fd09b93,
0xd095939e,0x99839e99,0x84d09594,0x93d09598,0x91869e91,0x9e91d083,0x9884d094,0x9dd09e95,0xd095869f,0x9d959884,0x9583859f,
0x958296d0,0xdc899c95,0x849987d0,0x84859f98,0x959884d0,0x95959ed0,0x9f84d094,0x95959bd0,0x9f98d080,0x9e99949c,0x9884d097,
0x8592d095,0x9e9f8484,0x879f94d0,0xd0d0de9e,0xd09c9cb1,0xd0839187,0x9c9c9587,0x949e91d0,0x9f9f97d0,0x83d0dc94,0xd0b9d09f,
0x82918483,0xd0949584,0x9e999884,0x979e999b,0x9f9291d0,0x9dd08485,0x95928991,0x9f9883d0,0x979e9987,0x96969fd0,0x959884d0,
0x94919883,0xd0de8295,0xd09598a4,0x9c998592,0x9e99dd84,0x949986d0,0x82d09f95,0x829f9395,0x979e9994,0x919596d0,0x95828584,
0xd08399d0,0x89829586,0x9e9198d0,0xd0dc8994,0xd0848592,0xd0959884,0x91969594,0x83849c85,0x99848495,0xd083979e,0xd79e9f94,
0x9f87d084,0x86d09b82,0xd0898295,0x9c9c9587,0x849987d0,0xd091d098,0x83999f9e,0x9d99d089,0xde959791,0x839cb1d0,0x99d0dc9f,
0x9f89d096,0x83d08285,0x95949198,0x8582d082,0x8491839e,0xc4c4c1d0,0x838096d0,0x83d0d0dc,0x9f94d09f,0x84d08395,0x86d09598,
0x9f959499,0x939582d0,0x9994829f,0xd0dc979e,0x949e91d0,0x919884d0,0xd083d784,0x84839f9d,0x9b999cd0,0xd0899c95,0x8295869f,
0x9c9c999b,0x8495a9de,0x9f9e91d0,0x82959884,0x829383d0,0xd0848099,0xd0839187,0x9e829f92,0x9fd0d0dc,0x84d0959e,0xd0849198,
0x93829f96,0x91d09495,0x8895d09e,0x93999c80,0x92d08499,0x91828499,0x96d09584,0x86d0829f,0x9f959499,0x9f939582,0x9e999482,
0x9cd0dc97,0x84999d99,0x84d09495,0x93d09598,0x85848091,0x96d09582,0x959d9182,0x95849182,0xd09f84d0,0x96d0c0c6,0xd0d08380,
0x919883d8,0xd0829594,0x9c998483,0x8582d09c,0x9e999e9e,0x8491d097,0x9c9c8596,0x958083d0,0xdcd99495,0x958385d0,0xd091d094,
0x95829f9d,0x839594d0,0x80998293,0x95869984,0x969594d0,0x849c8591,0x9d919ed0,0x9f96d095,0x9884d082,0x859fd095,0x84858084,
0x9c9996d0,0x91d0dc95,0x9c91949e,0x83d09f83,0x84829184,0x84d09495,0x83d09598,0x95949198,0x9887d082,0x82d09e95,0x829f9395,
0x979e9994,0x979592d0,0x91d09e91,0x80d0949e,0x95838591,0x8499d094,0x959887d0,0x8499d09e,0x949e95d0,0xd0de9495,0x9198a3d0,
0x84829594,0x99d0899f,0x8280d083,0x89848495,0x949491d0,0x99849399,0xd0de9586,0x9393bfd7,0x9f998391,0x9c9c919e,0xd0dcd789,
0x9996d0b9,0x9dd0949e,0x9c958389,0x9987d096,0x83d09884,0x82958695,0x91849c91,0x9fd08392,0xdc9e9580,0x9e85d0d0,0x959c9291,
0xd09f84d0,0x9c9c9584,0xd08491d0,0x9c97d091,0x95939e91,0x999887d0,0x99d09893,0x9887d083,0xde989399,0x9db1d0d0,0x91d0b9d0,
0x929184d0,0x919f98d0,0x82959482,0x93d0b9cf,0x949c859f,0x9f8483d0,0x9f84d080,0x999884d0,0x91d09b9e,0x84859f92,0x919884d0,
0x9f96d084,0xd091d082,0x959d9f9d,0xd0dc849e,0x9dd0829f,0x95928991,0x93d0b9d0,0x949c859f,0x998287d0,0x91d09584,0x98849f9e,
0x93838295,0x84809982,0xd09f84d0,0x9c809582,0xd0959391,0xd0959884,0x999d9196,0x8291999c,0x98a3d7d0,0x82959491,0xd0899f84,
0xb1a4b5b2,0x9184d0d7,0x9984d092,0xd0959c84,0x98849987,0x959e9fd0,0x8583d083,0x91d09893,0x82a0d783,0x9c99969f,0xd0ddd095,
0x949198a3,0x9f848295,0xd0dcd789,0x9791a0d7,0xd0c3d095,0x98a3d0dd,0x82959491,0xd7899f84,0x829fd0dc,0x98a3d7d0,0xd0959e91,
0x98a3d0dd,0x82959491,0xd7899f84,0xa9dedede,0x87d0859f,0x84d79e9f,0xbcb5b2d0,0xb5a6b5b9,0x919887d0,0x9198d084,0x9e958080,
0x959ed083,0xd18488,74,9546,19018,28489,37833,47135,0,51146,60619,70219,79820,89548,99263,0,107338,116811,126411,136011,
145611,155212,164938,174409,0,183755,193355,202957,212811,222406,0,231332,0xa2a4beb9,0xb3a5b4bf,0xa3b7beb9,0xb5b4b1b8,
0xa9bfa4a2,0xb5beb9d0,0xbeb5a3a3,0xbcb1b9a4,0xc0c2d0a3,0x9fb8c9c1,0xb5d0959d,0x99849994,0x95a49e9f,0x94958483,0x849987d0,
0x9d91a498,0x9d829580,0x959b9e9f,137,257803,259212,0x9d83d0b1,0xd09c9c91,0x9c9c9f93,0x99849395,0x9fd09e9f,0x98a3d096,
0x82959491,0xd0899f84,0x91958784,0x9fb3839b,0x9e959d9d,0x8280d084,0x95998695,0x8a91b487,0xd0959c8a,0x87d08385,0xd0988499,
0x82859f89,0x979184d0,0x9f9c93dd,0x979e9983,0x999b83d0,0xb3839c9c,0x99809d9f,0x9984919c,0x84d09e9f,0x9e999d99,0x9e91b397,
0x9fd084d7,0x9d998480,0xd0958a99,0x84919887,0x859f89d0,0x9e9193d0,0x9dd084d7,0x85839195,0x99b69582,0xdd848382,0x83829580,
0x99d09e9f,0x8485809e,0x949f9dd0,0x9195a295,0x9cd09893,0x9c958695,0xd0c0c3d0,0xa1d09e99,0x959b9185,0x91bdd0de,0xbd959289,
0xd095829f,0x93839594,0x84809982,0xd0958699,0x95979180,0x849984d0,0xb683959c,0x84d0829f,0x84d09598,0x98d09291,0x9482919f,
0xd0838295,0x9e9f9d91,0x8385d097,0x959499a6,0x9193d09f,0x82858480,0x8784d095,0x839b9195,0x989799b8,0x849992d0,0x95849182,
0xa0bdd0dc,0xc2b8dfc4,0x99d0c4c6,0x8583d096,0x829f8080,0xbe949584,0xd0b4b5b5,0xbfd0bfa4,0xbdb9a4a0,0xb3b5aab9,0xb9a0bdbf,
0xa4d0b5bc,0xa3b5bdb9,207,301968,304014,0xa4beb1a7,0xd0bfa4d0,0xb5a6b1b8,0xa2bfbdd0,0xbea5b6b5,0xa0a8b5d0,0xb9a2bfbc,
0xcfb7be,307217,309390,0xd7beb1b3,0xb5b7d0a4,0xbeb5d0a4,0xb8b7a5bf,0xa3d0b6bf,0xb5b4b1b8,0xa9bfa4a2,207,312336,314381,
0x859fa9d2,0x859f87d0,0xd79e949c,0x9597d084,0x9884d084,0x96d08399,0xd09d9f82,0xd0899e91,0x9598849f,0x8597d082,0x99a2d289,
0x82919893,0xdeb1d094,0x8291d0dc,0x84839984,317482,322834),STRBEGIN=7,STRLEN=(1<<STRBEGIN)-1,MULTILINE=1<<19,BACK_BLURB=
583326,INTRODUCING=251403,SHADERTOY_MODS=252827,HOME_EDITION=256268,FOR_TAMPERMONKEY=589570,SMALL_COLLECTION=262182,
COMMENT_PREVIEW=267023,DESC_COMMENT=268966,COMPILATION_TIMING=273810,DESC_TIMING=276133,FPS_MODE=280855,DESC_FPS=283806,
PAGE_TITLES=287644,DESC_TITLES=291229,VIDEO_CAPTURE=294932,DESC_VIDEO=297507,INTRO_OPTIMIZE=600834,INTRO_FPS=602114,
INTRO_TABS=603394,USER_QUOTE=605570;

struct Font {
    vec2 size;
    float weight;
    vec2 align;
    vec4 color;
};

Font default_font() {
    return Font(iResolution.y/vec2(40,16), 1., vec2(0), vec4(0,0,0,1));
}

int substr(int string, int start, int len) {
    return (string & ~STRLEN) + (start << STRBEGIN) + len;
}

int trim(int string, int begin, int end) {
    return string + (begin << STRBEGIN) - (begin + end);
}

float text(vec2 fragCoord, float px, Font font, int string) {
    fragCoord /= font.size;
    int num_lines = ((string & MULTILINE) != 0) ? string & STRLEN : 1;
    fragCoord.y += font.align.y * float(num_lines);
    int line = int(floor(fragCoord.y));
    if (uint(line) >= uint(num_lines))
        return 0.;
    line = num_lines - 1 - line;

    if ((string & MULTILINE) != 0)
        string = STRING_DATA[((string ^ MULTILINE) >> STRBEGIN) + line];
    fragCoord.x += font.align.x * float(string & STRLEN);
    int glyph	= int(floor(fragCoord.x)),
        begin	= string >> STRBEGIN,
		end		= begin + (string & STRLEN);
    if (uint(glyph) >= uint(end - begin))
        return 0.;

    glyph += begin;
    glyph = (STRING_DATA[glyph >> 2] >> ((glyph & 3) << 3)) & 255;
    fragCoord = fract(fragCoord);
    fragCoord.x = (fragCoord.x - .5) * .52 + .5;
    fragCoord += vec2(glyph & 15, glyph >> 4);
    
    px *= 2./length(font.size);
    float alpha = textureLod(iChannel0, fragCoord/16., 0.).w - .5;
    return 1. - smoothstep(-px*.5, px*.5, alpha - (font.weight - 1.) * px);
}

float text(vec2 fragCoord, Font font, int string) {
    return text(fragCoord, 1., font, string);
}

void print(inout vec3 fragColor, vec2 fragCoord, float px, Font font, int string) {
    fragColor.rgb = mix(fragColor.rgb, font.color.rgb, font.color.a * text(fragCoord, px, font, string));
}

void print(inout vec3 fragColor, vec2 fragCoord, Font font, int string) {
    print(fragColor, fragCoord, 1., font, string);
}

// QR code (no spoilers, please!) //////////////////////////////

const int QR[]=int[20](0x7c03b880,0xf2898161,0x4ca51277,0xd204ea20,0xa019c637,494897831,0xa096aae7,0xb9c1d9c5,0x9f1104a6
,349813413,498351938,0xb7954703,404798302,-60817579,0xf00aaa03,0xba27d3d5,0x749448ba,582772881,0x807d125f,765);

int qr_bit(vec2 uv) {
    ivec2 iuv = ivec2(floor(uv * 25.));
    if (max(uint(iuv.x), uint(iuv.y)) >= 25u)
        return 1;
    int index = iuv.y * 25 + iuv.x;
    return (QR[index >> 5] >> (index & 31)) & 1;
}

// Timing //////////////////////////////////////////////////////

const float
    T0_NEED_OPT		= .5,
    T1_NEED_OPT		= T0_NEED_OPT + 2.,
    T0_EXPLORE		= T1_NEED_OPT,
    T1_EXPLORE		= T0_EXPLORE + 2.,
    T0_TABS			= T1_EXPLORE,
    T1_TABS			= T0_TABS + 2.,
    T0_INTRODUCING	= T1_TABS,
    T1_INTRODUCING	= T0_INTRODUCING + 1.,
    T0_SPIN			= T1_INTRODUCING,
    T1_SPIN			= T0_SPIN + 1.
;

struct Anim {
    bool loaded;
    float time;
    float delay;
    float need_opt;
    float explore;
    float tabs;
    float intro;
    float spin;
} g_anim;

void init_anim() {
    // After the font texture gets loaded we want to skip the intro
    // if we're in thumbnail mode (since the first frame is a plain color)
    bool is_thumbnail	= all(lessThan(iResolution.xy, vec2(500, 281)));
    float time_bias		= is_thumbnail ? 10. : 0.;

    float time_loaded	= texelFetch(SETTINGS_CHANNEL, ivec2(0), 0).x;
    g_anim.loaded		= time_loaded >= 0.;
    g_anim.time			= g_anim.loaded ? max(0., iTime - time_loaded + time_bias) : 0.;

    g_anim.delay		= linear_step(0., T0_NEED_OPT, g_anim.time);
    g_anim.need_opt		= linear_step(T0_NEED_OPT, T1_NEED_OPT, g_anim.time);
    g_anim.explore		= linear_step(T0_EXPLORE, T1_EXPLORE, g_anim.time);
    g_anim.tabs			= linear_step(T0_TABS, T1_TABS, g_anim.time);
    g_anim.intro		= linear_step(T0_INTRODUCING, T1_INTRODUCING, g_anim.time);
    g_anim.spin			= smoothstep(T0_SPIN, T1_SPIN, g_anim.time);
}

// Scene rendering /////////////////////////////////////////////

const vec3
    BOX_SIZE	= vec3(13, 18, 2),
    BOX_MINS	= vec3(-BOX_SIZE.x*.5,	0,			-BOX_SIZE.z*.5),
    BOX_MAXS	= vec3( BOX_SIZE.x*.5,	BOX_SIZE.y,	 BOX_SIZE.z*.5),
    BOX_CENTER	= (BOX_MINS + BOX_MAXS) * .5
;

const int
    HIT_NOTHING		= -1,
    HIT_BOX_SIDE	= 0,
    HIT_GROUND		= 6
;

struct HitResult {
    int		id;
    float	fraction;
    vec3	normal;
    // filled after intersection
    vec3	point;
    float	px;
};
    
HitResult no_hit() {
    return HitResult(HIT_NOTHING, 1., vec3(0), vec3(0), 0.);
}

bool intersect_ground(vec3 ray_origin, vec3 rcp_ray_delta, inout HitResult result) {
    float t = -ray_origin.y * rcp_ray_delta.y;
    if (t < 0. || t > result.fraction)
        return false;

    result.id 			= HIT_GROUND;
    result.fraction		= t;
    result.normal		= vec3(0, 1, 0);

    return true;
}

bool intersect_box(vec3 ray_origin, vec3 rcp_ray_delta, vec3 aabb_mins, vec3 aabb_maxs, inout HitResult result)
{
    vec3 t0 = (aabb_mins - ray_origin) * rcp_ray_delta;
    vec3 t1 = (aabb_maxs - ray_origin) * rcp_ray_delta;
    vec4 tmin = vec4(min(t0, t1), 0.);
    vec4 tmax = vec4(max(t0, t1), result.fraction);
    float t = max_component(tmin);
    if (t > min_component(tmax))
        return false;
    
    int axis =
        (t == tmin.x) ? 0 :
    	(t == tmin.y) ? 1 :
    	2;
    
    bool side = rcp_ray_delta[axis] > 0.;
	result.id			= HIT_BOX_SIDE + (axis << 1) + int(side);
    result.fraction		= t;
    result.normal		= vec3(0);
    result.normal[axis]	= side ? -1. : 1.;
    
    return true;
}

void intersect(vec3 pos, vec3 dir, out HitResult hit) {
    hit = no_hit();
    
    vec3 rcp_dir = 1./dir;
    if (pos.y > 0.)
    	intersect_ground(pos, rcp_dir, hit);
    intersect_box(pos, rcp_dir, BOX_MINS, BOX_MAXS, hit);
    
    hit.point = pos + dir * hit.fraction;
    hit.px = hit.fraction * max_component(fwidth(dir));
}

void add_text(inout vec3 color, HitResult hit) {
    Font font = default_font();
    vec2 text_pos;
    int string = 0;
    
    if (hit.id == HIT_GROUND) {
        if (g_anim.time > T0_INTRODUCING) {
            float intro = smoothstep(.25, .75, g_anim.intro);
            float outro = linear_step(.125, 0., g_anim.spin);
            string			= INTRODUCING;
            text_pos		= vec2(0, BOX_MAXS.z + .5);
            font.size		= vec2(1.5, 3) * outro;
            font.align		= vec2(.5, 1. - min(intro, outro));
        	text_pos		= hit.point.xz - text_pos;
            if (text_pos.y < -.5)
                string = 0;
        } else if (g_anim.time > T0_TABS) {
            float f			= linear_step(1., .95, g_anim.tabs);
            string			= INTRO_TABS;
            text_pos		= vec2(BOX_MAXS.z + 4., 0);
            font.size		= vec2(3.*f, 7);
            font.align		= vec2(0, .5);
        	text_pos		= (hit.point.zx - text_pos) * vec2(1, -1);
        } else if (g_anim.explore > 0.) {
            float f			= 1.;
            string			= INTRO_FPS;
            text_pos		= vec2(BOX_MAXS.z + 4., 0);
            font.size		= vec2(3.*f, 7);
            font.align		= vec2(1, .5);
        	text_pos		= (hit.point.zx - text_pos) * vec2(-1, 1);
        } else if (g_anim.need_opt > 0.) {
            float f			= elastic(1., linear_step(0., .4, g_anim.need_opt));
            string			= INTRO_OPTIMIZE;
            text_pos		= vec2(BOX_MAXS.z + 4., 0);
            font.size		= vec2(3.*f, 7);
            font.align		= vec2(0, .5);
        	text_pos		= (hit.point.zx - text_pos) * vec2(1, -1);
        }
        font.color		= GROUND_TEXT_COLOR;
        font.weight		= 1.2;
    }
    
    if (uint(hit.id - HIT_BOX_SIDE) < 6u) {
        int side = hit.id - HIT_BOX_SIDE;
        if (side == 5) {
            if (hit.point.y < 3.) {
                string		= FOR_TAMPERMONKEY;
                text_pos	= vec2(BOX_MINS.x + 2., BOX_MINS.y + 1.5);
                font.align	= vec2(0, .5);
                font.size	= vec2(.17, .35);
                font.color	= TAMPERMONKEY_TEXT_COLOR;
                font.weight = 1.;
            } else if (hit.point.y < 8.5) {
                string		= HOME_EDITION;
                text_pos	= vec2(BOX_CENTER.x + 3.4, 8.5);
                font.align	= vec2(.5, 1);
                font.size	= vec2(.3, .7);
                font.color	= HOME_EDITION_COLOR;
                font.weight = .875;
            } else {
                text_pos	= BOX_CENTER.xy + vec2(1, -.5);
                font.size	= vec2(.55, 2.2);
                font.color	= BOX_TITLE_COLOR;
                font.weight	= 1.2;

                if (hit.point.x > text_pos.x) {
                    string			= substr(SHADERTOY_MODS, 23, 4);
                    font.size		= vec2(1, 6);
                    text_pos		+= vec2(.5, -.85);
                } else if (hit.point.y > text_pos.y + font.size.y) {
                    string			= substr(SHADERTOY_MODS, 0, 9);
                    font.align.x	= 1.;
                    text_pos.y		+= font.size.y;
                } else {
                    string			= substr(SHADERTOY_MODS, 10, 12);
                    font.align.x	= 1.;
                }
            }

            text_pos = hit.point.xy - text_pos;
        } else if (side == 4) {
            if (hit.point.y < 2.) {
                string		= USER_QUOTE;
                text_pos	= vec2(.7, 1.75);
                font.align	= vec2(.7, 1);
                font.size	= vec2(.15, .3);
                font.color	= USER_QUOTE_COLOR;
                font.weight = 1.1;
            } else {
                string		= BACK_BLURB;
                text_pos	= vec2(5.75, 14);
                font.align	= vec2(0, 1);
                font.size	= vec2(.15, .3);
                font.color	= BLURB_TEXT_COLOR;
                font.weight = .875;
            }
            
            text_pos = (hit.point.xy - text_pos) * vec2(-1, 1);
        } else if (side == 1) {
            string		= SHADERTOY_MODS;
            text_pos	= BOX_CENTER.yz;
            font.align	= vec2(.375, .5);
            font.size	= vec2(.3, .7);
            font.color	= BOX_TITLE_COLOR;
            font.weight = 1.;
            text_pos = (hit.point.yz - text_pos);
        }
    }
    
    if (string != 0)
    	print(color, text_pos, hit.px, font, string);
}

const float
    FOV = radians(30.),
    MAX_DRAW_DISTANCE = 1e4
;

vec3 unproject(vec2 uv) {
    return vec3(uv * tan(FOV*.5), 1.);
}

struct Camera {
    vec3 pos;
    vec2 angles; // yaw, pitch
};

Camera setup_camera() {
    Camera cam;
    
    float spin = 1. - pow(1. - g_anim.spin, 4.);
    float zoomout = 10.;
    zoomout = mix(zoomout, 1.5, elastic(1.5, g_anim.delay));
    zoomout = mix(zoomout, 0., 1.-elastic(1.5, 1.-around(0., 1., g_anim.time - T0_EXPLORE)));
    zoomout = mix(zoomout, 0., 1.-elastic(1., 1.-around(0., 1., g_anim.time - T0_TABS)));
    zoomout = mix(zoomout, 4., 1.-elastic(1., 1.-around(0., .5, g_anim.time - T0_INTRODUCING)));
    zoomout = mix(zoomout, 0., elastic(1., g_anim.intro));
    zoomout = mix(zoomout, 0., spin);
    
    cam.pos = vec3(0, 9, -60);
    cam.pos = mix(cam.pos, vec3(12, 9, -45), spin);
    cam.pos.z *= exp2(zoomout);
   
    cam.angles = vec2(90, -90);
    cam.angles.x += 180. * smoothen(g_anim.delay);
    cam.angles.x -= 180. * smoothstep(-.25, .25, g_anim.time - T1_NEED_OPT);
    cam.angles.x += 180. * smoothstep(-.25, .25, g_anim.time - T1_EXPLORE);
    cam.angles.x -= 270. * pow(smoothstep(0., .875, g_anim.intro), 2.);
    cam.angles += vec2(-315, 95) * spin;

    if (iMouse.z > 0.)
        cam.angles += vec2(180, 90) * (iMouse.xy - abs(iMouse.zw)) / iResolution.xy;
    
    const vec3 PIVOT = vec3(0, 9, 0);
    const float MIN_CAMERA_HEIGHT = .5;
    cam.pos -= PIVOT;
    cam.pos.yz *= rotation(cam.angles.y);
    cam.pos.xz *= rotation(cam.angles.x);
    cam.pos /= max(1., -cam.pos.y / (PIVOT.y - MIN_CAMERA_HEIGHT));
    cam.pos += PIVOT;

    return cam;
}

void spawn_ray(Camera camera, in vec2 fragCoord, out vec3 pos, out vec3 dir) {
    pos = camera.pos;
    dir = MAX_DRAW_DISTANCE * unproject((2.*fragCoord - iResolution.xy) / iResolution.y);
    dir.yz *= rotation(camera.angles.y);
    dir.xz *= rotation(camera.angles.x);
}

vec3 shade(vec3 pos, vec3 dir, HitResult hit) {
    vec3 color = BACKGROUND_COLOR.rgb;
    
    if (hit.id == HIT_GROUND) {
        float light = 1. / (1. + dot(hit.point, hit.point)/96.);
        color = mix(color, SPOTLIGHT_COLOR.rgb, light * SPOTLIGHT_COLOR.a);

        // authentically fake box shadow
        float dist = box(hit.point.xz, BOX_SIZE.xz * .5);
        color *= 1. - .75 / (1. + dist);
    }
    
    if (uint(hit.id - HIT_BOX_SIDE) < 6u) {
        const float
            QR_SIZE		= 2.7,
            QR_MARGIN	= .55,
            QR_DIST		= QR_MARGIN + QR_SIZE * .5
        ;
        const vec2 QR_POS = BOX_MINS.xy + QR_DIST;

        vec3 middle = BOX_COLOR2.rgb * (.5 + smooth_noise(hit.point.xy * vec2(.2, .31)));
        float dist;

        dist = abs(hit.point.y - sin(hit.point.x) * .3 - 6.);
        middle *= 1. + 1.3 * clamp(1. -  dist * .3, 0., 1.);
        dist = abs(hit.point.y - sin(hit.point.x * .7) * .5 - 6.5);
        middle *= 1. + .3 * clamp(1. - dist * .6, 0., 1.);

        dist = hit.point.y - 3.5 + sin(.1 + hit.point.x / 5.1);
        dist = min(dist, -(hit.point.y - 15. - .5 * sin(.7 + -hit.point.x / 5.1)));

        color = BOX_COLOR1.rgb;
        color = mix(color, middle, clamp(dist/hit.px, 0., 1.) * BOX_COLOR2.a);
        color = mix(color, BOX_LINE_COLOR.rgb, clamp(1. - (abs(dist) - .1) / hit.px, 0., 1.) * BOX_LINE_COLOR.a);

        int side = hit.id - HIT_BOX_SIDE;
        if (side == 4 && max_component(abs(hit.point.xy - QR_POS)) < QR_SIZE*.55) {
            vec2 qr_uv = (hit.point.xy - QR_POS + QR_SIZE*.5) / QR_SIZE;
            qr_uv.x = 1. - qr_uv.x;
            color = vec3(qr_bit(qr_uv));
        }
        
        if (side == 5) {
            const float TAMPERMONKEY_LOGO_SIZE = .5;
            dist = tampermonkey((hit.point.xy - vec2(-5.25, 1.5))/TAMPERMONKEY_LOGO_SIZE) * TAMPERMONKEY_LOGO_SIZE;
            color = mix(color, TAMPERMONKEY_TEXT_COLOR.rgb, clamp(1.-dist/hit.px, 0., 1.) * TAMPERMONKEY_TEXT_COLOR.a);
        }
    }

    add_text(color, hit);
    
    if (uint(hit.id - HIT_BOX_SIDE) < 6u) {
        // We want the box edges to appear slightly rounded
        const float FILLET = .1;
        vec3 bent_normal = normalize(hit.point - clamp(hit.point, BOX_MINS+FILLET, BOX_MAXS-FILLET));
        float NoL = clamp(-dot(normalize(dir), bent_normal), 0., 1.);
        color *= mix(NoL, 1., .25);		// diffuse + ambient
        color += pow(NoL, 32.) / 12.;	// specular
    }
    
    return color;
}

vec3 render_scene(Camera camera, vec2 fragCoord) {
    vec3 pos, dir;
    spawn_ray(camera, fragCoord, pos, dir);
    
    HitResult hit;
    intersect(pos, dir, hit);
    
    vec3 color = shade(pos, dir, hit);

#if ENABLE_REFLECTION
    pos.y = -pos.y;
    dir.y = -dir.y;
    
    // Note: we intersect the reflection unconditionally to avoid divergence
    // when computing the intersection footprint
    HitResult reflection;
    intersect(pos, dir, reflection);

    if (hit.id == HIT_GROUND) {
        // fakey mcfake
        float cos_theta = max(0., normalize(dir).y);
        float noise = mix(.5, 1., smooth_noise(hit.point.xz / 3.));
        float spec = mix(.0625, .5, pow(1. - cos_theta, 5.) * noise);
        if (uint(reflection.id - HIT_BOX_SIDE) < 6u)
            color = mix(color, shade(pos, dir, reflection), spec);
    }
#endif
    
    return color;
}

vec2 hammersley(int i, int total) {
    uint r = uint(i);
	r = ((r & 0x55u) << 1u) | ((r & 0xAAu) >> 1u);
	r = ((r & 0x33u) << 2u) | ((r & 0xCCu) >> 2u);
	r = ((r & 0x0Fu) << 4u) | ((r & 0xF0u) >> 4u);
    return vec2(float(i)/float(total), float(r)*(1./256.)) + .5/float(total);
}

vec3 render_scene_aa(Camera camera, vec2 fragCoord) {
    const int AA = clamp(ANTIALIAS, 1, 256);
    vec3 color = vec3(0);
    for (int i=0+NO_UNROLL; i<AA; ++i)
    	color += render_scene(camera, fragCoord + hammersley(i, AA) - .5);
    return color/float(AA);
}

////////////////////////////////////////////////////////////////

bool loading_screen(out vec4 fragColor, in vec2 fragCoord) {
    if (g_anim.loaded)
        return false;
    
    vec2  p			= fragCoord - .5 - floor(iResolution.xy * .5);
    float radius	= length(p),
		  dist		= abs(radius - 12.5) - 2.5,
    	  intensity	= clamp(1. - dist/fwidth(dist), 0., 1.),
    	  highlight	= floor(fract(-iTime) * 8.),
          segment	= fract(atan(p.y, p.x) / TAU) * 8.;
    intensity *= mix(.4, .84, floor(segment) == highlight);
    intensity *= smoothstep(0., 1.3, (.5-abs(fract(segment)-.5)) * radius);
    fragColor.rgb = vec3(intensity);
    fragColor.a = 1.;

    return true;
}

////////////////////////////////////////////////////////////////

void add_overlay(inout vec4 fragColor, in vec2 fragCoord) {
	float LINE_HEIGHT		= iResolution.y * 60./450.;
	float BASE_ICON_SIZE	= iResolution.y * 16./450.;
    vec2 FONT_SIZE			= iResolution.y / vec2(40, 16);
    
    vec2 slide_coord = fragCoord;
    slide_coord.x -= iResolution.x * (1. - elastic(.7, linear_step(.0, .9, g_anim.spin)));
    fragColor.rgb = mix(fragColor.rgb, OVERLAY_COLOR.rgb,
                        OVERLAY_COLOR.a * smoothstep(.35, .55, slide_coord.x/iResolution.x));
    
    Font font = default_font();
    font.color = OVERLAY_TEXT_COLOR;
    int string = 0;
    vec2 text_pos = iResolution.xy*vec2(.525, .55) + vec2(BASE_ICON_SIZE*-4., 2.*LINE_HEIGHT);
    
    float anim = 1. - smoothstep(.0, 1., g_anim.spin);
	float icon_size = BASE_ICON_SIZE * (1. - pow(anim, 4.));

    if (slide_coord.y >= text_pos.y) {
        font.size	= FONT_SIZE * .875;
        font.weight	= 1.1;
        string		= SMALL_COLLECTION;
    } else {
        text_pos.y -= BASE_ICON_SIZE * 1.25;
        text_pos.x += icon_size * 4.;

        const int LINES[] = int[10](COMMENT_PREVIEW, COMPILATION_TIMING, FPS_MODE, PAGE_TITLES, VIDEO_CAPTURE,
                                   DESC_COMMENT, DESC_TIMING, DESC_FPS, DESC_TITLES, DESC_VIDEO);

        float line = floor((text_pos.y - slide_coord.y) / LINE_HEIGHT);
        int line_index = int(line);
        if (uint(line_index) < 5u) {
            slide_coord.x -= line * LINE_HEIGHT * (1. - elastic(1., 1. - anim));

            text_pos.y -= (line + .5) * LINE_HEIGHT;
            font.align	= vec2(0);
            font.weight	= 1.;
            bool is_description = slide_coord.y < text_pos.y;
            if (is_description) {
                string			= LINES[5 + line_index];
                font.align.y	= 1.;
                font.size		= FONT_SIZE * .66 * vec2(1., elastic(.75, 1. - anim));
                font.color		= OVERLAY_TEXT2_COLOR;
            } else {
                font.size		= FONT_SIZE * .85;
                string			= LINES[line_index];
            }

            vec2 icon_pos = slide_coord - text_pos;
            icon_pos /= icon_size;
            icon_pos.x += 2.5;
    		float dist = 1e6,
                  icon_time = g_anim.time - T1_SPIN;
            switch (line_index) {
                case 0:  dist = comment_preview(icon_pos, icon_time); break;
                case 1:  dist = compilation_timing(icon_pos, icon_time); break;
                case 2:  dist = fps_mode(icon_pos, icon_time); break;
                case 3:  dist = page_title(icon_pos, icon_time); break;
                case 4:  dist = video(icon_pos, icon_time); break;
            }
            dist *= icon_size;
            fragColor.rgb = mix(fragColor.rgb, OVERLAY_ICON_COLOR.rgb, mask(dist) * OVERLAY_ICON_COLOR.a);
        }
    }

    if (string != 0)
    	print(fragColor.rgb, slide_coord - text_pos, font, string);
}

////////////////////////////////////////////////////////////////

float linear_to_srgb(float x) {
    return x <= 0.00031308 ? 12.92*x : 1.055*pow(x, 1./2.4)-.055;
}

vec3 linear_to_srgb(vec3 c) {
    return vec3(linear_to_srgb(c.r), linear_to_srgb(c.g), linear_to_srgb(c.b));
}

////////////////////////////////////////////////////////////////

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    init_anim();

    if (loading_screen(fragColor, fragCoord))
        return;

    fragColor.rgb = render_scene_aa(setup_camera(), fragCoord);
    fragColor.a = 1.;
    
    add_overlay(fragColor, fragCoord);
    
    // vignette
    vec2 uv = fragCoord / iResolution.xy - .5;
    fragColor.rgb *= 1. - smoothen(dot(uv, uv));
    
    // gamma correction
    fragColor.rgb = linear_to_srgb(fragColor.rgb);
    
    // dithering
    fragColor.rgb += (hash(fragCoord + iTime*PHI) - .5) / 128.;
}
