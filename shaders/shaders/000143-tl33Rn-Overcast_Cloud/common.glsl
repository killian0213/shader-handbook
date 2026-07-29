// Common (common) — Overcast Cloud by blackjero
// https://www.shadertoy.com/view/tl33Rn

// Overcast Cloud - by Jerome Liard, December 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://www.shadertoy.com/view/tl33Rn

// Trying to integrate clouds and atmosphere together, and a crude attempt at a cloud phase function with fogbow/glory.
// 3 cameras (sunset, afterburner, window seat) look around with mouse.
// 
// Notes:
// - Although the atmosphere is done normally spherically, the cloud layer isn't and is just a flat band parameterized from current vertical camera location. 
//   This makes it awkward to use in real situations (not to mention the overall prohibitive cost).
// - I didn't bother with inside/below/space views, cloud wise.
// - The cached cloud texture uses layers of alligator noise (documented in Houdini's online documentation). I hack a bit to detect screen resizes.
// - At high sun elevation we get uniform white/beige color, I probably did something wrong unless it is because it is a heightmap.
// - No plane shadow in the glory, I didn't model the 3d plane... sorry

// Bits of code from @iq, @Dave_Hoskins, @MyNameIsMJP, @AlanZucconi and others (see comments), and some visual reference from @FabriceNeyret2 for the cloud phase.
// The code length is hopeless as always.

#define iTanHalfFovy 0.505275
#define iExposure 4.118157

#define iSlider0 0.692857
#define iSlider1 0.085714
#define iSlider2 0.450000
#define iSlider3 0.000000
#define iSlider4 0.000000
#define iSlider5 0.100000

#define PI 3.141592654
#define const
#ifndef FLT_MAX
#define FLT_MAX 1000000.0
#endif

const vec3 RED = vec3( 1, 0, 0 );
const vec3 GREEN = vec3( 0, 1, 0 );
const vec3 BLUE = vec3( 0, 0, 1 );
const vec3 WHITE = vec3( 1, 1, 1 );
const vec3 BLACK = vec3( 0, 0, 0 );
const vec3 YELLOW = vec3( 1, 1, 0 );
const vec3 CYAN = vec3( 0, 1, 1 );

#define IMPL_SATURATE(type) type saturate( type x ) { return clamp( x, type(0.0), type(1.0) ); }

IMPL_SATURATE( float ) 
IMPL_SATURATE( vec2 ) 
IMPL_SATURATE( vec3 ) 
IMPL_SATURATE( vec4 )

float exp_decay( float x ) { return 1. - exp( -x ); } // note: exp_decay(pow(x,a)*b) for smooth in

float smoothstep_unchecked( float x ) { return ( x * x ) * ( 3.0 - x * 2.0 ); }
vec2 smoothstep_unchecked( vec2 x ) { return ( x * x ) * ( 3.0 - x * 2.0 ); }
vec3 smoothstep_unchecked( vec3 x ) { return ( x * x ) * ( 3.0 - x * 2.0 ); }

float smoothbump( float a, float r, float x ) { return 1.0 - smoothstep_unchecked( min( abs( x - a ), r ) / r ); }
vec3 smoothbump( vec3 a, vec3 r, vec3 x ) { return vec3( 1.0 ) - smoothstep_unchecked( min( abs( x - a ), r ) / r ); }

// like smoothstep, but takes a center and a radius instead
float smoothstep_c( float x, float c, float r ) { return smoothstep( c - r, c + r, x ); }
// band, centered at 0... like smoothstep_c but different meaning
float smoothband( float x, float r, float raa ) { return 1. - smoothstep_c( abs( x ), r, raa ); }
// range s,e
float smoothband( float x, float s, float e, float raa ) { return smoothband( x - ( e + s ) * 0.5, ( e - s ) * 0.5, raa ); }

vec2 perp( vec2 v ) { return vec2( -v.y, v.x ); }
// return range -pi,pi
float calc_angle( vec2 v ) { return atan( v.y, v.x ); }
float calc_angle( vec2 a, vec2 b ) { return calc_angle( vec2( dot( a, b ), dot( perp( a ), b ) ) ); }
vec3 contrast( vec3 x, vec3 s ) { return ( x - 0.5 ) * s + 0.5; }
float lensqr( vec2 v ) { return dot( v, v ); }
float lensqr( vec3 v ) { return dot( v, v ); }
float lensqr( vec4 v ) { return dot( v, v ); }
float pow2( float x ) { return x * x; }
vec3 pow2( vec3 x ) { return x * x; }
vec4 pow2( vec4 x ) { return x * x; }
float pow5( float x ) { float x2 = x * x; return x2 * x2 * x; }

//https://iquilezles.org/articles/smin
float smin_pol( float a, float b, float k ) { float h = clamp( 0.5f + 0.5f * ( b - a ) / k, 0.0f, 1.0f ); return mix( b, a, h ) - k * h * ( 1.0 - h ); }
float smax_pol( float a, float b, float k ) { return -smin_pol( -a, -b, k ); }

float powerful_scurve( float x, float p1, float p2 ) { return pow( 1.0 - pow( 1.0 - clamp( x, 0.0, 1.0 ), p2 ), p1 ); }
float maxcomp( float x ) { return x; }
float maxcomp( vec2 v ) { return max( v.x, v.y ); }
float maxcomp( vec3 v ) { return max( max( v.x, v.y ), v.z ); }
float mincomp( float x ) { return x; }
float mincomp( vec2 v ) { return min( v.x, v.y ); }
float mincomp( vec3 v ) { return min( min( v.x, v.y ), v.z ); }
float nearest( float x ) { return floor( 0.5 + x ); }
float sum( vec2 v ) { return v.x + v.y; }
float sum( vec3 v ) { return v.x + v.y + v.z; }
float sum( vec4 v ) { return v.x + v.y + v.z + v.w; }
float product( vec2 v ) { return v.x * v.y; }
float product( vec3 v ) { return v.x * v.y * v.z; }
float product( vec4 v ) { return v.x * v.y * v.z * v.w; }

float safe_acos( float x ) { return acos( clamp( x, -1., 1. ) ); }
float safe_asin( float x ) { return asin( clamp( x, -1., 1. ) ); }

// use with constants...
#define POW0(x) 1.0
#define POW1(x) (x)
#define POW2(x) (POW1(x)*(x))
#define POW3(x) (POW2(x)*(x))
#define POW4(x) (POW3(x)*(x))
#define POW5(x) (POW4(x)*(x))
#define POW6(x) (POW5(x)*(x))

// project this on line (O,d), d is assumed to be unit length
#define PROJECT_ON_LINE1(type) type project_on_line1( type P, type O, type d ) { return O + d * dot( P - O, d ); }

PROJECT_ON_LINE1( vec2 ) 
PROJECT_ON_LINE1( vec3 )

mat4 mat4_translation( vec3 value ) { return mat4( vec4( 1.0, 0.0, 0.0, 0.0 ),  vec4( 0.0, 1.0, 0.0, 0.0 ), vec4( 0.0, 0.0, 1.0, 0.0 ), vec4( value, 1.0 ) ); }

mat4 mat4_inverse1( mat4 m )
{
	// inv(T(t)xR)=inv(R)xinv(T(t))=trans(R)xT(-t)
	return mat4(
		vec4( m[0].x, m[1].x, m[2].x, 0.0 ),
		vec4( m[0].y, m[1].y, m[2].y, 0.0 ),
		vec4( m[0].z, m[1].z, m[2].z, 0.0 ),
		vec4( 0, 0, 0, 1 ) ) * mat4_translation( -m[3].xyz );
}

vec3 transform_point( mat4 m, vec3 p ) { return ( m * vec4( p, 1.0 ) ).xyz; }
vec3 transform_vector( mat4 m, vec3 v ) { return ( m * vec4( v, 0.0 ) ).xyz; }

#define REPEAT_FUNCTIONS( type ) \
type repeat( type x, type len ) { return len * fract( x * ( type( 1.0 ) / len ) ); } \
type repeat_mirror( type x, type len ) { return len * abs( type( -1.0 ) + 2.0 * fract( ( ( x * ( type( 1.0 ) / len ) ) - type( -1.0 ) ) * 0.5 ) ); } \
type repeat_e( type x, type start, type end ) { return start + repeat( x - start, end - start ); } /* _e means end as in start,end, return identity in range start,start+len, and repeat elsewhere */ \
type tri0( type x ) { return abs( fract( x * 0.5 ) - type(0.5) ) * 2.0; } /* mirror repeat of y=1-x on 0,1 */ \
type tri( type x ) { return tri0( type(1.0) - x ); } /* mirror repeat of y=x on 0,1 */

REPEAT_FUNCTIONS( float )
REPEAT_FUNCTIONS( vec2 )

float stripes( float x, float period, float r, float raa ) { return smoothstep( r + raa, r - raa, repeat_mirror( x, period * 0.5 ) ); }

// w is a magical aa scale factor, smaller w gives thicker lines
float rulers( float p, float spacing, float w )
{
	float u = tri( p * ( 2.0 / spacing ) );
	u /= fwidth( p ); // == abs(dFdx(p)) + abs(dFdy(p))
	u = smoothstep( 0., 1., spacing * u * w );
	return 1.0 - u; // alpha
}

// iq's function munged for vec4 https://www.shadertoy.com/view/XlXcW
vec4 hash42_( ivec2 x0 )
{
	uint k = 1103515245U;  // GLIB C
	uvec4 x = uvec4( x0, x0 * 0x8da6b343 );
	x = ( ( x >> 13U ) ^ x.yzwx ) * k;
	x = ( ( x >> 13U ) ^ x.zwxy ) * k;
	return vec4( x ) * ( 1.0 / float( 0xffffffffU ) );
}

vec2 hash22i( vec2 index ) { return hash42_( ivec2( index ) ).xy; }

// hash functions from David Hoskins's https://www.shadertoy.com/view/4djSRW
// *** Use this for integer stepped ranges, ie Value-Noise/Perlin noise functions.
#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)
#define HASHSCALE4 vec4(1031, .1030, .0973, .1099)
float hash11( float p ) { vec3 p3  = fract( vec3( p ) * HASHSCALE1 ); p3 += dot( p3, p3.yzx  + 19.19 ); return fract( ( p3.x + p3.y ) * p3.z ); }
float hash12( vec2 p ) { vec3 p3  = fract( vec3( p.xy, p.x ) * HASHSCALE1 ); p3 += dot( p3, p3.yzx  + 19.19 ); return fract( ( p3.x + p3.y ) * p3.z ); }

const vec2 V45 = vec2( 0.707106781, 0.707106781 );

// return a unit vector, or an angle (it's the same thing)
vec2 unit_vector2( float angle ) { return vec2( cos( angle ), sin( angle ) ); }
// note that if point p is also a unit vector, rotate_with_unit_vector returns the same as doing unit_vector2 on the sum of the angles (obvious but)
vec2 rotate_with_unit_vector( vec2 p, vec2 cs ) { return vec2( cs.x * p.x - cs.y * p.y, cs.y * p.x + cs.x * p.y ); }

// theta is angle with the z axis, range [0,pi].
// phi is angle with x vectors on z=0 plane, range [0,2pi].
// theta_vec is the unit vector for angle theta
// phi_vec is the unit vector for angle phi
vec3 zup_spherical_coords_to_vector( vec2 theta_vec, vec2 phi_vec ) { return vec3( theta_vec.y * phi_vec, theta_vec.x ); }
vec3 zup_spherical_coords_to_vector( float theta, float phi ) { return zup_spherical_coords_to_vector( unit_vector2( theta ), unit_vector2( phi ) ); }
vec3 zup_spherical_coords_to_vector( vec2 theta_phi ) { return zup_spherical_coords_to_vector( theta_phi.x, theta_phi.y ); }

// note: n.xy==0 is undefined for phi, pleae handle in caller code
vec2 vector_to_zup_spherical_coords( vec3 n )
{
	float theta = safe_acos( n.z ); // note: vectors normalized with normalize() are not immune to -1,1 overflow which cause nan in acos
	float phi = calc_angle( n.xy  );
	return vec2( theta, phi );
}

mat4 zup_spherical_coords_to_matrix( vec2 theta, vec2 phi )
{
	vec3 z = zup_spherical_coords_to_vector( theta, phi );
	vec3 x = zup_spherical_coords_to_vector( perp( theta ), phi ); // note: perp(theta) = unit_vector2(theta+PI*0.5)
	vec3 y = cross( z, x );
	return ( mat4( vec4( x, 0.0 ), vec4( y, 0.0 ), vec4( z, 0.0 ), vec4( 0.0, 0.0, 0.0, 1.0 ) ) );
}

// same as zup_spherical_coords_to_matrix with extra roll around x
mat4 zup_spherical_coords_to_matrix_rollx( vec2 theta, vec2 phi, vec2 rollx )
{
	vec3 z = zup_spherical_coords_to_vector( theta, phi );
	vec3 x = zup_spherical_coords_to_vector( perp( theta ), phi ); // note: perp(theta) = unit_vector2(theta+PI*0.5)
	vec3 y = cross( z, x );
	vec3 ry = y * rollx.x + z * rollx.y;
	vec3 rz = -y * rollx.y + z * rollx.x;
	y = ry;
	z = rz;
	return ( mat4( vec4( x, 0.0 ), vec4( y, 0.0 ), vec4( z, 0.0 ), vec4( 0.0, 0.0, 0.0, 1.0 ) ) );
}

mat4 zup_spherical_coords_to_matrix( float theta, float phi ) { return zup_spherical_coords_to_matrix( unit_vector2( theta ), unit_vector2( phi ) ); }

vec3 yup_spherical_coords_to_vector( vec2 theta, vec2 phi ) { return zup_spherical_coords_to_vector( theta, phi ).yzx; }
vec3 yup_spherical_coords_to_vector( float theta, float phi ) { return yup_spherical_coords_to_vector( unit_vector2( theta ), unit_vector2( phi ) ); }

mat4 yup_spherical_coords_to_matrix( vec2 theta, vec2 phi )
{
	vec3 y = yup_spherical_coords_to_vector( theta, phi );
	vec3 z = yup_spherical_coords_to_vector( perp( theta ), phi ); // note: perp(theta) = unit_vector2(theta+PI*0.5)
	vec3 x = cross( y, z );
	return ( mat4( vec4( x, 0.0 ), vec4( y, 0.0 ), vec4( z, 0.0 ), vec4( 0, 0, 0, 1 ) ) );
}

mat4 yup_spherical_coords_to_matrix( float theta, float phi ) {  return yup_spherical_coords_to_matrix( unit_vector2( theta ), unit_vector2( phi ) ); }

mat4 x_rotation( const float angle ) { vec2 v = unit_vector2( angle ); return mat4( vec4( 1,0,0,0 ), vec4( 0.f, v.x, v.y, 0.f ), vec4( 0.f,-v.y, v.x, 0.f ), vec4( 0,0,0,1 ) ); }
mat4 y_rotation( const float angle ) { vec2 v = unit_vector2( angle ); return mat4( vec4( v.x, 0.f, -v.y, 0.f ), vec4( 0,1,0,0 ), vec4( v.y, 0.f, v.x, 0.f ), vec4( 0,0,0,1 ) ); }
mat4 z_rotation( const float angle ) { vec2 v = unit_vector2( angle ); return mat4( vec4( v.x, v.y, 0.0, 0.0 ), vec4( -v.y, v.x, 0.0, 0.0 ), vec4( 0, 0, 1, 0 ), vec4( 0, 0, 0, 1 ) ); }

// source: adapted from Houdini online doc
float calc_alligator_noise( vec2 p, float period )
{
	vec2 p_index = floor( p );
	float d1 = 0.0;
	float d2 = 0.0;
	for ( int x = -1; x <= 1; ++x )
	{
		for ( int y = -1; y <= 1; ++y )
		{
			vec2 index = p_index + vec2( x, y );
			vec2 index_hash = index;
			if ( period != 0.0 ) index_hash = mod( index_hash, vec2( period ) );
			vec2 c = index + hash22i( index_hash ); // compiler bug.. hash bit returns 0 (but not always, depends where its called from)
			vec2 cp = p - c;
			float d = lensqr( cp );
			if ( d < 1.0 )
			{
				if ( period != 0.0 ) index_hash = mod( index_hash, vec2( period ) );
				d = hash12( index_hash ) * smoothstep_unchecked( 1.0 - sqrt( d ) );
				if ( d1 < d )
				{
					d2 = d1;
					d1 = d;
				}
				else if ( d2 < d )
				{
					d2 = d;
				}
			}
		}
	}

	return d1 - d2;
}

float noise1s( float x )
{
	x -= 0.5;
	float x0 = floor( x );
	float y0 = hash11( x0 );
	float y1 = hash11( x0 + 1.0 );
	return mix( y0, y1, smoothstep_unchecked( x - x0 ) );
}

// noise layering with build time expanded normalizing factors etc (use constants obviously)

#define LAYERED6(func,p,args,frequency,persistence,period) \
((func(p*POW0(frequency),args,period*POW0(frequency))*POW1(persistence)+ \
  func(p*POW1(frequency),args,period*POW1(frequency))*POW2(persistence)+ \
  func(p*POW2(frequency),args,period*POW2(frequency))*POW3(persistence)+ \
  func(p*POW3(frequency),args,period*POW3(frequency))*POW4(persistence)+ \
  func(p*POW4(frequency),args,period*POW4(frequency))*POW5(persistence)+ \
  func(p*POW5(frequency),args,period*POW5(frequency))*POW6(persistence))* \
   (1.0/( (POW1(persistence)+ \
	 POW2(persistence)+ \
	 POW3(persistence)+ \
	 POW4(persistence)+ \
	 POW5(persistence)+ \
	 POW6(persistence)))))

// higher values for a gives smoother landscapes
float calc_alligator_noise_( vec2 p, float args, float period ) { return calc_alligator_noise( p, period ); }

float alligator6_12( vec2 p, float period ) { return LAYERED6( calc_alligator_noise_, p, -1.0, 2.0, 0.5, period ); }
float alligator6_12( vec2 p, float frequency, float persistence, float period ) { return LAYERED6( calc_alligator_noise_, p, -1.0, frequency, persistence, period ); }

struct Ray{ vec3 o; vec3 d; };

Ray mkray( vec3 o, vec3 d ) { Ray tmp; tmp.o = o; tmp.d = d; return tmp; }
// note: looking down z
vec3 get_view_dir( vec2 normalized_pos, float aspect, float tan_half_fovy_rcp ) { return normalize( vec3( normalized_pos.x * aspect, normalized_pos.y, -tan_half_fovy_rcp ) ); }
// note that we pass the reciprocal of tan_half_fovy
// normalized_pos is (-1,1-)->(1,1)
Ray get_view_ray2( vec2 normalized_pos, float aspect, float tan_half_fovy_rcp, mat4 camera ) { return mkray( camera[3].xyz, transform_vector( camera, get_view_dir( normalized_pos, aspect, tan_half_fovy_rcp ) ) ); }
Ray transform_ray( mat4 m, Ray ray ) { return mkray( transform_point( m, ray.o ), transform_vector( m, ray.d ) ); }

vec2 sphere_trace( Ray ray, float radius, vec3 center )
{
	vec3 O = ray.o;
	vec3 d = ray.d;
	float tp = dot( center - O, d ); // O + d * tp = center projected on line (O,d)
	float h_sqr = lensqr( ( O + d * tp ) - center );
	float radius_sqr = radius * radius;
	if ( h_sqr > radius_sqr ) return vec2( FLT_MAX, FLT_MAX ); // ray missed the sphere
	float dt = sqrt( radius_sqr - h_sqr ); // distance from P to In (near hit) and If (far hit)
	return vec2( tp - dt, tp + dt ); // record 2 hits In, If
}

float get_horizon_elevation( vec3 c, float r, vec3 p ) { return safe_asin( r / length( p - c ) ); }
float get_ray_elevation( vec3 c, vec3 o, vec3 d ) { return safe_acos( dot( d, normalize( c - o ) ) ); }
float get_ray_elevation( vec3 c, Ray view_ray ) { return get_ray_elevation( c, view_ray.o, view_ray.d ); }

float opI( float d1, float d2 ) { return max( d1, d2 ); }
float opU( float d1, float d2 ) { return -max( -d1, -d2 ); }
float opS( float d1, float d2 ) { return max( -d2, d1 );}

// http://nishitalab.org/user/nis/cdrom/sig93_nis.pdf
float CornetteSingleScatteringPhaseFunction( float cos_theta, float g )
{
	float g2 = g * g;
	return 3.0 * ( 1.0 - g2 ) * ( 1.0 + pow2( cos_theta ) ) / ( 2.0 * ( 2.0 + g2 ) * pow( 1.0 + g2 - 2.0 * g * cos_theta, 1.5 ) );
}

// notes: RayleighScattering(cos_theta)  == CornetteSingleScatteringPhaseFunction( cos_theta, 0.0 )
// should integrate to one on the sphere (check with integral_of_spherical_func)
float RayleighScattering( float cos_theta ) { return 0.75 * ( 1.0 + cos_theta * cos_theta ); }

// https://www.astro.umd.edu/~jph/HG_note.pdf HG, g in [-1,1]
// note: multiply by 4*PI to integrate to 1 on the sphere, I think... (check with integral_of_spherical_func)
float HenyeyGreensteinPhaseFunction( float cos_theta, float g )
{
	float g2 = g * g;
	return ( 1.0 / ( 4.0 * PI ) ) * ( 1.0 - g2 ) / pow( 1.0 + g2 - 2.0 * g * cos_theta, 1.5 );
}

// this one gives us fogbow and glories
// for the cloud phase function I used "Interactive multiple anisotropic scattering in clouds" Figure 2 for rough reference https://hal.inria.fr/inria-00333007/document
vec3 CloudPhaseFunction( float cos_theta )
{
	float x = safe_acos( cos_theta );
	float x2 = max( 0., x - 2.45 ) / ( PI - 2.15 );
	float x3 = max( 0., x - 2.95 ) / ( PI - 2.95 );
	float y = ( exp( -max( x * 1.5 + 0.0, 0.0 ) * 30.0 ) // front peak
				+ smoothstep( 1.7, 0., x ) * 0.45 * 0.8 // front ramp
				+ smoothbump( 0.4, 0.5, cos_theta ) * 0.02 // front bump middle
				- smoothstep( 1., 0.2, x ) * 0.06 // front ramp damp wave
				+ smoothbump( 2.18, 0.20, x ) * 0.06 // first trail wave
				+ smoothstep( 2.28, 2.45, x ) * 0.18 // trailing piece
				- powerful_scurve( x2 * 4.0, 3.5, 8. ) * 0.04 // trail
				+ x2 * -0.085
				+ x3 * x3 * 0.1 ); // trail peak

	vec3 ret = vec3( y );
	// spectralize a bit
	ret = mix( ret, ret + 0.008 * 2., smoothstep( 0.94, 1., cos_theta ) * sin( x * 10. * vec3( 8, 4, 2 ) ) );
	ret = mix( ret, ret - 0.008 * 2., smoothbump( -0.7, 0.14, cos_theta ) * sin( x * 20. * vec3( 8, 4, 2 ) ) ); // fogbow
	ret = mix( ret, ret - 0.008 * 5., smoothstep( -0.994, -1., cos_theta ) * sin( x * 30. * vec3( 3, 4, 2 ) ) ); // glory

	// scale and offset should be tweaked so integral on sphere is 1
	ret += 0.13 * 1.4;
	return ret * 3.9;
}

// http://graphicrants.blogspot.jp/
// 
// Trowbridge-Reitz
float D_GGX( float m_dot_n, float alpha ) { float alpha_sqr = alpha * alpha; return alpha_sqr / ( PI * pow2( pow2( m_dot_n ) * ( alpha_sqr - 1. ) + 1. ) ); }
float G_neumann( float n_dot_l, float n_dot_v ) { return n_dot_l * n_dot_v / max( n_dot_l, n_dot_v ); }
float F_schlick( float v_dot_h, float F0 ) { return F0 + ( 1. - F0 ) * pow5( 1. - v_dot_h ); }
float F_cooktorrance( float v_dot_h, float F0 )
{
	float F0_sqrt = sqrt( F0 );
	float mu = ( 1. + F0_sqrt ) / ( 1. - F0_sqrt );
	float c = v_dot_h;
	float g = sqrt( mu * mu + c * c - 1. );
	return 0.5 * pow2( ( g - c ) / ( g + c ) ) * ( 1. + pow2( ( ( g + c ) * c - 1. ) / ( ( g - c ) * c + 1. ) ) );
}

// this is just an example
// v = wi
// l = Li
vec3 add_light_contrib( vec3 albedo, vec3 l, vec3 n, vec3 v, vec3 Li, float dwi, float kdiffuse, float kspecular, float roughness )
{
	float F0 = 0.08;
	float alpha = roughness * roughness;
	vec3 h = normalize( l + v );
	float n_dot_l_raw = dot( n, l );
	float n_dot_v_raw = dot( n, v );
	float n_dot_h_raw = dot( n, h );
	float eps = 1e-4; // else divides by zero
	float n_dot_l = max( eps, n_dot_l_raw );
	float n_dot_v = max( eps, n_dot_v_raw );
	float n_dot_h = max( eps, n_dot_h_raw );
	float D = D_GGX( n_dot_h, alpha ); // n_dot_h should probably be clamped to >=0
	float G = G_neumann( n_dot_l, n_dot_v );
	float F = F_schlick( n_dot_v, F0 );
	return ( ( kdiffuse * albedo * ( 1.0 / PI ) + kspecular * ( D * F * G ) / ( 4. * n_dot_l * n_dot_v ) ) ) * Li * n_dot_l * dwi;
}

vec3 add_light_contrib( vec3 albedo, vec3 l, vec3 n, vec3 v, vec3 Li, float dwi, vec3 kdiffuse_kspecular_roughness )
{
	return add_light_contrib( albedo, l, n, v, Li, dwi, kdiffuse_kspecular_roughness.x, kdiffuse_kspecular_roughness.y, kdiffuse_kspecular_roughness.z );
}

vec3 tonemap_reinhard( vec3 x ) { return x / ( 1. + x ); } // //http://www.cs.utah.edu/~reinhard/cdrom/tonemap.pdf
vec3 tonemap_reinhard( vec3 x, float exposure ) { return exposure * tonemap_reinhard( x ); }
vec3 gamma_correction( vec3 L ) { return pow( L, vec3( 0.45 ) ); }
vec3 gamma_correction_itu( vec3 L ) { return mix( 4.5061986 * L, 1.099 * pow( L, vec3( 0.45 ) ) - 0.099, step( vec3( 0.018 ), L ) ); } // mentioned in http://resources.mpi-inf.mpg.de/tmo/logmap/

// spherical gaussians code copied from @MyNameIsMJP, tried to use a bit for the soft look but didn't push much
// https://mynameismjp.wordpress.com/2016/10/09/sg-series-part-2-spherical-gaussians-101/

struct SG { vec3 Amplitude; vec3 Axis; float Sharpness; };

SG MakeSG( vec3 a, vec3 v, float s )
{
	SG sg;
	sg.Amplitude = a;
	sg.Axis = v;
	sg.Sharpness = s;
	return sg;
}

// approximate integral on omega of sg(v)dv
vec3 ApproximateSGIntegral( in SG sg ) { return 2. * PI * ( sg.Amplitude / sg.Sharpness ); }

vec3 SGIrradianceFitted( in SG lightingLobe, in vec3 normal )
{
	const float muDotN = dot( lightingLobe.Axis, normal );
	const float lambda = lightingLobe.Sharpness;

	const float c0 = 0.36f;
	const float c1 = 1.0f / ( 4.0f * c0 );

	float eml  = exp( -lambda );
	float em2l = eml * eml;
	float rl   = 1.0 / lambda;

	float scale = 1.0f + 2.0f * em2l - rl;
	float bias  = ( eml - em2l ) * rl - em2l;

	float x  = sqrt( 1.0f - scale );
	float x0 = c0 * muDotN;
	float x1 = c1 * x;

	float n = x0 + x1;

	float y = saturate( muDotN );
	if ( abs( x0 ) <= x1 ) y = n * n / x;

	float result = scale * y + bias;

	return result * ApproximateSGIntegral( lightingLobe );
}

// is this correct then?
vec3 SGDiffuseFitted( in SG lightingLobe, in vec3 normal, vec3 albedo )
{
	vec3 brdf = albedo / PI;
	return SGIrradianceFitted( lightingLobe, normal ) * brdf;
}

// AlanZucconi's spectral palette functions from https://www.shadertoy.com/view/ls2Bz1

vec3 bump3y( vec3 x, vec3 yoffset ) { vec3 y = 1. - x * x; return saturate( y - yoffset ); }

vec3 spectral_zucconi6_01( float x )
{
	const vec3 c1 = vec3( 3.54585104, 2.93225262, 2.41593945 );
	const vec3 x1 = vec3( 0.69549072, 0.49228336, 0.27699880 );
	const vec3 y1 = vec3( 0.02312639, 0.15225084, 0.52607955 );
	const vec3 c2 = vec3( 3.90307140, 3.21182957, 3.96587128 );
	const vec3 x2 = vec3( 0.11748627, 0.86755042, 0.66077860 );
	const vec3 y2 = vec3( 0.84897130, 0.88445281, 0.73949448 );
	
	return bump3y( c1 * ( x - x1 ), y1 ) + bump3y( c2 * ( x - x2 ), y2 );
}

vec3 spectral_zucconi6( float w )
{
	// w: [400, 700]
	// x: [0,   1]
	float x = saturate( ( w - 400.0 ) / 300.0 );
	return spectral_zucconi6_01( x );
}

struct coordsys_t { vec3 o,x,y,z; };

float calc_Fr_r( float cos_theta ) { return RayleighScattering( cos_theta  ); }
float calc_Fr_m( float cos_theta, float g ) { return CornetteSingleScatteringPhaseFunction( cos_theta, g ); }

#define earth_radius 6.36e+6 // careful algorithm is very sensitive to this
#define earth_center vec3(0.0,0.0,0.0)
const float earth_angular_velocity = ( 2.0 * PI / ( 24.0 * 60.0 * 60.0 ) );
const float sun_radius = 6.955e+8; // for render only
#define sun_dist 1.49e+11 // for render only
const float sun_cos = 0.999989; // for render only
const float H0_r = 8e+3;
const float H0_m = 1.2e+3;
const float atm_max = 6420e+3 - earth_radius; // as small as possible, large enough to accomodate H0_ values
// beta is 1/m units, but we work in km
const vec3 beta_r = 1.0 * vec3( 5.19e-6, 1.21e-5, 2.96e-5 ); // calculated offline
//vec3 beta_r = 1.0 * vec3( 5.8e-6, 13.5e-6, 33.1e-6 ); // from "Precomputed Atmospheric Scattering"
//vec3 beta_r = 1.0 * vec3( 5.5e-6, 13.0e-6, 22.4e-6 ); // wwwtyro
const vec3 beta_m = 0.01 * vec3( 210e-5 ); // from "Precomputed Atmospheric Scattering", but need an extra factor 100 to get something that looks like something...
const vec3 beta_c = vec3( 6e-4f, 5e-4f, 2e-4f ) * 0.6 * 1.5;
#define Is (vec3( 1.0, 1.0, 1.0 ) * 1.6)
const vec3 sun_Ls = Is * 2.0; // for solid objects lighting

const vec3 earth_diffuse_reflection = vec3( 0.1 ); // controls blue depth
const float Isky_max_angle_deg = 110.0;

// include window scale when debugging plane orientation (helps to see more of the outside)
#define WINDOW_RADIUS_SCALE 1.0
#define CLOUD_AND_SKY_AS_DOWNSIZED_BUFFER
#define NICER_HORIZON 2
#define USE_REAL_SUN_COLOR
#define CLAMP_IV // be careful: clamping fixes clouds bright dots artifacts but ruins atm where used
#define CLOUD_AND_SKY_AS_BUFFER_DOWWNSCALE 0.5 /*0.25 or 0.5*/
#define num_view_ray_segments 40 // we have to bump this number quite a bit to get decent integration
								 // also 40 causes cream artifact on the horizon
int enable_solid_clouds = 1;
int enable_sky_and_clouds = 1;
#define min_max_cloud_steps 25.0
#define max_cloud_steps_increment 5.0
float max_max_cloud_steps = min_max_cloud_steps + max_cloud_steps_increment * 2.0;
float sun_ray_optical_depth_max_n = 10.f; // affects shadow a lot
int enable_cloud_phase = 1;
int enable_solid_clouds_half_screen = 0;
// pretend altocumulus-ish altitude https://en.wikipedia.org/wiki/Altocumulus_cloud altough we do full opaque...
#define cloud_end 6.0e+3
#define cloud_layer_thickness 5.e+3
#define cloud_start (cloud_end - cloud_layer_thickness)
#define cloud_mid (( cloud_end + cloud_start ) * 0.5)
const float cloud_tex_world_size = 21000.0;
float cloud_sharpness = 1.0;
float cloud_density = 1.1;
float sun_cloud_tmax_hack = 1.0;
float cloud_scattering_max_step = 450.0; // affects the look of the cloud quite a bit, try 50.0
										 // when flying below clouds this must be small
struct scene_params_t
{
	mat4 camera;
	mat4 plane_to_world;
	mat4 plane_render_camera;
	vec3 sun_direction;
	coordsys_t b;
	float tan_half_fovy;
	float fade;
	int enable_cabin_view;
	int enable_sun_glare;
	int enable_sun_flares;
	vec4 cloud_animation_params; // xy: cloud_scroll_offset  z: animation speed w: iTime
};

// [0,1] -> [0,1]
// s is the slope at midpoint (0.5.0.5)
// for s pick something >4 to get a bit of oversteer
float oversteer_step_cubic( float x, float s )
{
	s = -s;
	x = saturate( x );
	if ( x > 0.5 ) {
		x = 1.0 - x;
		return 1.0 + ( ( ( -6.0 - s * 2.0 ) + ( 8.0 + s * 4.0 ) * x ) * x ) * x;
	}
	return -( ( ( -6.0 - s * 2.0 ) + ( 8.0 + s * 4.0 ) * x ) * x ) * x;
}

float quantize( float x, float q ) { return nearest( x * q ) / q; }

// for camera movements
// set s to 2,3 for smooth noise with a bit of control on the smoothness
// set s to 4,5,6 for some oversteer (6 starts to get quite strong)
float noise1s_quantized_oversteer( float x, float s, float q )
{
	x -= 0.5;
	float x0 = floor( x );
	float y0 = quantize( hash11( x0 ), q );
	float y1 = quantize( hash11( x0 + 1.0 ), q );
	if ( s == 1.0 ) return mix( y0, y1, smoothstep_unchecked( x - x0 ) );
	return mix( y0, y1, oversteer_step_cubic( x - x0, s ) );
}

vec3 getFlyingCameraPath( float time )
{
	vec3 p;
	p.y = 3000.0 * noise1s_quantized_oversteer( 0.1 * time, 6.0, 4.0 );
	p.z = time * 3000.0;
	p.x = ( noise1s_quantized_oversteer( 0.06 * time, 5.0, 4.0 ) - 0.5 ) * 2.0 * 10000.0;
	return p;
}

// note: scene_params.camera's position must stay in place!! cloud uv scroll makes it look like we are moving (sorry this is sad)
void applyFlyingCamera( inout scene_params_t scene_params, float time )
{
	vec3 p0 = getFlyingCameraPath( time - 1.0 );
	vec3 p1 = getFlyingCameraPath( time );

	float roll = ( p1.x - p0.x ) * 0.0001;
	
	scene_params.camera[3].xyz = scene_params.b.z * ( earth_radius + cloud_end + 1500.0 );

	vec3 x = scene_params.camera[0].xyz;
	vec3 y = scene_params.camera[1].xyz;
	vec3 z = scene_params.camera[2].xyz;
	vec3 o = scene_params.camera[3].xyz;
	
	scene_params.camera[3].xyz = (scene_params.camera * vec4(p1.x,p1.y,0.0,1.0) ).xyz;

	vec2 rollv = unit_vector2( roll );
	scene_params.camera[0].xyz = rollv.x * x + rollv.y * y;
	scene_params.camera[1].xyz = -rollv.y * x + rollv.x * y;

	float travelled = p1.z * 2.0;

	scene_params.cloud_animation_params.xy = vec2( -travelled, 0.0 );
	scene_params.cloud_animation_params.z = 1.0;
}

scene_params_t getSceneParams( float aTime, vec3 aResolution, vec4 aMouse )
{
	scene_params_t scene_params;

	scene_params.enable_cabin_view = 0;
	scene_params.enable_sun_glare = 1;
	scene_params.enable_sun_flares = 1;
	scene_params.fade = 1.0;

	scene_params.cloud_animation_params.xy = unit_vector2( PI ) * aTime * 1000.0;
	scene_params.cloud_animation_params.z = 1.0; // cloud animation
	scene_params.cloud_animation_params.w = aTime;

	float theta_from_sun_direction = radians( 110.0 * iSlider0 ); // note: theta_from_sun_direction can't be zero, our trace doesn't support it (because b)
	float flying_altitude = cloud_end + 1800.0 + ( 30000. - 1800. ) * iSlider1;
	float plane_yaw = 2.0 * PI * iSlider2 * 1.0;
	float plane_roll = 2.0 * PI * iSlider3 * 1.0;
	float plane_pitch = 2.0 * PI * iSlider4 * 1.0;

	scene_params.tan_half_fovy = iTanHalfFovy;

	vec2 mm = vec2( 0.0, 0.0 );
	vec2 mm0 = mm;
	vec2 mm1 = mm;

	{
		// mouse control
		bool sticky_mouse = false;
		if ( aMouse.z > 0.0 || sticky_mouse ) mm0 = ( aMouse.xy - aResolution.xy * 0.5 ) / ( min( aResolution.x, aResolution.y ) * 0.5 );
		mm1 = mm0;
		mm1 = sign( mm1 ) * pow( abs( mm1 ), vec2( 0.9 ) );
		mm = mm1 * 3.0 * scene_params.tan_half_fovy;
	}

	int camera_index = -1;

	float t0 = 15.0;
	float t1 = 28.0;
	float t2 = 26.0;
	
	float time = aTime;

#if 1

	time = mod( time, t0 + t1 + t2  );
	float t = 0.0;

	float fade_time = 0.5;
	scene_params.fade = saturate( 1.0 -( smoothbump( 0.0, fade_time, time )+
										 smoothbump( t0, fade_time, time )+
										 smoothbump( t0 + t1, fade_time, time )+
										 smoothbump( t0 + t1 + t2, fade_time, time ) ) );
	 
	     if ( time < t0      ) { camera_index = 0;                  t = time / t0; }
	else if ( time < t0 + t1 ) { camera_index = 1; time -= t0;      t = time / t1; }
	else                       { camera_index = 2; time -= t0 + t1; t = time / t2; }

#else

	float loop_time = t2;
	camera_index = 2;
	time = mod( time, loop_time );
	float t = time / loop_time;
	
#endif

	if ( camera_index == 0 ) // sunset
	{
		theta_from_sun_direction = radians( 90.0 );
		flying_altitude = cloud_end + 1800.0 * mix( 1.5, 3.5, t );
		mm.x += exp_decay( pow(time,2.0) * 0.015 ) * 1.0;
		mm.y -= t * 0.6;
		
		scene_params.cloud_animation_params.xy = unit_vector2( plane_yaw ) * aTime * 5000.0;
	}
	else if ( camera_index == 1 ) // flight
	{
		theta_from_sun_direction = radians( 80.0 );
		float lookup = 1.0 - 0.82 * exp_decay( time * 0.1 );
		mm.y -= lookup;
	}
	else if ( camera_index == 2 ) // cabin
	{
		theta_from_sun_direction = radians( mix( 91.0, 70.0, t ) );
		flying_altitude = cloud_end + 6000.0;
		scene_params.enable_cabin_view = 1;
		scene_params.tan_half_fovy = 0.51;
		plane_yaw = radians( 39.0 );
		scene_params.cloud_animation_params.xy = -unit_vector2( plane_yaw ) * aTime * 1000.0;

		if ( aMouse.z <= 0.0 )
		{
			mm0.x -= smoothband( time, 6.0, 11.0, 2.0 ) * 0.18;
			mm0.y -= smoothband( time, 6.2, 12.0, 2.0 ) * 0.10;
		}

		// todo: make the clamp below smoother...
		mm1 = clamp( mm0, vec2( -0.2, -0.32 ), vec2( +0.6, +0.3 ) );
		mm1 = sign( mm1 ) * pow( abs( mm1 ), vec2( 0.9 ) );
		mm = mm1 * 3.0 * scene_params.tan_half_fovy;
	}

	mat4 tmp = zup_spherical_coords_to_matrix( theta_from_sun_direction, 0.0 );

	scene_params.sun_direction = vec3( 0., 0., 1. ); // no point in changing this
	vec3 cloud_plane_n = tmp[2].xyz;

	scene_params.b.x = tmp[0].xyz;
	scene_params.b.y = tmp[1].xyz;
	scene_params.b.z = tmp[2].xyz;
	scene_params.b.o = earth_radius * cloud_plane_n; // ground point

	scene_params.camera[0].xyz = tmp[1].xyz;
	scene_params.camera[1].xyz = tmp[2].xyz;
	scene_params.camera[2].xyz = tmp[0].xyz;
	scene_params.camera[3].xyz = cloud_plane_n * ( earth_radius + flying_altitude );

	if ( camera_index == 1 ) applyFlyingCamera( scene_params, time );

	mat4 mouse_rotation = yup_spherical_coords_to_matrix( mm.y, -mm.x );
	scene_params.camera = scene_params.camera * mouse_rotation;

	if ( scene_params.enable_cabin_view == 1 )
	{
		scene_params.plane_to_world = tmp; // plane is local so origin is 0,0,0

		float noise_rotation_amplitude = 1.15;
		scene_params.plane_to_world = scene_params.plane_to_world
			* zup_spherical_coords_to_matrix_rollx(
			unit_vector2( plane_pitch + noise_rotation_amplitude * sin( (time)*2. * PI / 9.0 ) * 0.01 ),
			unit_vector2( plane_yaw + noise_rotation_amplitude * sin( ( time - 3.0 ) * 2. * PI / 10.0 ) * 0.01 ),
			unit_vector2( plane_roll + noise_rotation_amplitude * sin( ( time + 4.0 ) * 2. * PI / 11.0 ) * 0.01 ) );

		// plane needs to be traced with saner float ranges so origin same as plane local offset from here
		scene_params.plane_render_camera[0] = scene_params.plane_to_world[0];
		scene_params.plane_render_camera[1] = scene_params.plane_to_world[2];
		scene_params.plane_render_camera[2] = -scene_params.plane_to_world[1];
		scene_params.plane_render_camera[3] = scene_params.plane_to_world[3]
			+ scene_params.plane_to_world[0] * 0.30 // move along plane
			+ scene_params.plane_to_world[1] * 5.30 // get closer to the window
			+ scene_params.plane_to_world[2] * 0.75 // up and down
		;

		scene_params.plane_render_camera
			= scene_params.plane_render_camera
			* x_rotation( radians( -4.5 ) )
			* y_rotation( radians( 15.0 ) );

		{
			// vector that looks at windows center
			vec3 z = -scene_params.plane_render_camera[3].xyz;

			// move along plane
			scene_params.plane_render_camera[3].xyz += scene_params.plane_to_world[0].xyz
				* ( ( smoothstep( 0.0, 0.12, abs( mm1.x ) ) )
					* max( mm1.x, 0. ) * -1.2 );

			// up and down
			scene_params.plane_render_camera[3].xyz += scene_params.plane_to_world[2].xyz
				* ( smoothstep( 0.1, 0.4, abs( mm1.y ) ) )
				* max( -mm1.y, 0. ) * 0.65;

			// get closer to the window
			scene_params.plane_render_camera[3].xyz -= z
				* maxcomp( smoothstep( 0.1, 0.4, abs( mm1 ) ) * abs( mm1 ) ) * 0.1;

			// translate closer to the window when looking left and down
			scene_params.plane_render_camera[3].xyz += scene_params.plane_to_world[1].xyz
				* smoothstep( 0.0, 0.025, abs( mm1.x ) * max( -mm1.x, 0. ) ) * 0.3;
		}

		scene_params.plane_render_camera = scene_params.plane_render_camera * mouse_rotation;
		
		scene_params.camera[0] = scene_params.plane_render_camera[0];
		scene_params.camera[1] = scene_params.plane_render_camera[1];
		scene_params.camera[2] = scene_params.plane_render_camera[2];
	}

	return scene_params;
}

// write Image's iChannel0
vec4 calcCloudHeightMap_bufA( vec2 fragCoord, vec3 aResolution, int aFrame, vec4 aMouse, sampler2D aChannel0, sampler2D aChannel1 )
{
	int calculate_bufA_every_frame = 0;

	bool resized = ( aResolution != texelFetch( aChannel1, ivec2( aResolution.xy ) - ivec2( 1, 1 ), 0 ).xyz ); // check the resolution we think we have (should have been written in the top right pixel of bufB)

	if ( !resized && ( calculate_bufA_every_frame == 0 ) && aFrame > 2 ) return texture( aChannel0, fragCoord.xy / aResolution.xy ); // reuse

	vec2 uv = fragCoord.xy / aResolution.xy;
	vec4 tex = vec4( 0.0 );
	 // s must be integer
	{ float s =  8.; tex.x = alligator6_12( uv.xy * s, s ); }
	{ float s =  4.; tex.y = alligator6_12( uv.xy * s, s ); }
	{ float s = 10.; tex.z = alligator6_12( uv.xy * s, s ); }
	return tex;
}

float getCloudDist( vec3 p, coordsys_t b, vec4 cloud_animation_params, sampler2D aChannel0 )
{
	float aTime = cloud_animation_params.w;
	
	float lod = 0.0;

	float r = length( p );
	float ph = r - earth_radius;
	vec3 n = p; // / r; // we don't need normalize, because we project
	n = vec3( dot( n, b.x ),
			  dot( n, b.y ),
			  dot( n, b.z ) );
	p.xy = ( 8. * 1000000.0 ) * ( n.xy / n.z ); // cube projection centered on b
	p.xy += cloud_animation_params.xy;
	vec2 uv = p.xy * ( 1.0 / cloud_tex_world_size );

	vec4 n1 = textureLod( aChannel0, uv + aTime * ( 0.004 * cloud_animation_params.z ), lod );
	vec4 n2 = textureLod( aChannel0, uv * ( 1.0 / 8. ) + ( aTime * 0.0017 * cloud_animation_params.z ), lod );
	float h = saturate( ( 1.0 * n1.x * 0.3 +
						  1.0 * n1.y * 0.5 +
						  1.0 * n2.z * 1.3 - 0.05 ) ); // saturating here should make no difference, if it does it means h range is wrong

	float h1 = mix( mix( cloud_start, cloud_end, 0.3 ), cloud_end, h );
	float h2 = mix( mix( cloud_start, cloud_end, 0.2 ), cloud_start, h );
	float d1 = ph - h1;
	float d2 = h2 - ph;
	float dist = opI( d1, d2 );
	return dist;
}

vec2 getCloudDensityAndDistance( vec3 p, coordsys_t b, vec4 cloud_animation_params, sampler2D aChannel0 )
{
	float dist = getCloudDist( p, b, cloud_animation_params, aChannel0 );
	float density = ( dist > 0.0 ? 0.0 : exp_decay( max( -dist, 0.0 ) * cloud_sharpness ) * cloud_density ); // also: beta_c
//	float density = step( dist, 0.0 ); // little visual different and a little bit faster
	return vec2( density, dist );
}

// like sphere_trace with some bits factored out
vec2 sphere_trace_2( float tp, float h_sqr, float radius )
{
	float radius_sqr = radius * radius;
	if ( h_sqr > radius_sqr ) return vec2( FLT_MAX, FLT_MAX ); // ray missed the sphere
	float dt = sqrt( radius_sqr - h_sqr ); // distance from P to In (near hit) and If (far hit)
	return vec2( tp - dt, tp + dt ); // record 2 hits In, If
}

// return the trace interval of the cloud band
// return 0,0 if there is nothing to trace
vec2 getCloudTraceRange( Ray view_ray )
{
	vec3 O = view_ray.o;
	vec3 d = view_ray.d;
	float tp = dot( earth_center - O, d ); // O + d * tp = center projected on line (O,d)
	float h_sqr = lensqr( ( O + d * tp ) - earth_center );
	vec2 tcs = sphere_trace_2( tp, h_sqr, earth_radius + cloud_start );
	vec2 tce = sphere_trace_2( tp, h_sqr, earth_radius + cloud_end );

	float r2 = lensqr( view_ray.o - earth_center );

	if ( r2 > pow2( earth_radius + cloud_end ) )
	{
		if ( tce.x == FLT_MAX || tce.x < 0.0 ) return vec2( 0.0, 0.0 );
		if ( tcs.x == FLT_MAX ) return vec2( tce.x, tce.y );
		return vec2( tce.x, tcs.x );
	}

	if ( r2 > pow2( earth_radius + cloud_start ) )
	{
		if ( tcs.x != FLT_MAX && tcs.x > 0.0 ) return vec2( 0, tcs.x );
		return vec2( 0.0, tce.y );
	}

	if ( tcs.y != FLT_MAX && tcs.y > 0.0 )
	{
		vec2 tea = sphere_trace_2( tp, h_sqr, earth_radius );
		if ( tea.x == FLT_MAX || tea.x > 0.0 ) return vec2( 0, 0 );
		return vec2( tcs.y, tce.y );
	}

	return vec2( 0, 0 );
}

#define body_radius vec2( 5.96, 6.09 )
const vec2 windows_radius = vec2( 25.0, 37.0 ) / 229.0 * body_radius.x * 0.5;
const float windows_spacing = 50.0 / 229.0 * body_radius.x * 0.5;
const float windows_pos_from_center = 50.0 / 229.0 * body_radius.x * 0.5;

float sdAirlinerWindow( vec2 p, float window_radius_scale )
{
	p = abs( p );

	vec2 r = vec2( 525.0, 625.0 ) / 525.0;
	p *= r.x / ( windows_radius.x * window_radius_scale );

	return smin_pol( smin_pol( -p.y + r.y, -p.x + r.x, 0.95 )
					 , -dot( V45, p - project_on_line1( p, r + V45 * 1.05, perp( V45 ) ) ), 2.1 );
}

float sd_cylinderx( vec3 p, vec3 c, float r ) { return length( p.yz - c.yz ) - r; }

float sdPlaneWindowVolume( vec3 p, float window_radius_scale )
{
	vec3 cc = vec3( 0 );
	float wall_in = body_radius.x - 0.05;
	float wall_out = body_radius.x + 0.02;
	vec2 p2 = p.xz;
	p2.x = repeat_e( p.x, -windows_spacing, windows_spacing );
	p2.y -= windows_pos_from_center;
	// wx is window border mapped to 0,1
	float wx = saturate( ( ( p.y - cc.y ) - wall_in ) / ( wall_out - wall_in ) );
	p2 *= ( 1.0 + wx * 0.1 );
	float dw = sdAirlinerWindow( p2, window_radius_scale );
	return dw;
}

float sdPlaneCabin( vec3 p, float window_radius_scale )
{
	vec3 cc = vec3( 0 );

	float wall_in = body_radius.x - 0.05;
	float wall_out = body_radius.x + 0.02;

	float l = 72.25; //a350len
	float d = opI( opI( ( p - cc ).x - l * 0.5, //front clip
				  opI( -sd_cylinderx( p, cc, wall_in ),
					   sd_cylinderx( p, cc, wall_out ) ) ), // plane body wall
			 -( p - cc ).x - l * 0.5 ); // back clip

	// https://www.airbus.com/content/dam/corporate-topics/publications/backgrounders/techdata/aircraft_characteristics/Airbus-Commercial-Aircraft-AC-A350-900-1000.pdf
	// Page 9 for window size and position
	vec2 p2 = p.xz;
	p2.x = repeat_e( p.x, -windows_spacing, windows_spacing );
	p2.y -= windows_pos_from_center;
	// wx is window border mapped to 0,1
	float wx = saturate( ( ( p.y - cc.y ) - wall_in ) / ( wall_out - wall_in ) );
	p2 *= ( 1.0 + wx * 0.1 );
	float dw = sdAirlinerWindow( p2, window_radius_scale );
	d = opI( d, dw );
	float d1 = opI( -sd_cylinderx( p, cc, wall_in + 0.02 ),
					sd_cylinderx( p, cc, wall_in + 0.03 ) );
	d = opS( d, d1 );
	return d;
}

vec3 gPlaneCabin( vec3 p, float window_radius_scale )
{
	float d = 0.05; // for near stuff
	float c = sdPlaneCabin( p, window_radius_scale );
	return normalize( vec3( sdPlaneCabin( p + vec3( d, 0.0, 0.0 ), window_radius_scale ) - c,
							sdPlaneCabin( p + vec3( 0.0, d, 0.0 ), window_radius_scale ) - c,
							sdPlaneCabin( p + vec3( 0.0, 0.0, d ), window_radius_scale ) - c ) );
}

// for debug coloring of cloud surface
vec3 gForClouds( vec3 p, coordsys_t b, vec4 cloud_animation_params, sampler2D aChannel0 )
{
	float d = 70.0; // d too small will reveal bilinear lookup discontinuities, if used
	float c = getCloudDist( p, b, cloud_animation_params, aChannel0 );
	return normalize( vec3( getCloudDist( p + vec3( d, 0.0, 0.0 ), b, cloud_animation_params, aChannel0 ) - c,
							getCloudDist( p + vec3( 0.0, d, 0.0 ), b, cloud_animation_params, aChannel0 ) - c,
							getCloudDist( p + vec3( 0.0, 0.0, d ), b, cloud_animation_params, aChannel0 ) - c ) );
}

vec3 calc_Fr_c( float cos_theta )
{
	if ( enable_cloud_phase == 1 ) return 1.04 * CloudPhaseFunction( cos_theta );

	// *4.0*PI is so that function integrates to 1 on the sphere
	// note: linear combination still integrate to 1
	return vec3( mix( HenyeyGreensteinPhaseFunction( cos_theta, 0.42 ), // normal phase (increase g to strengthen illumination in sun direction)
					  HenyeyGreensteinPhaseFunction( cos_theta, -0.3 ), // hack boost clouds on the other side of the sun too..
					  0.3 ) * 4.0 * PI );
	// also see Physically based Sky, Atmosphere and Cloud Rendering in Frostbite:
	// http://blog.selfshadow.com/publications/s2016-shading-course/hillaire/s2016_pbs_frostbite_sky_clouds.pptx
}

// return r,m in .xy and set cloud density to 0 in .z
vec3 calc_rho_atm_only( vec3 p )
{
	float h = length( p - earth_center ) - earth_radius;
	return vec3( exp( -vec2( h ) / vec2( H0_r, H0_m ) ), 0.0 );
}

struct vec9 { vec3 r, m, c; }; // rayleigh, mie, cloud

vec9 mkvec9( vec3 s )
{
	vec9 val;
	val.r = vec3( s.x );
	val.m = vec3( s.y );
	val.c = vec3( s.z );
	return val;
}

vec9 mkvec9( float s ) { return mkvec9( vec3( s, s, s ) ); }

void add_vec9( inout vec9 od, vec9 value, float ds )
{
	od.r += value.r * beta_r * ds;
	od.m += value.m * beta_m * ds;
	od.c += value.c * beta_c * ds;
}

void add_vec9_c( inout vec3 od_c, vec3 value_c, float ds ) { od_c += value_c * beta_c * ds; }

struct integration_t
{
	vec9 prev;
	vec9 sum;
	bool first; // could use a 0,1 float and mulitply
};

integration_t integration_init()
{
	integration_t ret;
	ret.sum = mkvec9( 0.0 );
	ret.first = true;
	return ret;
}

void add_vec9( inout integration_t od, vec9 value, float ds )
{
	if ( !od.first )
	{
		vec9 tmp;
		tmp.r = ( od.prev.r + value.r ) * 0.5;
		tmp.m = ( od.prev.m + value.m ) * 0.5;
		tmp.c = ( od.prev.c + value.c ) * 0.5;
		add_vec9( od.sum, tmp, ds );
	}
	od.prev = value;
	od.first = false;
}

void add_vec9_c( inout integration_t od, vec3 value_c, float ds )
{
	if ( !od.first )
	{
		vec9 tmp;
//		tmp.r = ( od.prev.r + value.r ) * 0.5; // 0.0
//		tmp.m = ( od.prev.m + value.m ) * 0.5; // 0.0
		tmp.c = ( od.prev.c + value_c ) * 0.5;
		add_vec9_c( od.sum.c, tmp.c, ds );
	}
	od.prev.c = value_c;
	od.first = false;
}

// note: transmittance = exp(-opticalDepth)
integration_t opticalDepth2( Ray ray, float t, float t2, coordsys_t b )
{
	integration_t ret = integration_init();
#define num_segments 15
	float dt = ( t2 - t ) / float( num_segments );
	for ( int i = 0; i < num_segments + 1; ++i )
	{
		vec3 p = ray.o + ray.d * t;
		vec3 rho = calc_rho_atm_only( p ); // no cloud
		add_vec9( ret, mkvec9( rho ), dt );
		t += dt;
	}
	return ret;
}

struct TraceOutput
{
	float t;
	float num_iterations; // num iterations
	float dist; // distance to surface (error)
	float shadow;
};

TraceOutput traceClouds( Ray ray, coordsys_t b, vec2 tmax, vec4 cloud_animation_params, sampler2D aChannel0 )
{
	float dbreak = 0.0004; // tweak for perfs!!! depends on scene scale etc might make small features thicker than they actually are
	float tfrac = 1.0;
	int max_iterations = 100;

	TraceOutput to;
	to.t = tmax.x;
//	to.t = 0.0;
	to.num_iterations = 0.0;
	to.dist = 0.0;
	to.shadow = 1.0;

	for ( int i = 0; i < max_iterations; ++i )
	{
		float d = getCloudDist( ray.o + to.t * ray.d, b, cloud_animation_params, aChannel0 );
		to.dist = d;
		if ( ( abs( to.dist ) <= dbreak * to.t ) || to.t > tmax.y ) break;
		
		to.t += to.dist * tfrac; // d can be negative... hmm
		to.num_iterations += 1.0;
	}

	return to;
}

// just cloud contribution
integration_t opticalDepth3( Ray ray, float tmax, coordsys_t b, vec2 uv, float nn, vec4 cloud_animation_params, sampler2D aChannel0 )
{
	integration_t ret = integration_init();
	float dx = 2000.0;
	float n = min( ceil( tmax / dx ), nn );
	dx = tmax / n;
	float tprev = 0.0;
	float t = 0.0;
	for ( float i = 0.; i < n; i += 1.0 )
	{
		vec3 p = ray.o + ray.d * t;
		vec2 dd = getCloudDensityAndDistance( p, b, cloud_animation_params, aChannel0 );
		float density = dd.x;
		float dist = dd.y;
		float dt = t - tprev;
		add_vec9_c( ret, vec3( density ), dt ); // note: dt not used the first time
		tprev = t;
		dist = abs( dist );
		dist = max( dist, cloud_scattering_max_step );
		t += dist;
	}
	return ret;
}

bool in_earth_shadow( vec3 p, vec3 sun_direction ) { return ( dot( p, sun_direction ) < 0.0 ) && ( lensqr( p - project_on_line1( p, earth_center, sun_direction ) ) < earth_radius * earth_radius ); }

vec4 s_params_r = vec4( 11.8549757, 22.499994277, 0.01295454, 0.199916169 );
vec4 s_params_g = vec4( 7.501523494, 12.642851829, 0.023999901, 0.242999389 );
vec4 s_params_b = vec4( 0.381065428, 9.642851829, 0.073178708, 0.570980966 );

float calc_Isky_div_Is_approx_per_wavelength( float x, vec4 params )
{
	x = -( x - radians( Isky_max_angle_deg ) ) / radians( Isky_max_angle_deg );
	x = saturate( x );
	x -= params.w;
	// Gompertz Function, via Payul Bouyrke miscellaneous functions
	return exp( params.x * exp_decay( x * params.y ) / params.y ) * params.z;
}

vec3 calc_Isky_div_Is_approx( float x )
{
	return vec3( calc_Isky_div_Is_approx_per_wavelength( x, s_params_r ),
				 calc_Isky_div_Is_approx_per_wavelength( x, s_params_g ),
				 calc_Isky_div_Is_approx_per_wavelength( x, s_params_b ) );
}

// implementation of http://nishitalab.org/user/nis/cdrom/sig93_nis.pdf
// using buffer and  all symmetries we could cache luts and make this shader considerably faster,
// but I wanted a no buffers shader, so brute force.

struct AtmOut
{
	vec3 earth_p; // when hitting earth surface
	vec3 earth_n; // when hitting earth surface
	bool earth_surface; // is earth surface
};

vec3 atmEval_WithClouds( Ray view_ray, inout AtmOut atm_out
						 , vec3 sun_direction, coordsys_t b
						 , vec2 uv, float first_cloud_t, vec2 cloud_trange
						 , vec4 cloud_animation_params
						 , sampler2D aChannel0 )
{
	// elevation from (view point,earth center) vector
	float elev_view_vector = get_ray_elevation( earth_center, view_ray );
	float elev_earth_horizon = get_horizon_elevation( earth_center, earth_radius, view_ray.o );
	float elev_cloud_end_vector = get_horizon_elevation( earth_center, earth_radius + cloud_end, view_ray.o );
	bool hits_earth = elev_view_vector < elev_earth_horizon;

	vec2 te = sphere_trace( view_ray, earth_radius, earth_center ); // earth sphere
	vec2 ta = sphere_trace( view_ray, earth_radius + atm_max, earth_center ); // upper atmosphere sphere

	atm_out.earth_surface = ( te.x > 0.0 && te.x != FLT_MAX );

	vec3 spacecolor = BLACK;

	if ( ta.x == FLT_MAX ) return spacecolor; // view_ray line doesn't intersect a (and therefore, e since e is inside a)
	if ( ta.y <= 0.0 ) return spacecolor; // return mix(SPACECOLOR,WHITE,0.7);	// view_ray line intersects a(atm) but behind us
	if ( te.x <= 0.0 && te.y >= 0.0 ) return GREEN; // inside (e)earth

	// sky range
	vec2 atm_trace_range; // range segment we integrate things on along view_ray

	if ( te.x == FLT_MAX ) atm_trace_range = vec2( max( 0.0, ta.x ), ta.y ); // view_ray line intersects a, doesn't intersect e
	// view_ray line intersects a and e
	else if ( ta.x > 0.0 ) atm_trace_range = vec2( ta.x, te.x ); // ray hitting a from outside atm
	else if ( te.x > 0.0 ) atm_trace_range = vec2( 0.0, te.x ); // ray hitting e from inside atm
	else atm_trace_range = vec2( 0.0, ta.y ); // ray hitting a from inside atm

	if ( atm_trace_range.y - atm_trace_range.x < 0.0 ) return YELLOW; // should never happen

	// we also set this once more after the loop, here it is set in case we early return for debug but still want the normal
	if ( atm_out.earth_surface ) atm_out.earth_n = normalize( view_ray.o + view_ray.d * te.y - earth_center );

	Ray sun_ray;
	sun_ray.d = sun_direction;

	vec3 p;
	integration_t tppc = integration_init(); // the last of those is a earth hit -> sun ray when earth_surface is true
	integration_t tppa = integration_init(); // the last of those is a earth hit -> eye ray when earth_surface is true
	integration_t Iv_sum = integration_init();
	
	float tp = atm_trace_range.x;
	float atm_trace_step0 = ( atm_trace_range.y - atm_trace_range.x ) / float( num_view_ray_segments );
	float atm_trace_step = atm_trace_step0;

	float cloud_step = 0.0; // total budget for stepping inside clouds
	float cloud_t = first_cloud_t;

	bool global_cloud_trace_active = ( first_cloud_t > 0.0 && first_cloud_t != FLT_MAX && cloud_trange.y != 0.0 );
//	if ( global_cloud_trace_active ) return WHITE;
	bool global_cloud_trace_active0 = global_cloud_trace_active;

	float longpath2 = smoothstep( elev_earth_horizon - radians( 5.0 ), elev_earth_horizon, elev_view_vector );

	for ( int i = 0; i < num_view_ray_segments + 1; ++i )
	{
		p = view_ray.o + view_ray.d * tp;
		p = earth_center + normalize( p ) * max( earth_radius * 1.00001, length( p ) ); // make sure we don't start inside the earth when p is a hit point
		vec3 rho = calc_rho_atm_only( p );

		if ( !in_earth_shadow( p, sun_direction ) )
		{
			sun_ray.o = p;
			vec2 ta_sun = sphere_trace( sun_ray, earth_radius + atm_max, earth_center );
			tppc = opticalDepth2( sun_ray, 0.0/*p*/, ta_sun.y/*pc*/, b ); // note: ta_sun.y > 0.0
			vec9 tmp;
			vec3 tr = exp( -tppc.sum.r - tppa.sum.r
						   - tppc.sum.m - tppa.sum.m
						   - tppc.sum.c - tppa.sum.c );
			tmp.r = rho.x * tr;
			tmp.m = rho.y * tr;
			tmp.c = rho.z * tr;
			add_vec9( Iv_sum, tmp, atm_trace_step );
		}

		add_vec9( tppa, mkvec9( rho ), atm_trace_step );
#if 1
		if ( global_cloud_trace_active && tp > cloud_t )
		{
			bool local_cloud_trace_active = global_cloud_trace_active;

			float cloud_limit_this_step = min( tp + atm_trace_step, cloud_trange.y );

			float max_cloud_steps = min_max_cloud_steps; // affects horizon mostly (the noisy glitter artifact)

#if NICER_HORIZON == 1
// most of our problems are in that range, we need more res
			if ( !hits_earth ) max_cloud_steps = max_max_cloud_steps * 2.;
#elif NICER_HORIZON == 2
// second attempt with smoother transition
			max_cloud_steps = mix( max_cloud_steps, max_max_cloud_steps * 2., longpath2 );
#endif
			// cloud trace catch up
			for (; cloud_step < max_cloud_steps
				  && local_cloud_trace_active
				  ; cloud_step += 1.0 )
			{
				vec3 p2 = view_ray.o + cloud_t * view_ray.d;

				//if ( length( p2 ) - earth_radius < cloud_start ) return RED; // should ne noise or nothing

				vec2 d = getCloudDensityAndDistance( p2, b, cloud_animation_params, aChannel0 );
				float density = d.x;
				float dist = d.y;

				// just trace the whole space always, give more steps to closest bits
				float cloud_step_left = max_cloud_steps - cloud_step;
				float cloud_t_left = cloud_trange.y - cloud_t;
				float cloud_dt = mix( abs( dist ), cloud_t_left / cloud_step_left
									  , cloud_step / max_cloud_steps );

				if ( cloud_t + cloud_dt >= cloud_limit_this_step )
				{
					local_cloud_trace_active = false;
					cloud_dt = cloud_limit_this_step - cloud_t;
				}

				if ( !in_earth_shadow( p2, sun_direction ) )
				{
					sun_ray.o = p2;
					float sun_cloud_tmax = getCloudTraceRange( sun_ray ).y * sun_cloud_tmax_hack;
					integration_t tppc2 = opticalDepth3( sun_ray, sun_cloud_tmax/*pc*/, b, uv
														 ,
#if NICER_HORIZON == 1
// since we have double the res we half steps on sun direction scattering
// we get most of the perf back + it gives a bit of fade out
														 !hits_earth ? sun_ray_optical_depth_max_n * 0.5 : sun_ray_optical_depth_max_n
#elif NICER_HORIZON == 2
// second attempt with smoother transition
														 mix( sun_ray_optical_depth_max_n, sun_ray_optical_depth_max_n * 0.5, longpath2 )
#else
														 sun_ray_optical_depth_max_n
#endif

														 , cloud_animation_params, aChannel0 ); // note: ta_sun.y > 0.0
				//	tppc2.sum = mkvec9( 0.5 );
					vec3 tr = exp(
						-tppc2.sum.r - tppa.sum.r
						- tppc2.sum.m - tppa.sum.m // doesn't contribute
						- tppc2.sum.c - tppa.sum.c );

					add_vec9_c( Iv_sum, vec3( density * tr ), cloud_dt );
				}

				add_vec9_c( tppa, vec3( density ), cloud_dt ); // add cloud contribution

				cloud_t += cloud_dt;
			}
		}
#endif
		tp += atm_trace_step;
	}

	float cos_theta = dot( sun_direction, view_ray.d );
	vec3 Iv = Is *
		( ( Iv_sum.sum.r / ( 4.0 * PI ) ) * calc_Fr_r( cos_theta ) +
		  ( Iv_sum.sum.m / ( 4.0 * PI ) ) * calc_Fr_m( cos_theta, 0.8 ) +
		  ( Iv_sum.sum.c / ( 4.0 * PI ) ) * calc_Fr_c( cos_theta ) );

	if ( atm_out.earth_surface )
	{
		vec3 n = normalize( p - earth_center );
		float cos_alpha = dot( sun_direction, n );
		vec3 Isky_div_Is = calc_Isky_div_Is_approx( safe_acos( cos_alpha ) );

		atm_out.earth_p = p; // note: P is the earth hit
		atm_out.earth_n = n;

		// note:
		// tr_ppc is the tr of earth hit -> sun ray
		// Tr_ppa is the tr of earth hit -> eye ray
		vec3 Ie = earth_diffuse_reflection
			* ( cos_alpha * Is * exp( -tppc.sum.r - tppc.sum.m ) + Is * Isky_div_Is );
		Iv += Ie * exp( -tppa.sum.r - tppa.sum.m );
	}
	else
	{
//		float sun_visible = cos_theta > sun_cos ? 1.0 : 0.0;
		float sun_visible = cos_theta > ( sun_cos - 0.00001 ) ? 1.0 : 0.0; // make it bigger so we can do a lookup
		Iv += Is * exp( -tppa.sum.r - tppa.sum.m ) * sun_visible;
	}

#ifdef CLAMP_IV
	if ( global_cloud_trace_active0
		 && ( length( view_ray.o ) - earth_radius ) > cloud_start // protect below cloud views from this hack
		)
	{
		Iv = mix( Iv, min( Iv, vec3( 0.23 ) ), longpath2 );
	}
#endif

	return Iv;
}

#define MAX_ITERATIONS 120
float TMAX = 350.0;

TraceOutput tracePlaneCabin( Ray ray, float soft_shadow_sharpness, float window_radius_scale )
{
	float DBREAK = 0.0025; // tweak for perfs!!! depends on scene scale etc might make small features thicker than they actually are
	float TFRAC = 0.25;

	TraceOutput to;
	to.t = 0.0;
	to.num_iterations = 0.0;
	to.dist = 0.0;
	to.shadow = 1.0;

	for ( int i = 0; i < MAX_ITERATIONS; ++i )
	{
		float d = sdPlaneCabin( ray.o + to.t * ray.d, window_radius_scale );
		to.dist = d;
		if ( ( abs( to.dist ) <= DBREAK * to.t ) || to.t > TMAX ) break;
		to.shadow = min( to.shadow, soft_shadow_sharpness * to.dist / to.t ); // https://iquilezles.org/www/material/nvscene2008/rwwtt.pdf
		to.t += to.dist * TFRAC; // d can be negative... hmm
		to.num_iterations += 1.0;
	}

	to.shadow = max( 0.0, to.shadow ); // hide shitty artifacts
	return to;
}

vec3 renderPlaneCabin( scene_params_t scene_params, vec2 uv, float aspect, float window_radius_scale
					   , bool skip_shading, inout bool outside_visible )
{
	mat4 world_to_plane = mat4_inverse1( scene_params.plane_to_world );

	Ray plane_view_ray = get_view_ray2( ( uv - vec2( 0.5 ) ) * 2.0, aspect, 1.0 / scene_params.tan_half_fovy, scene_params.plane_render_camera );

	Ray plane_view_ray_plane_local = transform_ray( world_to_plane, plane_view_ray );
	TraceOutput to = tracePlaneCabin( plane_view_ray_plane_local, 1.0, window_radius_scale );

	bool sky = to.t > TMAX;
	outside_visible = sky;

	if ( skip_shading ) return CYAN; // just occlude with flat color

	vec3 p_plane_local = plane_view_ray_plane_local.o + to.t * plane_view_ray_plane_local.d;
	vec3 n_plane_local = gPlaneCabin( p_plane_local, window_radius_scale );

	float ao = 1.0;
	{
		// https://iquilezles.org/www/material/nvscene2008/rwwtt.pdf
		float delta = 0.01;
		float a = 0.0;
		float bb = 1.0;
		for ( int i = 0; i < 5; i++ )
		{
			float fi = float( i );
			float d = sdPlaneCabin( p_plane_local + delta * fi * n_plane_local, window_radius_scale );
			a += ( delta * fi - d ) * bb;
			bb *= 0.5;
		}
		ao = max( 1.0 - 1.2 * a, 0.0 );
	}

	vec3 l = scene_params.sun_direction;

	float soft_shadow = 1.0;
	float soft_shadow_sharpness = 5.0;
	float direct_shadow = 1.0;
	if ( !sky )
	{
		Ray sun_ray;
		sun_ray.o = p_plane_local + n_plane_local * 0.05;
		sun_ray.d = transform_vector( world_to_plane, l );
		TraceOutput tos = tracePlaneCabin( sun_ray, soft_shadow_sharpness, window_radius_scale );
		soft_shadow = tos.shadow;
		direct_shadow = tos.t > TMAX ? 1.0 : 0.0;
	}
	float shadow = mix( soft_shadow, direct_shadow, 0.05 );

	vec3 v = plane_view_ray.d; // same orientation has world space
	vec3 n = transform_vector( scene_params.plane_to_world, n_plane_local );

	vec3 sky_color = vec3( 0.3, 0.4, 0.5 ) * 0.3; // todo: pick this color from BufB

	vec3 albedo = vec3( 1.0, 0.917, 0.866 );
	albedo *= albedo;

	if ( sky ) return sky_color;

	vec3 col = vec3( 0 );
#if 1
	float f = smoothstep( -0.707, 0., dot( n, scene_params.plane_to_world[1].xyz ) );
	// sky lobe
	col += f * SGDiffuseFitted( MakeSG( sky_color * 1.17 * 0.1, vec3( 0, 0, 1 ), 2.133 ), n, albedo );
	// cloud lobe
	col += f * SGDiffuseFitted( MakeSG( vec3( 0.05, 0.05, 0.05  ) * 1.17, vec3( 0, 0, -1 ), 2.133 ), n, albedo );
	// cabin light lobe
	col += ( 1.0 - f ) * SGDiffuseFitted( MakeSG( vec3( 0.05, 0.05, 0.05  ) * 0.2 * 1.17, -scene_params.plane_to_world[1].xyz, 2.133 ), n, albedo );
	// direct sun light
	vec3 kdiffuse_kspecular_roughness = vec3( 0.4, 0.2, 0.8 );
	col += shadow * add_light_contrib( albedo, l, n, -v, sun_Ls * 0.1, 1.0, kdiffuse_kspecular_roughness );
#endif
	vec3 l_plane_local = transform_vector( world_to_plane, l );
	float window_glow_d = sdPlaneWindowVolume( p_plane_local + l_plane_local * 0.2 * iSlider5, window_radius_scale );
	float window_glow = exp( -10.0 * max( 0., -window_glow_d ) );
	col += vec3( window_glow ) * 0.21 * sky_color;

	return col;
}

// sun center uv so we can lookup in bufB
vec2 getSunCenterUV( mat4 camera, vec3 sun_direction, float tan_half_fovy, float aspect )
{
	vec3 v = sun_direction;
	v = vec3( dot( camera[0].xyz, v ),
			  dot( camera[1].xyz, v ),
			  dot( camera[2].xyz, v ) );
	v = normalize( v );
	float d = 1.0 / tan_half_fovy;
	vec3 P = vec3( 0, 0, -d );
	vec3 n = vec3( 0, 0, 1 );
	vec3 O = vec3( 0, 0, 0 );
	float alpha = dot( P - O, n ) / dot( v, n );
	vec3 I = O + alpha * v;
	I.x /= aspect;
	return ( I.xy + vec2( 1.0, 1.0 ) ) * 0.5;
}

vec3 calcCloudsAndSky_bufB( vec2 fragCoord, float aTime, vec3 aResolution, vec4 aMouse, sampler2D aChannel0 )
{
#ifndef CLOUD_AND_SKY_AS_DOWNSIZED_BUFFER
	return RED;
#else

	if ( fragCoord.xy == ( aResolution.xy - vec2( 0.5, 0.5 )) ) return aResolution; // write the resolution we think we have in a volunteer pixel (top right pixel of bufB)

	float aspect = aResolution.x / aResolution.y;
	vec2 uv = fragCoord.xy / aResolution.xy;

	if ( uv.x > CLOUD_AND_SKY_AS_BUFFER_DOWWNSCALE ||
		 uv.y > CLOUD_AND_SKY_AS_BUFFER_DOWWNSCALE ) return RED;

	uv *= ( 1.0 / CLOUD_AND_SKY_AS_BUFFER_DOWWNSCALE );

	scene_params_t scene_params = getSceneParams( aTime, aResolution, aMouse );
	Ray view_ray = get_view_ray2( ( uv - vec2( 0.5 ) ) * 2.0, aspect, 1.0 / scene_params.tan_half_fovy, scene_params.camera );
	vec2 cloud_trange = getCloudTraceRange( view_ray );

	vec3 col = vec3(0.0);
	AtmOut atm_out;

	bool outside_visible = true;

	if ( scene_params.enable_cabin_view == 1 )
	{
		float window_radius_scale = 1.2 * WINDOW_RADIUS_SCALE;

		bool skip_shading = true;
		// render window to get occlusion
		col = renderPlaneCabin( scene_params, uv, aspect, window_radius_scale, skip_shading, outside_visible );
	}

	float first_cloud_t = FLT_MAX;

	if ( enable_solid_clouds == 1 )
	{
		// trace to find the first hit distance
		TraceOutput to = traceClouds( view_ray, scene_params.b, cloud_trange, scene_params.cloud_animation_params, aChannel0 );
		if ( to.t < cloud_trange.y ) first_cloud_t = to.t;
		if ( uv.x > 0.5 && enable_solid_clouds_half_screen == 1 ) return to.t > cloud_trange.y ? BLUE * 0.5 : ( gForClouds( view_ray.o + to.t * view_ray.d, scene_params.b, scene_params.cloud_animation_params, aChannel0 ) + 1.0 ) * 0.5;
	}

	if ( enable_sky_and_clouds == 1 )
	{
		if ( outside_visible ) // shameless culling of cloud work when outside_visible is false
		{
			col = atmEval_WithClouds( view_ray, atm_out, scene_params.sun_direction, scene_params.b, uv
									  , first_cloud_t, cloud_trange, scene_params.cloud_animation_params, aChannel0 );
		}
	}

	return col;

#endif
}

float flare_noise1s( float x, float cut )
{
	x -= 0.5;
	float x0 = floor( x );
	float y0 = hash11( x0 );
	float y1 = hash11( x0 + 1.0 );
	float y = mix( y0, y1, smoothstep_unchecked( x - x0 ) );
	return y;
}

float calcFallOff( float sd, float r, float p1, float p2 )
{
	float sd_last = sun_cos - r; //length of rays
	float g = 1.0 - saturate( max( sun_cos - sd, 0.0 ) / ( sun_cos - sd_last ) );
	return powerful_scurve( g, p1, p2 );
}

void add_sun_glow_and_flares( inout vec3 col, Ray view_ray, Ray center_view_ray
							  , scene_params_t scene_params, bool outside_visible, vec3 real_sun_color, float aTime )
{
	float sd = dot( view_ray.d, scene_params.sun_direction ); // assumes sun very far... view_ray.d needs renormalize for some obscure reason
	float sd_center = dot( center_view_ray.d, scene_params.sun_direction ); // assumes sun very far... view_ray.d needs renormalize for some obscure reason

	vec3 n = normalize( view_ray.o );
	vec3 x = normalize( cross( scene_params.sun_direction, n ) );
	vec3 y = cross( x, scene_params.sun_direction );
	float theta = safe_acos( sd );
	vec2 v = vec2( dot( view_ray.d, x ), dot( view_ray.d, y ) );
	float phi = calc_angle( v );

	float flare_attn_gradiant_angle = radians( 90.0 );

	vec3 xsum2 = vec3( 0.0 );

	float flare = pow2( smoothstep( 0.995, 1.0, sd_center ) );

	if ( outside_visible && ( scene_params.enable_sun_flares == 1 ) )
	{
		float cut = 0.3;
		float phi2 = phi + safe_acos( sd_center ) * 0.4;
		vec3 spectre = spectral_zucconi6( mix( 400., 700., sin( theta * 10.0 + aTime * 0.1 ) ) );
		vec3 offset = ( 1. + 0.4 * spectre );
		float nn = flare_noise1s( phi2 * 14., cut );
		nn = 0.0 + smax_pol( nn - cut, 0.0, 0.2 ) / ( 1. - cut );
		xsum2 += 0.85 * 0.02 * offset * nn;
		xsum2 = vec3( smoothstep( 0.0, 0.4, xsum2 ) * 4.0 ) * offset; // higher contrast?
		xsum2 *= vec3( smoothstep( 1.0, 20., degrees( theta ) ) ); // fade out center

		vec3 xsum0 = vec3( xsum2 );

		float flare_attn_grad = dot( v, unit_vector2( flare_attn_gradiant_angle ) );
		float flare_attn2 = 1.0 - smoothstep( -0.7, -0.24, flare_attn_grad );

		xsum2 *= flare_attn2; // fade upper half of the lens flare

		// first wave of radial bumps
		xsum2 += vec3( smoothbump( ( radians( 25. + noise1s( phi ) * 6. ) ),
								   (  radians( 3. + noise1s( phi ) * 3. ) )
								   , ( theta ) ) * xsum0 * mix( 5., 20.0, flare ) ) * flare_attn2;

		// second wave of radial bumps
		xsum2 += vec3( smoothband( theta, radians( 50.0 ), radians( 54.0 ), radians( 2.5 ) ) * xsum0 * 4.0 ) * flare_attn2;

		vec3 spectral_ring = spectral_zucconi6( mix( 400., 700., smoothstep( radians( 27.0 ),
																			 radians( 35.0 ), theta ) ) )
		* stripes( phi, radians( 1.2 ), radians( 0.2 ), radians( 0.2 ) );
		xsum2 += spectral_ring * 0.02 * flare;
	}

	xsum2 *= 0.8;
	xsum2 *= 1. - smoothstep( radians( 60. ), radians( 71. ), theta ); // fade lens flare below and behind

	vec3 xsum1 = vec3( 0.0 );

	if ( outside_visible && ( scene_params.enable_sun_glare == 1 ) )
	{
		// sun glow
		xsum1 += calcFallOff( sd, 0.005, 3.0, 0.32 );

		{
			// sun glow peaks (todo: cull)
			vec2 sc_v = unit_vector2( phi ) * theta;
			float gs = calcFallOff( sd, 0.004, 3.0, 0.9 );
			float n = 5.0;
			vec2 sv0 = unit_vector2( 2.0 * PI / n );
			vec2 sv = sv0;
			for ( float i = 0.0; i < n; i += 1.0 )
			{
				float vv0 = dot( sc_v, sv );
				float vv1 = dot( sc_v, perp( sv ) );
				float vv = abs( vv0 );
				vv /= PI;
				vv *= 0.4;
				xsum1 += exp( -vv * 1500.0 ) * gs * 0.04 * ( vv1 > 0.0 ? 1.0 : 0.0 );
				sv = rotate_with_unit_vector( sv, sv0 );
				//break;
			}
		}
	}

	vec3 xsum = vec3( 0.0 );
	xsum += xsum2;
	xsum += xsum1
#ifdef USE_REAL_SUN_COLOR
		* real_sun_color // use sun color
#endif
	;

	col += xsum;
}

vec3 calcFinalImage( vec2 fragCoord, float aTime, vec3 aResolution, vec4 aMouse, sampler2D aChannel0, sampler2D aChannel1 )
{
	float aspect = aResolution.x / aResolution.y;
	vec2 uv = fragCoord.xy / aResolution.xy;

	scene_params_t scene_params = getSceneParams( aTime, aResolution, aMouse );
	vec2 sun_center_uv = getSunCenterUV( scene_params.camera, scene_params.sun_direction, scene_params.tan_half_fovy, aspect );
	Ray view_ray = get_view_ray2( ( uv - vec2( 0.5 ) ) * 2.0, aspect, 1.0 / scene_params.tan_half_fovy, scene_params.camera );
	Ray center_view_ray = get_view_ray2( vec2( 0.0 ), aspect, 1.0 / scene_params.tan_half_fovy, scene_params.camera );
	vec2 cloud_trange = getCloudTraceRange( view_ray );

	vec3 col = vec3(0.0);
	AtmOut atm_out;

	bool outside_visible = true;

	if ( scene_params.enable_cabin_view == 1 )
	{
		float window_radius_scale = 1.0 * WINDOW_RADIUS_SCALE;

		bool skip_shading = false;

		col = renderPlaneCabin( scene_params, uv, aspect, window_radius_scale, skip_shading, outside_visible );
	}

	float first_cloud_t = FLT_MAX;

#ifndef CLOUD_AND_SKY_AS_DOWNSIZED_BUFFER

	if ( enable_solid_clouds == 1 )
	{
		// trace to find the first hit distance
		TraceOutput to = traceClouds( view_ray, scene_params.b, cloud_trange, scene_params.cloud_animation_params, aChannel0 );
		if ( to.t < cloud_trange.y ) first_cloud_t = to.t;
		if ( uv.x > 0.5 && enable_solid_clouds_half_screen == 1 ) return to.t > cloud_trange.y ? BLUE * 0.5 : ( gForClouds( view_ray.o + to.t * view_ray.d, scene_params.b, scene_params.cloud_animation_params, aChannel0 ) + 1.0 ) * 0.5;
	}

#endif

	vec3 real_sun_color = vec3( 1. );

	if ( enable_sky_and_clouds == 1 )
	{
#ifndef CLOUD_AND_SKY_AS_DOWNSIZED_BUFFER

		if ( outside_visible )
		{
			col = atmEval_WithClouds( view_ray, atm_out, scene_params.sun_direction, scene_params.b, uv
									  , first_cloud_t, cloud_trange, scene_params.cloud_animation_params, aChannel0 );
		}
#else
		if ( sun_center_uv == saturate( sun_center_uv ) )
		{
			// if the sun is visible-ish read the value from its center in bufB
			float a = ( 1.0 / aspect );
			float b = 2.0 / aResolution.x;
			float fade = ( ( 1.0 - smoothstep( 0.5 - b, 0.5, abs( uv.x - 0.5 ) ) ) *
						   ( 1.0 - smoothstep( a * 0.5 - b, a * 0.5, abs( uv.y * a - a * 0.5 ) ) ) );
			real_sun_color = mix( real_sun_color, texture( aChannel1, sun_center_uv * CLOUD_AND_SKY_AS_BUFFER_DOWWNSCALE ).xyz, fade ); // calcCloudsAndSky_bufB
		}

		if ( outside_visible )
		{
		#if 0
			col = texture( aChannel1, uv* CLOUD_AND_SKY_AS_BUFFER_DOWWNSCALE ).xyz; // calcCloudsAndSky_bufB
		#else
			// perform a manly edge clamp as we only use downsize area and we have garbage RED on borders
			vec2 x = ( fragCoord.xy * CLOUD_AND_SKY_AS_BUFFER_DOWWNSCALE - vec2( 0.5 ) );
			vec2 f = fract( x );
			ivec2 p00 = ivec2( floor( x ) );
			ivec2 edge = ivec2( aResolution.xy / 2.0 ) - ivec2( 1, 1 );
			vec3 c00 = texelFetch( aChannel1, clamp( p00 + ivec2( 0, 0 ), ivec2( 0, 0 ), edge ), 0 ).xyz;
			vec3 c10 = texelFetch( aChannel1, clamp( p00 + ivec2( 1, 0 ), ivec2( 0, 0 ), edge ), 0 ).xyz;
			vec3 c01 = texelFetch( aChannel1, clamp( p00 + ivec2( 0, 1 ), ivec2( 0, 0 ), edge ), 0 ).xyz;
			vec3 c11 = texelFetch( aChannel1, clamp( p00 + ivec2( 1, 1 ), ivec2( 0, 0 ), edge ), 0 ).xyz;
			col = mix( mix( c00, c10, f.x ), mix( c01, c11, f.x ), f.y );
		#endif
			if ( uv.x > 0.5 && ( enable_solid_clouds_half_screen == 1 ) ) return col;
		}
#endif
	}

//	col = mix( col, GREEN, smoothbump( get_horizon_elevation( earth_center, earth_radius, view_ray.o ), 1e-2, get_ray_elevation( earth_center, view_ray ) ) ); // show the horizon

	if ( ( scene_params.enable_sun_flares == 1 ) || ( scene_params.enable_sun_glare == 1 ) )
	{
		add_sun_glow_and_flares( col, view_ray, center_view_ray, scene_params, outside_visible, real_sun_color, aTime );
	}

	col = tonemap_reinhard( col, iExposure );
//	col = max( vec3( 0 ), contrast( col, vec3( 1.05 ) ) );
	col *= 0. + 1. * pow( 20. * uv.x * uv.y * ( 1. - uv.x ) * ( 1. - uv.y ), 0.075 ); // vignette
//	col = gamma_correction( col );
	col = gamma_correction_itu( col );
	col *= scene_params.fade;
	
	return col;
}

#define BUFFERA void mainImage( out vec4 fragColor, in vec2 fragCoord ) { fragColor = calcCloudHeightMap_bufA( fragCoord, iResolution, iFrame, iMouse, iChannel0, iChannel1 ); }
#define BUFFERB void mainImage( out vec4 fragColor, in vec2 fragCoord ) { fragColor = vec4( calcCloudsAndSky_bufB( fragCoord, iTime, iResolution, iMouse, iChannel0 ), 1.0 ); }
#define IMAGE void mainImage( out vec4 fragColor, in vec2 fragCoord ) { fragColor = vec4( calcFinalImage( fragCoord, iTime, iResolution, iMouse, iChannel0, iChannel1 ), 1.0 ); }
