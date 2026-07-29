// Image (image) — MagicaVoxel by gltracy
// https://www.shadertoy.com/view/MdBGRm

// math const
const float PI = 3.14159265359;
const float DEG_TO_RAD = PI / 180.0;

// height map
float voxel( vec3 pos ) {
	pos = floor( pos );
	float density = textureLod( iChannel0, pos.xz / 2048.0, 0.0 ).x;
	return step( pos.y, floor( density * 32.0 ) );
}

// improvement based on fb39ca4's implementation to remove most of branches :
// https://www.shadertoy.com/view/4dX3zl
// min | x < y | y < z | z < x
//  x  |   1   |   -   |   0  
//  y  |   0   |   1   |   -  
//  z  |   -   |   0   |   1  
float ray_vs_world( vec3 pos, vec3 dir, out vec3 mask, out vec3 center ) {
	// grid space
	vec3 grid = floor( pos );
	vec3 grid_step = sign( dir );
	vec3 corner = max( grid_step, vec3( 0.0 ) );
	
	// ray space
	vec3 inv = vec3( 1.0 ) / dir;
	vec3 ratio = ( grid + corner - pos ) * inv;
	vec3 ratio_step = grid_step * inv;
	
	// dda
	float hit = -1.0;
	for ( int i = 0; i < 512; i++ ) {
		if ( voxel( grid ) > 0.5 ) {
			hit = 1.0;
			continue;
		}

		vec3 cp = step( ratio, ratio.yzx );

		mask = cp * ( vec3( 1.0 ) - cp.zxy );
		
		grid  += grid_step  * mask;		
		ratio += ratio_step * mask;
	}
	
	center = grid + vec3( 0.5 );
	return dot( ratio - ratio_step, mask ) * hit;
}

// improvement based on iq's implementation to remove lots of redundant texture accesses :
// https://www.shadertoy.com/view/4dfGzs
void occlusion( vec3 v, vec3 n, out vec4 side, out vec4 corner ) {
	vec3 s = n.yzx;
	vec3 t = n.zxy;

	side = vec4 (
		voxel( v - s ),
		voxel( v + s ),
		voxel( v - t ),
		voxel( v + t )
	);
	
	corner = vec4 (
		voxel( v - s - t ),
		voxel( v + s - t ),
		voxel( v - s + t ),
		voxel( v + s + t )
	);
}

float filterf( vec4 side, vec4 corner, vec2 tc ) {
	vec4 v = side.xyxy + side.zzww + corner;

	return mix( mix( v.x, v.y, tc.y ), mix( v.z, v.w, tc.y ), tc.x ) * 0.25;
}

float ao( vec3 v, vec3 n, vec2 tc ) {
	vec4 side, corner;
	
	occlusion( v + n, abs( n ), side, corner );
	
	return 1.0 - filterf( side, corner, tc );
}

float edge( vec3 v, vec3 n, vec2 tc ) {
	float scale = 1.0 / 12.0;
	tc = fract( tc / scale );
	n *= scale;

	v += abs( n.yzx ) * ( -tc.y + 0.5 );
	v += abs( n.zxy ) * ( -tc.x + 0.5 );

	vec4 side_l, side_h, corner_l, corner_h;
		
	occlusion( v - n, abs( n ), side_l, corner_l );
	occlusion( v + n, abs( n ), side_h, corner_h );

	return 1.0 - filterf(
		vec4( 1.0 ) -   side_l * ( vec4( 1.0 ) -   side_h ),
		vec4( 1.0 ) - corner_l * ( vec4( 1.0 ) - corner_h ),
		tc
	);
}

float grid( vec2 tc ) {
	tc = abs( tc - vec2( 0.5 ) );

	return 1.0 - pow( max( tc.x, tc.y ) * 1.6, 10.0 );
}

// pitch, yaw
mat3 rot3xy( vec2 angle ) {
	vec2 c = cos( angle );
	vec2 s = sin( angle );
	
	return mat3(
		c.y      ,  0.0, -s.y,
		s.y * s.x,  c.x,  c.y * s.x,
		s.y * c.x, -s.x,  c.y * c.x
	);
}

// get ray direction
vec3 ray_dir( float fov, vec2 size, vec2 pos ) {
	vec2 xy = pos - size * 0.5;

	float cot_half_fov = tan( ( 90.0 - fov * 0.5 ) * DEG_TO_RAD );	
	float z = size.y * 0.5 * cot_half_fov;
	
	return normalize( vec3( xy, -z ) );
}

vec3 ray_dir_spherical( float fov, vec2 size, vec2 pos ) {
	vec2 angle = ( pos - vec2( 0.5 ) * size ) * ( fov / size.y * DEG_TO_RAD );

	vec2 c = cos( angle );
	vec2 s = sin( angle );
	
	return normalize( vec3( c.y * s.x, s.y, -c.y * c.x ) );
}

// phong shading
vec3 shading( vec3 v, vec3 n, vec3 eye ) {
	vec3 final = vec3( 0.0 );
	
	// light 0
	{
		vec3 light_pos = vec3( 100.0, 110.0, 150.0 );
		vec3 light_color = vec3( 1.0 );
		vec3 vl = normalize( light_pos - v );
		float diffuse  = max( 0.0, dot( vl, n ) );
		final += light_color * diffuse;
	}

	return final;
}

float fog_uniform( vec3 o, vec3 dir, float d ) {
    float density = 0.01;
    return 1.0 - exp( -d * density );
}

float b = 0.04;
float fog_density( vec3 p ) {
    return exp( -p.y * b );
}

float fog_exp( vec3 o, vec3 dir, float d ) {
   float optic = ( fog_density( o ) - fog_density( o + dir * d ) ) / ( dir.y * b );
   return optic;1.0 - exp( -optic * 0.08 );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	// default ray dir
	vec3 dir = ray_dir( 60.0, iResolution.xy, fragCoord.xy );//_spherical
	
	// default ray origin
	vec3 eye = vec3( 0.0, 0.0, 180.0 );

	// rotate camera
	mat3 rot = rot3xy( vec2( -DEG_TO_RAD * 34.0, iTime * 0.1 ) );
	dir = rot * dir;
	eye = rot * eye;
	
	dir = normalize( dir );
	
	vec3 fog_color = vec3( 0.4, 0.6, 0.8 );

    // grid traversal
	vec3 mask;
	vec3 center;
	float depth = ray_vs_world( eye, dir, mask, center );
    if ( depth < 0.0 ) {
        fragColor = vec4( fog_color, 1.0 );
        return;
    }
    
	vec3 p = eye + dir * depth;
	vec3 n = -mask * sign( dir );

	vec2 tc =
		( fract( p.yz ) * mask.x ) +
		( fract( p.zx ) * mask.y ) +
		( fract( p.xy ) * mask.z );
	
	// ambient occlusion
	float k_ao = ao( center, n, tc );
	
	// grid
	float k_grid = grid( tc );
	
	// edge
	float k_edge = edge( p, n, tc );
	
	// color
	vec3 color = shading( p, n, eye ) * (
		k_ao
		//k_grid *
		//k_edge * k_edge
		);
    
    float att = fog_exp( eye, dir, depth );
	
    
	fragColor = vec4( mix( color, fog_color, att ), 1.0 );
}