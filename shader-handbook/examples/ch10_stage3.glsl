// 第 10 章 · 阶梯实战 · 阶段 3：抖动消洋葱条带
// 固定步长会在等密度面上留下「洋葱圈」。给每条射线的起点加一点
// 与像素相关的随机偏移，条带就被打散了。按 B 对比：有/无抖动。
#define STEPS 40

const float SIGMA_T = 2.4;
const float SIGMA_S = 2.1;
const vec3  ALBEDO = vec3(0.85, 0.92, 1.00);

float hash21(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float density(vec3 p)
{
    // 两层球，更容易暴露条带
    float d1 = length(p - vec3(-0.35, 0.0, 0.0)) - 0.55;
    float d2 = length(p - vec3( 0.40, 0.10, 0.15)) - 0.48;
    float d  = min(d1, d2);
    return clamp(0.50 - d * 2.0, 0.0, 1.0);
}

vec3 sky(vec3 rd)
{
    return mix(vec3(0.08, 0.10, 0.16), vec3(0.40, 0.55, 0.80),
               pow(max(rd.y, 0.0), 0.55));
}

vec3 integrate(vec3 ro, vec3 rd, float jitter)
{
    float tMin = 0.8, tMax = 4.2;
    float dt   = (tMax - tMin) / float(STEPS);
    float t    = tMin + jitter * dt;   // ★ 抖动：只改起点

    float T   = 1.0;
    vec3  col = vec3(0.0);
    for (int i = 0; i < STEPS; i++) {
        vec3  p = ro + rd * t;
        float d = density(p);
        if (d > 1e-4) {
            float sigmaT = SIGMA_T * d;
            col += T * ALBEDO * (SIGMA_S * d) * dt;
            T   *= exp(-sigmaT * dt);
            if (T < 0.015) break;
        }
        t += dt;
        if (t > tMax) break;
    }
    return col + T * sky(rd);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0*fragCoord - iResolution.xy) / iResolution.y;

    vec3 ro = vec3(0.0, 0.2, 3.0);
    vec3 rd = normalize(vec3(uv, -1.6));

    // 左半：无抖动（条带明显）；右半：有抖动
    float j = 0.0;
    if (uv.x > 0.0) j = hash21(fragCoord + floor(iTime*2.0));

    vec3 col = integrate(ro, rd, j);

    // 中缝
    col = mix(col, vec3(1.0), smoothstep(0.006, 0.0, abs(uv.x)));

    fragColor = vec4(col, 1.0);
}
