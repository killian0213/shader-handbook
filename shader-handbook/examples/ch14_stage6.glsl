// 第 14 章 · 阶梯实战 · 阶段 6：黏菌 / 聚合味
// 域扭曲 fbm + 阈值做出 slime mold / reaction 斑图，缓慢蠕动。
// 真版 = Gray-Scott 或 agent-based 仿真写 Buffer；这里用静态噪声场 + 时间漂移近似。
float hash12(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p)
{
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash12(i), hash12(i + vec2(1, 0)), f.x),
               mix(hash12(i + vec2(0, 1)), hash12(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p)
{
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 6; i++) {
        v += a * vnoise(p);
        p = p * 2.03 + vec2(100.0);
        a *= 0.5;
    }
    return v;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float t = iTime * 0.12;

    // 域扭曲：模拟黏菌伪足伸展
    vec2 q = uv * 1.8;
    vec2 w = vec2(fbm(q + vec2(t, 0.0)),
                  fbm(q + vec2(5.2, 1.3) - t * 0.7));
    float n = fbm(q + 2.5 * w + t * 0.3);

    // 第二尺度：聚合「脉管」
    float n2 = fbm(q * 2.5 - w * 1.5 + vec2(t * 0.5, -t * 0.4));
    float field = mix(n, n2, 0.45);

    // 阈值斑图 + 边缘（类似 reaction-diffusion 相）
    float body = smoothstep(0.42, 0.58, field);
    float edge = smoothstep(0.015, 0.0, abs(field - 0.50));
    float vein = smoothstep(0.68, 0.78, n2) * body;

    vec3 bg   = vec3(0.04, 0.03, 0.06);
    vec3 mold = vec3(0.85, 0.55, 0.95);
    vec3 core = vec3(0.95, 0.88, 0.35);
    vec3 veinC = vec3(0.25, 0.95, 0.65);

    vec3 col = mix(bg, mold, body);
    col = mix(col, core, vein * 0.7);
    col = mix(col, veinC, edge * 0.9);

    // 缓慢「爬行」高光
    float crawl = fbm(q * 4.0 + t * 2.0);
    col += vec3(0.15, 0.08, 0.2) * crawl * body * 0.3;

    col = pow(col, vec3(0.95));
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
