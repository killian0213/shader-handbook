// Buf A (buffer) — Bring the heat by ddsol
// https://www.shadertoy.com/view/4sfBWj

const mat2 m = mat2( 0.8,  0.6, -0.6,  0.8 );
const mat3 m3 = mat3( 0.8,  0.6, 0.0, -0.6,  0.80, 0.0, 0.0, 0.0, 1.0) *
                mat3( 1.0,  0.0, 0.0, 0.0, -0.60,  0.80, 0.0, 0.8, 0.6) *
                mat3( 0.8, 0.6, 0.0, -0.6,  0.80, 0.0, 0.0, 0.0, 1.0) *
                mat3( 1.0,  0.0, 0.0, 0.0, -0.60,  0.80, 0.0, 0.8, 0.6);

float time;

float n1f0(float p) {
    return fract(sin(p * 1.7227636) * 8.03e2);
}

float n1f1(float p) {
    return fract(sin(p * 1.42736 + 1.12) * 5.1e2);
}

float n1f2(float p) {
    return fract(sin(p * 1.22712 + 12.161) * 5.2e2);
}


float n3f(vec3 p) {
    return fract(n1f0(p.x) + n1f1(p.y) + n1f2(p.z) + n1f0(p.x * 1.613) + n1f1(p.y * 3.112) + n1f2(p.z * 4.112));
}

float n3(vec3 p) {
    vec3 b = floor(p);
    vec3 e = b + vec3(1.0);
    vec3 f = smoothstep(vec3(0.0), vec3(1.0), fract(p));
    float c000 = n3f(b);
    float c001 = n3f(vec3(b.x, b.y, e.z));
    float c010 = n3f(vec3(b.x, e.y, b.z));
    float c011 = n3f(vec3(b.x, e.y, e.z));
    float c100 = n3f(vec3(e.x, b.y, b.z));
    float c101 = n3f(vec3(e.x, b.y, e.z));
    float c110 = n3f(vec3(e.x, e.y, b.z));
    float c111 = n3f(e);
    vec4 z = mix(vec4(c000, c100, c010, c110), vec4(c001, c101, c011, c111),  f.z);
    vec2 yz = mix(z.xy, z.zw, f.y);
    return mix(yz.x, yz.y, f.x);
    
}


float fbm4( vec3 p )
{
    float f = 0.0;
    p = m3 * p;
    f +=     0.5000*n3( p ); p = m3*p*2.02;
    f +=     0.2500*n3( p ); p = m3*p*2.03;
    f +=     0.1250*n3( p ); p = m3*p*2.01;
    f +=     0.0625*n3( p );
    return f/0.9375;
}

float fbm4( vec2 p )
{
    return fbm4(vec3(p, time));
}

float fbm6( vec3 p )
{
    float f = 0.0;
    p = m3 * p;
    f +=     0.500000*n3( p ); p = m3*p*2.02;
    f +=     0.250000*n3( p ); p = m3*p*2.03;
    f +=     0.125000*n3( p ); p = m3*p*2.01;
    f +=     0.062500*n3( p ); p = m3*p*2.04;
    f +=     0.031250*n3( p ); p = m3*p*2.01;
    f +=     0.015625*n3( p );
    return f/0.984375;
}


float fbm6( vec2 p )
{
    return fbm6(vec3(p, time));
}

float grid(vec2 p) {
    p = sin(p * 3.1415);
    return smoothstep(-0.01, 0.01, p.x * p.y);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    time = iTime * 0.7;
    
    vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= iResolution.x/iResolution.y;
    p.y *= 0.3;
    p.y -= time * 1.5;
    float tc = time * 1.2;
    float tw1 = time * 2.5;
    float tw2 = time * 0.6;

    vec3 vw1 = vec3(p, tw1);
    vw1.y *= 2.8;
    vec2 ofs1 = vec2(fbm4(vw1), fbm4(vw1 + vec3(10.0, 20.0, 50.0)));
    ofs1.y *= 0.3;
    ofs1.x *= 1.3;

    vec3 vw2 = vec3(p, tw2);
    vw2.y *= 0.8;
    vec2 ofs2 = vec2(fbm4(vw2), fbm4(vw2 + vec3(10.0, 20.0, 50.0)));
    ofs2.y *= 0.3;
    ofs2.x *= 1.3;
    
    vec2 vs = (p + ofs1 * 0.5 + ofs2 * 0.9) * 4.0;
    vec3 vc = vec3(vs, tc);
    float l;
    l = fbm6(vc);
    l = smoothstep(0.0, 1.0, l);
    l = max(0.0, (l - pow(q.y * 0.8, 0.6)) * 1.8);
    float r = pow(l , 1.5);
    float g = pow(l , 3.0);
    float b = pow(l , 6.0);
    
    //r = grid(vs);
    fragColor = vec4( r, g, b, 1.0 );
    
}
