// Buffer A (buffer) — singularity space by latel88
// https://www.shadertoy.com/view/3dlyRN

vec3 getForce ( const in sampler2D buffer, const in int index, const in int length, const in vec2 resolution )
{
    int i = index + 1;
    vec3 force = texelFetch( buffer, ivec2(modI( float(i), resolution.x ), floor( float(i) / resolution.x )), 0 ).rgb;
    
    return force;
    
}

vec4 computeForce ( const in int index, const in int count )
{
   	Entity entity = getEntity( iChannel0, index, count,  iResolution.xy  );
   	vec3 force = getForce( iChannel0, index, count, iResolution.xy );
    Singularity singularity = getSingularity( iTime );
    
    float dist = length( entity.position - singularity.position );
    float delta = getFrameTime( iTimeDelta );
    
    if (dist < singularity.radius)
    {
        float impact = mix( 0.000, 0.005, dist / singularity.radius) * max( 0.0, singularity.force );
        vec3 add = (singularity.position - entity.position) * impact;
        
        force += add * delta;
        
    }
    
    force -= force * 0.02 * delta;
    
    return vec4(force, 0.0);
    
}

vec4 computeEntity ( const in int index, const in int count )
{
   	Entity entity = getEntity( iChannel0, index, count,  iResolution.xy  );
   	vec3 force = getForce( iChannel0, index, count, iResolution.xy );
    
    vec3 pos = entity.position;
    float rotate = entity.rotate;
    float delta = getFrameTime( iTimeDelta );
    
    pos += force * delta;
    rotate += (force.x + force.y + force.z) * delta * (sign( hash( float(index) * 0.233 ) ) * 1.5);
    
    return vec4(pos, rotate);
    
}

void mainImage ( out vec4 fragColor, in vec2 fragCoord )
{
    int compute_point = int(fragCoord.y) * int(iResolution.x) + int(fragCoord.x);
    
    vec4 o = vec4(0.0);

    if (compute_point == 0)
    {
        o = vec4(iResolution.xy, 0.0, 0.0);
        
    }
    else
    {
        vec2 resolution = texelFetch( iChannel0, ivec2(0), 0 ).xy;
        
        compute_point -= 1;
        
        if (resolution.x == iResolution.x && resolution.y == iResolution.y)
        {
            int count = EntityCount;
            
            if (compute_point < count)
            {
                o = computeForce( compute_point, count );

            }
            else if (compute_point < count * 2)
            {
                o = computeEntity( compute_point - count, count );

            }
            
        }
        
    }

    fragColor = o;
    
}