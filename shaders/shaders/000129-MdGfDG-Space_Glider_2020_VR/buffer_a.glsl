// Buffer A (buffer) — Space Glider 2020 VR by scholarius
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
 * Part 2 of 6: Buffer A shader (simulation and update logic)
 * This software comes with no warranty. Use it at your own risk.
 * v 45
 */

GameState GS;
VehicleState VS;
VehicleData VD;
SphereMap SM;
PlanetData PD;
LocalEnv LE;
AchieveDetect AD;
MsgQueue MQ;
vec4 DT;
GameStateAux GSX;

float g_subsample = 1.;
int g_msgindex = 0;
int g_localplanetindex = 1;

// ----------------------------------------------------------------------------
// PLANET DATA
// ----------------------------------------------------------------------------

/*
	wavelength band					615		535		445		1250

	Rayleigh optical depth [1]		0.0572	0.1003	0.1977	0.0034
	Aerosol optical depth [2]		0.0708	0.0822	0.0999	0.0330
	Ozone absorbtion [3]			0.0346	0.0215	0.0019	0.0000029
	Water vapor absorption [4]		0.0160	0.0052	0.00026	0.0372

	[1] Fröhlich & Shaw 1980 (with Young's correction)
	[2] AOD 0.08, centered at 550 nm, with Ångström exponent 1.08 (estimate of global average, super clear sky is AOD 0.02)
	[3] Optical depth of 300 Dobson units ozone (about 0.35 ppm, but yearly average more like 340), from spectral absorbtion of Chappuis bands
	[4] Optical depth of 2.5 cm precipitable water vapor (estimate of global average, mid-latitude over land more like 1.0)
*/

const vec4 ATM_TAU_RAYLEIGH =					vec4( 0.0572, 0.1003, 0.1977, 0.0034 );
const vec4 ATM_TAU_AEROSOL =	  0.08 / 0.08 * vec4( 0.0708, 0.0822, 0.0999, 0.0330 );
const vec4 ATM_TAU_OZONE =		  300. / 300. * vec4( 0.0346, 0.0215, 0.0019, 2.9e-6 );
const vec4 ATM_TAU_VAPOR =		   1.5 /  2.5 *	vec4( 0.0160, 0.0052, 2.6e-4, 0.0372 );
const vec4 ATM_OMEGA_AEROSOL = vec4( .93, .94, .95, .8 );

const float GM_SCALE = SCN_SCALE * SCN_SCALE / INV_G_SCALE;
const float OP_SCALE = sqrt( SCN_SCALE * INV_G_SCALE );
const float RP_SCALE = SECONDS_PER_MINUTE / 10.;

PlanetData g_planet_data( int index )
{
	switch( index )
	{
	// Solna
	default:
	return PlanetData(
		0.,
		SCN_DATA_SUNRADIUS,
		66355148.1 * GM_SCALE,
		0.,
		0.,
		vec2(0),
		KEPLERA( 0., 0., 0., 0., 0. ),
		TrnData( ZERO, ZERO, ZERO, ZERO, ZERO, ZERO ),
		TrnLayer[6](
			TrnLayer( vec4(0), vec4(0), vec4(0), 0., 0., 0. ),
			TrnLayer( vec4(0), vec4(0), vec4(0), 0., 0., 0. ),
			TrnLayer( vec4(0), vec4(0), vec4(0), 0., 0., 0. ),
			TrnLayer( vec4(0), vec4(0), vec4(0), 0., 0., 0. ),
			TrnLayer( vec4(0), vec4(0), vec4(0), 0., 0., 0. ),
			TrnLayer( vec4(0), vec4(0), vec4(0), 0., 0., 0. ) ),
		OcnData( vec4(0), vec4(0), vec4(0), vec4(0) ),
		AtmProfile( vec4(0), ZERO, 0., mat4x2(0), mat4x2(0), ZERO, mat2x3( ZERO, ZERO ), vec2(0), ZERO, ZERO, ZERO, vec2(0) ),
		AtmModel( 0., 0., vec4(0), vec4(0), vec4(0), vec4(0), 0., vec4(0), vec2(0), vec4(0), vec2(0) ),
		CldData( ZERO, ZERO, vec2(0), vec4(0), vec4(0) )
	);

	// Miderra
	case 1:
	return PlanetData(
		0.,													// parent
		954.266445 * SCN_SCALE,								// radius
		9040.92615 * GM_SCALE,								// GM
		245.292732 * OP_SCALE,								// orbital period
		3.93581842 * RP_SCALE,								// rotation period
		vec2( radians( 66.5608 ), radians( 90.0000 ) ),		// north pole
		KEPLERA( SCN_DATA_PLANETDIST, 0.0117938001, 0., radians( 114.2 ), radians( 348.7 ) ),
		TrnData(
			vec3( 0.00, -1.05, -8.05 ),						// seed
			vec3( -0.010, 0.0115, 0.00090 ),				// levels
			vec3( 0.00020, 0.00010, 0.00011 ),				// offcenter
			vec3( 2.40, 8.90, 5.6 ),						// noise
			vec3( 0.00070, 0.0072, 0.96 ),					// flatten
			vec3( TRN_SCALE / SCN_SCALE, -1.25, 2.50 ) ),	// slope effects
		TrnLayer[6](
			TrnLayer( vec4( .055, .060, .030, .45 ), vec4( 0, 0.7, 1.03, 1.09 ), vec4(0), 0., 0., 0. ),											// trees
			TrnLayer( vec4( .155, .160, .055, .55 ), vec4( 5, 1.0, 0.95, 0.90 ), vec4( -0.50, -1.00,	1.00, -25.00 ),	 1.50, 0.05, 0.95 ),	// gras
			TrnLayer( vec4( .155, .125, .080, .25 ), vec4( 2, 0.8, 0.95, 0.90 ), vec4(	0.00,  0.00, -500.00,	0.00 ),	 0.00, 0.00, 1.00 ),	// tide
			TrnLayer( vec4( .405, .275, .150, .40 ), vec4( 1, 1.0, 0.92, 0.88 ), vec4(	0.25, -2.00,   -1.00,  -5.00 ),	 0.55, 0.05, 0.85 ),	// sand
			TrnLayer( vec4( .815, .800, .785, .15 ), vec4( 5, 1.0, 1.10, 1.15 ), vec4( -3.30,  0.00,	1.30,  -1.00 ),	 0.80, 0.00, 1.00 ),	// snow
			TrnLayer( vec4( .200, .190, .180, .35 ), vec4( 5, 1.5, 1.02, 1.06 ), vec4( -0.25, -0.50,	0.25,	1.00 ), -0.35, 0.00, 1.00 )		// rock
			),
		OcnData(
			vec4( .1760, .0567, .0355, 25 ),
			vec4( .0050, .0188, .0441, 0 ),					// color for about 0.5 mg/m³ chlorophyll concentration
			// vec4( .0020, .0105, .0295, 0 ),				// color for about 0.1 mg/m³ chlorophyll concentration
			vec4( 277.16, 1028, 0.1628, 1.4654 ),			// temp / dens / surfance roughness (for avg wind speed of 7.5 m/s) / speed of sound @ temp
			vec4( .00167, .000000000145, 1.011, 4001. )		// dyn viscosity / avg molecular size (1.45 Å), ratio of specific heats, cp
		),
		AtmProfile(
			vec4( 288.15, 1.01325, 1.225, 8.4106 * ATM_SCALE ),
			vec3( 102.9309 * ATM_SCALE, 1000., 41.6533 * ATM_SCALE ),
			.340293991,
			mat2( ATM_SCALE, 0, 0, 1 ) * mat4x2( vec2( 10.9651, 216.65 ), vec2( 14.4541, 206.58 ), vec2( 19.9366, 216.65 ), vec2( 31.8986, 228.65 ) ),
			mat2( ATM_SCALE, 0, 0, 1 ) * mat4x2( vec2( 46.8511, 270.65 ), vec2( 50.8384, 270.65 ), vec2( 70.7750, 214.65 ), vec2( 84.5831, 186.87 ) ),
			vec3( 43.118, 0.0761, -32.6285 ),
			mat2x3( vec3( 3.8533, -4.7020, -3.9716 ), vec3( -4.9857, 4.9801, 5.1333 ) ),
			vec2( 6, 12 ),
			vec3( .00001812, 114, 2.005 ),
			vec3( .9593, .0001553, .2871 ),
			vec3( -.001683, .0000105, 0. ),
			vec2( .112, .112 )
		),
		AtmModel(
			7.5528 * ATM_SCALE,
			0.5,
			ATM_TAU_RAYLEIGH + ATM_TAU_AEROSOL + ATM_TAU_OZONE + ATM_TAU_VAPOR,		// total optical depth
			ATM_TAU_RAYLEIGH + ATM_TAU_AEROSOL * ATM_OMEGA_AEROSOL,					// total scattering optical depth
			ATM_TAU_AEROSOL + ATM_TAU_VAPOR,										// ground layer optical depth
			ATM_TAU_AEROSOL * ATM_OMEGA_AEROSOL,									// ground layer scattering optical depth
			4.,																		// ground layer scale height multiplier
			ATM_TAU_OZONE * 0.95,													// ozone layer optical depth
			vec2( 24.3029, 7.0041 ) * ATM_SCALE,									// ozone layer altitude profile
			COL_AIRGLOW,															// emission layer emittance
			vec2( 84.7307, 4.4857 ) * ATM_SCALE										// emission layer altitude profile
		),
		CldData(
			vec3( 2.2 * ATM_SCALE, 65. / ATM_SCALE, 0.85 ),							// akg
			vec3( 3, 9, 1. * ATM_SCALE ),											// fluff
			vec2( 32, 1.5 ) * SCN_SCALE,											// size
			vec4( 19.55, -8, -30, 8. / ATM_SCALE ),									// noise
			vec4( .42, .000045, .000015 / SCN_SCALE, .00002 )						// move
		)
	);

	// Muni
	case 2:
	return PlanetData(
		1.,
		384.241471 * SCN_SCALE,
		416.174722 * GM_SCALE,
		40.0059349 * OP_SCALE,
		40.0059349 * OP_SCALE,
		vec2( radians( -95.3701 ), radians( 89.9783 ) ),
		KEPLERA( 16810.0502 * SCN_SCALE, 0.039031473, radians( 5.1 ), radians( 125.1 ), radians( 318.2 ) ),
		TrnData(
			vec3( -0.00, -1.05, -8.05 ),		// seed
			vec3( -0.023, 0.020, 0.0006 ),		// levels
			ZERO,
			vec3( 1.70, 6, 4.5 ),				// noise
			vec3( 0.0003, 0.010, 0.95 ),		// flatten
			vec3( 1.0, -1.0, 2.0 ) ),			// slope
		TrnLayer[6](
			TrnLayer( vec4(0), vec4(0), vec4(0), 0., 0., 0. ),
			TrnLayer( vec4(0), vec4(0), vec4(0), 0., 0., 0. ),
			TrnLayer( vec4(0), vec4(0), vec4(0), 0., 0., 0. ),
			TrnLayer( vec4(0), vec4(0), vec4(0), 0., 0., 0. ),
			TrnLayer( vec4(0), vec4(0), vec4(0), 0., 0., 0. ),
			TrnLayer( vec4(0), vec4(0), vec4(0), 0., 0., 0. ) ),
		OcnData( vec4(0), vec4(0), vec4(0), vec4(0) ),
		AtmProfile( vec4(0), ZERO, 0., mat4x2(0), mat4x2(0), ZERO, mat2x3( ZERO, ZERO ), vec2(0), ZERO, ZERO, ZERO, vec2(0) ),
		AtmModel( 0., 0., vec4(0), vec4(0), vec4(0), vec4(0), 0., vec4(0), vec2(0), vec4(0), vec2(0) ),
		CldData( ZERO, ZERO, vec2(0), vec4(0), vec4(0) )
	);
	}
}

// ----------------------------------------------------------------------------
// START DATA
// ----------------------------------------------------------------------------

StartData g_start_data( int index )
{
	switch( index )
	{
	// Init
	default:
	return StartData( uvec4(0), ivec4( 1, 1, 1, 0 ), vec4( 30, 120, 1000, 120 ) );

	case 1:
#if SCALING_PRESET == 6
	// STS-1 Orbit on 1:1 scale
	return StartData( uvec4( 0x5354532d, 0x31209000, 0, 75 ), ivec4( 1, 0, 0, 7 ), vec4( -17.1351, 0, 268.54, 64.9924 ) );
#else
	// Low orbit
	return StartData( uvec4( 0x4c6f7720, 0x90000000, 0, 5 ), ivec4( 1, 0, 0, 7 ), vec4( 0, 30, 150, 60 ) );
#endif

	// Space center west
	case 2:
	return StartData( uvec4( 0x94959700, 0, 0, 3 ), ivec4( 3, 0, 0, 7 ), vec4( 1, ZERO ) );

	// Space center east
	case 3:
	return StartData( uvec4( 0x94959600, 0, 0, 3 ), ivec4( 3, 7, 0, 25 ), vec4( 1, ZERO ) );

	// Lucerne
	case 4:
	return StartData( uvec4( 0x4c756365, 0x726e6500, 0, 7 ), ivec4( 3, 15, 0, 19 ), vec4( 1, ZERO ) );

	// Bensersiel
	case 5:
	return StartData( uvec4( 0x42656e73, 0x65727369, 0x656c0000, 10 ), ivec4( 2, 0, 0, 19 ), vec4( 62.47, 152.0782, .0008, 250. ) );

	// North point (Kaffeklubben island)
	case 6:
	return StartData( uvec4( 0x4b616666, 0x656b6c75, 0x6262656e, 0x20a8000e ), ivec4( 2, 0, 0, 19 ), vec4( 87.3323, 157.6711, -.0003, 180 ) );

	// Spitsbergen
	case 7:
	return StartData( uvec4( 0x53706974, 0x73626572, 0x67656e00, 11 ), ivec4( 2, 0, 0, 73 ), vec4( 72.4248, 79.5030, 6.0972, 270 ) );

	// Cancún
	case 8:
	return StartData( uvec4( 0xa1202020, 0, 0, 4 ), ivec4( 3, 25, 0, 37 ), vec4( 1, ZERO ) );

	// Underwater primitive exhibition
	case 9:
	return StartData( uvec4( 0xa2a36578, 0x68696269, 0x74696f6e, 12 ), ivec4( 2, 0, 0, 25 ), vec4( 28.9906, 156.4883, -.0143, 350 ) );

	// Rocky Springs
	case 10:
	return StartData( uvec4( 0x526f636b, 0x79205370, 0x72696e67, 0x7300000d ), ivec4( 3, 45, 0, 51 ), vec4( -1, ZERO ) );

	// Lake Victoria
	case 11:
	return StartData( uvec4( 0x4c616b65, 0x20566963, 0x746f7269, 0x6100000d ), ivec4( 3, 51, 0, 45 ), vec4( 1, ZERO ) );

	// Kilimandjaro
	case 12:
	return StartData( uvec4( 0x4b696c69, 0x6d616e64, 0x6a61726f, 0x0000000c ), ivec4( 2, 0, 0, 51 ), vec4( -2.4973, 98.8717, 9.3104, 105 ) );

	// Hang gliding challenge
	case 13:
	return StartData( uvec4( 0x48616e67, 0x20676c69, 0x64696e67, 0x20a4000e ), ivec4( 2, 0, 0, 58 ), vec4( -51.5485, -124.1851, 7.3009, 70 ) );

	// Hang gliding destination
	case 14:
	return StartData( uvec4( 0x48616e67, 0x20676c69, 0x64696e67, 0x20ad000e ), ivec4( 3, 58, 0, 55 ), vec4( -1, ZERO ) );

	// South pole station
	case 15:
	return StartData( uvec4( 0x99706f6c, 0x65209b00, 0, 7 ), ivec4( 2, 0, 0, 69 ), vec4( -89.9883, 31.6990, .0123, 150. ) );

	// Gonder (Ethiopian highlands)
	case 16:
	return StartData( uvec4( 0x476f6e64, 0x65720000, 0, 6 ), ivec4( 3, 70, 0, 0 ), vec4( -1, ZERO ) );

	// Dakhla oasis
	case 17:
	return StartData( uvec4( 0x44616b68, 0x6c61206f, 0x61736973, 12 ), ivec4( 2, 0, 0, 70 ), vec4( 25.8881, -149.4194, .0045, 150 ) );

	// Ash island
	case 18:
	return StartData( uvec4( 0x41736820, 0x69736c61, 0x6e640000, 10 ), ivec4( 3, 72, 0, 0 ), vec4( 1, ZERO ) );

	// Edge of the trench
	case 19:
	return StartData( uvec4( 0x45646765, 0x206f6620, 0x74686520, 0xa600000d ), ivec4( 2, 0, 0, 0 ), vec4( 3.0093, 22.9312, -7.5635, 35 ) );

	// Towards sunrise
	case 20:
	return StartData( uvec4( 0x546f7761, 0x72647320, 0x73756e72, 0x6973650f ), ivec4( 3, 73, 0, 0 ), vec4( 1, ZERO ) );

	// Hand gliding challenge 2
	case 21:
	return StartData( uvec4( 0x48616e67, 0x20676c69, 0x64696e67, 0x20a4320f ), ivec4( 2, 0, 0, 74 ), vec4( 58.6771, 125.2693, 8.5352, 100 ) );

	// Hand gliding destination 2
	case 22:
	return StartData( uvec4( 0x48616e67, 0x20676c69, 0x64696e67, 0x20ad320f ), ivec4( 3, 74, 0, 0 ), vec4( 1, ZERO ) );

	// The north face
	case 23:
	return StartData( uvec4( 0x54686520, 0x98666163, 0x65000000, 9 ), ivec4( 2, 0, 0, 0 ), vec4( 60.2080, 120.2213, 6.6135, 205 ) );

	// Continue high orbit
	case 24:
	return StartData( uvec4( 0x436f6e74, 0x696e7565, 0x20686967, 0x6820900f ), ivec4(0), vec4(0) );
	}
}

// ----------------------------------------------------------------------------
// VEHICLE DATA
// ----------------------------------------------------------------------------

VehicleData g_vehicle_data( int index )
{
	switch( index )
	{
	// "Super XR 7000"
	// blend of 3 parts F-16 and 1 part Shuttle orbiter ...
	default:
	return VehicleData(
		vec4( 48.27, 11.62, 5.31, 10630. ),					// Sbcm
		vec4( 23700, 147800, 163000, 1100 ),				// I
		vec2( 29000, 0.2 ),                                 // Re, kD
		vec4(  0.0365,	1.8875,	 1.0488,  0.0750 ),			// CD
		vec4(  0.1850,	3.8547, 23.0975,  0.4925 ),			// CL
		vec4( -0.0028, -0.1481, -5.2071, -0.4816 ),			// Cm
		vec4( -1.0047, -0.1717,	 1.0391,  0.1715 ),			// CY
		vec4(  0.1906,	0.0597, -0.4233, -0.0826 ),			// Cn
		vec4( -0.0642, -0.3149,	 0.0951,  0.1378 ),			// Cl
		vec4( -0.5938, -3.0300, -0.3085, -0.0947 ),			// C90
		vec2(  0.2500, -0.0250 ),							// Cadot
		vec2(  0.1786, -0.4419 ),							// Cnside
		vec2( -0.3082,	0.0844 ),	         				// Cmisc
		vec4(  0.8700,	0.0159,	 0.0106,  3.5000 ),			// mach
		vec2(  0.0300,	0.2097 ),							// rare
		vec4( .45, -.25, .2, .5 ),							// ground
		mat3(  0.0350,  0.1805,  0.0000,                    // config
			   0.0300, -0.0500,  0.0000,
			   0.0204,  0.0075,  0.0000 ),
			   0.0736,										// gearClb
		vec4(  0.4500,  0.9800,  1.0000,  0.5500 ),			// etaCL
		vec3(  0.4663,  0.3640,  0.5220 ),					// dx_max
			  136000.,     									// T_max
	#if SCALING_PRESET == 6
		vec4(  0.9500,  1.7000,  1.3800,  5.3500 )			// Rn
	#else
		vec4(  0.2100,  0.3800,  0.2800,  5.3500 )			// Rn
	#endif
	);

	// B747
	case 1:
	return VehicleData(
		vec4( 511.38, 59.67, 8.32, 162500. ),
		vec4( 14415000, 25253000, 37922000, 0 ),
		vec2( 80000, 0.2 ),
		vec4(  0.0149,	0.8377,	 0.3350,  0.0690 ),
		vec4(  0.2195,	4.9966,	 7.2544,  0.3253 ),
		vec4(  0.0700, -1.1460,-22.5088, -1.2960 ),
		vec4( -0.9553,	0.0000,	 0.3000,  0.1477 ),
		vec4(  0.1847, -0.1181, -0.3219, -0.1077 ),
		vec4( -0.1433, -0.3828,	 0.1742,  0.0318 ),
		vec4( -1.5000, -3.7737, -0.3189, -0.2474 ),
		vec2(  6.7242, -3.6500 ),
		vec2(  0.5267, -0.1129 ),
		vec2( -0.4104,  0.0000 ),
		vec4(  0.7200,	0.0431,	 0.0102,  9.9999 ),
		vec2(  0.0300,  0.0931 ),
		vec4(0),
		mat3(  0.0980,  0.9750, -0.1700,
			   0.0240, -0.0800, -0.0100,
			   0.0270,  0.0000, -0.0100 ),
			  -0.1719,
		vec4( 0.15, 0.35, 1.00, 0.55 ),
		vec3( 0.3640, 0.3640, 0.4663 ),
			 830000.,
		vec4( .55, .55, .55, 8. )
	);
	}
}

const int USE_VEHICLE_INDEX = 0;

// ----------------------------------------------------------------------------
// MENU DATA
// ----------------------------------------------------------------------------

uvec4 g_menu_data( int index )
{
	switch( index )
	{
	default: return uvec4(0);

	// 01 global entry points
	case  1: return uvec4( 0x82810000, 0, 0, 0x00060602 );					// 'Command ...' -> 06
	case  2: return uvec4( 0x4d617020, 0x81000000, 0, 0x00300605 );			// 'Map ...' -> 30
	case  3: return uvec4( 0x44656275, 0x67208100, 0, 0x00380407 );			// 'Debug ...' -> 38,
	case  5: return uvec4( 0x53757265, 0x3f000000, 0, 5 );					// 'Sure?'

	// 06 Command ...
	case  6: return uvec4( 0x86888100, 0, 0, 0x000e0a03 );					// 'Info page ...' -> 0e
	case  7: return uvec4( 0x484d4420, 0x87810000, 0, 0x00180306 );			// 'HMD mode ...' -> 18
	case  8: return uvec4( 0x8d878100, 0, 0, 0x001e0303 );					// 'Aero mode ...' -> 1e
	case  9: return uvec4( 0x52435320, 0x87810000, 0, 0x00240406 );			// 'RCS mode ...' -> 24
	case 10: return uvec4( 0x83878100, 0, 0, 0x002a0403 );					// 'Engine mode ...' -> 2a
	case 11: return uvec4( 0x51756974, 0, 0, 0x00050104 );					// 'Quit' -> 05
	case 12: return uvec4(0);
	case 13: return uvec4(0);

	// 0e Info page ...
	case 14: return uvec4( 0x866f6666, 0, 0, 4 );							// 'Info off'
	case 15: return uvec4( 0x91860000, 0, 0, 2 );							// 'Location info'
	case 16: return uvec4( 0xa7860000, 0, 0, 2 );							// 'Waypoint info'
	case 17: return uvec4( 0x90860000, 0, 0, 2 );							// 'Orbit info'
	case 18: return uvec4( 0x476c6964, 0x65208600, 0, 7 );					// 'Glide info'
	case 19: return uvec4( 0x84860000, 0, 0, 2 );							// 'Control info'
	case 20: return uvec4( 0x53746174, 0x696320b8, 0x86000000, 9 );			// 'Static air info'
	case 21: return uvec4( 0x44796e61, 0x6d696320, 0xb8860000, 10 );		// 'Dynamic air info'
	case 22: return uvec4( 0x54656d70, 0x65726174, 0x75726520, 0x8600000d );// 'Temperature info'
	case 23: return uvec4( 0x54696d65, 0x20860000, 0, 6 );					// 'Time info'

	// 18 HMD mode ...
	case 24: return uvec4( 0x484d4420, 0x6f666600, 0, 7 );					// 'HMD off'
	case 25: return uvec4( 0x8fa50000, 0, 0, 2 );							// 'Surface overlay'
	case 26: return uvec4( 0x90a50000, 0, 0, 2 );							// 'Orbit overlay'

	// 1e Aero mode ...
	case 30: return uvec4( 0x8d6f6666, 0, 0, 4 );							// 'Aero off'
	case 31: return uvec4( 0x64697265, 0x6374208e, 0x84000000, 9 );			// 'Direct manual control'
	case 32: return uvec4( 0x466c7920, 0x627920af, 0x84000000, 9 );			// 'Fly by wire control'

	// 24 RCS mode ...
	case 36: return uvec4( 0x52435320, 0x6f666600, 0, 7 );					// 'RCS off'
	case 37: return uvec4( 0x64697265, 0x6374208e, 0x84000000, 9 );			// 'Direct manual control'
	case 38: return uvec4( 0xae898400, 0, 0, 3 );							// 'Rotation rate control'
	case 39: return uvec4( 0xae89842b, 0x204c564c, 0x48000000, 9 );			// 'Rotation rate control + LVLH'

	// 2a Engine mode ...
	case 42: return uvec4( 0x836f6666, 0, 0, 4 );							// 'Engine off'
	case 43: return uvec4( 0x8a830000, 0, 0, 2 );							// 'Drive engine'
	case 44: return uvec4( 0x8b830000, 0, 0, 2 );							// 'Impulse engine'
	case 45: return uvec4( 0x4e6f7661, 0x20830000, 0, 6 );					// 'Nova engine'

	// 30 Map ...
	case 48: return uvec4( 0x50687973, 0x6963616c, 0, 8 );					// 'Physical'
	case 49: return uvec4( 0x456c6576, 0x6174696f, 0x6e000000, 9 ); 		// 'Elevation'
	case 50: return uvec4( 0x536c6f70, 0x65000000, 0, 5 );					// 'Slope'
	case 51: return uvec4( 0x45717561, 0x6c206172, 0x65610000, 10 );		// 'Equal area'
	case 52: return uvec4( 0x45717561, 0x6c20616e, 0x676c6500, 11 );		// 'Equal angle'
	case 53: return uvec4( 0x53657420, 0xa7000000, 0, 5 );					// 'Set waypoint'

	// 38 Debug ...
	case 56: return uvec4( 0x92888100, 0, 0, 0x003e0108 );					// 'Debug page ...' -> 3e,
	case 57: return uvec4( 0x92677261, 0x70682081, 0, 0x00440308 );			// 'Debug graph ...' -> 44,
	case 58: return uvec4( 0x8c9a8100, 0, 0, 0x004a0403 );					// 'Buffer display ...' -> 4a,
	case 59: return uvec4( 0x8c878100, 0, 0, 0x00500603 );					// 'Buffer mode ...' -> 50,

	// 3e Debug info ...
	case 62: return uvec4( 0x92886f66, 0x66000000, 0, 5 );					// 'Debug page off'

	// 44 Debug graph ...
	case 68: return uvec4( 0x92677261, 0x7068206f, 0x66660000, 10 );		// 'Debug graph off'
	case 69: return uvec4( 0x434c2c43, 0x442c436d, 0x00000000,	8 );		// 'CL,CD,Cm
	case 70: return uvec4( 0x4351622c, 0x436c622c, 0x436e6200, 11 );		// 'CQb,Clb,Cnb

	// 4a Buffer display ...
	case 74: return uvec4( 0x8c9a6f66, 0x66000000, 0, 5 );					// 'Buffer display off',
	case 75: return uvec4( 0x9a8c4100, 0, 0, 3 );							// 'Display buffer A',
	case 76: return uvec4( 0x9a8c4200, 0, 0, 3 );							// 'Display buffer B',
	case 77: return uvec4( 0x9a8c4300, 0, 0, 3 );							// 'Display buffer C',

	// 50 Buffer mode ...
	case 80: return uvec4( 0x8c873100, 0, 0, 3 );							// 'Buffer mode 1',
	case 81: return uvec4( 0x8c873200, 0, 0, 3 );							// 'Buffer mode 2',
	case 82: return uvec4( 0x8c873300, 0, 0, 3 );							// 'Buffer mode 3',
	case 83: return uvec4( 0x8c873400, 0, 0, 3 );							// 'Buffer mode 4',
	case 84: return uvec4( 0x8c873500, 0, 0, 3 );							// 'Buffer mode 5',
	case 85: return uvec4( 0x8c873600, 0, 0, 3 );							// 'Buffer mode 6',
	}
}

const int MENU_COMMAND = 1;
const int MENU_MAP = 2;
const int MENU_DEBUG = 3;
const int MENU_QUIT = 5;
// const int MENU_IPAGE_BEGIN --> common
// const int MENU_IPAGE_SIZE --> common
const int MENU_HMD_BEGIN = 0x18;
const int MENU_HMD_SIZE = 3;
const int MENU_AERO_BEGIN = 0x1e;
const int MENU_AERO_SIZE = 3;
const int MENU_RCS_BEGIN = 0x24;
const int MENU_RCS_SIZE = 4;
const int MENU_ENG_BEGIN = 0x2a;
const int MENU_ENG_SIZE = 4;
const int MENU_MMODE_BEGIN = 0x30;
const int MENU_MMODE_SIZE = 3;
const int MENU_MPROJ_BEGIN = 0x33;
const int MENU_MPROJ_SIZE = 2;
const int MENU_SET_WAYPOINT = 0x35;
// const int MENU_DPAGE_BEGIN --> common
// const int MENU_DPAGE_SIZE --> common
// const int MENU_BDISP_BEGIN --> common
// const int MENU_BDISP_SIZE --> common
// const int MENU_BMODE_BEGIN --> common
// const int MENU_BMODE_SIZE --> common

// ----------------------------------------------------------------------------
// VEHICLE INPUTS
// ----------------------------------------------------------------------------

const int KEY_BACK = 8;
const int KEY_TAB = 9;
const int KEY_SHIFT = 16;
const int KEY_CTRL = 17;
const int KEY_ALT = 18;
const int KEY_ESC = 27;
const int KEY_SPACE = 32;
const int KEY_LEFT = 37;
const int KEY_UP = 38;
const int KEY_RIGHT = 39;
const int KEY_DOWN = 40;
const int KEY_0 = 48;
const int KEY_1 = 49;
const int KEY_2 = 50;
const int KEY_3 = 51;
const int KEY_4 = 52;
const int KEY_LESS = 60;
const int KEY_A = 65;
const int KEY_B = 66;
const int KEY_C = 67;
const int KEY_D = 68;
const int KEY_F = 70;
const int KEY_G = 71;
const int KEY_H = 72;
const int KEY_I = 73;
const int KEY_J = 74;
const int KEY_K = 75;
const int KEY_L = 76;
const int KEY_M = 77;
const int KEY_N = 78;
const int KEY_P = 80;
const int KEY_Q = 81;
const int KEY_R = 82;
const int KEY_S = 83;
const int KEY_T = 84;
const int KEY_V = 86;
const int KEY_W = 87;
const int KEY_Z = 90;
const int KEY_NUM2 = 98;
const int KEY_NUM4 = 100;
const int KEY_NUM6 = 102;
const int KEY_NUM8 = 104;
const int KEY_F1 = 112;
const int KEY_F2 = 113;
const int KEY_F3 = 114;
const int KEY_F4 = 115;
const int KEY_F5 = 116;
const int KEY_F7 = 118;
const int KEY_F8 = 119;
const int KEY_F10 = 121;
const int KEY_F12 = 123;
const int KEY_ACCENT_FIREFOX = 192;
const int KEY_ACCENT_CHROME = 226;
const int KEY_META_FIREFOX = 224;
const int KEY_META_CHROME = 91;

float keystate( int key )
	{ return texelFetch( iChannel3, ivec2( key, 0 ), 0 ).x; }

float keypress( int key )
	{ return texelFetch( iChannel3, ivec2( key, 1 ), 0 ).x; }

float keystatepress( int key )
	{ return max( keystate( key ), keypress( key ) ); }

struct VehicleInputs
{
	float flapsswitch;
	float spoiltoggle;
	float gearstoggle;
	float gearbrake;
	float lightstoggle;
	float throttlecommand;
	vec3 joycommand;
	float trimcommand;
	bool trimdisplay;
	// vec3 rcscommand;
	float tvecswitch;
	float canopytoggle;

	// read only
	vec3 vjoy_copy;
};

VehicleInputs vi_read_inputs( VehicleState vs )
{
	VehicleInputs result;

	float shift = keystate( KEY_SHIFT );
	float meta = max( keystate( KEY_CTRL ), max( keystate( KEY_META_FIREFOX ), keystate( KEY_META_CHROME ) ) );
	vec2 arrows = vec2( keystatepress( KEY_RIGHT ) - keystatepress( KEY_LEFT ), keystatepress( KEY_UP ) - keystatepress( KEY_DOWN ) );
	vec2 WASD = vec2( max( keystatepress( KEY_A ), keystatepress( KEY_Q ) ) - keystatepress( KEY_D ), max( keystatepress( KEY_W ), keystatepress( KEY_Z ) ) - keystatepress( KEY_S ) );
	float shiftmod = mix( 1., .25, shift );

	result.flapsswitch = keypress( KEY_F ) * ( 1. - 2. * shift );
	result.spoiltoggle = keypress( KEY_V );
	result.gearstoggle = keypress( KEY_G );
	result.gearbrake = shiftmod * max( keystate( KEY_B ), keystate( KEY_SPACE ) );
	result.lightstoggle = keypress( KEY_L );
	result.throttlecommand = keystate( KEY_SPACE ) > 0. ? -9999. : vs.modes.z == VS_ENG_OFF ? 0. : mix( 1., abs( vs.throttle ) < 0.1 ? .0625 : .25, shift ) * WASD.y;

	result.joycommand = ZERO;
	result.trimcommand = 0.;
	result.trimdisplay = false;

	if( vs.modes2.x != VS_AERO_OFF && meta > 0. )
	{
		result.trimdisplay = true;
		result.trimcommand = mix( 1., .25, shift ) * -arrows.y;
		arrows.y = 0.;
	}

	result.joycommand = shiftmod * vec3( -arrows.y, arrows.x, WASD.x );
	result.tvecswitch = max( keypress( KEY_LESS ), max( keypress( KEY_ACCENT_FIREFOX ), keypress( KEY_ACCENT_CHROME ) ) ) * ( 2. * shift - 1. );
	result.canopytoggle = keypress( KEY_C );

	result.vjoy_copy = ZERO;
	return result;
}

// ----------------------------------------------------------------------------
// FRAME CONTEXT
// ----------------------------------------------------------------------------

struct FrameContext
{
	float dt_filter;
	float dt_frame;
	float timeaccel;
	int subframe_count;
	float subframe_dt;
	float dt;
};

FrameContext fr_init( vec4 dtime, bool local )
{
	FrameContext result;
	result.dt_filter = dot( dtime, vec4( 1, 2, 2, 1 ) / 6. );
	result.dt_frame = safediv( 1., uintBitsToFloat( floatBitsToUint( safediv( 1., result.dt_filter ) ) + 0x00080000u & 0x7ff00000u ) );
	result.timeaccel =
		keystate( KEY_F4 ) > 0. && !local ? 10000. :
		keystate( KEY_F3 ) > 0. ? 1000. :
		keystate( KEY_F2 ) > 0. ? 100. :
		keystate( KEY_F1 ) > 0. ? 10. :
		1.;
	result.subframe_count = min( VS_MAX_ITER, int( ceil( sqrt( result.timeaccel ) ) ) );
	result.subframe_dt = min( local ? VS_MAX_PACE_LOCAL : VS_MAX_PACE, result.dt_frame * result.timeaccel / float( result.subframe_count ) );
	result.timeaccel = result.timeaccel == 1. ? 1. : float( result.subframe_count ) * safediv( result.subframe_dt, result.dt_frame );
	result.dt = result.subframe_dt * float( result.subframe_count );
	return result;
}

// ----------------------------------------------------------------------------
// SCENE OBJECT
// ----------------------------------------------------------------------------

SceneObj so_init( vec4 navb, vec4 tybr )
{
	SceneObj result;
	result.r = nav2r( vec3( navb.xy, PD.radius + navb.z ) );
	result.B = bearing2B( result.r, navb.w );
	result.tybr = tybr;
	return result;
}

SceneObj so_init( const SceneData data )
{
	SceneObj result = so_init( data.navb, data.tybr );
	result.paramsA = data.paramsA;
	result.paramsB = data.paramsB;
	return result;
}

SceneObj so_end()
{
	SceneObj result = so_init( vec4(0), vec4( SCNOBJ_TYPE_INVALID, ZERO ) );
	result.paramsA = result.paramsB = vec4(0);
	return result;
}

int so_expand_to_primitives( SceneObj obj, int k, float timer, ivec2 addr, ivec2 sc, inout vec4 fc )
{
	int type = int( obj.tybr.x );
	if( type == SCNOBJ_TYPE_TOWER )
	{
		obj.r -= obj.B[2] * obj.paramsB.z;
		so_store( SceneObj( obj.B, obj.r, vec4( SCNOBJ_TYPE_PRIMITIVE, ZERO ), vec4( obj.paramsA.xyz, 2 ), obj.paramsB ), addr + ivec2( k, 0 ), sc, fc );
		k++;
		obj.r += obj.B * obj.paramsB.xyz;
		obj.r -= obj.B[2] * obj.paramsA.w;
		so_store( SceneObj( obj.B, obj.r, vec4( SCNOBJ_TYPE_PRIMITIVE, ZERO ), vec4( obj.paramsA.xyz, 2 ), vec4( obj.paramsB.ww, obj.paramsA.w, 0 ) ), addr + ivec2( k, 0 ), sc, fc );
		k++;
		obj.r -= obj.B[2] * ( obj.paramsA.w + 0.001 );
		so_store( SceneObj( obj.B, obj.r, vec4( SCNOBJ_TYPE_PRIMITIVE, ZERO ), vec4( obj.paramsA.xyz, 2 ), vec4( obj.paramsB.ww + 0.001, 0.001, 0 ) ), addr + ivec2( k, 0 ), sc, fc );
		k++;
		obj.r -= obj.B[2] * ( 0.005 );
		so_store( SceneObj( obj.B, obj.r, vec4( SCNOBJ_TYPE_PRIMITIVE, ZERO ), vec4( obj.paramsA.xyz, 2 ), vec4( obj.paramsB.ww + 0.002, 0.0005, 0 ) ), addr + ivec2( k, 0 ), sc, fc );
		k++;
		obj.r -= obj.B[2] * ( 0.003 );
		float s = sin( timer ), c = cos( timer );
		mat3 M = mat3( c, -s, 0, s, c, 0, 0, 0, 1 );
		obj.B *= M;
		so_store( SceneObj( obj.B, obj.r, vec4( SCNOBJ_TYPE_PRIMITIVE, ZERO ), vec4( obj.paramsA.xyz, 2 ), vec4( obj.paramsB.w, 0.0005, 0.0002, 0 ) ), addr + ivec2( k, 0 ), sc, fc );
		k++;
	}
	else
	if( type == SCNOBJ_TYPE_LIGHTHOUSE )
	{
		obj.r -= obj.B[2] * obj.paramsA.w;
		so_store( SceneObj( obj.B, obj.r, vec4( SCNOBJ_TYPE_PRIMITIVE, ZERO ), vec4( -99, 10, 13, 3 ), vec4( obj.paramsB.w, obj.paramsA.w, 0, 0 ) ), addr + ivec2( k, 0 ), sc, fc );
		k++;
		obj.r += obj.B * vec3( obj.paramsB.xy, obj.paramsA.w );
		obj.r -= obj.B[2] * obj.paramsB.z;
		so_store( SceneObj( obj.B, obj.r, vec4( SCNOBJ_TYPE_PRIMITIVE, ZERO ), vec4( obj.paramsA.xyz, 2 ), obj.paramsB ), ADDR_SCENE_OBJECTS + ivec2( k, 0 ), sc, fc );
		k++;
		obj.r -= obj.B * vec3( obj.paramsB.xy, 2. * obj.paramsA.w );
		obj.r -= obj.B[2] * ( 0.0005 - obj.paramsB.z );
		so_store( SceneObj( obj.B, obj.r, vec4( SCNOBJ_TYPE_PRIMITIVE, ZERO ), vec4( obj.paramsA.xyz, 3 ), vec4( obj.paramsB.w + 0.0005, 0.0005, 0, 0 ) ), addr + ivec2( k, 0 ), sc, fc );
		k++;
		obj.r -= obj.B[2] * 0.0025;
		so_store( SceneObj( obj.B, obj.r, vec4( SCNOBJ_TYPE_PRIMITIVE, ZERO ), vec4( obj.paramsA.xyz, 3 ), vec4( obj.paramsB.w - 0.0005, 0.0015, 0, 0 ) ), addr + ivec2( k, 0 ), sc, fc );
		k++;
		obj.r -= obj.B[2] * 0.0025;
		so_store( SceneObj( obj.B, obj.r, vec4( SCNOBJ_TYPE_PRIMITIVE, ZERO ), vec4( obj.paramsA.xyz, 3 ), vec4( obj.paramsB.w, 0.00025, 0, 0 ) ), addr + ivec2( k, 0 ), sc, fc );
		k++;
	}
	else
	{
		int primtype = int( obj.paramsA.w );
		float offset =
			type != SCNOBJ_TYPE_PRIMITIVE ? 0. :
			primtype == SCNOBJ_PRIMITIVE_SPHERE ? obj.paramsB.x :
			primtype == SCNOBJ_PRIMITIVE_CUBE ? obj.paramsB.z :
			primtype == SCNOBJ_PRIMITIVE_CYLINDER ? obj.paramsB.y :
			0.;
		obj.r -= obj.B[2] * offset;
		so_store( obj, addr + ivec2( k, 0 ), sc, fc );
		k++;
	}

	return k;
}

void so_dynamic_bubblesort( int index, vec3 campos, ivec2 sc, inout vec4 fc )
{
	int phase = ( iFrame & 1 ) / 1;
	int indexeven = ( ( index + phase ) & ~1 ) - phase;
	SceneObj obj1 = so_load( iChannel0, ADDR_SCENE_DATA + ivec2( indexeven + 0, 0 ) );
	SceneObj obj2 = so_load( iChannel0, ADDR_SCENE_DATA + ivec2( indexeven + 1, 0 ) );
	float d1 = distance( campos, obj1.r ) * obj2.tybr.y;
	float d2 = distance( campos, obj2.r ) * obj1.tybr.y;
	bool inorder = int( obj1.tybr ) == SCNOBJ_TYPE_INVALID ||
				   int( obj2.tybr ) == SCNOBJ_TYPE_INVALID ||
				   d1 < d2;
	so_store( obj1, ADDR_SCENE_DATA + ivec2( indexeven + int( !inorder ), 0 ), sc, fc );
	so_store( obj2, ADDR_SCENE_DATA + ivec2( indexeven + int( inorder ), 0 ), sc, fc );
}

// ----------------------------------------------------------------------------
// PLANET STATE
// ----------------------------------------------------------------------------

PlanetState ps_init( PlanetData data )
{
	PlanetState ps = PlanetState( ZERO, ZERO, 0., IDENTITY, ZERO, ZERO, 0., 0., 0., 0. );
	ps.dnudt90 = safediv( TAU, data.orb_period * sqrt( abs( cube( 1. - data.orbit.e * data.orbit.e ) ) ) ) / 3600.;
	ps.nu = PI - data.orbit.O - data.orbit.w;
	ps.E = kp_nu2E( ps.nu, data.orbit.e );
	ps.M = kp_E2M( ps.E, data.orbit.e );
	ps.B[2] = vec3(
		cos( data.rot_northpole.x ) * cos( data.rot_northpole.y ),
		cos( data.rot_northpole.x ) * sin( data.rot_northpole.y ),
		sin( data.rot_northpole.x ) );
	ps.B[0] = normalize( reject( -UNIT_X, ps.B[2] ) );
	ps.B[1] = cross( ps.B[2], ps.B[0] );
	ps.omega = safediv( TAU, data.rot_period * 3600. );
	kp_get_vectors( data.orbit, ps.nu, ps.dnudt90, ps.orbitr, ps.orbitv );
	ps.r = ps.orbitr;
	ps.v = ps.orbitv;
	return ps;
}

void ps_pace( inout PlanetState ps, Kepler orbit, float dt )
{
	ps.nu += dt * ps.dnudt90 * square( 1. + orbit.e * cos( ps.nu ) );
	ps.E = kp_nu2E( ps.nu, orbit.e );
	ps.M = kp_E2M( ps.E, orbit.e );
	ps.B = matrixspin( ps.B, dt * ps.omega * ps.B[2] );
}

// ----------------------------------------------------------------------------
// FLIGHT DYNAMICS
// ----------------------------------------------------------------------------

float lift_efficiency_curve( float s, float c, vec4 config, float influence )
{
	config.z = mix( config.w, config.z, influence );
	return mix( config.z, config.w, c < 0. ? 1. : clamp( safediv( abs(s) - config.x, config.y - config.x ), 0., 1. ) );
}

float mach_curve( float M, float CD0, vec3 machcfg )
{
	float c = safediv( machcfg.y - machcfg.z, CD0 + machcfg.z );
	float k = safediv( c, c + 1. );
	float b = ( 1. - machcfg.x ) * k;
	return M < machcfg.x ? 0. : safediv( k * square( M - machcfg.x ), c * square( M - machcfg.x - b ) + b * b );
}

float delta_sincos( float s, float c, float ds, float dc, float newton )
{
	float s2 = s * s;
	float c2 = c * c;
	float ds2ssds = ds * ds * sign( s + ds );
	float dc2ssds = dc * dc * sign( s + ds );
	float a = ds * ( dc * ( c * c - s * s ) - 2. * ds * s * c );
	float b = c2 * ( c * dc * ds2ssds - s * ( ds2ssds * ds - 2. * dc2ssds * ds ) ) +
			+ s2 * ( c * ( dc2ssds * dc - 2. * ds2ssds * dc - sign(s) ) - s * ds * dc2ssds );
	return mix( b, a, newton );
}

float log_reynolds_curve( float r )
{
	return r <= 0. ? 0. :
		   r >= .957447 && r < 1.04444 ? r / 2. - square( 1. - r ) / 12. :
		   r * r * log(r) / ( r * r - 1. );
}

struct FdInputs
{
	vec4 CD;
	vec4 CL, CY, Cl;
	vec3 C90;
	vec2 Cside;
	float Cadot;
	vec3 CL_for_F;
	vec3 CY_for_F;
};

FdInputs fd_inputs_init( float u, float v, float w,
						 float p, float q, float r,
						 float d_wu_de, float d_wu_da, float d_uv_dr,
						 float adot, float cos_b, float mach_drag,
						 float newton )
{
  	float nw = mix( abs(w), 1., newton );
	float nv = mix( abs(v), 1., newton );
	FdInputs inputs;
	inputs.CD = vec4( 1, w * w * nw, v * v * nv, mach_drag );
	inputs.CL = vec4( vec3( 1, w, q ) * u * nw, d_wu_de );
	inputs.CY = vec4( vec3( v, p, r ) * u * nv, d_uv_dr );
	inputs.Cl = vec4( vec3( v, p, r ) * u * nv, d_wu_da );
	inputs.C90 = vec3( w * nw, q * nw, v * nv ) * w * w;
	inputs.Cside = vec2( v, r ) * v * v * nv;
	inputs.Cadot = adot * u * nw;
	inputs.CL_for_F = vec3( 1, w, q ) * v * cos_b * nw;				// CL inputs rewritten with u exchanged for v * cos_b
	inputs.CY_for_F = vec3( v, p, r ) * w * nv;						// CY inputs rewritten with u exchanged for w
	return inputs;
}

struct FdDerivs
{
	vec4 CD;
	vec4 CL, CY, Cm, Cn, Cl;
	vec2 Cadot;
};

FdDerivs fd_derivs_init( vec3 fsg, float u, float cos_a, float eta, float rare )
{
	vec4 config = vec4( VD.config * fsg, VD.gearClb * fsg.z );
	FdDerivs derivs;
	derivs.CD = vec4( config.x + VD.CD.x, VD.CD.yz, VD.mach.y );
	derivs.CL = vec4( config.y + VD.CL.x, VD.CL.yzw ) * eta * rare;
	derivs.Cm = vec4( config.z + VD.Cm.x, VD.Cm.yzw ) * eta * rare;
	derivs.CY = VD.CY * rare;
	derivs.Cn = VD.Cn * rare;
	derivs.Cl = vec4( config.w + VD.Cl.x, VD.Cl.yzw ) * vec4( mix( 1., eta, VD.RekD.y ) * u, u, u, eta * cos_a ) * rare;
	derivs.Cadot = VD.Cadot * eta * rare;
	return derivs;
}

struct FdCoeffs
{
	float CD, CQ, CL;
	float Cl, Cm, Cn;
};

FdCoeffs fd_coeffs_init( FdInputs inputs, FdDerivs derivs,
						 float u, float v, float w, float sin_a, float cos_a,
						 float eta, float rare, vec4 gnh, vec3 gnhw )
{
	// compute basic linear flight dynamics

	float CD = dot( derivs.CD, inputs.CD );							// CD0, CDa2, CDb2, wave drag
	float CL = dot( derivs.CL, inputs.CL );							// CL0, CLa, CLq, CLde
	float Cm = dot( derivs.Cm, inputs.CL ) * cos_a;					// Cm0, Cma, Cmq, Cmde
	float CY = dot( derivs.CY, inputs.CY );							// CYb, CYp, CYr, CYdr
	float Cn = dot( derivs.Cn, inputs.CY ) * u;						// Cnb, Cnp, Cnr, Cndr
	float Cl = dot( derivs.Cl, inputs.Cl );							// Clb, Clp, Clr, Clda
	float CF = dot( derivs.CL.xyz, inputs.CL_for_F )				// CF = ( CL * sin_b + CY * sin_a ) / cos_a
			 + dot( derivs.CY.xyz, inputs.CY_for_F );
	float CQ = CY * cos_a + CF * sin_a;								// CQ = ( CY + CL * sin_b ) / cos_a

	// + special effects

	CL += derivs.Cadot.x * inputs.Cadot;							// + CLadot
	Cm += derivs.Cadot.y * inputs.Cadot * cos_a;					// + Cmadot

	CD += VD.CD.w * square( dot( derivs.CL.yzw, inputs.CL.yzw ) );	// + CDi
	Cm += VD.Cmisc.y * square( derivs.CL.y * inputs.CL.y ) * w;		// + Cmi

	Cm += dot( VD.C90.xy, inputs.C90.xy );							// + Cm90, Cmq90
	Cn += VD.C90.z * inputs.C90.z;									// + Cnb90
	Cl += VD.C90.w * inputs.C90.z;									// + Clb90

	float ClCn = safediv( VD.Cl.x, VD.Cn.x ) * ( 1. - VD.RekD.y );
	Cn += dot( VD.Cside, inputs.Cside );							// + Cnside, Cnpside
	Cl += dot( VD.Cside, inputs.Cside ) * ClCn;						// + Clside, Clrside (via roll-yaw coupling)
	Cl += VD.Cmisc.x * eta * u * v * w * rare;	              		// + Clab

	// + ground effect

#if WORKAROUND_12_TANH
	float greff = dot( vec3( -CD, CQ, -CL ), gnhw ) * ( 1. - tanh( clamp( gnh.w / ( 2. * VD.Sbcm.y * VD.ground.z ), -10., 10. ) ) );
#else
	float greff = dot( vec3( -CD, CQ, -CL ), gnhw ) * ( 1. - tanh( gnh.w / ( 2. * VD.Sbcm.y * VD.greff.z ) ) );
#endif
	CD -= greff * VD.ground.x * gnhw.x;
	CQ += greff * VD.ground.x * gnhw.y;
	CL -= greff * VD.ground.x * gnhw.z;
	Cl += greff * VD.ground.y * cross( UNIT_Z, gnh.xyz ).x * VD.Sbcm.z / VD.Sbcm.y;
	Cm += greff * VD.ground.y * cross( UNIT_Z, gnh.xyz ).y;

	return FdCoeffs( CD, CQ, CL, Cl, Cm, Cn );
}

FdCoeffs fd_compute_coeffs(
	float u, float v, float w, float p, float q, float r,
	vec3 ctrl, vec3 fsg, vec4 gnh, vec3 gnhw,
	float sin_a, float cos_a, float sin_b_cos_a, float cos_b, float adot )
{
	// Ma/Re/Kn modifiers

	float Re = max( FRACT_1_256, LE.fe.Re );
	float Kn = LE.fe.Kn;
	float newton = square( VD.mach.w ) / ( square( VD.mach.w ) + square( LE.fe.Ma ) );
	float rare = sqrt( VD.rare.x ) / ( sqrt( VD.rare.x ) + sqrt( LE.fe.Kn ) );
	float liftboost = .217125526 * log_reynolds_curve( 100. * LE.fe.Re / VD.RekD.x );
	float eta = lift_efficiency_curve( sin_a, cos_a, VD.etaCL, liftboost );

	// control variables

	vec3 sinctrl = sinatan( ctrl * VD.dx_max );
	vec3 cosctrl = cosatan( ctrl * VD.dx_max );
	float d_wu_de = delta_sincos( w, u, sinctrl.x, cosctrl.x, newton );
	float d_wu_da = delta_sincos( w, u, sinctrl.y, cosctrl.y, newton );
	float d_uv_dr = delta_sincos( sin_b_cos_a, u, sinctrl.z, cosctrl.z, newton );

	// derivative inputs

	FdInputs inputs = fd_inputs_init(
		u, v, w,
		p, q, r,
		d_wu_de, d_wu_da, d_uv_dr,
		adot, cos_b, mach_curve( LE.fe.Ma, VD.CD.x, VD.mach.xyz ), newton );

	// stability derivatives

	FdDerivs derivs = fd_derivs_init( fsg, u, cos_a, eta, rare );

	// force and moment coefficients

	FdCoeffs coeffs = fd_coeffs_init( inputs, derivs, u, v, w, sin_a, cos_a, eta, rare, gnh, gnhw );

	// apply the low-Reynolds/high-Knudsen drag boost to the drag, and by extension also to all moments
	// under the assumption that lift is no longer a contributor when this effect becomes significant

	float CD_orig = coeffs.CD;
	coeffs.CD = ( coeffs.CD * ( 1. + 9. * Kn ) + .126491106 * ( inversesqrt( Re ) - inversesqrt( VD.RekD.x ) ) + .024 / ( VD.Rn.w * Re ) - .24 / ( VD.Rn.w * VD.RekD.x ) ) / ( 1. + 3. * Kn );
	coeffs.Cl *= safediv( coeffs.CD, CD_orig );
	coeffs.Cm *= safediv( coeffs.CD, CD_orig );
	coeffs.Cn *= safediv( coeffs.CD, CD_orig );

	return coeffs;
}

void compute_flight_dynamics(
	vec3 velo,			// incoming wind velocity vector (= 'uvw' in body axes)
	vec3 rates,			// rotation rates (= 'pqr' in body axes)
	vec3 ctrl,			// control inputs 0..1 (de, da, dr)
	vec3 fsg,			// flaps/spoilers/gears
	vec4 gnh,			// direction of local ground normal and ground clearance
	float wdelay,		// time-lagged z component of the velo vector, must have an effective delay of c_bar/(2u) seconds
	inout vec3 uvwdot,	// = accelerations (body axes)
	inout vec3 pqrdot,	// = angular accelerations (body axes)
	inout vec3 info )
{
	vec3 XYZ = ZERO;
	vec3 LMN = ZERO;

	float S = VD.Sbcm.x;
	float V2 = dot( velo, velo );

	if( V2 >= FRACT_2_TO_NEG_48 )
	{
		float V = sqrt( V2 );
		float rcpV = 1. / V;

		// wind axes frame

		mat3x3 W;
		W[0] = velo * rcpV;
		W[2] = safenormalize( cross( W[0], UNIT_Y ) );
		W[1] = cross( W[2], W[0] );

		// common variables

		float b = VD.Sbcm.y,			c_bar = VD.Sbcm.z;
		float u = W[0].x,				p = sinatan( rates.x * rcpV * b / 2. );
		float v = W[0].y,				q = sinatan( rates.y * rcpV * c_bar / 2. );
		float w = W[0].z,				r = sinatan( rates.z * rcpV * b / 2. );
		float sin_a = -W[2].x,			cos_a = W[2].z;
		float sin_b = W[0].y,			cos_b = W[1].y;
		float sin_b_cos_a = -W[1].x,	adot = ( velo.z - wdelay ) * rcpV;

		// aerodynamic coefficients

		FdCoeffs coeffs = fd_compute_coeffs(
			u, v, w, p, q, r, ctrl, fsg, gnh, gnh.xyz * W,
			sin_a, cos_a, sin_b_cos_a, cos_b, adot );

		// forces and moments in body axes frame

		float QS = LE.fe.rho * V2 * S / 2.;
		XYZ = QS * W * vec3( -coeffs.CD, coeffs.CQ, -coeffs.CL );
		LMN = QS * vec3( coeffs.Cl, coeffs.Cm, coeffs.Cn ) * vec3( b, c_bar, b );

		info.x = coeffs.CL;
		info.y = coeffs.CD;
		info.z = degrees( atan( sin_a, cos_a ) );
	}

	// = linear accelerations in body axes

	float invm = safediv( FDM_MASS_SCALE, VD.Sbcm.w );
	uvwdot = XYZ * invm /* + cross( velo, rates ) */;

	// = angular accelerations in body, incl inertia

	LMN += ( rates.yzx * rates.zxy * ( VD.I.yzx - VD.I.zxy ) + cross( rates, vec3( rates.xz, 0 ).yzx ) * VD.I.w ) / FDM_MASS_SCALE;
	pqrdot.y = safediv( LMN.y * FDM_MASS_SCALE, VD.I.y );
	pqrdot.xz = ( VD.I.zw * LMN.x + VD.I.wx * LMN.z ) * safediv( FDM_MASS_SCALE, determinant( mat2( VD.I.zw, VD.I.wx ) ) );
}

// ----------------------------------------------------------------------------
// VEHICLE STATE
// ----------------------------------------------------------------------------

void vs_cvt_local2orbit( inout VehicleState vs, PlanetState ps )
{
	vec3 localpsomega = vec3( 0, 0, ps.omega );
	vs.orbitr = ps.B * ( vs.localr );
	vs.orbitv = ps.B * ( vs.localv + cross( localpsomega, vs.localr ) );
	vs.B = ps.B * ( vs.localB );
	vs.omega = ps.B * ( vs.localomega + localpsomega );
}

void vs_cvt_orbit2local( inout VehicleState vs, PlanetState ps )
{
	vec3 localpsomega = vec3( 0, 0, ps.omega );
	vs.localr = vs.orbitr * ps.B;
	vs.localv = vs.orbitv * ps.B - cross( localpsomega, vs.localr );
	vs.localB = transpose( ps.B ) * vs.B;
	vs.localomega = vs.omega * ps.B - localpsomega;
}

void vs_cvt_orbit2global( inout VehicleState vs, PlanetState ps )
{
	vs.r = vs.orbitr + ps.r;
	vs.v = vs.orbitv + ps.v;
}

void vs_cvt_global2orbit( inout VehicleState vs, PlanetState ps )
{
	vs.orbitr = vs.orbitr - ps.r;
	vs.orbitv = vs.orbitv - ps.v;
}

void vs_commit_local( inout VehicleState vs, PlanetState ps )
{
	vs_cvt_local2orbit( vs, ps );
	vs_cvt_orbit2global( vs, ps );
	vs.localr_diff = ZERO;
	vs.localr_base = vs.localr;
}

void vs_commit_orbit( inout VehicleState vs, PlanetState ps )
{
	vs_cvt_orbit2local( vs, ps );
	vs_cvt_orbit2global( vs, ps );
	vs.localr_diff = ZERO;
	vs.localr_base = vs.localr;
}

void rot90( inout vec3 a, inout vec3 b )
	{ vec3 tmp = a; a = b; b = -tmp; }

void vs_reset_to_orbiting( inout VehicleState vs, PlanetState ps, PlanetData pd, vec4 navb, bool downfacing )
{
	vs = vs_init();
	float R = navb.z + pd.radius;
	vs.localr = nav2r( vec3( navb.xy, R ) );
	vs.localB = bearing2B( vs.localr, navb.w );
	if( downfacing )
		{ rot90( vs.localB[1], vs.localB[0] ); rot90( vs.localB[0], vs.localB[2] ); }
	vs.orbitr = ps.B * vs.localr;
	vs.B = ps.B * vs.localB;
	vs.orbitv = sqrt( pd.GM / R ) * normalize( downfacing ? vs.B[1] : vs.B[0] );
	vs.omega = cross( vs.orbitr, vs.orbitv ) / dot( vs.orbitr, vs.orbitr );
	vs_commit_orbit( vs, ps );
	vs.modes = ivec3( VS_HMD_ORB, 0, VS_ENG_IMP );
	vs.modes2 = ivec3( 0, VS_RCS_LVLH, VS_THR_MAN );
}

void vs_reset_to_offroad( inout VehicleState vs, PlanetState ps, PlanetData pd, vec4 navb )
{
	vs = vs_init();
	float R = navb.z + pd.radius;
	vs.localr = nav2r( vec3( navb.xy, R ) );
	vs.localB = bearing2B( vs.localr, navb.w );
	vs_commit_local( vs, ps );
	vs.FSG.z = 1.;
	vs.modes = ivec3( VS_HMD_SFCE, 0, VS_ENG_DRV );
	vs.modes2 = ivec3( VS_AERO_MAN, 0, VS_THR_MAN );
	bit_set( vs.switches, VS_SW_GEARS );
}

void vs_reset_to_threshold( inout VehicleState vs, PlanetState ps, SceneObj runway, float sense )
{
	vs = vs_init();
	vs.localr = runway.r - runway.B[0] * sense * ( runway.paramsB.x / 2. - 30. ) / 1000.;
	vs.localB[0] = runway.B[0] * sense;
	vs.localB[1] = cross( vs.localB[0], normalize( vs.localr ) );
	vs.localB[2] = cross( vs.localB[0], vs.localB[1] );
	vs_commit_local( vs, ps );
	vs.FSG.z = 1.;
	vs.modes = ivec3( VS_HMD_SFCE, 0, VS_ENG_IMP );
	vs.modes2 = ivec3( VS_AERO_MAN, 0, VS_THR_MAN );
	bit_set( vs.switches, VS_SW_GEARS );
}

void vs_realize_startpos( inout VehicleState vs, inout GameState gs, PlanetState ps, StartData start )
{
#if WORKAROUND_03_SWITCH
	if( start.iparams.x == 1 )
		vs_reset_to_orbiting( vs, ps, PD, start.params * vec4( 1, 1, start.iparams.z != 0 ? SCN_SCALE : ATM_SCALE, 1 ), bool( start.iparams.y ) );
	else
	if( start.iparams.x == 2 )
		vs_reset_to_offroad( vs, ps, PD, start.params * vec4( 1, 1, TRN_SCALE, 1 ) );
	else
	if( start.iparams.x == 3 && start.iparams.y < SCENE_DATA_COUNT )
		vs_reset_to_threshold( vs, ps,
			so_init( sd_load( iChannel1, ivec2( 0, ADDR_B_SCENE_DATA + SCENE_DATA_SIZE * start.iparams.y ) ) ),
			start.params.x );
#else
	switch( start.iparams.x )
	{
	case 1:
		vs_reset_to_orbiting( vs, ps, PD, start.params * vec4( 1, 1, start.iparams.z != 0 ? SCN_SCALE : ATM_SCALE, 1 ), bool( start.iparams.y ) );
		break;
	case 2:
		vs_reset_to_offroad( vs, ps, PD, start.params * vec4( 1, 1, TRN_SCALE, 1 ) );
		break;
	case 3:
		if( start.iparams.y < g_scene_data_length )
			vs_reset_to_threshold( vs,
				so_init( sd_load( iChannel1, ivec2( 0, ADDR_B_SCENEDATA + ADDR_SCENE_DATA_SIZE * start.iparams.y ) ) ),
				start.params.x );
		break;
	}
#endif

	if( start.iparams.w > 0 && start.iparams.w < SCENE_DATA_COUNT )
		gs.waypoint = nav2r( sd_load( iChannel1, ivec2( 0, ADDR_B_SCENE_DATA + SCENE_DATA_SIZE * start.iparams.w ) ).navb.xyz + UNIT_Z * PD.radius );
}

void vs_pace_switches( inout VehicleState vs, VehicleInputs vi )
{
	bitfield_set( vs.switches, VS_SW_FLAPS_MASK, VS_SW_FLAPS_SHIFT,
		uint( clamp( float( bitfield_get_uint( vs.switches, VS_SW_FLAPS_MASK, VS_SW_FLAPS_SHIFT ) ) + vi.flapsswitch, 0., VS_FLAPS_MAX ) ) );

	bitfield_set( vs.switches, VS_SW_TVEC_MASK, VS_SW_TVEC_SHIFT,
		uint( clamp( float( bitfield_get_uint( vs.switches, VS_SW_TVEC_MASK, VS_SW_TVEC_SHIFT ) ) + vi.tvecswitch, 0., VS_TVEC_MAX ) ) );

	if( vi.spoiltoggle != 0. )
		bit_toggle( vs.switches, VS_SW_SPOIL );

	if( vi.gearstoggle != 0. )
		bit_toggle( vs.switches, VS_SW_GEARS );

	if( vi.lightstoggle != 0. )
		bit_toggle( vs.switches, VS_SW_LIGHT );

	if( vi.canopytoggle != 0. )
		bit_toggle( vs.switches, VS_SW_CANOPY );

	/*
	if( lensq( vs.localv ) >= 0.0004 )
		bit_set( vs.switches, VS_SW_CANOPY );
	*/
}

void vs_pace_FSG( inout VehicleState vs, float dt )
{
	vec3 FSG_target = vec3(
		vs_flaps_notches( float( bitfield_get_uint( vs.switches, VS_SW_FLAPS_MASK, VS_SW_FLAPS_SHIFT ) ) ),
		float( bit_is_set( vs.switches, VS_SW_SPOIL ) ),
		float( bit_is_set( vs.switches, VS_SW_GEARS ) ) );
	vec3 FSG_move = vec3( .125, .5, .125 );
	vec3 FSG_delta = dt * clamp( 8. * ( FSG_target - vs.FSG ), -FSG_move, FSG_move );
	vs.FSG = clamp( vs.FSG + FSG_delta, -1., 1. );
	float tvec_target = vs_tvec_notches( float( bitfield_get_uint( vs.switches, VS_SW_TVEC_MASK, VS_SW_TVEC_SHIFT ) ) );
	float tvec_move = 15.;
	float tvec_delta = dt * clamp( 25. * ( tvec_target - vs.tvec ), -tvec_move, tvec_move );
	vs.tvec = clamp( vs.tvec + tvec_delta, 0., 180. );
}

void vs_pace_canopy( inout VehicleState vs, float dt )
{
	float canopy_target = float( bit_is_set( vs.switches, VS_SW_CANOPY ) );
	float canopy_move = .25;
	float canopy_delta = dt * clamp( 8. * ( canopy_target - vs.canopy ), -canopy_move, canopy_move );
	vs.canopy = clamp( vs.canopy + canopy_delta, 0., 1. );
}

void vs_pace_throttle( inout VehicleState vs, VehicleInputs vi, float dt )
{
	if( vi.throttlecommand == -9999. )
		vs.throttle = 0.;
	else
	{
		float modelimit = vs.modes.z == VS_ENG_IMP ? -0.15 : -1.;
		float tmin = bit_is_unset( vs.switches, VS_SW_THROTTLE_EDGE ) ? modelimit :
			vs.throttle >= 0. ? 0. : modelimit;
		float tmax = bit_is_unset( vs.switches, VS_SW_THROTTLE_EDGE ) ? 1. :
			vs.throttle <= .00 ? .00 :
			vs.throttle <= .15 ? .15 :
			vs.throttle <= .35 ? .35 :
			vs.throttle <= .70 ? .70 : 1.;
		vs.switches = bit_set_to( vs.switches, VS_SW_THROTTLE_EDGE, uint( vi.throttlecommand != 0. && vs.thr_hold < .5 ) );
		float delta = .25 * dt * vi.throttlecommand;
		vs.thr_hold = vs.throttle + delta > tmax ? vs.thr_hold + 4. * ( vs.throttle + delta - tmax ) : 0.;
		vs.throttle = clamp( vs.throttle + delta, tmin, tmax );
	}
}

void vs_pace_EAR_and_trim( inout VehicleState vs, VehicleInputs vi, float dt )
{
	vec3 target = ZERO;
	if( vs.modes2.x == VS_AERO_MAN )
	{
		vs.trim = clamp( vs.trim + dt * .0625 * vi.trimcommand, -1., 1. );
		target = vi.vjoy_copy + vs.trim * UNIT_X;
	}
	else
	if( vs.modes2.x == VS_AERO_FBW )
		target = vec3( vs.aerostuff.yw, vi.vjoy_copy.z );
	target = clamp( target, -1., 1. );
	vs.EAR += sign( target - vs.EAR ) * min( abs( target - vs.EAR ), 2. * dt );
}

void vs_pace_RCS( VehicleState vs, VehicleInputs vi, PlanetState ps, float dt,
				  inout vec3 domega, bool localphysics, bool pausemode )
{
	const float MAX_RCS_THRUST = 0.06;	// TODO: CONFIG

	vec3 thrustercommand = ZERO;
	vec3 joycmd = vi.joycommand.yxz * vec3( 1, 1, -1 );

	if( vs.modes2.y == VS_RCS_MAN )
		thrustercommand = joycmd * MAX_RCS_THRUST;
	else
	if( vs.modes2.y != VS_RCS_OFF )
	{
		vec3 bodyomega = vs.omega * vs.B;
		vec3 targetomega = radians( 12. ) * joycmd;

		if( vs.modes2.y == VS_RCS_LVLH )
		{
			vec3 localpsomega = vec3( 0, 0, ps.omega );
			if( !pausemode )
				targetomega += cross( vs.orbitr, vs.orbitv ) / dot( vs.orbitr, vs.orbitr ) * vs.B;
		}

		targetomega = length( targetomega ) < .25 ? targetomega : normalize( targetomega );
		thrustercommand = clamp( targetomega - bodyomega, -MAX_RCS_THRUST, MAX_RCS_THRUST );
	}

	domega += ( localphysics ? vs.localB : vs.B ) * ( -expm1( -2. * dt ) * thrustercommand );
}

void vs_pace_thrust( VehicleState vs, float dt,
					 inout vec3 dv, bool localphysics )
{
	if( vs.modes.z == VS_ENG_IMP )
	{
		float T_max = VD.T_max;
		float mass = VD.Sbcm.w / FDM_MASS_SCALE;
		vec2 sct = sincospi( vs.tvec / 180. );
		vec3 tvec = vec3( sct.y, 0, -sct.x );
		dv += 0.001 * dt * vs.throttle * T_max / mass * ( ( localphysics ? vs.localB : vs.B ) * tvec );
	}
}

void vs_pace_flight_dynamics( inout VehicleState vs, vec4 localterrain,
							  float dt, inout vec3 dv, inout vec3 domega, vec3 dr )
{
	vec3 uvw = 1000. * vs.localv * vs.localB;
	vec3 pqr = vs.localomega * vs.localB;
	vec3 uvwdot = ZERO, pqrdot = ZERO;
	float invtau = length( uvw ) * 2. / VD.Sbcm.z;

	vec3 N = normalize( localterrain.xyz );
	float bN = dot( vs.localr_base, N );
	float dN = dot( vs.localr_diff + dr, N );
	float tN = dot( normalize( vs.localr ), N ) * ( localterrain.w + PD.radius );
	float clearance = dN - FORCE_EVAL( tN - bN );

	vs.wdelay -= expm1( -dt * invtau ) * ( uvw.z - vs.wdelay );

	compute_flight_dynamics(
		uvw,
		pqr,
		vec3( -vs.EAR.x, vs.EAR.yz ),
		vs.FSG,
		vec4( N * vs.localB, 1000. * clearance ),
		vs.wdelay,
		uvwdot,
		pqrdot,
		vs.info.xyz );

	dv += dt * vs.localB * ( uvwdot /* - cross( uvw, pqr ) */ ) / 1000.;
	domega += dt * vs.localB * pqrdot;
}

vec3 calc_gravity_relief( vec3 r, vec3 v )
{
	vec3 omega = cross( r, v ) / dot( r, r );
	return cross( omega, cross( omega, r ) );
}

vec3 calc_gravity( vec3 r )
{
	float r2 = dot( r, r );
	return r2 < square( PD.radius ) ?
		- PD.GM / cube( PD.radius ) * r :
		- PD.GM / ( r2 * sqrt( r2 ) ) * r;
}

void vs_pace_fly_by_wire( inout VehicleState vs, VehicleInputs vi, float dt, vec3 gr )
{
	float V2 = max( FRACT_1_65536, dot( vs.localv, vs.localv ) );
	float Q = max( .02, 5. * LE.fe.rho * V2 );
	float V = sqrt( V2 );

	float c = length( reject( normalize( vs.localv ), normalize( vs.localr ) ) );
	float d = length( reject( normalize( vs.localB[1] ), normalize( vs.localr ) ) );
	float g0 = length( gr ) * c / max( .5, d );
	float thr = -0.0005 * vs.throttle * VD.T_max / VD.Sbcm.w * sin( radians( vs.tvec ) );
	float cmd = ( ( vi.vjoy_copy.x < 0. ?
		 ( -.0015 * FDM_STD_G - g0 - thr ) :
		 (	.0035 * FDM_STD_G - g0 - thr ) ) ) * abs( vi.vjoy_copy.x );
	vec3 uvw = vs.localv * vs.localB / V;
	vec3 pqr = vs.localomega * vs.localB * VD.Sbcm.yzy / ( 2000. * V );
	float adot = ( dot( gr, vs.localB[2] ) + vs.acc.z ) * VD.Sbcm.z / ( 2000. * V2 ) + pqr.y;
	float eta = lift_efficiency_curve( uvw.z, uvw.x, VD.etaCL, V / LE.fe.a );
	vec3 config = VD.config * vs.FSG;

	const float ki = .25;
	const float kp = .2;
	const float kd = 18.;
	float kr = min( 3., LE.fe.rho );
	float krinv = min( 1., inversesqrt( LE.fe.rho ) );

	vs.aerostuff.x = clamp( vs.aerostuff.x + dt * ( cmd + g0 + thr + vs.acc.z ) / ( krinv ), -FRACT_1_16, FRACT_1_16 );

	float acctgt = ( cmd + g0 + thr + ki * vs.aerostuff.x );
	float CLtgt = clamp( acctgt * VD.Sbcm.w / ( Q * VD.Sbcm.x * 100. ), -2., 2. );
	float CLtgt_a = ( CLtgt - VD.CL.x - config.y ) / eta - VD.CL.z * pqr.y + VD.CL.w * vs.EAR.x * VD.dx_max.x - .25 * VD.Cadot.x * adot;
	float atgt = clamp( CLtgt_a / VD.CL.y, -.5, .5 );
	float aerr = kr * ( atgt - uvw.z ) - krinv * kd * adot;
	float adottgt = clamp( kr * kp * aerr, -2., 2. );
	float qtgt = adottgt + pqr.y - adot;

	float Cmtgt_de = VD.Cm.x + config.z + ( VD.Cm.y * atgt + krinv * VD.Cm.z * qtgt + .25 * VD.Cadot.y * adottgt ) * eta;
	vs.aerostuff.y = Cmtgt_de / ( VD.Cm.w * VD.dx_max.x );

	float ptgt = 1. * vi.vjoy_copy.y * VD.Sbcm.y / ( 2000. * V );

	vs.aerostuff.z = clamp( vs.aerostuff.z + dt * ( ptgt - pqr.x ), -.02, .02 );

	ptgt += .5 * vs.aerostuff.z;

	float Cltgt_da = ( VD.Cl.x + VD.gearClb * vs.FSG.z ) * uvw.y * mix( 1., eta, VD.RekD.y ) + VD.Cl.y * ptgt + VD.Cl.z * pqr.z;
	vs.aerostuff.w = -Cltgt_da / ( VD.Cl.w * VD.dx_max.y );
}

bool vs_pace_ground_interaction( VehicleState vs, VehicleInputs vi, vec4 localterrain, float dt,
								 inout vec3 dv, inout vec3 domega, inout vec3 dr )
{
	bool result = false;
	vec3 tentative_localv = vs.localv + dv;
	vec3 N = normalize( localterrain.xyz );
	float gearcoord = - 0.0015 * vs.FSG.z;
	float hdiff = sumdifflen( SM.r0 * SM.rn, FORCE_EVAL( vs.localr_base - SM.r0 * SM.rn ) + vs.localr_diff ) - FORCE_EVAL( PD.radius - SM.r0 ) - localterrain.w;
	float clearance = hdiff * dot( normalize( vs.localr ), N ) + dot( dr, N ) + gearcoord;
	float dotvN = dot( tentative_localv, N );
	float error_in_r = 8. * FRACT_1_16777216 * length( vs.localr );
	float error_in_v = 8. * FRACT_1_16777216 * length( tentative_localv );

	if( dotvN < -error_in_v && clearance < error_in_r - dt * dotvN )
	{
		result = true;

		// handle friction, drive and steering
		vec3 T = reject( vs.localB[0], N );
		if( dot( T, T ) >= FRACT_1_16777216 )
		{
			T = normalize(T);
			vec3 B = normalize( cross( T, N ) );
			float dotvT = dot( tentative_localv, T );
			float dotvB = dot( tentative_localv, B );
			float dotomegaN = dot( vs.localomega, N );
			float cT = vs.FSG.z >= .25 ? 0.90 : 0.60;
			const float cB = 0.60; // TODO: config
			const float comega = 600.; // TODO: config
			const float cnb = 15.; // TODO: config
			const float invturnradius = 140.; // TODO: config
			const float maxspeed = 0.036; // TODO: config

			float steer = invturnradius * clamp( vs.EAR.z, -1., 1. ) * dotvT;
			float maxdvup = dt * ( dotvT < 0. ? 0.045 : min( 0.045, 0.0004 / abs( dotvT ) ) );
			float maxdvdn = dt * ( dotvT < 0. ? min( 0.045, 0.0004 / abs( dotvT ) ) : 0.045 );
			float drive =
				vs.FSG.z < .25 ? 0. :
				vs.modes.z != VS_ENG_DRV || vi.gearbrake > 0. ?
					sign( dotvT ) * max( 0., abs( dotvT ) - mix( 0.001 * dt, -cT * dotvN, vi.gearbrake ) ) :
					clamp( vs.throttle * maxspeed, ( dotvT ) - maxdvdn, ( dotvT ) + maxdvup );

			// friction works to reduce slip up to a maximum delta-v budget per frame
			dv -= sign( dotvT - drive ) * min( abs( dotvT - drive ), -cT * dotvN ) * T;
			dv -= sign( dotvB ) * min( abs( dotvB ), -cB * dotvN ) * B;

			float dotvB_new = dot( vs.localv + dv, B );
			float domegatarget = dotomegaN - steer + cnb * dotvB_new;
			domega -= sign( domegatarget ) * min( abs( domegatarget ), -comega * dotvN ) * N;
		}

		// force vehicle to contact position
		float u = -clearance / dotvN;
		if( error_in_v > 0. )
			dr += u * tentative_localv;

		// eliminate normal velocity component
		dv -= dotvN * N;

		// advance to end of frame using new v
		dr += ( dt - u ) * ( vs.localv + dv );

		// add spring and damping to align upwards (wheel springs)
		float spring = min( 2. / dt, dt > 0. ? 1000. * max( 0., -dotvN / dt ) : 0. ); // TODO: config
		domega -= dt * spring * cross( vs.localB[2], N );
		domega -= dt * spring * cross( cross( N, vs.localomega ), N ) * .2;
	}

	return result;
}

void vs_pace_beginframe( inout VehicleState vs, bool localphysics )
{
	if( localphysics )
	{
		vec3 d = FORCE_EVAL( vs.localr - vs.localr_base );
		if( dot( d, d ) >= 1. )
		{
			vs.localr_diff -= d;
			vs.localr_base = vs.localr;
		}
	}
}

void vs_pace_halfstep( inout VehicleState vs, VehicleInputs vi,
					   float dt, bool localphysics, bool pausemode )
{
	vs_pace_FSG( vs, dt );
	vs_pace_canopy( vs, dt );
	vs_pace_throttle( vs, vi, dt );
	vs_pace_EAR_and_trim( vs, vi, dt );

	if( localphysics )
	{
		if( !pausemode )
		{
			vs.localr_diff += dt * vs.localv;
			vs.localr = vs.localr_base + vs.localr_diff;
		}
	}
	else
	{
		if( !pausemode )
			vs.orbitr += dt * vs.orbitv;
	}
}

void vs_pace_midframe( inout VehicleState vs, VehicleInputs vi,
					   PlanetState ps, float dt, bool localphysics, bool pausemode )
{
	vec3 dvsum = ZERO, grsum = ZERO;
	float dtsum = 0.;
	if( localphysics )
	{
		vec4 localterrain = trn_sample_baserel( SM, iChannel1, vs.localr_base, vs.localr_diff );
		vec3 localpsomega = vec3( 0, 0, ps.omega );
		vec3 gr_static = calc_gravity( vs.localr );
		vec3 gr_centrifugal = cross( localpsomega, cross( localpsomega, vs.localr ) );
		float min_dt = inversesqrt( 1. + 250. * LE.fe.rho * ( 1. + LE.fe.rho * dot( vs.localv, vs.localv ) ) );
		int n = clamp( int( ceil( dt / min_dt ) ), FDM_MIN_ITER, FDM_MAX_ITER );
		float dt_inner = dt / float(n);
		vec3 dr = ZERO;
		mat3x3 localB = vs.localB;

		for( int i = 0; i < NOUNROLL(n); ++i )
		{
			vec3 gr_coriolis = 2. * cross( localpsomega, vs.localv );
			vec3 gr = gr_static - gr_centrifugal - gr_coriolis;
			if( pausemode )
				gr -= calc_gravity_relief( vs.localr, vs.localv );
			vec3 dv = dt_inner * gr;
			vec3 domega = ZERO;

			vs_pace_RCS( vs, vi, ps, dt_inner, domega, true, pausemode );
			vs_pace_thrust( vs, dt_inner, dv, true );
			vs_pace_flight_dynamics( vs, localterrain, dt_inner, dv, domega, dr );
			if( vs_pace_ground_interaction( vs, vi, localterrain, dt_inner, dv, domega, dr ) )
				vs.info.w = 1.;

			float limit = 1.;
			limit = min( limit,		lensq( dv ) == 0. ? 1. : sqrt( ( FRACT_1_256 + FRACT_1_16 *		lensq( vs.localv ) ) / lensq( dv )	   ) );
			limit = min( limit, lensq( domega ) == 0. ? 1. : sqrt( ( FRACT_1_256 + FRACT_1_16 * lensq( vs.localomega ) ) / lensq( domega ) ) );

			if( 2 * n < FDM_MAX_ITER + i && limit < 1. )
			{
				n += n - i;
				dt_inner /= 2.;
				continue;
			}

			grsum += dt_inner * gr;
			dtsum += dt_inner;
			dvsum += dv * limit - dt_inner * gr;
			vs.localv += dv * limit;
			vs.localomega += domega * limit;
			vs.localB = matrixspin( vs.localB, dt_inner * vs.localomega );
		}

		if( dot( dr, dr ) > 0. )
		{
			vs.localr_diff += dr - dt * vs.localv;
			vs.localr += vs.localr_base + vs.localr_diff;
		}

		if( vs.modes2.x == VS_AERO_FBW )
			vs_pace_fly_by_wire( vs, vi, dtsum, safediv( grsum, dtsum ) );
	}
	else
	{
		vec3 gr = calc_gravity( vs.orbitr );
		if( pausemode )
			gr -= calc_gravity_relief( vs.orbitr, vs.orbitv );
		vec3 dv = ZERO;
		vec3 domega = ZERO;
		vs_pace_RCS( vs, vi, ps, dt, domega, false, pausemode );
		vs_pace_thrust( vs, dt, dv, false );
		vs.orbitv += ( dvsum = dv ) + ( dtsum = dt ) * ( grsum = gr );
		vs.omega += domega;
		vs.B = matrixspin( vs.B, dt * vs.omega );
	}

	vs.acc = safediv( dvsum, dtsum ) * ( localphysics ? vs.localB : vs.B );
}

void vs_pace_endframe( inout VehicleState vs, PlanetState ps, float dt, bool localphysics )
{
	if( localphysics )
	{
		vs.localr = vs.localr_base + vs.localr_diff;
		vs_cvt_local2orbit( vs, ps );
	}
	else
	{
		vs_cvt_orbit2local( vs, ps );
		vs.localr_diff = ZERO;
		vs.localr_base = vs.localr;
	}
	vs_cvt_orbit2global( vs, ps );
}

void vs_pace_frame( inout VehicleState vs, VehicleInputs vi, PlanetState ps, float dt, bool localphysics, bool pausemode )
{
	vs_pace_beginframe( vs, localphysics );
	vs_pace_halfstep( vs, vi, dt / 2., localphysics, pausemode );
	vs_pace_midframe( vs, vi, ps, dt, localphysics, pausemode );
	vs_pace_halfstep( vs, vi, dt / 2., localphysics, pausemode );
	vs_pace_endframe( vs, ps, dt, localphysics );
}

// ----------------------------------------------------------------------------
// MENU
// ----------------------------------------------------------------------------

void check_menu_item( int i, int p )
{
	if( keypress( KEY_0 + ( i + 1 ) % 10 ) == 1. )
	{
		int curr = p + i;
		int next = int( md_load( iChannel0, p + i ).w >> 8 ) & 0xff;
		GS.menustate.x = next == 0 ? 0 : curr;
		GS.menustate.y = next == 0 ? curr : 0;
		GS.menustate.z = GS.menustate.y;
	}
}

void process_menu()
{
	GS.menustate.y = 0;
	if( GS.menustate.x > 0 )
	{
		uvec4 currmenu = md_load( iChannel0, GS.menustate.x );
		int n = int( currmenu.w >> 8 ) & 0xff;
		int p = int( currmenu.w >> 16 ) & 0xff;
	#if WORKAROUND_02_FOR_IF
		for( int i = 0, n = NOUNROLL(10); i < n; ++i )
			if( i < n )
				check_menu_item( i, p );
	#else
		for( int i = 0; i < NOUNROLL(n); ++i )
			check_menu_item( i, p );
	#endif
	}
}

void respond_to_menu()
{
	int item = GS.menustate.y;
	if( item >= MENU_IPAGE_BEGIN && item < MENU_IPAGE_BEGIN + MENU_IPAGE_SIZE )
		bitfield_set( GS.switches, GS_SW_IPAGE_MASK, GS_SW_IPAGE_SHIFT, uint( item - MENU_IPAGE_BEGIN ) );
	else
	if( item >= MENU_HMD_BEGIN && item < MENU_HMD_BEGIN + MENU_HMD_SIZE )
		VS.modes.x = item - MENU_HMD_BEGIN;
	else
	if( item >= MENU_ENG_BEGIN && item < MENU_ENG_BEGIN + MENU_ENG_SIZE )
	{
		if( item - MENU_ENG_BEGIN == int( VS_ENG_NOVA ) )
			mq_push_if_empty( MQ, g_msgindex, uvec4( 0x4e6f7661, 0x20836e6f, 0x7420a900, 13 ) );
		else
			VS.modes.z = item - MENU_ENG_BEGIN, VS.throttle = 0.;
	}
	else
	if( item >= MENU_AERO_BEGIN && item < MENU_AERO_BEGIN + MENU_AERO_SIZE )
	{
		int newmode = item - MENU_AERO_BEGIN;
		if( VS.modes2.x < VS_AERO_FBW && newmode >= VS_AERO_FBW )
			VS.trim = 0.;
		if( VS.modes2.x >= VS_AERO_FBW && newmode < VS_AERO_FBW )
			VS.trim = VS.EAR.x, VS.aerostuff = vec4(0);
		VS.modes2.x = newmode;
	}
	else
	if( item >= MENU_RCS_BEGIN && item < MENU_RCS_BEGIN + MENU_RCS_SIZE )
		VS.modes2.y = item - MENU_RCS_BEGIN;
	else
	if( item >= MENU_MMODE_BEGIN && item < MENU_MMODE_BEGIN + MENU_MMODE_SIZE )
		bitfield_set( GS.switches, GS_SW_MMODE_MASK, GS_SW_MMODE_SHIFT, uint( item - MENU_MMODE_BEGIN ) );
	else
	if( item >= MENU_MPROJ_BEGIN && item < MENU_MPROJ_BEGIN + MENU_MPROJ_SIZE )
		bitfield_set( GS.switches, GS_SW_MPROJ_MASK, GS_SW_MPROJ_SHIFT, uint( item - MENU_MPROJ_BEGIN ) );
	else
	if( item == MENU_SET_WAYPOINT )
		GS.waypoint = GS.mapmarker, GS.mapmarker = ZERO;
	else
	if( item >= MENU_DPAGE_BEGIN && item < MENU_DPAGE_BEGIN + MENU_DPAGE_SIZE )
		bitfield_set( GS.dbg_switches, GS_DBG_DPAGE_MASK, GS_DBG_DPAGE_SHIFT, uint( item - MENU_DPAGE_BEGIN ) );
	else
	if( item >= MENU_DGRAPH_BEGIN && item < MENU_DGRAPH_BEGIN + MENU_DGRAPH_SIZE )
		bitfield_set( GS.dbg_switches, GS_DBG_DGRAPH_MASK, GS_DBG_DGRAPH_SHIFT, uint( item - MENU_DGRAPH_BEGIN ) );
	else
	if( item >= MENU_BDISP_BEGIN && item < MENU_BDISP_BEGIN + MENU_BDISP_SIZE )
		bitfield_set( GS.dbg_switches, GS_DBG_BDISP_MASK, GS_DBG_BDISP_SHIFT, uint( item - MENU_BDISP_BEGIN ) );
	else
	if( item >= MENU_BMODE_BEGIN && item < MENU_BMODE_BEGIN + MENU_BMODE_SIZE )
		bitfield_set( GS.dbg_switches, GS_DBG_BMODE_MASK, GS_DBG_BMODE_SHIFT, uint( item - MENU_BMODE_BEGIN ) );
}

// ----------------------------------------------------------------------------
// ACHIEVEMENT DETECTOR
// ----------------------------------------------------------------------------

void ad_pace( inout AchieveDetect ad, inout MsgQueue msg, int msgindex, VehicleState vs,
			  vec4 localterrain, float dt )
{
	bool contact = bool( vs.info.w );
	switch( ad.LT_state )
	{
	case AD_LT_INIT:
		ad.LT_state = contact ? AD_LT_LANDED : AD_LT_AIRBORNE;
		ad.LT_timer = 0.;
		ad.LT_localv = ZERO;
		break;
	case AD_LT_LANDED:
		if( !contact )
		{
			ad.LT_timer -= dt;
			if( ad.LT_timer < -2. )
			{
				ad.LT_state = AD_LT_AIRBORNE;
				ad.LT_timer = 0.;
				ad.LT_localv = vs.localv;
				mq_push_if_empty( msg, msgindex, uvec4( 0x41697262, 0x6f726e65, 0, 8 ) );
			}
		}
		else
			ad.LT_timer = 0.;
		break;
	case AD_LT_AIRBORNE:
		ad.LT_timer -= dt;
		if( ad.LT_timer < -5. && contact )
		{
			vec3 N = localterrain.xyz;
			vec3 T = normalize( reject( vs.localB[0], N ) );
			vec3 B = normalize( reject( vs.localB[1], N ) );
			ad.LT_localv = 1000. * ad.LT_localv * mat3( T, B, -N );
			if( abs( ad.LT_localv.x ) < 250. &&
				abs( ad.LT_localv.y ) < 10. &&
				ad.LT_localv.z < 6. &&
				dot( vs.localB[0], N ) < .342 &&
				dot( vs.localB[0], N ) >= -.087 &&
				abs( dot( vs.localB[1], N ) ) < .342 )
			{
				ad.LT_state = vs.FSG.z >= FRACT_63_64 ? AD_LT_TOUCHDOWN : AD_LT_BELLYDOWN;
				ad.LT_timer = 0.;
				mq_push( msg, msgindex, uvec4( 0xaa000000, 0, 0, 1 ) );
			}
			else
			{
				ad.LT_state = AD_LT_CRASH;
				ad.LT_timer = 0.;
				mq_push( msg, msgindex, uvec4( 0x43726173, 0x68000000, 0, 5 ) );
			}
		}
		else
			ad.LT_localv = vs.localv;
		break;
	case AD_LT_TOUCHDOWN:
	case AD_LT_BELLYDOWN:
		if( contact )
		{
			ad.LT_timer += dt;
			if( ad.LT_timer >= 5. )
			{
				bool wasempty = mq_empty( msg );
				mq_push( msg, msgindex, ad.LT_state == AD_LT_TOUCHDOWN ?
					uvec4( 0xab6c616e, 0x64696e67, 0, 8 ) :
					uvec4( 0x42656c6c, 0x79206c61, 0x6e64696e, 0x6700000d ) );
				if( wasempty )
				{
					mq_push( msg, msgindex, uvec4( 0xaa737065, 0x656420f7, 0, 8 ), vec4( ad.LT_localv.x ) );
					mq_push( msg, msgindex, uvec4( 0x44657363, 0x656e7420, 0x72617465, 0x20f6000e ), vec4( ad.LT_localv.z ) );
					if( ad.LT_localv.z >= 4. )
						mq_push( msg, msgindex, uvec4( 0x54686174, 0x20776173, 0x20686172, 0x6400000d ) );
					else
					if( ad.LT_localv.x >= 80. )
						mq_push( msg, msgindex, uvec4( 0x54686174, 0x20776173, 0x20666173, 0x7400000d ) );
					else
					if( ad.LT_localv.z < 2. )
						mq_push( msg, msgindex, uvec4( 0x54686174, 0x20776173, 0x20ac0000, 10 ) );
				}
				ad.LT_state = AD_LT_LANDED;
				ad.LT_timer = 0.;
			}
		}
		else
		{
			ad.LT_timer -= dt;
			if( ad.LT_timer < 0. )
			{
				ad.LT_state = AD_LT_AIRBORNE;
				ad.LT_timer = 0.;
				ad.LT_localv = vs.localv;
			}
		}
		break;
	case AD_LT_CRASH:
		ad.LT_timer += dt;
		if( ad.LT_timer >= 5. )
			ad.LT_state = AD_LT_INIT;
		break;
	}
}

// ----------------------------------------------------------------------------
// MAP MODE
// ----------------------------------------------------------------------------

void enter_map_mode()
{
	bit_set( GS.switches, GS_SW_TRMAP );
	bit_unset( GS.switches, GS_SW_IRCAM );
	GS.mouselook = vec3(
		normalize( -GS.campos.xy ),
		atan( -GS.campos.z, length( GS.campos.xy ) ) );
	GS.camzoom = 16.;
	GS.mapmarker = ZERO;
}

void leave_map_mode()
{
	bit_unset( GS.switches, GS_SW_TRMAP );
	GS.mouselook = UNIT_X;
	GS.camzoom = 1.;
}

void process_map_mode()
{
	if( keypress( KEY_TAB ) == 1. )
		GS.menustate.x = GS.menustate.x != 0 ? 0 : MENU_MAP;

	float zoomspeed = max( keystatepress( KEY_W ), keystatepress( KEY_Z ) ) -
						   keystatepress( KEY_S );
	zoomspeed *= ( keystate( KEY_SHIFT ) > 0. ? .25 : 1. );
	GS.camzoom = clamp( GS.camzoom * exp2pp( dot( DT, vec4( 1, 2, 2, 1 ) / 6. ) * zoomspeed ), 0.5, 6826.66667 * TRN_SCALE );

	if( iMouse.z < 0. && GS.dragstate.xy == -iMouse.zw )
	{
		vec4 marker = gs_map_unproject( GS, iMouse.xy + .5, iResolution.xy );
		if( abs( marker.w ) < 1. )
		{
			marker *= ( PD.radius + texelFetch( iChannel1, ivec2( iMouse.xy ), 0 ).w );
			if( marker.xyz == GS.mapmarker )
				GS.mapmarker = ZERO;
			else
				GS.mapmarker = marker.xyz;
		}
		GS.dragstate.xy = vec2(0);
	}
}

// ----------------------------------------------------------------------------
// CAMERA
// ----------------------------------------------------------------------------

void mouselook()
{
	if( bit_is_unset( GS.switches, GS_SW_TRMAP ) )
	{
		const mat2x2 R = mat2x2( 1, -1, 1, 1 ) * SQRTHALF;
		float C = dot( normalize( VS.localr ), VS.localB[2] );
		float S = dot( normalize( VS.localr ), VS.localB[1] );

		if( keypress( KEY_BACK ) == 1. )
			GS.mouselook = UNIT_X, GS.camzoom = 1.;
		else
		if( keypress( KEY_NUM8 ) == 1. )
			GS.mouselook = UNIT_X;
		else
		if( keypress( KEY_NUM2 ) == 1. )
			GS.mouselook = -UNIT_X;
		else
		if( keypress( KEY_NUM4 ) == 1. )
			GS.mouselook.xy = R * GS.mouselook.xy, GS.mouselook.z = -.5 * GS.mouselook.y * C * S;
		else
		if( keypress( KEY_NUM6 ) == 1. )
			GS.mouselook.xy = GS.mouselook.xy * R, GS.mouselook.z = -.5 * GS.mouselook.y * C * S;
	}
	else
	if( keypress( KEY_BACK ) == 1. )
		enter_map_mode();

	if( iMouse.z > 0. )
	{
		float zoomres = GS.camzoom * CAM_FOCUS * iResolution.y;
		vec2 dragdelta = 2. * ( iMouse.xy - GS.dragstate ) / zoomres;
		GS.dragstate = iMouse.xy;
		float l = PI / 2. - 0.001 / GS.camzoom;
		float q = cos( GS.mouselook.z ) + 0.25 / GS.camzoom;
		vec2 sc = sincospi( dragdelta.x / ( q * PI ) );
		GS.mouselook.xy = normalize( GS.mouselook.xy * mat2( sc.yx, -sc.x, sc.y ) );
		GS.mouselook.z = clamp( GS.mouselook.z + dragdelta.y, -l, l );
	}
}

void update_camera()
{
	vec2 sc = sincospi( GS.mouselook.z / PI );
	vec3 forward = vec3( GS.mouselook.xy * sc.y, sc.x );
	vec3 right = normalize( cross( UNIT_Z, forward ) );
	vec3 down = cross( forward, right );
	GS.camframe = mat3( forward, right, down );
	if( bit_is_unset( GS.switches, GS_SW_TRMAP ) )
	{
		if( keypress( KEY_R ) == 1. )
			if( keystate( KEY_SHIFT ) == 1. )
				GS.camzoom = GS.camzoom > 8. ? 8. : GS.camzoom > 3. ? 3. : 1.;
			else
				GS.camzoom = GS.camzoom < 3. ? 3. : GS.camzoom < 8. ? 8. : 21.;
		GS.campos_diff = VS.localr_diff + VS.localB * vec3( .001, 0, -.0015 );
		GS.campos = VS.localr_base + GS.campos_diff;
		GS.camframe = VS.localB * GS.camframe;
	}
}

// ----------------------------------------------------------------------------
// GAME UPDATE
// ----------------------------------------------------------------------------

bool pace_camera_transition( float dt )
{
	float u = -expm1( -1.00 * dt * min( 1., .5 * GS.timer ) );
	float v = -expm1( -1.50 * dt * min( 1., .5 * GS.timer ) );
	vec3 a = normalize( mix( GS.camframe[0], normalize( VS.localr - GS.campos ), v ) );
	vec3 b = normalize( mix( normalize( GS.camframe[1] - a * dot( GS.camframe[1], a ) ),
							 normalize( VS.localB[1] - a * dot( VS.localB[1], a ) ), v ) );
	vec3 target = VS.localr - 0.03 * VS.localB[0];
	float alt = mix( length( GS.campos ), length( target ) + .150 * length( target - GS.campos ), u );
	GS.campos = normalize( mix( GS.campos, target, u ) ) * alt;
	GS.camframe = mat3( a, b, cross( a, b ) );
	return dot( normalize( VS.localr - GS.campos ), VS.localB[0] ) >= FRACT_15_16;
	// return distance( GS.campos, VS.localr ) < ( length( target ) - PD.radius < 25. ? 0.0305 : 0.3 );
}

void pace_hud_brightness( float dt )
{
	if( GS.exposure.x > 0. )
	{
		int hudbright = bitfield_get_int( GS.switches, GS_SW_HMD_BRIGHT_MASK, GS_SW_HMD_BRIGHT_SHIFT );
		GS.hudbright += -expm1( -4. * dt ) * ( exp2pp( 2. * float( hudbright ) - 6. ) * sqrt( GS.exposure.x + 0.00005 ) - GS.hudbright );
	}
}

void pace_first_person_mode( float dt )
{
	if( keypress( KEY_T ) == 1. )
		bit_toggle( GS.switches, GS_SW_TRDAR );

	if( keypress( KEY_I ) == 1. )
	{
		bit_toggle( GS.switches, GS_SW_IRCAM );
		/*
		if( ( gs.switches & GS_IRCAM ) != 0u )
			gs.switches &= ~GS_NVISN;
		*/
	}

	if( keypress( KEY_N ) == 1. )
	{
		bit_toggle( GS.switches, GS_SW_NVISN );
		/*
		if( ( gs.switches & GS_NVISN ) != 0u )
			gs.switches &= ~GS_IRCAM;
		*/
	}

	if( keypress( KEY_P ) == 1. )
		bit_toggle( GS.switches, GS_SW_PAUSE );

	if( keypress( KEY_TAB ) == 1. )
		GS.menustate.x = GS.menustate.x != 0 ? 0 : MENU_COMMAND;

	int hudbright = bitfield_get_int( GS.switches, GS_SW_HMD_BRIGHT_MASK, GS_SW_HMD_BRIGHT_SHIFT );
	if( keypress( KEY_H ) == 1. )
		hudbright = clamp( hudbright + ( keystate( KEY_SHIFT ) == 1. ? -1 : 1 ), 0, 3 );
	bitfield_set( GS.switches, GS_SW_HMD_BRIGHT_MASK, GS_SW_HMD_BRIGHT_SHIFT, uint( hudbright ) );
}

void pace_running_state( float dt )
{
	if( abs( iMouse.x - iMouse.z ) < 6. &&
		abs( iMouse.y - iMouse.w ) < 6. && iMouse.z > 0. )
	{
		GS.dragstate = iMouse.xy;
	}

	if( keypress( KEY_M ) == 1. )
		if( bit_is_unset( GS.switches, GS_SW_TRMAP ) )
			enter_map_mode();
		else
			leave_map_mode();

	if( bit_is_unset( GS.switches, GS_SW_TRMAP ) )
		pace_first_person_mode( dt );
	else
		process_map_mode();
}

void pace_vjoy( inout VehicleInputs vi, float urgency, float dt )
{
	// TODO: config
	const float RISE = .25;
	const float HOLD = .0625;
	const float FALL = .5;
	const float SWITCH = 2.;
	vec3 sc = sign( vi.joycommand );
	vec3 ac = abs( vi.joycommand );
	vec3 asc = abs( sc );
	vec3 speed = urgency * mix( mix( vec3( HOLD ), vec3( FALL ), step( .5, GS.vjoy_hold ) ), vec3( RISE ) * ac, asc );
	float speedsw = urgency * SWITCH;
	vec3 ds = max( ZERO, -sc * GS.vjoy );
	vec3 dtsw = min( vec3( dt ), ds / speedsw );
	GS.vjoy += sign( sc - GS.vjoy ) * min( abs( sc - GS.vjoy ), ( dt - dtsw ) * speed + dtsw * speedsw );
	GS.vjoy_hold = ( GS.vjoy_hold + dt ) * ( 1. - asc );
	vi.vjoy_copy = GS.vjoy;
}

void pace_exposure( float dt )
{
	if( GS.stage != GS_STAGE_INIT )
	{
		vec4 sum = vec4(0);

		for( int i = 0; i < NOUNROLL(8); ++i )
			for( int j = 0; j < NOUNROLL(8); ++j )
				sum += texelFetch( iChannel0, ADDR_EXPOSURE.yx + ivec2( i, j ), 0 );

		float mu = safediv( sum.x, sum.z );
		float sigma = sqrt( max( 0., safediv( sum.y, sum.z ) - mu * mu ) );
		float sigmaswitch = mu / ( .25 + mu );
		float level = max( mu, sigmaswitch * sigma );

	  #if WITH_ILLUM_TEST
		GS.exposure.x -= expm1( -dt * ( GS.exposure.x < level ? 4. : 2. ) ) * ( level - GS.exposure.x );
		GS.exposure.y = 0.;
	  #else
		GS.exposure.x -= expm1( -dt * ( GS.exposure.x < level ? 4. : 2. ) ) * ( level - GS.exposure.x );
		GS.exposure.y -= expm1( -dt * ( GS.exposure.y < level ? 1. : .5 ) ) * ( level - GS.exposure.y );
	  #endif
	}
	else
		GS.exposure = vec2(1);
}

mat3x2 make_phases( PlanetState ps, vec4 rn )
{
	vec3 rnxy = length_normalize( rn.xy );
	vec3 psrn = normalize( ps.r );
	vec3 pshn = normalize( cross( ps.r, ps.v ) );
	vec3 pshB = normalize( reject( ps.B[2], pshn ) );
	vec2 Lnxy = normalize( ( -ps.r * ps.B ).xy );
	return mat3x2(
		vec2( rnxy.z, rn.z ),
		vec2( dot( pshB, psrn ), dot( pshB, pshn ) ),
		vec2( dot( perp( Lnxy ), rnxy.xy ), dot( Lnxy, rnxy.xy ) ) );
}

float geopotential_height( float r, float r0 )
	{ return r >= r0 ? ( r - r0 ) * r0 / r : ( r - r0 ) * ( r + r0 ) / ( 2. * r0 ); }

void le_update_atmosphere_and_phases( inout LocalEnv le, PlanetState ps, vec4 rn, float V, float L )
{
	mat3x2 phases = make_phases( ps, rn );
	int lod = 15 - int( log2( PD.radius * PI ) + log2( max( 1.5, rn.w - PD.radius ) ) );
	float terrain = texelFetch( iChannel1, ivec2( ADDR_B_CAMPOS_SAMPLE + lod, 0 ), 0 ).w;
	float att = parabolstep( -.25, .75, terrain );
	le.h = geopotential_height( rn.w, PD.radius );
	float u = parabolstep( 0., 0.0015, -le.h ); // TODO: config wading depth
	bool ocean = PD.ocn.beta50 != vec4(0);
	AtmProfileSample aps = ap_sample( PD.ap, ocean ? max( 0., le.h ) : le.h, phases[0], phases[1], phases[2] * att );
	float a2 = square( dot( normalize( VS.localv ), VS.localB[2] ) );
	float b2 = square( dot( normalize( VS.localv ), VS.localB[1] ) );
	float Rn = ( 1. - a2 - b2 ) * VD.Rn.x + a2 * VD.Rn.y + b2 * VD.Rn.z;
	FluidEnv A = fe_init_from_atm( aps, V, L, max( ZERO, PD.ap.cp + le.h * PD.ap.dcpdh ), safediv( Rn, VD.Sbcm.z ) );
	if( ocean )
	{
		FluidEnv B = fe_init_from_ocn( PD, A.T, V, L, le.h );
		le.fe = fe_mix( A, B, u );
	}
	le_update_phases( le, phases[1], phases[2] );
	float h_s = 500. * dot( VS.localv, VS.localv ) + ( PD.ap.cp.x * le.fe.T + .5 * PD.ap.cp.y * square( le.fe.T ) );
	le.nose.x = fe_heating_rate( le.fe, PD.ap.K, Rn, h_s );
	le.nose.y = fe_equilibrium_temp( le.fe, le.nose.x, .85, .865 ); // TODO: config emissivity and recovery factor (also in buffer B)
}

void pace_game(
	inout FrameContext fr,
	inout VehicleInputs vi )
{
	int localplanetindex = 1;

	PlanetState ps;
	if( GS.stage == GS_STAGE_INIT )
		ps = ps_init( PD );
	else
		ps = ps_load( iChannel0, ps_addr( localplanetindex ) );
	if( GS.stage != GS_STAGE_TRANSITION )
		if( sm_is_valid( SM ) )
			ps_pace( ps, PD.orbit, fr.dt );
	if( GS.stage == GS_STAGE_INIT )
		VS.r = ps.r;

	bool irmode = bit_is_set( GS.switches, GS_SW_IRCAM );
	LE.L = normalize( -VS.r * ps.B );
	LE.sunlight = irselect( COL_SUNLIGHT, irmode ) * square( SCN_DATA_PLANETDIST ) / dot( VS.r, VS.r );
	LE.sundisk = square( SCN_DATA_SUNRADIUS ) / dot( VS.r, VS.r );
	LE.starlight = irselect( COL_STARLIGHT, irmode );
	LE.radius = PD.radius;

	if( bit_is_set( GSX.stateflags, GSX_SF_RESCHANGE ) )
		SM = sm_init();
	if( keypress( KEY_F10 ) == 1. )
		GS.menustate.x = GS.menustate.x < MENU_DEBUG ? MENU_DEBUG : 0;
	process_menu();
	if( GS.menustate.y == MENU_QUIT )
	{
		GS = gs_init();
		MQ = mq_init();
		return;
	}
	respond_to_menu();

	switch( GS.stage )
	{
	case GS_STAGE_INIT:
		{
			vs_realize_startpos( VS, GS, ps, st_load( iChannel0, st_addr(0) ) );
			VS.modes = ivec3(0);
			VS.modes2 = ivec3(0);
			SM = sm_init();
			mq_push( MQ, g_msgindex, uvec4( 0x949cf220, 0x9d9e0000, 0, 6 ), vec4( iDate.x, ZERO ) );
			mq_push( MQ, g_msgindex, uvec4( 0x939f9100, 0, 0, 3 ) );
			GS.stage = GS_STAGE_SELECT_LOCATION;
			GS.timer = 0.;
			GS.datetime.y = 14.;
		}
		break;

	case GS_STAGE_SELECT_LOCATION:
		{
			GS.timer += fr.dt;
			int selected = 0;
				for( int i = 1; i < NOUNROLL(START_DATA_COUNT); ++i )
			{
			#if WORKAROUND_07_KEYPRESS
				if( keypress( KEY_A - 1 + i ) == 1. )
			#else
				if( keypress( KEY_A + i - 1 ) == 1. )
			#endif
					selected = i;
			}
			if( selected > 0 )
			{
				StartData start = st_load( iChannel0, ADDR_START_DATA + ivec2( selected, 0 ) );
				vs_realize_startpos( VS, GS, ps, start );
				if( dot( VS.localr, LE.L ) < 0. || length( VS.orbitr ) < PD.radius - 0.03 )
					bit_set( VS.switches, VS_SW_LIGHT );
				mq_push( MQ, g_msgindex, uvec4( 0xa0746f20, 0x2e2e2e00, 0, 7 ) );
				mq_push( MQ, g_msgindex, start.name );
				GS.stage = GS_STAGE_TRANSITION;
				GS.timer = 0.;
			}
		}
		break;

	case GS_STAGE_TRANSITION:
		{
			GS.timer += fr.dt;
			bool high = length( GS.campos ) >= PD.radius * ( 1. + PD.trn.levels.y * PD.trn.slope.x );
			vec4 rn = length_normalize( VS.localr );
			if( !high && sm_is_valid( SM ) && sm_is_uv_safe( SM, rn.xyz ) )
			{
				VS.localr = rn.xyz * ( trn_sample_n( SM, iChannel1, rn.xyz ).w + 0.0015 + PD.radius );
				vs_commit_local( VS, ps );
			}
			if( pace_camera_transition( fr.dt ) )
			{
				GS.stage = GS_STAGE_RUNNING;
				GS.mouselook = UNIT_X;
			}
		}
		break;

	case GS_STAGE_RUNNING:
		{
			GS.timer += fr.dt;
			pace_running_state( fr.dt );
			mouselook();
			pace_vjoy( vi, VS.modes.z == VS_ENG_DRV ? 2. : 1., fr.dt );
			vs_pace_switches( VS, vi );
			float wp_elev = texelFetch( iChannel1, ivec2( ADDR_B_WAYPOINT_SAMPLE, 0 ), 0 ).w;
			if( wp_elev > 0. )
				GS.waypoint = normalize( GS.waypoint ) * wp_elev;
		}
		break;
	}

	if( GS.stage != GS_STAGE_RUNNING || bit_is_unset( GSX.switches_last, GS_SW_TRMAP ) )
	{
		pace_exposure( fr.dt );
		pace_hud_brightness( fr.dt );
	}

	if( GS.stage != GS_STAGE_TRANSITION )
	{
		VS.info = vec4(0);
		if( sm_is_valid( SM ) )
		{
			bool pausemode = bit_is_set( GS.switches, GS_SW_PAUSE );
			for( int i = 0; i < NOUNROLL(fr.subframe_count); ++i )
			{
				float dt = fr.subframe_dt;
				vec4 rn = length_normalize( VS.localr );
				le_update_atmosphere_and_phases( LE, ps, rn, length( VS.localv ), VD.Sbcm.z );
				vs_pace_frame( VS, vi, ps, dt, bit_is_set( GSX.stateflags, GSX_SF_LOCALPHYSICS ), pausemode );
			}
		}
		update_camera();
	}

	const float solar_day = 1440. * SECONDS_PER_MINUTE;
	GS.datetime.x += fr.dt / solar_day;
	if( GS.datetime.x >= 1. )
	{
		GS.datetime.x--;
		GS.datetime.y++;
		float days_per_year = 61. + ( mod( GS.datetime.z, 3. ) == 0. ? 1. : 0. );
		if( GS.datetime.y >= days_per_year )
		{
			GS.datetime.y -= days_per_year;
			GS.datetime.z++;
		}
	}

	bit_set_to( GS.switches, GS_SW_CHEES, keystate( KEY_F12 ) );

	if( keystate( KEY_SHIFT ) == 1. )
	{
		if( keystate( KEY_1 ) == 1. )
			bitfield_set( GS.switches, GS_SW_SUBSAMPLE_MASK, GS_SW_SUBSAMPLE_SHIFT, 0u );
		else
		if( keystate( KEY_2 ) == 1. )
			bitfield_set( GS.switches, GS_SW_SUBSAMPLE_MASK, GS_SW_SUBSAMPLE_SHIFT, 1u );
		else
		if( keystate( KEY_3 ) == 1. )
			bitfield_set( GS.switches, GS_SW_SUBSAMPLE_MASK, GS_SW_SUBSAMPLE_SHIFT, 2u );
		else
		if( keystate( KEY_4 ) == 1. )
			bitfield_set( GS.switches, GS_SW_SUBSAMPLE_MASK, GS_SW_SUBSAMPLE_SHIFT, 3u );
	}
}

// ----------------------------------------------------------------------------
// AUTO EXPOSURE
// ----------------------------------------------------------------------------

vec4 sample_exposure( ivec2 tileindex )
{
	float M1 = 0.;
	float M2 = 0.;
	float wsum = 0.;

	vec2 tilesize = iResolution.xy / ( 16. * g_subsample );
	vec2 tilebase = vec2( tileindex ) * tilesize;
	int N = min( IMG_EXPOSURE_SAMPLES, int( tilesize.x * tilesize.y ) );
	uint rnd = 7u * uint( iFrame ) + 17u * uint( tileindex.x ) + 11u * uint( tileindex.y );
	bool vrmode = bool( texelFetch( iChannel2, ivec2(0,0), 0 ).w );

	for( int i = 0; i < NOUNROLL(N); ++i )
	{
		vec2 uv = tilebase + tilesize * vec2( rnd *= RNG32, rnd *= RNG32 ) * SHR32;
		float weight = square( ( 1. - square( 4. * uv.x * g_subsample / iResolution.x - 1. ) ) *
							   ( 1. - square( 4. * uv.y * g_subsample / iResolution.y - 1. ) ) );
		if( vrmode )
			uv.x = .5 * uv.x + .5 * float( i < N / 2 );
		vec3 col = texelFetch( iChannel2, ivec2(uv), 1 ).xyz;
		col = clamp( col, 0., IMG_EXPOSURE_MAX );
	  #if WITH_ILLUM_TEST
		float L = dot( col, COL_YWEIGHTS );
	  #else
		float L = hmax( col );
	  #endif
		L = min( L, IMG_EXPOSURE_MAX );
		M1 += L * weight;
		M2 += L * L * weight;
		wsum += weight;
	}

	return vec4( M1, M2, wsum, 0 );
}

// ----------------------------------------------------------------------------
// DEBUG GRAPH DATA
// ----------------------------------------------------------------------------

vec4 dbg_graph_data( float p, bool line )
{
	vec4 result = vec4(0);
	uint dgraph = bitfield_get_uint( GS.dbg_switches, GS_DBG_DGRAPH_MASK, GS_DBG_DGRAPH_SHIFT );
	switch( dgraph )
	{
	case 1u:
	case 2u:
		{
			vec2 sc = sincospi( p / 2. );
			// sc.x = p;
			// sc.y = sqrt( max( 0., 1. - p * p ) );
			vec4 localterrain = trn_sample_n( SM, iChannel1, normalize( VS.localr ) );
			mat3 B = matrixspin( VS.localB, ( line ? .5 : -.5 ) * FRACT_1_4096 * VS.localB[2] );
			vec3 uvw = 1000. * VS.localv * B;
			vec3 pqr = VS.localomega * B;
			vec3 uvwdot = ZERO, pqrdot = ZERO;
			float invtau = 2. * length( uvw ) / ( VD.Sbcm.z );
			vec3 N = normalize( localterrain.xyz );
			float bN = dot( VS.localr_base, N );
			float dN = dot( VS.localr_diff, N );
			float tN = dot( normalize( VS.localr ), N ) * ( localterrain.w + PD.radius );
			float clearance = dN - FORCE_EVAL( tN - bN );
			{
				vec3 velo = uvw;
				vec3 rates = pqr;
				vec3 ctrl = vec3( -VS.EAR.x, VS.EAR.yz );
				vec3 fsg = VS.FSG;
				vec4 gnh = vec4( N * VS.localB, 1000. * clearance );
				float wdelay = VS.wdelay;
				float S = VD.Sbcm.x;
				float V2 = dot( velo, velo );
				if( V2 >= FRACT_2_TO_NEG_48 )
				{
					float V = sqrt( V2 );
					float rcpV = 1. / V;
					mat3x3 W;
					W[0] = velo * rcpV;
					W[2] = safenormalize( cross( W[0], UNIT_Y ) );
					W[1] = cross( W[2], W[0] );
					float v = W[0].y;
					float sin_a = sc.x,				cos_a = sc.y;
					float sin_b = v,				cos_b = sqrt( max( 0., 1. - v * v ) );
					float sin_b_cos_a = sin_b * cos_a;
					float u = cos_a * cos_b;
					float w = sin_a * cos_b;
					float b = VD.Sbcm.y,			c_bar = VD.Sbcm.z;
					float p = sinatan( rates.x * rcpV * b / 2. );
					float q = sinatan( rates.y * rcpV * c_bar / 2. );
					float r = sinatan( rates.z * rcpV * b / 2. );
					float adot = ( velo.z - wdelay ) * rcpV;
					FdCoeffs coeffs = fd_compute_coeffs(
						u, v, w, p, q, r, ctrl, fsg, gnh, gnh.xyz * W,
						sin_a, cos_a, sin_b_cos_a, cos_b, adot );
					switch( dgraph )
					{
					case 1u:
						result.x = ( coeffs.CL - .5 * dFdy( coeffs.CL ) ) / 3.;
						result.y = ( coeffs.CD - .5 * dFdy( coeffs.CD ) ) / 3.;
						result.z = ( coeffs.Cm - .5 * dFdy( coeffs.Cm ) ) / .6;
						break;
					case 2u:
						result.x = dFdy( coeffs.CQ / 3. ) * 4096.;
						result.y = dFdy( coeffs.Cl / .6 ) * 4096.;
						result.z = dFdy( coeffs.Cn / .6 ) * 4096.;
						break;
					}
					result.w = VS.info.z / 90.;
				}
			}
		}
		break;
	}
	return result;
}

// ----------------------------------------------------------------------------
// MAIN
// ----------------------------------------------------------------------------

void store_const_data( inout vec4 fcolor, ivec2 sc )
{
	// store const data

	if( in_addr_range( sc, ADDR_MENU_DATA, 2, MENU_DATA_COUNT ) )
	{
		int index = sc.y - ADDR_MENU_DATA.x;
		fcolor = pack_uvec4( g_menu_data( index ) );
	}
	else
	if( in_st_range( sc ) )
	{
		int index = sc.y - ADDR_START_DATA.x;
		StartData start = g_start_data( index );
		st_store( start, st_addr( index ), sc, fcolor );
	}
	else
	if( in_pd_range( sc ) )
	{
		int index = sc.y - ADDR_PLANET_STATES.x;
		PlanetData data = g_planet_data( index );
		pd_store( data, pd_addr( index ), sc, fcolor );
	}
}

void load_or_init( bool init, bool reschange )
{
	GS = gs_load_or_init( iChannel0, ADDR_GAME_STATE, init );
	GSX = gsx_load_or_init( iChannel0, ADDR_GAME_STATE_AUX, init );
	VS = vs_load_or_init( iChannel0, ADDR_VEHICLE_STATE, init );
	VD = g_vehicle_data( USE_VEHICLE_INDEX );
	SM = sm_load_or_init( iChannel0, ADDR_LOCAL_SM, init );
	LE = le_load_or_init( iChannel0, ADDR_LOCAL_ENV, GS.stage == GS_STAGE_INIT );
	AD = ad_load_or_init( iChannel0, ADDR_ACHIEVEMENTS, init );
	DT = vec4( iTimeDelta, init ? ZERO : memload( iChannel0, ADDR_DTIME, 0 ).xyz );

	if( iFrame == 0 )
		GS.stage == GS_STAGE_STORE;
	else
	{
		PD = pd_load( iChannel0, pd_addr( g_localplanetindex ) );
		GSX.switches_last = GS.switches;
		GSX.stateflags_last = GSX.stateflags;
		bit_set_to( GSX.stateflags, GSX_SF_RESCHANGE, reschange );
		float rmax = PD.radius * ( 1. + PD.trn.levels.y * PD.trn.slope.x );
		float Q = 5. * LE.fe.rho * dot( VS.localv, VS.localv );
		vec4 rn = length_normalize( VS.localr );
		bool localphysics = Q >= FRACT_1_1048576 || rn.w < rmax;
		bit_set_to( GSX.stateflags, GSX_SF_LOCALPHYSICS, localphysics );
		bool locallimit = length( VS.orbitr ) < 12. * PD.am.scale + log( PD.ap.ref.z ) + PD.radius;
		bit_set_to( GSX.stateflags, GSX_SF_LOCALLIMIT, locallimit );
	}
}

void store_state( FrameContext fr, bool init, ivec2 sc, inout vec4 fcolor )
{
	if( in_addr_range( sc, ADDR_RESOLUTION, 2, 2 ) )
	   memstore( iResolution, 0., ADDR_RESOLUTION, 0, sc, fcolor );
	else
	if( in_addr_range( sc, ADDR_DTIME, 2, 2 ) )
	{
	   memstore( DT, ADDR_DTIME, 0, sc, fcolor );
	   vec3 dt_prev = init ? vec3( fr.dt ) : memload( iChannel0, ADDR_DTIME, 1 ).xyz;
	   memstore( vec4( mix( vec3( fr.dt ), dt_prev, exp( -vec3( .5, 1., 2. ) * fr.dt ) ), fr.dt ), ADDR_DTIME, 1, sc, fcolor );
	}
	else
	if( in_addr_range( sc, ADDR_EXPOSURE, 8, 8 ) )
	{
		ivec2 tileindex = sc - ADDR_EXPOSURE.yx;
		fcolor = init ? vec4(0) : sample_exposure( tileindex );
	}
	else
	if( in_ps_sm_ac_range( sc ) )
	{
		int index = sc.y - ADDR_PLANET_STATES.x;
		PlanetData data = pd_load( iChannel0, pd_addr( index ) );
		PlanetData parentdata = pd_load( iChannel0, pd_addr( int( data.parent ) ) );
		PlanetState ps, parent;
		SphereMap sm, smlast;
		if( GS.stage == GS_STAGE_INIT )
		{
			ps = ps_init( data );
			parent = ps_init( parentdata );
			sm = sm_init();
			smlast = sm_init();
		}
		else
		{
			ps = ps_load( iChannel0, ps_addr( index ) );
			parent = ps_load( iChannel0, ps_addr( int( data.parent ) ) );
			sm = sm_load( iChannel0, sm_addr( index ) );
			smlast = sm_load( iChannel0, sm_last_addr( index ) );
		}
		if( GS.stage != GS_STAGE_TRANSITION )
			if( sm_is_valid( SM ) )
			{
				ps_pace( ps, data.orbit, fr.dt );
				if( keypress( KEY_F7 ) != 0. || keypress( KEY_F8 ) != 0. )
				{
					vec2 sc = sincospi( ( keypress( KEY_F7 ) - keypress( KEY_F8 ) ) * SECONDS_PER_MINUTE / ( 30. * data.rot_period ) );
					float t = safediv( sc.x, sc.y );
					ps.B[0] = normalize( ps.B[0] + t * cross( ps.B[2], ps.B[0] ) );
					ps.B[1] = normalize( ps.B[1] + t * cross( ps.B[2], ps.B[0] ) );
				}
			}
		kp_get_vectors( data.orbit, ps.nu, ps.dnudt90, ps.orbitr, ps.orbitv );
		ps.r = ps.orbitr + parent.orbitr;
		ps.v = ps.orbitv + parent.orbitv;
		AtmContext ac = ac_init( data, bit_is_set( GS.switches, GS_SW_IRCAM ) );
		ps_store( ps, ps_addr( index ), sc, fcolor );
		ac_store( ac, ac_addr( index ), sc, fcolor );
		sm_store( sm, sm_addr( index ), sc, fcolor );
		sm_store( smlast, sm_last_addr( index ), sc, fcolor );
	}
	else
	if( in_so_objrange( sc ) || in_addr_range( sc, ADDR_DATASIZES, 1, 1 ) )
	{
		int k = 0;
		float distthres = .25 * GS.camzoom * CAM_FOCUS_INNER * iResolution.x / g_subsample;
		bool notmapmode = ( GS.switches & GS_SW_TRMAP ) == 0u;
		if( iFrame >= 4 )
		for( int i = 0, n = NOUNROLL(SCENE_DATA_COUNT); i < n && k < SCN_MAX_PRIMITIVES; ++i )
		{
			SceneObj obj = so_load( iChannel0, so_dataaddr(i) );
			if( int( obj.tybr.x ) != SCNOBJ_TYPE_INVALID )
			{
				if( notmapmode && distance( GS.campos, obj.r ) >= obj.tybr.y * distthres )
					break;
				if( notmapmode || int( obj.tybr.x ) < SCNOBJ_TYPE_3D )
					k = so_expand_to_primitives( obj, k, GS.timer, ADDR_SCENE_OBJECTS, sc, fcolor );
			}
		}
		memstore( vec4( 0, 0, 0, k ), ADDR_DATASIZES, 0, sc, fcolor );
	}
	else
	if( in_game_update_range( sc ) )
	{
		vs_store( VS, ADDR_VEHICLE_STATE, sc, fcolor );
		le_store( LE, ADDR_LOCAL_ENV, sc, fcolor );

		vec4 localterrain = texelFetch( iChannel1, ivec2( ADDR_B_CAMPOS_SAMPLE, 0 ), 0 );
		if( localterrain.w == 0. )
			localterrain = vec4( normalize( GS.campos ), PD.radius );
		if( GS.stage == GS_STAGE_RUNNING && bit_is_unset( GS.switches, GS_SW_TRMAP ) )
			ad_pace( AD, MQ, g_msgindex, VS, localterrain, fr.dt );
		ad_store( AD, ADDR_ACHIEVEMENTS, sc, fcolor );
		mq_store( MQ, g_msgindex, ADDR_MSG_QUEUE, sc, fcolor );

		sm_store( SM, ADDR_LOCAL_SM_LAST, sc, fcolor );
		vec4 box = trn_box_main( iChannel1 );
		float maxscale = 2. * exp2( TRN_MAX_LEVELS ) / box.z;
	   	float htop = PD.trn.levels.y * PD.trn.slope.x;
		float rd = PD.radius * sqrt( ( 2. + htop ) * htop );
		float rmin = localterrain.w * sm_limit_radius( maxscale, rd );
		if( bit_is_unset( GS.switches, GS_SW_TRMAP ) )
			sm_update_stable( SM, GS.campos, localterrain.w, box, rmin, rd );
		else
			SM = sm_init();
		sm_store( SM, ADDR_LOCAL_SM, sc, fcolor );

		GS.campos_baserel = FORCE_EVAL( FORCE_EVAL( GS.campos - GS.campos_diff ) - SM.rn * SM.r0 ) + GS.campos_diff;
		gs_store( GS, ADDR_GAME_STATE, sc, fcolor );

		{
			bool resolutionchange = bit_is_set( GSX.stateflags_last, GSX_SF_RESCHANGE );
			bool lightdirchange = dot( texelFetch( iChannel1, ivec2( iResolution.y + 4., 2. ), 0 ).xyz, LE.L ) < FRACT_4095_4096;
			bool shadowupdate = iFrame < 4 || ( int( SM.age ) & 127 ) == 0 || resolutionchange || lightdirchange;
			bit_set_to( GSX.stateflags, GSX_SF_SHADOWUPDATE, shadowupdate );
		}

		gsx_store( GSX, ADDR_GAME_STATE_AUX, sc, fcolor );
	}
	else
	if( in_so_datarange( sc ) )
	{
		int index = sc.y - ADDR_SCENE_DATA.x;
		if( iFrame >= 4 && keypress( KEY_F5 ) == 0. )
			so_dynamic_bubblesort( index, GS.campos, sc, fcolor );
		else
		{
			SceneData sd = sd_load( iChannel1, sd_addr_b( index ) );
			SceneObj obj = so_init( sd );
			so_store( obj, so_dataaddr( index ), sc, fcolor );
		}
	}
	else
	if( float( sc.y ) >= iResolution.y - 2. )
	{
		float u = clamp( float( sc.x ) / iResolution.x * 2.25 - 1.125, -1., 1. );
		fcolor = dbg_graph_data( u, ( sc.y & 1 ) == 0 );
	}
}

void mainImage( out vec4 fcolor, in vec2 fcoord )
{
	fcolor = vec4( ZERO, 0 );

#if BUFFER_RUNLEVEL >= 1

	if( ( fcoord.x >= float( ADDR_MAX.y ) || fcoord.y >= float( ADDR_MAX.x ) ) && fcoord.y < iResolution.y - 2. )
		discard;

	// store const data

	ivec2 sc = ivec2( fcoord );
	store_const_data( fcolor, sc );

	// load or init

	bool init = ( iFrame < 2 );
   	bool reschange = init || ( iResolution.xy != memload( iChannel0, ADDR_RESOLUTION, 0 ).xy );
	load_or_init( init, reschange );

	bool locallimit = bit_is_set( GSX.stateflags, GSX_SF_LOCALLIMIT );
	FrameContext fr = fr_init( DT, locallimit );
	VehicleInputs vi = vi_read_inputs( VS );
	g_subsample = gs_get_subsample( GS );
	g_msgindex = ( sc.x - ADDR_MSG_QUEUE.y - 1 ) % TXT_MSG_MAX_PHRASES;
	MQ = mq_load_and_pace_or_init( iChannel0, ADDR_MSG_QUEUE, mq_index( sc ), fr.dt, init );

	// update

	if( GS.stage >= GS_STAGE_INIT && in_game_update_range( sc ) || in_ac_range( sc ) )
		pace_game( fr, vi );

	// store state

	store_state( fr, init, sc, fcolor );

#endif // RUNLEVEL
}
