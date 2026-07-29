// Buffer A (buffer) — wireframe stellated dodecahedron by ChunderFPV
// https://www.shadertoy.com/view/McfXzr

// wireframe code from FabriceNeyret2: https://www.shadertoy.com/view/XfS3DK

#define A(v) mat2(cos((v*3.1416) + vec4(0, -1.5708, 1.5708, 0)))          // rotate
#define s(a, b) c = max(c, .006/abs(L( u, K(a, v, h), K(b, v, h) )+.02)); // segment

// line
float L(vec2 p, vec3 A, vec3 B)
{
    vec2 a = A.xy, 
         b = B.xy - a;
         p -= a;
    float h = clamp(dot(p, b) / dot(b, b), 0., 1.);
    return length(p - b*h) + .01*mix(A.z, B.z, h);
}

// cam
vec3 K(vec3 p, mat2 v, mat2 h)
{
    p.zy *= v; // pitch
    p.zx *= h; // yaw
    if (texelFetch(iChannel0, ivec2(80, 2), 0).x < 1.) // P key
        p *= 4. / (p.z+4.); // perspective view
    return p;
}

void mainImage( out vec4 C, in vec2 U )
{
    vec2 R = iResolution.xy,
         u = (U+U-R)/R.y*3.,
         m = (iMouse.xy*2.-R)/R.y;
    
    float t = iTime/120.,
          a = 1.618; // use -.618 for icosa
    
    if (iMouse.z < 1.) // not clicking
        m = vec2(sin(t*6.2832)*2., sin(t*6.2832*2.)*.7); // fig-8 movement
    
    mat2 v = A(m.y), // pitch
         h = A(m.x); // yaw
    
    vec3 c = vec3(0);
    
    // stellated dodeca
    s( vec3(-1,  a,  0), vec3( 0, -1, -a) )
    s( vec3(-1,  a,  0), vec3( 0, -1,  a) )
    s( vec3(-1,  a,  0), vec3( a,  0, -1) )
    s( vec3(-1,  a,  0), vec3( a,  0,  1) )
    s( vec3( 1,  a,  0), vec3( 1, -a,  0) )
    s( vec3( 1,  a,  0), vec3( 0, -1, -a) )
    s( vec3( 1,  a,  0), vec3( 0, -1,  a) )
    s( vec3( 1,  a,  0), vec3(-a,  0, -1) )
    s( vec3( 1,  a,  0), vec3(-a,  0,  1) )
    s( vec3(-1, -a,  0), vec3(-1,  a,  0) )
    s( vec3(-1, -a,  0), vec3( 0,  1, -a) )
    s( vec3(-1, -a,  0), vec3( 0,  1,  a) )
    s( vec3(-1, -a,  0), vec3( a,  0, -1) )
    s( vec3(-1, -a,  0), vec3( a,  0,  1) )
    s( vec3( 1, -a,  0), vec3( 0,  1, -a) )
    s( vec3( 1, -a,  0), vec3( 0,  1,  a) )
    s( vec3( 1, -a,  0), vec3(-a,  0, -1) )
    s( vec3( 1, -a,  0), vec3(-a,  0,  1) )
    s( vec3( 0,  1, -a), vec3( 0,  1,  a) )
    s( vec3( 0,  1, -a), vec3( a,  0,  1) )
    s( vec3( 0,  1, -a), vec3(-a,  0,  1) )
    s( vec3( 0, -1, -a), vec3( 0, -1,  a) )
    s( vec3( 0, -1, -a), vec3( a,  0,  1) )
    s( vec3( 0, -1, -a), vec3(-a,  0,  1) )
    s( vec3(-a,  0, -1), vec3( a,  0, -1) )
    s( vec3(-a,  0,  1), vec3( a,  0,  1) )
    s( vec3(-a,  0, -1), vec3( 0,  1,  a) )
    s( vec3(-a,  0, -1), vec3( 0, -1,  a) )
    s( vec3( a,  0, -1), vec3( 0,  1,  a) )
    s( vec3( a,  0, -1), vec3( 0, -1,  a) )
    
    C = vec4(min(c, 1.), 1);
}