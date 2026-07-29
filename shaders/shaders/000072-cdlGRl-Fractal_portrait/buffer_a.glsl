// Buffer A (buffer) — Fractal portrait by loicvdb
// https://www.shadertoy.com/view/cdlGRl

#define eps 0.0002
#define fp 8.0
#define twopi 6.28318530718
#define lo normalize(vec3(0.9, -0.1, -0.2))

uint seed;
float ot;

float de(vec3 c)
{
    vec3 z = c;
    float dr = 1.0;
    float r = length(z);
    ot = 1.0;
    
    for (int j = 0; j < 11 && r < 4.0; j++)
    {
        dr = dr * r * 2.0 + 1.0;
        float t = acos(z.z / r) * 2.0;
        float p = atan(z.y, z.x) * 2.0;
        z = r * r * vec3(sin(t) * vec2(cos(p), sin(p)), cos(t)) + c;
        r = length(z);
        ot = min(abs(z.z) * 9.0, ot);
    }
    
    return 0.5 * log(r) * r / dr;
}

vec4 trace(vec3 ro, vec3 rd)
{
    float t = 0.0;
    float d = de(ro);
    
    for (int i = 0; i < 128 && d > eps && t < fp + eps; i++)
    {
        t += d;
        d = de(ro + rd * t);
    }
    
    t -= eps;
    
    vec3 p = ro + rd * t;
    vec2 k = vec2(0, eps);
    vec3 n = normalize(vec3(de(p + k.yxx), de(p + k.xyx), de(p + k.xxy)) - de(p));
    
    return vec4(n, t);
}

float hash(int s)
{
    uint i = uint(s) + seed;
    i *= 0xB5297A4Du;
    i ^= i >> 8;
    i += 0x68E31DA4u;
    i ^= i << 8;
    i *= 0x1B56C4E9u;
    i ^= i >> 8;
    return float(i) / float(~0u);
}

vec3 ortho(vec3 n)
{
    return normalize(abs(n.x) > abs(n.z) ? vec3(-n.y, n.x, 0)  : vec3(0, -n.z, n.y));
}

mat3 base(vec3 n)
{
    vec3 o1 = n;
    vec3 o0 = ortho(o1);
    return mat3(o0, cross(o0, o1), o1);
}


vec3 li(vec3 ro, vec3 rd)
{
    vec3 rad = vec3(0);
    vec3 att = vec3(1);
    
    for (int b = 0; b < 4; b++)
    {
        vec4 t = trace(ro, rd);
        if (t.w > fp)
        {
            rad += att * vec3(0.9, 0.8, 0.5) * step(rd.x + rd.z, -0.8);
            rad += att * 0.2;
            break;
        }
        
        ro += t.w * rd;
        
        float la = hash(4 + b * 4) * twopi;
        float lr = 1.0 - 0.04 * hash(5 + b * 4);
        vec3 ld = base(lo) * vec3(sqrt(1.0 - lr * lr) * vec2(cos(la), sin(la)), lr);
        
        float dr = sqrt(hash(6 + b * 4));
        float da = hash(7 + b * 4) * twopi;
        rd = base(t.xyz) * vec3(dr * cos(da), dr * sin(da), sqrt(1.0 - dr * dr));
        
        att *= mix(vec3(1.0, 1.0, 0.9), vec3(0.7, 0.2, 0.3), ot);
        rad += att * vec3(5, 6, 8) * max(0.0, dot(ld, t.xyz)) * float(trace(ro, ld).w > fp);
    }
    
    return rad;
}


void mainImage(out vec4 o, vec2 u)
{
    seed ^= 0x300A6F5Eu * uint(iFrame);
    seed ^= 0x884C78B7u * uint(u.x);
    seed ^= 0x1F704572u * uint(u.y);
    
    vec2 cuv = (u - 0.5 + vec2(hash(0), hash(1)) - iResolution.xy * 0.5) / iResolution.y;
    
    vec3 rot = vec3(0.95, -0.1, 4.2);
    vec3 c = cos(rot);
    vec3 s = sin(rot);
    mat3 rx = mat3(1, 0, 0, 0, c.x, s.x, 0, -s.x, c.x);
    mat3 ry = mat3(c.y, 0, -s.y, 0, 1, 0, s.y, 0, c.y);
    mat3 rz = mat3(c.z, s.z, 0, -s.z, c.z, 0, 0, 0, 1);
    mat3 cam = rx * ry * rz;
    
    float a = hash(2) * twopi;
    vec3 ap = 0.1 * sqrt(hash(3)) * vec3(cos(a), sin(a), 0);
    
    vec3 rd = cam * normalize(vec3(cuv * 3.0, 4.6) - ap);
    vec3 ro = cam * (vec3(0, -0.2, -5) + ap);
    
    vec4 tex = texelFetch(iChannel0, ivec2(u), 0);
    uint m = floatBitsToUint(tex.w) + 1u;
    o = vec4(mix(tex.xyz, li(ro + 4.0 * rd, rd), 1.0 / float(m)), uintBitsToFloat(m));
}