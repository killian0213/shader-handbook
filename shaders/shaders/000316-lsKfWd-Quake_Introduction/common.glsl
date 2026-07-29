// Common (common) — Quake / Introduction by adx
// https://www.shadertoy.com/view/lsKfWd

////////////////////////////////////////////////////////////////
// config.cfg //////////////////////////////////////////////////
////////////////////////////////////////////////////////////////

#define DEMO_MODE				0
#define DEMO_STAGE_DURATION		1.5
#define DEMO_MODE_HALFTONE		1		// 0=blue noise dither; 1=disks

#define GRAVITY					800.0
#define LOADING_TIME			2.5		// lower bound, in seconds
#define LIGHTMAP_AA_SAMPLES		8

// Used for mipmap generation, texture filtering and light shafts
// Lighting is performed in 'gamma' (non-linear) space for a more authentic look
#define USE_GAMMA_CORRECTION	2		// 0=off; 1=sRGB; 2=gamma 2.0

#define VIEW_DISTANCE			2048.0

// Debug switches //////////////////////////////////////////////

#define COMPILE_FASTER			1
#define USE_DISCARD				1

////////////////////////////////////////////////////////////////
// Implementation //////////////////////////////////////////////
////////////////////////////////////////////////////////////////

#if COMPILE_FASTER
	#define NO_UNROLL(k)		((k)+min(iFrame,0))
#else
	#define NO_UNROLL(k)		(k)
#endif

#if USE_DISCARD
	#define DISCARD				discard
#else
	#define DISCARD				return
#endif

// Speed up your shaders on Intel iGPUs with this one weird trick!
// No, seriously - on a Surface 3 (Atom x7-Z8700), wrapping global
// arrays in structs increased framerate from ~1.4 FPS to 45+!

// Side note: token pasting would be really handy right about now...
#define WRAP(struct_name, name, type, count)\
    const struct struct_name { type data[count]; } name = struct_name(type[count]

// Standard materials (cached in Buffer A) /////////////////////

#define MATERIAL_WIZMET1_2      0
#define MATERIAL_WBRICK1_5      1
#define MATERIAL_WIZMET1_1      2
#define MATERIAL_WIZ1_4         3
#define MATERIAL_CITY4_7        4
#define MATERIAL_BRICKA2_2      5
#define MATERIAL_CITY4_6        6
#define MATERIAL_WIZWOOD1_5     7
#define MATERIAL_TELEPORT       8
#define MATERIAL_WINDOW02_1     9
#define MATERIAL_COP3_4         10
#define MATERIAL_WATER1         11
#define MATERIAL_LAVA1          12
#define MATERIAL_WATER2         13
#define MATERIAL_DEM4_1         14
#define MATERIAL_QUAKE          15
#define MATERIAL_SKY1           16
#define MATERIAL_SKY1B          17
#define MATERIAL_FLAME          18
#define MATERIAL_ZOMBIE         19
#define NUM_MATERIALS           20

const int
	ATLAS_WIDTH                 = 512,
	ATLAS_HEIGHT                = 256;
// atlas usage: 100%

WRAP(Tiles,tiles,int,10)(1703961,1835035,393221,851975,67633173,917533,1441807,16777246,38470217,2031639));

vec4 get_tile(int index)
{
    int data = (tiles.data[index >> 1] >> ((index & 1) << 4)) & 4095;
    return vec4(ivec4(data & 7, (data >> 3) & 7, ((data >> 6) & 7) + 1, ((data >> 9) & 7) + 1) << 6);
}

// Extra materials /////////////////////////////////////////////

const int
    BASE_SHOTGUN_MATERIAL		= NUM_MATERIALS,
    MATERIAL_SHOTGUN_PUMP		= 0 + BASE_SHOTGUN_MATERIAL,
    MATERIAL_SHOTGUN_BARREL		= 1 + BASE_SHOTGUN_MATERIAL,
    MATERIAL_SHOTGUN_FLASH		= 2 + BASE_SHOTGUN_MATERIAL,
    NUM_SHOTGUN_MATERIALS		= 3,

    BASE_TARGET_MATERIAL		= BASE_SHOTGUN_MATERIAL + NUM_SHOTGUN_MATERIALS,
    NUM_TARGETS					= 8;

// Material helpers ////////////////////////////////////////////

const int
    MATERIAL_MASK_SKY			= (1<<MATERIAL_SKY1) | (1<<MATERIAL_SKY1B),
    MATERIAL_MASK_LIQUID		= (1<<MATERIAL_WATER1) | (1<<MATERIAL_WATER2) | (1<<MATERIAL_LAVA1) | (1<<MATERIAL_TELEPORT);

bool is_material_viewmodel(const int material)
{
    return uint(material-BASE_SHOTGUN_MATERIAL) < uint(NUM_SHOTGUN_MATERIALS);
}

bool is_material_balloon(const int material)
{
    return uint(material-BASE_TARGET_MATERIAL) < uint(NUM_TARGETS);
}

bool is_material_any_of(const int material, const int mask)
{
    return uint(material) < 32u && (mask & (1<<material)) != 0;
}

bool is_material_sky(const int material)
{
    return is_material_any_of(material, MATERIAL_MASK_SKY);
}

bool is_material_liquid(const int material)
{
    return is_material_any_of(material, MATERIAL_MASK_LIQUID);
}

////////////////////////////////////////////////////////////////

const vec3 LAVA_BOUNDS[]=vec3[2](vec3(704,768,-176),vec3(1008,1232,-112));

////////////////////////////////////////////////////////////////

const vec2	ATLAS_OFFSET		= vec2(0, 24);
const vec2	ATLAS_SIZE			= vec2(ATLAS_WIDTH, ATLAS_HEIGHT);
const float	ATLAS_CHAIN_WIDTH	= float(ATLAS_WIDTH) * 1.5;
const vec2	ATLAS_CHAIN_SIZE	= vec2(ATLAS_CHAIN_WIDTH, ATLAS_HEIGHT);
const int	MAX_MIP_LEVEL		= 6;

float exp2i(lowp int exponent)
{
    return intBitsToFloat(floatBitsToInt(1.) + (exponent << 23));
}

vec2 mip_offset(lowp int level)
{
    return level < 2 ?
        vec2(level, 0) :
    	vec2(1.5 - exp2i(1 - level), .5);
}

vec4 atlas_chain_bounds(float scale)
{
    return vec4(ATLAS_OFFSET, ATLAS_CHAIN_SIZE*scale);
}

vec4 atlas_mip0_bounds(float scale)
{
    return vec4(ATLAS_OFFSET, ATLAS_SIZE*scale);
}

////////////////////////////////////////////////////////////////

const float
	PI			= 3.1415926536,
	HALF_PI 	= PI * 0.5,
    TAU			= PI * 2.0,
    PHI			= 1.6180340888,
	SQRT2		= 1.4142135624,
	INV_SQRT2	= SQRT2 * 0.5;

// Rotations ///////////////////////////////////////////////////

mat3 rotation(vec3 angles)
{
    angles = radians(angles);
	float sy = sin(angles.x), sp = sin(angles.y), sr = sin(angles.z);
	float cy = cos(angles.x), cp = cos(angles.y), cr = cos(angles.z);
    
    return mat3
	(
        cr*cy+sy*sp*sr,		cr*sy-cy*sp*sr,		cp*sr,
        -sy*cp,				cy*cp,				sp,
        cr*sy*sp-cy*sr,		-cr*cy*sp-sy*sr,	cr*cp
	);
}

mat3 rotation(vec2 angles)
{
    angles = radians(angles);
	float	sy = sin(angles.x), sp = sin(angles.y);
	float	cy = cos(angles.x), cp = cos(angles.y);
   
    return mat3
	(
        cy,		sy,		0.,
        -sy*cp,	cy*cp,	sp,
        sy*sp,	-cy*sp,	cp
	);
}

mat2 rotation(float angle)
{
    angle = radians(angle);
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c,s,-s,c);
}

vec2 rotate(vec2 p, float angle)
{
    return rotation(angle)*p;
}

vec3 rotate(vec3 p, float yaw)
{
    p.xy = rotate(p.xy, yaw);
    return p;
}

vec3 rotate(vec3 p, vec2 angles)
{
    p.yz = rotate(p.yz, angles.y);
    p.xy = rotate(p.xy, angles.x);
    return p;
}

vec3 rotate(vec3 p, vec3 angles)
{
    return rotation(angles)*p;
}

////////////////////////////////////////////////////////////////

// TODO: make sure these values are used explicitly where needed

const float FOV = 90.;
const float FOV_FACTOR = tan(radians(FOV*.5));
const int FOV_AXIS = 0;

float scale_fov(float fov, float scale)
{
    return 2. * degrees(atan(scale * tan(radians(fov * .5))));
}

vec2 get_resolution_fov_scale(vec2 resolution)
{
    return resolution / resolution[FOV_AXIS];
}

vec2 compute_fov(vec2 resolution)
{
    vec2 scale = get_resolution_fov_scale(resolution);
    return vec2(scale_fov(FOV, scale.x), scale_fov(FOV, scale.y));
}

vec3 unproject(vec2 ndc)
{
    return vec3(ndc.x, 1., ndc.y);
}

vec3 project(vec3 direction)
{
    return vec3(direction.xz/direction.y, direction.y);
}

vec2 taa_jitter(int frame)
{
#if 0
    const float SCALE = 1./8.;
    const float BIAS = .5 * SCALE - .5;
    frame &= 7;
    int ri = ((frame & 1) << 2) | (frame & 2) | ((frame & 4) >> 2);
    return vec2(frame,ri)*SCALE + BIAS;
#else
    return vec2(0);
#endif
}

// xy=scale, zw=bias
vec4 get_viewport_transform(int frame, vec2 resolution, float downscale)
{
    vec2 ndc_scale = vec2(downscale);
    vec2 ndc_bias = vec2(0);//ndc_scale * taa_jitter(frame) / resolution.xy;
    ndc_scale *= 2.;
    ndc_bias  *= 2.;
    ndc_bias  -= 1.;
    ndc_scale.y *= resolution.y / resolution.x;
    ndc_bias.y  *= resolution.y / resolution.x;
    return vec4(ndc_scale, ndc_bias);
}

vec2 hammersley(int i, int total)
{
    uint r = uint(i);
	r = ((r & 0x55u) << 1u) | ((r & 0xAAu) >> 1u);
	r = ((r & 0x33u) << 2u) | ((r & 0xCCu) >> 2u);
	r = ((r & 0x0Fu) << 4u) | ((r & 0xF0u) >> 4u);
    return vec2(float(i)/float(total), float(r)*(1./256.)) + .5/float(total);
}

////////////////////////////////////////////////////////////////

bool test_flag(int var, int flag)
{
    return (var & flag) != 0;
}

////////////////////////////////////////////////////////////////

float max3(float a, float b, float c)
{
    return max(a, max(b, c));
}

float min3(float a, float b, float c)
{
    return min(a, min(b, c));
}

float min_component(vec2 v)		{ return min(v.x, v.y); }
float min_component(vec3 v)		{ return min(v.x, min(v.y, v.z)); }
float min_component(vec4 v)		{ return min(min(v.x, v.y), min(v.z, v.w)); }
float max_component(vec2 v)		{ return max(v.x, v.y); }
float max_component(vec3 v)		{ return max(v.x, max(v.y, v.z)); }
float max_component(vec4 v)		{ return max(max(v.x, v.y), max(v.z, v.w)); }

////////////////////////////////////////////////////////////////

int dominant_axis(vec3 nor)
{
    nor = abs(nor);
    float max_comp = max(nor.x, max(nor.y, nor.z));
    return
        (max_comp==nor.x) ? 0 : (max_comp==nor.y) ? 1 : 2;
}

////////////////////////////////////////////////////////////////

float smoothen(float x)			{ return x * x * (3. - 2. * x); }
vec2  smoothen(vec2 x)  		{ return x * x * (3. - 2. * x); }
vec3  smoothen(vec3 x)			{ return x * x * (3. - 2. * x); }

float quintic(float t)			{ return t * t * t * (t * (t * 6. - 15.) + 10.); }

float sqr(float x)				{ return x * x; }

////////////////////////////////////////////////////////////////

float length_squared(vec2 v) 	{ return dot(v, v); }
float length_squared(vec3 v) 	{ return dot(v, v); }
float length_squared(vec4 v) 	{ return dot(v, v); }

vec2 safe_normalize(vec2 v)		{ return all(equal(v, vec2(0))) ? vec2(0) : normalize(v); }
vec3 safe_normalize(vec3 v)		{ return all(equal(v, vec3(0))) ? vec3(0) : normalize(v); }

////////////////////////////////////////////////////////////////

float around(float center, float max_dist, float var)
{
    return 1. - clamp(abs(var - center)*(1./max_dist), 0., 1.);
}

float linear_step(float low, float high, float value)
{
    return clamp((value-low)*(1./(high-low)), 0., 1.);
}

float triangle_wave(float period, float t)
{
    return abs(fract(t*(1./period))-.5)*2.;
}

// UV distortions //////////////////////////////////////////////

vec2 skew(vec2 uv, float factor)
{
    return vec2(uv.x + uv.y*factor, uv.y);
}

// Gamma <-> linear ////////////////////////////////////////////

float linear_to_gamma(float f)
{
#if USE_GAMMA_CORRECTION == 2
    return sqrt(f);
#elif USE_GAMMA_CORRECTION == 1
    return f <= 0.0031308 ? f * 12.92 : (1.055 * pow(f, (1./2.4)) - 0.055);
#else
    return f;
#endif
}

vec3 linear_to_gamma(vec3 c)
{
    return vec3(linear_to_gamma(c.r), linear_to_gamma(c.g), linear_to_gamma(c.b));
}

vec4 linear_to_gamma(vec4 c)
{
    return vec4(linear_to_gamma(c.r), linear_to_gamma(c.g), linear_to_gamma(c.b), c.a);
}

float gamma_to_linear(float f)
{
#if USE_GAMMA_CORRECTION == 2
    return f * f;
#elif USE_GAMMA_CORRECTION == 1
    return f <= 0.04045 ? f * (1./12.92) : pow((f + 0.055) * (1./1.055), 2.4);
#else
    return f;
#endif
}

vec3 gamma_to_linear(vec3 c)
{
    return vec3(gamma_to_linear(c.r), gamma_to_linear(c.g), gamma_to_linear(c.b));
}

vec4 gamma_to_linear(vec4 c)
{
    return vec4(gamma_to_linear(c.r), gamma_to_linear(c.g), gamma_to_linear(c.b), c.a);
}

// Noise functions /////////////////////////////////////////////

// Dave Hoskins/Hash without Sine
// https://www.shadertoy.com/view/4djSRW

const vec4 HASHSCALE = vec4(.1031, .1030, .0973, .1099);

float hash1(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * HASHSCALE.x);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 hash3(vec3 p3)
{
	p3 = fract(p3 * HASHSCALE.xyz);
    p3 += dot(p3, p3.yxz + 19.19);
    return fract((p3.xxy + p3.yxx) * p3.zyx);
}

vec3 hash3(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * HASHSCALE.xyz);
    p3 += dot(p3, p3.yxz + 19.19);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

vec3 hash3(float p)
{
   vec3 p3 = fract(vec3(p) * HASHSCALE.xyz);
   p3 += dot(p3, p3.yzx + 19.19);
   return fract((p3.xxy + p3.yzz) * p3.zyx); 
}

vec4 hash4(float p)
{
	vec4 p4 = fract(vec4(p) * HASHSCALE);
    p4 += dot(p4, p4.wzxy + 19.19);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

vec4 hash4(vec2 p)
{
	vec4 p4 = fract(vec4(p.xyxy) * HASHSCALE);
    p4 += dot(p4, p4.wzxy + 19.19);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

// https://www.shadertoy.com/view/4dS3Wd
// By Morgan McGuire @morgan3d, http://graphicscodex.com
float hash(float n) { return fract(sin(n) * 1e4); }
float hash(vec2 p)  { return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }

// 2D Weyl hash #1, by MBR
// https://www.shadertoy.com/view/Xdy3Rc
// http://marc-b-reynolds.github.io/math/2016/03/29/weyl_hash.html
float weyl_hash(vec2 c)
{
    c *= fract(c * vec2(.5545497, .308517));
    return fract(c.x * c.y);
}

// by iq
vec2 hash2(vec2 p)
{
	return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

float random(vec2 p)
{
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

#define SMOOTH_NOISE_FUNC(p, hash_name)							\
	vec2 i = floor(p);											\
    p -= i;														\
    p *= p * (3. - 2.*p);										\
    float														\
    	s00 = hash_name(i),										\
        s01 = hash_name(i + vec2(1, 0)),						\
        s10 = hash_name(i + vec2(0, 1)),						\
        s11 = hash_name(i + vec2(1, 1));						\
	return mix(mix(s00, s01, p.x), mix(s10, s11, p.x), p.y)		\

float smooth_noise(vec2 p)
{
    SMOOTH_NOISE_FUNC(p, random);
}

float smooth_weyl_noise(vec2 p)
{
    SMOOTH_NOISE_FUNC(p, weyl_hash);
}

float smooth_noise(float f)
{
    float i = floor(f);
    f -= i;
    f *= f * (3. - 2.*f);
    return mix(hash(i), hash(i + 1.), f);
}

#define FBM_FUNC(uv, gain, lacunarity, noise)		\
	float accum = noise(uv);						\
    float octave_weight = gain;						\
    float total_weight = 1.;						\
													\
    uv *= lacunarity;								\
    accum += noise(uv) * octave_weight;				\
    total_weight += octave_weight;					\
													\
    uv *= lacunarity; octave_weight *= gain;		\
    accum += noise(uv) * octave_weight;				\
    total_weight += octave_weight;					\
													\
    uv *= lacunarity; octave_weight *= gain;		\
    accum += noise(uv) * octave_weight;				\
    total_weight += octave_weight;					\
													\
    return accum / total_weight						\

float turb(vec2 uv, float gain, float lacunarity)
{
    FBM_FUNC(uv, gain, lacunarity, smooth_noise);
}

float weyl_turb(vec2 uv, float gain, float lacunarity)
{
    FBM_FUNC(uv, gain, lacunarity, smooth_weyl_noise);
}

vec4 blue_noise(vec2 fragCoord, sampler2D channel, int frame)
{
    ivec2 uv = ivec2(fragCoord) + frame * ivec2(19, 23);
    return texelFetch(channel, uv & (textureSize(channel, 0) - 1), 0);
}

#define BLUE_NOISE(fragCoord) blue_noise(fragCoord, NOISE_CHANNEL, iFrame)

// SDF operations //////////////////////////////////////////////

float sdf_exclude(float from, float what)
{
    return max(from, -what);
}

float sdf_union(float a, float b)
{
    return min(a, b);
}

float sdf_intersection(float a, float b)
{
    return max(a, b);
}

// polynomial smooth min
// https://iquilezles.org/articles/smin
float sdf_smin(float a, float b, float k)
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

// SDF effects /////////////////////////////////////////////////

float sdf_mask(float sdf, float px)
{
    return clamp(1. - sdf/px, 0., 1.);
}

float sdf_mask(float sdf)
{
    float px = max(abs(dFdx(sdf)), abs(dFdy(sdf)));
    return sdf_mask(sdf, px);
}

vec2 sdf_normal(float sdf)
{
    vec2 n = vec2(dFdx(sdf), dFdy(sdf));
	float sqlen = dot(n, n);
    return n * ((sqlen > 0.) ? inversesqrt(sqlen) : 1.);
}

vec2 sdf_emboss(float sdf, float bevel, vec2 light_dir)
{
    float mask = sdf_mask(sdf);
    bevel = clamp(1. + sdf/bevel, 0., 1.);
    return vec2(mask * (.5 + sqrt(bevel) * dot(sdf_normal(sdf), light_dir)), mask);
}

// SDF generators //////////////////////////////////////////////

float sdf_disk(vec2 uv, vec2 center, float radius)
{
    return length(uv - center) - radius;
}

float sdf_ellipse(vec2 uv, vec2 center, vec2 r)
{
    return (length((uv-center)/r) - 1.) / min(r.x, r.y);
}

float sdf_centered_box(vec2 uv, vec2 center, vec2 size)
{
    return max(abs(uv.x-center.x) - size.x, abs(uv.y-center.y) - size.y);
}

float sdf_box(vec2 uv, vec2 mins, vec2 maxs)
{
    return sdf_centered_box(uv, (mins+maxs)*.5, (maxs-mins)*.5);
}

float sdf_line(vec2 uv, vec2 a, vec2 b, float thickness)
{
    vec2 ab = b-a;
    vec2 ap = uv-a;
    float t = clamp(dot(ap, ab)/dot(ab, ab), 0., 1.);
    return length(uv - (ab*t + a)) - thickness*.5;
}

float sdf_seriffed_box(vec2 uv, vec2 origin, vec2 size, vec2 top_serif, vec2 bottom_serif)
{
    float h = clamp((uv.y - origin.y) / size.y, 0., 1.);
    float xmul = h < bottom_serif.y ? mix(1.+bottom_serif.x, 1., sqrt(1.-sqr(1.-(h/bottom_serif.y)))) :
    		h > (1.-top_serif.y) ? 1.+top_serif.x*sqr(1.-(1.-h)/(top_serif.y)) :
            1.;
    return sdf_centered_box(uv, vec2(origin.x, origin.y+size.y*.5), vec2(size.x*xmul*.5, size.y*.5));
}

float sdf_nail(vec2 uv, vec2 top, vec2 size)
{
    const float head_flat_frac = .02;
    const float head_round_frac = .08;
    const float body_thickness = .5;

    float h = clamp((top.y - uv.y) / size.y, 0., 1.);
    float w = (h < head_flat_frac) ? 1. :
        (h < head_flat_frac + head_round_frac) ? mix( body_thickness, 1., sqr(1.-(h-head_flat_frac)/head_round_frac)) :
    	h > .6 ? ((1.05 - h) / (1.05 - .6)) * body_thickness : body_thickness;
    return sdf_centered_box(uv, top - vec2(0., size.y*.5), size*vec2(w, .5));
}

float sdf_Q(vec2 uv)
{
    float dist = sdf_disk(uv, vec2(.5, .67), .32);
    dist = sdf_exclude(dist, sdf_disk(uv, vec2(.5, .735), .27));
    dist = sdf_union(dist, sdf_nail(uv, vec2(.5, .59), vec2(.09, .52)));
    return dist;
}

float sdf_id(vec2 uv)
{
    float d = .06*sdf_ellipse(uv, vec2(.52, .38), vec2(.26, .28));
    d = sdf_exclude(d, .02*sdf_ellipse(uv, vec2(.57, .39), vec2(.12, .18)));
    d = sdf_union(d, sdf_centered_box(uv, vec2(.75, .51), vec2(.09, .30)));
    d = sdf_union(d, sdf_centered_box(uv, vec2(.80, .80), vec2(.04, .10)));
    d = sdf_smin(d, sdf_centered_box(uv, vec2(.78, .15), vec2(.12, .05)), .05);
    d = sdf_smin(d, sdf_centered_box(uv, vec2(.66, .81), vec2(.10, .05)), .05);
    float i = sdf_centered_box(uv, vec2(.25, .40), vec2(.09, .23));
    i = sdf_union(i, sdf_disk(uv, vec2(.24, .79), .09));
    i = sdf_smin(i, sdf_centered_box(uv, vec2(.25, .15), vec2(.15, .05)), .05);
    i = sdf_smin(i, sdf_centered_box(uv, vec2(.20, .60), vec2(.10, .03)), .05);
    return sdf_exclude(sdf_union(i, d), sdf_intersection(i, d));
}

vec2 add_knob(vec2 uv, float px, vec2 center, float radius, vec2 light_dir)
{
    float light = dot(normalize(uv-center), light_dir)*.5 + .5;
    float mask = sdf_mask(sdf_disk(uv, center, radius), px);
    return vec2(light, mask);
}

vec3 closest_point_on_segment(vec3 p, vec3 a, vec3 b)
{
    vec3 ab = b-a, ap = p-a;
    float t = clamp(dot(ap, ab)/dot(ab, ab), 0., 1.);
    return ab*t + a;
}

// QUAKE text //////////////////////////////////////////////////

float sdf_nail_v2(vec2 uv, vec2 top, vec2 size)
{
    const float
        head_flat_frac = .1,
    	head_round_frac = .1,
    	body_thickness = .5;

    float h = clamp((top.y - uv.y) / size.y, 0., 1.);
    float w = (h < head_flat_frac) ? 1. :
        (h < head_flat_frac + head_round_frac) ? mix( body_thickness, 1., sqr(1.-(h-head_flat_frac)/head_round_frac)) :
    	h > .6 ? ((1.05 - h) / (1.05 - .6)) * body_thickness : body_thickness;
    return sdf_centered_box(uv, top - vec2(0., size.y*.5), size*vec2(w, .5));
}

float sdf_Q_top(vec2 uv)
{
    uv.y -= .01;
    float dist = sdf_disk(uv, vec2(.5, .64), .36);
    dist = sdf_exclude(dist, sdf_disk(uv, vec2(.5, .74), .29));
    dist = sdf_union(dist, sdf_nail_v2(uv, vec2(.5, .61), vec2(.125, .57)));
    dist = sdf_exclude(dist, .95 - uv.y);
    return dist;
}

float sdf_U(vec2 uv)
{
    float sdf = sdf_seriffed_box(uv, vec2(.5, .3), vec2(.58, .6), vec2(.25, .35), vec2(-.7,.3));
    sdf = sdf_exclude(sdf, sdf_seriffed_box(uv, vec2(.5, .34), vec2(.3, .58), vec2(-.5, .35), vec2(-.75, .2)));
    sdf = sdf_exclude(sdf, sdf_centered_box(uv, vec2(.5, .3), vec2(.04, .15)));
    return sdf;
}

float sdf_A(vec2 uv)
{
    float h = linear_step(.3, .9, uv.y);
	float sdf = sdf_seriffed_box(uv, vec2(.5, .3), vec2(mix(.7, .01, h), .6), vec2(0.,.3), vec2(.2,.3));
    h = linear_step(.1, .65, uv.y);
	sdf = sdf_exclude(sdf, sdf_seriffed_box(uv, vec2(.45, .1), vec2(mix(.7, .01, h), .55), vec2(0.,.3), vec2(0.,.3)));
    sdf = sdf_union(sdf, sdf_centered_box(uv, vec2(.45, .47), vec2(.18, .02)));
    return sdf;
}

float sdf_K(vec2 uv)
{
	float sdf = sdf_seriffed_box(uv, vec2(.1, .3), vec2(.15, .6), vec2(.5,.2), vec2(.5,.2));
	sdf = sdf_disk(uv, vec2(.17, .17), .5);
	sdf = sdf_exclude(sdf, sdf_disk(uv, vec2(.1, -.05), .6));
    sdf = sdf_exclude(sdf, sdf_centered_box(uv, vec2(-.32, .3), vec2(.4, .8)));
    sdf = sdf_union(sdf, sdf_seriffed_box(uv, vec2(.1, .3), vec2(.15, .6), vec2(.5,.2), vec2(.5,.2)));
	sdf = sdf_union(sdf, sdf_seriffed_box(skew(uv+vec2(.25,-.3),-1.3), vec2(.1, .3), vec2(mix(.25, .01, linear_step(.5, 1., uv.y)), .3), vec2(0.,.3), vec2(.5,.3)));
    sdf = sdf_exclude(sdf, sdf_centered_box(uv, vec2(.5, .1), vec2(.4, .2)));
    return sdf;
}

float sdf_E(vec2 uv)
{
    float sdf_r = sdf_centered_box(uv, vec2(.66, .6), vec2(.1, .3));
    sdf_r = sdf_exclude(sdf_r, sdf_disk(uv, vec2(.58, .6), .25));
    sdf_r = sdf_exclude(sdf_r, sdf_centered_box(uv, vec2(.33, .6), vec2(.25, .35)));
    float sdf = sdf_seriffed_box(uv, vec2(.5, .3), vec2(.55, .6), vec2(.2, .15), vec2(-.5,.3));
    sdf = sdf_exclude(sdf, sdf_seriffed_box(uv, vec2(.5, .33), vec2(.3, .57), vec2(-.5, .15), vec2(-.75, .2)));
    sdf = sdf_exclude(sdf, sdf_centered_box(uv, vec2(.65, .6), vec2(.2, .35)));
    sdf = sdf_union(sdf, sdf_r);
    float t = linear_step(.4, .5, uv.x);
    sdf = sdf_union(sdf, sdf_centered_box(uv, vec2(.4, .6), vec2(.1, mix(.03, .01, t))));
    return sdf;
}

// Time ////////////////////////////////////////////////////////

const float
    CONSOLE_XFADE_DURATION	= 1.,
	CONSOLE_SLIDE_DURATION	= .5,
	CONSOLE_TYPE_DURATION	= 2.,
    WORLD_RENDER_TIME		= CONSOLE_XFADE_DURATION,
	INPUT_ACTIVE_TIME		= (CONSOLE_XFADE_DURATION + CONSOLE_SLIDE_DURATION + CONSOLE_TYPE_DURATION),
    
    // TODO: s/TIME/DURATION/
    LEVEL_COUNTDOWN_TIME	= 3.,
    BALLOON_SCALEIN_TIME	= .5,
    LEVEL_WARMUP_TIME		= LEVEL_COUNTDOWN_TIME + BALLOON_SCALEIN_TIME,
    HUD_TARGET_ANIM_TIME	= .25,
    
    THUMBNAIL_MIN_TIME		= 5.
;

float g_time = 0.;

void update_time(float bake_time, float uniform_time)
{
    if (bake_time > 0.)
    	g_time = uniform_time - bake_time;
    else
        g_time = -uniform_time;
}

#define UPDATE_TIME(lighting)		update_time(lighting.bake_time, iTime)

// GBuffer /////////////////////////////////////////////////////

const int GBUFFER_NORMAL_BITS = 8;
const float
    GBUFFER_NORMAL_SCALE = float(1 << GBUFFER_NORMAL_BITS),
    GBUFFER_NORMAL_MAX_VALUE = GBUFFER_NORMAL_SCALE - 1.;

// http://jcgt.org/published/0003/02/01/paper.pdf
vec2 signNotZero(vec2 v)
{
	return vec2((v.x >= 0.0) ? +1.0 : -1.0, (v.y >= 0.0) ? +1.0 : -1.0);
}

// Assume normalized input. Output is on [-1, 1] for each component.
vec2 vec3_to_oct(vec3 v)
{
	// Project the sphere onto the octahedron, and then onto the xy plane
	vec2 p = v.xy * (1.0 / (abs(v.x) + abs(v.y) + abs(v.z)));
	// Reflect the folds of the lower hemisphere over the diagonals
	return (v.z <= 0.0) ? ((1.0 - abs(p.yx)) * signNotZero(p)) : p;
}

vec3 oct_to_vec3(vec2 e)
{
    vec3 v = vec3(e.xy, 1.0 - abs(e.x) - abs(e.y));
    if (v.z < 0.0)
        v.xy = (1.0 - abs(v.yx)) * signNotZero(v.xy);
    return normalize(v);
}

float compress(vec2 v, vec2 noise)
{
    v = floor(clamp(v, 0., 1.) * GBUFFER_NORMAL_MAX_VALUE + noise);
    return v.y * GBUFFER_NORMAL_SCALE + v.x;
}

vec2 uncompress(float f)
{
    vec2 v = vec2(mod(f, GBUFFER_NORMAL_SCALE), f / GBUFFER_NORMAL_SCALE);
    return clamp(floor(v) / GBUFFER_NORMAL_MAX_VALUE, 0., 1.);
}

struct GBuffer
{
    vec3	normal;
    float	z;
    float	light;
    int		material;
    int		uv_axis;
    bool	edge;
};

vec4 gbuffer_pack(GBuffer g, vec2 noise)
{
    int props =
        (g.material 	<< 3) |
        (g.uv_axis 		<< 1) |
        int(g.edge);
    return vec4(compress(vec3_to_oct(g.normal) * .5 + .5, noise), g.light, g.z, float(props));
}

GBuffer gbuffer_unpack(vec4 v)
{
    int props = int(round(v.w));
    
    GBuffer g;
    g.normal	= oct_to_vec3(uncompress(v.x) * 2. - 1.);
    g.light		= v.y;
    g.z			= v.z;
    g.material	= props >> 3;
    g.uv_axis	= (props >> 1) & 3;
    g.edge		= (props & 1) != 0;
    
    return g;
}

// Lightmap encoding ///////////////////////////////////////////

const float LIGHTMAP_OVERBRIGHT = 2.;

struct LightmapSample
{
    vec4 weights;
    vec4 values;
};

LightmapSample empty_lightmap_sample()
{
    return LightmapSample(vec4(0), vec4(0));
}

LightmapSample decode_lightmap_sample(vec4 encoded)
{
    return LightmapSample(floor(encoded), fract(encoded) * LIGHTMAP_OVERBRIGHT);
}

vec4 encode(LightmapSample s)
{
    return floor(s.weights) + clamp(s.values * (1./LIGHTMAP_OVERBRIGHT), 0., 1.-1./1024.);
}

// Fireball ////////////////////////////////////////////////////

const vec3 FIREBALL_ORIGIN = vec3(864, 992, -168);

struct Fireball
{
    float launch_time;
    vec3 velocity;
};
    
void get_fireball_props(float time, out Fireball props)
{
    const float INTERVAL	= 5.;
    const float MAX_DELAY	= 2.;
    const float BASE_SPEED	= 600.;

    float interval_start = floor(time*(1./INTERVAL)) * INTERVAL;
    float delay = hash(interval_start) * MAX_DELAY;
    
    props.launch_time = interval_start + delay;
    props.velocity.x = hash(interval_start + .23) * 100. - 50.;
    props.velocity.y = hash(interval_start + .37) * 100. - 50.;
    props.velocity.z = hash(interval_start + .71) * 200. + BASE_SPEED;
}

vec3 get_fireball_offset(float time, Fireball props)
{
    float elapsed = max(0., time - props.launch_time);

    vec3 offset = elapsed * props.velocity;
    offset.z -= GRAVITY * .5 * elapsed * elapsed;
    offset.z = max(offset.z, 0.);
    
    return offset;
}

vec3 get_fireball_offset(float time)
{
    Fireball props;
    get_fireball_props(time, props);
    return get_fireball_offset(time, props);
}

float get_landing_time(Fireball props)
{
    return props.launch_time + props.velocity.z * (2./GRAVITY);
}

// Classic (dot) halftoning ////////////////////////////////////

vec2 halftone_point(vec2 fragCoord, float grid_size)
{
    const mat2 rot = INV_SQRT2 * mat2(1,1,-1,1);
    fragCoord = rot * fragCoord;
    vec2 fc2 = fragCoord * (1./grid_size);
    vec2 nearest = (floor(fc2) + .5) * grid_size;
    nearest.x += grid_size*.5 * step(.5, fract(fc2.y * .5)) * sign(round(fc2.x)*grid_size - fragCoord.x);
    return nearest * rot;
}

float halftone(vec2 fragCoord, vec2 center, float grid_size, float fraction)
{
    fraction *= grid_size * INV_SQRT2;
    return step(length_squared(fragCoord - center), sqr(fraction));
}

float halftone_classic(vec2 fragCoord, float grid_size, float fraction)
{
    vec2 point = halftone_point(fragCoord, grid_size);
    return halftone(fragCoord, point, grid_size, fraction);
}

// Demo mode ///////////////////////////////////////////////////

const int
	DEMO_STAGE_NONE			= 0,
	DEMO_STAGE_DEPTH		= 2,
	DEMO_STAGE_NORMALS		= 3,
	DEMO_STAGE_UV			= -1,	// disabled for now
	DEMO_STAGE_TEXTURES		= 4,
	DEMO_STAGE_LIGHTING		= 5,
	DEMO_STAGE_COMPOSITE	= 6,
	DEMO_STAGE_FPS			= 7,
	DEMO_NUM_STAGES			= 9;

int g_demo_stage = DEMO_STAGE_NONE;
int g_demo_scene = 0;

bool is_demo_mode_enabled(bool thumbnail)
{
#if !DEMO_MODE
    if (!thumbnail)
        return false;
#endif // !DEMO_MODE
    return true;
}

bool is_demo_stage_composite(int stage)
{
    return uint(stage - DEMO_STAGE_DEPTH) >= uint(DEMO_STAGE_COMPOSITE - DEMO_STAGE_DEPTH);
}

bool is_demo_stage_composite()
{
    return is_demo_stage_composite(g_demo_stage);
}

void update_demo_stage(vec2 fragCoord, vec2 resolution, float downscale, sampler2D noise, int frame, bool thumbnail)
{
    float time = g_time;

    if (!is_demo_mode_enabled(thumbnail))
    {
		g_demo_stage = DEMO_STAGE_NONE;
        return;
    }
    
    resolution *= 1./downscale;
    vec2 uv = clamp(fragCoord/resolution, 0., 1.);
        
    const float TRANSITION_WIDTH = .125;
    const vec2 ADVANCE = vec2(.5, -.125);

    time = max(0., time - INPUT_ACTIVE_TIME);
    time *= 1./DEMO_STAGE_DURATION;
    time += dot(uv, ADVANCE) - ADVANCE.y;

#if !DEMO_MODE_HALFTONE
    time += TRANSITION_WIDTH * sqrt(blue_noise(fragCoord, noise, frame).x);
#else
    const float HALFTONE_GRID = 8.;
    float fraction = clamp(1. - (round(time) - time) * (1./TRANSITION_WIDTH), 0., 1.);
    time += TRANSITION_WIDTH * halftone_classic(fragCoord, HALFTONE_GRID, fraction);
#endif // !DEMO_MODE_HALFTONE

    g_demo_stage = int(mod(time, float(DEMO_NUM_STAGES)));
    g_demo_scene = int(time * (1./float(DEMO_NUM_STAGES)));
}
	
#define UPDATE_DEMO_STAGE_EX(fragCoord, downscale, thumbnail)	\
	update_demo_stage(fragCoord, iResolution.xy, downscale, NOISE_CHANNEL, iFrame, thumbnail)

#define UPDATE_DEMO_STAGE(fragCoord, downscale, thumbnail)	\
	UPDATE_DEMO_STAGE_EX(fragCoord, downscale, thumbnail)

const struct DemoScene
{
    vec3 pos;
    vec2 angles;
}
g_demo_scenes[] = DemoScene[4]
(
    DemoScene(vec3(544,272,49),		vec2(0,5)),
    DemoScene(vec3(992,1406,196),	vec2(138,-26)),
    DemoScene(vec3(323,890,-15),	vec2(35.5,4)),
    //DemoScene(vec3(1012,453,73),	vec2(38.25,-8))
    DemoScene(vec3(1001,514,37),	vec2(42.3,.2))
);

DemoScene get_demo_scene()
{
    return g_demo_scenes[g_demo_scene % g_demo_scenes.length()];
}

////////////////////////////////////////////////////////////////

float get_viewmodel_offset(vec3 velocity, float bob_cycle, float attack)
{
    const float BOB_FRACTION = .003;
    float speed = length(velocity.xy);
    float bob = speed * BOB_FRACTION * (.3 + .7 * sin(TAU * bob_cycle));
    bob = clamp(bob, -.5, 1.);
    attack = attack * attack * -4.;
    return bob + attack;
}

////////////////////////////////////////////////////////////////
// Persistent state ////////////////////////////////////////////
////////////////////////////////////////////////////////////////

// https://www.shadertoy.com/view/XsdGDX

float is_inside(vec2 fragCoord, vec2 address)
{
    vec2 d = abs(fragCoord - (0.5 + address)) - 0.5;
    return -max(d.x, d.y);
}

// changed from original: range is half-open
float is_inside(vec2 fragCoord, vec4 address_range)
{
    vec2 d = abs(fragCoord - (address_range.xy + address_range.zw*0.5)) + -0.5*address_range.zw;
    return -max(d.x, d.y);
}

vec4 load(vec2 address, sampler2D channel)
{
    return texelFetch(channel, ivec2(address), 0);
}

void store(inout vec4 fragColor, vec2 fragCoord, vec2 address, vec4 value)
{
    if (is_inside(fragCoord, address) > 0.0) fragColor = value;
}

void store(inout vec4 fragColor, vec2 fragCoord, vec4 address_range, vec4 value)
{
    if (is_inside(fragCoord, address_range) > 0.0) fragColor = value;
}

void assign(out float dst,	float src)		{ dst = src; }
void assign(out float dst,	int src)		{ dst = float(src); }
void assign(out int dst,	int src)		{ dst = src; }
void assign(out int dst,	float src)		{ dst = int(src); }
void assign(out vec2 dst,	vec2 src)		{ dst = src; }
void assign(out vec3 dst,	vec3 src)		{ dst = src; }

// Serialization codegen macros ////////////////////////////////

#define FN_DEFINE_FIELD(pack, field_type, field_name, init)		field_type field_name;
#define FN_CLEAR_FIELD(pack, field_type, field_name, init)		assign(data.field_name, init);
#define FN_LOAD_FIELD(pack, field_type, field_name, init)		assign(data.field_name, v.pack);
#define FN_STORE_FIELD(pack, field_type, field_name, init)		assign(v.pack, data.field_name);

////////////////////////////////////////////////////////////////////////////////
#define DEFINE_STRUCT_BASE(type_name, field_list)								\
	struct type_name															\
    {																			\
        field_list(FN_DEFINE_FIELD)												\
	};																			\
	void from_vec4(out type_name data, const vec4 v)							\
	{																			\
        field_list(FN_LOAD_FIELD)												\
    }																			\
	void to_vec4(out vec4 v, const type_name data)								\
	{																			\
        v = vec4(0);															\
        field_list(FN_STORE_FIELD)												\
    }																			\
	void clear(out type_name data)												\
    {																			\
        field_list(FN_CLEAR_FIELD)												\
	}																			\
////////////////////////////////////////////////////////////////////////////////
#define DEFINE_STRUCT(type_name, address, field_list)							\
	DEFINE_STRUCT_BASE(type_name, field_list)									\
    void load(out type_name data, sampler2D channel)							\
	{																			\
        from_vec4(data, load(address, channel));								\
    }																			\
    void store(inout vec4 fragColor, vec2 fragCoord, const type_name data)		\
	{																			\
        if (is_inside(fragCoord, address) > 0.)									\
        	to_vec4(fragColor, data);											\
    }																			\
////////////////////////////////////////////////////////////////////////////////
#define DEFINE_STRUCT_RANGE(type_name, address_range, field_list)				\
	DEFINE_STRUCT_BASE(type_name, field_list)									\
    void load(vec2 offset, out type_name data, sampler2D channel)				\
	{																			\
        from_vec4(data, load(address_range.xy + offset, channel));				\
    }																			\
    void store(inout vec4 fragColor, vec2 fragCoord, const type_name data)		\
	{																			\
        if (is_inside(fragCoord, address_range) > 0.)							\
        	to_vec4(fragColor, data);											\
    }																			\
////////////////////////////////////////////////////////////////////////////////

#define LOAD(what) 				load(what, SETTINGS_CHANNEL)
#define LOADR(ofs, what)   		load(ofs, what, SETTINGS_CHANNEL)
#define LOAD_PREV(what)			if (iFrame==0) clear(what); else LOAD(what)
#define LOAD_PREVR(ofs, what)	if (iFrame==0) clear(what); else LOADR(ofs, what)

// Persistent state addresses //////////////////////////////////
        
const uvec2 LIGHTMAP_SIZE 			= uvec2(180,256);

const int
	NUM_MAP_AXIAL_BRUSHES           = 88,
	NUM_MAP_AXIAL_PLANES            = NUM_MAP_AXIAL_BRUSHES * 6,
	NUM_MAP_NONAXIAL_PLANES         = 502,
	NUM_MAP_NONAXIAL_BRUSHES        = 89,
	NUM_MAP_PLANES                  = NUM_MAP_AXIAL_PLANES + NUM_MAP_NONAXIAL_PLANES,
	NUM_MAP_PACKED_BRUSH_OFFSETS    = (NUM_MAP_NONAXIAL_BRUSHES + 3) / 4,
	NUM_LIGHTS                      = 61,
	NUM_LIGHTMAP_SAMPLES            = clamp(LIGHTMAP_AA_SAMPLES, 1, 128),
	NUM_LIGHTMAP_POSTPROCESS_STEPS  = 4,
	NUM_LIGHTMAP_REGIONS            = 4 /*RGBA*/,
	NUM_LIGHTMAP_FRAMES             = NUM_LIGHTMAP_SAMPLES * NUM_LIGHTMAP_REGIONS,
	NUM_WAIT_FRAMES                 = NUM_LIGHTMAP_FRAMES + NUM_LIGHTMAP_POSTPROCESS_STEPS;

const int
    NUM_MAP_COLLISION_BRUSHES		= 28,
    NUM_MAP_COLLISION_PLANES		= 167;

const vec2
	ADDR_POSITION					= vec2(0,0),
	ADDR_VELOCITY					= vec2(0,1),	// W=jump key state
	ADDR_GROUND_PLANE				= vec2(0,2),
	ADDR_CAM_POS					= vec2(1,0),
	ADDR_TRANSITIONS				= vec2(1,1),	// X=stair step offset; Y=bob phase; Z=attack phase; W=# of shots fired
	ADDR_CAM_ANGLES					= vec2(1,2),
    ADDR_ANGLES						= vec2(2,0),	// X=yaw; Y=pitch; Z=ideal pitch; W=autopitch delay

    ADDR_PREV_MOUSE					= vec2(3,1),
	ADDR_PREV_CAM_POS				= vec2(4,0),
	ADDR_PREV_CAM_ANGLES			= vec2(4,1),
	ADDR_RESOLUTION					= vec2(5,0),	// XY=resolution; Z=flags
	ADDR_ATLAS_INFO					= vec2(5,1),	// X=max mip; Y=lod
	ADDR_PERF_STATS					= vec2(6,0),	// X=filtered frame time; W=UI state
	ADDR_GAME_STATE					= vec2(6,1),	// X=level; Y=time left; Z=score; W=last shot #
	ADDR_LIGHTING					= vec2(6,2),
	ADDR_TIMING						= vec2(7,0),
    ADDR_MENU						= vec2(7,1),
    ADDR_OPTIONS					= vec2(7,2);

const vec4
	ADDR_RANGE_PHYSICS				= vec4(0,0, 3,3),
	ADDR_RANGE_PERF_HISTORY			= vec4(8,0, 192,1),
	ADDR_RANGE_SHOTGUN_PELLETS		= vec4(8,1, 24,1),
    ADDR_RANGE_TARGETS				= vec4(8,2, NUM_TARGETS+1,1),	// X=level; Y=last shot #; Z=hits
    ADDR_RANGE_LIGHTS				= vec4(0,3, NUM_LIGHTS,1),
    ADDR_RANGE_COLLISION_PLANES		= vec4(0,4, NUM_MAP_COLLISION_PLANES,1),
	ADDR_RANGE_NONAXIAL_PLANES		= vec4(0,8, 128,(NUM_MAP_NONAXIAL_PLANES+127)/128),
    ADDR_RANGE_LMAP_TILES			= vec4(0,ADDR_RANGE_NONAXIAL_PLANES.y + ADDR_RANGE_NONAXIAL_PLANES.w,
                                           128, (NUM_MAP_PLANES+127)/128),
    ADDR_RANGE_ATLAS_MIP0			= vec4(ATLAS_OFFSET, ATLAS_SIZE),
    ADDR_RANGE_ATLAS_CHAIN			= vec4(ATLAS_OFFSET, ATLAS_CHAIN_SIZE),
	ADDR_RANGE_PARAM_BOUNDS			= vec4(0,0, ATLAS_CHAIN_SIZE + ATLAS_OFFSET);

// Secondary buffer (Buffer C) addresses
const vec4
    ADDR2_RANGE_LIGHTMAP			= vec4(0,0,		LIGHTMAP_SIZE.x, LIGHTMAP_SIZE.y / 4u),
    ADDR2_RANGE_TEX_OPTIONS			= vec4(0,ADDR2_RANGE_LIGHTMAP.w, 144,24),
    ADDR2_RANGE_TEX_QUAKE			= vec4(0,ADDR2_RANGE_TEX_OPTIONS.y+ADDR2_RANGE_TEX_OPTIONS.w, 144,32),
    ADDR2_RANGE_FONT				= vec4(ADDR2_RANGE_TEX_OPTIONS.zy, 64,56),
    ADDR2_RANGE_PARAM_BOUNDS		= vec4(0,0, 	max(ADDR2_RANGE_LIGHTMAP.xy + ADDR2_RANGE_LIGHTMAP.zw,
                                                        max(ADDR2_RANGE_TEX_QUAKE.xy + ADDR2_RANGE_TEX_QUAKE.zw,
                                                           	ADDR2_RANGE_FONT.xy + ADDR2_RANGE_FONT.zw)));
const vec2
    SKY_TARGET_OFFSET				= vec2(NUM_TARGETS, 0);

const int
    RESOLUTION_FLAG_CHANGED			= 1 << 0,
    RESOLUTION_FLAG_THUMBNAIL		= 1 << 1;

// Persistent state structs (x-macros) /////////////////////////

#define PERF_STATS_FIELD_LIST(_)			\
    _(x, float,	smooth_frametime,	0.)		\
	_(w, float,	ui_state,			0.)
DEFINE_STRUCT(PerfStats, ADDR_PERF_STATS, PERF_STATS_FIELD_LIST)

#define TRANSITIONS_FIELD_LIST(_)			\
    _(x, float,	stair_step,		0.)			\
	_(y, float,	bob_phase,		0.)			\
	_(z, float,	attack,			0.)			\
	_(w, float,	shot_no,		0.)
DEFINE_STRUCT(Transitions, ADDR_TRANSITIONS, TRANSITIONS_FIELD_LIST)

#define TARGET_FIELD_LIST(_)				\
    _(x, float,	level,			0.)			\
	_(y, float,	shot_no,		0.)			\
	_(z, float,	hits,			0.)
DEFINE_STRUCT_RANGE(Target, ADDR_RANGE_TARGETS, TARGET_FIELD_LIST)
        
#define LIGHTING_FIELD_LIST(_)					\
	_(x, int,	num_lights,		NUM_LIGHTS)		\
	_(y, int,	num_tiles,		NUM_MAP_PLANES)	\
	_(z, float, bake_time,		0.)				\
	_(w, float, progress,		0.)
DEFINE_STRUCT(Lighting, ADDR_LIGHTING, LIGHTING_FIELD_LIST)

////////////////////////////////////////////////////////////////

#define GAME_STATE_FIELD_LIST(_)			\
    _(x, float,	level,			0.)			\
	_(y, float,	time_left,		0.)			\
	_(z, float,	targets_left,	0.)
DEFINE_STRUCT(GameState, ADDR_GAME_STATE, GAME_STATE_FIELD_LIST)

bool in_progress(GameState game_state) { return game_state.level > 0.; }

////////////////////////////////////////////////////////////////

const int
    OPTION_TYPE_SLIDER						= 0,
    OPTION_TYPE_TOGGLE						= 1,

	OPTION_FLAG_INVERT_MOUSE				= 1 << 0,
	OPTION_FLAG_SHOW_FPS					= 1 << 1,
	OPTION_FLAG_SHOW_FPS_GRAPH				= 1 << 2,
	OPTION_FLAG_SHOW_LIGHTMAP				= 1 << 3,
	OPTION_FLAG_SHOW_WEAPON					= 1 << 4,
	OPTION_FLAG_NOCLIP						= 1 << 5,
	OPTION_FLAG_MOTION_BLUR					= 1 << 6,
	OPTION_FLAG_TEXTURE_FILTER				= 1 << 7,
	OPTION_FLAG_LIGHT_SHAFTS				= 1 << 8,
	OPTION_FLAG_CRT_EFFECT					= 1 << 9,
    
    DEFAULT_OPTION_FLAGS					= OPTION_FLAG_SHOW_WEAPON | OPTION_FLAG_MOTION_BLUR;

#define MENU_STATE_FIELD_LIST(_)			\
	_(x, int,	selected,		0)			\
	_(y, int,	open,			0)
DEFINE_STRUCT(MenuState, ADDR_MENU, MENU_STATE_FIELD_LIST)

#define OPTIONS_FIELD_LIST(_)				\
	_(x, float, brightness,		5.)			\
	_(y, float, screen_size,	10.)		\
	_(z, float, sensitivity,	5.)			\
	_(w, int,	flags,			DEFAULT_OPTION_FLAGS)
DEFINE_STRUCT(Options, ADDR_OPTIONS, OPTIONS_FIELD_LIST)

struct MenuOption { int data; };
int get_option_type(MenuOption option)		{ return option.data & 1; }
int get_option_field(MenuOption option)		{ return (option.data >> 1) & 3; }
int get_option_range(MenuOption option)		{ return option.data >> 3; }

#define MENU_OPTION_SLIDER(index)			MenuOption(OPTION_TYPE_SLIDER | ((index) << 1))
#define MENU_OPTION_TOGGLE(index, bit)		MenuOption(OPTION_TYPE_TOGGLE | ((index) << 1) | ((bit) << 3))

const MenuOption
    // must match Options struct defined above
	OPTION_DEF_BRIGHTNESS					= MENU_OPTION_SLIDER(0),
    OPTION_DEF_SCREEN_SIZE					= MENU_OPTION_SLIDER(1),
	OPTION_DEF_SENSITIVITY					= MENU_OPTION_SLIDER(2),
    OPTION_DEF_INVERT_MOUSE					= MENU_OPTION_TOGGLE(3, OPTION_FLAG_INVERT_MOUSE),
    OPTION_DEF_SHOW_FPS						= MENU_OPTION_TOGGLE(3, OPTION_FLAG_SHOW_FPS),
    OPTION_DEF_SHOW_FPS_GRAPH				= MENU_OPTION_TOGGLE(3, OPTION_FLAG_SHOW_FPS_GRAPH),
    OPTION_DEF_MOTION_BLUR					= MENU_OPTION_TOGGLE(3, OPTION_FLAG_MOTION_BLUR),
    OPTION_DEF_TEXTURE_FILTER				= MENU_OPTION_TOGGLE(3, OPTION_FLAG_TEXTURE_FILTER),
    OPTION_DEF_SHOW_LIGHTMAP				= MENU_OPTION_TOGGLE(3, OPTION_FLAG_SHOW_LIGHTMAP),
    OPTION_DEF_SHOW_WEAPON					= MENU_OPTION_TOGGLE(3, OPTION_FLAG_SHOW_WEAPON),
    OPTION_DEF_NOCLIP						= MENU_OPTION_TOGGLE(3, OPTION_FLAG_NOCLIP),
    OPTION_DEF_LIGHT_SHAFTS					= MENU_OPTION_TOGGLE(3, OPTION_FLAG_LIGHT_SHAFTS),
    OPTION_DEF_CRT_EFFECT					= MENU_OPTION_TOGGLE(3, OPTION_FLAG_CRT_EFFECT),

    // must match string table used in draw_menu (Image tab)
	OPTION_DEFS[] = MenuOption[]
	(
        OPTION_DEF_SENSITIVITY,
        OPTION_DEF_INVERT_MOUSE,
        OPTION_DEF_BRIGHTNESS,
        OPTION_DEF_SCREEN_SIZE,
        OPTION_DEF_SHOW_FPS,
        OPTION_DEF_SHOW_FPS_GRAPH,
        OPTION_DEF_TEXTURE_FILTER,
        OPTION_DEF_MOTION_BLUR,
        OPTION_DEF_LIGHT_SHAFTS,
        OPTION_DEF_CRT_EFFECT,
        OPTION_DEF_SHOW_LIGHTMAP,
        OPTION_DEF_SHOW_WEAPON,
        OPTION_DEF_NOCLIP
	)
;

const int NUM_OPTIONS						= OPTION_DEFS.length();
MenuOption get_option(int index)			{ return OPTION_DEFS[index]; }

float get_downscale(Options options)		{ return max(6. - options.screen_size * .5, 1.); }

////////////////////////////////////////////////////////////////

const int
    TIMING_FLAG_PAUSED						= 1 << 0;

#define TIMING_FIELD_LIST(_)				\
    _(x, float,	anim,			0.)			\
	_(y, float,	prev,			0.)			\
	_(z, int,	flags,			0)
DEFINE_STRUCT(Timing, ADDR_TIMING, TIMING_FIELD_LIST)

////////////////////////////////////////////////////////////////

vec4 load_camera_pos(sampler2D settings, bool thumbnail)
{
    if (!is_demo_mode_enabled(thumbnail))
        return load(ADDR_CAM_POS, settings);
    return vec4(get_demo_scene().pos, 0);
}

vec4 load_camera_angles(sampler2D settings, bool thumbnail)
{
    if (!is_demo_mode_enabled(thumbnail))
        return load(ADDR_CAM_ANGLES, settings);
    return vec4(get_demo_scene().angles, 0, 0);
}
