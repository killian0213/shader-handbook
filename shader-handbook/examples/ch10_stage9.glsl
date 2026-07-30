// 第 10 章 · 阶梯实战 · 阶段 9：极光飘带
// 多层正弦波状密度片悬浮在天空，绿/紫自发光，相机微仰。
// 比火焰难：密度是「曲面壳层」而非竖柱，层间相位错开制造飘动感。
#define STEPS 72

float hash21(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// 单层飘带：在高度 y0 附近，xz 平面上的波状壳
float ribbonLayer(vec3 p, float y0, float freq, float speed, float thick)
{
    float wave = sin(p.x * freq + iTime * speed)
               * cos(p.z * (freq * 0.7) - iTime * speed * 0.6);
    float sheet = abs(p.y - y0 - wave * 0.22);
    float mask  = exp(-dot(p.xz, p.xz) * 0.08);
    return smoothstep(thick, 0.0, sheet) * mask;
}

float auroraDensity(vec3 p)
{
    float d = 0.0;
    d += ribbonLayer(p, 1.45, 1.8, 0.35, 0.07);
    d += ribbonLayer(p, 1.85, 2.4, 0.28, 0.06) * 0.85;
    d += ribbonLayer(p, 2.25, 3.1, 0.42, 0.05) * 0.70;
    d += ribbonLayer(p, 1.65, 1.2, 0.22, 0.08) * 0.55;
    return clamp(d, 0.0, 1.0);
}

vec3 auroraEmit(vec3 p, float d)
{
    float g = smoothstep(1.3, 2.5, p.y);
    float pur = smoothstep(1.5, 2.3, p.y) * (0.5 + 0.5 * sin(p.x * 2.0 + iTime * 0.5));
    vec3 green  = vec3(0.15, 0.95, 0.55);
    vec3 purple = vec3(0.55, 0.18, 0.95);
    vec3 teal   = vec3(0.10, 0.65, 0.85);
    vec3 c = mix(green, teal, g * 0.4);
    c = mix(c, purple, pur * 0.65);
    return c * d * (0.8 + 0.2 * sin(p.z * 3.0 + iTime * 0.8));
}

vec3 nightSky(vec3 rd)
{
    float h = clamp(rd.y, 0.0, 1.0);
    vec3  col = mix(vec3(0.01, 0.02, 0.05), vec3(0.04, 0.06, 0.14), pow(h, 0.5));
    // 稀疏星点
    float stars = step(0.997, hash21(rd.xz * 120.0 + rd.y * 80.0));
    col += vec3(0.9, 0.95, 1.0) * stars * h;
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float ang = 0.15 * sin(iTime * 0.07);
    vec3  ro  = vec3(sin(ang) * 0.3, -0.15, sin(ang * 0.7) * 0.2);
    vec3  ta  = vec3(0.0, 2.0, 0.0);
    vec3  ww  = normalize(ta - ro);
    vec3  uu  = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3  vv  = cross(uu, ww);
    vec3  rd  = normalize(uv.x * uu + uv.y * vv + 1.15 * ww);

    vec3 bg = nightSky(rd);

    float tMin = 0.5, tMax = 8.0;
    float dt   = (tMax - tMin) / float(STEPS);
    float t    = tMin + hash21(fragCoord) * dt;

    float T = 1.0;
    vec3  col = vec3(0.0);
    const float SIGMA_T = 2.8;

    for (int i = 0; i < STEPS; i++) {
        vec3  p = ro + rd * t;
        float d = auroraDensity(p);
        if (d > 1e-4) {
            col += T * auroraEmit(p, d) * dt;
            T   *= exp(-SIGMA_T * d * dt);
            if (T < 0.015) break;
        }
        t += dt;
    }

    col += T * bg;

    // 地平线微光
    col += vec3(0.08, 0.12, 0.18) * pow(max(rd.y + 0.05, 0.0), 2.0) * 0.35;

    vec2 q = fragCoord / iResolution.xy;
    col *= 0.58 + 0.42 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.28);
    col = pow(col, vec3(0.4545));
    col += (hash21(fragCoord) - 0.5) / 255.0;

    fragColor = vec4(col, 1.0);
}
