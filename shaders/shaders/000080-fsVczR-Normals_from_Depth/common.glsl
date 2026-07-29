// Common (common) — Normals from Depth by iq
// https://www.shadertoy.com/view/fsVczR

void camera( out vec3 ro, out vec3 rd, in float time, in vec2 p)
{
    // screen split
    p.x -= sign(p.x)*1.77777*0.5;

    // camera position and target
    ro = vec3(0.5, 0.3, 0.5 );
    vec3 ta = ro + vec3( -1.0, 0.0, -1.0 );
    
    // contruct ray
    vec3 cw = normalize( ta-ro );
    vec3 cp = vec3( 0.0, 1.0, 0.0 );
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    rd = normalize( p.x*cu + p.y*cv + 1.8*cw );
}