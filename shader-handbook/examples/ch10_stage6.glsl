// 第 10 章 · 阶梯实战 · 阶段 6：打磨成片
// 几何仍是一朵 fbm 云。新增：地面、高度雾、powder 薄区修正、
// 软膝 tonemap、暗角。对照阶段 5 —— 氛围感跨一档。
#define STEPS 72

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
    return mix(mix(mix(hash13(i+vec3(0,0,0)), hash13(i+vec3(1,0,0)), f.x),
                   mix(hash13(i+vec3(0,1,0)), hash13(i+vec3(1,1,0)), f.x), f.y),
               mix(mix(hash13(i+vec3(0,0,1)), hash13(i+vec3(1,0,1)), f.x),
                   mix(hash13(i+vec3(0,1,1)), hash13(i+vec3(1,1,1)), f.x), f.y), f.z);
}
float fbm(vec3 p)
{
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * vnoise(p);
        p = p * 2.05 + vec3(100.0);
        a *= 0.5;
    }
    return v;
}
float hash21(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float density(vec3 p)
{
    float hy = smoothstep(0.10, 0.35, p.y) * smoothstep(1.45, 0.85, p.y);
    float hr = 1.0 - smoothstep(1.05, 1.95, length(p.xz));
    float n  = fbm(p*1.20 + vec3(iTime*0.035, 0.0, -iTime*0.025));
    return clamp((n - 0.46) * 2.0 * hy * hr, 0.0, 1.0);
}

float henyeyGreenstein(float cosTheta, float g)
{
    float g2 = g*g;
    return (1.0 - g2) / (4.0*3.14159 * pow(1.0 + g2 - 2.0*g*cosTheta, 1.5));
}

float powder(float od) { return 1.0 - exp(-od * 2.0); }

vec3 sky(vec3 rd, vec3 sun)
{
    float h = clamp(rd.y*0.5+0.5, 0.0, 1.0);
    vec3  col = mix(vec3(0.70, 0.78, 0.95), vec3(0.22, 0.40, 0.72), pow(h, 0.7));
    col = mix(col, vec3(1.00, 0.72, 0.45), pow(1.0 - max(rd.y, 0.0), 8.0)*0.45);
    float s = pow(max(dot(rd, sun), 0.0), 12.0);
    col += vec3(1.0, 0.90, 0.65) * s * 0.85;
    return col;
}

vec3 softKnee(vec3 c)
{
    const float K = 0.85;
    vec3 hi = max(c - K, 0.0);
    return min(c, vec3(K)) + (1.0 - K) * (1.0 - exp(-hi / (1.0 - K)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0*fragCoord - iResolution.xy) / iResolution.y;

    vec3 sun = normalize(vec3(0.60, 0.48, -0.30));
    float ang = 0.15*sin(iTime*0.12);
    vec3  ro  = vec3(sin(ang)*0.4, 0.42, 3.6);
    vec3  ta  = vec3(0.0, 0.55, 0.0);
    vec3  ww  = normalize(ta - ro);
    vec3  uu  = normalize(cross(ww, vec3(0,1,0)));
    vec3  vv  = cross(uu, ww);
    vec3  rd  = normalize(uv.x*uu + uv.y*vv + 1.55*ww);

    // —— 地面（解析）——
    vec3 bg = sky(rd, sun);
    if (rd.y < -0.002) {
        float tg = (0.0 - ro.y) / rd.y;
        if (tg > 0.0 && tg < 40.0) {
            vec3 gp = ro + rd * tg;
            float chk = mod(floor(gp.x*0.6)+floor(gp.z*0.6), 2.0);
            vec3 ground = mix(vec3(0.22, 0.26, 0.18), vec3(0.32, 0.36, 0.26), chk);
            float sunVis = smoothstep(0.0, 0.2, dot(vec3(0,1,0), sun));
            ground *= 0.35 + 0.65*sunVis;
            // 高度/距离雾：解析体积的廉价版
            float fog = 1.0 - exp(-0.012 * tg * tg);
            bg = mix(ground, sky(rd, sun), fog);
        }
    }

    float mu = dot(rd, sun);
    float phase = mix(henyeyGreenstein(mu, 0.55),
                      henyeyGreenstein(mu,-0.25), 0.4);

    float tMin = 1.4, tMax = 6.0;
    float dt   = (tMax - tMin) / float(STEPS);
    float t    = tMin + hash21(fragCoord)*dt;

    float T = 1.0;
    vec3  col = vec3(0.0);
    const float SIGMA_T = 4.0;
    const float SIGMA_S = 3.6;

    for (int i = 0; i < STEPS; i++) {
        vec3  p = ro + rd * t;
        float d = density(p);
        if (d > 1e-4) {
            float dS  = density(p + sun * 0.16);
            float dif = clamp((d - dS)*3.2 + 0.22, 0.12, 1.6);
            float od  = SIGMA_T * d * dt;
            float pwd = mix(1.0, powder(od*8.0), clamp(mu*0.5+0.5, 0.0, 1.0));
            vec3  lin = vec3(0.50, 0.65, 0.95)*0.40
                      + vec3(1.00, 0.88, 0.68)*dif*phase*1.15*pwd;
            col += T * lin * (SIGMA_S * d) * dt;
            T   *= exp(-od);
            if (T < 0.015) break;
        }
        t += dt;
        if (t > tMax) break;
    }

    col += T * bg;

    // 暗角 + 软膝
    vec2 q = fragCoord / iResolution.xy;
    col *= 0.55 + 0.45*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.35);
    col  = softKnee(col);
    col += (hash21(fragCoord) - 0.5) / 255.0;

    fragColor = vec4(col, 1.0);
}
