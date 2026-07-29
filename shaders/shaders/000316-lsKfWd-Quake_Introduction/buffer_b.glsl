// Buffer B (buffer) — Quake / Introduction by adx
// https://www.shadertoy.com/view/lsKfWd

////////////////////////////////////////////////////////////////
// Buffer B: map/lightmap rendering
// - ray-tracing for the world brushes
// - ray-marching for the entities
// - GBuffer output
////////////////////////////////////////////////////////////////

#define RENDER_WORLD				3		// 0=off; 1=axial brushes; 2=non-axial brushes; 3=all
#define RENDER_ENTITIES				1
#define RENDER_WEAPON				1

#define USE_PARTITION				3		// 0=off; 1=axial brushes; 2=non-axial brushes; 3=all
#define USE_ENTITY_AABB				1

#define DEBUG_ENTITY_AABB			0

#define ENTITY_RAYMARCH_STEPS		96
#define ENTITY_RAYMARCH_TOLERANCE	1.0
#define ENTITY_LIGHT_DIR			normalize(vec3(.5, 1, -.5))
#define ENTITY_MIN_LIGHT			0.3125
#define DITHER_ENTITY_NORMALS		1

#define LIGHTMAP_FILTER				1		// 0=off; 1=linear, 1/16 UV increments; 2=linear
#define QUANTIZE_LIGHTMAP			24		// only when texture filtering is off; comment out to disable
#define QUANTIZE_DYNAMIC_LIGHTS		32		// only when texture filtering is off; comment out to disable

// Lightmap baking settings: changing these requires a restart
#define LIGHTMAP_HEIGHT_OFFSET		0.1
#define LIGHTMAP_EXTRAPOLATE		1.0		// max distance from brush edge, in texels

#define LIGHTMAP_SCALEDIST			1.0
#define LIGHTMAP_SCALECOS			0.5
#define LIGHTMAP_RANGESCALE			0.7

////////////////////////////////////////////////////////////////
// Implementation //////////////////////////////////////////////
////////////////////////////////////////////////////////////////

#define BAKE_LIGHTMAP				1
#define COMPRESSED_BRUSH_OFFSETS	1
#define SETTINGS_CHANNEL			iChannel0
#define NOISE_CHANNEL				iChannel2

float g_downscale = 2.;
float g_animTime = 0.;

vec4 load(vec2 address)
{
    return load(address, SETTINGS_CHANNEL);
}

////////////////////////////////////////////////////////////////
//
// World data
//
// Generated from a trimmed/tweaked version of
// the original map by John Romero
// https://rome.ro/news/2016/2/14/quake-map-sources-released
//
// Split between Buffer A and B to even out compilation time
////////////////////////////////////////////////////////////////

const vec3 AXIAL_MINS=vec3(48,176,-192), AXIAL_MAXS=vec3(1040,1424,336);

WRAP(AxialBrushes,axial_brushes,int,NUM_MAP_AXIAL_BRUSHES*2)(1073156,8464628,8431646,0xa8b822,8431622,0xa8b80a,8431854,0xa8b8f2,
8431830,0xa8b8da,8426512,0xa89c18,8426720,0xa89ce8,8439008,0xa8cce8,8438800,0xa8cc18,31483956,33630264,31484096,33630404,
31483960,33583296,8419328,25241604,8419572,25241848,0xc0003c,25168060,0xb07854,0xc088a4,8390660,0xc060f4,0xc02874,0xc44884,
0x998890,0xaa089c,0x99885c,0xaa0868,1134788,7430356,0x99886c,0xaa088c,1167556,8519892,8513700,9572592,1124376,7473180,75804,
1183984,1140816,0xe18858,1181720,7477308,1183804,9574562,8493060,0xa1b808,1151088,0x99a088,1171568,0x99f088,1126508,7422092,
7415900,8472732,7415872,8523852,7415816,8523836,1183906,9574640,1157280,0xe1c8a4,3745880,3805344,5318820,5378288,3221532,3280976
,29435992,29968544,1124432,25249884,34154584,34687136,1124588,34687220,29435916,34687064,29436064,34687212,1124508,25249960,
8464384,34686988,29960280,34162848,1132624,28403800,8472580,28416008,23160912,28411992,23173124,28424200,0xe1a8a2,23185572,
1132704,33663140,23177376,33671332,0xa19800,23181316,0xe16850,23169110,1149008,28446808,8501252,32663560,1132784,33712372,
1165472,33689764,0xa2109c,25309352,0xa21050,25309276,9572360,29503500,0xa210ec,29503728,29495304,33698032,0xa23054,32139352,
8521736,9594940,0xa230a0,33712292,19028166,20078802,0xb258c6,0xc260d2,0xb258c0,20078790,0xb258d2,20078808,0xb25870,0xc26088,
19028080,20078728,0xc25870,19030134,0xb25834,20078650,0xc25882,19030152,0xb25828,0xc26034,19028008,20078644,0xb25822,20078632,
0xc25c28,19030068,0xc25c76,19030146,0xc25cc6,19030226,0xa26808,29520034,0xa268a4,33714416));

WRAP(Brushes,brushes,int,NUM_MAP_PACKED_BRUSH_OFFSETS)(18822,805254,1591686,2378118,3164550,3950982,4737414,5522822,6241605,
6931846,7685510,8439174,9160005,9913734,0xa23d45,0xac4966,0xb7c565,0xc35186,0xcfbd45,0xd9c166,0xe43d45,0xeebd45,0xf894a5));

#define M(x)  x*0x111111,
#define M2(x) M(x)M(x)
#define M4(x) M2(x)M2(x)
#define M8(x) M4(x)M4(x)

const int NUM_MATERIAL_ENTRIES = 162;
WRAP(Materials,materials,int,NUM_MATERIAL_ENTRIES)(1315089,M8(2)M2(0)M(0)M2(1)M(1)M2(6)M(10)M4(0)M2(0)M4(1)M2(1)M2(3)M(3)M2(4)M(
4)M(5)1118485,M(11)M(12)M(13)M8(0)61440,M4(1)5592549,1118485,1118485,M(9)1118494,M2(1)M(5)1118485,M4(0)M(0)M(1)M(4)1118485,M8(0)
M4(0)M2(8)M(8)M(1)M(5)M8(2)M8(2)M4(6)M4(0)M(0)M4(3)M(3)M(0)17<<16,M(1)7829265,7,3355440,M(3)7829363,M(0)M2(3)489335,1<<22,M(4)
1328196,M2(1)M(1)4473921,68,M8(0)1118464,4473921,5592388,M(5)M4(0)M(7)M2(0)M(0)M2(7)1911,0));

// Geometry partitions /////////////////////////////////////////

const int
    NUM_AXIAL_NODES = 10,
    NUM_NONAXIAL_NODES = 10
;

struct PackedNode
{
    int begin;
    int end;
};
    
const struct BVL
{
    PackedNode axial[NUM_AXIAL_NODES];
    PackedNode nonaxial[NUM_NONAXIAL_NODES];
}
bvl = BVL
(
	#define N PackedNode

	N[10](N(687940864,857812285),N(855714048,991967529),N(301999361,688800572),N(17306113,0x90b1a3d),N(68609,17311037),N(
	989931777,0x3f204d3d),N(289<<19,304096574),N(0x3f084102,0x47204d3c),N(0x470b4b08,0x56134c36),N(0x560a4d02,0x58204e3c)),

	N[10](N(721429511,856174140),N(856041751,0x3c0a3937),N(0x4c132524,0x531b3c3d),N(461825,336403005),N(0x41162501,
	0x4c1e4d28),N(587663104,656286989),N(654772016,723395901),N(0x3c003902,0x41094d3c),N(336003073,589238333),N(0x53163d24,
	0x591b4d3b))

    #undef N
);

const vec3
	AXIAL_BVL_MINS      = vec3(48,176,-192),
	NONAXIAL_BVL_MINS   = vec3(48,176,-176);

struct Node
{
    vec3 mins;
    int begin;
    vec3 maxs;
    int end;
};
    
ivec3 unpack888(int n)
{
    return (ivec3(n) >> ivec3(0,8,16)) & 255;
}

Node unpack(const PackedNode p, vec3 bias)
{
    Node n;
    n.mins	= vec3(unpack888(p.begin)) * 16. + bias;
    n.begin	= int(uint(p.begin) >> 24);
    n.maxs	= vec3(unpack888(p.end)) * 16. + bias;
    n.end	= int(uint(p.end >> 24));
    return n;
}

// Lightmap UV-mapping /////////////////////////////////////////

const float LIGHTMAP_SCALE = 16.;
const vec2 LIGHTMAP_OFFSET = vec2(-169.5,-260.5);
#define _ -1
WRAP(LightmapOffsets,LIGHTMAP_OFFSETS,int,NUM_MAP_PLANES)(_,_,121456,_,145069,_,6702,2603,4629,6677,24073,_,8747,_,6169,12800,
22534,_,_,12831,12870,12873,25655,_,2606,4654,8774,10822,20096,_,12843,_,4120,6168,19465,_,_,8238,10316,12364,22592,_,_,16415,
16442,16448,22592,_,16427,_,16405,4124,25609,_,21180,22716,_,63045,57526,86682,18108,19644,_,21639,74457,52412,_,_,106628,115243
,123991,123956,75844,_,_,_,_,_,_,75867,_,_,_,_,_,_,104492,_,_,_,7190,2588,78447,_,78953,_,_,_,120944,_,139376,_,_,_,25763,_,
16450,_,_,64101,18491,2141,56466,47767,64067,_,7333,8869,47758,65157,7772,22100,22107,_,_,_,_,64084,29749,29758,56466,65170,
20087,24183,_,15974,_,_,_,_,_,76910,100930,100970,72404,_,_,_,_,_,_,_,_,_,135347,_,121398,32399,_,_,56335,_,11379,_,_,6747,_,_,_
,_,_,41142,_,_,20040,_,_,_,100912,_,41528,3205,3185,41572,_,_,3218,24721,41565,1710,_,_,_,_,33369,_,_,_,_,_,52318,_,79488,79471,
94282,95306,_,_,119823,119827,76500,_,_,_,119827,119841,_,_,_,1743,_,_,39575,46743,_,_,60585,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_
,_,_,_,87092,87111,_,82502,8921,19127,72316,72304,_,_,_,_,89121,75861,82521,_,_,73433,56551,39655,106038,_,_,_,72300,72280,85572
,85552,_,_,69265,72277,85569,85629,32435,19122,72327,72331,_,_,38078,_,35978,24720,46624,_,_,_,66175,66156,_,_,22749,68806,89615
,_,_,_,10427,_,35970,_,_,_,29274,32842,_,_,_,148495,32838,_,_,_,_,53323,22651,27259,_,_,_,_,89784,89771,89727,_,50815,_,35471,
138298,_,_,87586,101952,29845,_,_,_,_,_,36467,31859,_,_,_,_,55008,68832,_,68772,_,_,75966,_,_,24717,_,_,_,89821,_,_,_,_,89764,
89774,_,89729,_,_,45230,102037,45190,29832,_,_,16057,45235,37501,29821,_,_,76360,_,52865,52863,_,_,_,43209,43174,14004,_,_,_,_,
128056,125496,_,152750,64717,76884,_,_,_,_,1216,_,_,77857,54379,_,76900,76892,_,_,_,_,_,_,_,6246,47215,80432,_,_,_,35906,80459,_
,7820,51789,_,21609,69163,_,_,46303,_,46639,105665,_,_,_,_,3185,80456,_,_,_,_,39487,_,80465,49404,_,_,12391,_,_,_,10410,_,12358,
_,_,_,32508,_,9297,_,_,_,_,_,79373,54282,_,_,_,_,15881,_,55314,29853,_,_,16961,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,
109639,158323,_,_,_,_,76929,_,_,_,7708,14929,12877,28355,29891,_,_,8786,10834,29245,29249,132145,20116,3130,5175,23087,96365,
32876,27716,_,23078,3189,23082,54845,38970,23073,15934,37994,28733,48696,29251,23065,4160,23121,37473,16950,_,_,7686,27666,29696
,10303,_,7689,_,32265,32268,_,_,3105,8733,32774,36352,6184,_,14878,16926,36369,36373,43047,25614,7226,11319,21038,_,21121,28163,
13370,21045,4224,28674,32827,32793,28745,21050,17472,26653,_,5178,_,2182,33341,33350,45096,25714,8251,13371,37889,96769,_,17983,
18483,_,35916,21584,77957,_,122411,_,65562,2140,94293,_,144951,_,20585,21609,_,_,53945,_,35881,79379,77468,_,114816,_,11868,
110103,_,_,57465,57478,45702,44166,_,_,52822,57864,126985,76294,_,_,_,_,30328,23672,13440,13938,_,_,17000,110602,57412,57399,_,_
,36483,133162,_,_,116276,_,119383,118399,_,32403,_,_,12983,42156,38513,_,_,_,23145,38505,52368,_,_,_,42107,12928,30868,_,_,_,
23142,23154,_,_,16450,30762,29224,_,_,22038,18969,22033,_,_,_,_,52864,_,_,_,_,63615,_,_,_,133177,116349,_,_,43606,48214,81414,
82950,56926,_,_,_,51806,36452,22692,_,_,_,42095,22651,_,_,_,104506,104493,_,_,57413,57426,79926,24218,_,57391,_,_,36513,44184,_,
32415,_,_,42159,42162,_,_,_,104581,104567,28727,52277,78997,75925,19513,28720,_,_,_,33387,42086,7735,_,_,_,66719,30826,64066,_,_
,_,14935,3675,_,_,_,18519,7259,_,_,_,_,18011,_,_,_,_,90,_,_,50742,_,82503,82485,22571,_,36427,_,_,43618,57949,36418,_,_,_,34389,
38997,_,_,_,_,39011,34403,_,53819,53815,12492,8252,_,45125,45121,2112,13884,_,96302,52816,13878,13874,_,53838,55856,34378,9282,_
,31802,38955,3639,103471,_,59004,146045,9260,1095,_,94293,89683,89698,1126,22675,_,_,_,_,21120,_,_,_,113221,158894,158835,78355,
_,_,_,_,22133,_,_,_,_,7801,52761,52771,_,_,33331,27218,_,_,28758,25686,_,45654,_,_,49255,49245,75815,48231,47685,47675,_,_,33380
,22127,_,_,66737,_,104607,87199,_,_,76344,76367,97396,_,144920,47200,_,47651,47641,_,51275,_,47631,47621,_,58443,_,_,_,_,141895,
_,_,_,91305,77993,_,_,_,53405,53416,44652,41580,_,_,33356,16978,_,50798,42057,79430,66629,_,39504,39513,63074,66609,_,39488,
37440,64594,67671,_,40009,40018,62560,64603,_,40025,50777,48241,64606,_,38522,35450,_,48762,52830,52820,_,_,33370,19567,_,50767,
40034,80965,72236,_,36972,_,54880,62041,_,_,36964,50797,58470,_,11396,35933,51804,48220,_,52824,52814,_,61050));
#undef _

////////////////////////////////////////////////////////////////

uvec3 unpack(int data, const ivec3 bits)
{
    uvec3 mask = (uvec3(1) << bits) - 1u;
	uvec3 shift = uvec3(0, bits.x, bits.x + bits.y);
    return (uvec3(data) >> shift) & mask;
}

vec3 get_axial_point(int index)
{
    return vec3(unpack(axial_brushes.data[index], ivec3(9))) * 4. + AXIAL_MINS;
}

int get_nonaxial_brush_start(int index)
{
#if COMPRESSED_BRUSH_OFFSETS
    int data = brushes.data[index >> 2], base = data >> 15;
    return base + (((data << 5) >> (uint(index & 3) * 5u)) & 31);
#else
    return brushes.data[index];
#endif
}

vec4 get_nonaxial_plane(int index)
{
    ivec2 addr = ivec2(ADDR_RANGE_NONAXIAL_PLANES.xy) + ivec2(index&127,index>>7);
    return texelFetch(SETTINGS_CHANNEL, addr, 0);
}

vec4 get_plane(int index)
{
    vec4 plane;
    
    if (index < NUM_MAP_AXIAL_PLANES)
    {
        uint
            brush = uint(index) / 6u,
        	side = uint(index) % 6u,
        	axis = side >> 1,
        	front = side & 1u;
        vec3 p = get_axial_point(int(brush * 2u + (front ^ 1u)));
        plane = vec4(0);
        plane[axis] = front == 1u ? -1. : 1.;
        plane.w = -p[axis] * plane[axis];
    }
    else
    {
        plane = get_nonaxial_plane(index - NUM_MAP_AXIAL_PLANES);
    }
    
    return plane;
}

int get_plane_material(mediump int plane_index)
{
    // An encoding that only needs bit shifts/masks to decode
    // (like 4x8b, 4x4b or 8x4b) would be a much smarter choice.
    // On the other hand, 6x4b leads to a shorter textual encoding
    // for the array (and a slower decoding sequence).
    // Let's pretend character count matters and go with 6x4b...
    
    // Side note: we can use just 4 bits for each plane material id
    // because the material list is sorted by frequency of use
    // before the id's are assigned, and it just so happens that the map
    // currently uses only 16 materials. If we wanted to add just one more
    // we'd have to bump up the number of bits per face to 5.
    
    // better division/modulo codegen for unsigned ints:
    // http://shader-playground.timjones.io/a05d99ce3e6e1ae57ef111c8323e52d2
    mediump uint index = uint(plane_index);
    
    mediump uint unit_index = index / 6u;
    lowp uint bit_index = index % 6u;
    bit_index <<= 2;
    int code = uint(unit_index) < uint(NUM_MATERIAL_ENTRIES) ? materials.data[uint(unit_index)] : 0;

    return 15 & (code >> bit_index);
}

int get_axial_brush_material(int brush, lowp int side)
{
    // Since we chose 6x4b and axial brushes happen to have 6 sides, the math gets easier
    int code = uint(brush) < uint(NUM_MATERIAL_ENTRIES) ? materials.data[uint(brush)] : 0;
    return 15 & (code >> (side << 2));
}

// Axial UV mapping ////////////////////////////////////////////

vec2 uv_map_axial(vec3 pos, int axis)
{
    return (axis==0) ? pos.yz : (axis==1) ? pos.xz : pos.xy;
}

vec3 uv_unmap(vec2 uv, vec4 plane, int axis)
{
    switch (axis)
    {
        case 0: return vec3(-(plane.w + dot(plane.yz, uv)) / plane.x, uv.x, uv.y);
        case 1: return vec3(uv.x, -(plane.w + dot(plane.xz, uv)) / plane.y, uv.y);
        case 2: return vec3(uv.x, uv.y, -(plane.w + dot(plane.xy, uv)) / plane.z);
        default:
        	return vec3(0);
    }
}

vec3 uv_unmap(vec2 uv, vec4 plane)
{
    return uv_unmap(uv, plane, dominant_axis(plane.xyz));
}

///////////////////////////////////////////////////////////////

vec2 sdf_union(vec2 a, vec2 b)
{
    return (a.x < b.x) ? a : b;
}

float sdf_ellipsoid(vec3 p, vec3 r)
{
    return (length(p/r) - 1.) / min3(r.x, r.y, r.z);
}

float sdf_sphere(vec3 p, float r)
{
    return length(p) - r;
}

float sdf_box(vec3 p, vec3 center, vec3 half_bound)
{
    p = abs(p - center) - half_bound;
    return max3(p.x, p.y, p.z);
}

// iq
float sdf_round_box(vec3 p, vec3 b, float r)
{
    return length(max(abs(p) - b, 0.)) - r;
}

float sdf_torus(vec3 p, vec2 t)
{
    vec2 q = vec2(length(p.xz)-t.x,p.y);
    return length(q)-t.y;
}

float sdRoundCone( vec3 p, float r1, float r2, float h )
{
    vec2 q = vec2( length(p.xy), p.z );
    
    float b = (r1-r2)/h;
    float a = sqrt(1.0-b*b);
    float k = dot(q,vec2(-b,a));
    
    if( k < 0.0 ) return length(q) - r1;
    if( k > a*h ) return length(q-vec2(0.0,h)) - r2;
        
    return dot(q, vec2(a,b) ) - r1;
}

// http://mercury.sexy/hg_sdf
// Cone with correct distances to tip and base circle. Z is up, 0 is in the middle of the base.
float sdf_cone(vec3 p, float radius, float height) {
	vec2 q = vec2(length(p.xy), p.z);
	vec2 tip = q - vec2(0, height);
	vec2 mantleDir = normalize(vec2(height, radius));
	float mantle = dot(tip, mantleDir);
	float d = max(mantle, -q.y);
	float projected = dot(tip, vec2(mantleDir.y, -mantleDir.x));
	
	// distance to tip
	if ((q.y > height) && (projected < 0.)) {
		d = max(d, length(tip));
	}
	
	// distance to base ring
	if ((q.x > radius) && (projected > length(vec2(height, radius)))) {
		d = max(d, length(q - vec2(radius, 0)));
	}
	return d;
}

float fOpIntersectionRound(float a, float b, float r) {
	vec2 u = max(vec2(r + a,r + b), vec2(0));
	return min(-r, max (a, b)) + length(u);
}

float fOpDifferenceRound(float a, float b, float r) {
	return fOpIntersectionRound(a, -b, r);
}

float sdf_capsule(vec3 p, vec3 a, vec3 b, float radius)
{
    vec3 ab = b - a;
    vec3 ap = p - a;
    float t = clamp(dot(ap, ab) / dot(ab, ab), 0., 1.);
    return sdf_sphere(p - mix(a, b, t), radius);
}

// this is not quite right
// see https://www.shadertoy.com/view/4lcBWn for a correct solution
float sdf_capsule(vec3 p, vec3 a, vec3 b, float radius_a, float radius_b)
{
    vec3 ab = b - a;
    vec3 ap = p - a;
    float t = clamp(dot(ap, ab) / dot(ab, ab), 0., 1.);
    return sdf_sphere(p - mix(a, b, t), mix(radius_a, radius_b, t));
}

////////////////////////////////////////////////////////////////

struct Closest
{
    vec3 point;
    float distance_squared;
};

Closest init_closest(vec3 p, vec3 first)
{
    return Closest(first, length_squared(p - first));
}

void update_closest(vec3 p, inout Closest closest, vec3 candidate)
{
    float distance_squared = length_squared(p - candidate);
    if (distance_squared < closest.distance_squared)
    {
        closest.distance_squared = distance_squared;
        closest.point = candidate;
    }
}

#define FIND_CLOSEST(point, closest, vecs, len)	\
	closest = init_closest(point, vecs[0]);		\
    for (int i=1; i<len; ++i)					\
        update_closest(p, closest, vecs[i])		\

////////////////////////////////////////////////////////////////

float overshoot(float x, float amount)
{
    amount *= .5;
    return x + amount + amount*sin(x * TAU + -PI/2.);
}

float fast_sqrt(float x2)
{
    return x2 * inversesqrt(x2);
}

vec2 bounding_sphere(const float distance_squared, const float radius, const int material)
{
    return vec2(fast_sqrt(distance_squared)+-radius, material);
}

bool ray_vs_aabb(vec3 ray_origin, vec3 rcp_ray_delta, float max_t, vec3 aabb_mins, vec3 aabb_maxs)
{
    vec3 t0 = (aabb_mins - ray_origin) * rcp_ray_delta;
    vec3 t1 = (aabb_maxs - ray_origin) * rcp_ray_delta;
    vec4 tmin = vec4(min(t0, t1), 0.);
    vec4 tmax = vec4(max(t0, t1), max_t);
    return max_component(tmin) <= min_component(tmax);
}

bool ray_vs_aabb(vec3 ray_origin, vec3 rcp_ray_delta, vec3 aabb_mins, vec3 aabb_maxs)
{
    return ray_vs_aabb(ray_origin, rcp_ray_delta, 1., aabb_mins, aabb_maxs);
}

// Minimalistic quaternion support /////////////////////////////

struct Quaternion
{
    float s;
    vec3 v;
};

Quaternion axis_angle(vec3 axis, float angle)
{
    angle = radians(angle * .5);
    return Quaternion(cos(angle), sin(angle) * axis);
}

Quaternion mul(Quaternion lhs, Quaternion rhs)
{
    return Quaternion(lhs.s * rhs.s - dot(lhs.v, rhs.v), lhs.s * rhs.v + rhs.s * lhs.v + cross(lhs.v, rhs.v));
}

Quaternion conjugate(Quaternion q)
{
    return Quaternion(q.s, -q.v);
}

Quaternion euler_to_quat(vec3 angles)
{
    Quaternion
        q0 = axis_angle(vec3(0, 0, 1), angles.x),
        q1 = axis_angle(vec3(1, 0, 0), angles.y),
        q2 = axis_angle(vec3(0, 1, 0),-angles.z);
    return mul(q0, mul(q1, q2));
}

vec3 rotate(Quaternion q, vec3 v)
{
    // https://fgiesen.wordpress.com/2019/02/09/rotating-a-single-vector-using-a-quaternion/
    vec3 t = 2. * cross(q.v, v);
    return v + q.s * t + cross(q.v, t);
}

////////////////////////////////////////////////////////////////

const int
    NUM_TORCHES					= 3,
    NUM_LARGE_FLAMES			= 2,
    NUM_ZOMBIES					= 4,
    NUM_BALLOONS				= 14,
    NUM_BALLOON_SETS			= 3
;

const struct EntityPositions
{
    vec3 torches[NUM_TORCHES];
    vec3 large_flames[NUM_LARGE_FLAMES];
    vec3 zombies[NUM_ZOMBIES];
    vec3 balloons[NUM_BALLOONS];
    uint balloon_sets[NUM_BALLOON_SETS];
}
g_ent_pos = EntityPositions
(
	vec3[3](vec3(698,764,84),vec3(394,762,84),vec3(362,1034,20)),
	vec3[2](vec3(126,526,12),vec3(958,526,12)),
	vec3[4](vec3(1004,928,72),vec3(1004,1048,124),vec3(708,992,52),vec3(708,1116,120)),
	vec3[14](vec3(848,896,152),vec3(128,528,144),vec3(960,528,144),vec3(344,1064,168),vec3(440,1344,208),vec3(696,744,224),
             vec3(664,1056,136),vec3(984,1336,176),vec3(392,744,200),vec3(120,1336,208),vec3(104,1000,96),vec3(656,1328,216),
             vec3(472,1096,-112),vec3(416,936,112)),
	uint[3](0xa9865320u,0xdcba8510u,0x76543210u)
);

const uint
    ENTITY_BIT_TARGET			= 0u,
    ENTITY_BIT_VIEWMODEL		= uint(NUM_TARGETS),
    ENTITY_BIT_LARGE_FLAMES		= ENTITY_BIT_VIEWMODEL + 1u,
    ENTITY_BIT_TORCHES			= ENTITY_BIT_LARGE_FLAMES + 1u,
    ENTITY_BIT_FIREBALL			= ENTITY_BIT_TORCHES + 1u,

    ENTITY_MASK_TARGETS			= (1u << NUM_TARGETS) - 1u,
    ENTITY_MASK_LARGE_FLAMES	= (1u << NUM_LARGE_FLAMES) - 1u,
    ENTITY_MASK_TORCHES			= (1u << NUM_TORCHES) - 1u
;
    
struct FlameState
{
    float loop;
    vec2 sin_cos;
};

struct FireballState
{
    vec3 offset;
    Quaternion rotation;
};

struct TargetState
{
    uint indices;
    float scale;
};
    
struct ViewModelState
{
    vec3 offset;
    float attack;
    Quaternion rotation;
};

struct EntityState
{
    FlameState		flame;
    FireballState	fireball;
    ViewModelState	viewmodel;
    TargetState		target;
    uint			mask;
};
    
EntityState g_entities;

void update_entity_state(vec3 camera_pos, vec3 camera_angles, vec3 direction, float depth, bool is_thumbnail)
{
    g_entities.mask = 0u;
    
    g_entities.flame.loop			= fract(floor(g_animTime * 10.) * .1);
    g_entities.flame.sin_cos		= vec2(sin(g_entities.flame.loop * TAU), cos(g_entities.flame.loop * TAU));
    g_entities.fireball.offset		= get_fireball_offset(g_animTime);
    g_entities.fireball.rotation	= axis_angle(normalize(vec3(1, 8, 4)), g_animTime * 360.);

    float base_fov_y = scale_fov(FOV, 9./16.);
    float fov_y = compute_fov(iResolution.xy).y;
    float fov_y_delta = base_fov_y - fov_y;

    vec3 velocity = load(ADDR_VELOCITY).xyz;
    Transitions transitions;
    LOAD(transitions);
    float offset = get_viewmodel_offset(velocity, transitions.bob_phase, transitions.attack);
    g_entities.viewmodel.offset		= camera_pos;
    g_entities.viewmodel.rotation	= mul(euler_to_quat(camera_angles), axis_angle(vec3(1,0,0), fov_y_delta*.5));
    g_entities.viewmodel.offset		+= rotate(g_entities.viewmodel.rotation, vec3(0,1,0)) * offset;
    g_entities.viewmodel.rotation	= conjugate(g_entities.viewmodel.rotation);
    g_entities.viewmodel.attack		= linear_step(.875, 1., transitions.attack);
    
#if USE_ENTITY_AABB
    #define TEST_AABB(pos, rcp_delta, mins, maxs) ray_vs_aabb(pos, rcp_delta, mins, maxs)
#else
    #define TEST_AABB(pos, rcp_delta, mins, maxs) true
#endif
    
    Options options;
    LOAD(options);
    
    const vec3 VIEWMODEL_MINS = vec3(-1.25,       0, -8);
    const vec3 VIEWMODEL_MAXS = vec3( 1.25,      18, -4);
    vec3 viewmodel_ray_origin = vec3(    0, -offset,  0);
    vec3 viewmodel_ray_delta  = rotate(g_entities.viewmodel.rotation, direction);
    bool draw_viewmodel = is_demo_mode_enabled(is_thumbnail) ? (g_demo_scene & 1) == 0 : true;
    draw_viewmodel = draw_viewmodel && test_flag(options.flags, OPTION_FLAG_SHOW_WEAPON);
    if (draw_viewmodel && TEST_AABB(viewmodel_ray_origin, 1./viewmodel_ray_delta, VIEWMODEL_MINS, VIEWMODEL_MAXS))
        g_entities.mask |= 1u << ENTITY_BIT_VIEWMODEL;
    
    vec3 inv_world_ray_delta = 1./(direction*depth);

    const vec3 TORCH_MINS = vec3(-4, -4, -28);
	const vec3 TORCH_MAXS = vec3( 4,  4,  18);
    for (int i=0; i<NUM_TORCHES; ++i)
        if (TEST_AABB(camera_pos - g_ent_pos.torches[i], inv_world_ray_delta, TORCH_MINS, TORCH_MAXS))
            g_entities.mask |= (1u<<ENTITY_BIT_TORCHES) << i;
    
    const vec3 LARGE_FLAME_MINS = vec3(-10, -10, -18);
	const vec3 LARGE_FLAME_MAXS = vec3( 10,  10,  34);
    for (int i=0; i<NUM_LARGE_FLAMES; ++i)
        if (TEST_AABB(camera_pos - g_ent_pos.large_flames[i], inv_world_ray_delta, LARGE_FLAME_MINS, LARGE_FLAME_MAXS))
            g_entities.mask |= (1u<<ENTITY_BIT_LARGE_FLAMES) << i;
        
	const vec3 FIREBALL_MINS = vec3(-10);
	const vec3 FIREBALL_MAXS = vec3( 10);
    if (g_entities.fireball.offset.z > 8. &&
        TEST_AABB(camera_pos - FIREBALL_ORIGIN - g_entities.fireball.offset, inv_world_ray_delta, FIREBALL_MINS, FIREBALL_MAXS))
        g_entities.mask |= 1u << ENTITY_BIT_FIREBALL;

    GameState game_state;
    LOAD(game_state);
    g_entities.target.scale = 0.;
    g_entities.target.indices = 0u;
    if (abs(game_state.level) >= 1.)
    {
        vec2 scale_bias = game_state.level > 0. ? vec2(1, 0) : vec2(-1, 1);
        float fraction = linear_step(BALLOON_SCALEIN_TIME * .1, 0., fract(abs(game_state.level)));
        g_entities.target.scale = fraction * scale_bias.x + scale_bias.y;
        if (g_entities.target.scale > 1e-2)
        {
            float level = floor(abs(game_state.level));
            int set = int(fract(level * PHI + .15) * float(NUM_BALLOON_SETS));
            uint indices = g_ent_pos.balloon_sets[set];
            g_entities.target.scale = overshoot(g_entities.target.scale, .5);
        	g_entities.target.indices = indices;
            
            vec3 BALLOON_MINS = vec3(-28, -28, -20) * g_entities.target.scale;
            vec3 BALLOON_MAXS = vec3( 28,  28,  64) * g_entities.target.scale;
            for (int i=0; i<NUM_TARGETS; ++i, indices>>=4)
            {
                Target target;
                LOADR(vec2(i, 0.), target);
                if (target.hits < ADDR_RANGE_SHOTGUN_PELLETS.z * .5)
                    if (TEST_AABB(camera_pos - g_ent_pos.balloons[indices & 15u], inv_world_ray_delta, BALLOON_MINS, BALLOON_MAXS))
	                    g_entities.mask |= (1u << i);
            }
        }
    }
}

////////////////////////////////////////////////////////////////

vec2 map_torch_handle(vec3 p)
{
    p = rotate(p, 45.);
    float dist = sdf_box(p, vec3(0, 0, -17), vec3(1, 1, 10));
    dist = sdf_smin(dist, sdf_box(p, vec3(0, 0, -9), vec3(2, 2, 3)), 3.);
    vec2 wood = vec2(dist, MATERIAL_WIZWOOD1_5);
    dist = sdf_box(p, vec3(0, 0, p.z > -20.5 ? -14.5 : -26.5), vec3(1.25, 1.25, .75));
    return sdf_union(wood, vec2(dist, MATERIAL_WIZMET1_1));
}

vec2 map_flame(vec3 p)
{
    const float scale = 1.;
    p *= 1./scale;

    p.z += 6.;
    
    float loop = g_entities.flame.loop;
    float angle_jitter = hash(g_entities.flame.loop) * 360.;

    vec3 ofs = vec3(-.5, -.5, 0);
    vec3 p1 = rotate(p, angle_jitter + p.z * (360./16.)) + ofs;
    float dist = sdf_cone(p1, 2.5, 16.);

    ofs = vec3(-1, -1, -2);
    p1 = rotate(p, angle_jitter + 180. - p.z * (360./32.)) + ofs;
    dist = sdf_smin(dist, sdf_cone(p1, 1.75, 10.), 1.);
    
    dist = sdf_smin(dist, sdf_capsule(p, vec3(0, 0, 1), vec3(0, 0, 4), 2.5, 1.), 3.);

    mat2 loop_rotation = mat2(g_entities.flame.sin_cos.yxxy * vec4(1, 1, -1, 1));
    p1 = vec3(loop_rotation * p.xy, p.z - 2.);
    dist = sdf_union(dist, sdf_sphere(p1 - vec3( 2,  2, mix(8., 20., loop)), .25));
    dist = sdf_union(dist, sdf_sphere(p1 - vec3(-2,  1, mix(12., 22., fract(loop + .3))), .25));
    dist = sdf_union(dist, sdf_sphere(p1 - vec3(-1, -2, mix(10., 16., fract(loop + .6))), .25));

    return vec2(dist*scale, MATERIAL_FLAME);
}

vec2 map_large_flame(vec3 p)
{
    const float scale = 2.;
    p *= 1./scale;
    p.z += 6.;

    float loop = g_entities.flame.loop;
    float angle_jitter = hash(g_entities.flame.loop) * 360.;

    vec3 ofs = vec3(-.5, -.5, 0.);
    vec3 p1 = rotate(p, angle_jitter + p.z * (360./16.)) + ofs;
    float dist = sdf_cone(p1, 2., 14.);
    
    ofs = vec3(1., 1., 0.);
    p1 = rotate(p, angle_jitter + p.z * (360./32.)) + ofs;
    dist = sdf_smin(dist, sdf_cone(p1, 2., 10.), .25);

    ofs = vec3(-.75, -.75, -1.5);
    p1 = rotate(p, angle_jitter + 180. - p.z * (360./32.)) + ofs;
    dist = sdf_smin(dist, sdf_cone(p1, 2., 10.), .25);

    dist = sdf_smin(dist, sdf_capsule(p, vec3(0, 0, 1), vec3(0, 0, 5), 3.25, 1.5), 2.);

    mat2 loop_rotation = mat2(g_entities.flame.sin_cos.yxxy * vec4(1, 1, -1, 1));
    p1 = vec3(loop_rotation * p.xy, p.z);
    dist = sdf_union(dist, sdf_sphere(p1 - vec3( 2, 2, mix(8., 20., loop)), .25));
    dist = sdf_union(dist, sdf_sphere(p1 - vec3(-2, 1, mix(12., 22., fract(loop + .3))), .25));
    dist = sdf_union(dist, sdf_sphere(p1 - vec3(-1,-2, mix(10., 16., fract(loop + .6))), .25));

    return vec2(dist*scale, MATERIAL_FLAME);
}

vec2 map_torch(vec3 p, vec3 origin)
{
    p -= origin;
    return sdf_union(map_torch_handle(p), map_flame(p));
}

vec2 map_fireball(vec3 p, vec3 origin)
{
    vec3 current_pos = origin + g_entities.fireball.offset;
    p -= current_pos;
    p = rotate(g_entities.fireball.rotation, p);
    float dist = sdf_sphere(p, 3.);
    dist = sdf_smin(dist, sdf_sphere(p - vec3(1.5, 1.5, 4), 4.), 3.);
    dist = sdf_smin(dist, sdf_sphere(p - vec3(2.5,-1.5, 3), 2.5), 3.);
    return vec2(dist, MATERIAL_LAVA1);
}

// very rough draft; work in progress
vec2 map_zombie(vec3 p)
{
    const vec3
        hip = vec3(2, 3, 2),
    	knee = vec3(-1, 1.5, -9),
    	ankle = vec3(4, 1.25, -21),
    	toe1 = vec3(1.5, 1.6, -24),
    	toe2 = vec3(1, 1.1, -24),
    
        spine1 = vec3(1.5, 0, 2),
        spine2 = vec3(1, 0, 13.5),

        shoulder = vec3(2, 6, 16),
        elbow = vec3(2, 14, 20),
        wrist = vec3(2, 22, 26),

        neck = vec3(1, 0, 18),
        head = vec3(-1.5, 0, 22),
        mouth = vec3(-1.5, 0, 20)
	;
    
    vec3 mp = p;
    mp.y = abs(mp.y);

    float dist = sdf_capsule(mp, ankle, knee, 1., 1.5);
    dist = sdf_smin(dist, sdf_capsule(mp, knee, hip, 1.5, 2.), .05);
    dist = sdf_smin(dist, sdf_capsule(mp, ankle, toe1, 1., .5), .5);
	dist = sdf_smin(dist, sdf_capsule(mp, ankle, toe2, 1., .5), .5);
    
    dist = sdf_smin(dist, sdf_capsule(mp, shoulder, elbow, 1.3, 1.2), 2.);
    dist = sdf_smin(dist, sdf_capsule(mp, elbow, wrist, 1.2, .9), .5);

    dist = sdf_smin(dist, sdf_round_box(p - spine1, vec3(.25, 3., 3.), .25), 1.5);
    dist = sdf_smin(dist, sdf_capsule(p, spine1, spine2, 1.), 4.);
    dist = sdf_smin(dist, sdf_round_box(p - spine2, vec3(.75, 2.5, 2.5), 1.25), 4.);

    dist = sdf_smin(dist, sdf_capsule(p, neck, head, 1.5, 1.1), 1.);
    dist = sdf_smin(dist, sdf_sphere(p - head, 2.5), 2.);
    dist = sdf_smin(dist, sdf_round_box(p - mouth, vec3(.5, .5, .5), 1.), 1.);

    //return vec2(dist, MATERIAL_COP3_4);
    return vec2(dist, MATERIAL_ZOMBIE);
}

vec2 map_viewmodel(vec3 p)
{
    p -= g_entities.viewmodel.offset;
    float sq_dist = length_squared(p);
    if (sq_dist > sqr(32.))
        return bounding_sphere(sq_dist, 24., MATERIAL_SHOTGUN_BARREL);
    
    p = rotate(g_entities.viewmodel.rotation, p);
    
    const vec3
        BARREL_0	= vec3(0,    4, -4.375),
    	BARREL_1	= vec3(0, 13.5, -4.375),
    	FLASH_0		= vec3(0, 14.6, -4.375),
    	FLASH_1		= vec3(0, 16.1, -4.375),
    	BODY_0		= vec3(0,    2, -4.7),
    	BODY_1		= vec3(0,  7.5, -4.7),
        INDENT		= vec3(0,  7.5, -4.7),
		PUMP_0		= vec3(0,    9, -6.),
    	PUMP_1		= vec3(0, 12.9, -6.),
        PUMP_GROOVE	= vec3(0, 12.7, -6.)
	;
    
    vec2 body = vec2(sdf_capsule(p, BARREL_0, BARREL_1, .5), MATERIAL_SHOTGUN_BARREL);
    body.x = sdf_smin(body.x, sdf_capsule(p, BODY_0, BODY_1, .875), .05);
    body.x = sdf_smin(body.x, sdf_torus(p - INDENT, vec2(.7, .3)), .05);
    
    float attack = g_entities.viewmodel.attack;
    if (attack > 0.)
        body = sdf_union(body, vec2(sdf_capsule(p, FLASH_0, FLASH_1, .6, .2), MATERIAL_SHOTGUN_FLASH));

    const float GROOVE_SPACING = .675;
    vec2 pump = vec2(sdf_capsule(p, PUMP_0, PUMP_1, 1.4), MATERIAL_SHOTGUN_PUMP);
    p -= PUMP_GROOVE;
    p.y = fract(p.y * GROOVE_SPACING - .25) * (1./GROOVE_SPACING) - .5;
    pump.x = fOpDifferenceRound(pump.x, sdf_torus(p, vec2(1.3125, .375)), .125);
    
    return sdf_union(body, pump);
}

void add_targets(vec3 p, inout vec2 result)
{
    uint mask = g_entities.mask & ENTITY_MASK_TARGETS;
    if (mask == 0u)
        return;

    float best_sq_dist = 1e+8;
    int best_index = -1;
    int best_material = 0;
    uint indices = g_entities.target.indices;
    for (int i=0; i<NUM_TARGETS; ++i, mask>>=1, indices>>=4)
    {
        if ((mask & 1u) == 0u)
            continue;
        int index = int(indices & 15u);
        float sq_dist = length_squared(p - g_ent_pos.balloons[index]);
        if (sq_dist < best_sq_dist)
        {
            best_sq_dist = sq_dist;
            best_index = index;
            best_material = i;
        }
    }

    best_material += BASE_TARGET_MATERIAL;
    if (best_sq_dist > sqr(64.))
    {
        result = sdf_union(result, bounding_sphere(best_sq_dist, 56., best_material));
        return;
    }
    
    vec3 target = g_ent_pos.balloons[best_index];
    target.z += 8. * sin(TAU * fract(g_animTime * .25 + dot(target.xy, vec2(1./137., 1./163.))));
    float scale = g_entities.target.scale;
    result = sdf_union(result, vec2(sdRoundCone(p - target, 8.*scale, 24.*scale, 28.*scale), best_material));
}

vec2 map_entities(vec3 p)
{
    // Finding the closest instance and only mapping it instead of the whole list (even for such tiny lists)
    // shaves about 4.9 seconds off the compilation time on my machine (~7.6 vs ~12.5)

    vec2 entities = vec2(1e+8, MATERIAL_SKY1);
    Closest closest;
    
    if (0u != (g_entities.mask & (ENTITY_MASK_TORCHES << ENTITY_BIT_TORCHES)))
    {
        FIND_CLOSEST(p, closest, g_ent_pos.torches, NUM_TORCHES);
        if (closest.distance_squared > sqr(40.))
            entities = bounding_sphere(closest.distance_squared, 32., MATERIAL_FLAME);
        else
            entities = map_torch(p, closest.point);
    }

    if (0u != (g_entities.mask & (ENTITY_MASK_LARGE_FLAMES << ENTITY_BIT_LARGE_FLAMES)))
    {
        FIND_CLOSEST(p, closest, g_ent_pos.large_flames, NUM_LARGE_FLAMES);
        if (closest.distance_squared > sqr(48.))
            entities = sdf_union(entities, bounding_sphere(closest.distance_squared, 40., MATERIAL_FLAME));
        else
            entities = sdf_union(entities, map_large_flame(p - closest.point));
    }
    
#if 0
    FIND_CLOSEST(p, closest, ZOMBIES);
	entities = sdf_union(entities, map_zombie(p - closest.point));
    //int num_zombies = NO_UNROLL(NUM_ZOMBIES);
    //for (int i=0; i<num_zombies; ++i)
    //    entities = sdf_union(entities, map_zombie(p - zombies[i]));
#endif
    
    if (0u != (g_entities.mask & (1u << ENTITY_BIT_FIREBALL)))
    	entities = sdf_union(entities, map_fireball(p, FIREBALL_ORIGIN));

    add_targets(p, entities);

    #if RENDER_WEAPON
    {
        if ((g_entities.mask & (1u << ENTITY_BIT_VIEWMODEL)) != 0u)
    		entities = sdf_union(entities, map_viewmodel(p));
    }
	#endif
    
    return entities;
}

vec3 estimate_entity_normal(vec3 p, float dist)
{
    const float EPSILON = 1e-3;
    vec3 normal = vec3(-dist);
    for (int i=NO_UNROLL(0); i<3; ++i)
    {
        vec3 p2 = p;
        p2[i] += EPSILON;
        normal[i] += map_entities(p2).x;
    }
    return normalize(normal);
}

////////////////////////////////////////////////////////////////

struct Intersection
{
    float	t;
    vec3	normal;
    int		plane;
    int		material;
    int		uv_axis;
    bool	mips;
};

void reset_intersection(out Intersection result)
{
    result.t			= 1.;
    result.normal		= vec3(0.);
    result.plane		= -1;
    result.material		= -1;
    result.mips			= false;
    result.uv_axis		= 0;
}

void intersect_entities(vec3 campos, vec3 angles, vec3 dir, bool is_thumbnail, inout Intersection result)
{
#if RENDER_ENTITIES
    update_entity_state(campos, angles, dir, result.t, is_thumbnail);
    if (g_entities.mask == 0u)
        return;

    float t = 0.;
    float rcp_length = 1./length(dir);
    int max_steps = NO_UNROLL(ENTITY_RAYMARCH_STEPS);
    vec2 current = vec2(2, -1);
    float tolerance = 1e-4;
    float max_tolerance = ENTITY_RAYMARCH_TOLERANCE * VIEW_DISTANCE * FOV_FACTOR * .5 * g_downscale / iResolution[FOV_AXIS];
    for (int i=0; i<max_steps; ++i)
    {
        current = map_entities(campos + dir * t);
        tolerance = t*max_tolerance + .015;
        if (current.x < tolerance)
            break;
        t += current.x * rcp_length;
        if (t >= result.t)
            break;
    }
    
    if (t < result.t && t > 0. && current.x < tolerance)
    {
        vec3 hit_point = campos + dir * t;
        
        result.t			= t;
        result.material		= int(current.y);
        result.plane		= -1;
        result.normal		= estimate_entity_normal(hit_point, current.x);
        result.mips			= true;
        result.uv_axis		= 3;
    }
#if DEBUG_ENTITY_AABB
    else
    {
        result.material		= BASE_TARGET_MATERIAL;
    }
#endif // DEBUG_ENTITY_AABB
#endif // RENDER_ENTITIES
}

void intersect_axial_brushes
(
    int brush_begin, int brush_end,
    vec3 campos, vec3 rcp_delta, float znear,
    inout float best_dist, inout int best_index
)
{
#if RENDER_WORLD & 1
    brush_begin = brush_begin << 1;
    brush_end = NO_UNROLL(brush_end) << 1;
    for (int i=brush_begin; i<brush_end; i+=2)
    {
        vec3 mins = get_axial_point(i);
        vec3 maxs = get_axial_point(i+1);
        vec3 t0 = (mins - campos) * rcp_delta;
        vec3 t1 = (maxs - campos) * rcp_delta;
        vec3 tmin = min(t0, t1);
        vec4 tmax = vec4(max(t0, t1), best_dist);
        float t_enter = max_component(tmin);
        float t_exit = min_component(tmax);
        if (t_exit >= max(t_enter, 0.) && t_enter > znear)
        {
            best_dist = t_enter;
            best_index = i;
        }
    }
#endif // RENDER_WORLD & 1    
}

void resolve_axial_intersection(vec3 campos, vec3 rcp_delta, inout Intersection result, int best_index)
{
    if (best_index == -1)
        return;

    vec3 mins = get_axial_point(best_index);
    vec3 maxs = get_axial_point(best_index+1);
    vec3 t0 = (mins - campos) * rcp_delta;
    vec3 t1 = (maxs - campos) * rcp_delta;
    vec3 tmin = min(t0, t1);
    float t = max_component(tmin);
    int axis =
        (t == tmin.x) ? 0 :
    	(t == tmin.y) ? 1 :
    	2;
    bool side = rcp_delta[axis] > 0.;
    int face = (axis << 1) + int(side);

    result.plane		= (best_index + (best_index<<1)) + face;
    result.material		= get_axial_brush_material(best_index>>1, face);
    result.normal		= vec3(0);
    result.normal[axis]	= side ? -1. : 1.;
    result.uv_axis		= axis;
    result.mips			= fwidth(float(result.plane)) < 1e-4;
}

void intersect_nonaxial_brushes
(
    int brush_begin, int brush_end,
    vec3 campos, vec3 dir, float znear, 
    inout float best_dist, inout int best_plane
)
{
#if RENDER_WORLD & 2
    if (brush_begin >= brush_end)
        return;
    brush_end = NO_UNROLL(brush_end);
    for (int i=brush_begin, first_plane=get_nonaxial_brush_start(i), last_plane; i<brush_end; ++i, first_plane=last_plane)
    {
       	last_plane = get_nonaxial_brush_start(i + 1);
        int best_brush_plane = -1;
        float t_enter = -1e6;
        float t_leave = 1.;
       	for (int j=first_plane; j<last_plane; ++j)
        {
            vec4 plane = get_nonaxial_plane(j);
            float dist = dot(plane.xyz, campos) + plane.w;
            float align = dot(plane.xyz, dir);
            if (align == 0.)
            {
                if (dist > 0.)
                {
                    t_enter = 2.;
                    break;
                }
                continue;
            }
            dist /= -align;
            best_brush_plane = (align < 0. && t_enter < dist) ? j : best_brush_plane;
            t_enter = (align < 0.) ? max(t_enter, dist) : t_enter;
            t_leave = (align > 0.) ? min(t_leave, dist) : t_leave;
            if (t_leave <= t_enter)
                break;
        }
        if (t_leave > max(t_enter, 0.) && t_enter > znear && best_dist > t_enter)
        {
            best_plane = best_brush_plane;
            best_dist = t_enter;
        }
    }
#endif // RENDER_WORLD & 2
}

void resolve_nonaxial_intersection(inout Intersection result, int best_index)
{
    if (best_index == -1)
        return;
    
    vec4 plane = get_nonaxial_plane(best_index);
    
    result.normal = plane.xyz;
    result.uv_axis = dominant_axis(plane.xyz);
    result.plane = best_index + NUM_MAP_AXIAL_PLANES;
    result.material = get_plane_material(result.plane);

    // pixel quad straddling geometric planes? no mipmaps for you!
    float plane_hash = dot(plane, vec4(17463.12, 25592.53, 15576.84, 19642.77));
    result.mips = fwidth(plane_hash) < 1e-4;
}

////////////////////////////////////////////////////////////////

void intersect_world(vec3 campos, vec3 dir, float znear, inout Intersection result)
{
    vec3 inv_world_dir = 1./dir;
    int best_index = -1;
    
    // axial brushes //
    
	#if USE_PARTITION & 1
    {
        for (int i=NO_UNROLL(0); i<NUM_AXIAL_NODES; ++i)
        {
            Node n = unpack(bvl.axial[i], AXIAL_BVL_MINS);
            if (ray_vs_aabb(campos, inv_world_dir, result.t, n.mins, n.maxs))
                intersect_axial_brushes(int(n.begin), int(n.end), campos, inv_world_dir, znear, result.t, best_index);
        }
    }
	#else
    {
    	intersect_axial_brushes(0, NUM_MAP_AXIAL_BRUSHES, campos, inv_world_dir, znear, result.t, best_index);
    }
	#endif
    resolve_axial_intersection(campos, inv_world_dir, result, best_index);
    
    // non-axial brushes //
    
    best_index = -1;

	#if USE_PARTITION & 2
    {
        for (int i=NO_UNROLL(0); i<NUM_NONAXIAL_NODES; ++i)
        {
            Node n = unpack(bvl.nonaxial[i], NONAXIAL_BVL_MINS);
            if (ray_vs_aabb(campos, inv_world_dir, result.t, n.mins, n.maxs))
                intersect_nonaxial_brushes(int(n.begin), int(n.end), campos, dir, znear, result.t, best_index);
        }
    }
	#else
    {
    	intersect_nonaxial_brushes(0, NUM_MAP_NONAXIAL_BRUSHES, campos, dir, znear, result.t, best_index);
    }
	#endif
    resolve_nonaxial_intersection(result, best_index);
}

////////////////////////////////////////////////////////////////

vec4 get_light(int index)
{
    ivec2 addr = ivec2(ADDR_RANGE_LIGHTS.xy);
    addr.x += index;
    return texelFetch(SETTINGS_CHANNEL, addr, 0);
}

vec4 get_lightmap_tile(int index)
{
    ivec2 addr = ivec2(ADDR_RANGE_LMAP_TILES.xy);
    addr.x += index & 127;
    addr.y += index >> 7;
    return texelFetch(SETTINGS_CHANNEL, addr, 0);
}

int find_tile(vec2 fragCoord, int num_tiles)
{
#if BAKE_LIGHTMAP
    for (int i=NO_UNROLL(0); i<num_tiles; ++i)
		if (is_inside(fragCoord, get_lightmap_tile(i)) > 0.)
            return i;
#endif
    return -1;
}

ivec2 get_brush_and_side(int plane_index)
{
    if (plane_index < NUM_MAP_AXIAL_PLANES)
        return ivec2(uint(plane_index) / 6u, uint(plane_index) % 6u);
    
    plane_index -= NUM_MAP_AXIAL_PLANES;
	
    #define TEST(dist) (int((get_nonaxial_brush_start(brush + (dist)) <= plane_index)) * (dist))
    
	int brush = 0;
    brush  = TEST(NUM_MAP_NONAXIAL_BRUSHES-64);
    brush += TEST(32);
    brush += TEST(16);
    brush += TEST(8);
    brush += TEST(4);
    brush += TEST(2);
    brush += TEST(1);

    #undef TEST

    return ivec2(brush + NUM_MAP_AXIAL_BRUSHES, plane_index - get_nonaxial_brush_start(brush));
}

float find_edge_distance(vec3 p, int brush, int side)
{
    float dist = -1e8;
    
    if (brush < NUM_MAP_AXIAL_BRUSHES)
    {
        vec3[2] deltas;
        deltas[0] = get_axial_point(brush*2) - p;
        deltas[1] = p - get_axial_point(brush*2+1);
        int axis = side >> 1;
        int front = side & 1;
        for (int i=0; i<6; ++i)
            if (i != side)
            	dist = max(dist, deltas[1&~i][i>>1]);
    }
    else
    {
        int begin = get_nonaxial_brush_start(brush - NUM_MAP_AXIAL_BRUSHES);
        int end = get_nonaxial_brush_start(brush - (NUM_MAP_AXIAL_BRUSHES - 1));
        for (int i=begin; i<end; ++i)
        {
            if (i == begin + side)
                continue;
            vec4 plane = get_nonaxial_plane(i);
            dist = max(dist, dot(p, plane.xyz) + plane.w);
        }
    }
    
    return dist;
}

vec2 get_lightmap_offset(int plane_index)
{
	const int NUM_BITS = 9, MASK = (1 << NUM_BITS) - 1;
	int packed_offset = LIGHTMAP_OFFSETS.data[plane_index];
    return (packed_offset >= 0) ?
        LIGHTMAP_OFFSET + vec2(packed_offset & MASK, packed_offset >> NUM_BITS) :
        LIGHTMAP_OFFSET + vec2(-1);
}

float fetch_lightmap_texel(ivec2 addr)
{
    addr = clamp(addr, ivec2(0), ivec2(LIGHTMAP_SIZE) - 1);
    int channel = addr.y & 3;
    addr.y >>= 2;
    return decode_lightmap_sample(texelFetch(iChannel1, addr, 0)).values[channel];
}

float sample_lightmap(vec3 camera_pos, vec3 dir, Options options, Intersection result)
{
    if (result.uv_axis == 3)
        return clamp(-dot(result.normal, ENTITY_LIGHT_DIR), ENTITY_MIN_LIGHT, 1.);
    if (result.plane == -1)
        return 1.;

    float unmapped_light = is_material_any_of(result.material, MATERIAL_MASK_LIQUID|MATERIAL_MASK_SKY) ? 1. : 0.;
    vec3 point = camera_pos + dir * result.t;
    vec2 offset = get_lightmap_offset(result.plane);
    if (any(lessThan(offset, LIGHTMAP_OFFSET)))
        return unmapped_light;

    vec2 uv = uv_map_axial(point, result.uv_axis);
#if LIGHTMAP_FILTER == 1 // snap to world texels
    if (!test_flag(options.flags, OPTION_FLAG_TEXTURE_FILTER))
    	uv = floor(uv) + .5;
#endif
    uv = uv / LIGHTMAP_SCALE - offset;
    
#if LIGHTMAP_FILTER > 0
    uv -= .5;
#endif
    
    vec2 base = floor(uv);
    ivec2 addr = ivec2(base);
    if (uint(addr.x) >= LIGHTMAP_SIZE.x || uint(addr.y) >= LIGHTMAP_SIZE.y)
        return unmapped_light;
    
    uv -= base;
#if !LIGHTMAP_FILTER
    uv = vec2(0);
#endif
    
    float
        s00 = fetch_lightmap_texel(addr + ivec2(0,0)),
        s01 = fetch_lightmap_texel(addr + ivec2(0,1)),
        s10 = fetch_lightmap_texel(addr + ivec2(1,0)),
        s11 = fetch_lightmap_texel(addr + ivec2(1,1)),
        light = mix(mix(s00, s01, uv.y), mix(s10, s11, uv.y), uv.x);

#ifdef QUANTIZE_LIGHTMAP
    const float LEVELS = float(QUANTIZE_LIGHTMAP);
    if (!test_flag(options.flags, OPTION_FLAG_TEXTURE_FILTER) && g_demo_stage != DEMO_STAGE_LIGHTING)
        light = floor(light * LEVELS + .5) * (1./LEVELS);
#endif
    
    return light;
}

vec3 lightmap_to_world(vec2 fragCoord, int plane_index)
{
    fragCoord += get_lightmap_offset(plane_index);
    vec4 plane = get_plane(plane_index);
    return uv_unmap(fragCoord * LIGHTMAP_SCALE, plane) + plane.xyz * LIGHTMAP_HEIGHT_OFFSET;
}

float compute_light_atten(vec4 light, vec3 surface_point, vec3 surface_normal)
{
    vec3 light_dir = light.xyz - surface_point;
	float
        dist = length(light_dir) * LIGHTMAP_SCALEDIST,
    	angle = mix(1., dot(surface_normal, normalize(light_dir)), LIGHTMAP_SCALECOS);
    return max(0., (light.w - dist) * angle * (LIGHTMAP_RANGESCALE / 255.));
}

// dynamic lights didn't seem to be taking normals into account
// (fireball light showing up on the right wall of the Normal hallway)
float compute_dynamic_light_atten(vec4 light, vec3 surface_point)
{
    vec3 light_dir = light.xyz - surface_point;
    float dist = length(light_dir);
    float radius = light.w;
    return clamp(1.-dist/abs(radius), 0., 1.) * sign(radius);
}

vec3 simulate_lightmap_distortion(vec3 surface_point)
{
    surface_point = floor(surface_point);
    surface_point *= 1./LIGHTMAP_SCALE;
    vec3 f = fract(surface_point + .5);
    return (surface_point + f - smoothen(f)) * LIGHTMAP_SCALE;
}

float sample_lighting(vec3 camera_pos, vec3 dir, Options options, Intersection result)
{
#if !BAKE_LIGHTMAP
    return 1.;
#endif

    Transitions transitions;
    LOAD(transitions);
    
    float lightmap = sample_lightmap(camera_pos, dir, options, result);
    
    float dynamic_lighting = 0.;
    vec3 surface_point = camera_pos + dir * result.t;
    surface_point = simulate_lightmap_distortion(surface_point);
    
    vec3 fireball_offset = get_fireball_offset(g_animTime);
    vec4 fireball_light = vec4(fireball_offset + FIREBALL_ORIGIN, 150);
    if (fireball_offset.z > 8.)
    	dynamic_lighting += compute_dynamic_light_atten(fireball_light, surface_point);
    if (transitions.attack > .875)
        dynamic_lighting += compute_dynamic_light_atten(vec4(camera_pos, 200), surface_point);
    
#ifdef QUANTIZE_DYNAMIC_LIGHTS
    const float LEVELS = float(QUANTIZE_DYNAMIC_LIGHTS);
    if (!test_flag(options.flags, OPTION_FLAG_TEXTURE_FILTER))
    	dynamic_lighting = floor(dynamic_lighting * LEVELS + .5) * (1./LEVELS);
#endif
    
    return lightmap + dynamic_lighting;
}

////////////////////////////////////////////////////////////////

void mainImage( out vec4 fragColor, vec2 fragCoord )
{
    ivec2 addr = ivec2(fragCoord);
    
    vec3 pos, dir, angles;
    float light_level = -1., znear = 0.;
    bool is_ground_sample = false;
    bool is_thumbnail = test_flag(int(load(ADDR_RESOLUTION).z), RESOLUTION_FLAG_THUMBNAIL);
    vec4 plane;

    Lighting lighting;
    LOAD(lighting);
    
    Options options;
    LOAD(options);

    Timing timing;
    LOAD(timing);
    g_animTime = timing.anim;
    
    // initial setup //

    bool baking = iFrame < NUM_LIGHTMAP_FRAMES;
    if (baking)
    {
        if (uint(addr.x) >= LIGHTMAP_SIZE.x || uint(addr.y) >= LIGHTMAP_SIZE.y/4u)
            DISCARD;
        fragColor = vec4(-1);
        
        int region = iFrame & 3;
        int frame = iFrame >> 2;
        addr.y += region * int(LIGHTMAP_SIZE.y/4u);
        vec2 lightmap_coord = vec2(addr);
        
        int plane_index = find_tile(lightmap_coord + .5, lighting.num_tiles);
        if (plane_index == -1)
            return;
        lightmap_coord += hammersley(frame % NUM_LIGHTMAP_SAMPLES, NUM_LIGHTMAP_SAMPLES);

        ivec2 brush_side = get_brush_and_side(plane_index);
        int brush = brush_side.x;
        int side = brush_side.y;

        pos = lightmap_to_world(lightmap_coord, plane_index);
        if (find_edge_distance(pos, brush, side) > LIGHTMAP_SCALE * LIGHTMAP_EXTRAPOLATE)
            return;

        plane = get_plane(plane_index);
        znear = -1e8;
    }
    else
    {
        g_downscale = get_downscale(options);
        is_ground_sample = all(equal(ivec2(fragCoord), ivec2(iResolution.xy)-1));
        vec2 actual_res = min(ceil(iResolution.xy / g_downscale * .125) * 8., iResolution.xy);
        if (max_component(fragCoord - .5 - actual_res) > 0. && !is_ground_sample)
        	DISCARD;

        vec2 demo_coord = is_ground_sample ?
            iResolution.xy * vec2(.5, .25) / g_downscale :
        	fragCoord;

        UPDATE_TIME(lighting);
        UPDATE_DEMO_STAGE(demo_coord, g_downscale, is_thumbnail);

        pos = load_camera_pos(SETTINGS_CHANNEL, is_thumbnail).xyz;
        angles = load_camera_angles(SETTINGS_CHANNEL, is_thumbnail).xyz;
        if (!is_ground_sample)
        {
            vec2 uv = (fragCoord * 2. * g_downscale - iResolution.xy) / iResolution.x;
            dir = unproject(uv) * VIEW_DISTANCE;
            dir = rotate(dir, angles);
        }
        else
        {
            dir = vec3(0, 0, -VIEW_DISTANCE);
            angles = vec3(0, -90, 0);
        }
    }

    // render loop //
    
    Intersection result;
    
#if !BAKE_LIGHTMAP
    lighting.num_lights = 0;
#endif

    int num_iter = baking ? lighting.num_lights : 1;
    for (int i=0; i<num_iter; ++i)
    {
        float contrib;
        if (baking)
        {
            vec4 light = get_light(i);
            contrib = compute_light_atten(light, pos, plane.xyz);
            if (contrib <= 0.)
                continue;
            dir = light.xyz - pos;
        }

        reset_intersection(result);
    	intersect_world(pos, dir, znear, result);

        if (baking)
        {
            if (result.t >= 1. || is_material_liquid(result.material))
                light_level = max(light_level, 0.) + contrib;
            else if (result.t > 0.)
                light_level = max(light_level, 0.);
		}
    }

    if (!baking && !is_ground_sample)
	    intersect_entities(pos, angles, dir, is_thumbnail, result);

    // output //

    if (baking)
    {
        fragColor.rgb = vec3(light_level);
    }
    else
    {
        if (result.material == -1)
        {
            result.t = 1.;
            result.material = MATERIAL_SKY1;
            result.normal = vec3(0, 0, -1);
            result.mips = true;
        }

        GBuffer g;
        g.normal	= result.normal;
        g.light		= sample_lighting(pos, dir, options, result);
        g.z			= result.t;
        g.material	= result.material;
        g.uv_axis	= result.uv_axis;
        g.edge		= !result.mips;

        // In demo mode, we can have the shotgun model rendered at two different map locations
        // at the same time (during the stage transitions). We only take a single lightmap sample
        // for the ground point per frame, so to avoid harsh transitions between different light
        // levels, we just use a default light value for the weapon model if demo mode is enabled
        if (is_ground_sample && test_flag(int(load(ADDR_RESOLUTION).z), RESOLUTION_FLAG_THUMBNAIL))
            g.light	= .5;
        
#if DITHER_ENTITY_NORMALS
        vec2 noise = result.plane == -1 ? fract(BLUE_NOISE(fragCoord).xy) : vec2(.5);
#else
        vec2 noise = vec2(.5);
#endif

        fragColor = gbuffer_pack(g, noise);
    }
}
