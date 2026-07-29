// Buffer B (buffer) — singularity space by latel88
// https://www.shadertoy.com/view/3dlyRN

bool hasAABB ( const in vec3 rdX, const in vec3 rdY, const in vec3 rdZ, const in vec3 ro, const in int index, const in int count, const in float fov, const in vec2 AABB_size, const in vec2 AABB_center )
{
    Entity entity = getEntity( iChannel0, index, count, iResolution.xy );
    
    if (length( entity.position - ro ) > 1.75)
    {
        Project proj = projectSphere( rdX, rdY, rdZ, ro, entity.position, entity.radius, fov );

        vec2 so = proj.uv;
        float sr = proj.radius;
        vec2 bo = AABB_center;
        vec2 br = AABB_size;

        vec2 vDelta = max( vec2(0.0), abs( bo - so ) - br );

        return dot( vDelta, vDelta ) <= sr * sr;
        
    }
    
    return false;
    
}

vec4 computeCulling ( const in vec3 rdX, const in vec3 rdY, const in vec3 rdZ, const in vec3 ro, const in float fov, const in vec2 resolution, const in vec2 coord )
{
    vec2 tile = vec2(TileSize);
    ivec2 tile_resolution = ivec2(listResolution / tile);
    
    vec2 fix = iResolution.xy / min( iResolution.x, iResolution.y );

	ivec2 AABB_coord = ivec2(coord) / tile_resolution;
    vec2 AABB_size = 1.0 / tile * fix;
	vec2 AABB_center = vec2(AABB_coord) * AABB_size + AABB_size / 2.0 - fix * 0.5;
    
    ivec2 tile_start_coord = AABB_coord * tile_resolution;
    ivec2 tile_end_coord =  (AABB_coord + 1) * tile_resolution;
    
    ivec2 tile_fix_resolution = tile_end_coord - tile_start_coord;
    ivec2 tile_coord = ivec2(coord) - tile_start_coord;
    
  	int index = tile_coord.y * tile_fix_resolution.x + tile_coord.x;
	int count = EntityCount;
    int entity_index = index * 4;

    return vec4(
        entity_index + 0 < count && hasAABB( rdX, rdY, rdZ, ro, entity_index + 0, count, fov, AABB_size, AABB_center ) ? 1 : 0,
        entity_index + 1 < count && hasAABB( rdX, rdY, rdZ, ro, entity_index + 1, count, fov, AABB_size, AABB_center ) ? 1 : 0,
        entity_index + 2 < count && hasAABB( rdX, rdY, rdZ, ro, entity_index + 2, count, fov, AABB_size, AABB_center ) ? 1 : 0,
        entity_index + 3 < count && hasAABB( rdX, rdY, rdZ, ro, entity_index + 3, count, fov, AABB_size, AABB_center ) ? 1 : 0
    );
    
}

void mainImage ( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 resolution = listResolution;
    vec2 coord = fragCoord;
    
    vec4 o = vec4(0.0);
    
    if (coord.x < resolution.x && coord.y < resolution.y)
    {
    	Camera cam = createCamera( iMouse, iTime );
    	vec3 rdZ = yawPitchToDirection( cam.direction, vec2(0.5), 1.0 );
        vec3 rdY = yawPitchToDirection( vec2(cam.direction.x, cam.direction.y - HALF), vec2(0.5), 1.0 );
        vec3 rdX = normalize( cross( rdZ, rdY ) );

        o = computeCulling( rdX, rdY, rdZ, cam.position, cam.fov, resolution, coord );
        
    }
    
    fragColor = o;
	
}