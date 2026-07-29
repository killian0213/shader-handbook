// Buffer D (buffer) — Space Glider 2020 VR by scholarius
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
 * Part 5 of 6: Buffer D shader (main rendering)
 * This software comes with no warranty. Use it at your own risk.
 * v 45
 */

// ----------------------------------------------------------------------------

GameState GS;
VehicleState VS;
LocalEnv LE;
SphereMap SM;
AtmContext AC;
PlanetData PD;

float g_subsample = 1.;
float g_pixelscale = 1.;
vec3 g_ocn_beta50 = vec3(1);
vec3 g_ocn_omega = vec3(1);
bool g_vrmode = false;
mat3 g_vrframe = mat3(0);
vec4 g_vrfocus = vec4(0);
vec3 g_campos_base = ZERO;
RayBaserel g_ray = RayBaserel( ZERO, ZERO, ZERO );
RayBaserel g_ray_jittered = RayBaserel( ZERO, ZERO, ZERO );

uniform vec4 unViewport;
uniform vec3 unCorners[5];

// ----------------------------------------------------------------------------
// MATERIALS
// ----------------------------------------------------------------------------

float phase_curve( float cosphase )
	{ return .85 + .15 * ( 8. + 1. ) * pow( max( 0., .5 - .5 * cosphase ), 8. ); }

vec3 lunar_lambert( vec3 omega, float mu, float mu_0 )
{
	// non-lambertian diffuse shading used for terrain land masses
	// mix Lambert and Lommel-Seeliger based on single scattering albedo omega_0,

	// return omega / ( mu + mu_0 );
	// return omega;

	/*
	vec3 omega_0 = 4. * omega / ( 3. * omega + 1. );
	return omega_0 * ( omega + .25 * ( 1. - omega ) / max( 0.0001, mu + mu_0 ) );
	/*/
	vec3 omega_0 = 244. * omega / ( 184. * omega + 61. );
	return omega_0 * ( ( 1. + sqrt( mu * mu_0 ) ) / 2. * omega + .25 / max( 0.0001, mu + mu_0 ) );
	//*/
}

	// Comparison with Chandrasekhar H functions:

	//		omega			1									0.7									0.2
	//		omega_0			1		1			1				0.9		0.9		0.975				0.5		0.5			0.7
	//
	//		mu + mu_0		V1		V2			exact			V1		V2		exact				V1		V2			exact
	//
	//		0.2				1.00	1.75..1.80	1.81..1.95		1.08	1.60..1.64	1.71..1.83		1.20	1.35..1.36	1.42..1.49
	//		0.5				1.00	1.00..1.13	1.01..1.20		0.85	0.85..0.94	0.88..1.04		0.60	0.60..0.63	0.66..0.73
	//		1.0				1.00	0.75..1.00	0.73..1.02		0.78	0.60..0.78	0.57..0.78		0.40	0.35		0.36..0.43
	//		1.5				1.00	1.02..1.06	0.98..1.01		0.75	0.76..0.79	0.67..0.69		0.33	0.34		0.32
	//		2.0				1.00	1.13		1.05			0.74	0.83		0.64			0.30	0.33		0.26
	//
	//		mu + mu_0
	//
	//		0.2			   -48.7	-7.7					   -59.0   -10.4					   -19.5	-8.7
	//		0.5			   -16.7	-5.8					   -18.2	-9.6					   -17.8   -13.7
	//		1.0				37.0	 2.3						36.8	 5.2						11.1   -18.6
	//		1.5				 2.0	 4.9						11.9	13.4						 3.1	 6.3
	//		2.0				-4.7	 7.6						15.6	29.7						15.3	26.9


float NDFphase( float xi, float a )
{ return 1. / ( ( LN2 + a ) * ( 1. + exp( -a ) - xi ) ); }

float NDF( float xi, float a )
{ return 1. / ( max( SQRTTWO, a - SQRTHALF ) * ( 1. + exp( -a ) - xi ) ); }

float NDFintegral( float xi0, float xi1, float a )
{
	float k0 = 1. + exp( -a ) - xi0;
	float k1 = 1. + exp( -a ) - xi1;
	return ( ( k0 > 0. ? log( k0 ) : -a ) - ( k1 > 0. ? log( k1 ) : -a ) ) / max( SQRTTWO, a - SQRTHALF );
}

float NDFdisk( float xi, float a, float b )
{
	// disk-integrated normal distribution function
	// using the distribution 1/((a-1)*(1+exp(-a)-xi))
	float xi0 = xi - b / 2.;
	float xi1 = xi + b / 2.;
	return ( NDFintegral( max( 0., xi0 ), min( 1., xi1 ), a ) +
		( xi1 >= 1. ? NDFintegral( 2. - xi1, 1., a ) : 0. ) ) / b;
}

struct MaterialData
{
	vec4 omega;
};

MaterialData g_matdata( int index )
{
	switch( index )
	{
	// 0
	default: return MaterialData( vec4(0) );
	case 1: return MaterialData( vec4( .455, .439, .393, .45 ) * .9375 );	// concrete 1
	case 2: return MaterialData( vec4( .367, .349, .326, .43 ) * .9375 );	// concrete 2
	case 3: return MaterialData( vec4( .281, .272, .260, .41 ) * .9375 );	// concrete 3
	case 4: return MaterialData( vec4( .226, .217, .215, .37 ) * .9375 );	// concrete 4
	// 5
	case 5: return MaterialData( vec4( .274, .222, .112, .47 ) );			// sandy grass
	case 6: return MaterialData( vec4( .443, .320, .240, .42 ) );			// sandy concrete
	case 7: return MaterialData( vec4( .369, .258, .145, .35 ) );			// dark sand
	case 8: return MaterialData( vec4( .088, .079, .101, .12 ) );			// asphalt
	case 9: return MaterialData( vec4( .204, .206, .084, .60 ) );			// light grass
	// 10
	case 10: return MaterialData( vec4( .3918, .0616, .0180, .71 ) );		// RAL 3020 traffic red
	case 11: return MaterialData( vec4( .5832, .5931, .5815, .65 ) );		// RAL 7035 light grey
	case 12: return MaterialData( vec4( .1579, .0805, .0469, .29 ) );		// RAL 8024 beige brown
	case 13: return MaterialData( vec4( .8852, .8827, .8532, .77 ) );		// RAL 9016 traffic white
	case 14: return MaterialData( vec4( .0440, .0820, .1473, .56 ) );		// RAL 5000 violet blue
	// 15
	case 15: return MaterialData( vec4( .0069, .0827, .2402, .52 ) );		// RAL 5002 ultramarine blue
	case 16: return MaterialData( vec4( .3600, .0531, .0332, .42 ) );		// RAL 3000 fire red
	case 17: return MaterialData( vec4( .6000, .3245, .0472, .55 ) );		// RAL 1005 honey yellow
	case 18: return MaterialData( vec4( .2414, .3557, .1122, .39 ) );		// RAL 6018 yellow green
	case 19: return MaterialData( vec4( .0838, .2669, .1433, .41 ) );		// RAL 6024 traffic green
	// 20
	case 20: return MaterialData( vec4( .3079, .2515, .1929, .32 ) );		// RAL 7002 olive grey
	case 21: return MaterialData( vec4( .3259, .3259, .3290, .31 ) );		// RAL 7004 signal grey
	case 22: return MaterialData( vec4( .0609, .2021, .2066, .35 ) );		// RAL 5021 water blue
	// 25
	case 25: return MaterialData( vec4( .115, .064, .011, .26 ) );			// dark wood
	case 26: return MaterialData( vec4( .167, .118, .055, .36 ) );			// medium wood
	case 27: return MaterialData( vec4( .775, .755, .735, .25 ) );			// compressed snow
	case 28: return MaterialData( vec4( .357, .243, .168, .43 ) );			// sandstone
	case 29: return MaterialData( vec4( .152, .115, .111, .21 ) );			// muddy grass
	// 30
	case 30: return MaterialData( vec4( .73, .73, .72, .33 ) );
	}
}

// ----------------------------------------------------------------------------
// TERRAIN
// ----------------------------------------------------------------------------

vec4 texturenoise( vec3 r )
{
	vec3 uvw = r / iChannelResolution[3];
	return texture( iChannel3, uvw ) * 2. - 1.;
}

float trn_detailmap( vec3 pos )
{
	return 1. + .10 * texturenoise( pos / .01 ).x +
		.12 * texturenoise( pos / .003 ).x +
		.15 * texturenoise( pos / .001 ).x +
		.17 * texturenoise( pos / .0003 ).x;
}

float trn_blendmask( vec3 pos )
{
	pos *= PD.trn.slope.x;
	return clamp( .40 * texturenoise( pos / 10. ).x +
				  .50 * texturenoise( pos / 3. ).x +
				  .40 * texturenoise( pos / 1. ).x +
				  .30 * texturenoise( pos / 0.3 ).x + .5, 0., 1. );
}

vec3 trn_ripplemap( vec3 pos )
{
	return .20 * texturenoise( pos / .01 ).xyz +
		   .30 * texturenoise( pos / .003 ).xyz +
		   .30 * texturenoise( pos / .001 ).xyz +
		   .20 * texturenoise( pos / .0003 ).xyz;
}

vec4 texturenoiseLod( vec3 r, float lod )
{
	vec3 uvw = r / iChannelResolution[3];
	return textureLod( iChannel3, uvw, lod ) * 2. - 1.;
}

float trn_detailmapLod( vec3 pos, float scale )
{
	float lod = log2( scale / 0.001 );
	return 1. + .05 * texturenoiseLod( pos / .01, lod - 3.322 ).x +
				.07 * texturenoiseLod( pos / .003, lod - 1.585 ).x +
				.09 * texturenoiseLod( pos / .001, lod ).x +
				.11 * texturenoiseLod( pos / .0003, lod + 1.585 ).x;
}

float trn_blendmaskLod( vec3 pos, float scale )
{
	float lod = log2( scale );
	return clamp( .40 * texturenoiseLod( pos / 10., lod - 3.322 ).x +
				  .50 * texturenoiseLod( pos / 3., lod - 1.585 ).x +
				  .40 * texturenoiseLod( pos / 1., lod ).x +
				  .30 * texturenoiseLod( pos / 0.3, lod + 1.585 ).x, -.5, .5 );
}

vec3 trn_ripplemapLod( vec3 pos, float scale )
{
	float lod = log2( scale / 0.001 );
	return .20 * texturenoiseLod( pos / .01, lod - 3.322 ).xyz +
		.30 * texturenoiseLod( pos / .003, lod - 1.585 ).xyz +
		.30 * texturenoiseLod( pos / .001, lod ).xyz +
		.20 * texturenoiseLod( pos / .0003, lod + 1.585 ).xyz;
}

vec3 trn_normalmapLod( vec3 pos, float scale )
{
	float lod = log2( scale / 0.001 );
	return .15 * texturenoiseLod( pos / 0.01, lod - 3.322 ).xyz +
		.35 * texturenoiseLod( pos / 0.003, lod - 1.585 ).xyz +
		.35 * texturenoiseLod( pos / 0.001, lod ).xyz +
		.15 * texturenoiseLod( pos / 0.0003, lod + 1.585 ).xyz;
}

vec3 trn_albedo( vec3 r, float Krwidth, float alt, float slope, vec2 sigmares, float sinlat, const bool detail )
{
	float coslat = sqrt( max( 0., 1. - sinlat * sinlat ) );
	float cos2lat = coslat * coslat * 2. - 1.;
	float cos3lat = cos2lat * coslat * 2. - coslat;
	float cos3lat2 = cos3lat * cos3lat;
	float sin3lat = sqrt( max( 0., 1. - cos3lat * cos3lat ) );

	bool ir = bit_is_set( GS.switches, GS_SW_IRCAM );
	float m1 = detail ? trn_detailmapLod( r, Krwidth ) : 1.;
	float m4 = detail ? trn_detailmapLod( r / 4., Krwidth / 4. ) : 1.;

	const vec2 LEGACYFACTORS = vec2(
		0.48 / TRN_SCALE, // ( 1.8 + 5.2 / TRN_SCALE * 0.3 ) / 7.,
		SCN_SCALE / ( 0.833333333 * TRN_SCALE ) );

	vec4 factors = vec4(
		coslat,
		cos3lat2,
		alt * LEGACYFACTORS.x,
		slope * LEGACYFACTORS.y );

	float Kb = Krwidth * .2511972 / SCN_SCALE;
	float b = trn_blendmaskLod( r * .2511972 / SCN_SCALE, Kb );
	float s = 8.;

	vec3 col = ZERO;

	for( int i = 0; i < 6; ++i )
	{
		TrnLayer tl = tl_load( iChannel0, pd_addr(1) + ivec2( 0, pd_layer_addr(i) ) );
		if( detail )
		{
			TrnLayer tl2 = tl_load( iChannel0, pd_addr(1) + ivec2( 0, pd_layer_addr( int( tl.detail.x ) ) ) );
			tl.color = m1 * mix( tl.color, tl.detail.y * tl2.color, parabolstep( tl.detail.z, tl.detail.w, m4 ) );
		}
		float u = dot( tl.weights, factors ) + tl.offset;
		float c = clamp( .5 + u, tl.lower, tl.upper );
		float v = mix( b, c - .5, s );
		float K = dot( tl.weights.zw, sigmares * LEGACYFACTORS );
		float t = i == 0 ? 1. : saturate( .5 + v / max( 1., 1.48260222 * abs( s * K ) ) );
		col = mix( col, irselect( tl.color, ir ), t );
	}

	if( alt >= 10.3135 * TRN_SCALE )
		col = irselect( vec4( COL_PRIMARYRED, .35 ), ir );;

	return col;
}

// ----------------------------------------------------------------------------
// ATMOSPHERE
// ----------------------------------------------------------------------------

vec4 atm_inscatter_sample( sampler2D ch, vec2 uv, float t )
{
	uv = uv / SCN_ATM_SUBSAMPLE_RATIO;
	uv.x = g_vrmode ? uv.x : min( uv.x, 1. / SCN_ATM_SUBSAMPLE_RATIO - .5001 / float( textureSize( ch, 0 ).x ) );
#if WITH_ATM_BILATERAL_UPSAMPLE
	vec2 tc = vec2( textureSize( ch, 0 ).xy ) * uv;
	vec2 rtc = round( tc );
	ivec2 itc = ivec2( rtc ) - 1;
	vec4 sa = texelFetchOffset( ch, itc, 0, ivec2( 0, 0 ) );
	vec4 sb = texelFetchOffset( ch, itc, 0, ivec2( 1, 0 ) );
	vec4 sc = texelFetchOffset( ch, itc, 0, ivec2( 0, 1 ) );
	vec4 sd = texelFetchOffset( ch, itc, 0, ivec2( 1, 1 ) );
	float wx0 = abs( rtc.x + .5 - tc.x );
	float wx1 = abs( rtc.x - .5 - tc.x );
	float wy0 = abs( rtc.y + .5 - tc.y );
	float wy1 = abs( rtc.y - .5 - tc.y );
	float wta = abs( t - sa.z ) + .25;
	float wtb = abs( t - sb.z ) + .25;
	float wtc = abs( t - sc.z ) + .25;
	float wtd = abs( t - sd.z ) + .25;
	float wa = wx0 * wy0 * wtb * wtc * wtd;
	float wb = wx1 * wy0 * wta * wtc * wtd;
	float wc = wx0 * wy1 * wta * wtb * wtd;
	float wd = wx1 * wy1 * wta * wtb * wtc;
  #if WITH_ATM_PACKHALF2X16
	sa.xz = unpackHalf2x16( floatBitsToUint( sa.x ) ) / ATM_HALF2X16_SCALE;
	sb.xz = unpackHalf2x16( floatBitsToUint( sb.x ) ) / ATM_HALF2X16_SCALE;
	sc.xz = unpackHalf2x16( floatBitsToUint( sc.x ) ) / ATM_HALF2X16_SCALE;
	sd.xz = unpackHalf2x16( floatBitsToUint( sd.x ) ) / ATM_HALF2X16_SCALE;
  #else
	sa.xz = exp2( vec2( floor( sa.x ) / 128., fract( sa.x ) * 32. ) - 24. ) - FRACT_1_16777216;
	sb.xz = exp2( vec2( floor( sb.x ) / 128., fract( sb.x ) * 32. ) - 24. ) - FRACT_1_16777216;
	sc.xz = exp2( vec2( floor( sc.x ) / 128., fract( sc.x ) * 32. ) - 24. ) - FRACT_1_16777216;
 	sd.xz = exp2( vec2( floor( sd.x ) / 128., fract( sd.x ) * 32. ) - 24. ) - FRACT_1_16777216;
  #endif
	return ( sa * wa + sb * wb + sc * wc + sd * wd ) / ( wa + wb + wc + wd + FRACT_1_16777216 );
#else
	return textureLod( ch, uv, 0. );
#endif
}

vec4 atm_reflection_sample( sampler2D ch, vec2 uv )
{
	uv = uv / SCN_ATM_SUBSAMPLE_RATIO;
	uv.x = g_vrmode ? uv.x + .25 : max( uv.x, .5001 / float( textureSize( ch, 0 ).x ) ) + .5;
#if WITH_ATM_BILATERAL_UPSAMPLE
	vec2 tc = vec2( textureSize( ch, 0 ).xy ) * uv;
	vec2 rtc = round( tc );
	ivec2 itc = ivec2( rtc ) - 1;
	vec4 sa = texelFetchOffset( ch, itc, 0, ivec2( 0, 0 ) );
	vec4 sb = texelFetchOffset( ch, itc, 0, ivec2( 1, 0 ) );
	vec4 sc = texelFetchOffset( ch, itc, 0, ivec2( 0, 1 ) );
	vec4 sd = texelFetchOffset( ch, itc, 0, ivec2( 1, 1 ) );
	float wx0 = abs( rtc.x + .5 - tc.x );
	float wx1 = abs( rtc.x - .5 - tc.x );
	float wy0 = abs( rtc.y + .5 - tc.y );
	float wy1 = abs( rtc.y - .5 - tc.y );
	float wa = wx0 * wy0 * float( sa != vec4(0,0,0,1) );
	float wb = wx1 * wy0 * float( sb != vec4(0,0,0,1) );
	float wc = wx0 * wy1 * float( sc != vec4(0,0,0,1) );
	float wd = wx1 * wy1 * float( sd != vec4(0,0,0,1) );
	return ( sa * wa + sb * wb + sc * wc + sd * wd ) / ( wa + wb + wc + wd + FRACT_1_16777216 );
#else
	return textureLod( ch, uv, 0. );
#endif
}

// ----------------------------------------------------------------------------
// SCENE
// ----------------------------------------------------------------------------

float scene_primitive_sphere( Ray ray, float R, inout float t, inout vec3 N )
{
	vec2 sph = sphere_impact( ray.o, ray.d );
	if( sph.x < R * R )
	{
		float to = sphere_limits( R, sph ).x;
		if( to >= 0. && to < t )
		{
			t = to;
			N = normalize( ray.o + t * ray.d );
		}
	}
	float shadow = 1.;
	if( sph.y < 0. )
	{
		float K = -2. * sph.y * sqrt( LE.sundisk );
		float u = sqrt( sph.x );
		shadow = 1. - aaa_interval( K, u, 2. * R );
	}
	return shadow;
}

float scene_primitive_cube( Ray ray, vec3 size, inout float t, inout vec3 N )
{
	vec3 dn = ray.o + sign( ray.d ) * size;
	vec3 to = -dn / ray.d;
	if( to.x >= 0. && to.x < t &&
		hmax( abs( ray.o.yz + ray.d.yz * to.x ) - size.yz ) < 0. )
	{
		t = to.x;
		N = sign( ray.o.x ) * UNIT_X;
	}
	if( to.y >= 0. && to.y < t &&
		hmax( abs( ray.o.zx + ray.d.zx * to.y ) - size.zx ) < 0. )
	{
		t = to.y;
		N = sign( ray.o.y ) * UNIT_Y;
	}
	if( to.z >= 0. && to.z < t &&
		hmax( abs( ray.o.xy + ray.d.xy * to.z ) - size.xy ) < 0. )
	{
		t = to.z;
		N = sign( ray.o.z ) * UNIT_Z;
	}
	float shadow = 1.;
	if( hmax( to ) >= 0. )
	{
		vec3 K = 2. * max( ZERO, max( to.yzx, to.zxy ) ) * sqrt( LE.sundisk );
		vec3 R = size.yzx * abs( ray.d ).zxy + size.zxy * abs( ray.d ).yzx;
		vec3 u = cross( ray.o, ray.d );
		shadow = 1. - aaa_interval( K.x, u.x, 2. * R.x )
			* aaa_interval( K.y, u.y, 2. * R.y )
			* aaa_interval( K.z, u.z, 2. * R.z );
	}
	return shadow;
}

float scene_primitive_cylinder( Ray ray, vec2 size, inout float t, inout vec3 N )
{
	float R = size.x;
	float omzz = max( 0., 1. - ray.d.z * ray.d.z );
	float ooomzz = 1. / omzz;
	float od = dot( ray.o.xy, ray.d.xy );
	float u = square( dot( ray.o.xy, perp( ray.d.xy ) ) ) * ooomzz;
	float v = max( 0., R * R - u );
	float to = -od * ooomzz - sqrt( v * ooomzz );
	float dz = ray.o.z + sign( ray.d.z ) * size.y;
	float tz = -dz / ray.d.z;
	if( u < R * R )
	{
		if( to >= 0. && to < t && abs( ray.o.z + ray.d.z * to ) < size.y )
		{
			t = to;
			N = vec3( normalize( ray.o.xy + t * ray.d.xy ), 0. );
		}
		vec2 xy = ray.o.xy + ray.d.xy * tz;
		if( tz >= 0. && tz < t && dot( xy, xy ) < R * R )
		{
			t = tz;
			N = sign( ray.o ) * UNIT_Z;
		}
	}
	float shadow = 1.;
	if( ( od < 0. || -sign( ray.d.z ) * ray.o.z >= size.y ) &&
					  sign( ray.d.z ) * ray.o.z < size.y * 0.95 )
	{
		float somzz = sqrt( omzz );
		float K = 2. * max( 0., max( to, tz ) * sqrt( LE.sundisk ) );
		float u1 = sqrt( u );
		float u2 = ( od * ray.d.z * ooomzz - ray.o.z ) * somzz;
		float R2 = sqrt( v ) * abs( ray.d.z ) + size.y * somzz;
		shadow = 1. - aaa_interval( K, u1, 2. * R ) *
			aaa_interval( K, u2, 2. * R2 );
	}
	return shadow;
}

float scene_obj_primitive( SceneObj obj, Ray ray, inout float t, inout vec3 albedo, inout vec3 out_N )
{
	float to = t, shadow = 1.;
	vec3 N = ZERO;
	switch( int( obj.paramsA.w ) )
	{
	case SCNOBJ_PRIMITIVE_SPHERE:
	shadow = scene_primitive_sphere( ray, obj.paramsB.x, to, N );
	break;
	case SCNOBJ_PRIMITIVE_CUBE:
	shadow = scene_primitive_cube( ray, obj.paramsB.xyz, to, N );
	break;
	case SCNOBJ_PRIMITIVE_CYLINDER:
	shadow = scene_primitive_cylinder( ray, obj.paramsB.xy, to, N );
	break;
	}
	if( to < t )
	{
		t = to;
		out_N = N;
		bool ir = bit_is_set( GS.switches, GS_SW_IRCAM );
		if( obj.paramsA.x == -99. )
		{
			float u = ray.o.z + ray.d.z * t;
			float Ku = 2. * sqrt( g_pixelscale ) * t * mix( 1., 1. / dot( -ray.d.xy, N.xy ), square( ray.d.z ) );
			albedo = mix( irselect( g_matdata( int( obj.paramsA.y ) ).omega, ir ),
						  irselect( g_matdata( int( obj.paramsA.z ) ).omega, ir ),
						  aaa_stipple( Ku, u - .001, .004, .5 ) );
		}
		else
			albedo = irselect( g_matdata( int( abs( obj.paramsA.x ) ) ).omega, ir );
	}

	return shadow;
}

int scene_raycast_objects( RayBaserel ray, inout float t, inout vec3 albedo, inout vec3 out_N )
{
	int result = -1;
#if WITH_OBJECTS
	for( int i = 0, n = int( memload( iChannel0, ADDR_DATASIZES, 0 ).w ); i < n; ++i )
	{
		float to = t;
		vec3 N = ZERO;
		SceneObj obj = so_load( iChannel0, ADDR_SCENE_OBJECTS + ivec2( i, 0 ) );
		Ray localray = Ray( ( ray.orel - FORCE_EVAL( obj.r - g_campos_base ) ) * obj.B, ray.d * obj.B );
		switch( int( obj.tybr.x ) )
		{
		case SCNOBJ_TYPE_PRIMITIVE:
		scene_obj_primitive( obj, localray, to, albedo, N );
		break;
		}
		if( to < t )
			result = i, t = to, out_N = obj.B * N;
	}
#endif
	return result;
}

float scene_raycast_object_shadows( Ray ray )
{
	float result = 1.;
#if WITH_OBJECTS
	float t = SCN_ZFAR;
	vec3 albedo, N;
	for( int i = 0, n = int( memload( iChannel0, ADDR_DATASIZES, 0 ).w ); i < n; ++i )
	{
		SceneObj obj = so_load( iChannel0, ADDR_SCENE_OBJECTS + ivec2( i, 0 ) );
		Ray localray = Ray( ( ray.o - FORCE_EVAL( obj.r - g_campos_base ) ) * obj.B, ray.d * obj.B );
		switch( int( obj.tybr.x ) )
		{
		case SCNOBJ_TYPE_PRIMITIVE:
		result *= scene_obj_primitive( obj, localray, t, albedo, N );
		break;
		}
	}
#endif
	return max( 0., result );
}

vec3 scene_object_lighting( vec3 albedo, vec3 N, vec3 L, vec3 V, vec3 Z, vec3 F,
							vec3 skyZ, vec3 skyL, vec3 skyR, vec3 ground )
{
#if WITH_OBJECTS
	float mu_0 = mu_stretch( dot( N, L ), .01 );
	float mu = mu_stretch( dot( N, V ), .01 );
	float cosi = dot( N, Z );
	float cosp = dot( L, V );
	float cost = dot( normalize( reject( N, Z ) ), normalize( reject( L, Z ) ) );
	vec3 kd = lunar_lambert( albedo, mu, mu_0 );
	float kl = phase_curve( cosp );
	vec3 E = F * mu_0;
	//*
	vec3 sky = mix( mix( skyR, skyL, .5 + .5 * cost ), skyZ, cosi * .3333 + .6667 );
	return E * kd * kl + albedo * mix( ground, sky, cosi * .5 + .5 );
#else
	return ZERO;
#endif
	/*/
	float cosi2 = cosi * cosi;
	vec3 skyH = ( skyL + skyR ) / 2.;
	vec3 skyJ = ( skyL - skyR ) / 2.;
	vec3 sky = skyZ / 8. * ( 2.6667 + cosi * ( 3.5 + cosi2 * ( -0.3333 + cosi2 * ( -0.5 + cosi2 ) ) ) ) +
			   skyH / 8. * ( 1.3333 + cosi * ( 0.5 + cosi2 * ( +0.3333 + cosi2 * ( +0.5 + cosi2 ) ) ) ) +
			   skyJ * cost / ( 105. * PI ) * ( 30. - cosi2 * ( 6. + cosi2 * ( 8. + cosi2 * 16. ) ) );
	return E * kd * kl + albedo * ( sky + ground * ( 1. - cosi ) / 2. );
	//*/
}

vec4 scene_ocean_normal_and_lensing( vec3 r, float t, float h, float d, vec3 V, vec3 Z )
{
	vec3 A = normalize( V - Z * dot( V, Z ) );
	vec3 B = cross( A, Z );
	vec3 M = normalize( Z + .25 * trn_normalmapLod( r + 0.002 * iTime * Z, d ) );
	float dMdA = dot( A, normalize( Z + .25 * trn_normalmapLod( r + 0.002 * iTime * Z + d * A, d ) ) - M );
	float dMdB = dot( B, normalize( Z + .25 * trn_normalmapLod( r + 0.002 * iTime * Z + d * B, d ) ) - M );
	float lens = 1. + h / d * ( dMdA + dMdB );
	return vec4( M, 1. / max( FRACT_1_64, lens * lens ) );
}

vec3 scene_object_color( vec3 r, mat2x3 Kr, float t, float r0, vec3 N, vec3 V, vec3 albedo,
						 bool submerged, int index, vec3 r_baserel )
{
#if WITH_OBJECTS
	float h = length(r) - r0;
	vec3 Z = normalize(r);
	vec3 skyL = texelFetch( iChannel2, ivec2( iResolution.x - 6., int( iResolution.y ) / 2 + 2 * index ), 0 ).xyz;
	vec3 skyR = texelFetch( iChannel2, ivec2( iResolution.x - 4., int( iResolution.y ) / 2 + 2 * index ), 0 ).xyz;
	vec4 skyZ = texelFetch( iChannel2, ivec2( iResolution.x - 2., int( iResolution.y ) / 2 + 2 * index ), 0 );
	vec3 TL = ac_transmittance( AC, Z * max( PD.radius, length( r ) ), LE.L, true );
	vec3 F = LE.sunlight;
	vec3 L = LE.L;
	if( submerged )
	{
		float d = max( 0.001, -.25 * h );
		vec4 M = scene_ocean_normal_and_lensing( r, t, h, d, V, Z );
		F = F * M.w;
		F = F * saturate( 1. - fresnel_schlick( .02, dot( M.xyz, L ) ) );
		L = normalize( -simple_refract( -L, Z ) );
	}
	float trnshadow = trn_shadow_sample( SM, iChannel1, length_normalize(r) ).x;
	F *= trnshadow * TL * skyZ.w;
	float objshadow = scene_raycast_object_shadows( Ray( r_baserel, L ) );
	float slope = length( N / dot( N, Z ) - Z );
	vec3 ground = trn_albedo( r, 4. * h, h, slope, vec2(0), Z.z, false ) * ( F * mu_stretch( dot( L, Z ), .01 ) + skyZ.xyz );
	if( submerged )
	{
		skyZ.xyz = .75 * skyZ.xyz + .125 * skyL + .125 * skyR;
		skyL = .125 * skyL + .375 * ( skyZ.xyz + ground );
		skyR = .125 * skyR + .375 * ( skyZ.xyz + ground );
	}
	return scene_object_lighting( albedo, N, L, V, Z, F * objshadow, skyZ.xyz, skyL, skyR, ground );
#else
	return ZERO;
#endif
}

float scene_obj_runway_centerline( mat2 K, vec2 uv, vec2 size )
{
	float l = floor( size.x / 60. - 1.5 ) * 60.;
	return aaa_stipple( Linfinity( K[0] ), uv.x, 60., .5 ) *
		aaa_box( K, uv, vec2( l, .7 ), vec2( 0 ) );
}

float scene_obj_runway_threshold_markers( mat2 K, vec2 uv, vec2 size )
{
	uv = abs( uv ) - size / 2. + vec2( 30, size.y / 4. );
	float w = floor( size.y / 9. ) * 3.;
	return aaa_stipple( Linfinity( K[1] ), uv.y - fract( w / 6. ) * 3., 3., .5 ) *
		aaa_box( K, uv, vec2( 30., w ), vec2( 0 ) );
}

vec4 scene_obj_runway( vec4 col, SceneObj obj, vec3 _r, mat2x3 Kr )
{
	vec3 dr = 1000. * ( _r - FORCE_EVAL( obj.r - g_campos_base ) );
	if( dot( dr, dr ) < 2. * dot( obj.paramsB.xy, obj.paramsB.xy ) )
	{
		vec2 uv = ( dr * obj.B ).xy;
		mat2 K = 1000. * mat2( obj.B[0] * Kr, obj.B[1] * Kr );

		// tarmac
		float d;
		d = aaa_box( K, uv, obj.paramsB.xy, obj.paramsB.zw );
		vec3 albedo = irselect( g_matdata( int( abs( obj.paramsA.x ) ) ).omega, bit_is_set( GS.switches, GS_SW_IRCAM ) );
		col = mix( col, vec4( albedo, 1 ), d );

		// paintings
		if( obj.paramsA.w > 0. )
		{
			d = ( scene_obj_runway_centerline( K, uv, obj.paramsB.xy ) +
				  scene_obj_runway_threshold_markers( K, uv, obj.paramsB.xy ) );
			col = mix( col, vec4( obj.paramsA.www, 1 ), d );
		}
	}
	return col;
}

vec3 scene_surface_albedo( vec3 _r, mat2x3 Kr, float h, float slope, vec2 sigmares, float sinlat, bool detail )
{
	vec4 col = vec4( 0 );
	for( int i = 0, n = int( memload( iChannel0, ADDR_DATASIZES, 0 ).w ); i < n; ++i )
	{
		ivec2 addr = ADDR_SCENE_OBJECTS + ivec2( i, 0 );
		SceneObj obj = so_load( iChannel0, addr );
		switch( int( obj.tybr.x ) )
		{
		case SCNOBJ_TYPE_RUNWAY:
		col = scene_obj_runway( col, obj, _r, Kr );
		break;
		}
		if( col.w >= 1. )
			break;
	}
	float Krwidth = sqrt( max( dot( Kr[0], Kr[0] ), dot( Kr[1], Kr[1] ) ) );
	return trn_albedo( _r + g_campos_base, Krwidth, h, slope, sigmares, sinlat, detail ) * ( 1. - col.w ) + col.xyz;
}

vec3 scene_lighting_terrain( vec3 albedo, vec3 N, vec3 L, vec3 V, vec3 Z, vec3 F,
							 vec3 sky, vec2 shadow )
{
#if WITH_ILLUM_TEST
	float mu0 = max( 0., dot( N, L ) );
	return F * mu0 + sky;
#else
	float mu_0 = mu_stretch( dot( N, L ), .01 );
	float mu = mu_stretch( dot( N, V ), .01 );
	float cosi = dot( N, Z );
	float cosp = dot( L, V );
	vec3 kd = lunar_lambert( albedo, mu, mu_0 );
	float kl = phase_curve( cosp );
	float kj = cosi * .5 + .5;
	vec3 E = F * mu_0 * shadow.x;
	vec3 backbounce = .5 * albedo * F * shadow.y * mu_stretch( dot( N, -L ), .125 )
		* mu_stretch( dot( L, Z ), .005 );
	return E * kd * kl + albedo * ( sky * kj + backbounce );
#endif
}

vec3 scene_lighting_ocean( vec3 albedo, vec3 Z, vec3 N, vec3 M, vec3 L, vec3 V, vec3 F,
						   float a, vec3 sky,
						   vec4 refl, float extra_T )
{
#if WITH_ILLUM_TEST
	float mu0 = max( 0., dot( N, L ) );
	return F * mu0 + refl.xyz;
#else
	// variation of the KSK microfacet model
	vec3 L_refract = normalize( -simple_refract( -L, Z ) );
	float mu0_refract = max( 0., dot( N, L_refract ) ) * max( 0., dot( L, Z ) );
	float mu0 = max( 0., dot( M, L ) );
	vec3 H = normalize( L + V );
	float cosxi = max( 0., dot( M, H ) );
	float cospsi = max( .0625, dot( L, H ) );
	float fr_mu = refl.w;
	float fr_psi = fresnel_schlick( .02, cospsi );
	float kd = ( 1. - fr_mu );
	float ks = extra_T * NDFdisk( cosxi, a, .5 * LE.sundisk ) / ( 4. * cospsi * cospsi );
	return F * mix( mu0_refract * albedo * kd, mu0 * vec3( ks ), fr_psi ) + albedo * sky * ( 1. - fr_mu ) + refl.xyz;
#endif
}

vec3 ndist( vec3 Z, float k, vec3 dZ )
{
	float b = dot( Z, dZ );
	return normalize( Z * square( 1. - k + k * b ) + k * ( dZ - Z * b ) );
}

vec3 scene_surface_color( vec3 r, mat2x3 Kr, float t, vec3 V, vec2 uv, bool submerged,
						  inout vec3 albedo, inout vec3 N, vec3 r_baserel )
{
	float Krwidth = sqrt( max( dot( Kr[0], Kr[0] ), dot( Kr[1], Kr[1] ) ) );
	vec2 sigmares = vec2(0);
	vec4 rn = length_normalize(r);
	vec4 tsample = trn_sample_fine( SM, iChannel1, rn.xyz, PD, Krwidth, sigmares );
	vec2 tshadow = trn_shadow_sample( SM, iChannel1, rn );
	N = normalize( tsample.xyz );
	vec3 Z = rn.xyz;
	float h = tsample.w;
	float pshadow = atm_planet_shadow( dot( LE.L, Z ), sqrt( max( 0., 1. - LE.radius * LE.radius / dot( r, r ) ) ), sqrt( LE.sundisk ) );
	vec4 sky = atm_skylight_sample( SM, iChannel2, r );
	vec3 TL = ac_transmittance( AC, Z * max( PD.radius, rn.w ), LE.L, true );
	vec3 F = LE.sunlight * TL * sky.w * pshadow;
	float slope = length( N / dot( N, Z ) - Z );
	albedo = scene_surface_albedo( r_baserel, Kr, h, slope, sigmares, Z.z, h >= 0. || submerged );
	float d = submerged ?
		max( 0.001, -.25 * h ) :
		max( max( 0.001, 125. * h * h ), 4. * t * sqrt( g_pixelscale ) );
	vec4 M = scene_ocean_normal_and_lensing( r, t, h, d, V, Z );
	vec3 L = LE.L;
	if( submerged )
	{
		F = F * M.w;
		F = F * saturate( 1. - fresnel_schlick( .02, dot( M.xyz, L ) ) );
		L = normalize( -simple_refract( -L, Z ) );
	}
	float oshadow = scene_raycast_object_shadows( Ray( r_baserel, L ) );
	vec3 col = ZERO;
	if( h < 0. && !submerged )
	{
		// water surface
		vec3 To = exp2pp( 1000. * h * g_ocn_beta50 );
		vec4 rsmpl = atm_reflection_sample( iChannel2, uv );
		vec3 albedo = mix( g_ocn_omega, To * albedo, To );
		F = F * M.w;
		F = F * mix( ONE, vec3( tshadow.x * oshadow ), To );
		const float cld_g = 0.85;
		const float cld_f = cld_g * cld_g;
		float extra_T = pow( sky.w, inversesqrt( 1. - cld_f ) - 1. );
		float a = sqrt( .0003 * inversesqrt( g_pixelscale ) / t + 1. ) * .8 / PD.ocn.paramsA.z;
		vec3 M = ndist( Z, 1.5 * PD.ocn.paramsA.z, trn_ripplemap( r + 0.002 * iTime * Z ) );
		M = M + .35 * PD.ocn.paramsA.z * ( Z + V ) * parabolstep( 0., .250, t - t * dot( V, Z ) );
		M = normalize( M + V * mu_stretch( -dot( M, V ), .03125 ) );
		col = scene_lighting_ocean( albedo, Z, N, M, LE.L, V, F, a, sky.xyz, rsmpl, extra_T );
	}
	else
	if( t < SCN_ZFAR )
	{
		// land surface
		col = scene_lighting_terrain( albedo, N, L, V, Z, F * oshadow, sky.xyz, tshadow.xy );
	}
	return col;
}

float scene_raycast_terrain(
	RayBaserel ray, float wlevel, float tmax2nd, inout float t0, inout vec3 rrel, bool submerged, vec2 limits )
{
	float t = limits.x, h = 0., alt = 0.;
	float lasth = 0., lastt = 0., lasta = 0.;
	float altbase = FORCE_EVAL( SM.r0 - PD.radius );
	vec4 tsmpl = vec4(0);
	for( int i = 0, n = SCN_RAYCAST_MAX_ITER; i < n; i++ )
	{
		rrel = ray.orel + t * ray.d;
		tsmpl = trn_sample_baserel( SM, iChannel1, ray.obase, rrel );
		lasta = alt;
		alt = sumdifflen( ray.obase, rrel ) + altbase;
		lasth = h;
		h = alt - ( submerged ? tsmpl.w : max( wlevel, tsmpl.w ) );
		if( h < 0. )
		{
			t = mix( lastt, t, safediv( 0. - lasth, h - lasth ) );
			rrel = ray.orel + t * ray.d;
			return t;
		}
		else
		if( submerged && alt >= wlevel )
		{
			if( t0 > 0. )
				break;
			t = mix( lastt, t, safediv( wlevel - lasta, alt - lasta ) );
			rrel = ray.orel + t * ray.d;
			vec3 Z = normalize( rrel + ray.obase );
			vec3 N = ndist( Z, 1.5 * PD.ocn.paramsA.z, trn_ripplemap( rrel + ray.obase + 0.002 * iTime * Z ) );
			ray.d = normalize( ray.d - 2. * N * dot( ray.d, N ) );
			ray.d = normalize( ray.d - Z * max( 0., dot( ray.d, Z ) ) );
			ray.orel = rrel - t * ray.d;
			t0 = t;
			alt = wlevel;
			h = wlevel - trn_sample_n( SM, iChannel1, Z ).w;
		}
		lastt = t;
		t += max( TRN_SAFE_SLOPE_FACTOR * ( 1. + .25 * dot( tsmpl.xyz, ray.d ) ) * h, SCN_RAYCAST_MIN_ADVANCE + SCN_RAYCAST_MIN_ADVANCE_SCALE * t );
		if( t >= limits.y || ( t0 > 0. && t >= tmax2nd ) )
		{
			t = SCN_ZFAR;
			break;
		}
	}
	return SCN_ZFAR;
}

// ----------------------------------------------------------------------------
// STARFIELD / SUNDISK
// ----------------------------------------------------------------------------

vec3 starfield_worker( vec4 params, float pixelscale )
{
	// about 336 visible cells, 27 stars per cell = 9072 stars
	// simulate the actual magnitude distribution up to 6.5 mag as a power law

	const float power = -0.7684;
	const float powersum = 31.8768;						// = sum( i^-0.7684, i=1..9072 )

	float n = min( 8344508., 2. / pixelscale );
	float scale = 2. * ( n + 2. ) / powersum * pow( length( params.xyz ), -n );
	vec3 cell = vec3( floor( asin( params.xy ) * 5.09393754 ), params.w + sign( params.z ) );
	vec3 col = ZERO; // vec3( cell.xy / 7. + .5, cell.z / 5. );
	int k = 1 + int( mod( 233. * dot( cell, vec3( 1, 8, 64 ) ), 384. ) );
	uint rnd = uint( 13 * k );
	for( int i = 0, N = 27; i < N; ++i )
	{
		vec2 phi = sin( ( cell.xy + vec2( rnd *= 3934873077u, rnd *= 3934873077u ) / 4294967296. ) / 5.09393754 );
		vec3 dir = vec3( phi, sign( params.z ) * sqrt( 1. - dot( phi, phi ) ) );
		col += scale * pow( float( k + 384 * i ), power ) * pow( dot( dir, params.xyz ), n );
	}
	return LE.starlight * mix( col, ONE, COL_STARLIGHT_ISL );
}

vec3 starfield( vec3 raydir, float pixelscale )
{
	PlanetState ps = ps_load( iChannel0, ps_addr(1) );
	raydir = ps.B * raydir;

#if WITH_STARS
	vec3 absdir = abs( raydir );
	vec4 params = absdir.x < absdir.y ?
		absdir.y < absdir.z ?
		vec4( raydir.xyz, 0 ) :
		vec4( raydir.zxy, 2 ) :
		absdir.z < absdir.x ?
		vec4( raydir.yzx, 4 ) :
		vec4( raydir.xyz, 0 );
	return starfield_worker( params, pixelscale );
#else
	return ZERO;
#endif
}

vec3 sundisk( float cosangle )
{
	float cosbeta = sqrt( max( 0., 1. - LE.sundisk ) );
	float shape = 1.333 * parabolstep( cosbeta, ( 1. + cosbeta ) / 2., cosangle );
	return shape * LE.sunlight / LE.sundisk;
}

// ----------------------------------------------------------------------------
// MAP MODE
// ----------------------------------------------------------------------------

vec2 vr_unproject( vec3 r )
	{ return unViewport.zw * ( g_vrfocus.xy + .5 * g_vrfocus.zw * r.yz / r.x * vec2( 1, -1 ) ); }

vec2 fix_fcoord_for_vr( vec2 fcoord )
{
	if( g_vrmode )
	{
		vec2 xy = vr_unproject( vec3( 1.35, -1, +iResolution.y / iResolution.x ) );
		vec2 zw = vr_unproject( vec3( 1.35, +1, -iResolution.y / iResolution.x ) );
		fcoord = ( fcoord - unViewport.xy - xy ) * iResolution.xy / ( zw - xy );
	}
	return fcoord;
}

float map_expand_flatten( float h )
{
	float flevel = PD.trn.flatten.x * PD.trn.slope.x * PD.radius;
	float frange = PD.trn.flatten.y * PD.trn.slope.x * PD.radius;
	float fstrenth = PD.trn.flatten.z;
	float compress = ( fstrenth / 3. - fstrenth + 1. );
	float compressed_top = flevel + frange * compress;
	float compressed_bottom = flevel - frange * compress;
	float expanded_top = flevel + frange;
	float expanded_bottom = flevel - frange;
	float minh = PD.trn.levels.x * PD.trn.slope.x * PD.radius;
	float maxh = PD.trn.levels.y * PD.trn.slope.x * PD.radius;
	if( h > compressed_top )
		return ( h - compressed_top ) / ( maxh - compressed_top ) * ( maxh - expanded_top ) + expanded_top;
	else
		if( h < compressed_bottom )
			return ( h - minh ) / ( compressed_bottom - minh ) * ( expanded_bottom - minh ) + minh;
		else
			return ( h - compressed_bottom ) / ( compressed_top - compressed_bottom ) * ( expanded_top - expanded_bottom ) + expanded_bottom;
}

float map_grid_coverage( vec3 r, mat2x3 Kr, float zoom )
{
	vec3 north = normalize( reject( UNIT_Z, r ) );
	vec3 east = cross( north, r );
	float lat = degrees( atan( r.z, length( r.xy ) ) );
	float lng = degrees( atan( r.y, r.x ) );
	float sz = sqrt( 1. - r.z * r.z );
	float Ku = degrees( Linfinity( north * Kr ) );
	float Kv = degrees( Linfinity( east * Kr ) ) / sz;
	const float n = 5.;
	const float log2n = log2( n );
	float levels[] = float[]( 90., 30., 5., 1., .2 );
	int l = zoom < 1. ? 0 : zoom < 6. ? 1 : zoom < 30. ? 2 : 3;
	float grid1 = levels[l];
	float grid2 = levels[l + 1];
	int m = min( l, abs( lat ) >= 90. - grid2 ? 0 :
					abs( lat ) >= 90. - grid1 ? 1 :
					abs( lat ) >= 85. ? 2 : 3 );
	float grid1h = levels[m];
	float grid2h = levels[m + 1];
	float latitudes = aaa_stipple( Ku, grid1 / 2. + lat, grid1, .25 * Ku / grid1 );
	float meridians = aaa_stipple( Kv, grid1h / 2. + lng, grid1h, .25 * Kv / grid1h );
	float sub_latitudes = aaa_stipple( Ku, grid2 / 2. + lat, grid2, .0625 * Ku / grid2 );
	float sub_meridians = aaa_stipple( Kv, grid2h / 2. + lng, grid2h, .0625 * Kv / grid2h );
	float meridian_mask = aaa_interval( Ku, lat, 180. - 2. * grid2 / 5. );

	return max(
		latitudes, max(
			meridians * meridian_mask, max(
				sub_latitudes,
				sub_meridians * meridian_mask ) ) );
}

float map_isocontour_coverage( float h, float Kh )
{
	float grid1 = 1.;
	float grid2 = .1;
	float grid3 = .01;
	float super_contours = aaa_stipple( Kh, grid1 / 2. + h, grid1, min( .25, Kh / grid1 ) );
	float contours = aaa_stipple( Kh, grid2 / 2. + h, grid2, min( .125, .5 * Kh / grid2 ) );
	float sub_contours = aaa_stipple( Kh, grid3 / 2. + h, grid3, min( .0625, .25 * Kh / grid3 ) );
	float result = max( super_contours, max( contours, sub_contours ) );
	return result;
}

vec3 map_display( vec2 fcoord )
{
	vec2 fc = fix_fcoord_for_vr( fcoord );
	if( any( greaterThanEqual( abs( fc - iResolution.xy / 2. ), iResolution.xy / 2. ) ) )
		return ZERO;
	vec3 drdx = ZERO, drdy = ZERO;
	vec4 r = gs_map_unproject_d( GS, fc, iResolution.xy, drdx, drdy );
	mat2x3 Kr = mat2x3( drdx, drdy );
	vec2 c = mix( iResolution.xy / 2., fc, 1. / g_subsample );
	vec4 tsmpl = texture( iChannel1, c / iResolution.xy, 0. );
	vec2 sigmares = vec2(0);
#if WITH_TRN_SURFACE_AA && !WORKAROUND_11_MAP_CRASH
	{
		SphereMap sm;
		sm.rn = r.xyz;
		sm.TB[0] = normalize( reject( UNIT_Z, sm.rn ) );
		sm.TB[1] = cross( sm.rn, sm.TB[0] );
		int zoneindex = int( tsmpl.z );
		tsmpl = sm_unpack_normal( sm, tsmpl );
		float detail = log2( iResolution.y * GS.camzoom ) - TRN_LOD_BIAS - 2.5 * float( g_vrmode );
		float Krwidth = sqrt( max( dot( Kr[0], Kr[0] ), dot( Kr[1], Kr[1] ) ) ) * g_subsample;
		vec4 zone = zd_trn_zone( zd_load( iChannel1, zd_addr_b( zoneindex ) ), PD.radius );
		trn_elevation_refine(
			r.xyz,
			detail,
			PD,
			zone,
			detail,
			tsmpl,
			sigmares );
	}
#endif
	float h = tsmpl.w;
	float Kh = Linfinity( vec2( dFdx(h), dFdy(h) ) );
	float s = degrees( acos( dot( tsmpl.xyz, r.xyz ) ) ) / 100.;
	float Ks = Linfinity( vec2( dFdx(s), dFdy(s) ) );
	float z = 0.;
	float Kz = 0.;
	float cut = 0.;
	if( abs( r.w ) >= 1. )
		return ZERO;
	tsmpl.w += PD.radius;
	vec3 col = ZERO;

	int mode = bitfield_get_int( GS.switches, GS_SW_MMODE_MASK, GS_SW_MMODE_SHIFT );
	vec3 oceanI = 3.5 * mix( square( PD.ocn.omega.xyz ), ( PD.ocn.omega.xyz ), exp2( -h * 5. / ( PD.radius * PD.trn.levels.x ) ) );
	vec3 oceanT = h < 0. ? 0.95 * exp2pp( min( 0., h ) * PD.ocn.beta50.xyz * 1000. ) : ONE;
	vec3 gridcol = ZERO;
	if( mode == GS_MAP_PHYSICAL )
	{
		vec3 N = tsmpl.xyz;
		vec3 Z = r.xyz;
		float slope = length( N / dot( N, Z ) - Z );
		vec3 albedo = scene_surface_albedo( tsmpl.w * r.xyz - g_campos_base, tsmpl.w * Kr * g_subsample, h, slope, sigmares, r.z, true );
		col = mix( oceanI, oceanT * albedo, oceanT );
		gridcol = col.y < .5 ? ONE : ZERO;
		cut = .125;
	}
	else
	if( mode == GS_MAP_ELEVATION )
	{
		float e = map_expand_flatten(h) / ( PD.radius * PD.trn.slope.x * abs( h < 0. ? PD.trn.levels.x : PD.trn.levels.y ) );
		col = vec3( cos( e * 3. - PI / 2. ), cos( e * 3. ), cos( e * 3. + PI / 2. ) ) * .3 * saturate( 4. * abs( h ) ) + .4;
		col = mix( oceanI, col, .5 + .5 * oceanT );
		// col = vec3( -.5 * h / ( PD.radius * PD.trn.slope.x * PD.trn.levels.x ) + .5 );
		z = h;
		Kz = Kh;
		cut = .25;
	}
	else
	if( mode == GS_MAP_SLOPE )
	{
		col = vec3( cos( s * 9. ), cos( s * 9. + PI * 0.6667 ), cos( s * 9. + PI * 1.3333 ) ) * .3 * saturate( 4. * s ) + .4;
		col = mix( oceanI, col, .5 + .5 * oceanT );
		// col = vec3( max( 0., log2( tan( radians( 100. * s ) ) ) / 8. + 1. ) );
		// col = vec3( clamp( 100. / 8. * s, 0., 1. ) );
		z = max( s, Ks );
		Kz = Ks;
		cut = .75;
	}

	//*
	if( mode != GS_MAP_PHYSICAL )
		col = mix( col, ZERO, map_isocontour_coverage( z, Kz ) );
	vec3 L = normalize( r.xyz - normalize( Kr[0] ) + normalize( Kr[1] ) );
	col = col * max( cut, 1.5 * dot( tsmpl.xyz, L ) ) * mix( COL_RODVISION, COL_SUNLIGHT.xyz, parabolstep( -.01, .01, dot( r.xyz, LE.L ) ) );
	col = mix( col, gridcol, map_grid_coverage( r.xyz, Kr, GS.camzoom ) );
	//*/

	// TODO: display outline of apparent horizon
	/*
	{
		if( tsmpl.w < PD.radius && r.w < PD.radius )
		{
			tsmpl.w = PD.radius;
			tsmpl.xyz = normalize( r.xyz );
		}
		float c = dot( r.xyz, VS.localr );
		vec3 dwdr = tsmpl.xyz / dot( tsmpl.xyz, r.xyz ) - r.xyz;
		float Kc = 2. * Linfinity( ( abs(c) * VS.localr + length( VS.localr ) * tsmpl.w * dwdr ) * Kr );
		col += vec3( 1, .5, 0 ) * aaa_interval( Kc, ( tsmpl.w + abs(c) ) * ( tsmpl.w - c ), .5 * Kc );
	}
	//*/

	return col;
}

// ----------------------------------------------------------------------------
// MAIN
// ----------------------------------------------------------------------------

/*

  // scene_object_color

	vec3 L = LE.L;
	if( submerged )
	{
		float d = max( 0.001, -.25 * h );
		vec4 M = scene_ocean_normal_and_lensing( r, t, h, d, V, Z );
		F = F * M.w;
		F = F * saturate( 1. - fresnel_schlick( .02, dot( M.xyz, L ) ) );
		L = normalize( -simple_refract( -L, Z ) );
	}

  // scene_surface_color

	float d = submerged ?
		max( 0.001, -.25 * h ) :
		max( max( 0.001, 125. * h * h ), 4. * t * sqrt( g_pixelscale ) );
	vec4 M = scene_ocean_normal_and_lensing( r, t, h, d, V, Z );

	vec3 L = LE.L;
	if( submerged )
	{
		F = F * M.w;
		F = F * saturate( 1. - fresnel_schlick( .02, dot( M.xyz, L ) ) );
		L = normalize( -simple_refract( -L, Z ) );
	}
*/

vec4 render( vec2 uv, bool submerged )
{
	float t0 = 0., Tc = 1., t = SCN_ZFAR;
	float r0 = PD.radius;
	vec3 _r = g_ray.orel, N = ZERO, col = ZERO, albedo = ZERO, I = ZERO;
	vec2 sph = sphere_impact( g_ray.obase + g_ray.orel, g_ray.d );
	float rtop = PD.radius * ( 1. + PD.trn.levels.y * PD.trn.slope.x );
	if( rtop * rtop >= sph.x )
	{
		vec2 limits = max( vec2(0), sphere_limits( rtop, sph ) );
		t = scene_raycast_terrain( g_ray, 0., 12. / ( 1000. * hmin( PD.ocn.beta50 ) ), t0, _r, submerged, limits );
	}
	float tx = t0 > 0. ? t0 : t;
	int index = scene_raycast_objects( g_ray_jittered, tx, albedo, N );
	mat2x3 Kr = mat2x3( dFdx(_r), dFdy(_r) );

	if( index >= 0 )
	{
		// object hit:
		// get atmosphere samples and color for object
		vec4 objsmpl = texelFetch( iChannel2, ivec2( iResolution.x - 8., int( iResolution.y ) / 2 + 2 * index ), 0 );
		Tc = objsmpl.w, I = objsmpl.xyz, t = tx, _r = g_ray_jittered.orel + t * g_ray_jittered.d;
		col = scene_object_color( _r + g_campos_base, Kr, t, PD.radius, N, - g_ray.d, albedo, submerged, index, _r );
	}
	else
	{
		// not object hit:
		// get atmosphere samples and color for sky and terrain
		vec4 asmpl = atm_inscatter_sample( iChannel2, uv, log2( max( FRACT_1_4096, t ) ) );
		Tc = asmpl.w, I = asmpl.xyz;
		if( t < SCN_ZFAR )
		{
			vec3 V = t0 > 0. ? normalize( _r - g_ray.orel ) : - g_ray.d;
			col = scene_surface_color( _r + g_campos_base, Kr, t, V, uv, submerged, albedo, N, g_ray.orel + t * g_ray.d );
		}
	}

	if( t >= SCN_ZFAR && !submerged )
	{
		// sky hit:
		// add contribution of celestial bodies
		// compute aerial perspective for an infinite ray
		const float cld_g = 0.85;
		const float cld_f = cld_g * cld_g;
		float extra_T = pow( Tc, inversesqrt( 1. - cld_f ) - 1. );
		float cosphase = saturate( dot( g_ray.d, LE.L ) );
		col = starfield( g_ray.d, g_pixelscale )
			+ extra_T * irselect( COL_SUNLIGHT, bit_is_set( GS.switches, GS_SW_IRCAM ) ) * sundisk( cosphase );
		vec3 Ta = ac_transmittance( AC, g_ray.orel + g_campos_base, g_ray.d, false );
		col = col * Tc * Ta + I;
	}
	else
	{
		// not sky hit:
		// add landing light contribution, if switched on
		vec3 collight = ZERO;
		if( bit_is_set( VS.switches, VS_SW_LIGHT ) )
		{
			// Xenon arc lamp 3 MCd with double beam pattern
			vec3 axis = normalize( VS.localB[0] + .05 * VS.localB[2] );
			vec3 L = normalize( VS.localr - _r - g_campos_base );
			vec3 V = normalize( g_ray.orel - _r );
			float beam1 = square( saturate( 2. * dot( -axis, L ) - 1. ) );
			float beam2 = square( saturate( 20. * dot( -axis, L ) - 19. ) );
			float mu0 = max( 0., dot( N, L ) );
			float mu = max( 0., dot( N, V ) );
			float cosphase = dot( L, V );
			/*
			vec3 omega0 = 4. * albedo / ( 3. * albedo + 1. );
			vec3 kd = ( albedo + .25 * ( 1. - albedo ) / max( 0.0001, mu + mu0 ) );
			/*/
			vec3 omega0 = 244. * albedo / ( 184. * albedo + 61. );
			vec3 kd = ( albedo * ( 1. + sqrt( mu * mu0 ) ) / 2. + .25 / max( 0.0001, mu + mu0 ) );
			//*/
			float kl = phase_curve( cosphase );
			float d = max( .002, distance( VS.localr, _r + g_campos_base ) );
			vec3 col = irselect( COL_XENONARC, bit_is_set( GS.switches, GS_SW_IRCAM ) );
			vec3 E = .00011 * col / pow( d, 1.67 ) * mu0;
			if( submerged )
				E *= exp2pp( -d * g_ocn_beta50 * 1000. );
			collight += omega0 * E * kd * kl * mix( beam1, beam2, .75 );
		}

		if( submerged )
		{
			// underwater:
			// modify color by underwater scattering
			vec3 surfacepoint = normalize( g_ray.orel + g_campos_base ) * PD.radius;
			vec3 surfacelight = LE.sunlight
				* ac_transmittance( AC, surfacepoint, LE.L, true )
				* ( 1. - fresnel_schlick( .02, dot( normalize( surfacepoint ), LE.L ) ) )
				* texelFetch( iChannel2, ivec2( iChannelResolution[2].xy ) - 1, 0 ).w
				+ texelFetch( iChannel2, ivec2( iChannelResolution[2].xy ) - 1, 0 ).xyz;
			float z0 = PD.radius - length( g_ray.orel + g_campos_base );
			float z1 = max( 0., PD.radius - length( _r + g_campos_base ) );
			vec3 W0 = exp2pp( -z0 * g_ocn_beta50 * 1000. );
			vec3 W1 = exp2pp( -z1 * g_ocn_beta50 * 1000. );
			if( t0 > 0. && index == -1 )
			{
				vec3 r0 = g_ray.orel + g_campos_base + t0 * g_ray.d;
				vec3 Z = normalize( r0 );
				vec3 M = ndist( Z, 1.5 * PD.ocn.paramsA.z, trn_ripplemap( r0 + 0.002 * iTime * Z ) );
				vec3 refrac = normalize( simple_refract( g_ray.d, M ) );
				float pixelscale_refrac = 4. * g_pixelscale;
				float cosxi = dot( M, normalize( simple_refract_inv( g_ray.d, LE.L, Z ) ) );
				float a = sqrt( .0003 * inversesqrt( pixelscale_refrac ) / t0 + 1. ) * .8 / PD.ocn.paramsA.z;
				vec3 Ta = ac_transmittance( AC, surfacepoint, refrac, false );
				vec3 outercol = I + Tc * Ta * (
					starfield( refrac, pixelscale_refrac ) +
					LE.sunlight * max( 0., NDFdisk( cosxi, a, .5 * LE.sundisk ) ) * max( 0., dot( Z, LE.L ) ) );
				vec3 WX = exp2pp( -t0 * g_ocn_beta50 * 1000. );
				vec3 WI = t0 - z0 >= 0.0001 ? W0 - ( W0 - WX ) * t0 / ( t0 - z0 ) : W0 - W0 * t0 * g_ocn_beta50 * 1000. * LN2;
				vec3 WY = exp2pp( -t * g_ocn_beta50 * 1000. );
				vec3 WJ = WY * ( t - t0 ) / ( t - t0 + z1 );
				float fr = max( 0., 1. - pow( 1.6666667 - dot( M, g_ray.d ), 8. ) );
				col = WX * mix( WY * ( collight + W1 * col ), outercol, fr ) + ( W0 - WI * WJ ) * g_ocn_omega * surfacelight;
			}
			else
			{
				vec3 WT = exp2pp( -t * g_ocn_beta50 * 1000. );
				vec3 WI = ( W0 - WT * W1 ) * ( t - t0 ) / ( t - t0 + z1 - z0 );
				col = WT * ( collight + W1 * col ) + WI * g_ocn_omega * surfacelight;
			}
		}
		else
		{
			// not underwater:
			// compute aerial perspective for a finite ray
			vec3 Ta = ac_transmittance_finite( AC, g_ray.orel + g_campos_base, _r + g_campos_base );
			col = ( collight + col ) * Tc * Ta + I;
		}
	}

	if( uv.y * g_subsample >= 1. - VS.canopy )
		col *= irselect( COL_CANOPY_TINT, bit_is_set( GS.switches, GS_SW_IRCAM ) );

	return vec4( col, t0 > 0. && ( index == -1 || t0 < t ) ? 1. : t > 0. ? t / ( 1. + t ) : 1. );
}

void hmd_night_vision( inout vec3 col, vec2 coord, vec3 cc )
{
	vec2 uv = coord / iResolution.xy;
	if( abs( cc.y ) < HMD_BORDER.x * cc.x && abs( cc.z ) < HMD_BORDER.y * cc.x )
	{
		float y = COL_NVISNGAIN * dot( col, irselect( COL_NVISNSENS, bit_is_set( GS.switches, GS_SW_IRCAM ) ) );
		col += COL_P43PHOSPHOR * COL_NVISNSAT * y / ( COL_NVISNSAT + y );
	}
}

uvec2 bitreverseinterleave16( uvec2 up )
{
	up = ( ( up &     0xff00u ) >> 8u ) | ( ( up &     0x00ffu ) << 16u );
	up = ( ( up &   0xf000f0u ) >> 4u ) | ( ( up &    0xf000fu ) <<  8u );
	up = ( ( up &  0xc0c0c0cu ) >> 2u ) | ( ( up &  0x3030303u ) <<  4u );
	up = ( ( up & 0x22222222u ) >> 1u ) | ( ( up & 0x11111111u ) <<  2u );
	return up;
}

float ditherthres( vec2 p )
{
	uvec2 up = bitreverseinterleave16( uvec2( p ) );
	return float( up.x + 2u * ( up.x ^ up.y ) ) / 4294967296.;
}

bool get_render_ray( vec2 fcoord, inout vec2 uv, inout vec3 cc, inout RayBaserel ray )
{
	if( g_vrmode )
	{
		uv = ( fcoord - unViewport.xy ) / unViewport.zw;
		cc = ( mix( mix( unCorners[0], unCorners[1], uv.x ),
					mix( unCorners[3], unCorners[2], uv.x ), uv.y ) - unCorners[4] ).zxy * vec3( -1, 1, -1 ) * g_vrframe;
		if( dot( cc.yz, cc.yz ) >= 1.55 / GS.camzoom * cc.x * cc.x )
			return false;
		cc.yz /= GS.camzoom;
		cc = normalize( cc );
		g_pixelscale = .25 * abs( cc.x * dFdx( cc.y / cc.x ) * dFdy( cc.z / cc.x ) );
		if( fcoord.x * 2. >= iResolution.x )
			uv.x += SCN_ATM_SUBSAMPLE_RATIO;
		uv.x /= 2.;
		vec3 dp = unCorners[4].zxy * vec3( -1, 1, -1 ) / 1000.;
		ray.obase = g_campos_base;
		ray.orel = GS.campos_baserel + GS.camframe * dp;
		ray.d = GS.camframe * g_vrframe * cc;
	}
	else
	{
		uv = fcoord / iResolution.xy;
		vec2 sc = 2. * g_subsample * uv - 1.;
		if( sc.x >= 1. || sc.y >= 1. )
			return false;
		vec2 ec = sc * vec2( 1, iResolution.y / iResolution.x );
		cc = normalize( vec3( CAM_FOCUS, barrel_distort( vec2( ec.x, -ec.y ) / GS.camzoom, CAM_DISTORT ) ) );
		g_pixelscale = .25 * abs( cc.x * dFdx( cc.y / cc.x ) * dFdy( cc.z / cc.x ) );
		ray.obase = g_campos_base;
		ray.orel = GS.campos_baserel;
		ray.d = GS.camframe * cc;
	}
	return true;
}

void main_image_worker( out vec4 fcolor, in vec2 fcoord )
{
	fcolor = vec4( ZERO, 1. );

#if BUFFER_RUNLEVEL >= 4

	if( iFrame == 0 )
		return;

	GS = gs_load( iChannel0, ADDR_GAME_STATE );
	VS = vs_load( iChannel0, ADDR_VEHICLE_STATE );
	LE = le_load( iChannel0, ADDR_LOCAL_ENV );
	SM = sm_load( iChannel0, ADDR_LOCAL_SM );
	AC = ac_load( iChannel0, ac_addr(1) );
	PD = pd_load( iChannel0, pd_addr(1) );

	g_subsample = gs_get_subsample( GS );

	bool ir = bit_is_set( GS.switches, GS_SW_IRCAM );
	g_ocn_beta50 = irselect( PD.ocn.beta50, ir );
	g_ocn_omega = irselect( PD.ocn.omega, ir );
	g_campos_base = SM.rn * SM.r0;

	vec2 uv = vec2(0);
	vec3 cc = ZERO;
	bool ray_ok = get_render_ray( fcoord, uv, cc, g_ray );
	bool submerged = length( g_ray.obase + g_ray.orel ) < PD.radius;
	ivec2 sc = ivec2( fcoord );

	// feed forward of effective text resolution
	if( sc.x >= ADDR_D_TEXTSCALE && sc.y < 2 )
		fcolor = texelFetch( iChannel1, ivec2( ADDR_B_WAYPOINT_SAMPLE, 0 ), 0 ) / IMG_MIPMAP_HIDE;

	// direct sun visibility and vr flag
	else
	if( sc.x >= ADDR_D_SUN_VISIBILITY && sc.y < 2 )
	{
		vec3 T =
			ac_transmittance( AC, GS.campos, LE.L, true ) *
			texelFetch( iChannel2, ivec2( iChannelResolution[2].xy ) - 1, 0 ).w;
		float shadow =
			trn_shadow_sample( SM, iChannel1, length_normalize( GS.campos ) ).x *
			scene_raycast_object_shadows( Ray( GS.campos, LE.L ) ) *
			atm_planet_shadow( dot( LE.L, normalize( GS.campos ) ), sqrt( max( 0., 1. - LE.radius * LE.radius / dot( GS.campos, GS.campos ) ) ), sqrt( LE.sundisk ) );
		fcolor.xyz = submerged ? ZERO : T * max( 0., 2. * shadow - 1. ) / IMG_MIPMAP_HIDE;
		fcolor.w = float( g_vrmode );
	}

	// feed forward of text formatting data
	else
	if( fcoord.y >= iResolution.y - 2. )
		fcolor = texelFetch( iChannel1, ivec2( fcoord ), 0 ) / IMG_MIPMAP_HIDE;

	// main image
	else
	{
		uint bdisp = bitfield_get_uint( GS.dbg_switches, GS_DBG_BDISP_MASK, GS_DBG_BDISP_SHIFT );
		uint bmode = bitfield_get_uint( GS.dbg_switches, GS_DBG_BMODE_MASK, GS_DBG_BMODE_SHIFT );
		if( bdisp == 0u )
		{
			// terrain map
			if( bit_is_set( GS.switches, GS_SW_TRMAP ) )
				fcolor.xyz = map_display( fcoord );
			else
			if( ray_ok )
			{
				// Normal display
			#if WITH_SCN_RAYCAST_JITTER
				vec2 uv_jittered;
				vec3 cc_jittered;
				get_render_ray( fcoord + ditherthres( fcoord ) - .5, uv_jittered, cc_jittered, g_ray_jittered );
			#else
				g_ray_jittered = g_ray;
			#endif
				vec4 col = render( uv, submerged );
				if( bit_is_unset( GS.switches, GS_SW_TRMAP ) && bit_is_set( GS.switches, GS_SW_NVISN ) )
					hmd_night_vision( col.xyz, g_vrmode ? fcoord.xy - unViewport.xy : fcoord.xy, cc );
				if( g_vrmode )
					col /= GS.camzoom;
				fcolor = clamp( col / max( 1., hmax( col ) / IMG_EXPOSURE_MAX ), 0., IMG_EXPOSURE_MAX );
			}
		}
		else
		switch( bdisp )
		{
		case 1u:
			// Buffer A
			{
				float scale = hmax( floor( iResolution.xy / vec2( ADDR_MAX ).yx ) );
				if( all( lessThan( fcoord, vec2( ADDR_MAX ).yx * scale ) ) )
					fcolor.xyz = saturate( .25 + .125 * texelFetch( iChannel0, ivec2( fcoord / scale ), 0 ).xyz );
			}
			break;
		case 2u:
			// Buffer B
			switch( bmode )
			{
			case 0u:
				// Terrain slope
				vec4 poslod = sm_uv_inverse_lod( SM, sm_fcoord_2_uv( fcoord, trn_box_main( iChannel1 ) ) );
				fcolor.xyz = vec3( poslod != vec4(0) ? sqrt( max( 0., 1. - square( saturate( dot(
					sm_unpack_normal( SM, texelFetch( iChannel1, ivec2( fcoord ), 0 ) ).xyz, normalize( poslod.xyz ) ) ) ) ) ) : 0. );
				break;
			case 1u:
				// Terrain normal XYZ
				if( sm_box_inside( trn_box_main( iChannel1 ), fcoord ) )
					fcolor.xyz = saturate( sm_unpack_normal( SM, texelFetch( iChannel1, ivec2( fcoord ), 0 ) ).xyz * .5 + .5 );
				break;
			case 2u:
				// Zone index / ambient occlusion
				fcolor.xyz = saturate( texelFetch( iChannel1, ivec2( fcoord ), 0 ).zzz / 16. );
				break;
			case 3u:
				// Terrain height
				fcolor.x = texelFetch( iChannel1, ivec2( fcoord ), 0 ).w / PD.radius / PD.trn.slope.x;
				fcolor.xyz = saturate( fcolor.x < 0. ? vec3( .1, .3, .9 ) * ( fcolor.x / PD.trn.levels.x ) :
													   vec3( .9, .3, .1 ) * ( fcolor.x / PD.trn.levels.y ) );
				break;
			case 4u:
				// Shadow umbra
				fcolor.xyz = saturate( ( texelFetch( iChannel1, ivec2( fcoord ), 0 ).xyz / PD.radius - 1. ) / PD.trn.levels.y );
				break;
			case 5u:
				// Text processing
				fcolor.xyz = saturate( texelFetch( iChannel1, ivec2( fcoord.x, fcoord.y / 16. + iResolution.y * 15. / 16. ), 0 ).xyz );
				break;
			}
			break;
		// Buffer C
		case 3u:
			switch( bmode )
			{
			case 0u:
				// Overview
				fcolor.xyz = texelFetch( iChannel2, ivec2( fcoord ), 0 ).xyz;
			#if WITH_ATM_BILATERAL_UPSAMPLE
				if( all( lessThan( fcoord.xy, iResolution.xy / 2. ) ) )
			  #if WITH_ATM_PACKHALF2X16
					fcolor.xz = unpackHalf2x16( floatBitsToUint( fcolor.x ) );
			  #else
					fcolor.xz = exp2( vec2( floor( fcolor.x ) / 128., fract( fcolor.x ) * 32. ) - 24. );
			  #endif
			#endif
				fcolor = saturate( fcolor );
				break;
			case 1u:
				// Atmosphere inscatter (lower left)
				fcolor.xyz = texelFetch( iChannel2, ivec2( fcoord / SCN_ATM_SUBSAMPLE_RATIO ), 0 ).xyz;
			#if WITH_ATM_BILATERAL_UPSAMPLE
			  #if WITH_ATM_PACKHALF2X16
				fcolor.xz = unpackHalf2x16( floatBitsToUint( fcolor.x ) );
			  #else
				fcolor.xz = exp2( vec2( floor( fcolor.x ) / 128., fract( fcolor.x ) * 32. ) - 24. );
			  #endif
			#endif
				break;
			case 2u:
				// Atmosphere reflection (lower right)
				fcolor.xyz = texelFetch( iChannel2, ivec2( fcoord / SCN_ATM_SUBSAMPLE_RATIO + vec2( floor( iResolution.x / 16. ) * 8., 0 ) ), 0 ).xyz;
				break;
			case 3u:
				// Atmosphere skylight (upper left)
				if( fcoord.x / 2. < iResolution.y / 2. )
					fcolor.xyz = texelFetch( iChannel2, ivec2( fcoord / 2. + vec2( 0, iResolution.y / 2. ) ), 0 ).xyz;
				break;
			case 4u:
				// Objects skylight samples
				fcolor.xyz = texelFetch( iChannel2, ivec2( fcoord / SCN_ATM_SUBSAMPLE_RATIO + iResolution.xy / 2. ), 0 ).xyz;
				break;
			}
			break;
		}
	}
#endif // RUNLEVEL
}

void mainImage( out vec4 fcolor, in vec2 fcoord )
	{ main_image_worker( fcolor, fcoord ); }

void mainVR( out vec4 fcolor, in vec2 fcoord, in vec3 _ro_dummy_, in vec3 _rd_dummy_ )
{
	g_vrmode = true;
	vec3 horz = ( unCorners[1] + unCorners[2] - unCorners[0] - unCorners[3] ).zxy * vec3( -1, 1, -1 );
	vec3 down = ( unCorners[0] + unCorners[1] - unCorners[2] - unCorners[3] ).zxy * vec3( -1, 1, -1 );
	vec3 forw = ( unCorners[0] + unCorners[1] + unCorners[2] + unCorners[3] - 4. * unCorners[4] ).zxy * vec3( -1, 1, -1 );
	g_vrframe[1] = normalize( horz );
	g_vrframe[2] = normalize( down );
	g_vrframe[0] = cross( g_vrframe[1], g_vrframe[2] );
	vec3 cent = g_vrframe[0] * dot( forw, g_vrframe[0] ) - 2. * ( unCorners[0] - unCorners[4] ).zxy * vec3( -1, 1, -1 );
	g_vrfocus.xy = vec2( dot( cent, g_vrframe[1] ) / dot( horz, g_vrframe[1] ), dot( cent, g_vrframe[2] ) / dot( -down, g_vrframe[2] ) );
	g_vrfocus.zw = dot( forw, g_vrframe[0] ) / vec2( dot( horz, g_vrframe[1] ), dot( down, g_vrframe[2] ) );
	main_image_worker( fcolor, gl_FragCoord.xy );
}

#define unViewport _unViewport_dummy_
#define unCorners _unCorners_dummy_
