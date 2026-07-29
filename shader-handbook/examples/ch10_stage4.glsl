// 第 10 章 · 阶梯实战 · 阶段 4：fbm 密度 → 一团真正的「云」
// 密度不再是解析球，而是高度窗 × (fbm - 阈值)。抖动保留。
#define STEPS 56

float hash13(vec3 p)
{
    p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}

float vnoise(vec3 x)
{
    vec3 i = floor(x), f = fract(x);
    f = f*f*(3.0 - 2.0*f);
    return mix(mix(mix(hash13(i + vec3(0,0,0)), hash13(i + vec3(1,0,0)), f.x),
                   mix(hash13(i + vec3(0,1,0)), hash13(i + vec3(1,1,0)), f.x), f.y),
               mix(mix(hash13(i + vec3(0,0,1)), hash13(i + vec3(1,0,1)), f.x),
                   mix(hash13(i + vec3(0,1,1)), hash13(i + vec3(1,1,1)), f.x), f.y), f.z);
}

float fbm(vec3 p)
{
    float v = 0.0, a = 0.5;
    mat3  m = mat3( 0.00,  0.80,  0.60,
                   -0.80,  0.36, -0.48,
                   -0.60, -0.48,  0.64);
    for (int i = 0; i < 5; i++) {
        v += a * vnoise(p);
        p  = m * p * 2.02;
        a *= 0.5;
    }
    return v;
}

float density(vec3 p)
{
    // 高度窗：只在某一层有云
    float hy = smoothstep(0.0, 0.25, p.y) * smoothstep(1.35, 0.75, p.y);
    // 水平范围
    float hr = 1.0 - smoothstep(1.1, 1.9, length(p.xz));
    float n  = fbm(p * 1.35 + vec3(iTime*0.05, 0.0, iTime*0.03));
    // 阈值：调大云更碎更稀
    float d  = n - 0.48;
    return clamp(d * 1.8 * hy * hr, 0.0, 1.0);
}

float hash21(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec3 sky(vec3 rd)
{
    float h = clamp(rd.y*0.5 + 0.5, 0.0, 1.0);
    vec3  col = mix(vec3(0.55, 0.65, 0.85), vec3(0.18, 0.32, 0.62), h);
    col = mix(col, vec3(0.95, 0.75, 0.55), pow(1.0 - max(rd.y, 0.0), 6.0)*0.35);
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0*fragCoord - iResolution.xy) / iResolution.y;

    vec3 ro = vec3(0.0, 0.55, 3.4);
    vec3 ta = vec3(0.0, 0.55, 0.0);
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0,1,0)));
    vec3 vv = cross(uu, ww);
    vec3 rd = normalize(uv.x*uu + uv.y*vv + 1.5*ww);

    float tMin = 1.2, tMax = 5.5;
    float dt   = (tMax - tMin) / float(STEPS);
    float t    = tMin + hash21(fragCoord) * dt;

    float T = 1.0;
    vec3  col = vec3(0.0);
    const float SIGMA_T = 3.5;
    const float SIGMA_S = 3.2;
    const vec3  ALBEDO  = vec3(1.0);

    for (int i = 0; i < STEPS; i++) {
        vec3  p = ro + rd * t;
        float d = density(p);
        if (d > 1e-4) {
            col += T * ALBEDO * (SIGMA_S * d) * dt;
            T   *= exp(-SIGMA_T * d * dt);
            if (T < 0.02) break;
        }
        t += dt;
        if (t > tMax) break;
    }

    col += T * sky(rd);
    fragColor = vec4(col, 1.0);
}
