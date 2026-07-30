// 第 10 章 · 阶梯实战 · 阶段 7：丁达尔光柱（解析遮挡 + Beer 积分）
// 空气中均匀雾 + 球/盒遮挡体。沿视线步进积分散射，朝太阳方向估算
// 遮挡透光率 → 光束从缝隙漏出。不用 fbm 云，先把「光穿过介质」看清楚。
#define STEPS 56
#define L_STEPS 20

float hash21(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// 场景雾：近地薄、远处略浓
float fogDensity(vec3 p)
{
    float h = exp(-max(p.y, 0.0) * 0.55);
    float r = 1.0 - smoothstep(3.5, 7.0, length(p.xz));
    return 0.07 * h * r;
}

// 遮挡体：盒 + 球，高密度吸收（软边）
float occluderDensity(vec3 p)
{
    vec3 qb = abs(p - vec3(0.0, 0.55, -0.8)) - vec3(0.55, 0.70, 0.18);
    float boxD = length(max(qb, 0.0)) + min(max(qb.x, max(qb.y, qb.z)), 0.0);
    float box  = smoothstep(0.12, -0.02, boxD);

    float sph = length(p - vec3(0.85, 0.25, 0.35)) - 0.32;
    float sp  = smoothstep(0.10, -0.02, sph);

    return max(box, sp) * 6.0;
}

// 朝太阳方向积分遮挡 → 透光率（Beer）
float sunVisibility(vec3 p, vec3 sun)
{
    float tau = 0.0;
    float t   = 0.05;
    for (int i = 0; i < L_STEPS; i++) {
        float dt = 0.18 + 0.06 * float(i);
        tau += occluderDensity(p + sun * t) * dt;
        t   += dt;
        if (tau > 8.0) break;
    }
    return exp(-tau);
}

vec3 sky(vec3 rd, vec3 sun)
{
    float h = clamp(rd.y * 0.5 + 0.5, 0.0, 1.0);
    vec3  col = mix(vec3(0.18, 0.22, 0.32), vec3(0.52, 0.68, 0.92), pow(h, 0.6));
    col += vec3(1.0, 0.82, 0.55) * pow(max(dot(rd, sun), 0.0), 64.0) * 0.9;
    col += vec3(1.0, 0.70, 0.35) * pow(max(dot(rd, sun), 0.0), 8.0) * 0.25;
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    vec3 sun = normalize(vec3(0.72, 0.28, -0.64));
    float ang = iTime * 0.08;
    vec3  ro  = vec3(sin(ang) * 1.2, 0.35, 3.8);
    vec3  ta  = vec3(0.0, 0.45, -0.5);
    vec3  ww  = normalize(ta - ro);
    vec3  uu  = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3  vv  = cross(uu, ww);
    vec3  rd  = normalize(uv.x * uu + uv.y * vv + 1.65 * ww);

    vec3 bg = sky(rd, sun);
    // 地面
    if (rd.y < -0.001) {
        float tg = -ro.y / rd.y;
        if (tg > 0.0) {
            vec3 gp = ro + rd * tg;
            float chk = mod(floor(gp.x * 0.8) + floor(gp.z * 0.8), 2.0);
            vec3 gnd = mix(vec3(0.12, 0.14, 0.10), vec3(0.20, 0.22, 0.16), chk);
            bg = mix(gnd * 0.35, bg, 0.55);
        }
    }

    float tMin = 0.5, tMax = 9.0;
    float dt   = (tMax - tMin) / float(STEPS);
    float t    = tMin + hash21(fragCoord) * dt;

    float T = 1.0;
    vec3  col = vec3(0.0);
    const float SIGMA_T = 3.2;
    const float SIGMA_S = 2.8;

    for (int i = 0; i < STEPS; i++) {
        vec3  p = ro + rd * t;
        float d = fogDensity(p);
        if (d > 1e-5) {
            float vis  = sunVisibility(p, sun);
            float phase = 0.55 + 0.45 * max(dot(rd, sun), 0.0);
            vec3  lin = vec3(0.35, 0.42, 0.55) * 0.25
                      + vec3(1.00, 0.88, 0.62) * vis * phase * 1.35;
            float od = SIGMA_T * d * dt;
            col += T * lin * (SIGMA_S * d) * dt;
            T   *= exp(-od);
            if (T < 0.012) break;
        }
        t += dt;
    }

    col += T * bg;

    vec2 q = fragCoord / iResolution.xy;
    col *= 0.58 + 0.42 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.32);
    col = pow(col, vec3(0.4545));
    col += (hash21(fragCoord) - 0.5) / 255.0;

    fragColor = vec4(col, 1.0);
}
