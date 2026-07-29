// Common (common) — singularity space by latel88
// https://www.shadertoy.com/view/3dlyRN

//#define DEBUG_CULLING
//#define DEBUG_LOOP
//#define DEBUG_LIST
#define EFFECT

#define FOV 0.5
#define ENTITY_MAX 5000
#define MARCH_STEP 100
#define MARCH_DISTANCE 20.0

#define SINGULARITY_RADIUS 6.667

#define QUATER 0.7853981633974483
#define HALF 1.5707963267948966
#define PI 3.141592653589793
#define CIRCLE 6.283185307179586

#define TS max( 1.0, sqrt( (iResolution.x * iResolution.y * 4.0) / float(ENTITY_MAX) ) )
#define TileSize (TS - mod(TS, 2.0))
#define listResolution (iResolution.xy - mod( iResolution.xy, vec2(TileSize) ))
#define EntityCount int(min( float(ENTITY_MAX), (listResolution.x / TileSize) * (listResolution.y / TileSize) * 4.0 ))

#define modI(a,b) floor(a-floor((a+0.5)/b)*b+0.5)

#define hasInResolution(pos,rez) all(bvec2(all(greaterThanEqual(ivec2(pos),ivec2(0.0))),bvec2(all(lessThan(ivec2(pos),ivec2(rez))))))
#define getCheckerPos(coord) floor(mod(coord.y+modI(coord.x,2.0),2.0))

struct Camera
{
	vec3 position;
	vec2 direction;//pitch yaw
	float fov;

};

struct Entity
{
	vec3 position;
    float rotate;
    float radius;
    
};
    
struct Singularity
{
   	vec3 position;
    float radius;
    float force;
    
};
struct Project
{
    vec2 uv;
    float radius;
    
};

const vec2 checkerOffset[4] = vec2[4](
	vec2( 0, 0),
    vec2(-1, 0),
    vec2( 0, 1),
    vec2( 0,-1)
);

vec2 getAspect ( const in vec2 resolution )
{
    return resolution.xy / min( resolution.x, resolution.y );
    
}

float getFrameTime ( const in float delta )
{
  	return delta * 100.0 / 2.0;
    
}

float hash ( const in float p )
{
    return (fract( sin( p ) * CIRCLE ) - 0.5) / 0.5;
    
}
  
float hashAbs ( const in float p )
{
    return fract( sin( p ) * CIRCLE );
    
}

float atan2 ( const in float y, const in float x )
{
    return x == 0.0 ? sign( y ) * PI / 2.0 : atan( y, x );
    
}

vec3 rotate ( vec3 pos, vec3 axis,float theta )
{
    axis = normalize( axis );
    
    vec3 v = cross( pos, axis );
    vec3 u = cross( axis, v );
    
    return u * cos( theta ) + v * sin( theta ) + axis * dot( pos, axis );   
    
}

vec2 getEmbedCheckerCoord ( const in vec2 coord )
{
    vec2 cd = floor( coord );

    return vec2(
        cd.x * 2.0 + mod( cd.y, 2.0 ),
        cd.y

    );

}

struct CheckerCoord {
    ivec2 cd;
    bool isEmpty;
    int flip;
    vec2 coord;
    vec2 rez;

};

CheckerCoord getBufferCheckerCoord ( const in vec2 coord, const in vec2 rez )
{
    vec2 cd = floor( coord );
    float pos = mod( cd.x + cd.y, 2.0 );

    return CheckerCoord(
        ivec2(
            cd.x / 2.0,
            cd.y

        ),
        pos == 1.0,
        mod( cd.y, 2.0 ) == 0.0 ? 1 :-1,
        cd,
        rez

    );

}

vec4 getCheckerPixel ( const in sampler2D tex, const in ivec2 coord, const in ivec2 offset, const in vec2 rez, inout float div )
{
    vec4 color = vec4(0.0);
    ivec2 cd = coord + offset;

	if (hasInResolution( cd, rez ))
	{
        color = texelFetch( tex, cd, 0 );
        div += 1.0;

	}

    return color;

}

vec4 restoreCheckerBuffer ( const in sampler2D tex, const in CheckerCoord c )
{
    float div = 1.0;
    vec4 color = texelFetch( tex, c.cd, 0 );

    if (c.isEmpty)
    {
        color += getCheckerPixel( tex, c.cd, ivec2(c.flip, 0), c.rez, div );
        color += getCheckerPixel( tex, c.cd, ivec2( 0, 1), c.rez, div );
        color += getCheckerPixel( tex, c.cd, ivec2( 0,-1), c.rez, div );

    }

    return color / div;

}

//Copy to https://www.shadertoy.com/view/MdlGz4
vec3 yawPitchToDirection ( const in vec2 dir, const in vec2 uv , const in float fov )
{
	float xCos = cos( dir.x );
	float xSin = sin( dir.x );
	float yCos = cos( dir.y );
	float ySin = sin( dir.y );
	
	float gggxd = uv.x - 0.5;
	float ggyd = uv.y - 0.5;
	float ggzd = fov;
	
	float gggzd = ggzd * yCos + ggyd * ySin;
	
	return normalize( vec3(
		gggzd * xCos - gggxd * xSin,
		ggyd * yCos - ggzd * ySin,
		gggxd * xCos + gggzd * xSin
		
	) );

}

//Copy to https://www.shadertoy.com/view/MscSRr
Project projectSphere ( const in vec3 rdX, const in vec3 rdY, const in vec3 rdZ, const in vec3 ro, const in vec3 so, const in float sr, const in float fov )
{
	vec3 vel = so - ro;

	float cx = dot( vel, rdX );
	float cy = dot( vel, rdY );
	float cz = dot( vel, rdZ );
	
	float dz = dot( vel, rdZ );

    return Project(
		vec2(
            (cx / cz),
			(cy / cz)
            
        ) * fov,
		(sr * distance(vec2(1.0), vec2(0.0)) / dz) * fov
		
	);

}

Camera createCamera ( const in vec4 mouse, const in float time )
{
    float t = time / 10.0;
    vec3 pos = vec3((MARCH_DISTANCE / 2.0) + (MARCH_DISTANCE / 4.0) * sin( t ), MARCH_DISTANCE / 4.0, (MARCH_DISTANCE / 2.0) + (MARCH_DISTANCE / 4.0) * cos( t ));
    vec2 dir = vec2( atan2( pos.z - (MARCH_DISTANCE / 2.0), pos.x - (MARCH_DISTANCE / 2.0) ), -HALF - QUATER + 0.1);
    
    return Camera( pos, dir, FOV );
    
}

Entity getEntity ( const in sampler2D buffer, const in int index, const in int length, const in vec2 resolution )
{
    int i = length + index + 1;
    vec4 entity = texelFetch( buffer, ivec2(modI( float(i), resolution.x ), floor( float(i) / resolution.x )), 0  );
    vec3 pos = entity.rgb;
    float rotate = entity.a;
    float scale = 0.325 + hashAbs( float(index) * 0.87965 * float(index) ) * 0.125;

    if (pos.x == 0.0 && pos.y == 0.0 && pos.z == 0.0)
    {
        pos = vec3(
            hashAbs( float(index) * 0.012345 ) * MARCH_DISTANCE,
           	hashAbs( float(index) * 0.023154 ) * MARCH_DISTANCE,
            hashAbs( float(index) * 0.035312 ) * MARCH_DISTANCE

        );
        
        rotate = hashAbs( float(index) * 0.045131 );

    }
    
    pos = mod( pos, vec3(MARCH_DISTANCE) );
    
    return Entity( pos, rotate, scale );
    
}

Singularity getSingularity ( const in float time )
{
    float speed = 2.0;
    float radius = SINGULARITY_RADIUS;
    
    int index = int(floor( time / speed ));
    
   	vec3 pos = vec3(
        radius / 2.0 + hashAbs( float(index + 5) * 0.151 ) * (MARCH_DISTANCE - radius),
        radius / 2.0 + hashAbs( float(index + 5) * 0.781 ) * (MARCH_DISTANCE - radius),
        radius / 2.0 + hashAbs( float(index + 5) * 0.914 ) * (MARCH_DISTANCE - radius)
    
    );
    
    float force = cos( mod( time, speed ) / speed * PI );
    
    radius *= max( 0.0, sin( force * PI / 2.0 ) );
    
    return Singularity( pos, radius, force );
    
}
