// Buffer C (buffer) — Space Glider 2020 VR by scholarius
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
 * Part 4 of 6: Buffer C shader (atmospheric scattering)
 * This software comes with no warranty. Use it at your own risk.
 * v 45
 */

// ----------------------------------------------------------------------------

#if WITH_ATM_TWEAKS
const float TWEAK1 = .25;
const float TWEAK2 = 4.;
const float TWEAK3 = .5;
const float TWEAK4 = .25;
const float TWEAK5 = .25;
const float TWEAK6 = .25;
const float TWEAK7 = 32.;
const float TWEAK8 = .25;
#else
const float TWEAK1 = .5;
const float TWEAK2 = 6.;
const float TWEAK3 = .7;
const float TWEAK4 = .5;
const float TWEAK5 = .25;	// 0.125
const float TWEAK6 = .125;
const float TWEAK7 = 48.;
const float TWEAK8 = .5;
#endif

GameState GS;
LocalEnv LE;
SphereMap SM;
AtmContext AC;
PlanetData PD;
GameStateAux GSX;

float g_subsample = 1.;
float g_pixelscale = 1.;
bool g_vrmode = false;
mat3 g_vrframe = mat3(0);
vec3 g_campos_base = ZERO;

uniform vec4 unViewport;
uniform vec3 unCorners[5];

// ----------------------------------------------------------------------------
// CLOUD NOISE SHAPE
// ----------------------------------------------------------------------------

const float ATM_CLOUD_DENS_BIAS = -0.0005;
const float ATM_CLOUD_MAX_BETA = -log( 1. + ATM_CLOUD_DENS_BIAS );

float cld_alt = 0.;
float cld_k50max = 0.;
float cld_g = 0.;
float cld_f = 0.;
vec4  cld_noise = vec4(0);
vec2  cld_size = vec2(0);
vec3  cld_fluff = ZERO;
vec4  cld_move = vec4(0);

mat2 cld_fluff_rot = mat2(1);

#if WITH_CLOUDS
float atm_cloudnoise1( vec4 r, bool lowfreq )
{
	float lod = log2( r.w );
	float y = ( textureLod( iChannel3, r.xyz / 32., lod ).x + 2. * textureLod( iChannel3, r.xyz / 64., lod - 1. ).x ) / 3.;
	if( !lowfreq )
		y = 4. / 5. * y + ( textureLod( iChannel3, r.xyz / 8., lod + 2. ).x + 2. * textureLod( iChannel3, r.xyz / 16., lod + 1. ).x ) / 15.;
	return y;
}
vec3 atm_cloudnoise1_offs( vec4 r, bool lowfreq )
{
	float lod = log2( r.w );
	const vec2 offs = vec2( 1, 0 );
	vec3 offs_y = vec3(
		textureLod( iChannel3, ( r.xyz + offs.xyy ) / 32., lod ).x + 2. * textureLod( iChannel3, ( r.xyz + offs.xyy ) / 64., lod - 1. ).x,
		textureLod( iChannel3, ( r.xyz + offs.yxy ) / 32., lod ).x + 2. * textureLod( iChannel3, ( r.xyz + offs.yxy ) / 64., lod - 1. ).x,
		textureLod( iChannel3, ( r.xyz + offs.yyx ) / 32., lod ).x + 2. * textureLod( iChannel3, ( r.xyz + offs.yyx ) / 64., lod - 1. ).x ) / 3.;
	if( !lowfreq )
		offs_y = 4. / 5. * offs_y + vec3(
			textureLod( iChannel3, ( r.xyz + offs.xyy ) / 8., lod + 2. ).x + 2. * textureLod( iChannel3, ( r.xyz + offs.xyy ) / 16., lod + 1. ).x,
			textureLod( iChannel3, ( r.xyz + offs.yxy ) / 8., lod + 2. ).x + 2. * textureLod( iChannel3, ( r.xyz + offs.yxy ) / 16., lod + 1. ).x,
			textureLod( iChannel3, ( r.xyz + offs.yyx ) / 8., lod + 2. ).x + 2. * textureLod( iChannel3, ( r.xyz + offs.yyx ) / 16., lod + 1. ).x ) / 15.;
	return offs_y;
}
float atm_cloudnoise2( vec4 r, bool lowfreq )
{
	float lod = log2( r.w );
	float y = textureLod( iChannel3, r.xyz / 64., lod - 1. ).x;
	if( !lowfreq )
		y = 2. / 3. * y + textureLod( iChannel3, r.xyz / 32., lod ).x / 3.;
	return y;
}
vec3 atm_cloudnoise2_offs( vec4 r, bool lowfreq )
{
	float lod = log2( r.w );
	const vec2 offs = vec2( 1, 0 );
	vec3 offs_y = vec3(
		textureLod( iChannel3, ( r.xyz + offs.xyy ) / 64., lod - 1. ).x,
		textureLod( iChannel3, ( r.xyz + offs.yxy ) / 64., lod - 1. ).x,
		textureLod( iChannel3, ( r.xyz + offs.yyx ) / 64., lod - 1. ).x );
	if( !lowfreq )
	{
		offs_y = 2. / 3. * offs_y + vec3(
			textureLod( iChannel3, ( r.xyz + offs.xyy ) / 32., lod ).x,
			textureLod( iChannel3, ( r.xyz + offs.yxy ) / 32., lod ).x,
			textureLod( iChannel3, ( r.xyz + offs.yyx ) / 32., lod ).x ) / 3.;
	}
	return offs_y;
}
vec4 atm_cloudnoise1_d( vec4 r, float scale, bool lowfreq )
{
	float invscale = 1. / scale;
	float y = atm_cloudnoise1( invscale * r, lowfreq );
	return vec4( invscale * ( atm_cloudnoise1_offs( invscale * r, lowfreq ) - y ), y );
}
vec4 atm_cloudnoise2_d( vec4 r, float scale, bool lowfreq )
{
	float invscale = 1. / scale;
	float y = atm_cloudnoise2( invscale * r, lowfreq );
	return vec4( invscale * ( atm_cloudnoise2_offs( invscale * r, lowfreq ) - y ), y );
}

vec4 atm_cloudbeta_d( vec4 r, bool lowfreq )
{
	vec4 rn = length_normalize( r.xyz );
	vec4 h = rn - const_d( AC.r0 ) - const_d( cld_alt );
	vec4 fluff = mix_d( const_d( cld_fluff.x ), const_d( cld_fluff.y ), saturate_d( h / cld_fluff.z ) );
	vec3 y = rn.xyz;
	y.xy = ( y.xy /* + 0. * cld_move.z * GS.timer */ ) * cld_fluff_rot;
	float sin2lat = rn.z * rn.z * 2. - 1.;
	float sin3lat = sin2lat * rn.z * 2. - rn.z;
	vec3 x = vec3( rn.xy, sin3lat / 3. + cld_move.y * GS.timer + cld_move.x );
	vec4 n1 = atm_cloudnoise1_d( vec4( PD.radius * x, r.w ), cld_size.x, lowfreq );
	vec4 n2 = atm_cloudnoise2_d( vec4( PD.radius * y, r.w ), cld_size.y, lowfreq );
	vec4 c = + const_d( cld_noise.x )
			 + const_d( cld_noise.y * sin3lat * sin3lat )
			 + cld_noise.z * n1
			 - 6. * sqrt_d( ONE_D + square_d( cld_noise.w * h / 6. ) )
			 + mul_d( fluff, n2 * 2. - ONE_D );
	return min_d( const_d( ATM_CLOUD_MAX_BETA ), c );
}

float cld_tau50( vec4 x, vec4 dx, float tau50limit, bool lowfreq )
{
	vec4 dxdu = dx / length( dx.xyz );
	float tau50 = 0.;
	float beta = atm_cloudbeta_d( x, lowfreq ).w;
	float dens = exp2pp( LOG2E * beta );
	float betachange = 1. / cld_noise.w;
	for( int i = 0, n = ATM_CLOUD_MAX_ITER; i < n; ++i )
	{
		float du = TWEAK3 * atm_dulimit( TWEAK4, betachange, cld_k50max * dens );
		du = du * min( TWEAK7, 1. + tau50 * tau50 / 8. );
		du = max( 0.005, du );
		x += du * dxdu;
		float betanext = atm_cloudbeta_d( x, lowfreq ).w;
		float densnext = exp2pp( LOG2E * betanext );
		tau50 += cld_k50max * max( 0., mix( dens, densnext, .5 ) + ATM_CLOUD_DENS_BIAS ) * du;
		betachange = du / max( du * ( TWEAK5 * cld_noise.w ), abs( betanext - beta ) );
		beta = betanext;
		dens = densnext;
		if( tau50 >= tau50limit )
			break;
		float alt = length( x.xyz );
		if( dot( x.xyz, dxdu.xyz ) >= 0. && alt >= PD.radius * ( 1. + PD.trn.levels.y * PD.trn.slope.x ) )
			break;
		if( dot( x.xyz, dxdu.xyz ) < 0. && alt < PD.radius * ( 1. + PD.trn.levels.x * PD.trn.slope.x ) )
			break;
	}
	return tau50;
}
#endif

// ----------------------------------------------------------------------------
// ATMOSPHERE MODEL
// ----------------------------------------------------------------------------

struct AtmQuadraturePoint
{
	float coschi;			// light zenith angle
	float dens;				// density relative to reference
	float amtl;				// airmass towards lightsource (sun)
  #if WITH_ATM_LAYER_G
	float densg;			// same for ground layer
	float amtlg;
  #endif
  #if WITH_ATM_LAYER_A
	float densa;			// same for absorbtion layer
	float amtla;
  #endif
  #if WITH_ATM_LAYER_E
	float dense;			// same for emission layer
  #endif
	float shadow;			// amount of terrain shadowing
	float h50;
  #if WITH_ATM_AMTL_CORRECTION
	float cosbeta;
  #endif
};

float eval_gaussian50( float x, vec3 shape )
	{ return shape.y * exp2pp( -shape.z * square( x - shape.x ) ); }

AtmQuadraturePoint atm_quadrature_point( vec3 x, vec3 L, vec3 dxn )
{
	AtmQuadraturePoint result;
	vec4 xn = length_normalize(x);
	float x50 = xn.w * AC.invH50;
	float h50 = x50 - AC.X50;
	result.coschi = dot( xn.xyz, L );
#if WITH_ATMOSPHERE
	result.dens = exp2pp( -h50 );
	float s = AC.X50 / x50;
	float c = sqrt( max( 0., 1. - s * s ) );
	float planetshadow = atm_planet_shadow( result.coschi, c, sqrt( LE.sundisk ) );
	result.amtl = planetshadow >= 0.003 ? atm_chapman50_h( AC.X50, h50, result.coschi ) : 1e6;
  #if WITH_ATM_LAYER_G
	result.densg = AC.glayer_scale * exp2pp( -h50 * AC.glayer_scale );
	result.amtlg = planetshadow >= 0.003 ? atm_chapman50_h( AC.X50 * AC.glayer_scale, h50 * AC.glayer_scale, result.coschi ) : 1e6;
  #endif
  #if WITH_ATM_LAYER_A
	result.densa = eval_gaussian50( h50, AC.alayer_shape );
	result.amtla = ac_airmass_layer_a( AC, x * AC.invH50, L );
  #endif
  #if WITH_ATM_LAYER_E
	result.dense = eval_gaussian50( h50, AC.elayer_shape );
  #endif
	result.shadow = planetshadow * trn_shadow_sample( SM, iChannel1, xn ).x;
	result.h50 = h50;
  #if WITH_ATM_AMTL_CORRECTION
	result.cosbeta = c;
  #endif
#else
	result.dens = 0.;
	result.shadow = 1.;
#endif
	return result;
}

AtmQuadraturePoint atm_quadrature_mix( AtmQuadraturePoint a, AtmQuadraturePoint b,
									   float t )
{
	AtmQuadraturePoint result;
	result.coschi = mix( a.coschi, b.coschi, t );
	result.dens = mix( a.dens, b.dens, t );
	result.amtl = mix( a.amtl, b.amtl, t );
  #if WITH_ATM_LAYER_G
	result.densg = mix( a.densg, b.densg, t );
	result.amtlg = mix( a.amtlg, b.amtlg, t );
  #endif
  #if WITH_ATM_LAYER_A
	result.densa = mix( a.densa, b.densa, t );
	result.amtla = mix( a.amtla, b.amtla, t );
  #endif
  #if WITH_ATM_LAYER_E
	result.dense = mix( a.dense, b.dense, t );
  #endif
	result.shadow = mix( a.shadow, b.shadow, t );
	result.h50 = mix( a.h50, b.h50, t );
  #if WITH_ATM_AMTL_CORRECTION
	result.cosbeta = mix( a.cosbeta, b.cosbeta, t );
  #endif
	return result;
}

struct AtmQuadratureSegment
{
	vec3 mu0;				// cosine of light incidence angle
	vec3 omega0;			// local single-scattering albedo
	vec3 k50;				// half-value extinction efficiency
	vec3 tau50;				// half-value optical depth
	vec3 T;					// transmittance
	vec3 TL;				// transmittance in light direction
	vec3 TZ;				// transmittance in zenith direction
	vec3 TZs;				// transmittance in zenith direction, diffusion-scaled
	vec3 Is;				// illumination by the sun (direct)
	vec3 Im;				// illumination by the sky (indirect) and multi-scattering
	vec3 Ie;				// emission
#if WITH_CLOUDS
	vec3 skylight;			// analytical skylight estimate
#endif
};

vec3 atm_airmass_to_light( AtmQuadraturePoint avg )
{
	vec3 amtl = AC.k50 * avg.amtl;
  #if WITH_ATM_LAYER_G
	amtl += AC.glayer_k50 * ( avg.amtlg - avg.amtl );
  #endif
  #if WITH_ATM_LAYER_A
	amtl += AC.alayer_k50 * ( avg.amtla - avg.amtl );
  #endif
  #if WITH_ATM_AMTL_CORRECTION
	amtl *= atm_airmass_correction( AC.X50, avg.cosbeta + avg.coschi, ATM_AMTL_CORRECTION );
  #endif
	return amtl;
}

AtmQuadratureSegment atm_quadrature_segment( AtmQuadraturePoint avg,
											 float du,
											 float rayleigh_phase,
											 float aerosol_phase,
											 bool infinite )
{
	AtmQuadratureSegment result;
	vec3 mu_stretch = AC.mu_stretch * mix( 1.25, 1., saturate( avg.h50 ) );
	result.mu0 = log2( 1. + exp2pp( mu_stretch * avg.coschi ) ) / mu_stretch;
#if WITH_ATMOSPHERE
	vec3 k50 = AC.k50 * avg.dens;
	vec3 k50_s = AC.k50_s * avg.dens;
  #if WITH_ATM_LAYER_G
	k50 += ( avg.densg - avg.dens ) * AC.glayer_k50;
	k50_s += ( avg.densg - avg.dens ) * AC.glayer_k50_s;
  #endif
  #if WITH_ATM_LAYER_A
	k50 += ( avg.densa - avg.dens ) * AC.alayer_k50;
  #endif
	result.omega0 = k50_s / k50;
	result.k50 = k50;
	result.tau50 = result.k50 * du;
	result.T = exp2pp( -result.tau50 );
	result.TL = exp2pp( -AC.H * atm_airmass_to_light( avg ) );
	result.TZ = exp2pp( -AC.tau50 * avg.dens );
	result.TZs = exp2pp( -AC.tau50s * avg.dens );
	result.Is = result.omega0 / 4.;
  #if WITH_ATM_LAYER_G
	result.Is += avg.dens * ( AC.k50_s - AC.glayer_k50_s ) * ( rayleigh_phase - 1. ) / ( 4. * k50 );
	result.Is += avg.densg * AC.glayer_k50_s * ( aerosol_phase - 1. ) / ( 4. * k50 );
  #endif
	result.Is *= result.TL * LE.sunlight * avg.shadow;
	result.Im = result.TZ * ( LE.starlight + AC.elayer_emiss );
	result.Im += result.TZs * ( 1. - pow( result.TL, vec3(.5+.5*AC.g) ) ) * LE.sunlight  * result.mu0 * AC.omega0;
	result.Im += result.TZs * ( 1. - pow( result.TZ, vec3(.5+.5*AC.g) ) ) * ( LE.starlight + AC.elayer_emiss );
	result.Im *= result.omega0;
	result.Ie = ZERO;
  #if WITH_ATM_LAYER_E
	result.Ie += AC.elayer_emiss * avg.dense * AC.invH50 / k50;
  #endif
#else
	result.k50 = ZERO;
	result.tau50 = ZERO;
	result.T = ONE;
	result.TL = ONE;
	result.TZ = ONE;
	result.TZs = ONE;
	result.Is = ZERO;
	result.Im = ZERO;
	result.Ie = ZERO;
#endif
#if WITH_CLOUDS
	vec3 ht = AC.ht0s50 + AC.X50 * avg.coschi * min( 0., avg.coschi ) / 2.;
	result.skylight = ( result.TZ * LE.sunlight * exp2pp( -ht ) * AC.omega0 / 4. + result.Im * 2. ) * ( 1. - result.TZ );
	result.skylight += ( LE.starlight + AC.elayer_emiss ) * result.TZs;
#endif
	return result;
}

#if WITH_CLOUDS
struct CldQuadraturePoint
{
	vec4 beta;				// log2 relative density, xyz = gradients
	float dens;				// relative density
	float tau50L;			// optical half-value depth in light direction
	float tau50Z;			// optical half-value depth in zenith direction
};

CldQuadraturePoint cld_quadrature_point( vec4 x, vec3 L, float coschi )
{
	CldQuadraturePoint result;
	result.beta = atm_cloudbeta_d( x, false );
	result.dens = exp2pp( LOG2E * result.beta.w );
	float taulimit = mix( ATM_CLOUD_SHADOW_MIN_TAU, ATM_CLOUD_SHADOW_MAX_TAU, coschi );
	vec3 xn = normalize( x.xyz );
	vec3 Lc = normalize( reject_min( L, xn ) );
	vec3 Z = normalize( L + xn );
	result.tau50L = cld_tau50( x, vec4( Lc, sqrt( LE.sundisk ) ), taulimit, false );
	result.tau50Z = cld_tau50( x, vec4( Z, 4. ), ATM_CLOUD_SHADOW_MIN_TAU, false );
	return result;
}

CldQuadraturePoint cld_quadrature_mix( CldQuadraturePoint a,
									   CldQuadraturePoint b, float t )
{
	CldQuadraturePoint result;
	result.beta = mix( a.beta, b.beta, t );
	result.dens = mix( a.dens, b.dens, t );
	result.tau50L = mix( a.tau50L, b.tau50L, t );
	result.tau50Z = mix( a.tau50Z, b.tau50Z, t );
	return result;
}

struct CldQuadratureSegment
{
	float k50s;				// half-value extinction efficiency, delta-scaled
	float tau50s;			// half-value optical depth, delta-scaled
	float Ts;				// segment transmittance, delta-scaled
	float TL;				// transmittance in light direction
	float TLs;				// same, delta-scaled
	float TZs;				// transmittance in zenith direction, delta scaled
	float FminusL;			// Eddington downwelling flux component for direct sunlight
	float FminusZ;			// Eddington downwelling flux component for diffuse skylight
	vec3 Is;				// illumination by the sun (direct)
	vec3 Ii;				// illumination by the sky (indirect)
	vec3 Im;				// illumination by multi scattering
};

CldQuadratureSegment cld_quadrature_segment( CldQuadraturePoint avg,
											 AtmQuadraturePoint atmavg,
											 AtmQuadratureSegment atmseg,
											 vec3 L,
											 vec3 V,
											 float du,
											 float cloud_phase )
{
	CldQuadratureSegment result;
	result.k50s = cld_k50max * max( 0., avg.dens + ATM_CLOUD_DENS_BIAS ) * ( 1. - cld_f );
	result.tau50s = result.k50s * du;
	result.Ts = exp2pp( -result.tau50s );
	result.TL = exp2pp( -avg.tau50L );
	result.TLs = exp2pp( -avg.tau50L * ( 1. - cld_f ) );
	result.TZs = exp2pp( -avg.tau50Z * ( 1. - cld_f ) );
	result.FminusL = atm_delta_eddington_Fminus_direct( cld_g, avg.tau50L, atmseg.mu0.y );
	result.FminusZ = atm_delta_eddington_Fminus_diffuse( cld_g, avg.tau50Z );
	vec3 N = softnormalize( -avg.beta.xyz, 1. / cld_noise.w );
	float H = .5 + 1. * mu_stretch( -dot( N, V ), .125 );
	vec3 mu0 = vec3( mu_stretch( dot( N, L ), .125 ) );
	mu0 = mix( atmseg.mu0, mu0, .5 );
	result.Is = atmseg.TL * LE.sunlight * atmavg.shadow * result.TL * cloud_phase / 4.;
	result.Im = H * atmseg.TL * LE.sunlight * atmavg.shadow * result.FminusL * mu0;
	result.Ii = H * atmseg.skylight * result.FminusZ;
	if( bit_is_set( GS.switches, GS_SW_IRCAM ) )
	{
		result.Is *= 0.85;
		result.Im *= 0.85;
		result.Ii *= 0.85;
	}
	return result;
}

vec3 cld_atm_interaction( inout AtmQuadratureSegment atmseg,
						  AtmQuadraturePoint atmavg,
						  CldQuadratureSegment cldseg,
						  float coschi )
{
	vec3 illum = atmseg.omega0 * ( cldseg.Is + cldseg.Im + cldseg.Ii ) / 2.;
	atmseg.Is = mix( illum, atmseg.Is, cldseg.TLs );
	atmseg.Im = atmseg.Im * cldseg.TZs;
	return cldseg.k50s / ( atmseg.k50 + cldseg.k50s );
}

float cld_betachange( CldQuadraturePoint a, CldQuadraturePoint b, float du )
	{ return du / max( du * ( TWEAK5 * cld_noise.w ), b.beta.w - a.beta.w ); }

#endif // WITH_CLOUDS


float phase_hg( float g, float mu )
	{ return ( 1. - g * g ) * inversesqrt( cube( 1. + g * g - 2. * g * mu ) ); }

float phase_p( float n, float mu )
	{ return 2. / ( LN2 * ( n + 1. ) * ( 1. + exp2(-n) - mu ) ); }

float phase_e( float n, float mu )
	{ return LN2 * n * exp2( ( mu - 1. ) * n / 2. ); }

float phase_f( float n, float mu )
	{ return mix( phase_p( n, mu ), phase_e( n + 1., mu ), .5 ); }

float atm_compute_scatter( inout vec3 T, inout vec3 I,
						   vec4 x0, vec4 dx,
						   bool infinite,
						   bool low_aerosol_phase,
						   bool low_cloud_phase )
{
	vec4 dxn = length_normalize( dx.xyz );
	vec4 dxdu = dx / dxn.w;
	vec2 sph = sphere_impact( x0.xyz, dxn.xyz );
	float R = AC.r0 + AC.htop;
	if( R * R < sph.x )
		return 1.;
	vec2 limits = max( vec2(0), sphere_limits( R, sph ) );
	if( !infinite )
		limits = min( vec2( dxn.w ), limits );
	float urange = limits.y - limits.x;
	if( urange < .001 )
		return 1.;

	// TODO: vary water vapor content based on local temperature

	/*
	{
		vec4 rn = length_normalize( x0.xyz + max( 0., sph.y ) * dxdu.xyz );
		vec3 rnxy = length_normalize( rn.xy );
		vec3 psrn = normalize( g_ps.r );
		vec3 pshn = normalize( cross( g_ps.r, g_ps.v ) );
		vec3 pshB = normalize( reject( g_ps.B[2], pshn ) );
		vec2 Lnxy = normalize( ( -g_ps.r * g_ps.B ).xy );
		vec2 lphase = vec2( rnxy.z, rn.z );
		vec2 sphase = vec2( dot( pshB, psrn ), dot( pshB, pshn ) );
		vec3 lvar = PD.atm_profile.lvar + PD.atm_profile.svar * sphase;
		float dT_l = dot( lvar.xy, lphase ) + lvar.z;
		float T = PD.atm_profile.ref.x + dT_l;
	}
	*/

	float u = limits.x;
	vec4 x = x0 + u * dxdu;
	AtmQuadraturePoint atm1 = atm_quadrature_point( x.xyz, LE.L, dxn.xyz );
	bool ir = bit_is_set( GS.switches, GS_SW_IRCAM );
	float mu_L = dot( dxn.xyz, LE.L );
	float rayleigh_phase = .75 * ( 1. + mu_L * mu_L );
	float aerosol_phase = low_aerosol_phase ? 1. : min( ATM_CLOUD_SHADOW_MIN_TAU, phase_f( ir ? 5. : 6.5, mu_L ) );
#if WITH_CLOUDS
	CldQuadraturePoint cld1 = cld_quadrature_point( x, LE.L, atm1.coschi );
	float cloud_phase = low_cloud_phase ? 1. : min( ATM_CLOUD_SHADOW_MIN_TAU, phase_f( ir ? 14. : 18., mu_L ) );
	float betachange = 1. / cld_noise.w;
#endif
	float dumax = urange / float( ATM_SCATTER_MIN_ITER );
	float CT50s = 0.;
	for( int i = 0, n = ATM_SCATTER_MAX_ITER; i < n; ++i )
	{
		float du = dumax;
		du = min( du, TWEAK1 * atm_dulimit( TWEAK2, AC.H, AC.k50max * atm1.dens ) );
	#if WITH_CLOUDS
		du = min( du, TWEAK3 * atm_dulimit( TWEAK4, betachange, cld_k50max * cld1.dens ) );
	#endif
		du = min( dumax, du / max( TWEAK6, T.y ) );
		du = min( max( 0.003, du ), limits.y - u );
		float unext = u + du;
		vec4 xnext = x0 + unext * dxdu;
		AtmQuadraturePoint atm2 = atm_quadrature_point( xnext.xyz, LE.L, dxn.xyz );
	  #if WITH_ATM_TRAPEZ_QUADRATURE
		AtmQuadraturePoint atmavg = atm_quadrature_mix( atm1, atm2, .5 );
	  #else
		AtmQuadraturePoint atmavg = atm2;
	  #endif
		AtmQuadratureSegment atmseg = atm_quadrature_segment( atmavg, du, rayleigh_phase, aerosol_phase, infinite );
		atm1 = atm2;
	#if WITH_CLOUDS
		CldQuadraturePoint cld2 = cld_quadrature_point( xnext, LE.L, atm2.coschi );
	  #if WITH_ATM_TRAPEZ_QUADRATURE
		CldQuadraturePoint cldavg = cld_quadrature_mix( cld1, cld2, .5 );
	  #else
		CldQuadraturePoint cldavg = cld2;
	  #endif
		CldQuadratureSegment cldseg = cld_quadrature_segment( cldavg, atmavg, atmseg, LE.L, dxdu.xyz, du, cloud_phase );
		vec3 cloud_mix = cld_atm_interaction( atmseg, atmavg, cldseg, atmavg.coschi );
		vec3 segment_I = mix( atmseg.Is + atmseg.Im + atmseg.Ie, cldseg.Is + cldseg.Im + cldseg.Ii, cloud_mix );
		vec3 segment_T = atmseg.T * cldseg.Ts;
		vec3 segment_tau50 = atmseg.tau50 + cldseg.tau50s;
		CT50s += cldseg.tau50s;
		betachange = cld_betachange( cld1, cld2, du );
		cld1 = cld2;
	#else
		vec3 segment_I = atmseg.Is + atmseg.Im + atmseg.Ie;
		vec3 segment_T = atmseg.T;
		vec3 segment_tau50 = atmseg.tau50;
	#endif
		segment_I *= mix( 1. - segment_T, LN2 * segment_tau50, lessThan( segment_tau50, vec3( FRACT_1_4096 ) ) );
		I = I + T * segment_I;
		T = T * segment_T;
		u = unext;
		if( u >= limits.y )
			break;
		x = xnext;
		if( CT50s >= ATM_CLOUD_TAU50_CUTOFF )
			break;
		// debug:
		// float value = float( i - ATM_SCATTER_MIN_ITER ) / float( ATM_SCATTER_MAX_ITER - ATM_SCATTER_MIN_ITER );
		// float value = betachange;
		// float value = log2(35.*du)/10.;
		// float value = u / limits.y;
		// float value = CT50s / 1.;
		// I = mix( vec3(0,0,1), vec3(1,0,0), saturate( value ) );
		// vec3 value = T;
		// vec3 value = segment_T;
		// vec3 value = atm_transmittance( x0, dxn.xyz );
		// vec3 value = T / atm_transmittance( x0, dxn.xyz );
		// vec3 value = 1. - T;
		// vec3 value = atmseg.TL;
		// I = value;
		// if( i == -1 )
		//	 break;
	}

	float Tc = clamp( ( exp2pp( -CT50s ) - ATM_CLOUD_T_CUTOFF ) / ( 1. - ATM_CLOUD_T_CUTOFF ), 0., 1. );

	/*
	float K = .7 * fwidth( CT50s * LN2 );
	I.r *= 1. - aaa_interval( K, CT50s * LN2 - 1., K );
	I.rg *= 1. - aaa_interval( K, CT50s * LN2 - 3., K );
	I.rgb *= 1. - aaa_interval( K, CT50s * LN2 - 10., K );
	//*/

	return Tc;
}

// ----------------------------------------------------------------------------
// SCENE
// ----------------------------------------------------------------------------

vec4 texturenoise( vec3 r )
{
	vec3 uvw = r / iChannelResolution[3];
	return texture( iChannel3, uvw ) * 2. - 1.;
}

vec4 texturenoiseLod( vec3 r, float lod )
{
	vec3 uvw = r / iChannelResolution[3];
	return textureLod( iChannel3, uvw, lod ) * 2. - 1.;
}

vec3 trn_ripplemap( vec3 pos )
{
	return .20 * texturenoise( pos / .01 ).xyz +
		   .30 * texturenoise( pos / .003 ).xyz +
		   .30 * texturenoise( pos / .001 ).xyz +
		   .20 * texturenoise( pos / .0003 ).xyz;
}

vec3 trn_ripplemapLod( vec3 pos, float scale )
{
	float lod = log2( scale / 0.001 );
	return .20 * texturenoiseLod( pos / .01, lod - 3.322 ).xyz +
		   .30 * texturenoiseLod( pos / .003, lod - 1.585 ).xyz +
		   .30 * texturenoiseLod( pos / .001, lod ).xyz +
		   .20 * texturenoiseLod( pos / .0003, lod + 1.585 ).xyz;
}

vec3 ndist( vec3 Z, float k, vec3 dZ )
{
	float b = dot( Z, dZ );
	return normalize( Z * square( 1. - k + k * b ) + k * ( dZ - Z * b ) );
}

float scene_raycast_terrain( Ray _ray, float wlevel,
							 inout float t0, inout vec3 _r, int mode, vec2 limits )
{
	_ray.o = GS.campos_baserel;
	bool submerged = length( _ray.o + g_campos_base ) - PD.radius < wlevel;
	float t = limits.x, h = 0., alt = 0.;
	float lasth = 0., lastt = 0., lasta = 0.;
	vec4 tsmpl = vec4(0);
	for( int i = 0, n = SCN_RAYCAST_MAX_ITER; i < n; ++i )
	{
		_r = _ray.o + t * _ray.d;
		tsmpl = trn_sample_baserel( SM, iChannel1, g_campos_base, _r );
		lasta = alt;
		alt = sumdifflen( g_campos_base, _r ) + FORCE_EVAL( SM.r0 - PD.radius );
		lasth = h;
		h = alt - ( submerged ? tsmpl.w : max( wlevel, tsmpl.w ) );
		if( h < 0. )
		{
			t = mix( lastt, t, safediv( 0. - lasth, h - lasth ) );
			_r = _ray.o + t * _ray.d;
			return t;
		}
		else
		if( submerged && alt >= wlevel )
		{
			if( t0 > 0. )
				break;
			t = mix( lastt, t, safediv( wlevel - lasta, alt - lasta ) );
			_r = _ray.o + t * _ray.d;
			vec3 Z = normalize( _r + g_campos_base );
			vec3 N = ndist( Z, 1.5 * PD.ocn.paramsA.z, trn_ripplemap( _r + g_campos_base + 0.002 * iTime * Z ) );
			if( mode == 1 )
			{
				_r = normalize( simple_refract( _ray.d, N ) ) - g_campos_base; // !
				break;
			}
			_ray.d = normalize( _ray.d - 2. * N * dot( _ray.d, N ) );
			_ray.d = normalize( _ray.d - Z * max( 0., dot( _ray.d, Z ) ) );
			_ray.o = _r;
			t0 = t;
			t = 0.;
			alt = wlevel;
			h = wlevel - trn_sample_n( SM, iChannel1, Z ).w;
		}
		lastt = t;
		t += max( TRN_SAFE_SLOPE_FACTOR * ( 1. + .25 * dot( tsmpl.xyz, _ray.d ) ) * h, SCN_RAYCAST_MIN_ADVANCE + SCN_RAYCAST_MIN_ADVANCE_SCALE * t );
		if( t >= limits.y )
		{
			t = SCN_ZFAR;
			break;
		}
	}
	return SCN_ZFAR;
}

// ----------------------------------------------------------------------------
// MAIN
// ----------------------------------------------------------------------------

const int MODE_NONE	 =			0;
const int MODE_INSCATTER =		1;		// trace inscatter ray along view direction
const int MODE_SKYLIGHT =		2;		// trace skylight sample for a terrain position
const int MODE_REFLECTION =		3;		// trace ocean reflection sample from view hitpoint
const int MODE_OBJECTS =		4;		// trace inscatter and skylight for scene objects
const int MODE_PRESERVE =		99;		// preserve previous value (do not overwrite)

struct RenderParams
{
	int mode;
	vec4 x0;
	vec4 dx;
	float scale;
	bool infinite;
	bool low_aerosol_phase;
	bool low_cloud_phase;
	float t;
};

RenderParams get_render_params( Ray ray, int mode, vec2 fcoord )
{
	RenderParams result = RenderParams( MODE_NONE, vec4(0), vec4(0), 1., true, false, false, 0. );
	float r0 = PD.radius;
	float lod = sqrt( g_pixelscale ) * 2.;

	if( mode == MODE_OBJECTS )
	{
		if( fcoord.y >= iResolution.y - 8. )
		{
			vec3 r = GS.campos;
			vec3 Z = normalize(r);
			vec3 sampledir = Z * 4. + LE.L;
			vec3 x = Z * max( r0, length(r) );
			// skylight sample at camera position
			result.mode = MODE_SKYLIGHT;
			result.x0 = vec4( x, lod * length( x - ray.o ) );
			result.dx = vec4( sampledir, 4. );
			result.low_aerosol_phase = true;
			result.low_cloud_phase = true;

		}
		else
		{
			int index = int( fcoord.y ) / 2 - int( iResolution.y ) / 4;
			if( index >= 0 && index < int( memload( iChannel0, ADDR_DATASIZES, 0 ).w ) )
			{
				SceneObj obj = so_load( iChannel0, ADDR_SCENE_OBJECTS + ivec2( index, 0 ) );
				if( int( obj.tybr.x ) >= SCNOBJ_TYPE_3D )
				{
					if( fcoord.x < iResolution.x - 6. )
					{
						// in-scatter towards object position
						result.mode = MODE_INSCATTER;
						result.x0 = vec4( ray.o, 0 );
						result.dx = vec4( obj.r - ray.o, lod * length( obj.r - ray.o ) );
						result.infinite = false;
						result.t = 0.;
					}
					else
					{
						vec3 r = obj.r;
						vec3 Z = normalize(r);
						vec3 sampledir = normalize(
							fcoord.x < iResolution.x - 4. ? Z * .125 + normalize( reject( LE.L, Z ) ) :
							fcoord.x < iResolution.x - 2. ? Z * .125 - normalize( reject( LE.L, Z ) ) :
							Z );

						vec3 x = Z * max( r0, length(r) );
						// skylight sample at object position
						result.mode = MODE_SKYLIGHT;
						result.x0 = vec4( x, length( x - ray.o ) );
						result.dx = vec4( sampledir, 4 );
						result.low_aerosol_phase = true;
						result.low_cloud_phase = true;
					}
				}
			}
		}
	}
	else
	if( mode == MODE_SKYLIGHT )
	{
		vec4 box = atm_box_skylight( iChannel2 );
		vec2 uv = ( fcoord - box.xy ) / box.zw * 2. - 1.;
		vec4 rnlod = sm_uv_inverse_lod_centered_n( SM, uv );
		if( rnlod.w > 0. )
		{
			vec4 tsmpl = sm_unpack_normal( SM, sm_lookup_centered( iChannel1, trn_box_main( iChannel1 ), uv ) );
			vec3 N = normalize( tsmpl.xyz );
			vec3 sampledir = normalize( N * 2. + LE.L );
			vec3 x = rnlod.xyz * ( max( 0., tsmpl.w ) + r0 ); // TODO: max( 0, ... ) nur wenn ozean
			// skylight sample on terrain map
			result.mode = MODE_SKYLIGHT;
			result.x0 = vec4( x, lod * length( x - ray.o ) );
			result.dx = vec4( sampledir, 4 );
			result.scale = .5 + .5 * dot( sampledir, N );
			result.low_aerosol_phase = true;
			result.low_cloud_phase = true;
		}
	}
	else
	if( dot( ray.d, ray.d ) > 0. )
	{
		bool submerged = length( ray.o ) < r0;
		float t = SCN_ZFAR, t0 = 0.;
		vec3 _r = ray.o + t * ray.d - g_campos_base;
		vec2 sph = sphere_impact( ray.o, ray.d );
		float rtop = PD.radius * ( 1. + PD.trn.levels.y * PD.trn.slope.x );
		if( rtop * rtop >= sph.x )
		{
			vec2 limits = max( vec2(0), sphere_limits( rtop, sph ) );
			t = scene_raycast_terrain( ray, 0., t0, _r, mode, limits );
		}
		vec3 r = _r + g_campos_base;
		vec3 Z = normalize(r);
		vec3 V = normalize( -ray.d );
		vec4 tsmpl = trn_sample_n( SM, iChannel1, Z );
		tsmpl.xyz = normalize( tsmpl.xyz );
		float h = tsmpl.w;
		if( mode == MODE_INSCATTER )
		{
			if( t >= SCN_ZFAR )
			{
				// in-scatter along ray direction (terrain miss)
				result.mode = MODE_INSCATTER;
				result.x0 = vec4( submerged ? ray.o + t0 * ray.d : ray.o, 0 );
				result.dx = vec4( submerged ? r : ray.d, lod );
				result.t = t;
			}
			else
			if( !submerged )
			{
				// in-scatter along ray direction (terrain hit)
				result.mode = MODE_INSCATTER;
				result.x0 = vec4( ray.o, 0 );
				result.dx = vec4( r - ray.o, lod * t );
				result.infinite = false;
				result.t = t;
			}
		}
		else
		if( mode == MODE_REFLECTION && !submerged )
		{
			if( t < SCN_ZFAR &&
				bool( max( float( h < 0. ), fwidth( float( h < 0. ) ) ) ) )
			{
				vec3 N = ndist( Z, 1.5 * PD.ocn.paramsA.z, trn_ripplemap( r + 0.002 * iTime * Z ) );
				N = N + .35 * PD.ocn.paramsA.z * ( Z + V ) * parabolstep( 0., .250, t - t * dot( V, Z ) );
				N = normalize( N + V * mu_stretch( -dot( N, V ), .03125 ) );
				vec3 R = 2. * dot( N, V ) * N - V;
				R = normalize( R + Z * mu_stretch( -dot( R, Z ), .03125 ) );
				vec3 H = normalize( R + V );
				float fr = fresnel_schlick( .02, max( 0., dot( R, H ) ) );
				// reflection sample in view direction (ocean hit)
				float inva = .25 / PD.ocn.paramsA.z * inversesqrt( .0003 * inversesqrt( g_pixelscale ) / t + 1. ) ;
				result.mode = MODE_REFLECTION;
				result.x0 = vec4( r, lod * t );
				result.dx = vec4( R, inva );
				result.low_cloud_phase = true;
				result.scale = fr;
			}
		}
	}
	return result;
}

vec4 render( Ray ray, int mode, vec2 fcoord )
{
	RenderParams params = get_render_params( ray, mode, fcoord );
	vec4 result = vec4( ZERO, 1 );

	if( params.x0 == vec4(0) )
		return result;

	vec3 T = ONE, I = ZERO;
#if WITH_ATMOSPHERE
	float Tc = atm_compute_scatter(
		T,
		I,
		params.x0,
		params.dx,
		params.infinite,
		params.low_aerosol_phase,
		params.low_cloud_phase );
#else
	float Tc = 1.;
#endif
	switch( params.mode )
	{
	case MODE_INSCATTER:
		result.xyz = I;
		result.w = Tc;
	#if WITH_ATM_BILATERAL_UPSAMPLE
		if( params.t != 0. )
		{
		#if WITH_ATM_PACKHALF2X16
			result.x = uintBitsToFloat( packHalf2x16( result.xz * ATM_HALF2X16_SCALE ) );
		#else
			result.xz = clamp( result.xz + FRACT_1_16777216, FRACT_1_16777216, 254.617452 );
			result.xz = round( log2( result.xz ) * 128. + 3072. );
			result.x = result.x + result.z / 4096.;
		#endif
			result.z = log2( params.t );
		}
	#endif
		break;
	case MODE_SKYLIGHT:
		result.xyz = I * params.scale + T * LE.starlight;
	#if WITH_CLOUDS
		result.w = clamp( ( exp2pp( -cld_tau50( params.x0, vec4( LE.L, sqrt( LE.sundisk ) ), ATM_CLOUD_SHADOW_MIN_TAU, false ) * ( 1. - cld_f ) ) - ATM_CLOUD_T_CUTOFF ) / ( 1. - ATM_CLOUD_T_CUTOFF ), 0., 1. );
	#endif
		break;
	case MODE_REFLECTION:
		result.xyz = ( I + T * LE.starlight ) * params.scale;
		result.w = params.scale;
		break;
	}

	return result;
}

int get_render_mode( vec2 fcoord, inout vec2 sc )
{
	vec2 halfres = floor( iResolution.xy / 2. );
	int mode = MODE_NONE;
	bool shadowupdate = bit_is_set( GSX.stateflags, GSX_SF_SHADOWUPDATE );
	bool irchange = bit_is_set( GS.switches ^ GSX.switches_last, GS_SW_IRCAM );

#if WITH_ATMOSPHERE
	if( fcoord.y < halfres.y )
	{
		vec2 uv = g_vrmode ? ( fcoord - unViewport.xy ) / unViewport.zw : fcoord / iResolution.xy;
		if( uv.x < .5 )
		{
			sc = 2. * SCN_ATM_SUBSAMPLE_RATIO * g_subsample * uv - 1.;
			mode = MODE_INSCATTER;
		}
		else
		{
			uv.x -= .5;
			sc = 2. * SCN_ATM_SUBSAMPLE_RATIO * g_subsample * uv - 1.;
			mode = MODE_REFLECTION;
		}
	}
	else
	if( fcoord.x < halfres.y )
		mode = ( shadowupdate || irchange ) ? MODE_SKYLIGHT : MODE_PRESERVE;
	else
#endif
#if WITH_OBJECTS
	if( fcoord.x >= iResolution.x - 8. )
		mode = MODE_OBJECTS;
	else
#endif
	if( false )
		;
	return mode;
}

bool get_render_ray( int mode, vec2 sc, inout Ray ray )
{
	if( g_vrmode )
	{
		vec2 subframe_uv = ( sc + 1. ) / ( 2. * g_subsample );
		vec3 cc = ( mix( mix( unCorners[0], unCorners[1], subframe_uv.x ),
						 mix( unCorners[3], unCorners[2], subframe_uv.x ), subframe_uv.y ) - unCorners[4] ).zxy * vec3( -1, 1, -1 ) * g_vrframe;
		if( dot( cc.yz, cc.yz ) >= 1.55 / GS.camzoom * cc.x * cc.x )
			return false;
		cc.yz /= GS.camzoom;
		cc = normalize( cc );
		g_pixelscale = .25 * abs( cc.x * dFdx( cc.y / cc.x ) * dFdy( cc.z / cc.x ) );
		vec3 dp = unCorners[4].zxy * vec3( -1, 1, -1 ) / 1000.;
		ray.o = GS.campos + GS.camframe * dp;
		ray.d = GS.camframe * g_vrframe * cc;
	}
	else
	{
		vec2 ec = sc * vec2( 1, iResolution.y / iResolution.x );
		vec3 cc = normalize( vec3( CAM_FOCUS, barrel_distort( vec2( ec.x, -ec.y ) / GS.camzoom, CAM_DISTORT ) ) );
		g_pixelscale = .25 * abs( cc.x * dFdx( cc.y / cc.x ) * dFdy( cc.z / cc.x ) );
		ray.o = GS.campos;
		ray.d = GS.camframe * cc;
	}
	return true;
}

void main_image_worker( out vec4 fcolor, in vec2 fcoord )
{
	fcolor = vec4( ZERO, 1 );

#if BUFFER_RUNLEVEL >= 3

	if( iFrame == 0 )
		return;

	GS = gs_load( iChannel0, ADDR_GAME_STATE );
	LE = le_load( iChannel0, ADDR_LOCAL_ENV );
	SM = sm_load( iChannel0, ADDR_LOCAL_SM );
	AC = ac_load( iChannel0, ac_addr(1) );
	PD = pd_load( iChannel0, pd_addr(1) );
	GSX = gsx_load( iChannel0, ADDR_GAME_STATE_AUX );

	g_campos_base = SM.rn * SM.r0;

	cld_alt = PD.cld.akg.x;
	cld_k50max = PD.cld.akg.y;
	cld_g = PD.cld.akg.z;
	cld_f = cld_g * cld_g;
	cld_noise = PD.cld.noise;
	cld_size = PD.cld.size;
	cld_fluff = PD.cld.fluff;
	cld_move = PD.cld.move;

	// int localplanetindex = 1;
	// g_ps = ps_load( iChannel0, ADDR_PLANETS + ivec2( localplanetindex, 0 ) );

	g_subsample	 = gs_get_subsample( GS );

	if( bit_is_unset( GS.switches, GS_SW_TRMAP ) )
	{
		vec2 sc = vec2(0);
		int mode = get_render_mode( fcoord, sc );

		if( mode == MODE_PRESERVE )
			fcolor = texelFetch( iChannel2, ivec2( fcoord - .5 ), 0 );
		else
		if( mode > 0 && sc.x < 1. && sc.y < 1. )
		{
			vec2 sct = sincospi( GS.timer * cld_move.w );
			cld_fluff_rot = mat2( sct.yx, -sct.x, sct.y );
			Ray ray = Ray( ZERO, ZERO );
			bool ok = get_render_ray( mode, sc, ray );
			if( ok )
				fcolor = render( ray, mode, fcoord );
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
	main_image_worker( fcolor, gl_FragCoord.xy );
}

#define unViewport _unViewport_dummy_
#define unCorners _unCorners_dummy_
