// Buffer A (buffer) — Protein by iq
// https://www.shadertoy.com/view/M3BfW3

// precompute spheres
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 ip = ivec2(fragCoord);
    
    if( iFrame>2 || ip.x>=256 || ip.y>128 ) discard;
    
    int id = (ip.y<<8) + ip.x;

    fragColor = createSphere( uint(id) );
}