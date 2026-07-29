// Buffer B (buffer) — Space Glider 2020 VR by scholarius
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
 * Part 3 of 6: Buffer B shader (terrain elevation model)
 * This software comes with no warranty. Use it at your own risk.
 * v 45
 */

GameState GS;
VehicleState VS;
PlanetState PS;
PlanetData PD;
LocalEnv LE;
vec4 DT;
GameStateAux GSX;

float g_subsample = 1.;
vec2 g_textres;

// ----------------------------------------------------------------------------
// ZONE DATA
// ----------------------------------------------------------------------------

ZoneData g_zone_data( int index )
{
	switch( index )
	{
	default: return ZoneData( vec4(  34.342,  117.332, 4.000,  80 ), uvec4(0) );
	case  1: return ZoneData( vec4(  15.882,  167.539, 2.667,  98 ), uvec4(0) );
	case  2: return ZoneData( vec4(  52.529,  115.867, 1.500,  60 ), uvec4(0) );
	case  3: return ZoneData( vec4(  62.133,  150.955, 1.667,  57 ), uvec4(0) );
	case  4: return ZoneData( vec4(  62.468,  152.073,  .100,   0 ), uvec4(0) );
	case  5: return ZoneData( vec4(  29.907,  156.418, 2.667, 191 ), uvec4(0) );
	case  6: return ZoneData( vec4(  28.970,  156.660, 1.000,   0 ), uvec4(0) );
	case  7: return ZoneData( vec4(  28.994,  156.489,  .167,   0 ), uvec4(0) );
	case  8: return ZoneData( vec4(  17.449,  117.416, 1.333,  82 ), uvec4(0) );
	case  9: return ZoneData( vec4(  -5.083,  107.220, 1.333,   3 ), uvec4(0) );
	case 10: return ZoneData( vec4( -51.548, -124.185,  .075,  70 ), uvec4(0) );
	case 11: return ZoneData( vec4( -50.551, -120.686, 1.333,  91 ), uvec4(0) );
	case 12: return ZoneData( vec4( -90.000,    0.000, 2.000,  10 ), uvec4(0) );
	case 13: return ZoneData( vec4(  34.275, -152.626, 1.667,   0 ), uvec4(0) );
	case 14: return ZoneData( vec4( -26.900,   28.262, 1.333,   0 ), uvec4(0) );
	case 15: return ZoneData( vec4(  65.652,   61.718, 1.167,   0 ), uvec4(0) );
	case 16: return ZoneData( vec4(  58.190,  125.935,  .700,-10 ), uvec4(0) );
	};
}

// ----------------------------------------------------------------------------
// SCENE DATA
// ----------------------------------------------------------------------------

SceneData g_scene_data( int index )
{
	switch( index )
	{
	// 00 - Space center west
	case  0: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,   2.200, 0, 0 ), vec4(	  .060, -.430, 0, 102 ),	vec4( 7, 0, 0, .12 ),		vec4( 4382, 65, 15, 5 ) );
	case  1: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,   1.278, 0, 0 ), vec4(	 -.810,	 .230, 0,  31 ),	vec4( 7, 0, 0, .12 ),		vec4( 2739, 65, 12, 4 ) );
	case  2: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.228, 0, 0 ), vec4(		 0,		0, 0,  80 ),	vec4( 6, 0, 0, 0 ),			vec4( 250, 150, 5, 4 ) );
	case  3: return SceneData( vec4( SCNOBJ_TYPE_TOWER,		.028, 0, 0 ), vec4(	 -.305,	 .165, 0,  80 ),	vec4( 2, 0, 0, .015 ),		vec4( .009, .012, .004, .003 ) );
	case  4: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .060, 0, 0 ), vec4(	 -.090,	 .200, 0,  80 ),	vec4( 1, 0, 0, 2 ),			vec4( .040, .060, .006, 0 ) );
	case  5: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .060, 0, 0 ), vec4(	  .075,	 .200, 0,  80 ),	vec4( 1, 0, 0, 2 ),			vec4( .040, .060, .006, 0 ) );
	case  6: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .060, 0, 0 ), vec4(	  .290, -.015, 0,  80 ),	vec4( 1, 0, 0, 2 ),			vec4( .040, .060, .006, 0 ) );

	// 07 - Space center east
	case  7: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,   1.643, 0, 1 ), vec4(		 0,	 .975, 0,  98 ),	vec4( 2, 0, 0, .7 ),		vec4( 3286, 55, 0, 0 ) );
	case  8: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.548, 0, 1 ), vec4(	 -.700,	 .540, 0, 188 ),	vec4( 1, 0, 0, 0 ),			vec4( 639, 350, 0, 0 ) );
	case  9: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.548, 0, 1 ), vec4(	 -.300, -.375, 0,  92 ),	vec4( 2, 0, 0, 0 ),			vec4( 1278, 35, 0, 0 ) );
	case 10: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.146, 0, 1 ), vec4(	  .410, -.300, 0,  92 ),	vec4( 2, 0, 0, 0 ),			vec4( 160, 160, 0, 0 ) );
	case 11: return SceneData( vec4( SCNOBJ_TYPE_TOWER,		.028, 0, 1 ), vec4(	 -.920,	 .150, 0, 278 ),	vec4( 1, 0, 0, .012 ),		vec4( .025, .015, .002, .003 ) );
	case 12: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .050, 0, 1 ), vec4( -1.000, -.200, 0,  92 ),	vec4( 11, 0, 0, 2 ),		vec4( .100, .070, .005, 0 ) );
	case 13: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .040, 0, 1 ), vec4(	 -.890, -.505, 0,  92 ),	vec4( 11, 0, 0, 2 ),		vec4( .030, .035, .040, 0 ) );
	case 14: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .040, 0, 1 ), vec4(	 -.790, -.495, 0,  92 ),	vec4( 11, 0, 0, 2 ),		vec4( .030, .035, .040, 0 ) );

	// 15 - Lucerne
	case 15: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.657, 0, 2 ), vec4(		 0,	 .025, 0,  60 ),	vec4( 2, 0, 0, .7 ),		vec4( 1315, 25, 0, 0 ) );
	case 16: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.110, 0, 2 ), vec4(	 -.015, -.050, 0,  60 ),	vec4( 1, 0, 0, 0 ),			vec4( 120, 50, 0, 0 ) );
	case 17: return SceneData( vec4( SCNOBJ_TYPE_TOWER,		.015, 0, 2 ), vec4(	  .015, -.090, 0, 330 ),	vec4( 2, 0, 0, .006 ),		vec4( .012, .010, .002, .002 ) );
	case 18: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .018, 0, 2 ), vec4(	 -.040, -.090, 0,  60 ),	vec4( 3, 0, 0, 2 ),			vec4( .018, .012, .003, 0 ) );

	// 19 - Bensersiel airfield
	case 19: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.822, 0, 3 ),  vec4(  .349, -.000, 0,  57 ),	vec4( 8, 0, 0,	.7 ),		vec4( 1643, 35, 0, 0 ) );
	case 20: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.228, 0, 3 ),  vec4(  .192,	 .067, 0,  57 ),	vec4( 9, 0, 0, 0 ),			vec4( 250, 50, 50, 10 ) );
	case 21: return SceneData( vec4( SCNOBJ_TYPE_TOWER,		.012, 0, 3 ),  vec4(  .288,	 .111, 0, 147 ),	vec4( 2, 0, 0, .007 ),		vec4( .012, .010, .002, .002 ) );
	case 22: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .012, 0, 3 ),  vec4(  .219,	 .108, 0,  57 ),	vec4( 14, 0, 0, 2 ),		vec4( .012, .012, .004, 0 ) );
	case 23: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .012, 0, 3 ),  vec4(  .253,	 .110, 0,  57 ),	vec4( 14, 0, 0, 2 ),		vec4( .012, .012, .004, 0 ) );

	// 24 - Bensersiel Lighthouse
	case 24: return SceneData( vec4( SCNOBJ_TYPE_LIGHTHOUSE,.015, 0, 4 ),  vec4( ZERO, 120 ),				vec4( 2, 0, 0, .010 ),		vec4( .004, .004, .002, .0025 ) );

	// 25 - Cancun airfield
	case 25: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.548, 0, 5 ),  vec4( -.102,	 .549, 0, 173 ),	vec4( 5, 0, 0, 0 ),			vec4( 1095, 25, 60, 10 ) );
	case 26: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.959, 0, 5 ),  vec4(  .019, -.385, 0, 191 ),	vec4( 4, 0, 0, .6 ),		vec4( 1917, 35, 0, 0 ) );
	case 27: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.548, 0, 5 ),  vec4( -.323,		0, 0, 191 ),	vec4( 1, 0, 0, 0 ),			vec4( 250, 150, 0, 0 ) );
	case 28: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.548, 0, 5 ),  vec4(  .290,		0, 0, 191 ),	vec4( 1, 0, 0, 0 ),			vec4( 250, 150, 0, 0 ) );
	case 29: return SceneData( vec4( SCNOBJ_TYPE_TOWER,		.028, 0, 5 ),  vec4( -.041, -.131, 0, 191 ),	vec4( 2, 0, 0, .010 ),		vec4( .026, .038, .007, .003 ) );
	case 30: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .025, 0, 5 ),  vec4( -.016,		0, 0, 191 ),	vec4( 11, 0, 0, 2 ),		vec4( .095, .025, .010, 0 ) );

	// 31 - Cancun hotels
	case 31: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .025, 0, 6 ),  vec4( -.230, -.105, 0, 0 ),		vec4( 11, 0, 0, 2 ),		vec4( .025, .005, .013, 0 ) );
	case 32: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .025, 0, 6 ),  vec4( -.140, -.060, 0, 0 ),		vec4( 11, 0, 0, 2 ),		vec4( .025, .005, .013, 0 ) );
	case 33: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .025, 0, 6 ),  vec4( -.050, -.015, 0, 0 ),		vec4( 11, 0, 0, 2 ),		vec4( .025, .005, .013, 0 ) );
	case 34: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .025, 0, 6 ),  vec4(  .060, -.030, 0, 0 ),		vec4( 11, 0, 0, 2 ),		vec4( .025, .005, .013, 0 ) );
	case 35: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .025, 0, 6 ),  vec4(  .150,	 .015, 0, 0 ),		vec4( 11, 0, 0, 2 ),		vec4( .025, .005, .013, 0 ) );
	case 36: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .025, 0, 6 ),  vec4(  .240,	 .060, 0, 0 ),		vec4( 11, 0, 0, 2 ),		vec4( .025, .005, .013, 0 ) );

	// 37 - Cancun underwater museum
	case 37: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .002, 0, 7 ),  vec4( -.0255, -.0085, 0,  0 ),	vec4( 15, 0, 0, 1 ),		vec4( .002, ZERO ) );
	case 38: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .002, 0, 7 ),  vec4( -.0230,  .0012, 0,  0 ),	vec4( 16, 0, 0, 1 ),		vec4( .002, ZERO ) );
	case 39: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .002, 0, 7 ),  vec4( -.0218, -.0030, 0,  0 ),	vec4( 17, 0, 0, 1 ),		vec4( .002, ZERO ) );
	case 40: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .001, 0, 7 ),  vec4(  .0020, -.0147, 0, 64 ),	vec4( 28, 0, 0, 2 ),		vec4( .001, .001, .001, 0 ) );
	case 41: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .001, 0, 7 ),  vec4(  .0091, -.0219, 0, 31 ),	vec4( 28, 0, 0, 2 ),		vec4( .001, .001, .001, 0 ) );
	case 42: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .001, 0, 7 ),  vec4(  .0080, -.0177, 0, 22 ),	vec4( 28, 0, 0, 2 ),		vec4( .001, .001, .001, 0 ) );
	case 43: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .003, 0, 7 ),  vec4(  .0245,  .0365, 0,  0 ),	vec4( 18, 0, 0, 3 ),		vec4( .001, .003, 0, 0 ) );
	case 44: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .003, 0, 7 ),  vec4(  .0267,  .0281, 0,  0 ),	vec4( 19, 0, 0, 3 ),		vec4( .001, .003, 0, 0 ) );

	// 45 - Rocky springs
	case 45: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.685, 0, 8 ),  vec4( -.003, -.064, 0,  82 ),	vec4( 3, 0, 0, .6 ),		vec4( 1369, 30, 0, 0 ) );
	case 46: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.110, 0, 8 ),  vec4( -.209, -.002, 0,  82 ),	vec4( 3, 0, 0, 0 ),			vec4( 120, 50, 0, 0 ) );
	case 47: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.183, 0, 8 ),  vec4( -.116,	 .085, 0, 172 ),	vec4( 2, 0, 0, 0 ),			vec4( 220, 15, 0, 0 ) );
	case 48: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.183, 0, 8 ),  vec4(  .017,	 .121, 0,  82 ),	vec4( 1, 0, 0, 0 ),			vec4( 200, 150, 0, 0 ) );
	case 49: return SceneData( vec4( SCNOBJ_TYPE_TOWER,		.015, 0, 8 ),  vec4( -.160,	 .063, 0,  82 ),	vec4( 2, 0, 0, .007 ),		vec4( .012, .016, .0025, .003 ) );
	case 50: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .022, 0, 8 ),  vec4(  .010,	 .222, 0,  82 ),	vec4( 12, 0, 0, 2 ),		vec4( .045, .012, .004, 0 ) );

	// 51 - Lake Victoria
	case 51: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.548, 0, 9 ),  vec4(  .045,	 .050, 0, 3 ),		vec4( 29, 0, 0, 0 ),		vec4( 1095, 25, 70, 10 ) );
	case 52: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .025, 0, 9 ),  vec4( -.160,	 .200, 0, 0 ),		vec4( 20, 0, 0, 3 ),		vec4( .012, .003, 0, 0 ) );
	case 53: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .025, 0, 9 ),  vec4( -.140,	 .240, 0, 0 ),		vec4( 20, 0, 0, 3 ),		vec4( .012, .003, 0, 0 ) );
	case 54: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .025, 0, 9 ),  vec4( -.120,	 .280, 0, 0 ),		vec4( 20, 0, 0, 3 ),		vec4( .012, .003, 0, 0 ) );

	// 55 - Hang gliding summit station
	case 55: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .002, 0, 10 ), vec4(  .00592,.00382, 0, 0 ),	vec4( 25, 0, 0, 3 ),		vec4( .00005, .0015, 0, 0 ) );
	case 56: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .002, 0, 10 ), vec4(  .00408,.00618, 0, 0 ),	vec4( 25, 0, 0, 3 ),		vec4( .00005, .0015, 0, 0 ) );
	case 57: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .002, 0, 10 ), vec4(  .005,	 .005, .0025, 122 ),vec4( 11, 0, 0, 2 ),		vec4( .002, .00002, .0015, 0 ) );

	// 58 - Hang gliding base
	case 58: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.411, 0, 11 ), vec4( -.026, -.147, 0, 91 ),		vec4( 9, 0, 0, 0 ),			vec4( 822, 25, 10, 2 ) );
	case 59: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .006, 0, 11 ), vec4(  .225, -.182, 0, 91 ),		vec4( 26, 0, 0, 2 ),		vec4( .005, .006, .002, 0 ) );

	// 60 - South pole station
	case 60: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.959, 0, 12 ),	vec4( .628, -.362, 0, 150.3 ),	vec4( 27, 0, 0, .2 ),		vec4( 1917, 40, 0, 0 ) );
	case 61: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,   1.004, 0, 12 ),	vec4( .122, -.087, 0, 324.7 ),	vec4( 2, 0, 0, 0 ),			vec4( 30, 50, 2, 2 ) );
	case 62: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .025, 0, 12 ),	vec4( .122, -.087, .0035, 324.7 ), vec4( 11, 0, 0, 2 ),		vec4( .015, .025, .004, 0 ) );
	case 63: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .025, 0, 12 ),	vec4( .112, -.067, 0, -30.3 ),	vec4( 21, 0, 0, 2 ),		vec4( .0005, .0005, .003, 0 ) );
	case 64: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .025, 0, 12 ),	vec4( .112, -.107, 0, -43.5 ),	vec4( 21, 0, 0, 2 ),		vec4( .0005, .0005, .003, 0 ) );
	case 65: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .025, 0, 12 ),	vec4( .132, -.107, 0, -38.6 ),	vec4( 21, 0, 0, 2 ),		vec4( .0005, .0005, .003, 0 ) );
	case 66: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .025, 0, 12 ),	vec4( .132, -.067, 0, -26.5 ),	vec4( 21, 0, 0, 2 ),		vec4( .0005, .0005, .003, 0 ) );
	case 67: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE,	.002, 0, 12 ),	vec4(0),						vec4( 21, 0, 0, 3 ),		vec4( .001, .0002, 0, 0 ) );
	case 68: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE,	.002, 0, 12 ),	vec4(0),						vec4( 21, 0, 0, 3 ),		vec4( .00005, .001, 0, 0 ) );
	case 69: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE,	.002, 0, 12 ),	vec4( 0, 0, .002, 0 ),			vec4( 22, 0, 0, 1 ),		vec4( .0005, ZERO ) );

	// 70 - Gonder scenery
	case 70: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.566, 0, 13 ),  vec4( -.059, -.038, 0, 213 ),	vec4( 3, 0, 0, .5 ),		vec4( 1315, 30, 5, 2 ) );
	case 71: return SceneData( vec4( SCNOBJ_TYPE_TOWER,		.015, 0, 13 ),  vec4(  .067,  .044, 0, 123 ),	vec4( 2, 0, 0, .006 ),		vec4( .012, .010, .002, .002 ) );

	// 72 - Ash island
	case 72: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.630, 0, 14 ),  vec4( ZERO, 28 ),				vec4( 7, 0, 0, 0 ),			vec4( 1260, 25, 80, 10 ) );

	// 73 - Whitelands scenery
	case 73: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.602, 0, 15 ),  vec4( ZERO, 72 ),				vec4( 9, 0, 0, .4 ),		vec4( 1205, 25, 10, 10 ) );

	// 74 - Hang gliding 2
	case 74: return SceneData( vec4( SCNOBJ_TYPE_RUNWAY,	.125, 0, 16 ),	vec4(  .000, .000,  .00, 350 ), vec4( 27, 0, 0, .2 ),		vec4( 500, 100, 0, 0 ) );
	case 75: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .006, 0, 16 ),  vec4( -.070, .160, -.002, 65 ), vec4( 29, 0, 0, 2 ),		vec4( .006, .012, .004, 0 ) );
	case 76: return SceneData( vec4( SCNOBJ_TYPE_PRIMITIVE, .006, 0, 16 ),  vec4( -.080, .145, -.001, 35 ), vec4( 21, 0, 0, 3 ),		vec4( .0002, .015, 0, 0 ) );
	//
	default: return SceneData( vec4( SCNOBJ_TYPE_INVALID, ZERO ), vec4(0), vec4(0), vec4(0) );
	};
}

// ----------------------------------------------------------------------------
// TEXT DATA
// ----------------------------------------------------------------------------

uvec4 g_text_data( int index )
{
	switch( index )
	{
	// 80
	default:   return uvec4(0);
	case 0x81: return uvec4( 0x2e2e2e00, 0, 0, 3 );						// '...'
	case 0x82: return uvec4( 0x636f6d6d, 0x616e6400, 0, 7 );			// 'command'
	case 0x83: return uvec4( 0x656e6769, 0x6e650000, 0, 6 );			// 'engine'
	case 0x84: return uvec4( 0x636f6e74, 0x726f6c00, 0, 7 );			// 'control'
	case 0x85: return uvec4( 0x7468726f, 0x74746c65, 0, 8 );			// 'throttle'
	case 0x86: return uvec4( 0x696e666f, 0, 0, 4 );						// 'info'
	case 0x87: return uvec4( 0x6d6f6465, 0, 0, 4 );						// 'mode'

	// 88
	case 0x88: return uvec4( 0x70616765, 0, 0, 4 );						// 'page'
	case 0x89: return uvec4( 0x72617465, 0, 0, 4 );						// 'rate'
	case 0x8a: return uvec4( 0x64726976, 0x65000000, 0, 5 );			// 'drive'
	case 0x8b: return uvec4( 0x696d7075, 0x6c736500, 0, 7 );			// 'impulse'
	case 0x8c: return uvec4( 0x62756666, 0x65720000, 0, 6 );			// 'buffer'
	case 0x8d: return uvec4( 0x6165726f, 0, 0, 4 );						// 'aero'
	case 0x8e: return uvec4( 0x6d616e75, 0x616c0000, 0, 6 );			// 'manual'
	case 0x8f: return uvec4( 0x73757266, 0x61636500, 0, 7 );			// 'surface'

	// 90
	case 0x90: return uvec4( 0x6f726269, 0x74000000, 0, 5 );			// 'orbit'
	case 0x91: return uvec4( 0x6c6f6361, 0x74696f6e, 0, 8 );			// 'location'
	case 0x92: return uvec4( 0x44656275, 0x67000000, 0, 5 );			// 'debug'
	case 0x93: return uvec4( 0x73656c65, 0x63740000, 0, 6 );			// 'select'
	case 0x94: return uvec4( 0x73706163, 0x65000000, 0, 5 );			// 'space'
	case 0x95: return uvec4( 0x63656e74, 0x65720000, 0, 6 );			// 'center'
	case 0x96: return uvec4( 0x65617374, 0, 0, 4 );						// 'east'
	case 0x97: return uvec4( 0x77657374, 0, 0, 4 );						// 'west'

	// 98
	case 0x98: return uvec4( 0x6e6f7274, 0x68000000, 0, 5 );			// 'north'
	case 0x99: return uvec4( 0x736f7574, 0x68000000, 0, 5 );			// 'south'
	case 0x9a: return uvec4( 0x64697370, 0x6c617900, 0, 7 );			// 'display'
	case 0x9b: return uvec4( 0x73746174, 0x696f6e00, 0, 7 );			// 'station'
	case 0x9c: return uvec4( 0x476c6964, 0x65720000, 0, 6 );			// 'Glider'
	case 0x9d: return uvec4( 0x53686164, 0x6572746f, 0x79000000, 9 );	// 'Shadertoy'
	case 0x9e: return uvec4( 0x45646974, 0x696f6e00, 0, 7 );			// 'Edition'
	case 0x9f: return uvec4( 0x73746172, 0x74000000, 0, 5 );			// 'start'

	// a0
	case 0xa0: return uvec4( 0x7472616e, 0x73666572, 0x696e6700, 8 );	// 'transfer'
	case 0xa1: return uvec4( 0x43616e63, 0xfa6e0000, 0, 6 );			// 'Cancún'
	case 0xa2: return uvec4( 0x756e6465, 0x72776174, 0x65720000, 10 );	// 'underwater'
	case 0xa3: return uvec4( 0x7072696d, 0x69746976, 0x65000000, 9 );	// 'primitive'
	case 0xa4: return uvec4( 0x6368616c, 0x6c656e67, 0x65000000, 9 );	// 'challenge'
	case 0xa5: return uvec4( 0x6f766572, 0x6c617900, 0, 7 );			// 'overlay'
	case 0xa6: return uvec4( 0x7472656e, 0x63680000, 0, 6 );			// 'trench'
	case 0xa7: return uvec4( 0x77617970, 0x6f696e74, 0, 8 );			// 'waypoint'

	// a8
	case 0xa8: return uvec4( 0x69736c61, 0x6e640000, 0, 6 );			// 'island'
	case 0xa9: return uvec4( 0x696d706c, 0x656d656e, 0x74656400, 11 );	// 'implemented'
	case 0xaa: return uvec4( 0x746f7563, 0x68646f77, 0x6e000000, 9 );	// 'touchdown'
	case 0xab: return uvec4( 0x73756363, 0x65737366, 0x756c0000, 10 );	// 'successful'
	case 0xac: return uvec4( 0x65786365, 0x6c6c656e, 0x74000000, 9 );	// 'excellent'
	case 0xad: return uvec4( 0x64657374, 0x696e6174, 0x696f6e00, 11 );	// 'destination'
	case 0xae: return uvec4( 0x726f7461, 0x74696f6e, 0, 8 );			// 'rotation'
	case 0xaf: return uvec4( 0x77697265, 0, 0, 4 );						// 'wire'

	// b0
	case 0xb0: return uvec4( 0x80000000, 0, 0, 1 );						// 'α' (alpha)
	case 0xb1: return uvec4( 0x85000000, 0, 0, 1 );						// 'θ' (theta)
	case 0xb2: return uvec4( 0x8a000000, 0, 0, 1 );						// 'ρ' (rho)
	case 0xb3: return uvec4( 0xb0000000, 0, 0, 1 );						// '°' (degrees)
	case 0xb4: return uvec4( 0xb3000000, 0, 0, 1 );						// '³' (cubed)
	case 0xb5: return uvec4( 0x91680000, 0, 0, 2 );						// 'Δh' (Delta h)
	case 0xb6: return uvec4( 0x87626172, 0, 0, 4 );						// 'µbar' (microbar)
	case 0xb7: return uvec4( 0xb0430000, 0, 0, 2 );						// '°C' (degrees Celsius)

	// b8
	case 0xb8: return uvec4( 0x61697200, 0, 0, 3 );						// 'air'
	case 0xb9: return uvec4( 0x91740000, 0, 0, 2 );						// 'Δt' (Delta t)
	case 0xba: return uvec4( 0xb2000000, 0, 0, 1 );						// '²' (squared)
	}
}

// ----------------------------------------------------------------------------
// VEHICLE INPUT STATE
// ----------------------------------------------------------------------------

const int KEY_CTRL = 17;
const int KEY_ALT = 18;
const int KEY_F1 = 112;
const int KEY_F2 = 113;
const int KEY_F3 = 114;
const int KEY_F4 = 115;
const int KEY_META = 224;

float keystate( int key )
	{ return texelFetch( iChannel3, ivec2( key, 0 ), 0 ).x; }

float keypress( int key )
	{ return texelFetch( iChannel3, ivec2( key, 1 ), 0 ).x; }

float keystatepress( int key )
	{ return max( keystate( key ), keypress( key ) ); }

// ----------------------------------------------------------------------------
// FRAME CONTEXT
// ----------------------------------------------------------------------------

struct FrameContext
{
	float timeaccel;
	int subframe_count;
	float subframe_dt;
	float dt;
};

FrameContext fr_init( vec4 dtime, bool local )
{
	FrameContext result;
	float dt_frame = dot( dtime, vec4( 1, 2, 2, 1 ) / 6. );
	result.timeaccel =
		keystate( KEY_F4 ) > 0. && !local ? 10000. :
		keystate( KEY_F3 ) > 0. ? 1000. :
		keystate( KEY_F2 ) > 0. ? 100. :
		keystate( KEY_F1 ) > 0. ? 10. :
		1.;
	result.subframe_count = min( VS_MAX_ITER, int( ceil( sqrt( result.timeaccel ) ) ) );
	result.subframe_dt = min( local ? VS_MAX_PACE_LOCAL : VS_MAX_PACE, dt_frame * result.timeaccel / float( result.subframe_count ) );
	result.timeaccel = result.timeaccel == 1. ? 1. : float( result.subframe_count ) * safediv( result.subframe_dt, dt_frame );
	result.dt = result.subframe_dt * float( result.subframe_count );
	return result;
}

// ----------------------------------------------------------------------------
// TEXT PROCESSING
// ----------------------------------------------------------------------------

int ipow( int b, int e )
{
	int result = 1;
	if( e >= 0 )
	{
		if( bool( e & 1 ) ) result *= b; b *= b;
		if( bool( e & 2 ) ) result *= b; b *= b;
		if( bool( e & 4 ) ) result *= b; b *= b;
		if( bool( e & 8 ) ) result *= b; b *= b;
	}
	return result;
}

vec4 text_format( int index, vec4 params, uvec4 phrase, vec4 argv )
{
#define CHROUT(p,chr) if( (p) >= 0 && (p) < 4 ) result[p] = chr;
	vec4 result = vec4(0);
	int argc = 0;
	int nchars = 0;
	int nwords = int( phrase.w & TXT_FMT_LENGTH_MASK );
	for( int i = 0, n = nwords; i < n; ++i )
	{
		int pbase = nchars + 5 - 4 * index;
		int code = int( ( phrase[ i >> 2 ] >> ( ( ~i & 3 ) << 3 ) ) & 0xffu );
		if( code >= 0xf0 && argc < 4 )
		{
			// numeric conversion			integers	decimals
			// -------------------------------------------------
			// 0xf0 .. 0xf2:	unsigned	2,3,4		0
			// 0xf3 .. 0xf5:	signed		2,3,4		0
			// 0xf6 .. 0xf8:	signed		2,3,4		1
			// 0xf9 .. 0xfb:	signed		2,3,4		2
			// 0xfc .. 0xfe:	signed		2,3,4		4
			// 0xff:			signed		2			6

			const int base = 10;
			float arg = argv[ argc ];
			int p = ( code - 0xf0 ) % 3 + 2;
			int m = ipow( base, p );
			int q = ( code - 0xf0 ) / 3;
			bool overflow = abs(arg) >= float(m);
			bool signed = q > 0;
			if( signed )
			{
				q = q * q / 4;
				int r = ipow( base, q );
				m *= r;
				arg *= float(r);
				arg += .5 * sign( arg );
			}
			else
				arg *= float( base );
			int a = int( arg );
			int k = pbase;
			int jend = min( TXT_FMT_MAX_LEN - nchars - int( signed ), p + q + int( q > 0 ) );
			bool dout = !signed;
			for( int j = -int( signed ); j < jend; ++j )
			{
				int digit = abs(a) / m;
				float chr = 32.;
				if( j == p )
				{
					chr = 46.;
					dout = true;
				}
				else
				if( !dout && arg < 0. && ( abs(a) * base >= m || j + 2 >= p ) )
				{
					chr = 45.;
					a *= base;
					dout = true;
				}
				else
				if( overflow )
				{
					chr = j >= 0 ? 42. : 32.;
				}
				else
				{
					a -= sign(a) * m * digit;
					a *= base;
					if( digit > 0 || j + 1 >= p )
						dout = true;
					if( dout )
						chr = float( digit ) + 48.;
				}
				CHROUT( k, chr );
				k++;
			}
			nchars += jend + int( signed );
			argc++;
		}
		else
		if( code >= 0x80 )
		{
			// word substitution for bytes 0x80..0xef
			uvec4 word = g_text_data( code );
			int wlen = min( TXT_FMT_MAX_LEN - nchars, int( word.w & 0xffu ) );
			if( pbase >= -wlen && pbase < 4 )
				for( int j = 0; j < wlen; ++j )
				{
					int chr = int( ( word[ j >> 2 ] >> ( ( ~j & 3 ) << 3 ) ) & 0xffu );
					if( i == 0 && j == 0 )
						chr = int( chr ) & ~0x20;
					CHROUT( pbase + j, float( chr ) );
				}
			nchars += wlen;
			if( i + 1 < nwords )
				{ CHROUT( pbase + wlen, 32. ); nchars++; }
		}
		else
		if( code > 0 && nchars < TXT_FMT_MAX_LEN )
		{
			// literal character
			CHROUT( pbase, float( code ) ); nchars++;
		}
	}

	if( index == 0 )
	{
		result = params;
		if( ( phrase.w & TXT_FMT_FLAG_CENTER ) == TXT_FMT_FLAG_CENTER )
			result.x -= abs( result.w ) * float( nchars ) * TXT_FONT_SPACING / 2.;
		else
		if( ( phrase.w & TXT_FMT_FLAG_RIGHT ) == TXT_FMT_FLAG_RIGHT )
			result.x -= abs( result.w ) * float( nchars ) * TXT_FONT_SPACING;
	}
	else
	if( index == 1 )
	{
		result.x = float( nchars );
		if( ( phrase.w & TXT_FMT_FLAG_HUDCLIP ) == TXT_FMT_FLAG_HUDCLIP )
			result.x = -result.x;
	}
	return result;
#undef CHROUT
}

void process_text_message_line( int i, inout int N,
								inout vec4 params, inout uvec4 phrase, inout vec4 argv )
{
	float x = ( 1. + 2. * ( 1. - fract( 1. - memload( iChannel0, ADDR_MSG_QUEUE, 0 ).x ) ) ) * g_textres.x / 2.;
	float y = g_textres.y / 4. + 16.;
	switch( i - N )
	{
	case 0:
		params = vec4( x - g_textres.x, y, 1, 15 );
		phrase = unpack_uvec4( memload( iChannel0, ADDR_MSG_QUEUE, 1 ) );
		phrase.w |= TXT_FMT_FLAG_CENTER | TXT_FMT_FLAG_HUDCLIP;
		argv = memload( iChannel0, ADDR_MSG_QUEUE, 1 + TXT_MSG_MAX_PHRASES );
		break;
	case 1:
		params = vec4( x, y, 1, 15 );
		phrase = unpack_uvec4( memload( iChannel0, ADDR_MSG_QUEUE, 2 ) );
		phrase.w |= TXT_FMT_FLAG_CENTER | TXT_FMT_FLAG_HUDCLIP;
		argv = memload( iChannel0, ADDR_MSG_QUEUE, 2 + TXT_MSG_MAX_PHRASES );
		break;
	}
	N += 2;
}

void process_text_select_location( int i, inout int N,
								   inout vec4 params, inout uvec4 phrase )
{
	int n = START_DATA_COUNT - 1;
	int index = i - N + 1;
	if( index >= 1 && index < n )
	{
		StartData start = st_load( iChannel0, st_addr( index ) );
		vec3 nav = start.iparams.x == 3 && start.iparams.y < SCENE_DATA_COUNT ?
			sd_load( iChannel1, sd_addr_b( start.iparams.y ) ).navb.xyz :
			start.params.xyz * vec3( 1, 1, TRN_SCALE );
		vec3 r = nav2r( vec3( nav.xy, nav.z + PD.radius ) );
		vec3 v = normalize( r - VS.localr ) * GS.camframe;
		v = round( 2047.5 * v + 2047.5 );
		params = vec4( v.x + v.y / 4096., v.z, 1, -12 );
	  #if WORKAROUND_05_UVEC4
		phrase = uvec4( uint( 64 + index ) << 24u, 0u, 0u, 1u );
	  #else
		phrase = uvec4( uint( 64 + index ) << 24u, 0, 0, 1 );
	  #endif
	}
	N += n - 1;
}

void process_text_command_menu( int i, inout int N,
								inout vec4 params, inout uvec4 phrase )
{
	uvec4 currmenu = md_load( iChannel0, GS.menustate.x );
	if( i == N )
		params = vec4( 24, g_textres.y - 24., -1, 15 ),
		phrase = currmenu;
	N++;
	int j = i - N;
	int n = int( currmenu.w >> 8 ) & 0xff;
	int p = int( currmenu.w >> 16 ) & 0xff;
	if( n > 0 && j >= 0 )
	{
		float y = g_textres.y - 48. - float( j % n ) * 16.;
		if( j < n )
			params = vec4( 24, y, 1, 15 ), phrase = uvec4( ( ( ( j + 1 ) % 10 + 48 ) << 24 ) | 0x2e2000, 0, 0, 3 );
		else
		if( j < 2 * n )
			params = vec4( 48, y, 1, 15 ), phrase = md_load( iChannel0, p + j - n );
	}
	N += 2 * n;
}

void process_text_conj_gradients( int i, inout int N,
								  inout vec4 params, inout uvec4 phrase )
{
	vec3 r_ = VS.orbitr;
	vec3 v_ = VS.orbitv;
	float invGM = 1. / PD.GM;

	float r2 = dot( r_, r_ );
	float v2 = dot( v_, v_ );
	float rv = dot( r_, v_ );
	vec3 h_ = cross( r_, v_ );
	float h2 = dot( h_, h_ );
	float h = sqrt( h2 );
	float r = sqrt( r2 );
	float epsilon = v2 * invGM - 1. / r;
	vec3 e_ = epsilon * r_ - rv * invGM * v_;
	float e2 = dot( e_, e_ );
	float e = sqrt( e2 );
	vec3 f_ = e_ + epsilon * r_;

	vec3[5] dirs = vec3[5](
		cross( v_, h_ ) * sign( 1. - e ),
		f_,
		2. * e * ( 1. + e ) * r_ - invGM * h2 * f_,
		2. * e * ( 1. - e ) * r_ + invGM * h2 * f_,
		h_
	);

	if( lensq( dirs[2] ) * 16777216. < r2 * e )
		dirs[2] = abs( rv ) / r2 * r_ + sign( rv ) * e * v_;

	if( lensq( dirs[3] ) * 16777216. < r2 * e )
		dirs[3] = abs( rv ) / r2 * r_ - sign( rv ) * e * v_;

	uvec4[5] phrases = uvec4[5](
		uvec4( 0x00650000, 0, 0, 2 ),		// e
		uvec4( 0x00610000, 0, 0, 2 ),		// a
		uvec4( 0x00417000, 0, 0, 3 ),		// Ap
		uvec4( 0x00506500, 0, 0, 3 ),		// Pe
		uvec4( 0x00680000, 0, 0, 2 )		// h
	);

	vec2 tsc = sincospi( VS.tvec / 180. );
	mat3 tvecrot = VS.B *
		mat3( tsc.y, 0, tsc.x, 0, VS.tvec < 105. ? 1 : -1, 0, -tsc.x, 0, tsc.y ) *
		transpose( VS.B );

	for( int j = 0; j < 5; ++j )
	if( lensq( dirs[j] ) * 1e12 >= r2 && i == N++ )
	{
		vec3 dir = tvecrot * normalize( dirs[j] );
		if( dot( dir, PS.B * GS.camframe[0] ) < 0. )
			dir = -dir;
		bool plus = dot( dir, tvecrot * ( j >= 4 ? h_ : cross( h_, dirs[ j ^ 1 ] ) ) ) >= 0.;
		dir = round( 2047.5 * dir * PS.B * GS.camframe + 2047.5 );
		params = vec4( dir.x + dir.y / 4096., dir.z, 1, -12 );
		phrase = phrases[j];
		phrase[0] |= plus ? 0x2b000000u : 0x2d000000u;
	}
}

#define CW(a,b) ( (a) * (b) * TXT_FONT_SPACING )

void process_text_hmd_numbers( int i, inout int N,
							   inout vec4 params, inout uvec4 phrase, inout vec4 argv )
{
	float left = g_textres.x / 4.;
	float right = g_textres.x * 3. / 4.;
	float y = g_textres.y / 2.;
	vec3 localv = ( VS.localv +
		cross( vec3( 0, 0, VS.modes.x == VS_HMD_ORB ? PS.omega : 0. ), VS.localr ) );
	float spd =	 length( localv );
	if( i == N++ )
	{
		// speed
		params = vec4( left - CW(4.,15.), y, 1, 15 );
		if( spd < 9.9995 )
			phrase = uvec4( 0x202020f5, 0, 0, 4 ), argv.x = 1000. * spd;
		else
		if( spd < 9999.995 )
			phrase = uvec4( 0xfb6b0000, 0, 0, 2 ), argv.x = spd;
		else
			phrase = uvec4( 0xfb4d0000, 0, 0, 2 ), argv.x = spd / 1000.;
	}
	if( bit_is_set( GSX.stateflags, GSX_SF_LOCALPHYSICS ) )
	{
		// mach
		float mach = length( VS.localv ) / LE.fe.a;
		if( mach >= 0.005 && i == N++ )
		{
			params = vec4( left - CW(2.,12.), y - 16., 1, 12 );
			phrase = uvec4( 0x4df90000, 0, 0, 2 );
			argv.x = mach;
		}
		// dyn pressure
		float Q = .5 * ( 1e6 / 1e5 ) * LE.fe.rho * dot( VS.localv, VS.localv );
		if( Q >= 0.005 && i == N++ )
		{
			params = vec4( left -CW(2.,12.), y - 32., 1, 12 );
			phrase = uvec4( 0x51f90000, 0, 0, 2 );
			argv.x = Q;
		}
	}
	if( i == N++ )
	{
		// altitude
		float alt = length( VS.localr ) - PD.radius;
		params = vec4( right - CW(8.,15.), y, 1, 15 );
		if( alt < 9.9995 )
			phrase = uvec4( 0x202020f5, 0, 0, 4 ), argv.x = 1000. * alt;
		else
		if( alt < 9999.995 )
			phrase = uvec4( 0xfb6b0000, 0, 0, 2 ), argv.x = alt;
		else
			phrase = uvec4( 0xfb4d0000, 0, 0, 2 ), argv.x = alt / 1000.;
	}
	float vs = dot( localv, normalize( VS.localr ) );
	if( abs( vs ) >= 0.0000005 && i == N++ )
	{
		// vertical speed
		params = vec4( right - CW(8.,12.), y - 15., 1, 12 );
		if( abs( vs ) < 9.9995 )
			phrase = uvec4( abs( vs ) < 0.00995 ? 0x202020f6 : 0x202020f5, 0, 0, 4 ), argv.x = 1000. * vs;
		else
		if( abs( vs ) < 9999.5 )
			phrase = uvec4( 0xfb6b0000, 0, 0, 2 ), argv.x = vs;
		else
			phrase = uvec4( 0xfb4d0000, 0, 0, 2 ), argv.x = vs / 1000.;
	}
	if( i == N++ )
	{
		// heading
		params = vec4( g_textres.x / 2. - CW(1.5,12.), 3. * g_textres.y / 4. - 9., 1, 12 );
		phrase = uvec4( 0xf1000000, 0, 0, 1 );
		argv.x = B2bearing( VS.localr, VS.localB[0] ) + .5;
	}
	if( i == N++ )
	{
		// g-load
		params = vec4( g_textres.x / 2. - CW(3.5,12.), g_textres.y / 4. - 18., 1, 12 );
		phrase = uvec4( 0x47f90000, 0, 0, 2 );
		argv.x = -1000. / FDM_STD_G * VS.acc.z;
	}

	bool trimdisplay =
		max( keystate( KEY_CTRL ), keystate( KEY_META ) ) > 0. && ( VS.modes2.x != VS_AERO_OFF );

	if( trimdisplay && i == N++ )
	{
		// trim state
		argv.x = 100. * VS.trim;
		params = vec4( g_textres.x / 2. - CW(4.5,12.), g_textres.y / 4. - 36., 1, 12 );
		phrase = uvec4( 0x5452494d, abs( argv.x ) < 9.95 ? 0xf6000000 : 0xf4000000, 0, 5 );
	}

	if( i == N++ )
	{
		// nose temperature
		argv.x = LE.nose.y - 273.15;
		params = vec4( g_textres.x / 2. - CW(1.,12.), g_textres.y / 4., 1., 12 );
		phrase = uvec4( 0xf520b700, 0, 0, 3u | TXT_FMT_FLAG_CENTER );
	}
}

void process_text_time_accel( int i, inout int N,
							  inout vec4 params, inout uvec4 phrase, inout vec4 argv, FrameContext fr )
{
	float y = 3. * g_textres.y / 4. + 9.;
	if( bit_is_set( GS.switches, GS_SW_PAUSE ) )
	{
		if( i == N )
			params = vec4( g_textres.x / 2., y, step( .5, fract( iTime ) ), 12 ),
			phrase = uvec4( 0x50415553, 0x45000000, 0, 5u | TXT_FMT_FLAG_CENTER );
		N++;
	}
	else
	if( fr.timeaccel > 1.0625 )
	{
		if( i == N )
			params = vec4( g_textres.x / 2., y, step( .5, fract( iTime ) ), 12 ),
			phrase = uvec4( 0x54494d45, 0x20d7f500, 0, 7u | TXT_FMT_FLAG_CENTER ),
			argv.x = fr.timeaccel;
		N++;
	}
}

void process_text_console( int i, inout int N,
						   inout vec4 params, inout uvec4 phrase, inout vec4 argv )
{
	vec3 FSG_distance = abs( VS.FSG - ONE );
	FSG_distance.x = min( FSG_distance.x, abs( VS.FSG.x - 1./9. ) );
	FSG_distance.x = min( FSG_distance.x, abs( VS.FSG.x - 4./9. ) );

	vec3 FSG_light = max( vec3( .25 ),
						  min( step( FRACT_1_64, VS.FSG ),
							   max( vec3( step( .5, fract( iTime ) ) ),
									1. - step( FRACT_1_64, FSG_distance ) ) ) );

	float canopy_light = max( .25,
							  min( step( FRACT_1_64, VS.canopy ),
								   max( step( .5, fract( iTime ) ),
										1. - step( FRACT_1_64, 1. - VS.canopy ) ) ) );

	const uvec2 aero_modes[] = uvec2[] (
		uvec2( 0x4f464600, 3u | TXT_FMT_FLAG_CENTER ),
		uvec2( 0x4d414e00, 3u | TXT_FMT_FLAG_CENTER ),
		uvec2( 0x46425700, 3u | TXT_FMT_FLAG_CENTER )
	);

	const uvec2 rcs_modes[] = uvec2[] (
		uvec2( 0x4f464600, 3u | TXT_FMT_FLAG_CENTER ),
		uvec2( 0x4d414e00, 3u | TXT_FMT_FLAG_CENTER ),
		uvec2( 0x52415445, 4u | TXT_FMT_FLAG_CENTER ),
		uvec2( 0x4c564c48, 4u | TXT_FMT_FLAG_CENTER )
	);

	const uvec2 thr_modes[] = uvec2[] (
		uvec2( 0x4f464600, 3u | TXT_FMT_FLAG_CENTER ),
		uvec2( 0x4d414e00, 3u | TXT_FMT_FLAG_CENTER )
	);

	const uvec2 eng_modes[] = uvec2[] (
		uvec2( 0x4f464600, 3u | TXT_FMT_FLAG_CENTER ),
		uvec2( 0x44525600, 3u | TXT_FMT_FLAG_CENTER ),
		uvec2( 0x494d5000, 3u | TXT_FMT_FLAG_CENTER ),
		uvec2( 0x4e4f5641, 4u | TXT_FMT_FLAG_CENTER )
	);

#if WORKAROUND_08_UINT2FLOAT
	float tvec_notch = float( bitfield_get_uint( VS.switches, VS_SW_TVEC_MASK, VS_SW_TVEC_SHIFT ) );
#else
	float tvec_notch = float( ( VS.switches & VS_TVEC_MASK ) >> VS_TVEC_SHIFT );
#endif
	float tvec_target = vs_tvec_notches( tvec_notch );
	float tvec_distance = abs( VS.tvec - tvec_target );
	float tvec_light = max( step( .5, fract( iTime ) ), 1. - step( 2.5, tvec_distance ) );

	switch( i - N )
	{
	case 0:
		argv.x = 100. * VS.throttle;
	#if WORKAROUND_04_VEC4
		params = vec4( 32., 8., abs( sign( VS.throttle ) ), 12. );
	#else
		params = vec4( 32, 8, abs( sign( VS.throttle ) ), 12 );
	#endif
		phrase = uvec4( abs( argv.x ) < 9.95 ? 0xf6000000 : 0xf4000000, 0, 0, 1 );
		break;
	case 1:
		params = vec4( 96, 8, 1, 12 );
	#if WORKAROUND_05_UVEC4
		phrase = uvec4( 0x13131313u, 0u, 0u, bitfield_get_uint( VS.switches, VS_SW_FLAPS_MASK, VS_SW_FLAPS_SHIFT ) | TXT_FMT_FLAG_RIGHT );
	#else
		phrase = uvec4( 0x13131313, 0, 0, bitfield_get_uint( VS.switches, VS_SW_FLAPS_MASK, VS_SW_FLAPS_SHIFT ) | TXT_FMT_FLAG_RIGHT );
	#endif
		break;
	case 2: params = vec4( 104, 8, FSG_light.x, 15 ); phrase = uvec4( 0x46000000, 0, 0, 1 ); break;
	case 3: params = vec4( 120, 8, FSG_light.y, 15 ); phrase = uvec4( 0x53000000, 0, 0, 1 ); break;
	case 4: params = vec4( 136, 8, FSG_light.z, 15 ); phrase = uvec4( 0x47000000, 0, 0, 1 ); break;
	case 5: params = vec4( 152, 8, bit_is_set( VS.switches, VS_SW_LIGHT ) ? 1. : .25, 15 ); phrase = uvec4( 0x4c000000, 0, 0, 1 ); break;
	case 6: params = vec4( 168, 8, canopy_light, 15 ); phrase = uvec4( 0x43000000, 0, 0, 1 ); break;


	case 7: params = vec4( 200, 8, VS.modes2.x == 0 ? .25 : 1., 12 ); phrase = aero_modes[ clamp( VS.modes2.x, 0, 2 ) ].xxxy; break;
	case 8: params = vec4( 232, 8, VS.modes2.y == 0 ? .25 : 1., 12 ); phrase = rcs_modes[ clamp( VS.modes2.y, 0, 3 ) ].xxxy; break;
	// case 9: params = vec4( 264, 8, VS.modes2.z == 0 ? .25 : 1., 12 ); phrase = thr_modes[ clamp( VS.modes2.z, 0, 1 ) ].xxxy; break;
	case 10: params = vec4( 296, 8, VS.modes.z == 0 ? .25 : 1., 12 ); phrase = eng_modes[ clamp( VS.modes.z, 0, 3 ) ].xxxy; break;
	}
	N += 12;

	if( VS.tvec >= 2.5 && i == N++ )
	{
		argv.x = tvec_target;
		params = vec4( g_textres.x * .5 + 80., 8, 1, 12 );
		phrase = uvec4( tvec_light > 0. ? 0x564543f4 : 0x202020f4, 0, 0, 4 );
	}
}

vec3 fmt_time( int arg )
{
	int hours = arg / 3600;
	int minutes = ( arg - 3600 * hours ) / 60;
	int seconds = arg - 60 * minutes - 3600 * hours;
	return vec3( hours, minutes, seconds );
}

vec2 arc_distance( vec3 a, vec3 b )
{
	vec4 an = length_normalize(a);
	vec4 bn = length_normalize(b);
	vec4 dn = an - bn;
	float arclen = atan( length( reject( dn.xyz, an.xyz ) ), dot( bn.xyz, an.xyz ) );
	return vec2( length( vec2( .5 * ( an.w + bn.w ) * arclen, dn.w ) ), an.w - bn.w );
}

#define INFO1( a, b, c, d, arg ) if( i == N++ ) { phrase = uvec4( (a), (b), (c), (d) ); argv.x = (arg); }
#define INFO2( a, b, c, d, arg ) if( i == N++ ) { phrase = uvec4( (a), (b), (c), (d) ); argv.xy = (arg); }
#define INFO3( a, b, c, d, arg ) if( i == N++ ) { phrase = uvec4( (a), (b), (c), (d) ); argv.xyz = (arg); }

void process_text_info_page( int i, inout int N,
							 inout vec4 params, inout uvec4 phrase, inout vec4 argv, int pageno )
{
	float x = g_textres.x - 128.;
	float y = 64.;
	if( i == N++ )
		params = vec4( x, y, -1, 12 ), phrase = md_load( iChannel0, MENU_IPAGE_BEGIN + pageno );
	if( i < N )
		return;
	y -= 20. + 12. * float( ( i - N ) & 3 );
	params = vec4( x, y, 1, 12 );
	if( pageno == GS_INFO_LOCATION )
	{
		vec4 loc = navb( VS.localr, VS.localB[0] ) - vec4( 0, 0, PD.radius, 0 );
		loc.z = sumdifflen( VS.localr_base, VS.localr_diff ) - FORCE_EVAL( PD.radius - length( VS.localr_base ) );
		INFO1( 0x6c617420, 0xfeb30000, 0, 6, loc.x );
		INFO1( 0x6c6f6e67, 0xfeb30000, 0, 6, loc.y );
		INFO1( 0x616c7420, abs( loc.z ) < 9999.99995 ? 0xfe206b6d : ( loc.z /= 1000., 0xfe204d6d ), 0, 8, loc.z );
		INFO1( 0x68646720, 0xfeb30000, 0, 6, loc.w );
	}
	else
	if( pageno == GS_INFO_WAYPOINT && GS.waypoint != ZERO )
	{
		vec2 arcdist = arc_distance( GS.waypoint, VS.localr );
		float eta = length( arcdist ) / length( VS.localv );
		INFO1( 0x62726720, 0xfeb30000, 0, 6, B2bearing( VS.localr, GS.waypoint - VS.localr ) );
		INFO1( 0x64737420, 0xfe206b6d, 0, 8, arcdist.x );
		INFO1( 0xb520fe20, 0x6b6d0000, 0, 6, arcdist.y );
		if( dot( VS.localv, VS.localv ) >= .25e-6 )
			if( eta < 8640000. )
				{ INFO3( 0x65746120, 0x2020f33a, 0xf03af020, 12, fmt_time( int( floor( eta ) ) ) ) }
			else
				INFO1( 0x65746120, 0xfe206400, 0, 7, eta / 86400. );
	}
	else
	if( pageno == GS_INFO_ORBIT )
	{
		Kepler K = Kepler( 0., 0., 0., 0., 0. );
		float nu = kp_init( K, VS.orbitr, VS.orbitv, PD.GM );
		float ap = K.p / ( 1. - K.e ) - PD.radius;
		float pe = K.p / ( 1. + K.e ) - PD.radius;
		if( K.e < 0.99995 )
			INFO1( 0x41702020, abs( ap ) < 10000. ? 0xfe206b6d : ( ap /= 1000., 0xfe204d6d ), 0, 8, ap );
		INFO1( 0x50652020, abs( pe ) < 10000. ? 0xfe206b6d : ( pe /= 1000., 0xfe204d6d ), 0, 8, pe );
		INFO1( 0x65202020, 0xfe000000, 0, 5, K.e );
		if( K.e >= .00005 )
			INFO1( 0xb12020fe, 0xb3000000, 0, 5, degrees( nu ) );
	}
	else
	if( pageno == GS_INFO_GLIDE )
	{
		/*
		if( bit_is_unset( GSX.stateflags, GSX_SF_LOCALPHYSICS ) )
		{
			vec3 h = cross( VS.orbitr, VS.orbitv );
			vec3 e = cross( VS.orbitv, h ) / PD.GM - normalize( VS.orbitr );
			float e2 = dot( e, e );
			float p = dot( h, h ) / PD.GM;
			float ri = min( PD.radius + 120., length( VS.orbitr ) );
			if( e2 >= 2.5e-9 && p / ( 1. + sqrt(e2) ) < ri )
			{
				float cos_nu = safediv( p - ri, sqrt(e2) * ri );
				vec3 ep =
				   mat2x3( normalize(e), normalize( cross(e,h) ) ) *
				   vec2( cos_nu, sqrt( max( 0., 1. - cos_nu * cos_nu ) ) ) * ri;
				vec2 arcdist = arc_distance( GS.waypoint, ep * PS.B );
				INFO1( 0x64737420, 0xfe206b6d, 0, 8, arcdist.x );
				INFO1( 0xb520fe20, 0x6b6d0000, 0, 6, arcdist.y );
				float v = sqrt( PD.GM * max( 0., 2. / ri - ( 1. - sqrt(e2) ) * ( 1. + sqrt(e2) ) / p ) );
				float vs = 500. * arcdist.y * safediv( v, arcdist.x );
				INFO1( 0x76732020, 0xfe206d2f, 0x73000000, 9, vs );
			}
		}
		else
		//*/
		{
			INFO1( 0x434c2020, 0xfe000000, 0, 5, VS.info.x );
			INFO1( 0x43442020, 0xfe000000, 0, 5, VS.info.y );
			INFO1( 0x4c2f4420, 0xfe000000, 0, 5, safediv( VS.info.x, VS.info.y ) );
			INFO1( 0xb02020fe, 0xb3000000, 0, 5, VS.info.z );
		}
	}
	else
	if( pageno == GS_INFO_CONTROLS )
	{
		INFO1( 0x656c6576, 0xfe000000, 0, 5, VS.EAR.x * 100. );
		INFO1( 0x61696c20, 0xfe000000, 0, 5, VS.EAR.y * 100. );
		INFO1( 0x72756464, 0xfe000000, 0, 5, VS.EAR.z * 100. );
		INFO1( 0x7472696d, 0xfe000000, 0, 5, VS.trim * 100. );
	}
	else
	if( pageno == GS_INFO_AIR_STATIC )
	{
		INFO1( 0x54202020, 0xfe20b700, 0, 7, LE.fe.T - 273.15 );
		if( LE.fe.P < .00003 || LE.fe.rho < .00003 )
		{
			INFO1( 0x50202020, 0xfe20b600, 0, 7, 1000000. * LE.fe.P );
			INFO1( 0xb22020fe, 0x206d672f, 0x6db40000, 10, 1000000. * LE.fe.rho );
		}
		else
		if( LE.fe.P < .03 || LE.fe.rho < .03 )
		{
			INFO1( 0x50202020, 0xfe206d62, 0x61720000, 10, 1000. * LE.fe.P );
			INFO1( 0xb22020fe, 0x20672f6d, 0xb4000000, 9, 1000. * LE.fe.rho );
		}
		else
		{
			INFO1( 0x50202020, 0xfe206261, 0x72000000, 9, LE.fe.P );
			INFO1( 0xb22020fe, 0x206b672f, 0x6db40000, 10, LE.fe.rho );
		}
		INFO1( 0x4b6e2020, 0xfe000000, 0, 5, LE.fe.Kn );
	}
	else
	if( pageno == GS_INFO_AIR_DYNAMIC )
	{
		if( LE.fe.Tt - 273.15 >= 10000. )
			{ INFO1( 0x54742020, 0xfe206b20, 0xb7000000, 9, ( LE.fe.Tt - 273.15 ) / 1000. ); }
		else
			{ INFO1( 0x54742020, 0xfe20b700, 0, 7, LE.fe.Tt - 273.15 ); }
		if( LE.fe.Pt < .00003 )
			{ INFO1( 0x50742020, 0xfe20b600, 0, 7, 1000000. * LE.fe.Pt ); }
		else
		if( LE.fe.Pt < .03 )
			{ INFO1( 0x50742020, 0xfe206d62, 0x61720000, 10, 1000. * LE.fe.Pt ); }
		else
			{ INFO1( 0x50742020, 0xfe206261, 0x72000000, 9, LE.fe.Pt ); }
		if( LE.fe.Re < 30. )
			{ INFO1( 0x52652020, 0xfe206b00, 0, 7, LE.fe.Re ); }
		else
			{ INFO1( 0x52652020, 0xfe204d00, 0, 7, LE.fe.Re / 1000. ); }
		INFO1( 0x4d612020, 0xfe000000, 0, 5, LE.fe.Ma );
	}
	else
	if( pageno == GS_INFO_TEMPERATURE )
	{
		INFO1( 0x54202020, 0xfe20b700, 0, 7, LE.fe.T - 273.15 );
		if( LE.fe.Tt - 273.15 >= 10000. )
			{ INFO1( 0x54742020, 0xfe206b20, 0xb7000000, 9, ( LE.fe.Tt - 273.15 ) / 1000. ); }
		else
			{ INFO1( 0x54742020, 0xfe20b700, 0, 7, LE.fe.Tt - 273.15 ); }
		INFO1( 0x54772020, 0xfe20b700, 0, 7, LE.nose.y - 273.15 );
		INFO1( 0x71646f74, 0xfe206b57, 0x2f6dba00, 11, LE.nose.x * ( 1. - square( square( safediv( LE.nose.y, mix( LE.fe.T, LE.fe.Tt, 0.865 ) ) ) ) ) );
	}
	else
	if( pageno == GS_INFO_TIME )
	{
		float tzone = round( navb( VS.localr, VS.localB[0] ).y / 15. );
		bool dots = fract( GS.datetime.x * 1440. * SECONDS_PER_MINUTE ) < .5;
		INFO2( 0x64617465, 0x2020f22d, 0xf0000000, 9, GS.datetime.zy + 1. );
		INFO3( 0x74696d65, 0x20202020, 0xf03af03a, 0xf000000d,
			fmt_time( int( mod( 86400. * GS.datetime.x, 86400. ) ) ).xyz );
		INFO3( 0x6c6f6361, 0x6c202020, dots ? 0xf03af020 : 0xf020f020,
			( tzone == 0. ? 11 : tzone < 0. ? 0x202df00f : 0x202bf00f ),
			vec3( fmt_time( int( mod( 86400. * GS.datetime.x + 3600. * tzone, 86400. ) ) ).xy, abs( tzone ) ) );
		INFO1( 0xb92020fb, 0x20206d73, 0, 8, 1000. * DT.x );
	}
}

void process_text_debug_info_page( int i, inout int N,
								   inout vec4 params, inout uvec4 phrase, inout vec4 argv,
								   int pageno )
{
	float x = g_textres.x - 240.;
	float y = 64. - 20. - 12. * float( ( i - N ) & 3 );
	if( i == N++ )
		params = vec4( x, y, -1, 12 ), phrase = md_load( iChannel0, MENU_DPAGE_BEGIN + pageno );
	if( i < N )
		return;
}

#undef INFO1
#undef INFO2
#undef INFO3

void process_text_map_markers( int i, inout int N,
							   inout vec4 params, inout uvec4 phrase, inout vec4 argv )
{
	if( i == N )
	{
		params = vec4( g_textres.x / 2. - CW(19.,15.) / 2., g_textres.y / 6., 1, 15 );
		phrase = uvec4( 0x102020fb, 0x206b6d20, 0x20202012, 12 );
		float ls = 2. * g_textres.x / g_textres.y * CW(19.,15.) / g_textres.x * PD.radius / GS.camzoom;
		argv.x = ls;
	}
	N++;
	float x = g_textres.x - 160.;
	float y = g_textres.y - 24.;
	if( GS.waypoint != ZERO )
	{
		vec4 loc = navb( GS.waypoint, ZERO );
		switch( i - N )
		{
		case 0: params = vec4( x, y,	   1, 12 ); phrase = uvec4( 0xa7000000, 0, 0, 1 ); break;
		case 1: params = vec4( x, y - 16., 1, 12 ); phrase = uvec4( 0x6c617420, 0xfeb30000, 0, 6 ); argv.x = loc.x; break;
		case 2: params = vec4( x, y - 32., 1, 12 ); phrase = uvec4( 0x6c6f6e67, 0xfeb30000, 0, 6 ); argv.x = loc.y; break;
		case 3: params = vec4( x, y - 48., 1, 12 ); phrase = uvec4( 0x616c7420, 0xfe206b6d, 0, 8 ), argv.x = loc.z - PD.radius; break;
		}
		N += 4;
		y -= 80.;
	}
	if( GS.mapmarker != ZERO )
	{
		vec4 loc = navb( GS.mapmarker, ZERO );
		switch( i - N )
		{
		case 0: params = vec4( x, y,	   1, 12 ); phrase = uvec4( 0x4d61726b, 0x65720000, 0, 6 ); break;
		case 1: params = vec4( x, y - 16., 1, 12 ); phrase = uvec4( 0x6c617420, 0xfeb30000, 0, 6 ); argv.x = loc.x; break;
		case 2: params = vec4( x, y - 32., 1, 12 ); phrase = uvec4( 0x6c6f6e67, 0xfeb30000, 0, 6 ); argv.x = loc.y; break;
		case 3: params = vec4( x, y - 48., 1, 12 ); phrase = uvec4( 0x616c7420, 0xfe206b6d, 0, 8 ), argv.x = loc.z - PD.radius; break;
		}
		N += 4;
	}
}

vec4 process_text( int index,
				   int offs,
				   FrameContext fr )
{
	int N = 0, i = index;
	vec4 params = vec4(0), argv = vec4(0);
	uvec4 phrase = uvec4(0);

	process_text_message_line( i, N, params, phrase, argv );

	if( GS.stage == GS_STAGE_SELECT_LOCATION && GS.timer >= 3.5 )
		process_text_select_location( i, N, params, phrase );

	if( GS.menustate.x > 0 )
		process_text_command_menu( i, N, params, phrase );

	if( GS.stage == GS_STAGE_RUNNING )
	{
		if( bit_is_unset( GS.switches, GS_SW_TRMAP ) )
		{
			if( VS.modes.x > VS_HMD_OFF )
			{
				process_text_hmd_numbers( i, N, params, phrase, argv );

				if( VS.modes.x >= VS_HMD_ORB )
					process_text_conj_gradients( i, N, params, phrase );
			}

			process_text_time_accel( i, N, params, phrase, argv, fr );
			process_text_console( i, N, params, phrase, argv );

			int infopage = bitfield_get_int( GS.switches, GS_SW_IPAGE_MASK, GS_SW_IPAGE_SHIFT );
			if( infopage > 0 && infopage < MENU_IPAGE_SIZE )
				process_text_info_page( i, N, params, phrase, argv, infopage );
		}
		else
			process_text_map_markers( i, N, params, phrase, argv );
	}

	/*
	// debug numbers
	{
		vec4 debug = vec4(0);

		// Frame Time
		// debug.xyz = vec3( 1000. * iTimeDelta, 1. / iTimeDelta, iFrameRate );

		// Current exposure and dynamic gamma
		// debug.xy = log( GS.exposure ) / LN10;
		// const vec3 VIS_DYNGAMMA_PARAMS = vec3( .9, .7, .2 );
		// debug.zw = VIS_DYNGAMMA_PARAMS.x + VIS_DYNGAMMA_PARAMS.y * pow( GS.exposure.xy, VIS_DYNGAMMA_PARAMS.zz );

		// Investigate Barten exposure law
		// #define barten(x) (pow( (x) + 0.32 * pow( (x), 1./.58 ), .58 ))
		// debug.x = 40000. * pow( exposure.x, 1.43 );
		// debug.y = 100. * pow( exposure.x * exposure.z, 1.43 );
		// debug.z = log2( barten( debug.x ) / barten( debug.x * .0003 ) );
		// debug.w = debug.z / log2( barten( debug.y ) / barten( debug.y * .0003 ) );

		// VS info
		// debug = VS.info;

		// VS acceleration vector in Gs
		// debug.xyz = VS.acc * 1000. / FDM_STD_G;

		// aero control states
		// debug = VS.aerostuff;

		// rcs control states
		// debug.xyz = VS.rcsstuff;

		// Local environment
		// debug = vec4( LE.phases, 1e6 * LE.atm2 );

		// GS Vjoy
		// debug.xyz = GS.vjoy;

		// GS switches
		// debug.x = float( GS.switches & 255u );
		// debug.y = float( ( GS.switches >> 8 ) & 255u );
		// debug.z = float( ( GS.switches >> 16 ) & 255u );

		// Heating rate
		// debug.xy = LE.nose;
		// debug.z = 0.2 * inversesqrt( safediv( LE.fe.T * LE.fe.Pt, LE.fe.Tt * LE.fe.P ) );
		// debug.w = debug.z / ( debug.z + LE.fe.lambda );

		// SM params
		SphereMap SM = sm_load( iChannel0, ADDR_LOCAL_SM );
		debug.x = sm_r( SM );
		debug.y = SM.r0;
		debug.z = SM.e;
		debug.w = PD.radius * sqrt( ( 2. + PD.trn.levels.y * PD.trn.slope.x ) * ( PD.trn.levels.y * PD.trn.slope.x ) );
		// debug.w = debug.z *  / debug.x;
		// debug.x = exp2( TRN_MAX_LEVELS ) * TRN_UV_RANGE * 2. / trn_box_main( iChannel1 ).z;
		// debug.y = SM.e * SM.m; // 1000000. * sm_limit_radius( exp2( TRN_MAX_LEVELS ) * TRN_UV_RANGE * 2. / trn_box_main( iChannel1 ).z ) - 1000000.;
		// debug.z = SM.r0 * pwsinh( 1. / SM.m ) / SM.e;
		// debug.w = SM.age / 10000.;

		// GS and GSX switches
		// debug.x = float( GS.switches ) / 10000.;
		// debug.y = float( GS.switches ^ GSX.switches_last ) / 10000.;
		// debug.z = float( GSX.stateflags ) / 10000.;
		// debug.w = float( GSX.stateflags ^ GSX.stateflags_last ) / 10000.;

		// vec4 dtime = memload( iChannel0, ADDR_DTIME, 0 );
		// debug.x = 1. / dot( dtime, vec4( 1, 2, 2, 1 ) / 6. );
		// debug.y = uintBitsToFloat( ( floatBitsToUint( debug.x ) + 0x00080000u & 0x7ff00000u ) );

		float x = g_textres.x - 240.;
		float y = 64. - 20. - 12. * float( ( i - N ) & 3 );
		if( i >= N && i < N + 4 )
		{
			params = vec4( x, y, 1, 12 );
			switch( i - N )
			{
			case 0: phrase = uvec4( 0xfe000000, 0, 0, 1 ); argv.x = debug.x; break;
			case 1: phrase = uvec4( 0xfe000000, 0, 0, 1 ); argv.x = debug.y; break;
			case 2: phrase = uvec4( 0xfe000000, 0, 0, 1 ); argv.x = debug.z; break;
			case 3: phrase = uvec4( 0xfe000000, 0, 0, 1 ); argv.x = debug.w; break;
			}
		}
		N += 4;
	}
	//*/

	return text_format( offs, params, phrase, argv );
}


// ----------------------------------------------------------------------------
// MAIN
// ----------------------------------------------------------------------------


int get_zone_index( vec3 r )
{
	int k = -1;
	float mind = 1e36;
	vec3 rn = normalize(r);
	for( int i = 0; i < ZONE_DATA_COUNT; ++i )
	{
		vec4 zone = zd_trn_zone( zd_load( iChannel1, zd_addr_b(i) ), PD.radius );
		float d = lensq( zone.xyz - rn );
		if( d < mind )
			mind = d, k = i;
	}
	return k;
}

const int MODE_NONE			= 0;
const int MODE_HEIGHT		= 1;
const int MODE_RADIUS		= 2;
const int MODE_NORMAL		= 4;
const int MODE_ZONEINDEX	= 8;
const int MODE_SCENEDATA	= 16;
const int MODE_AO			= 32;

struct TerrainEvalParams
{
	int mode;
	vec3 r;
	float lod;
	mat2x3 TB;
	float eps;
	vec3 rn;
};

TerrainEvalParams get_trn_eval_params( inout vec4 fcolor, vec2 fcoord )
{
	TerrainEvalParams trneval = TerrainEvalParams( 0, ZERO, 0., mat2x3(0), 0., ZERO );

	ivec2 sc = ivec2( fcoord );
	if( sc.y < 2 )
	{
		// bottom letterbox space
		if( sc.x >= ADDR_B_SCENE_DATA && sc.x < ADDR_B_SCENE_DATA + SCENE_DATA_COUNT * SCENE_DATA_SIZE )
		{
			// scene data
			int index = ( sc.x - ADDR_B_SCENE_DATA ) / SCENE_DATA_SIZE;
			index = clamp( index, 0, SCENE_DATA_COUNT - 1 );
			SceneData sd = g_scene_data( index );
			int locindex = int( sd.tybr.w );
			ZoneData ld = zd_load( iChannel1, zd_addr_b( locindex ) );
			vec3 locr = nav2r( vec3( ld.zone.xy, PD.radius ) );
			mat3 locB = bearing2B( locr, ld.zone.w );
			sd.navb.xy = r2nav( locr + locB[0] * sd.navb.x - locB[1] * sd.navb.y ).xy;
			if( int( sd.tybr.x ) == SCNOBJ_TYPE_RUNWAY )
			{
				sd.tybr.y *= sqrt( INV_G_SCALE );
				sd.paramsB.x *= sqrt( INV_G_SCALE );
			}
			sd_store( sd, ivec2( fcoord.y, ADDR_B_SCENE_DATA + SCENE_DATA_SIZE * index ), sc, fcolor );
			if( sc.x - ADDR_B_SCENE_DATA - SCENE_DATA_SIZE * index == 1 )
			{
				trneval.mode = MODE_SCENEDATA;
				trneval.rn = trneval.r = nav2r( vec3( sd.navb.xy, 1. ) );
				trneval.lod = TRN_MAX_LEVELS;
			}
		}
		else
		if( sc.x >= ADDR_B_ZONE_DATA && sc.x < ADDR_B_ZONE_DATA + ZONE_DATA_COUNT * ZONE_DATA_SIZE )
		{
			// location data
			int index = ( sc.x - ADDR_B_ZONE_DATA ) / ZONE_DATA_SIZE;
			index = clamp( index, 0, ZONE_DATA_COUNT - 1 );
			ZoneData zd = g_zone_data( index );
			zd_store( zd, zd_addr_b( index ), sc, fcolor );
		}
		else
		if( sc.x >= ADDR_B_WAYPOINT_SAMPLE )
		{
			// terrain sample at waypoint (if available)
			if( GS.waypoint != ZERO )
			{
				trneval.mode = MODE_HEIGHT | MODE_RADIUS;
				trneval.rn = normalize( trneval.r = GS.waypoint );
				trneval.lod = TRN_MAX_LEVELS - 2. * float( sc.x - ADDR_B_WAYPOINT_SAMPLE );
			}
			// also the effective text resolution for this frame
			fcolor.xy = g_textres;
		}
		else
		if( sc.x >= ADDR_B_CAMPOS_SAMPLE )
		{
			// terrain sample at camera position
			if( GS.campos != ZERO )
			{
				trneval.mode = MODE_HEIGHT | MODE_RADIUS | MODE_NORMAL;
				trneval.rn = normalize( trneval.r = GS.campos );
				trneval.lod = TRN_MAX_LEVELS - fcoord.x;
				vec3 rn = normalize( GS.campos );
				trneval.TB[0] = normalize( reject( UNIT_Z, rn ) );
				trneval.TB[1] = cross( rn, trneval.TB[0] );
				trneval.eps = .0133 * SCN_SCALE;
			}
		}
	}
	else
	if( fcoord.y >= iResolution.y - 2. )
	{
		// top letterbox space: text processing
		int index = 2 * ( int( fcoord.x ) >> 4 ) + ( int( fcoord.y ) & 1 );
		int offs = int( fcoord.x ) & 15;
		vec4 dtime = memload( iChannel0, ADDR_DTIME, 0 );
		bool locallimit = length( VS.orbitr ) < 12. * PD.am.scale + log( PD.ap.ref.z ) + PD.radius;
		FrameContext fr = fr_init( dtime, locallimit );
		fcolor = process_text( index, offs, fr );
	}
	else
	if( bit_is_set( GS.switches, GS_SW_TRMAP ) )
	{
		// main area: map display
		vec2 c = mix( iResolution.xy / 2., fcoord, g_subsample );
		if( all( lessThan( abs( c - iResolution.xy / 2. ), iResolution.xy / 2. ) ) )
		{
			vec4 r = gs_map_unproject( GS, c, iResolution.xy );
			if( abs( r.w ) < 1. )
			{
				float vrmode = texelFetch( iChannel2, ivec2(0,0), 0 ).w;
			#if WITH_TRN_SURFACE_AA && !WORKAROUND_11_MAP_CRASH
				trneval.mode = MODE_HEIGHT | MODE_NORMAL | MODE_ZONEINDEX;
			#else
				trneval.mode = MODE_HEIGHT | MODE_NORMAL;
			#endif
				trneval.r = PD.radius * ( trneval.rn = r.xyz );
				trneval.lod = log2( iResolution.y * GS.camzoom ) - TRN_LOD_BIAS - 2.5 * vrmode;
				trneval.TB[0] = normalize( reject( UNIT_Z, trneval.rn ) );
				trneval.TB[1] = cross( trneval.rn, trneval.TB[0] );
				trneval.eps = .0133 * SCN_SCALE;
			}
		}
	}
	else
	{
		// main area: terrain buffers
		vec4 mainbox = trn_box_main( iChannel1 );
		vec4 shadowbox = trn_box_shadow( iChannel1 );
		bool insidemain = sm_box_inside( mainbox, fcoord );
		bool insideshadow = sm_box_inside( shadowbox, fcoord );
		if( insidemain || insideshadow )
		{
			SphereMap sm = sm_load( iChannel0, ADDR_LOCAL_SM );
			SphereMap smlast = sm_load( iChannel0, ADDR_LOCAL_SM_LAST );

			if( insidemain )
			{
				// main elevation buffer
				if( sm.age != 0. )
					fcolor = texelFetch( iChannel1, ivec2( fcoord ), 0 );
				else
				{
					vec2 uv = ( fcoord.xy - mainbox.xy ) / mainbox.zw;
					vec4 poslod = sm_uv_inverse_lod( sm, uv );
					if( poslod.w > 0. )
					{
						trneval.mode = MODE_HEIGHT | MODE_NORMAL | MODE_ZONEINDEX;
						trneval.r = poslod.xyz;
						trneval.lod = log2( mainbox.z * poslod.w ) - TRN_LOD_BIAS;
						trneval.TB = sm.TB;
						trneval.eps = max( SCN_SCALE * .0133, 2. * distance( poslod.xyz, GS.campos ) / ( mainbox.z * poslod.w ) );
						trneval.rn = sm.rn;
					}
				}
			}
		#if WITH_TRN_SHADOW
			else
			if( insideshadow )
			{
				// shadow buffer
				vec3 L = LE.L;
				bool shadowupdate = bit_is_set( GSX.stateflags, GSX_SF_SHADOWUPDATE );

				if( !sm_is_valid( smlast ) )
					fcolor = vec4( -SCN_ZFAR, -SCN_ZFAR + 1., 1, 1 );
				else
				if( !shadowupdate )
					fcolor = texelFetch( iChannel1, ivec2( fcoord ), 0 );
				else
				if( fcoord.x < iResolution.y + 6. && fcoord.y < 4. )
					fcolor.xyz = L;
				else
				{
					vec2 uv = ( fcoord.xy - shadowbox.xy ) / shadowbox.zw;
					vec4 poslod = sm_uv_inverse_lod( sm, uv );
					if( poslod.w > 0. )
					{
						vec3 result = ZERO;
						vec3 Z = normalize( poslod.xyz );
						float camheight = length( GS.campos );
						float lod = log2( shadowbox.z * poslod.w ) - TRN_LOD_BIAS;
						float elev = trn_sample_n( smlast, iChannel1, Z ).w;
						vec3 targetpoint = Z * ( elev + PD.radius );
						vec3 T = normalize( reject( L, Z ) );
						float dotLT = dot( L, T );
						float dotLZ = dot( L, Z );
						float sinalpha = sqrt( LE.sundisk );
						result.x = result.y = elev;
						result.z = 1.;
						if( dotLZ < FRACT_15_16 )
						{
							vec2 slopes = ( dotLZ + vec2( 1, -.1 ) * sinalpha ) / dotLT;
							float t = SCN_RAYCAST_SHADOW_TBIAS;
							for( int i = 0, n = SCN_RAYCAST_SHADOW_MAX_ITER; i < n; ++i )
							{
								vec3 x = targetpoint + t * L;
								vec3 rn = normalize(x);
								vec4 tsmpl = trn_sample_n( smlast, iChannel1, rn );
								vec2 f = dot( rn, Z ) - dot( rn, T ) * slopes;
								vec2 umbra = tsmpl.w * f + PD.radius * ( f - vec2(1) );
								float l = max( umbra.x, max( result.x, elev ) );
								float u = max( umbra.y, max( result.y, elev ) );
								float s = min( result.z, safediv( l - umbra.x, u - umbra.x ) );
								result.x = s < 1. ? u - ( u - l ) / ( 1. - s ) : l;
								result.y = u;
								result.z = s;
								t += ( 1. + .25 * dot( tsmpl.xyz, L ) ) * max( t * sinalpha, SCN_RAYCAST_SHADOW_MIN_ADVANCE + t * SCN_RAYCAST_SHADOW_MIN_ADVANCE_SCALE );
								if( t >= SCN_ZFAR || ( dot( L, rn ) >= 0. && tsmpl.w >= PD.radius * PD.trn.levels.y * PD.trn.slope.x ) )
									break;
							}
						}

						// x: min height of umbra
						// y: max height of umbra
						// z: AO
						float D = max( SCN_RAYCAST_SHADOW_HBIAS, SCN_RAYCAST_SHADOW_HSCALE * distance( targetpoint, GS.campos ) );
						fcolor.xy = result.xy - D * vec2( 1. + FRACT_1_64, 1 ) + PD.radius;
						fcolor.z = elev;
						trneval.mode = MODE_AO;
						trneval.rn = trneval.r = Z;
						trneval.lod = lod - TRN_AO_LOD_OFFSET;
					}
				}
			}
		#endif // TRN_SHADOW
		}
	#if WITH_TRN_AUX
		else
		{
			vec4 auxbox = sm_box_aux( iChannel1, float(0) );
			if( sm_box_inside( auxbox, fcoord ) )
			{
				SphereMap ts = sm_load( iChannel0, ADDR_LOCAL_TS );
				bool samplestate_equal = false;
				if( samplestate_equal )
					fcolor = texelFetch( iChannel1, ivec2( fcoord ), 0 );
				else
				{
					vec2 uv = ( fcoord.xy - auxbox.xy ) / auxbox.zw;
					vec4 poslod = sm_uv_inverse_lod( ts, uv );
					if( poslod.w > 0. )
					{
						trneval.mode = MODE_HEIGHT | MODE_NORMAL | MODE_ZONEINDEX;
						trneval.r = poslod.xyz;
						trneval.lod = log2( auxbox.z * poslod.w ) - TRN_LOD_BIAS;
						trneval.TB = ts.TB;
						trneval.eps = max( SCN_SCALE * .0133, 2. * distance( poslod.xyz, GS.campos ) / ( auxbox.z * poslod.w ) );
						trneval.rn = ts.rn;
					}
				}
			}
		}
	#endif // TRN_AUX
	}

	return trneval;
}


void mainImage( out vec4 fcolor, in vec2 fcoord )
{
	fcolor = vec4( ZERO, 0 );

#if BUFFER_RUNLEVEL >= 2

	if( iFrame == 0 )
		return;

	GS = gs_load( iChannel0, ADDR_GAME_STATE );
	VS = vs_load( iChannel0, ADDR_VEHICLE_STATE );
	PS = ps_load( iChannel0, ps_addr(1) );
	PD = pd_load( iChannel0, pd_addr(1) );
	LE = le_load( iChannel0, ADDR_LOCAL_ENV );
	DT = memload( iChannel0, ADDR_DTIME, 1 );
	GSX = gsx_load( iChannel0, ADDR_GAME_STATE_AUX );

	g_subsample	 = gs_get_subsample( GS );

	bool vrmode = bool( texelFetch( iChannel2, ivec2(0,0), 0 ).w );
	g_textres = vrmode ?
		iResolution.xy * inversesqrt( iResolution.y / 150. ) :
		iResolution.xy * inversesqrt( iResolution.y / 450. );

	TerrainEvalParams trneval = get_trn_eval_params( fcolor, fcoord );

#if WITH_TERRAIN
	if( trneval.mode != 0 )
	{
		int zoneindex = get_zone_index( trneval.r );
		vec4 zone = zd_trn_zone( zd_load( iChannel1, zd_addr_b( zoneindex ) ), PD.radius );
		trneval.lod = min( trneval.lod, TRN_MAX_LEVELS );
		float h = trn_elevation( trneval.r, trneval.lod, PD, zone );

		if( ( trneval.mode & MODE_HEIGHT ) != 0 )
			fcolor.w = h;

		if( ( trneval.mode & MODE_RADIUS ) != 0 )
			fcolor.w += PD.radius;

		if( ( trneval.mode & MODE_NORMAL ) != 0 )
		{
			vec2 dhdp = vec2(
		#if WITH_TRN_CENTRAL_DIFF
				trn_elevation( trneval.r + .5 * trneval.eps * trneval.TB[0], trneval.lod, PD, zone ) -
				trn_elevation( trneval.r - .5 * trneval.eps * trneval.TB[0], trneval.lod, PD, zone ),
				trn_elevation( trneval.r + .5 * trneval.eps * trneval.TB[1], trneval.lod, PD, zone ) -
				trn_elevation( trneval.r - .5 * trneval.eps * trneval.TB[1], trneval.lod, PD, zone )
		#else
				trn_elevation( trneval.r + trneval.eps * trneval.TB[0], trneval.lod, PD, zone ) - h,
				trn_elevation( trneval.r + trneval.eps * trneval.TB[1], trneval.lod, PD, zone ) - h
		#endif
			) / trneval.eps;
			fcolor.xyz = normalize( normalize( trneval.r ) - trneval.TB * dhdp );
		}

		if( ( trneval.mode & MODE_ZONEINDEX ) != 0 )
		{
			fcolor.xy = reject_max( fcolor.xyz, trneval.rn ) * trneval.TB;
			fcolor.z = float( zoneindex );
		}

		if( ( trneval.mode & MODE_SCENEDATA ) != 0 )
			fcolor.z += h;

		if( ( trneval.mode & MODE_AO ) != 0 )
		{
			float aoscale = PD.radius * exp2( - TRN_AO_LOD_OFFSET / 2. - trneval.lod );
			fcolor.z = aoscale / ( aoscale + max( 0., h - fcolor.z ) );
		}
	}
#endif // WITH_TERRAIN
#endif // RUNLEVEL
}
