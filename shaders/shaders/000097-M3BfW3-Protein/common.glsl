// Common (common) — Protein by iq
// https://www.shadertoy.com/view/M3BfW3

vec4 createSphere( in uint id )
{
    vec4 sphere = vec4(0.0,0.0,0.0,4.0);
    uint levels = uint(floor(log2(float(id))));
    for( uint i=0u; i<levels; i++ ) // i-th node in the root to id-leaf path
    {
        uint  b = id >> (levels-1u-i);
        vec4  r = sin( float(b)*vec4(21.0,13.0,17.0,43.0) + vec4(0.0,2.0,1.0,3.0) );
        float w = sphere.w*(0.73+0.2*r.w);
        sphere = vec4( sphere.xyz + normalize(r.xyz)*(sphere.w-w), w );
    }
    return sphere;
}
