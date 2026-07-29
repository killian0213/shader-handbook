// Common (common) — Space Glider 2020 VR by scholarius
// https://www.shadertoy.com/view/MdGfDG

/*
 *   \___ \  ___   \___    \___ \  ___      \___   \      \  \  ___  \  ___ \  ___
 *  \_     \    \_\    \  \      \         \        \      \  \    \  \      \    \_
 *    \___  \  __  \  ___  \      \  __     \    \_  \      \  \    \  \  __  \  __
 *        \_ \      \    \  \_     \         \_    \_ \      \  \    \_ \      \   \
 *    \_____  \_     \_   \_  \____ \_____     \_____  \_____ \_ \____   \_____ \_   \_
 *
 *   \__________________________________________________________________________________
 *
 *
 *	                                                     SPACE GLIDER SHADERTOY EDITION
 *                                                                 by Christian Schüler
 *			                                                            (c) 2001 - 2025
 *
 * Part 1 of 6: Common definitions
 * This software comes with no warranty. Use it at your own risk.
 * v 45
 */

// ----------------------------------------------------------------------------
// OPTIONS
// ----------------------------------------------------------------------------

// Set the overall quality level

#define QUALITY_LEVEL				4

	/*
	QUALITY_LEVEL					0		1		2		3		4		5

	WITH_ATM_BILATERAL_UPSAMPLE		-		-		-		x		x		x
	WITH_ATM_TRAPEZ_QUADRATURE		-		-		-		-		x		x
	WITH_ATM_TWEAKS					-		-		-		-		-		x
	WITH_TRN_CENTRAL_DIFF			-		-		x		x		x		x
	WITH_TRN_REFINE					-		x		x		x		x		x
	WITH_TRN_SURFACE_AA				-		-		-		x		x		x

	ATM_CLOUD_MAX_ITER				25		30		35		40		45		50
	ATM_CLOUD_TAU50_CUTOFF			8		9		10		11		12		13
	ATM_SCATTER_MAX_ITER			50		60		70		80		90		100
	SCN_RAYCAST_MAX_ITER			250		300		350		400		450		500
	TRN_MAX_REFINE_LEVELS			-		1		2		3		4		5
	TRN_SAFE_SLOPE					40		45		50		55		60		65
	*/

// Restrict compilation up to a certain buffer from 1..5
// (in the order A,B,C,D,Image) to troubleshoot issues

#define BUFFER_RUNLEVEL				5

// Enable or disable specific workarounds

#define WORKAROUND_01_EXP2			1		// Ubuntu Studio 18 (bionic) GTX 760
#define WORKAROUND_02_FOR_IF		1		// Ubuntu Studio 18 (bionic) GTX 760
#define WORKAROUND_03_SWITCH		1		// Windows 7 ANGLE/D3D backend
#define WORKAROUND_04_VEC4			1		// Windows 10 ANGLE/D3D backend / Edge Browser
#define WORKAROUND_05_UVEC4			1		// Windows 7 ANGLE/D3D backend
#define WORKAROUND_07_KEYPRESS		1		// iMac 2010 27 inch Radeon 5670 M
#define WORKAROUND_08_UINT2FLOAT	1		// Windows 7 ANGLE/D3D wants uint -> int -> float in some cases?
#define WORKAROUND_09_INT_EXP2		1		// Windows 10 ANGLE/D3D does not like float( 1 << i )
#define WORKAROUND_10_NOUNROLL		1		// iMac 2010 27 inch Radeon 5670 M
#define WORKAROUND_11_MAP_CRASH		0		// Windows 10 ANGLE/D3D crash when activating map mode (nvidia only?)
#define WORKAROUND_12_TANH			1		// MacBook Pro 15' 2017 tanh goes inf for arg > 88
#define WORKAROUND_13_HALF16FTZ     1       // MacBook Pro 15' 2017 packHalf2x16 flushes to zero instead of denormal (AMD 550M)
#define WORKAROUND_14_TEXLODOFFS    1       // macOS + Safari: miscompilation of textureLodOffset

// Feature switches

#define WITH_ATMOSPHERE				1
#define WITH_CLOUDS					1
#define WITH_OBJECTS				1
#define WITH_TERRAIN				1
#define WITH_STARS					1

// Testing switches

#define WITH_ILLUM_TEST				0		// illumination only, exposure measurements

// Detail switches

#define WITH_ATM_AMTL_CORRECTION	1
#define WITH_ATM_BILATERAL_UPSAMPLE ( QUALITY_LEVEL >= 3 )
#define WITH_ATM_PACKHALF2X16       1
#define WITH_ATM_LAYER_A			1		// absorbtion layer (used for ozone)
#define WITH_ATM_LAYER_E			1		// emission layer (used for airglow)
#define WITH_ATM_LAYER_G			1		// ground layer (used for aerosols and water vapor)
#define WITH_ATM_TRAPEZ_QUADRATURE	( QUALITY_LEVEL >= 4 )
#define WITH_ATM_TWEAKS				( QUALITY_LEVEL >= 5 )

#define WITH_TRN_CENTRAL_DIFF		( QUALITY_LEVEL >= 2 )
#define WITH_TRN_REFINE				( QUALITY_LEVEL >= 1 )
#define WITH_TRN_SHADOW				1
#define WITH_TRN_SURFACE_AA			( QUALITY_LEVEL >= 3 )

// Experimental/WIP

#define WITH_SCN_RAYCAST_JITTER		0
#define WITH_TRN_AUX				0

// ----------------------------------------------------------------------------
// WORLD SCALE
// ----------------------------------------------------------------------------

#define SCALING_PRESET				1

// Consistent 1:6 scale with 1:1 atmosphere + gravity
// Space Glider default scale, also Star Citizen uses this scale a lot
#if SCALING_PRESET == 1
const float SECONDS_PER_MINUTE		= 10.;	// game time speed: real seconds per in-game minute
const float INV_G_SCALE				= 1.;	// inverse scale of the gravity strength
const float ATM_SCALE				= 1.;	// scales the height of the atmosphere
const float SCN_SCALE				= 1.;	// scales the size of the world (all planet distances and sizes)
const float TRN_SCALE				= 1.;	// scales height of the terrain
const float SUN_SCALE				= 1.;
#endif

// Consistent 1:20 scale with 1:1 atmosphere + gravity
// Euro Truck Simulator would be this scale, if extended to planet scope
#if SCALING_PRESET == 2
const float SECONDS_PER_MINUTE		= 3.;
const float INV_G_SCALE				= 1.;
const float ATM_SCALE				= 1.;
const float SCN_SCALE				= .3;
const float TRN_SCALE				= .3;
const float SUN_SCALE				= 1.;
#endif

// Consistent 1:20 scale with 1:3 atmosphere + 3:1 gravity
// Space Glider scale in previous versions until about 2019
#if SCALING_PRESET == 3
const float SECONDS_PER_MINUTE		= 3.;
const float INV_G_SCALE				= .3;
const float ATM_SCALE				= .3;
const float SCN_SCALE				= .3;
const float TRN_SCALE				= .3;
const float SUN_SCALE				= 1.;
#endif

// Consistent 1:48 scale with 1:8 atmosphere + 1:1 gravity
// No Man's Sky 'large' planets are about this scale
#if SCALING_PRESET == 4
const float SECONDS_PER_MINUTE		= 1.25;
const float INV_G_SCALE				= 1.;
const float ATM_SCALE				= .125;
const float SCN_SCALE				= .125;
const float TRN_SCALE				= .125;
const float SUN_SCALE				= 1.;
#endif

// 1:10 size, 1:4 time, 1:1 atmosphere + gravity
// Kerbin in KSP is of this scale
#if SCALING_PRESET == 5
const float SECONDS_PER_MINUTE		= 15.;
const float INV_G_SCALE				= 1.;
const float ATM_SCALE				= 1.;
const float SCN_SCALE				= .628830551;
const float TRN_SCALE				= .628830551;
const float SUN_SCALE				= 1.;
#endif

// 1:1 real Earth size
// at this scale, the floating point precision is insufficient
// also the terrain is too flat (stretched out)
// use F1 time acceleration to complete the transfer seqeuence if it gets stuck
#if SCALING_PRESET == 6
const float SECONDS_PER_MINUTE		= 60.;
const float INV_G_SCALE				= 1.00317853;
const float ATM_SCALE				= 1.;
const float SCN_SCALE				= 6.67634161;
const float TRN_SCALE				= 1.;
const float SUN_SCALE               = .199689812;
#endif

// ----------------------------------------------------------------------------
// CONSTANTS
// ----------------------------------------------------------------------------

const float EULER = 2.71828183;
const float FRACT_1_16 = .0625;
const float FRACT_1_64 = .015625;
const float FRACT_1_256 = .000390625;
const float FRACT_1_4096 = 2.44140625e-4;
const float FRACT_1_65536 = 1.52587891e-5;
const float FRACT_1_1048576 = 9.53674316e-7;
const float FRACT_1_16777216 = 5.96046448e-8;
const float FRACT_15_16 = .9375;
const float FRACT_63_64 = .984375;
const float FRACT_127_128 = .9921875;
const float FRACT_1023_1024 = .999023438;
const float FRACT_4095_4096 = .999755859;
const float FRACT_16383_16384 = .999938965;
const float FRACT_65535_65536 = .999984741;
const float FRACT_2_TO_NEG_48 = 3.55271368e-15;
const float FRACT_2_TO_NEG_63 = 1.08420217e-19;
const vec3	HALF = vec3(.5);
const mat3	IDENTITY = mat3(1);
const float LN2 = .693147181;
const float LN10 = 2.30258509;
const float LOG2E = 1.44269504;
const vec3	ONE = vec3(1);
const float ONEOVERSQRTPI = .564189584;
const float ONEOVERSQRTTWOPI = .398942280;
const float PI = 3.14159265;
const float PIHALF = 1.57079632;
const uint	RNG32 = 3934873077u;
const float TAU = 6.28318531;
const float SQRDEG = radians( radians( 1. ) );
const float SQRTHALF = .707106781;
const float SQRT2LN2 = 1.17741002;
const float SQRTTWO = 1.41421356;
const float SQRTPILN2HALF = 1.04345246;
const float SQRTPIOVER8 = .626657069;
const float	SHR32 = 1. / 4294967296.;
const vec3	UNIT_X = vec3(1,0,0);
const vec3	UNIT_Y = vec3(0,1,0);
const vec3	UNIT_Z = vec3(0,0,1);
const vec3	ZERO = vec3(0);

const float ATM_AMTL_CORRECTION = 2.583861763 * sqrt( ATM_SCALE / SCN_SCALE );
const int	ATM_CLOUD_MAX_ITER = 25 + 5 * QUALITY_LEVEL;
const float ATM_CLOUD_SHADOW_MIN_TAU = 350.;
const float ATM_CLOUD_SHADOW_MAX_TAU = 750.;
const float ATM_CLOUD_TAU50_CUTOFF = 8. + float( QUALITY_LEVEL );
const float ATM_CLOUD_T_CUTOFF = exp2( -ATM_CLOUD_TAU50_CUTOFF );
const float ATM_HALF2X16_SCALE = bool( WORKAROUND_13_HALF16FTZ ) ? 4096. : 1.;
const float ATM_HALF2X16_SCALE_INV = 1. / ATM_HALF2X16_SCALE;
const int	ATM_SCATTER_MAX_ITER = 50 + 10 * QUALITY_LEVEL;
const int	ATM_SCATTER_MIN_ITER = 25;

const float CAM_FOV = 96.;
const float CAM_FOV_INNER = 94.;
const float CAM_FOCUS = 1. / tan( radians( CAM_FOV ) / 2. );
const float CAM_FOCUS_INNER = 1. / tan( radians( CAM_FOV_INNER ) / 2. );
const float CAM_DISTORT = max( 0.01, CAM_FOCUS_INNER / CAM_FOCUS - 1. );

#if SCALING_PRESET != 6
const vec4	COL_AIRGLOW = 1.0154e-6 * vec4( .8670, 1.0899, .4332, 15. );	// mixture of mostly 558 + some 589 and 630 nm emission lines
#else
const vec4	COL_AIRGLOW = 2.7419e-9 * vec4( .8670, 1.0899, .4332, 15. );
#endif
const vec4	COL_CANOPY_TINT = vec4( 0.7839, 0.8936, 0.8581, 0.7247 );		// canopy tint color
const vec3	COL_D65 = vec3( 0.8857, 1.0512, 1.0884 );
const vec4	COL_NVISNSENS = vec4( .6, .3, .1, 1.3 );						// night vision sensitivities
const float COL_NVISNSAT = 0.023;											// night vision saturation luminance
const float COL_NVISNGAIN = 215.;											// night vision amplification factor
const vec3	COL_RODVISION = vec3( 0.4856, 0.4856, 0.9713 );					// color of 2 parts S-cone over 1 part L + M cones
const vec3	COL_P20PHOSPHOR = vec3( 0.8975, 1.0930, 0.0934 );				// color of P20 phosphor emission spectrum
const vec3	COL_P43PHOSPHOR = vec3( 0.5335, 1.2621, 0.1874 );				// color of P43 phosphor emission spectrum
const vec3	COL_PRIMARYRED = vec3( 0.4411, 0.0000, 0.0000 );				// brightest physically realizable in-gamut red material color
#if SCALING_PRESET != 6
const vec4	COL_STARLIGHT = 0.9178e-6 * vec4( 0.9714, 1.0123, 1.0341, .3 );	// luminance and color of total starlight
#else
const vec4	COL_STARLIGHT = 2.3733e-9 * vec4( 0.9714, 1.0123, 1.0341, .3 );
#endif
const float COL_STARLIGHT_ISL = 0.7875;										// fraction of integrated starlight
const vec4	COL_SUNLIGHT = vec4( 0.9420, 1.0269, 1.0242, .3 );				// color of sunlight emission spectrum
const vec4	COL_THRESHOLD = vec4( 0.8699, 1.0000, 1.2022, 0.4239 ) * 3.462e-8;	// threshold of vision (here w is for rods, not for IR)
const float COL_THRESHOLD_AREA = .25 * SQRDEG;								// reference integration area for threshold
const float COL_THRESHOLD_TIME = 1. / 60.;									// reference integration time for threshold
const vec4	COL_XENONARC = vec4( 0.8203, 1.0856, 1.0254, 0.25 );			// color of xenon arc emission light spectrum
const vec3	COL_YWEIGHTS = vec3( 0.3161, 0.6543, 0.0296 );					// luminance weights of the 615,535,445 primaries

const float	FDM_MASS_SCALE = 1.00307805 / INV_G_SCALE;
const int	FDM_MIN_ITER = 4;
const int	FDM_MAX_ITER = 32;
const float FDM_STD_G = 9.83444460 / INV_G_SCALE;

const vec2	HMD_BORDER = vec2( .80, .40 );
const vec2	HMD_BORDER_LAD = vec2( .40, .30 );
const vec2	HMD_BORDER_SYM = vec2( .65, .35 );

const float IMG_EXPOSURE_MAX = 8.;
const int	IMG_EXPOSURE_SAMPLES = 1024;
const float IMG_MIPMAP_HIDE = 16777216.;

const float	SCN_ATM_SUBSAMPLE_RATIO = 2.;
const float SCN_DATA_SUNRADIUS = 25509.5823 * SCN_SCALE * SUN_SCALE;
const float SCN_DATA_PLANETDIST = 1094367.24 * SCN_SCALE;
const int	SCN_MAX_PRIMITIVES = 40;
const int	SCN_RAYCAST_MAX_ITER = 250 + 50 * QUALITY_LEVEL;
const float SCN_RAYCAST_MIN_ADVANCE = .002 * sqrt( SCN_SCALE );
const float SCN_RAYCAST_MIN_ADVANCE_SCALE = 8. / float( SCN_RAYCAST_MAX_ITER );
const int	SCN_RAYCAST_SHADOW_MAX_ITER = SCN_RAYCAST_MAX_ITER * 3 / 4;
const float SCN_RAYCAST_SHADOW_MIN_ADVANCE = .006 * sqrt( SCN_SCALE );
const float SCN_RAYCAST_SHADOW_MIN_ADVANCE_SCALE = 8. / float( SCN_RAYCAST_SHADOW_MAX_ITER );
const float SCN_RAYCAST_SHADOW_HBIAS = .002;
const float SCN_RAYCAST_SHADOW_HSCALE = .005;
const float SCN_RAYCAST_SHADOW_TBIAS = .001;
const float SCN_ZNEAR = 0.001 * sqrt( SCN_SCALE );
const float SCN_ZFAR = 99999.;

const float TRN_AO_LOD_OFFSET = 2.;
const float TRN_LOD_BIAS = 1.;
const float TRN_MAX_LEVELS = 16.;
const float TRN_MAX_REFINE_LEVELS = float( QUALITY_LEVEL );
const float TRN_SAFE_SLOPE = 40. + 5. * float( QUALITY_LEVEL );
const float TRN_SAFE_SLOPE_FACTOR = tan( radians( 90. - TRN_SAFE_SLOPE ) );
const float TRN_UPDATE_THRESHOLD = 9.;

const float TXT_FONT_SPACING = .50;
const float TXT_FONT_HOFFSET = .27;
const float TXT_FONT_BACKSLANT = .15625;
const int	TXT_FMT_MAX_LEN = 59;
const int	TXT_FMT_MAX_COUNT = 52;
const uint	TXT_FMT_FLAG_CENTER = 0x10u;
const uint	TXT_FMT_FLAG_RIGHT = 0x20u;
const uint	TXT_FMT_FLAG_HUDCLIP = 0x80u;
const uint	TXT_FMT_LENGTH_MASK = 0x0fu;
const int	TXT_MSG_MAX_PHRASES = 7;

// ----------------------------------------------------------------------------
// MEMORY MAP
// ----------------------------------------------------------------------------

bool in_addr_range( ivec2 sc, ivec2 addr, int size, int count )
	{ return sc.y >= addr.x && sc.y < addr.x + count &&
			 sc.x >= addr.y && sc.x < addr.y + size; }

vec4 memload( sampler2D ch, ivec2 addr, int offs )
	{ return texelFetch( ch, addr.yx + ivec2( offs, 0 ), 0 ); }

mat2x3 memload_mat2x3( sampler2D ch, ivec2 addr, int offs )
	{ return mat2x3( memload( ch, addr, offs ).xyz, memload( ch, addr, offs + 1 ).xyz ); }

mat3 memload_mat3( sampler2D ch, ivec2 addr, int offs )
	{ return mat3( memload( ch, addr, offs ).xyz, memload( ch, addr, offs + 1 ).xyz, memload( ch, addr, offs + 2 ).xyz ); }

vec3 memload_www( sampler2D ch, ivec2 addr, int offs )
	{ return vec3( memload( ch, addr, offs ).w, memload( ch, addr, offs + 1 ).w, memload( ch, addr, offs + 2 ).w ); }

void memstore( vec4 value, ivec2 addr, int offs, ivec2 sc, inout vec4 fc )
	{ if( sc.y == addr.x && sc.x == addr.y + offs ) fc = value; }

void memstore( vec3 value1, float value2, ivec2 addr, int offs, ivec2 sc, inout vec4 fc )
	{ if( sc.y == addr.x && sc.x == addr.y + offs ) fc = vec4( value1, value2 ); }

void memstore( vec2 value1, vec2 value2, ivec2 addr, int offs, ivec2 sc, inout vec4 fc )
	{ if( sc.y == addr.x && sc.x == addr.y + offs ) fc = vec4( value1, value2 ); }

void memstore( mat3 value1, vec3 value2, ivec2 addr, int offs, ivec2 sc, inout vec4 fc )
{
	if( sc.y == addr.x && sc.x == addr.y + offs )
		fc = vec4( value1[0], value2.x );
	if( sc.y == addr.x && sc.x == addr.y + offs + 1 )
		fc = vec4( value1[1], value2.y );
	if( sc.y == addr.x && sc.x == addr.y + offs + 2 )
		fc = vec4( value1[2], value2.z );
}

void memstore( mat3 value, ivec2 addr, int offs, ivec2 sc, inout vec4 fc )
	{ memstore( value, ZERO, addr, offs, sc, fc ); }

// A buffer addresses

/*
	.				  .					.				  .
	.				  .					.				  .
	.				  .					.				  .

	PSPSPSP. ........ SMSM.... SMSM.... ACACACAC ACACAC.. SOSOSO.. ........
	PSPSPSP. ........ SMSM.... SMSM.... ACACACAC ACACAC.. SOSOSO.. ........
	PSPSPSP. ........ SMSM.... SMSM.... ACACACAC ACACAC.. SOSOSO.. ........
	PSPSPSP. ........ SMSM.... SMSM.... ACACACAC ACACAC.. SOSOSO.. ........
	PSPSPSP. ........ SMSM.... SMSM.... ACACACAC ACACAC.. SOSOSO.. ........
	PSPSPSP. ........ SMSM.... SMSM.... ACACACAC ACACAC.. SOSOSO.. ........
	PSPSPSP. ........ SMSM.... SMSM.... ACACACAC ACACAC.. SOSOSO.. ........
	PSPSPSP. ........ SMSM.... SMSM.... ACACACAC ACACAC.. SOSOSO.. ........

	EXEXEXEX ........ ........ ........ ........ ........ SOSOSO.. ........
	EXEXEXEX ........ ........ ........ ........ ........ SOSOSO.. ........
	EXEXEXEX ........ ........ ........ ........ ........ SOSOSO.. ........
	EXEXEXEX ........ AA...... ........ ........ ........ SOSOSO.. ........
	EXEXEXEX ........ ........ ........ ........ ........ SOSOSO.. ........
	EXEXEXEX ........ AUX..... ........ ........ ........ SOSOSO.. ........
	EXEXEXEX ........ ........ ........ ........ ........ SOSOSO.. ........
	EXEXEXEX ........ MQMQMQMQ MQMQM... ........ ........ SOSOSO.. ........

	........ ........ ........ ........ ........ ........ SOSOSO.. ........
	........ ........ LELE.... VEVE.... ........ ........ SOSOSO.. ........
	........ ........ ........ ........ ........ ........ SOSOSO.. ........
	sizes... ........ SMSM.... SMSM.... ........ ........ SOSOSO.. ........
	........ ........ ........ ........ ........ ........ SOSOSO.. ........ .
	DTDT.... ........ VSVSVSVS VSVSVSVS VSV..... ........ SOSOSO.. ........ .
	........ ........ ........ ........ ........ ........ SOSOSO.. ........ .
	R....... ........ GSGSGSGS GSGSG... ........ ........ SOSOSO.. ........ const data ...
*/

const ivec2	ADDR_RESOLUTION =		ivec2( 0, 0 );
const ivec2	ADDR_DTIME =			ivec2( 2, 0 );
const ivec2	ADDR_DATASIZES =		ivec2( 4, 0 );
const ivec2	ADDR_EXPOSURE =			ivec2( 8, 0 );

const ivec2	ADDR_GAME_STATE =		ivec2( 0, 16 );
const ivec2	ADDR_VEHICLE_STATE =	ivec2( 2, 16 );
const ivec2	ADDR_LOCAL_SM =			ivec2( 4, 16 );
const ivec2	ADDR_LOCAL_SM_LAST =	ivec2( 4, 24 );
const ivec2	ADDR_LOCAL_ENV =		ivec2( 6, 16 );
const ivec2	ADDR_VEHICLE_ENV =		ivec2( 6, 24 );

const ivec2	ADDR_MSG_QUEUE =		ivec2( 8, 16 );
const ivec2	ADDR_GAME_STATE_AUX =	ivec2( 10, 16 );
const ivec2 ADDR_ACHIEVEMENTS =		ivec2( 12, 16 );

const ivec2	ADDR_PLANET_STATES =	ivec2( 16, 0 );
const ivec2 ADDR_SPHERE_MAPS =		ivec2( 16, 16 );
const ivec2 ADDR_SPHERE_MAPS_LAST = ivec2( 16, 24 );
const ivec2	ADDR_ATM_CONTEXTS =		ivec2( 16, 32 );
const ivec2 ADDR_PLANET_DATA =		ivec2( 16, 88 );

const ivec2	ADDR_SCENE_OBJECTS =	ivec2( 0, 48 );
const ivec2 ADDR_SCENE_DATA =		ivec2( 0, 64 );
const ivec2 ADDR_MENU_DATA =		ivec2( 0, 72 );
const ivec2 ADDR_START_DATA =		ivec2( 0, 80 );

const ivec2 ADDR_DEBUG_OUT =		ivec2( -2, 0 );
const ivec2 ADDR_MAX =              ivec2( 90, 160 );

// B buffer lower letterbox addresses

const int ADDR_B_CAMPOS_SAMPLE = 0;
const int ADDR_B_WAYPOINT_SAMPLE = 8;
const int ADDR_B_ZONE_DATA = 16;
const int ADDR_B_SCENE_DATA = 56;

// D buffer lower letterbox addresses

const int ADDR_D_SUN_VISIBILITY = 0;
const int ADDR_D_TEXTSCALE = 8;

// ----------------------------------------------------------------------------
// UTILITIES
// ----------------------------------------------------------------------------

#define FORCE_EVAL( x ) clamp( x, -1e12, 1e12 )
#define NOUNROLL( x ) max( -iFrame, x )

// screen coordinate utils

#define sc2uv( _sc ) ( (_sc) / iResolution.xy )
#define uv2sc( _uv ) ( (_uv) * iResolution.xy )
#define sc2ec( _sc ) ( ( 2. * (_sc) - iResolution.xy ) / iResolution.x )
#define ec2sc( _ec ) ( .5 * ( (_ec) * iResolution.x + iResolution.xy ) )
#define sc2mc( _sc ) ( ( 2. * (_sc) - iResolution.xy ) / iResolution.y )
#define mc2sc( _ec ) ( .5 * ( (_ec) * iResolution.y + iResolution.xy ) )

// type-generic utils

#define cosasin(x) sqrt( ( 1. - (x) ) * ( 1. + (x) ) )
#define cosatan(x) inversesqrt( (x) * (x) + 1. )
#define cube(x) ( (x) * (x) * (x) )
#define expm1(x) ( exp(x) - 1. )
#define log1p(x) log( (x) + 1. )	  // - ( FORCE_EVAL( FORCE_EVAL( (x) + 1. ) - 1. ) - (x) ) / ( (x) + 1. ) )
#define lensq(x) dot( x, x )
#define project(a,b) ( (b) * dot( a, b ) )
#define project_n(a,b) ( (b) * dot( a, b ) / lensq(b) )
#define reject(a,b) ( (a) - project(a,b) )
#define reject_max(a,b) ( (a) - (b) * max( 0., dot( a, b ) ) )
#define reject_min(a,b) ( (a) - (b) * min( 0., dot( a, b ) ) )
#define reject_n(a,b) ( (a) - project_n( a, b ) )
#define sinacos(x) sqrt( ( 1. - (x) ) * ( 1. + (x) ) )
#define sinatan(x) ( (x) * inversesqrt( (x) * (x) + 1. ) )
#define softadd(a,b) ( (a) + (b) - (a) * (b) )
#define softdiv( a, b, scale ) ( (a) * (b) / ( (scale) * (scale) + (b) * (b) ) )
#define softnormalize( a, scale ) ( softdiv( a, length(a), scale ) )
#define safediv( a, b ) softdiv( a, b, FRACT_1_16777216 )
#define safenormalize( a ) softnormalize( a, FRACT_1_16777216 )
#define saturate(a) clamp( a, 0., 1. )
#define smin1(a,S) ( 1. - log( 1. + exp( ( 1. - (a) ) / (S) ) ) * S )
#define sqdiff(a,b) ( ( (a) - (b) ) * ( (a) + (b) ) )
#define square(x) ( (x) * (x) )

// bitfield utils

#define bit_is_set( a, b ) ( ( (a) & (b) ) != 0u )
#define bit_is_unset( a, b ) ( ( (a) & (b) ) == 0u )
#define bit_set( a, b ) (a) |= (b)
#define bit_set_to( a, b, c ) (a) = ( (a) & ~(b) ) | ( (b) * uint( bool(c) ) )
#define bit_toggle( a, b ) (a) ^= (b)
#define bit_unset( a, b ) (a) &= ~(b)
#define bitfield_get_int( a, b, c ) int( ( (a) & (b) ) >> (c) )
#define bitfield_get_uint( a, b, c ) uint( ( (a) & (b) ) >> (c) )
#define bitfield_set( a, b, c, d ) (a) = ( (a) & ~(b) ) | ( (d) << (c) )

// type-specific utils

vec2 barrel_distort( vec2 ec, float a ) { return ec / max( 0., 1. + a * ( 1. - dot( ec, ec ) ) ); }
vec2 barrel_distort_inv( vec2 ec, float a ) { float ec2 = dot( ec, ec ); float u = a * ( a + 1. ) * ec2; return u < 1. / 4096. ? ec * ( a + 1. ) : ec / ( 2. * a * ec2 ) * ( sqrt( 4. * u + 1. ) - 1. ); }
float barrel_distort_rate( float ec2, float a ) { return ( a + 1. + a * ec2 ) / square( a + 1. - a * ec2 ); }
float fresnel_schlick( float r0, float mu ) { mu = 1. - mu; return mix( r0, 1., mu * mu * mu * mu * mu ); }
float hmax( vec2 arg ) { return max( arg.x, arg.y ); }
float hmax( vec3 arg ) { return max( arg.x, max( arg.y, arg.z ) ); }
float hmax( vec4 arg ) { return max( arg.x, max( arg.y, max( arg.z, arg.w ) ) ); }
float hmin( vec2 arg ) { return min( arg.x, arg.y ); }
float hmin( vec3 arg ) { return min( arg.x, min( arg.y, arg.z ) ); }
float hmin( vec4 arg ) { return min( arg.x, min( arg.y, min( arg.z, arg.w ) ) ); }
float ldexp( float a, int e ) { return a * intBitsToFloat( ( e + 127 ) << 23 ); }
vec2 length_invlength( vec2 x ) { float p = dot( x, x ); float q = inversesqrt( max( FRACT_1_16777216 * FRACT_1_16777216, p ) ); return vec2( p * q, q ); }
vec3 length_normalize( vec2 x ) { float p = dot( x, x ); float q = inversesqrt( max( FRACT_1_16777216 * FRACT_1_16777216, p ) ); return vec3( x, p ) * q; }
vec4 length_normalize( vec3 x ) { float p = dot( x, x ); float q = inversesqrt( max( FRACT_1_16777216 * FRACT_1_16777216, p ) ); return vec4( x, p ) * q; }
vec4 length_normalize_r( vec3 x, vec3 r ) { vec3 s = x + r; float p = dot( x, x ); float q = inversesqrt( max( FRACT_1_16777216 * FRACT_1_16777216, p ) ); return vec4( x, p ) * q; }
vec4 pack_uvec4( uvec4 a ) { return vec4( uintBitsToFloat( a.x ), uintBitsToFloat( a.y ), uintBitsToFloat( a.z ), uintBitsToFloat( a.w ) ); }
float parabolstep( float a, float b, float x ) { float t = clamp( ( x - a ) / ( b - a ), 0., 1. ) - .5; return .5 - 2. * ( abs( t ) * t - t ); }
vec2 perp( vec2 arg ) { return vec2( -arg.y, arg.x ); }
vec3 simple_refract( vec3 I, vec3 N ) { return	I - .8 * ( 1.5 - dot( N, I ) ) * N; }
vec3 simple_refract_inv( vec3 I, vec3 R, vec3 Z ) { vec3 result = normalize( I - R * length( simple_refract( I, Z ) ) ); return I - R * length( simple_refract( I, result ) ); }
uvec4 unpack_uvec4( vec4 a ) { return uvec4( floatBitsToUint( a.x ), floatBitsToUint( a.y ), floatBitsToUint( a.z ), floatBitsToUint( a.w ) ); }

#if WORKAROUND_01_EXP2
float exp2pp( float x ) { return exp2( max( x, -126. ) ); }
vec2 exp2pp( vec2 x ) { return exp2( max( x, -126. ) ); }
vec3 exp2pp( vec3 x ) { return exp2( max( x, -126. ) ); }
vec4 exp2pp( vec4 x ) { return exp2( max( x, -126. ) ); }
#else
float exp2pp( float x ) { return exp2(x); }
vec2 exp2pp( vec2 x ) { return exp2(x); }
vec3 exp2pp( vec3 x ) { return exp2(x); }
vec4 exp2pp( vec4 x ) { return exp2(x); }
#endif

// utils for automatic partial derivatives

const vec4 ONE_D = vec4( ZERO, 1 );
const vec4 ZERO_D = vec4(0);

vec4 abs_d( vec4 a ) { return a * sign( a.w ); }
vec4 asin_d( vec4 a ) { return vec4( a.xyz * inversesqrt( 1. - a.w * a.w ), asin( a.w ) ); }
vec4 atan_d( vec4 a ) { return vec4( a.xyz / ( 1. + a.w * a.w ), atan( a.w ) ); }
vec4 atan2_d( vec4 a, vec4 b ) { return vec4( ( a.xyz * b.w - b.xyz * a.w ) / ( square( b.w ) * ( 1. + square( a.w / b.w ) ) ), atan( a.w, b.w ) ); }
vec4 atanh_d( vec4 a ) { return vec4( a.xyz / ( 1. - a.w * a.w ), atanh( a.w ) ); }
vec4 clamp_d( vec4 x, vec4 a, vec4 b ) { return x.w < a.w ? a : x.w < b.w ? x : b; }
vec4 const_d( float x ) { return vec2( 0, x ).xxxy; }
vec4 cos_d( vec4 a ) { return vec4( -a.xyz * sin( a.w ), cos( a.w ) ); }
vec4 cosh_d( vec4 a ) { return vec4( a.xyz * sinh( a.w ), cosh( a.w ) ); }
vec4 div_d( vec4 a, vec4 b ) { return vec4( ( a.xyz * b.w - a.w * b.xyz ) / square( b.w ), a.w / b.w ); }
vec4 exp_d( vec4 a ) { return exp( a.w ) * vec4( a.xyz, 1 ); }
vec4 hypot_d( vec4 a, vec4 b ) { float h = sqrt( a.w * a.w + b.w * b.w ); return vec4( ( a.xyz * a.w + b.xyz * b.w ) / h, h ); }
vec4 log_d( vec4 a ) { return vec4( a.xyz / a.w, log( a.w ) ); }
vec4 max_d( vec4 a, vec4 b ) { return b.w < a.w ? a : b; }
vec4 min_d( vec4 a, vec4 b ) { return a.w < b.w ? a : b; }
vec4 mix_d( vec4 a, vec4 b, vec4 t ) { return mix( a, b, t.w ) + vec4( t.xyz, 0 ) * ( b.w - a.w ); }
vec4 mul_d( vec4 a, vec4 b ) { return a * b.w + vec4( a.w * b.xyz, 0 ); }
vec4 pow_d( vec4 a, float b ) { return a * pow( a.w, b - 1. ) * vec2( b, 1 ).xxxy; }
vec4 saturate_d( vec4 a ) { return a.w < 0. ? ZERO_D : a.w < 1. ? a : ONE_D; }
vec4 sin_d( vec4 a ) { return vec4( a.xyz * cos( a.w ), sin( a.w ) ); }
vec4 sinh_d( vec4 a ) { return vec4( a.xyz * cosh( a.w ), sinh( a.w ) ); }
vec4 smin1_d( vec4 a, float S ) { vec4 arg = ( ONE_D - a ) / S; return arg.w < 16. ? ONE_D - log_d( ONE_D + exp_d( arg ) ) * S : a; }
vec4 sqrt_d( vec4 a ) { return a * inversesqrt( a.w ) * vec2( .5, 1 ).xxxy; }
vec4 square_d( vec4 a ) { return a * a.w * vec2( 2, 1 ).xxxy; }
vec4 tan_d( vec4 a ) { float t = tan( a.w ); return vec4( a.xyz * ( 1. + t * t ), t ); }
vec4 tanh_d( vec4 a ) { float t = tanh( a.w ); return vec4( a.xyz * ( 1. - t * t ), t ); }

vec4 asin2_d( vec4 a, vec4 b ) { return atan2_d( a, sqrt_d( mul_d( b + a, b - a ) ) ); }

// piecewise exponentials and trancendentials

// https://www.shadertoy.com/view/t3ByDR
// https://www.shadertoy.com/view/w3ByDz

float pwexp2( float x )
	{ return intBitsToFloat( 1065353216 + int( round( 8388608. * x ) ) ); }

float pwlog2( float x )
	{ return float( floatBitsToInt(x) - 1065353216 ) / 8388608.; }

float pwinvexp2floorlog2( float x )
	{ return intBitsToFloat( 0x7f000000 - ( floatBitsToInt(x) & 0xff800000 ) ); }


float pwsinh( float x )
	{ return sign(x) * ( pwexp2( abs(x) ) - 1. ); }

float pwasinh( float x )
	{ return sign(x) * ( pwlog2( abs(x) + 1. ) ); }

float pwasinh_slope( float x )
	{ return pwinvexp2floorlog2( abs(x) + 1. ); }

// special functions

float sumdifflen( vec3 r, vec3 s )
{
	// = length( r + s ) - length(s)
	return dot( s, s + 2. * r ) / ( length( r + s ) + length(r) );
}

vec2 sincospi( float a )
{
	// https://www.shadertoy.com/view/WlXczs
	vec2 b = vec2( a - .5, a );
	vec2 x = .5 - abs( b - 2. * round( .5 * b ) );
	vec2 x2 = x * x;
	return ( ( ( ( .0771991387 * x2 - .598057449 ) * x2 + 2.55004048 ) * x2 - 5.16770887 ) * x2 + 3.14159274 ) * x;
}

mat3 matrixspin( mat3 B, vec3 omega )
{
	B[0] = normalize( B[0] + cross( omega, B[0] ) );
	B[1] = normalize( B[1] + cross( omega, B[1] ) );
	B[2] = normalize( cross( B[0], B[1] ) );
	B[1] = cross( B[2], B[0] );
	return B;
}

// ----------------------------------------------------------------------------
// RAYCAST UTILS
// ----------------------------------------------------------------------------

struct Ray { vec3 o; vec3 d; };
struct RayBaserel { vec3 obase; vec3 orel; vec3 d; };

vec2 sphere_impact( vec3 o, vec3 d )
{
	float q = dot( o, d );
	/*
	return vec2( dot( o, o ) - q * q, q );
	/*/
	vec3 h = o - d * q / dot( d, d );
	return vec2( dot( h, h ), q );
	//*/
}

vec2 sphere_limits( float R, vec2 impact )
{
	float D = R * R - impact.x;
	return sqrt(D) * vec2( -1, 1 ) - impact.y;
}

// ----------------------------------------------------------------------------
// GEODESY UTILS
// ----------------------------------------------------------------------------

vec3 nav2r( vec3 nav )
{
	vec2 sclat = sincospi( nav.x / 180. );
	vec2 sclong = sincospi( nav.y / 180. );
	return nav.z * vec3( sclat.y * sclong.y, sclat.y * sclong.x, sclat.x );
}

vec3 r2nav( vec3 r )
{
	return vec3(
		degrees( atan( r.z, length( r.xy ) ) ),
		degrees( atan( r.y, r.x ) ),
		length(r) );
}

mat3 bearing2B( vec3 r, float bearing )
{
	if( dot( r.xy, r.xy ) > 0. )
	{
		vec3 east = normalize( cross( UNIT_Z, r ) );
		vec3 north = normalize( cross( r, east ) );
		vec2 scb = sincospi( bearing / 180. );
		vec3 dir = scb.y * north + scb.x * east;
		return mat3( dir, -normalize( cross( r, dir ) ), -normalize(r) );
	}
	else
	{
		vec3 dir = vec3( cos( radians( bearing ) ), sin( radians( bearing ) ), 0 );
		return mat3( dir, -normalize( cross( r, dir ) ), -normalize(r) );
	}
}

float B2bearing( vec3 r, vec3 B )
{
	vec3 east = normalize( cross( UNIT_Z, r ) );
	vec3 north = normalize( cross( r, east ) );
	return mod( degrees( atan( dot( B, east ), dot( B, north ) ) ), 360. );
}

vec4 navb( vec3 r, vec3 B )
	{ return vec4( r2nav(r), B2bearing( r, B ) ); }

// ****************************************************************************
// STATIC DATA
// ****************************************************************************

// ----------------------------------------------------------------------------
// START DATA
// ----------------------------------------------------------------------------

struct StartData
{
	uvec4 name;
	ivec4 iparams;
	vec4 params;
};

const int START_DATA_SIZE = 3;
const int START_DATA_COUNT = 25;

ivec2 st_addr( int index )
	{ return ADDR_START_DATA + ivec2( index, 0 ); }

bool in_st_range( ivec2 sc )
	{ return in_addr_range( sc, ADDR_START_DATA, START_DATA_SIZE, START_DATA_COUNT ); }

StartData st_load( sampler2D ch, ivec2 addr )
{
	return StartData(
		unpack_uvec4( memload( ch, addr, 0 ) ),
		ivec4( memload( ch, addr, 1 ) ),
		memload( ch, addr, 2 ) );
}

void st_store( StartData self, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( pack_uvec4( self.name ), addr, 0, sc, fc );
	memstore( vec4( self.iparams ), addr, 1, sc, fc );
	memstore( self.params, addr, 2, sc, fc );
}

// ----------------------------------------------------------------------------
// ZONE DATA
// ----------------------------------------------------------------------------

struct ZoneData
{
	vec4 zone;			// xy = lat/long, z = size, w = bearing of local grid
	uvec4 name;			// phrase of zone name
};

const int ZONE_DATA_SIZE = 2;
const int ZONE_DATA_COUNT = ( ADDR_B_SCENE_DATA - ADDR_B_ZONE_DATA ) / ZONE_DATA_SIZE;

ivec2 zd_addr_b( int index )
	{ return ivec2( 0, ADDR_B_ZONE_DATA + ZONE_DATA_SIZE * index ); }

ZoneData zd_load( sampler2D ch, ivec2 addr )
{
	return ZoneData(
		memload( ch, addr, 0 ),
		unpack_uvec4( memload( ch, addr, 1 ) ) );
}

vec4 zd_trn_zone( ZoneData self, float radius )
	{ return vec4( nav2r( vec3( self.zone.xy, 1 ) ), self.zone.z * SCN_SCALE / radius ); }

void zd_store( ZoneData self, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( self.zone, addr, 0, sc, fc );
	memstore( pack_uvec4( self.name ), addr, 1, sc, fc );
}

// ----------------------------------------------------------------------------
// SCENE DATA
// ----------------------------------------------------------------------------

struct SceneData
{
	vec4 tybr;			// x = type, y = bounding radius, z = zone index
	vec4 navb;			// x = lat, y = long, z = alt, w = heading
	vec4 paramsA;
	vec4 paramsB;
};

const int SCENE_DATA_SIZE = 4;
const int SCENE_DATA_COUNT = 77;

ivec2 sd_addr_b( int index )
	{ return ivec2( 0, ADDR_B_SCENE_DATA + SCENE_DATA_SIZE * index ); }

SceneData sd_load( sampler2D ch, ivec2 addr )
{
	return SceneData(
		memload( ch, addr, 0 ),
		memload( ch, addr, 1 ),
		memload( ch, addr, 2 ),
		memload( ch, addr, 3 ) );
}

void sd_store( SceneData self, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( self.tybr, addr, 0, sc, fc );
	memstore( self.navb, addr, 1, sc, fc );
	memstore( self.paramsA, addr, 2, sc, fc );
	memstore( self.paramsB, addr, 3, sc, fc );
}

const int SCNOBJ_TYPE_INVALID = 0;
const int SCNOBJ_TYPE_2D = 1000;
const int SCNOBJ_TYPE_RUNWAY = 1001;
const int SCNOBJ_TYPE_3D = 2000;
const int SCNOBJ_TYPE_PRIMITIVE = 2001;
const int SCNOBJ_TYPE_COMPOUND = 3000;
const int SCNOBJ_TYPE_TOWER = 3001;
const int SCNOBJ_TYPE_LIGHTHOUSE = 3002;

const int SCNOBJ_PRIMITIVE_SPHERE = 1;
const int SCNOBJ_PRIMITIVE_CUBE = 2;
const int SCNOBJ_PRIMITIVE_CYLINDER = 3;

// ----------------------------------------------------------------------------
// KEPLER ORBITAL ELEMENTS
// ----------------------------------------------------------------------------

struct Kepler
{
	float p;		// semi-latus rectum
	float e;		// eccentricity
	float i;		// inclination
	float O;		// longitude of ascending node (Omega)
	float w;		// argument of periapsis (omega)
};

#define KEPLERA( a, e, i, O, w ) Kepler( a * ( 1. - (e) ) * ( 1. + (e) ), e, i, O, w )

float kp_semimajor( Kepler self )
	{ return self.p / ( 1. - self.e * self.e ); }

float kp_init( inout Kepler self, vec3 r, vec3 v, float GM )
{
	float nu = 0.;
	float r2 = dot( r, r );
	vec3 h = cross( r, v );
	float h2 = dot( h, h );
	float H = sqrt( h2 );
	float R = sqrt( r2 );
	vec3 e = cross( v, h ) / GM - r / R;
	float e2 = dot( e, e );
	self.e = sqrt( e2 );
	self.p = h2 / GM;
	float cosi = clamp( h.z / H, -1., 1. );
	self.i = atan( length( h.xy ), h.z );
	self.O = ( cosi == 1. ? 0. : cosi == -.1 ? PI : atan( h.x, -h.y ) );
	if( self.e >= .00005 )
	{
		float arglong =
			cosi == 1. ? atan( r.y, r.x ) :
			cosi == -1. ? atan( r.y, -r.x ) :
			atan( r.z * H, r.y * h.x - r.x * h.y );
		float u = self.p - R;
		float vH = dot( r, cross( h, e ) );
		nu = atan( vH, u * H );
		self.w = arglong - nu;
	}
	else
		self.w = 0.;
	return nu;
}

void kp_get_vectors( Kepler self, float nu, float dnudt90,
						 inout vec3 out_r, inout vec3 out_v )
{
	float opecn = 1. + self.e * cos(nu);
	float R = self.p / opecn;
	float u = R * cos( self.w + nu );
	float v = R * sin( self.w + nu );
	float sini = sin( self.i );
	float cosi = cos( self.i );
	float sinO = sin( self.O );
	float cosO = cos( self.O );

	out_r = vec3( u * cosO - v * sinO * cosi,
				  u * sinO + v * cosO * cosi,
				  v * sini );

	float dRdnu = self.p * self.e * sin(nu) /* / ( opecn * opecn ) */;
	float dudnu = dRdnu * cos( self.w + nu ) - self.p * opecn * sin( self.w + nu ) /* / ( opecn * opecn ) */;
	float dvdnu = dRdnu * sin( self.w + nu ) + self.p * opecn * cos( self.w + nu ) /* / ( opecn * opecn ) */;
	float dnudt = dnudt90 /* * opecn * opecn */;

	out_v = dnudt * vec3( dudnu * cosO - dvdnu * sinO * cosi,
						  dudnu * sinO + dvdnu * cosO * cosi,
						  dvdnu * sini );
}

vec4 kp_nu2E_d( vec4 nu, float e )
{
	return e < 1. ?
		2. * atan2_d( sqrt( 1. - e ) * sin_d( nu / 2. ), sqrt( 1. + e ) * cos_d( nu / 2. ) ) :
		2. * atanh_d( sqrt( ( e - 1. ) / ( e + 1. ) ) * tan_d( nu / 2. ) ); // = inverse Gudermann
}

vec4 kp_E2M_d( vec4 E, float e )
	{ return e < 1. ? E - e * sin_d(E) : e * sinh_d(E) - E; }

float kp_nu2E( float nu, float e )
	{ return kp_nu2E_d( const_d( nu ), e ).w; }

float kp_E2M( float E, float e )
	{ return kp_E2M_d( const_d(E), e ).w; }

// ----------------------------------------------------------------------------
// ATMOSPHERE THERMODYNAMIC PROFILE DATA
// ----------------------------------------------------------------------------

struct AtmProfile
{
	vec4 ref;				// properties at reference altitude (temperature, pressure, density, pressure scale height)
	vec3 exo;				// exospheric temperature profile (exobase, T_infinity, temperature scale height)
	float ssref;			// speed of sound at reference altitude
	mat4x2 pointsA;			// temperature profile points 1..4
	mat4x2 pointsB;			// temperature profile points 5..8
	vec3 lvar;				// params for latitudinal variation
	mat2x3 svar;			// params for seasonal variation
	vec2 dvar;				// params for diurnal variation
	vec3 ref2;				// dynamic viscosity (mu) at ref., Sutherland constant, inverse Jennings constant
	vec3 cp;				// parameters for specific heat: cp = x + T y / z: specific gas constant RM
	vec3 dcpdh;				// change of cp parameters with altitude
	vec2 K;					// Sutton-Graves heat transfer coefficient (x continuum flow, y molecular flow)
};

const int ATM_PROFILE_SIZE = 12;

AtmProfile ap_load( sampler2D ch, ivec2 addr )
{
	return AtmProfile(
		memload( ch, addr, 0 ),
		memload( ch, addr, 1 ).xyz,
		memload( ch, addr, 1 ).w,
		mat4x2( memload( ch, addr, 2 ), memload( ch, addr, 3 ) ),
		mat4x2( memload( ch, addr, 4 ), memload( ch, addr, 5 ) ),
		memload( ch, addr, 6 ).xyz,
		mat2x3( memload( ch, addr, 7 ).xyz, memload( ch, addr, 8 ).xyz ),
		memload_www( ch, addr, 6 ).xy,
		memload( ch, addr, 9 ).xyz,
		memload( ch, addr, 10 ).xyz,
		memload_www( ch, addr, 8 ).xyz,
		memload( ch, addr, 11 ).xy
	);
}

void ap_store( AtmProfile self, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( self.ref, addr, 0, sc, fc );
	memstore( self.exo, self.ssref, addr, 1, sc, fc );
	memstore( self.pointsA[0], self.pointsA[1], addr, 2, sc, fc );
	memstore( self.pointsA[2], self.pointsA[3], addr, 3, sc, fc );
	memstore( self.pointsB[0], self.pointsB[1], addr, 4, sc, fc );
	memstore( self.pointsB[2], self.pointsB[3], addr, 5, sc, fc );
	memstore( self.lvar, self.dvar.x, addr, 6, sc, fc );
	memstore( self.svar[0], self.dvar.y, addr, 7, sc, fc );
	memstore( self.svar[1], self.dcpdh.x, addr, 8, sc, fc );
	memstore( self.ref2, self.dcpdh.y, addr, 9, sc, fc );
	memstore( self.cp, self.dcpdh.z, addr, 10, sc, fc );
	memstore( self.K, vec2(0), addr, 11, sc, fc );
}

struct AtmProfileSample
{
	float T;		// local temperature
	float P;		// local pressure
	float rho;		// local density
	float a;		// local speed of sound
	float gamma;	// local ratio of specific heats
	float mu;		// local dynamic viscosity
	float lambda;	// local molecular mean free path
};

AtmProfileSample ap_sample( AtmProfile self, float hend, vec2 lphase, vec2 sphase, vec2 dphase )
{
	// get latitudinal, seasonal and diurnal variations
	vec3 lvar = self.lvar + self.svar * sphase;
	float dT_l = dot( lvar.xy, lphase ) + lvar.z;
	float dT_d = dot( normalize( lvar.xy ), lphase ) * dot( self.dvar.xy, dphase );

	// initial values
	float T0 = self.ref.x;
	float h = 0.;
	float z = 0.;
	float T = T0 + dT_l + dT_d;
	float profilescale = T / T0;

	// climb the piecewise linear temperature profile until h
	// (allow for negative h in the first iteration)
	for( int i = 0; i < 8 && hend != h; ++i )
	{
		vec2 point = i < 4 ? self.pointsA[i] : self.pointsB[i-4];
		float h1 = point.x * profilescale;
		float T1 = point.y * profilescale;
		if( T1 == 0. || h1 == h )
			break;
		float hnext = min( hend, h1 );
		if( T1 != T )
		{
			float lapse = ( T1 - T ) / ( h1 - h );
			float deltaT = lapse * ( hnext - h );
			z += log1p( deltaT / T ) * T0 / lapse;
			T = h1 != hnext ? T + deltaT : T1;
		}
		else
			z += ( hnext - h ) * T0 / T;
		h = hnext;
	}

	// assume constant temperature above profile
	float thermobase = self.exo.x * profilescale;
	z += max( 0., min( thermobase > 0. ? thermobase : hend, hend ) - h ) * T0 / T;

	// apply Bates-Walker formula for exospheric altitudes
	float exotemp = self.exo.y * profilescale;
	float exoscale = self.exo.z * profilescale;
	float rho0 = self.ref.z;
	if( exotemp > 0. && exoscale > 0. )
	{
		float a = max( 0., hend - thermobase ) / exoscale;
		float b = exoscale * T0 / exotemp;
		if( a < 16. )
			z += log1p( expm1( a ) * exotemp / T ) * b;
		else
			z += ( a + log( exotemp / T ) ) * b;
		T = mix( T, exotemp, -expm1( -a ) );
		rho0 *= mix( 1., .035, min( 1., a / 16. ) );
	}

	// final result
	float P = self.ref.y * exp( -z / self.ref.w );
	float rho = rho0 * self.ref.x * P / ( self.ref.y * T );
	float cp = self.cp.x + self.cp.y * T;
	float gamma = safediv( cp, cp - self.cp.z );
	float a = sqrt( gamma * self.cp.z * T / 1000. );
	float mu = self.ref2.x * safediv( T0 + self.ref2.y, T + self.ref2.y ) * pow( T / T0, 1.5 );
	float lambda = SQRTPIOVER8 * mu * self.ref2.z * inversesqrt( 100000. * P * rho );
	return AtmProfileSample( T, P, rho, a, gamma, mu, lambda );
}

// ----------------------------------------------------------------------------
// ATMOSPHERE VISUAL MODEL DATA
// ----------------------------------------------------------------------------

struct AtmModel
{
	float scale;			// effective optical scale height
	float g;				// effective overall asymmetry parameter
	vec4  tau;				// total optical depth
	vec4  tau_s;			// total optical depth (scattering only)
	vec4  glayer_tau;		// ground layer: optical depth,
	vec4  glayer_tau_s;		// ground layer: optical depth (scattering only)
	float glayer_scale;		// ground layer: scale height multiplier
	vec4  alayer_tau;		// absorbtion layer: optical depth
	vec2  alayer_shape;		// absorbtion layer: mu, sigma of altitude profile
	vec4  elayer_emiss;		// emission layer: column emission
	vec2  elayer_shape;		// emission layer: mu, sigma of altitude profile
};

const int ATM_MODEL_SIZE = 8;

AtmModel am_load( sampler2D ch, ivec2 addr )
{
	return AtmModel(
		memload( ch, addr, 0 ).x,
		memload( ch, addr, 0 ).y,
		memload( ch, addr, 1 ),
		memload( ch, addr, 2 ),
		memload( ch, addr, 3 ),
		memload( ch, addr, 4 ),
		memload( ch, addr, 0 ).z,
		memload( ch, addr, 5 ),
		memload( ch, addr, 7 ).xy,
		memload( ch, addr, 6 ),
		memload( ch, addr, 7 ).zw );
}

void am_store( AtmModel self, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( vec3( self.scale, self.g, self.glayer_scale ), 0., addr, 0, sc, fc );
	memstore( self.tau, addr, 1, sc, fc );
	memstore( self.tau_s, addr, 2, sc, fc );
	memstore( self.glayer_tau, addr, 3, sc, fc );
	memstore( self.glayer_tau_s, addr, 4, sc, fc );
	memstore( self.alayer_tau, addr, 5, sc, fc );
	memstore( self.elayer_emiss, addr, 6, sc, fc );
	memstore( self.alayer_shape, self.elayer_shape, addr, 7, sc, fc );
}

// ----------------------------------------------------------------------------
// PLANET DATA
// ----------------------------------------------------------------------------

struct TrnLayer
{
	vec4 color;
	vec4 detail;
	vec4 weights;
	float offset;
	float lower;
	float upper;
};

const int TRN_LAYER_SIZE = 4;

TrnLayer tl_load( sampler2D ch, ivec2 addr )
{
	return TrnLayer(
		memload( ch, addr, 0 ),
		memload( ch, addr, 1 ),
		memload( ch, addr, 2 ),
		memload( ch, addr, 3 ).x,
		memload( ch, addr, 3 ).y,
		memload( ch, addr, 3 ).z );
}

void tl_store( TrnLayer self, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( self.color, addr, 0, sc, fc );
	memstore( self.detail, addr, 1, sc, fc );
	memstore( self.weights, addr, 2, sc, fc );
	memstore( vec3( self.offset, self.lower, self.upper ), 0., addr, 3, sc, fc );
}

struct TrnData
{
	vec3 seeds;			// seed offsets x, y, z
	vec3 levels;		// min level, max level, ocean level
	vec3 offcenter;		// optional center displacement
	vec3 noise;			// noise amplitude, log-normal-distribution: mu, sigma
	vec3 flatten;		// flatten modifier: base level, range, reduction amount
	vec3 slope;			// slope modifiers: slope scale, divergence, slip
};

const int TRN_DATA_SIZE = 5;

TrnData td_load( sampler2D ch, ivec2 addr )
{
	return TrnData(
		memload( ch, addr, 0 ).xyz,
		memload( ch, addr, 1 ).xyz,
		memload( ch, addr, 2 ).xyz,
		memload_www( ch, addr, 0 ),
		memload( ch, addr, 3 ).xyz,
		memload( ch, addr, 4 ).xyz );
}

void td_store( TrnData self, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( self.seeds, self.noise.x, addr, 0, sc, fc );
	memstore( self.levels, self.noise.y, addr, 1, sc, fc );
	memstore( self.offcenter, self.noise.z, addr, 2, sc, fc );
	memstore( self.flatten, 0., addr, 3, sc, fc );
	memstore( self.slope, 0., addr, 4, sc, fc );
}

struct OcnData
{
	vec4 beta50;		// ocean absorbtion coefficients (exp2 based)
	vec4 omega;			// ocean optical albedo
	vec4 paramsA;		// ocean temperature / density / optical roughness (slope variance) / speed of sound;
	vec4 paramsB;		// ocean dynamic viscosity / avg molecular distance / gamma / cp
};

const int OCN_DATA_SIZE = 4;

OcnData od_load( sampler2D ch, ivec2 addr )
{
	return OcnData(
		memload( ch, addr, 0 ),
		memload( ch, addr, 1 ),
		memload( ch, addr, 2 ),
		memload( ch, addr, 3 ) );
}

void od_store( OcnData self, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( self.beta50, addr, 0, sc, fc );
	memstore( self.omega, addr, 1, sc, fc );
	memstore( self.paramsA, addr, 2, sc, fc );
	memstore( self.paramsB, addr, 3, sc, fc );
}

struct CldData
{
	vec3 akg;				// alt / k50max / g
	vec3 fluff;				// bottom strength / top strength / fade range
	vec2 size;				// noise size / fluff size
	vec4 noise;				// influence of const / sin3lat2 / noise / vertical
	vec4 move;				// phase offset / move speed / fluff move / fluff rotate
};

const int CLD_DATA_SIZE = 4;

CldData cd_load( sampler2D ch, ivec2 addr )
{
	return CldData(
		memload( ch, addr, 0 ).xyz,
		memload( ch, addr, 1 ).xyz,
		memload_www( ch, addr, 0 ).xy,
		memload( ch, addr, 2 ),
		memload( ch, addr, 3 ) );
}

void cd_store( CldData self, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( self.akg, self.size.x, addr, 0, sc, fc );
	memstore( self.fluff, self.size.y, addr, 1, sc, fc );
	memstore( self.noise, addr, 2, sc, fc );
	memstore( self.move, addr, 3, sc, fc );
}

struct PlanetData
{
	float parent;			// parent index
	float radius;			// planet radius (datum)
	float GM;				// standard gravitational parameter
	float orb_period;		// orbital period (hours)
	float rot_period;		// rotation period (hours)
	vec2 rot_northpole;		// lat/long of north pole in ecliptic coordinates
	Kepler orbit;			// orbital elements
	TrnData trn;
	TrnLayer[6] lyr;
	OcnData ocn;
	AtmProfile ap;
	AtmModel am;
	CldData cld;
};

const int PLANET_DATA_SIZE = 3 + TRN_DATA_SIZE + 6 * TRN_LAYER_SIZE + OCN_DATA_SIZE + ATM_PROFILE_SIZE + ATM_MODEL_SIZE + CLD_DATA_SIZE;
const int PLANET_DATA_COUNT = 3;

ivec2 pd_addr( int index )
	{ return ADDR_PLANET_DATA + ivec2( index, 0 ); }

int pd_layer_addr( int index )
	{ return 3 + TRN_DATA_SIZE + TRN_LAYER_SIZE * index; }

bool in_pd_range( ivec2 sc )
	{ return in_addr_range( sc, ADDR_PLANET_DATA, PLANET_DATA_SIZE, PLANET_DATA_COUNT ); }

PlanetData pd_load( sampler2D ch, ivec2 addr )
{
	return PlanetData(
		memload( ch, addr, 0 ).x, memload( ch, addr, 0 ).y,
		memload( ch, addr, 0 ).z, memload( ch, addr, 0 ).w,
		memload( ch, addr, 1 ).x, memload( ch, addr, 1 ).yz,
		Kepler( memload( ch, addr, 1 ).w, memload( ch, addr, 2 ).x,
				memload( ch, addr, 2 ).y, memload( ch, addr, 2 ).z,
				memload( ch, addr, 2 ).w ),
		td_load( ch, addr + ivec2( 0, 3 ) ),
		TrnLayer[6](
			tl_load( ch, addr + ivec2( 0, pd_layer_addr(0) ) ),
			tl_load( ch, addr + ivec2( 0, pd_layer_addr(1) ) ),
			tl_load( ch, addr + ivec2( 0, pd_layer_addr(2) ) ),
			tl_load( ch, addr + ivec2( 0, pd_layer_addr(3) ) ),
			tl_load( ch, addr + ivec2( 0, pd_layer_addr(4) ) ),
			tl_load( ch, addr + ivec2( 0, pd_layer_addr(5) ) ) ),
		od_load( ch, addr + ivec2( 0, pd_layer_addr(6) ) ),
		ap_load( ch, addr + ivec2( 0, pd_layer_addr(6) + OCN_DATA_SIZE ) ),
		am_load( ch, addr + ivec2( 0, pd_layer_addr(6) + OCN_DATA_SIZE + ATM_PROFILE_SIZE ) ),
		cd_load( ch, addr + ivec2( 0, pd_layer_addr(6) + OCN_DATA_SIZE + ATM_PROFILE_SIZE + ATM_MODEL_SIZE ) )
	);
}

void pd_store( PlanetData self, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( vec4( self.parent, self.radius, self.GM, self.orb_period ), addr, 0, sc, fc );
	memstore( vec4( self.rot_period, self.rot_northpole, self.orbit.p ), addr, 1, sc, fc );
	memstore( vec4( self.orbit.e, self.orbit.i, self.orbit.O, self.orbit.w ), addr, 2, sc, fc );
	td_store( self.trn, addr + ivec2( 0, 3 ), sc, fc );
	tl_store( self.lyr[0], addr + ivec2( 0, pd_layer_addr(0) ), sc, fc );
	tl_store( self.lyr[1], addr + ivec2( 0, pd_layer_addr(1) ), sc, fc );
	tl_store( self.lyr[2], addr + ivec2( 0, pd_layer_addr(2) ), sc, fc );
	tl_store( self.lyr[3], addr + ivec2( 0, pd_layer_addr(3) ), sc, fc );
	tl_store( self.lyr[4], addr + ivec2( 0, pd_layer_addr(4) ), sc, fc );
	tl_store( self.lyr[5], addr + ivec2( 0, pd_layer_addr(5) ), sc, fc );
	od_store( self.ocn, addr + ivec2( 0, pd_layer_addr(6) ), sc, fc );
	ap_store( self.ap, addr + ivec2( 0, pd_layer_addr(6) + OCN_DATA_SIZE ), sc, fc );
	am_store( self.am, addr + ivec2( 0, pd_layer_addr(6) + OCN_DATA_SIZE + ATM_PROFILE_SIZE ), sc, fc );
	cd_store( self.cld, addr + ivec2( 0, pd_layer_addr(6) + OCN_DATA_SIZE + ATM_PROFILE_SIZE + ATM_MODEL_SIZE ), sc, fc );
}

float pd_overarch( PlanetData planet )
{
	// normalized distance to horizon observable from one scale-height altitude;
	// used as a measure of terminator 'over-arch'
	return safediv(
		sqrt( planet.am.scale * ( 2. * planet.radius + planet.am.scale ) ),
		planet.radius + planet.am.scale );
}

// ----------------------------------------------------------------------------
// VEHICLE DATA
// ----------------------------------------------------------------------------

struct VehicleData
{
	vec4 Sbcm;					// area (S), span (b), chord (c) and mass (m)
	vec4 I;						// moments of inertia (Ixx, Iyy, Izz, Ixz)
	vec2 RekD;                  // reference Reynolds number (throusands), kD

	// stability coeffs
	vec4 CD;					// CD0, CDa2, CDb2, CDi
	vec4 CL;					// CL0, CLa, CLq, CLde
	vec4 Cm;					// Cm0, Cma, Cmq, Cmde
	vec4 CY;					// CYb, CYp, CYr, CYdr
	vec4 Cn;					// Cnb, Cnp, Cnr, Cndr
	vec4 Cl;					// Clb, Clp, Clr, Clda
	vec4 C90;					// Cm90, Cmq90, Cnb90, Clb90
	vec2 Cadot;					// CLadot, Cmadot
	vec2 Cside;					// Cnside, Cnrside
	vec2 Cmisc;					// Clab, Cmi

	// extra stuff
	vec4 mach;					// MDD, delta-CD mach 1, delta-CD mach inf, onset of newton regime
	vec2 rare;					// x = reference Knudsen number for aero effects, y = unused
	vec4 ground;				// xy = rel change CL and Cm, z = scale height in units of b, w = wake delay parameter

	// configuration stuff
	mat3 config;				// [0] = flaps, [1] = spoilers, [2] = gears; x = delta-CD, y = delta-CL, z = delta-Cm
	float gearClb;				// extra Clb when gears down

	// stall curve parameters
	vec4 etaCL;					// xy = input range, zw = output range

	// controls, thrust, heating
	vec3 dx_max;				// max control excursion, in radians (de, da, dr)
	float T_max;				// max thurst,
	vec4 Rn;					// nose cone radius (Rn) in xyz axis, w = ratio of wing area over frontal area
};

// ----------------------------------------------------------------------------
// MENU DATA
// ----------------------------------------------------------------------------

uvec4 md_load( sampler2D ch, int index )
	{ return unpack_uvec4( memload( ch, ADDR_MENU_DATA + ivec2( index, 0 ), 0 ) ); }

const int MENU_DATA_COUNT = 86;

const int MENU_IPAGE_BEGIN = 0x0e;
const int MENU_IPAGE_SIZE = 10;
const int MENU_DPAGE_BEGIN = 0x3c;
const int MENU_DPAGE_SIZE = 1;
const int MENU_DGRAPH_BEGIN = 0x44;
const int MENU_DGRAPH_SIZE = 3;
const int MENU_BDISP_BEGIN = 0x4a;
const int MENU_BDISP_SIZE = 4;
const int MENU_BMODE_BEGIN = 0x50;
const int MENU_BMODE_SIZE = 6;

// ****************************************************************************
// PRIMARY RUNTIME STATE - preseved between frames
// ****************************************************************************

// ----------------------------------------------------------------------------
// PLANET STATE
// ----------------------------------------------------------------------------

struct PlanetState
{
	// global coordinates
	vec3 r;				// position
	vec3 v;				// velocity
	float omega;		// angular velocity
	mat3 B;				// body frame

	// local coordinates
	vec3 orbitr;
	vec3 orbitv;

	// orbital parameters
	float M;			// mean anomaly
	float E;			// eccentric anomaly
	float nu;			// true anomaly
	float dnudt90;		// motion of true anomaly at latus rectum
};

const int PLANET_STATE_SIZE = 7;

ivec2 ps_addr( int index )
	{ return ADDR_PLANET_STATES + ivec2( index, 0 ); }

bool in_ps_sm_ac_range( ivec2 sc )
	{ return in_addr_range( sc, ADDR_PLANET_STATES, 48, PLANET_DATA_COUNT ); }

PlanetState ps_load( sampler2D ch, ivec2 addr )
{
	return PlanetState(
		memload( ch, addr, 0 ).xyz,
		memload( ch, addr, 1 ).xyz,
		memload( ch, addr, 2 ).x,
		memload_mat3( ch, addr, 3 ),
		memload_www( ch, addr, 0 ),
		memload_www( ch, addr, 3 ),
		memload( ch, addr, 6 ).x, memload( ch, addr, 6 ).y,
		memload( ch, addr, 6 ).z, memload( ch, addr, 6 ).w );
}

void ps_store( PlanetState self, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( self.r, self.orbitr.x, addr, 0, sc, fc );
	memstore( self.v, self.orbitr.y, addr, 1, sc, fc );
	memstore( vec3( self.omega, 0, 0 ), self.orbitr.z, addr, 2, sc, fc );
	memstore( self.B, self.orbitv, addr, 3, sc, fc );
	memstore( vec4( self.M, self.E, self.nu, self.dnudt90 ), addr, 6, sc, fc );
}

// ----------------------------------------------------------------------------
// VEHICLE STATE
// ----------------------------------------------------------------------------

struct VehicleState
{
	// global coordinates
	vec3 r;				// position
	vec3 v;				// velocity
	vec3 omega;			// angular velocity vector
	mat3 B;				// body frame

	// local orbit coordinates, non-rotating frame
	vec3 orbitr;
	vec3 orbitv;

	// local surface coordinates, rotating frame
	vec3 localr;
	vec3 localv;
	vec3 localomega;
	mat3 localB;

	// high precision accumulator for localr
	vec3 localr_base;
	vec3 localr_diff;

	// time-lagged vertical acceleration for flight dynamics
	vec3 acc;
	float wdelay;

	// vehicle configuration state
	vec3 FSG;			// flaps/spoilers/gears
	float throttle;
	vec3 EAR;			// elevator/aileron/rudder
	float trim;
	vec3 EAR_hold;		// hold timers for EAR
	float thr_hold;		// throttle hold timer

	// vehicle control state
	ivec3 modes;		// HMD/.../engine
	uint switches;		// bitfield
	ivec3 modes2;		// aero/rcs/throttle
	float tvec;			// thrust vector

	// other states
	vec4 aerostuff;		// state variables for aero control modes
	vec3 rcsstuff;		// state variables for rcs control modes
	float canopy;

	// read only
	vec4 info;			// CL, CD, alpha, contact
};

const int VEHICLE_STATE_SIZE = 21;

const int VS_MAX_ITER = 100;
const float VS_MAX_PACE_LOCAL = 0.25;
const float VS_MAX_PACE = 1.66666667;

const uint VS_SW_FLAPS_MASK = 3u;
const uint VS_SW_FLAPS_SHIFT = 0u;
const uint VS_SW_SPOIL = 4u;
const uint VS_SW_GEARS = 8u;
const uint VS_SW_LIGHT = 16u;
const uint VS_SW_THROTTLE_EDGE = 32u;
const uint VS_SW_TVEC_MASK = 960u;
const uint VS_SW_TVEC_SHIFT = 6u;
const uint VS_SW_CANOPY = 1024u;
const uint VS_SW_STEER = 2048u;

const float VS_FLAPS_MAX = 3.;
const float VS_TVEC_MAX = 10.;

float vs_flaps_notches( float n )
	{ return n * n / 9.; }

float vs_tvec_notches( float n )
	{ return n * ( n * ( n * .5 - 7.5 ) + 43. ); }

const int VS_ENG_OFF = 0;
const int VS_ENG_DRV = 1;
const int VS_ENG_IMP = 2;
const int VS_ENG_NOVA = 3;

const int VS_HMD_OFF = 0;
const int VS_HMD_SFCE = 1;
const int VS_HMD_ORB = 2;

const int VS_AERO_OFF = 0;
const int VS_AERO_MAN = 1;
const int VS_AERO_FBW = 2;

const int VS_RCS_OFF = 0;
const int VS_RCS_MAN = 1;
const int VS_RCS_RATE = 2;
const int VS_RCS_LVLH = 3;

const int VS_THR_OFF = 0;
const int VS_THR_MAN = 1;

bool in_vs_range( ivec2 sc )
	{ return in_addr_range( sc, ADDR_VEHICLE_STATE, VEHICLE_STATE_SIZE, 1 ); }

VehicleState vs_init()
{
	return VehicleState( ZERO, ZERO, ZERO, IDENTITY, ZERO, ZERO,
						 ZERO, ZERO, ZERO, IDENTITY, ZERO, ZERO,
						 ZERO, 0., ZERO, 0., ZERO, 0.,
						 ZERO, 0., ivec3(0), 0u, ivec3(0), 0.,
						 vec4(0), ZERO, 0., vec4(0) );
}

VehicleState vs_load( sampler2D ch, ivec2 addr )
{
	return VehicleState(
		memload( ch, addr, 0 ).xyz,
		memload( ch, addr, 1 ).xyz,
		memload( ch, addr, 2 ).xyz,
		memload_mat3( ch, addr, 3 ),
		memload_www( ch, addr, 0 ),
		memload_www( ch, addr, 3 ),
		memload( ch, addr, 6 ).xyz,
		memload( ch, addr, 7 ).xyz,
		memload( ch, addr, 8 ).xyz,
		memload_mat3( ch, addr, 9 ),
		memload_www( ch, addr, 6 ),
		memload_www( ch, addr, 9 ),
		memload( ch, addr, 12 ).xyz,
		memload( ch, addr, 12 ).w,
		memload( ch, addr, 13 ).xyz,
		memload( ch, addr, 13 ).w,
		memload( ch, addr, 14 ).xyz,
		memload( ch, addr, 14 ).w,
		memload( ch, addr, 15 ).xyz,
		memload( ch, addr, 15 ).w,
		ivec3( memload( ch, addr, 16 ).xyz ),
		uint( memload( ch, addr, 16 ).w ),
		ivec3( memload( ch, addr, 17 ).xyz ),
		memload( ch, addr, 17 ).w,
		memload( ch, addr, 18 ),
		memload( ch, addr, 19 ).xyz,
		memload( ch, addr, 19 ).w,
		memload( ch, addr, 20 ) );
}

VehicleState vs_load_or_init( sampler2D ch, ivec2 addr, bool init )
	{ if( init ) return vs_init(); else return vs_load( ch, addr ); }

void vs_store( VehicleState self, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( self.r, self.orbitr.x, addr, 0, sc, fc );
	memstore( self.v, self.orbitr.y, addr, 1, sc, fc );
	memstore( self.omega, self.orbitr.z, addr, 2, sc, fc );
	memstore( self.B, self.orbitv, addr, 3, sc, fc );
	memstore( self.localr, self.localr_base.x, addr, 6, sc, fc );
	memstore( self.localv, self.localr_base.y, addr, 7, sc, fc );
	memstore( self.localomega, self.localr_base.z, addr, 8, sc, fc );
	memstore( self.localB, self.localr_diff, addr, 9, sc, fc );
	memstore( self.acc, self.wdelay, addr, 12, sc, fc );
	memstore( self.FSG, self.throttle, addr, 13, sc, fc );
	memstore( self.EAR, self.trim, addr, 14, sc, fc );
	memstore( self.EAR_hold, self.thr_hold, addr, 15, sc, fc );
	memstore( vec3( self.modes ), float( self.switches ), addr, 16, sc, fc );
	memstore( vec3( self.modes2 ), self.tvec, addr, 17, sc, fc );
	memstore( self.aerostuff, addr, 18, sc, fc );
	memstore( self.rcsstuff, self.canopy, addr, 19, sc, fc );
	memstore( self.info, addr, 20, sc, fc );
}

// ----------------------------------------------------------------------------
// MESSAGE QUEUE STATE
// ----------------------------------------------------------------------------

struct MsgQueue
{
	vec4 state;
	uvec4 phrase;
	vec4 argv;
};

const int MSG_QUEUE_SIZE = 13;

bool mq_empty( MsgQueue msg )
	{ return msg.state.x == -1.; }

int mq_index( ivec2 sc )
	{ return ( sc.x - ADDR_MSG_QUEUE.y - 1 ) % TXT_MSG_MAX_PHRASES; }

MsgQueue mq_init()
	{ return MsgQueue( vec4( -1, 0, 0, 0 ), uvec4(0), vec4(0) ); }

MsgQueue mq_load_and_pace_or_init( sampler2D ch, ivec2 addr, int index, float dt, bool init )
{
	if( init )
		return mq_init();

	MsgQueue msg;
	msg.state = memload( ch, addr, 0 );

	if( !mq_empty( msg ) )
	{
		if( msg.state.y > 0. )
		{
			dt -= msg.state.y;
			msg.state.y = max( 0., -dt );
		}

		if( msg.state.y == 0. )
		{
			float p = ceil( msg.state.x ) - 1.;
			float q = msg.state.x - dt;

			if( q < p )
			{
				msg.state.x = p;
				uint nextphraselen = unpack_uvec4( memload( ch, addr, 2 ) ).w & TXT_FMT_LENGTH_MASK;
				if( p >= 0. && nextphraselen > 0u )
					msg.state.y = 1.5 + float( nextphraselen ) / 8. + q - p;
				index++;
			}
			else
				msg.state.x = max( -1., floor(q) ) + fract(q);
		}
	}

	if( index < 0 || index >= TXT_MSG_MAX_PHRASES )
	{
		msg.phrase = uvec4(0);
		msg.argv = vec4(0);
	}
	else
	{
		msg.phrase = unpack_uvec4( memload( ch, addr, index + 1 ) );
		msg.argv = memload( ch, addr, index + 1 + TXT_MSG_MAX_PHRASES );
	}

	return msg;
}

void mq_push( inout MsgQueue self, int index, uvec4 phrase, vec4 argv )
{
	if( self.state.x < float( TXT_MSG_MAX_PHRASES - 2 ) )
	{
		if( self.state.x < 0. )
			self.state.x++;
		self.state.x++;
		if( int( ceil( self.state.x ) ) == index )
		{
			self.phrase = phrase;
			self.argv = argv;
		}
	}
}

bool mq_push_if_empty( inout MsgQueue self, int index, uvec4 phrase, vec4 argv )
{
	if( mq_empty( self ) )
		{ mq_push( self, index, phrase, argv ); return true; }
	return false;
}

void mq_push( inout MsgQueue self, int index, uvec4 phrase )
	{ mq_push( self, index, phrase, vec4(0) ); }


bool mq_push_if_empty( inout MsgQueue self, int index, uvec4 phrase )
	{ return mq_push_if_empty( self, index, phrase, vec4(0) ); }

void mq_store( MsgQueue self, int index, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( self.state, addr, 0, sc, fc );
	if( index >= 0 && index < TXT_MSG_MAX_PHRASES )
	{
		memstore( pack_uvec4( self.phrase ), addr, index + 1, sc, fc );
		memstore( self.argv, addr, index + 1 + TXT_MSG_MAX_PHRASES, sc, fc );
	}
}

// ----------------------------------------------------------------------------
// GAME STATE
// ----------------------------------------------------------------------------

struct GameState
{
	vec3 campos;
	float camzoom;
	mat3 camframe;
	vec3 mouselook;
	vec3 datetime;
	uint switches;		// bitfield
	ivec3 menustate;	// x = current page, y = selection trigger, z = last selection persist
	int stage;
	vec3 mapmarker;
	float timer;
	vec3 waypoint;
	float hudbright;
	vec2 exposure;
	vec2 dragstate;
	vec3 campos_diff;
	uint dbg_switches;
	vec3 vjoy;			// virtual joystick from keyboard input
	vec3 vjoy_hold;		// latch timers
	vec3 campos_baserel;
};

const int GAME_STATE_SIZE = 13;

const uint GS_SW_IRCAM = 1u;
const uint GS_SW_TRDAR = 2u;
const uint GS_SW_NVISN = 4u;
const uint GS_SW_TRMAP = 8u;
const uint GS_SW_PAUSE = 16u;
const uint GS_SW_FREEZ = 32u;
const uint GS_SW_CHEES = 64u;
const uint GS_SW_IPAGE_MASK = 0xf00u;
const uint GS_SW_IPAGE_SHIFT = 8u;
const uint GS_SW_MMODE_MASK = 0x3000u;
const uint GS_SW_MMODE_SHIFT = 12u;
const uint GS_SW_MPROJ_MASK = 0xc000u;
const uint GS_SW_MPROJ_SHIFT = 14u;
const uint GS_SW_HMD_BRIGHT_MASK = 0x30000u;
const uint GS_SW_HMD_BRIGHT_SHIFT = 16u;
const uint GS_SW_SUBSAMPLE_MASK = 0xc0000u;
const uint GS_SW_SUBSAMPLE_SHIFT = 18u;

const int GS_INFO_LOCATION = 1;
const int GS_INFO_WAYPOINT = 2;
const int GS_INFO_ORBIT = 3;
const int GS_INFO_GLIDE = 4;
const int GS_INFO_CONTROLS = 5;
const int GS_INFO_AIR_STATIC = 6;
const int GS_INFO_AIR_DYNAMIC = 7;
const int GS_INFO_TEMPERATURE = 8;
const int GS_INFO_TIME = 9;

const int GS_MAP_PHYSICAL = 0;
const int GS_MAP_ELEVATION = 1;
const int GS_MAP_SLOPE = 2;
const int GS_MAP_EQ_AREA = 0;
const int GS_MAP_EQ_ANGLE = 1;

const int GS_STAGE_STORE = -1;
const int GS_STAGE_INIT = 0;
const int GS_STAGE_SPLASH = 1;
const int GS_STAGE_SELECT_LOCATION = 2;
const int GS_STAGE_TRANSITION = 3;
const int GS_STAGE_RUNNING = 4;

const uint GS_DBG_DPAGE_MASK = 0xfu;
const uint GS_DBG_DPAGE_SHIFT = 0u;
const uint GS_DBG_DGRAPH_MASK = 0xf0u;
const uint GS_DBG_DGRAPH_SHIFT = 4u;
const uint GS_DBG_BDISP_MASK = 0xf00u;
const uint GS_DBG_BDISP_SHIFT = 8u;
const uint GS_DBG_BMODE_MASK = 0xf000u;
const uint GS_DBG_BMODE_SHIFT = 12u;

bool in_gs_range( ivec2 sc )
	{ return in_addr_range( sc, ADDR_GAME_STATE, GAME_STATE_SIZE, 1 ); }

bool in_game_update_range( ivec2 sc )
	{ return in_addr_range( sc, ADDR_GAME_STATE, 24, 16 ); }

GameState gs_init()
{
	return GameState( ZERO, 1., IDENTITY, UNIT_X, ZERO, 0x30000u, ivec3(0),
					  GS_STAGE_INIT, UNIT_X, 0., vec3(0), 1., vec2(1), vec2(0),
					  ZERO, 0u, ZERO, ZERO, ZERO );
}

GameState gs_load( sampler2D ch, ivec2 addr )
{
	return GameState(
		memload( ch, addr, 0 ).xyz,
		memload( ch, addr, 0 ).w,
		memload_mat3( ch, addr, 1 ),
		memload_www( ch, addr, 1 ),
		memload( ch, addr, 4 ).xyz,
		uint( memload( ch, addr, 4 ).w ),
		ivec3( memload( ch, addr, 5 ).xyz ),
		int( memload( ch, addr, 5 ).w ),
		memload( ch, addr, 6 ).xyz,
		memload( ch, addr, 6 ).w,
		memload( ch, addr, 7 ).xyz,
		memload( ch, addr, 7 ).w,
		memload( ch, addr, 8 ).xy,
		memload( ch, addr, 8 ).zw,
		memload( ch, addr, 9 ).xyz,
		uint( memload( ch, addr, 9 ).w ),
		memload( ch, addr, 10 ).xyz,
		memload( ch, addr, 11 ).xyz,
		memload( ch, addr, 12 ).xyz );

}

GameState gs_load_or_init( sampler2D ch, ivec2 addr, bool init )
	{ if( init ) return gs_init(); else return gs_load( ch, addr ); }

void gs_store( GameState self, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( self.campos, self.camzoom, addr, 0, sc, fc );
	memstore( self.camframe, self.mouselook, addr, 1, sc, fc );
	memstore( self.datetime, float( self.switches ), addr, 4, sc, fc );
	memstore( vec3( self.menustate ), float( self.stage ), addr, 5, sc, fc );
	memstore( self.mapmarker, self.timer, addr, 6, sc, fc );
	memstore( self.waypoint, self.hudbright, addr, 7, sc, fc );
	memstore( vec4( self.exposure.xy, self.dragstate ), addr, 8, sc, fc );
	memstore( self.campos_diff, float( self.dbg_switches ), addr, 9, sc, fc );
	memstore( self.vjoy, 0., addr, 10, sc, fc );
	memstore( self.vjoy_hold, 0., addr, 11, sc, fc );
	memstore( self.campos_baserel, 0., addr, 12, sc, fc );
}

vec2 gs_map_project( GameState gs, vec3 r )
{
	r = normalize(r) * gs.camframe;
	if( int( gs.switches & GS_SW_MPROJ_MASK ) >> GS_SW_MPROJ_SHIFT == GS_MAP_EQ_ANGLE )
		r.z = log( tan( atan( r.z, length( r.xy ) ) / 2. + PI / 4. ) );
	vec2 coord = vec2( atan( -r.y, -r.x ) , r.z );
	return gs.camzoom * coord;
}

vec4 gs_map_unproject_d( GameState gs, vec2 sc, vec2 res, inout vec3 ddx, inout vec3 ddy )
{
	vec4 coord_x = vec4( 2, 0, 0, 2. * sc.x - res.x ) / ( gs.camzoom * res.y );
	vec4 coord_y = vec4( 0, 2, 0, 2. * sc.y - res.y ) / ( gs.camzoom * res.y );
	vec4 c = coord_y;
	if( int( gs.switches & GS_SW_MPROJ_MASK ) >> GS_SW_MPROJ_SHIFT == GS_MAP_EQ_ANGLE )
		c = sin_d( 2. * atan_d( exp_d( coord_y ) ) - const_d( PIHALF ) );
	vec4 s = sqrt_d( max_d( const_d( 0. ), const_d( 1. ) - square_d( c ) ) );
	vec4 x = -mul_d( cos_d( coord_x ), s );
	vec4 y = -mul_d( sin_d( coord_x ), s );
	vec4 z = clamp_d( c, -ONE_D, ONE_D );
	ddx = gs.camframe * vec3( x.x, y.x, z.x );
	ddy = gs.camframe * vec3( x.y, y.y, z.y );
	return vec4( gs.camframe * vec3( x.w, y.w, z.w ), c.w );
}

vec4 gs_map_unproject( GameState gs, vec2 sc, vec2 res )
	{ vec3 _; return gs_map_unproject_d( gs, sc, res, _, _ ); }

float gs_get_subsample( GameState gs )
	{ return vec4( 1, 1.5, 2, 3 )[ ( gs.switches & GS_SW_SUBSAMPLE_MASK ) >> GS_SW_SUBSAMPLE_SHIFT ]; }

// ----------------------------------------------------------------------------
// ACHIEVEMENT DETECTOR STATE
// ----------------------------------------------------------------------------

struct AchieveDetect
{
   // landing tracker
   vec3 unused;
   int LT_state;
   vec3 LT_localv;
   float LT_timer;
};

const int ACHIEVE_DETECT_SIZE = 2;

const int AD_LT_INIT = 0;
const int AD_LT_LANDED = 1;
const int AD_LT_AIRBORNE = 2;
const int AD_LT_TOUCHDOWN = 3;
const int AD_LT_BELLYDOWN = 4;
const int AD_LT_CRASH = 5;

AchieveDetect ad_init()
	{ return AchieveDetect( ZERO, AD_LT_INIT, ZERO, 0. ); }

AchieveDetect ad_load( sampler2D ch, ivec2 addr )
{
	return AchieveDetect(
		ZERO,
		int( memload( ch, addr, 0 ).w ),
		memload( ch, addr, 1 ).xyz,
		memload( ch, addr, 1 ).w );
}

AchieveDetect ad_load_or_init( sampler2D ch, ivec2 addr, bool init )
	{ if( init ) return ad_init(); else return ad_load( ch, addr ); }

void ad_store( AchieveDetect self, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( ZERO, float( self.LT_state ), addr, 0, sc, fc );
	memstore( self.LT_localv, self.LT_timer, addr, 1, sc, fc );
}

// ----------------------------------------------------------------------------
// SPHERE MAP
// ----------------------------------------------------------------------------

struct SphereMap
{
	vec3 rn;			// normalized pivot position
	float r0;			// radius of hypocenter
	mat2x3 TB;			// tangent frame
	float e;			// mapping scale before sinh distortion
	float invm;			// mapping scale after sinh distortion
	float age;			// frames since last update
};

const int SPHERE_MAP_SIZE = 4;

bool in_sm_range( ivec2 sc )
	{ return in_addr_range( sc, ADDR_SPHERE_MAPS, SPHERE_MAP_SIZE, PLANET_DATA_COUNT ); }

bool in_sm_last_range( ivec2 sc )
	{ return in_addr_range( sc, ADDR_SPHERE_MAPS_LAST, SPHERE_MAP_SIZE, PLANET_DATA_COUNT ); }

bool in_sphere_maps_range( ivec2 sc )
	{ return in_addr_range( sc, ADDR_SPHERE_MAPS, 16, PLANET_DATA_COUNT ); }

ivec2 sm_addr( int index )
	{ return ADDR_SPHERE_MAPS + ivec2( index, 0 ); }

ivec2 sm_last_addr( int index )
	{ return ADDR_SPHERE_MAPS_LAST + ivec2( index, 0 ); }

SphereMap sm_init()
	{ return SphereMap( ZERO, 0., mat2x3(0), 0., 0., 0. ); }

SphereMap sm_load( sampler2D ch, ivec2 addr )
{
	return SphereMap(
		memload( ch, addr, 0 ).xyz,
		memload( ch, addr, 0 ).w,
		memload_mat2x3( ch, addr, 1 ),
		memload( ch, addr, 1 ).w,
		memload( ch, addr, 2 ).w,
		memload( ch, addr, 3 ).w );
}

SphereMap sm_load_or_init( sampler2D ch, ivec2 addr, bool init )
	{ if( init ) return sm_init(); else return sm_load( ch, addr ); }

void sm_store( SphereMap self, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( self.rn, self.r0, addr, 0, sc, fc );
	memstore( self.TB[0], self.e, addr, 1, sc, fc );
	memstore( self.TB[1], self.invm, addr, 2, sc, fc );
	memstore( ZERO, self.age, addr, 3, sc, fc );
}

vec2 sm_params( float r0, float r, float rd )
{
	float e = r0 / ( r - r0 );
	float h = sqrt( ( r + r0 ) * ( r - r0 ) );
	return vec2( e, 1. / pwasinh( e / r * ( max( h, rd ) + rd ) + min( e * rd / r, .5 ) ) );
}

SphereMap sm_init( vec3 r, float r0, float rmin, float rd, vec3 up )
{
	vec4 rn = length_normalize(r);
	vec2 params = sm_params( r0, max( rmin, rn.w ), rd );
	vec3 B = normalize( reject( up, rn.xyz ) );
	vec3 T = cross( B, rn.xyz );
	return SphereMap( rn.xyz, r0, mat2x3( T, B ), params.x, params.y, 0. );
}

float sm_scale( float r, float r0, float rd )
{
	vec2 params = sm_params( r0, r, rd );
	return params.x * params.y;
}

float sm_scale( vec3 r, float r0, float rmin, float rd )
	{ return sm_scale( max( rmin, length_normalize(r).w ), r0, rd ); }

float sm_limit_radius( float maxscale, float rd )
{
	float result;
	float rmin = 1.;
	float rmax = 2.;
	for( int i = 0; i < 24; ++i )
	{
		result = ( rmin + rmax ) / 2.;
		if( sm_scale( result, 1., rd ) < maxscale )
			rmax = result;
		else
			rmin = result;
	}
	return result;
}

float sm_r( SphereMap self )
	{ return self.r0 * ( 1. + 1. / self.e ); }

float sm_d( SphereMap self, float rd )
	{ return sqrt( ( rd + self.r0 ) * ( rd - self.r0 ) ); }

bool sm_is_valid( SphereMap self )
	{ return self.r0 > 0.; }

vec2 sm_uv_centered_baserel( SphereMap self, vec3 rn_baserel )
{
	vec2 x = rn_baserel * self.TB;
	vec2 l = length_invlength(x);
 	return x * ( l.y * pwasinh( self.e * l.x ) * self.invm );
}

vec2 sm_uv_centered( SphereMap self, vec3 rn )
	{ return sm_uv_centered_baserel( self, rn - self.rn ); }

vec2 sm_uv( SphereMap self, vec3 rn )
	{ return .5 + .5 * sm_uv_centered( self, rn ); }

float sm_lod( SphereMap self, float d )
	{ return self.e * self.invm * pwasinh_slope( self.e * d ); }

float sm_lod( SphereMap self, vec3 rn )
	{ return sm_lod( self, length( ( rn - self.rn ) * self.TB ) ); }

bool sm_is_uv_safe( SphereMap self, vec3 rn )
	{ return lensq( sm_uv_centered( self, rn ) ) < 1.; }

vec4 sm_uv_inverse_lod_centered_n( SphereMap self, vec2 uv )
{
	vec2 l = length_invlength( uv );
	float d = pwsinh( l.x / self.invm ) / self.e;
	if( d < 1. && l.x < 1. )
	{
		vec3 x = self.TB * uv * ( l.y * d ) + self.rn * cosasin(d);
		return vec4( x, sm_lod( self, d ) );
	}
	else
		return vec4(0);
}

vec4 sm_uv_inverse_lod_n( SphereMap self, vec2 uv )
	{ return sm_uv_inverse_lod_centered_n( self, 2. * uv - 1. ); }

vec4 sm_uv_inverse_lod( SphereMap self, vec2 uv )
{
	vec4 result = sm_uv_inverse_lod_centered_n( self, 2. * uv - 1. );
	return vec4( self.r0 * result.xyz, result.w );
}

void sm_update_stable( inout SphereMap self, vec3 r_base, vec3 r_diff, float new_h, float new_R,
	vec4 box, float rmin, float rd )
{
	bool update = true;
	if( sm_is_valid( self ) && sm_is_uv_safe( self, normalize( r_base + r_diff ) ) )
	{
		if( self.age < 4. )
			update = false;
		else
		{
			vec3 r_baserel = FORCE_EVAL( r_base - self.r0 * self.rn ) + r_diff;
			vec2 uvnew = sm_uv_centered_baserel( self, r_baserel / length( r_base + r_diff ) );
			update = length( uvnew ) >= min( .5, self.e * rd / sm_r( self ) ) * self.invm;
			float scalenew = sm_scale( r_base + r_diff, new_h + new_R, rmin, rd );
			float scaleold = self.e * self.invm;
			update = update || scalenew >= SQRTTWO * scaleold || SQRTTWO * scalenew < scaleold;
			if( update )
			{
				vec3 rn_from_uvnew = sm_uv_inverse_lod_centered_n( self, ( 2. * round( .5 * uvnew * box.zw ) ) / box.zw ).xyz;
				if( rn_from_uvnew != ZERO )
					r_diff = length( r_base + r_diff ) * rn_from_uvnew - r_base;
				else
					update = false;
			}
		}
	}
	if( update )
		self = sm_init( r_base + r_diff, new_h + new_R, rmin, rd, UNIT_Z );
	else
		self.age++;
}

void sm_update_stable( inout SphereMap self, vec3 r, float new_r0, vec4 box, float rmin, float rd )
	{ sm_update_stable( self, r, ZERO, 0., new_r0, box, rmin, rd ); }

bool sm_box_inside( vec4 box, vec2 fc )
	{ return all( lessThan( ( fc.xxyy - box.xxyy ) * vec2( 1, -1 ).xyxy, vec3( box.zw, 0 ).xzyz ) ); }

vec2 sm_fcoord_2_uv( vec2 fcoord, vec4 box )
	{ return ( fcoord - box.xy ) / box.zw; }

vec4 sm_unpack_normal( SphereMap self, vec4 tsmpl )
{
	vec3 N = self.TB * tsmpl.xy + self.rn * sqrt( max( 0., 1. - dot( tsmpl.xy, tsmpl.xy ) ) );
	return vec4( N, tsmpl.w );
}

vec4 sm_lookup_centered( sampler2D ch, vec4 box, vec2 uv )
{
	vec2 res = vec2( textureSize( ch, 0 ) );
	vec2 limit = box.zw - 1.;
	return textureLod( ch, ( box.xy + .5 * ( box.zw + clamp( box.zw * uv, -limit, limit ) ) ) / res, 0. );
}

vec4 sm_lookup_uv( sampler2D ch, vec4 box, vec2 uv )
	{ return sm_lookup_centered( ch, box, uv * 2. - 1. ); }

vec4 sm_lookup_rn( SphereMap self, sampler2D ch, vec4 box, vec3 rn )
	{ return sm_lookup_centered( ch, box, sm_uv_centered( self, rn ) ); }

// ****************************************************************************
// AUXILLIARY DATA - recomputed each frame as a function of primary state
// ****************************************************************************

struct GameStateAux
{
	uint switches_last;		// copy of GameState swiches from last frame
	uint stateflags;		// bitfield with additional flags
	uint stateflags_last;	// copy of stateflags from last frame
};

int GAME_STATE_AUX_SIZE = 1;

const uint GSX_SF_RESCHANGE = 1u;
const uint GSX_SF_LOCALLIMIT = 2u;
const uint GSX_SF_LOCALPHYSICS = 4u;
const uint GSX_SF_SHADOWUPDATE = 8u;

GameStateAux gsx_init()
	{ return GameStateAux( 0u, 0u, 0u ); }

GameStateAux gsx_load( sampler2D ch, ivec2 addr )
{
	return GameStateAux(
		uint( memload( ch, addr, 0 ).x ),
		uint( memload( ch, addr, 0 ).y ),
		uint( memload( ch, addr, 0 ).z ) );
}

GameStateAux gsx_load_or_init( sampler2D ch, ivec2 addr, bool init )
	{ if( init ) return gsx_init(); else return gsx_load( ch, addr ); }

void gsx_store( GameStateAux self, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( vec3( float( self.switches_last ), float( self.stateflags ), float( self.stateflags_last ) ), 0., addr, 0, sc, fc );
}

// ----------------------------------------------------------------------------
// SCENE OBJECT
// ----------------------------------------------------------------------------

struct SceneObj
{
	mat3 B;
	vec3 r;
	vec4 tybr;
	vec4 paramsA;
	vec4 paramsB;
};

const int SCENE_OBJECT_SIZE = 6;

ivec2 so_objaddr( int index )
	{ return ADDR_SCENE_OBJECTS + ivec2( index, 0 ); }

ivec2 so_dataaddr( int index )
	{ return ADDR_SCENE_DATA + ivec2( index, 0 ); }

bool in_so_objrange( ivec2 sc )
	{ return in_addr_range( sc, ADDR_SCENE_OBJECTS, SCENE_OBJECT_SIZE, SCN_MAX_PRIMITIVES ); }

bool in_so_datarange( ivec2 sc )
	{ return in_addr_range( sc, ADDR_SCENE_DATA, SCENE_OBJECT_SIZE, SCENE_DATA_COUNT ); }

SceneObj so_load( sampler2D ch, ivec2 addr )
{
	return SceneObj(
		memload_mat3( ch, addr, 0 ),
		memload_www( ch, addr, 0 ),
		memload( ch, addr, 3 ),
		memload( ch, addr, 4 ),
		memload( ch, addr, 5 ) );
}

void so_store( SceneObj self, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( self.B, self.r, addr, 0, sc, fc );
	memstore( self.tybr, addr, 3, sc, fc );
	memstore( self.paramsA, addr, 4, sc, fc );
	memstore( self.paramsB, addr, 5, sc, fc );
}

// ----------------------------------------------------------------------------
// FLUID ENVIRONMENT
// ----------------------------------------------------------------------------

struct FluidEnv
{
	float T, P, rho, a, gamma, mu, lambda;		// same as AtmProfileSample
	float Ma;	 // local Mach number
	float Re;	 // local Reynolds number
	float Kn;	 // local Knudsen number
	float Tt;	 // local stagnation temperature
	float Pt;	 // local stagnation pressure (post shock, if Ma > 1)
};

float atm_temperature_model( float u2, float T, float a, float b )
{
	// modelled for a linear increase of specific heat with temperature
	// cp(T) = a + b T
	return ( sqrt( b * u2 + square( a + b * T ) ) - a ) / b;
}

float atm_pressure_model( float P0, float T1, float T0, float a_over_R, float b_over_R )
{
	// pressure relation to match the above temperature relation
	// dP / P = dT / T * cp(T) / R
	return P0 * exp( a_over_R * log( T1 / T0 ) + b_over_R * ( T1 - T0 ) );
}

vec3 atm_solve_rankine_hugoniot( float T0, float P0, float rho0, float u0, vec3 coeff )
{
	// could be done analytically, would results in a quartic in u
	float umax = u0;
	float umin = 0.;
	vec3 result;
	for( int i = 0; i < 18; ++i )
	{
		result.x = ( umax + umin ) / 2.;
		result.y = atm_temperature_model( 1000. * ( u0 + result.x ) * ( u0 - result.x ), T0, coeff.x, coeff.y );
		result.z = P0 + 10. * rho0 * u0 * ( u0 - result.x );
		if( 100. * result.z * result.x >= rho0 * u0 * coeff.z * result.y )
			umax = result.x;
		else
			umin = result.x;
	}
	return result;
}

FluidEnv fe_init_from_atm( AtmProfileSample aps, float V, float L, vec3 coeff, float Kn_ref )
{
	float Ma = safediv( V, aps.a );
	float Re = safediv( V * L * aps.rho, aps.mu );
	float Kn = safediv( aps.lambda, L );
	float Tt = atm_temperature_model( 1000. * V * V, aps.T, coeff.x, coeff.y );
	float Pt = atm_pressure_model( aps.P, Tt, aps.T, coeff.x / coeff.z, coeff.y / coeff.z );
	if( Ma >= 1. )
	{
		vec3 result = atm_solve_rankine_hugoniot( aps.T, aps.P, aps.rho, V, coeff );
		Pt = atm_pressure_model( result.z, Tt, result.y, coeff.x / coeff.z, coeff.y / coeff.z );
	}
	float t = safediv( Kn_ref, Kn_ref + Kn );
	Tt = mix( aps.T, Tt, t );
	Pt = mix( aps.P, Pt, t );
	return FluidEnv( aps.T, aps.P, aps.rho, aps.a, aps.gamma, aps.mu, aps.lambda, Ma, Re, Kn, Tt, Pt );
}

FluidEnv fe_init_from_ocn( PlanetData pd, float T0, float V, float L, float h )
{
	float z = max( 0., -h ) / ( .05 + max( 0., -h ) );
	float T = mix( T0, pd.ocn.paramsA.x, z );
	float P = pd.ap.ref.y - pd.ocn.paramsA.y * FDM_STD_G * h / 100.;
	return FluidEnv( T, P,
		pd.ocn.paramsA.y,
		pd.ocn.paramsA.w,
		pd.ocn.paramsB.z,
		pd.ocn.paramsB.x,
		pd.ocn.paramsB.y,
		safediv( V, pd.ocn.paramsA.w ),
		safediv( V * L * pd.ocn.paramsA.y, pd.ocn.paramsB.x ),
		safediv( pd.ocn.paramsB.y, L ),
		T + safediv( square( 1000. * V ), 2. * pd.ocn.paramsB.w ),
		P + pd.ocn.paramsA.y * square( 1000. * V ) / 200000. );
}

FluidEnv fe_mix( FluidEnv A, FluidEnv B, float u )
{
	return FluidEnv(
		mix( A.T, B.T, u ), mix( A.P, B.P, u ), mix( A.rho, B.rho, u ), mix( A.a, B.a, u ),
		mix( A.gamma, B.gamma, u ), mix( A.mu, B.mu, u ), mix( A.lambda, B.lambda, u ), mix( A.Ma, B.Ma, u ),
		mix( A.Re, B.Re, u ), mix( A.Kn, B.Kn, u ), mix( A.Tt, B.Tt, u ), mix( A.Pt, B.Pt, u ) );
}

float fe_heating_rate( FluidEnv self, vec2 K, float R, float h_s )
{
	// Sutton-Graves convective heating rate (kW/m^2) in the cold wall limit (h_w = 0)
	// - h_s: stagnation enthalpy h_s (kJ/kg),
	// - K: heat transfer coefficients sqrt(kg)/m
	// - R: nose cone Radius (m)
	float t = sqrt( self.Kn ) / ( 1. + sqrt( self.Kn ) );
	return mix( K.x, K.y, t ) * sqrt( safediv( self.Pt, R ) ) * h_s;
}

float fe_equilibrium_temp( FluidEnv self, float qdot, float e, float r )
{
	// Radiative equilibrium temperature with approx hot wall correction.
	// - qdot: heating rate (kW/m^2)
	// - e: surface emissivity
	// - r: recovery factor
	float Taw2 = sqrt( qdot / ( e * 5.67037442e-11 ) );
	float Tr2 = square( mix( self.T, self.Tt, r ) );
	return sqrt( safediv( Tr2 * Taw2, sqrt( Tr2 * Tr2 + Taw2 * Taw2 ) ) );
}

// ----------------------------------------------------------------------------
// LOCAL ENVIRONMENT
// ----------------------------------------------------------------------------

struct LocalEnv
{
	vec2 phases;		// local seasonal and diurnal phases
	vec3 L;				// local sunlight direction
	float h;			// geopotential altitude
	vec3 sunlight;		// local sunlight flux (F over PI)
	float sundisk;		// sun disk size: sin squared of half opening angle = (r_0/r)^2
	vec3 starlight;		// local starlight flux
	float radius;		// copy of local planet radius, if applicable
	FluidEnv fe;		// local fluid environment
	vec2 nose;			// convective heating rate (x), nose temperature (y)
};

const int LOCAL_ENV_SIZE = 7;

bool in_le_range( ivec2 sc )
	{ return in_addr_range( sc, ADDR_LOCAL_ENV, LOCAL_ENV_SIZE, 1 ); }

LocalEnv le_init()
{
	return LocalEnv( vec2(0), ZERO, 0., ZERO, 0., ZERO, 0., FluidEnv( 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0. ), vec2(0) );
}

LocalEnv le_load( sampler2D ch, ivec2 addr )
{
	return LocalEnv(
		memload( ch, addr, 0 ).xy,
		memload( ch, addr, 1 ).xyz, memload( ch, addr, 1 ).w,
		memload( ch, addr, 2 ).xyz, memload( ch, addr, 2 ).w,
		memload( ch, addr, 3 ).xyz, memload( ch, addr, 3 ).w,
		FluidEnv(
			memload( ch, addr, 4 ).x, memload( ch, addr, 4 ).y, memload( ch, addr, 4 ).z, memload( ch, addr, 4 ).w,
			memload( ch, addr, 5 ).x, memload( ch, addr, 5 ).y, memload( ch, addr, 5 ).z, memload( ch, addr, 5 ).w,
			memload( ch, addr, 6 ).x, memload( ch, addr, 6 ).y, memload( ch, addr, 6 ).z, memload( ch, addr, 6 ).w ),
		memload( ch, addr, 0 ).zw );
}

void le_store( LocalEnv self, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( self.phases, self.nose, addr, 0, sc, fc );
	memstore( self.L, self.h, addr, 1, sc, fc );
	memstore( self.sunlight, self.sundisk, addr, 2, sc, fc );
	memstore( self.starlight, self.radius, addr, 3, sc, fc );
	memstore( vec4( self.fe.T, self.fe.P, self.fe.rho, self.fe.a ), addr, 4, sc, fc );
	memstore( vec4( self.fe.gamma, self.fe.mu, self.fe.lambda, self.fe.Ma ), addr, 5, sc, fc );
	memstore( vec4( self.fe.Re, self.fe.Kn, self.fe.Tt, self.fe.Pt ), addr, 6, sc, fc );
}

LocalEnv le_load_or_init( sampler2D ch, ivec2 addr, bool init )
	{ if( init ) return le_init(); else return le_load( ch, addr ); }

void le_update_phases( inout LocalEnv self, vec2 sphase, vec2 dphase )
	{ self.phases = fract( vec2( atan( -sphase.x, -sphase.y ), atan( -dphase.x, -dphase.y ) ) / TAU ); }

float mu_stretch( float mu, float stretch )
{
	// overstretched version of max( 0., ... ) for lighting cosines
	float x = mu / stretch;
	return x >= 24. ? mu : log2( 1. + exp2(x) ) * stretch;
}

// ----------------------------------------------------------------------------
// ATMOSPHERE UTILS
// ----------------------------------------------------------------------------

float atm_chapman50_h( float X, float h, float coschi )
{
	// Approximation to the Chapman function (airmass integral)
	// cf. Schüler, C. (2012) in GPU Pro 3
	// returns the equivalent of Ch(X+h,coschi) times exp2(-h)

	float x = X + h;
	float c = SQRTPILN2HALF * sqrt(x);
	if( coschi >= 0. )
		return c / ( ( c - 1. ) * coschi + 1. ) * exp2pp( -h );
	else
	{
		float sinchi = sqrt( max( 0., 1. - coschi * coschi ) );
		return c / ( ( c - 1. ) * coschi - 1. ) * exp2pp( -h ) +
			   2. * c * exp2pp( X - x * sinchi ) * sqrt( sinchi );
	}
}

#if WITH_ATM_AMTL_CORRECTION
float atm_airmass_correction( float x, float coschi, float a )
{
	coschi = abs( coschi );
	float c = SQRTPILN2HALF * sqrt(x);
	return a * ( ( c - 1. ) * coschi + a ) / ( ( a * c - 1. ) * coschi + a );
}
#endif

float atm_planet_shadow( float coschi, float cosbeta, float sinalpha )
{
	return clamp( ( coschi + cosbeta ) / sinalpha + .5, 0., 1. );
}

float atm_delta_eddington_Fminus_direct( float g, float tau50, float mu )
{
	// Simplified Eddington downwelling flux component
	// for direct light input at the top interface,
	// assuming conservative scattering (omega0 = 1),
	// and no bottom reflection.
	float f = g * g;
	g = g / ( g + 1. );
	tau50 = ( 1. - f ) * tau50;
	return ( 2. + 3. * mu + ( 2. - 3. * mu ) * exp2pp( -tau50 ) ) / ( 4. + 3. * LN2 * tau50 * mu * ( 1. - g ) );
}

float atm_delta_eddington_Fminus_diffuse( float g, float tau50 )
{
	// Simplified Eddington downwelling flux component
	// for diffuse light input at the top interface,
	// assuming conservative scattering (omega0 = 1),
	// and no bottom reflection.
	float f = g * g;
	g = g / ( g + 1. );
	tau50 = ( 1. - f ) * tau50;
	return 4. / ( 4. + 3. * LN2 * tau50 * ( 1. - g ) );
}

float atm_dulimit( float invtau, float H50, float k50 )
{
	// maximum allowed advance to stay within 1/invtau mean free paths
	// used as step size control
	float s = invtau * k50;
	return
		H50 * s < FRACT_1_1048576 ? -H50 * log2( H50 * s ) :
		H50 * s >= 2048. ? 1. / ( LN2 * s ) :
		H50 * log2( 1. + 1. / ( H50 * s ) );
}

vec4 atm_box_skylight( sampler2D ch )
{
	vec2 res = vec2( textureSize( ch, 0 ) );
	float y = floor( res.y / 2. ); // ceil( res.y / 16. ) * 8.;
	float w = floor( res.y / 2. ); // floor( ( res.y - 2. ) / .8 ) * 8. - y;
	return vec4( 0, y, w, w );
}

vec4 atm_skylight_sample( SphereMap sm, sampler2D ch, vec3 x )
	{ return sm_lookup_rn( sm, ch, atm_box_skylight( ch ), normalize(x) ); }

// ----------------------------------------------------------------------------
// ATMOSPHERE CONTEXT
// ----------------------------------------------------------------------------

struct AtmContext
{
	float r0;
	float g;
	float H;
	float invH50;
	vec3 omega0;
	float X50;
	vec3 mu_stretch;
	float htop;
	vec3 tau50;
	vec3 tau50s;
	vec3 k50;
	vec3 k50_s;
	float k50max;
  #if WITH_ATM_LAYER_G
	vec3 glayer_k50;
	vec3 glayer_k50_s;
	float glayer_scale;
  #endif
  #if WITH_ATM_LAYER_A
	vec3 alayer_k50;
	vec3 alayer_shape;
  #endif
  #if WITH_ATM_LAYER_E
	vec3 elayer_emiss;
	vec3 elayer_shape;
  #endif
  #if WITH_CLOUDS
	vec3 ht0s50;
  #endif
};

const int ATM_CONTEXT_SIZE = 14;

ivec2 ac_addr( int index )
	{ return ADDR_ATM_CONTEXTS + ivec2( index, 0 ); }

bool in_ac_range( ivec2 sc )
	{ return in_addr_range( sc, ADDR_ATM_CONTEXTS, 16, PLANET_DATA_COUNT ); }

AtmContext ac_load( sampler2D ch, ivec2 addr )
{
	return AtmContext(
		memload( ch, addr, 0 ).x,
		memload( ch, addr, 0 ).y,
		memload( ch, addr, 0 ).z,
		memload( ch, addr, 0 ).w,
		memload( ch, addr, 1 ).xyz,
		memload( ch, addr, 1 ).w,
		memload( ch, addr, 2 ).xyz,
		memload( ch, addr, 2 ).w,
		memload( ch, addr, 3 ).xyz,
		memload( ch, addr, 4 ).xyz,
		memload( ch, addr, 5 ).xyz,
		memload( ch, addr, 6 ).xyz,
		memload( ch, addr, 6 ).w
	  #if WITH_ATM_LAYER_G
		,memload( ch, addr, 7 ).xyz
		,memload( ch, addr, 8 ).xyz
		,memload( ch, addr, 8 ).w
	  #endif
	  #if WITH_ATM_LAYER_A
		,memload( ch, addr, 9 ).xyz
		,memload( ch, addr, 10 ).xyz
	  #endif
	  #if WITH_ATM_LAYER_E
		,memload( ch, addr, 11 ).xyz
		,memload( ch, addr, 12 ).xyz
	  #endif
	  #if WITH_CLOUDS
		,memload( ch, addr, 13 ).xyz
	  #endif
	);
}

void ac_store( AtmContext self, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	memstore( vec4( self.r0, self.g, self.H, self.invH50 ), addr, 0, sc, fc );
	memstore( self.omega0, self.X50, addr, 1, sc, fc );
	memstore( self.mu_stretch, self.htop, addr, 2, sc, fc );
	memstore( self.tau50, 0., addr, 3, sc, fc );
	memstore( self.tau50s, 0., addr, 4, sc, fc );
	memstore( self.k50, 0., addr, 5, sc, fc );
	memstore( self.k50_s, self.k50max, addr, 6, sc, fc );
  #if WITH_ATM_LAYER_G
	memstore( self.glayer_k50, 0., addr, 7, sc, fc );
	memstore( self.glayer_k50_s, self.glayer_scale, addr, 8, sc, fc );
  #endif
  #if WITH_ATM_LAYER_A
	memstore( self.alayer_k50, 0., addr, 9, sc, fc );
	memstore( self.alayer_shape, 0., addr, 10, sc, fc );
  #endif
  #if WITH_ATM_LAYER_E
	memstore( self.elayer_emiss, 0., addr, 11, sc, fc );
	memstore( self.elayer_shape, 0., addr, 12, sc, fc );
  #endif
  #if WITH_CLOUDS
	memstore( self.ht0s50, 0., addr, 13, sc, fc );
  #endif
}

vec3 ac_eddington_lambda( vec3 omega0, float g, float k )
{
	// stretch factor to be multiplied with tau, appearing as 'lambda' in many texts
	// related to the backscatter coefficient or average diffusion length
	return sqrt( max( ZERO, 3. * ( 1. - omega0 * k ) * ( 1. - omega0 * g ) ) );
}

vec3 ac_cvt_layer_shape( vec2 shape, float invscale )
{
	vec3 result;
	result.x = shape.x * invscale;
	result.y = safediv( ONEOVERSQRTTWOPI * LOG2E, shape.y * invscale );
	result.z = safediv( .5 * LOG2E, square( shape.y * invscale ) );
	return result;
}

vec3 irselect( vec4 a, bool b )
	{ return b ? a.www : a.xyz; }

AtmContext ac_init( PlanetData data, bool ir )
{
	AtmContext result;
	result.r0 = data.radius;
	result.g = data.am.g;
	result.H = data.am.scale;
	result.invH50 = safediv( LOG2E, data.am.scale );
	result.omega0 = irselect( safediv( data.am.tau_s, data.am.tau ), ir );
	result.X50 = data.radius * result.invH50;
	vec3 stretchhalf = ac_eddington_lambda( result.omega0, result.g, .5 );
	vec3 stretchfull = ac_eddington_lambda( result.omega0, result.g, 1. );
	result.mu_stretch = result.X50 * stretchhalf * pd_overarch( data );
	result.htop = ( hmax( result.tau50 ) + 15. ) * data.am.scale;
	result.tau50 = irselect( data.am.tau, ir ) * LOG2E;
	result.tau50s = result.tau50 * stretchfull;
	result.k50 = irselect( data.am.tau, ir ) * result.invH50;
	result.k50_s = irselect( data.am.tau_s, ir ) * result.invH50;
	result.k50max = hmax( result.k50 );
  #if WITH_ATM_LAYER_G
	result.glayer_k50 = irselect( data.am.glayer_tau, ir ) * result.invH50;
	result.glayer_k50_s = irselect( data.am.glayer_tau_s, ir ) * result.invH50;
	result.glayer_scale = data.am.glayer_scale;
  #endif
  #if WITH_ATM_LAYER_A
	result.alayer_k50 = irselect( data.am.alayer_tau, ir ) * result.invH50;
	result.alayer_shape = ac_cvt_layer_shape( data.am.alayer_shape, result.invH50 );
  #endif
  #if WITH_ATM_LAYER_E
	result.elayer_emiss = irselect( data.am.elayer_emiss, ir );
	result.elayer_shape = ac_cvt_layer_shape( data.am.elayer_shape, result.invH50 );
  #endif
  #if WITH_CLOUDS
	result.ht0s50 = SQRTPILN2HALF * sqrt( result.X50 ) * irselect( data.am.tau, ir );
  #endif
	return result;
}

#if WITH_ATM_LAYER_A
float ac_airmass_layer_a( AtmContext ac, vec3 x, vec3 dir )
{
	float result = 0.;
	float mu = ac.alayer_shape.x + ac.X50;
	float hw = SQRT2LN2 * safediv( ONEOVERSQRTTWOPI * LOG2E, ac.alayer_shape.y ); // "half width half maximum"
	vec2 imp = sphere_impact( x, dir );
	if( imp.x < square( mu + hw ) ) // also catches dir == 0 via imp.x == NaN
	{
		vec2 limits = max( vec2(0), sphere_limits( mu + hw, imp ) );
		result += ( limits.y - limits.x );
		if( imp.x < square( mu - hw ) )
		{
			vec2 limits = max( vec2(0), sphere_limits( mu - hw, imp ) );
			result -= ( limits.y - limits.x );
		}
	}
	return .5 * result / hw;
}
#endif

vec3 ac_tau50_params( AtmContext ac, vec3 x, vec3 dir )
{
	float xsq = dot( x, x );
	float invxr = inversesqrt( xsq );
	float x50 = xsq * invxr;
	float h50 = x50 - ac.X50;
	float coschi = invxr * dot( x, dir );
	return vec3( sqrt( max( 0., 1. - square( ac.X50 / x50 ) ) ), h50, coschi );
}

vec3 ac_tau50( AtmContext ac, vec3 x, vec3 dir, float h50, float coschi )
{
	// Analytical approximation to the optical depth along a path
	// inside an exponentially decreasing, spherically symmetric
	// atmosphere as seen from point x into direction dir
	vec3 result = ZERO;
#if WITH_ATMOSPHERE
	float airmass = atm_chapman50_h( ac.X50, h50, coschi );
	result += ac.tau50 * airmass;
  #if WITH_ATM_LAYER_G
	float airmass_g = atm_chapman50_h( ac.X50 * ac.glayer_scale, h50 * ac.glayer_scale, coschi );
	result += ac.H * ac.glayer_k50 * ( airmass_g - airmass );
  #endif
  #if WITH_ATM_LAYER_A
	float airmass_a = ac_airmass_layer_a( ac, x, dir );
	result += ac.H * ac.alayer_k50 * ( airmass_a - airmass );
  #endif
#endif
	return result;
}

vec3 ac_transmittance( AtmContext ac, vec3 pos, vec3 dir, bool amtl )
{
	vec3 x = pos * ac.invH50;
	vec3 params = ac_tau50_params( ac, x, dir );
	vec3 tau50 = ac_tau50( ac, x, dir, params.y, params.z );
#if WITH_ATM_AMTL_CORRECTION
	if( amtl )
		tau50 *= atm_airmass_correction( ac.X50, params.x + params.z, ATM_AMTL_CORRECTION );
#endif
	return exp2pp( -tau50 );
}

vec3 ac_transmittance_finite( AtmContext ac, vec3 pos0, vec3 pos1 )
{
	vec3 dir = safenormalize( pos1 - pos0 );
	vec3 x0 = pos0 * ac.invH50;
	vec3 x1 = pos1 * ac.invH50;
	vec3 params0 = ac_tau50_params( ac, x0, dir );
	vec3 params1 = ac_tau50_params( ac, x1, dir );
	vec3 tau50 = dot( x0, dir ) < 0. ?
		ac_tau50( ac, x1, -dir, params1.y, -params1.z ) - ac_tau50( ac, x0, -dir, params0.y, -params0.z ) :
		ac_tau50( ac, x0,  dir, params0.y,	params0.z ) - ac_tau50( ac, x1,	 dir, params1.y,  params1.z );
	return exp2( -tau50 );
}

// ----------------------------------------------------------------------------
// TERRAIN GENERATOR
// ----------------------------------------------------------------------------

float trn_rand( ivec3 p )
{
	ivec3 q = sign(p) * abs(p) & 65535;
	int x = ( 3 + 4 * ( q.x + q.y * ( 1 + p.x ) + q.z * ( 1 + p.x + p.y ) ) );
	x = ( ( x  & 262143 ) * 47485 ) & 262143;
	float y = 2. * float(x) / 262144. - 1.;
	return y;
}

vec4 trn_noise_d( vec3 x )
{
	vec3 xf = fract(x);
	vec3 xi = floor(x);
	ivec3 ix = ivec3( xi );
	vec4 p = vec4( trn_rand( ix + ivec3( 0, 0, 0 ) ), trn_rand( ix + ivec3( 1, 0, 0 ) ),
				   trn_rand( ix + ivec3( 0, 1, 0 ) ), trn_rand( ix + ivec3( 1, 1, 0 ) ) );
	vec4 q = vec4( trn_rand( ix + ivec3( 0, 0, 1 ) ), trn_rand( ix + ivec3( 1, 0, 1 ) ),
				   trn_rand( ix + ivec3( 0, 1, 1 ) ), trn_rand( ix + ivec3( 1, 1, 1 ) ) );
	vec3 t = xf - .5;
	vec3 u = .5 - 2. * ( abs(t) * t - t );
	vec3 v = 2. - 4. * abs(t);
	vec4 dpq = q - p;
	vec4 pqz = mix( p, q, u.z );
	return vec4(
		mix( pqz.yz - pqz.xx, pqz.ww - pqz.zy, u.yx ) * v.xy,
		mix( mix( dpq.x, dpq.y, u.x ), mix( dpq.z, dpq.w, u.x ), u.y ) * v.z,
		mix( mix( pqz.x, pqz.y, u.x ), mix( pqz.z, pqz.w, u.x ), u.y ) );
}

struct TrnContext
{
	// accumulation variables
	vec4 h;			// height with partial derivatives
#if WITH_TRN_SURFACE_AA
	vec2 a;			// residual height and slope variance
#endif
	// read only precomputed
	float zl;		// zone level
	float zw;		// zone weight
	float fl;		// flatten multiplier
	float is;		// gaussian multiplier (inv sigma)
	float na;		// noise amplitude
};

TrnContext trn_context_init( const TrnData trn, vec4 zone, vec3 rn )
{
	return TrnContext(
		vec4(0),
	#if WITH_TRN_SURFACE_AA
		vec2(0),
	#endif
		-log2( zone.w ),
		1. - exp2pp( -lensq( zone.xyz - rn ) / ( zone.w * zone.w ) ),
		1. / trn.flatten.y,
		SQRTHALF / trn.noise.z,
		ONEOVERSQRTPI * trn.noise.x * ( SQRTHALF / trn.noise.z )
	);
}

void trn_context_iterate( inout TrnContext ctx, const TrnData trn, vec4 zone, vec3 rn,
						  float N0, float N1 )
{
	int i0 = int( floor( N0 ) );
	int i1 = int( ceil( N1 ) );
	const float S = .05 / EULER;
	for( int i = i0; i < i1; ++i )
	{
		float j = float(i);
		float k = ldexp( 1., i );
		float u = ( j - trn.noise.y ) * ctx.is;
		float v = ctx.na * exp2( - u * u - j );
		float slip = 1. + trn.slope.z * dot( ctx.h.xyz, ctx.h.xyz );
		vec3 x = k * ( rn + trn.seeds );
		vec3 dx = trn.slope.y * ctx.h.xyz;
		vec4 n = trn_noise_d( x + dx ) * vec4( k, k, k, 1 );
		vec4 g = smin1_d( square_d( ( ctx.h - const_d( trn.flatten.x ) ) * ctx.fl ), S );
		vec4 f = mix_d( const_d( 1. - trn.flatten.z ), ONE_D, g );
		vec4 l = max_d( const_d( 0. ), min_d( ctx.h - const_d( trn.levels.x ), const_d( trn.levels.y ) - ctx.h ) );
		vec4 d = mul_d( l, smin1_d( div_d( f * v, l ), S ) ) / slip;
		float w1 = saturate( N1 - j );
		float w2 = saturate( j + 1. - N0 );
		float w3 = mix( 1., ctx.zw, saturate( j - ctx.zl ) );
		ctx.h += min( w1, w2 ) * w3 * mul_d( d, n );
	#if WITH_TRN_SURFACE_AA
		ctx.a += square( min( 1. - w1, w2 ) * w3 * d.w * vec2( 1, k ) );
	#endif
	}
}

void trn_context_iterate_finish( inout TrnContext ctx, const TrnData trn, vec4 zone, vec3 rn,
								 float N1, float NMAX )
{
	int i1 = int( ceil( N1 ) );
	int iend = int( ceil( NMAX ) );
	const float S = .05 / EULER;
#if WITH_TRN_SURFACE_AA
	float invslip = 1. / ( 1. + trn.slope.z * dot( ctx.h.xyz, ctx.h.xyz ) );
	float g = smin1( square( ( ctx.h.w - trn.flatten.x ) * ctx.fl ), S );
	float f = mix( 1. - trn.flatten.z, 1., g );
	float l = min( ctx.h.w - trn.levels.x, trn.levels.y - ctx.h.w );
	for( int i = i1; i < iend; ++i )
	{
		float j = float(i);
		float k = ldexp( 1., i );
		float u = ( j - trn.noise.y ) * ctx.is;
		float v = ctx.na * exp2( - u * u - j );
		float d = min( f * v, l ) * invslip;
		float w3 = mix( 1., ctx.zw, saturate( j - ctx.zl ) );
		ctx.a += square( w3 * d * vec2( 1, k ) );
	}
#endif
}

float trn_elevation( vec3 _r, float detail, PlanetData pd, vec4 zone )
{
	vec3 rn = normalize(_r);
	TrnContext ctx = trn_context_init( pd.trn, zone, rn );
	trn_context_iterate( ctx, pd.trn, zone, rn, 0., detail );
	return pd.radius * pd.trn.slope.x * ( ctx.h.w - pd.trn.levels.z - dot( rn, pd.trn.offcenter ) );
}

vec4 trn_elevation_refine( vec3 rn, float detail, PlanetData data, vec4 zone,
						   float origdetail, vec4 tsmpl, inout vec2 sigmares )
{
	TrnContext ctx = trn_context_init( data.trn, zone, rn );
	ctx.h = vec4( ( rn - tsmpl.xyz / dot( tsmpl.xyz, rn ) ) / data.trn.slope.x,
				  tsmpl.w / ( data.radius * data.trn.slope.x ) + data.trn.levels.z + dot( rn, data.trn.offcenter ) );
	trn_context_iterate( ctx, data.trn, zone, rn, origdetail, detail );
#if WITH_TRN_SURFACE_AA
	trn_context_iterate_finish( ctx, data.trn, zone, rn, detail, TRN_MAX_LEVELS + TRN_MAX_REFINE_LEVELS );
	sigmares = sqrt( ctx.a / 3. ) * data.trn.slope.x;
#endif
	return vec4( normalize( rn - reject( data.trn.slope.x * ctx.h.xyz, rn ) ), tsmpl.w );
}

vec4 trn_box_main( sampler2D ch )
{
	vec2 res = vec2( textureSize( ch, 0 ) );
	float w = floor( res.y / 2. - 2. ) * 2.;
	return vec4( 0, 2, w, w );
}

vec4 trn_box_aux( sampler2D ch, float i )
{
	vec2 res = vec2( textureSize( ch, 0 ) );
	vec4 main = trn_box_main( ch );
	float w = floor( res.y / 4. );
	return vec4( main.z + w * i, res.y - 2. - w, w, w );
}

vec4 trn_box_shadow( sampler2D ch )
{
	vec2 res = vec2( textureSize( ch, 0 ) );
	vec4 aux = trn_box_aux( ch, 0. );
	float x = aux.x;
	float w = min( aux.y, res.x - x );
	return vec4( x, 2, w, w );
}

vec4 trn_sample_n( SphereMap self, sampler2D ch, vec3 rn )
	{ return sm_unpack_normal( self, sm_lookup_rn( self, ch, trn_box_main( ch ), rn ) ); }

vec4 trn_sample_baserel_n( SphereMap self, sampler2D ch, vec3 r_baserel_n )
{
	vec2 uv = sm_uv_centered_baserel( self, r_baserel_n );
	return sm_unpack_normal( self, sm_lookup_centered( ch, trn_box_main( ch ), uv ) );
}

vec4 trn_sample_baserel( SphereMap self, sampler2D ch, vec3 r_base, vec3 r_diff )
{
	vec3 r_baserel = FORCE_EVAL( r_base - self.rn * self.r0 ) + r_diff;
	float h = sumdifflen( self.rn * self.r0, r_baserel );
	return trn_sample_baserel_n( self, ch, r_baserel / ( self.r0 + h ) );
}

vec2 trn_shadow_sample( SphereMap self, sampler2D ch, vec4 rn )
{
#if WITH_TRN_SHADOW
	vec4 lookup = sm_lookup_rn( self, ch, trn_box_shadow( ch ), rn.xyz );
	return vec2( lookup.x != lookup.y ? parabolstep( lookup.x, lookup.y, rn.w ) : 1., lookup.z );
#else
	return vec2(1);
#endif
}

vec4 trn_sample_fine( SphereMap sm, sampler2D ch, vec3 rn,
					  PlanetData data, float Kx, inout vec2 sigmares )
{
#if WITH_TRN_REFINE
	float res = float( textureSize( ch, 0 ).y );
	float lod = sm_lod( sm, rn );
	float detail = min( log2( res * lod ) - TRN_LOD_BIAS, TRN_MAX_LEVELS );
	vec4 lookup = sm_lookup_rn( sm, ch, trn_box_main( ch ), rn );
	int zoneindex = int( lookup.z );
	vec4 tsmpl = sm_unpack_normal( sm, lookup );
	vec4 zone = zd_trn_zone( zd_load( ch, zd_addr_b( zoneindex ) ), data.radius );
	return trn_elevation_refine(
		rn,
		min( detail + TRN_MAX_REFINE_LEVELS, log2( data.radius / Kx ) ),
		data,
		zone,
		detail,
		tsmpl,
		sigmares
		);
#else
	return trn_sample_n( sm, ch, rn );
#endif
}

// ----------------------------------------------------------------------------
// ANISOTROPICALLY ANTIALIASED ANALYTIC PRIMITIVES
// ----------------------------------------------------------------------------

float Linfinity( vec2 a )
	{ return max( abs( a.x ), abs( a.y ) ); }

float aaa_cov( float a )
	{ return saturate( a ); }

float aaa_step( float K, float u )
	{ return aaa_cov( .5 + u / K ); }

vec2 aaa_step2( vec2 K, vec2 u )
	{ return vec2( aaa_step( K.x, u.x ), aaa_step( K.y, u.y ) ); }

float aaa_interval( float K, float u, float size )
	{ return aaa_cov( K < size ? .5 + ( .5 * size - abs(u) ) / K : ( 1. - abs(u) / K ) * size / K ); }

vec2 aaa_interval2( vec2 K, vec2 u, vec2 size )
	{ return vec2( aaa_interval( K.x, u.x, size.x ), aaa_interval( K.y, u.y, size.y ) ); }

float aaa_stipple( float K, float u, float per, float x_duty )
{
	float duty = fract( x_duty );
	float d = min( duty, 1. - duty );
	float s = d * per;
	u = abs( mod( u, per ) - per / 2. );
	return floor( x_duty ) + aaa_cov( K < .5 * per ?
		( duty < .5 ? aaa_interval( K, u, s ) : 1. - aaa_interval( K, per / 2. - u, s ) ) :
		duty - ( u - per / 4. ) * d / K );
}

vec2 aaa_stipple2( vec2 K, vec2 u, vec2 per, vec2 x_duty )
	{ return vec2( aaa_stipple( K.x, u.x, per.x, x_duty.x ), aaa_stipple( K.y, u.y, per.y, x_duty.y ) ); }

float aaa_box( mat2 K, vec2 uv, vec2 size, vec2 edge )
{
	return aaa_interval( max( edge.x, Linfinity( K[0] ) ), uv.x, size.x ) *
		   aaa_interval( max( edge.y, Linfinity( K[1] ) ), uv.y, size.y );
}

float aaa_rect( mat2 K, vec2 uv, vec2 size, vec2 d )
{
	return aaa_box( K, uv, size + d, vec2(0) ) * ( 1. - aaa_box( K, uv, size - d, vec2(0) ) );
}

float aaa_line( mat2 K, vec2 uv, vec2 dx, float width )
{
	vec3 dxn = length_normalize( dx );
	mat2 M = mat2( dxn.xy, perp( dxn.xy ) );
	uv = ( uv - dx / 2. ) * M;
	return aaa_box( K * M, uv, vec2( dxn.z, width ), vec2(0) );
}

float aaa_line( mat2 K, vec2 uv, vec2 x0, vec2 x1, float width )
	{ return aaa_line( K, uv - x0, x1 - x0, width ); }

float aaa_hline( mat2 K, vec2 uv, vec2 x0, float w, float width )
{
	uv = uv - vec2( w / 2., 0 );
	return aaa_box( K, uv - x0, vec2( w, width ), vec2(0) );
}

float aaa_vline( mat2 K, vec2 uv, vec2 x0, float h, float width )
{
	uv = uv - vec2( 0, h / 2. );
	return aaa_box( mat2( perp( K[0] ), perp( K[1] ) ), uv - x0, vec2( width, h ), vec2(0) );
}

float aaa_disk( mat2 K, vec2 uv, float size )
{
	vec3 uvn = length_normalize( uv );
	return aaa_interval( Linfinity( K * uvn.xy ), uvn.z, size );
}

float aaa_ring( mat2 K, vec2 uv, float size, float d )
{
	vec3 uvn = length_normalize( uv );
	return aaa_interval( Linfinity( K * uvn.xy ), abs( uvn.z - size / 2. ), d );
}
