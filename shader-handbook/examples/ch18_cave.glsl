// 第 18 章 · 效果配方 · 洞穴入口（廉价 2.5D 射线步进）
// 岩壁 SDF + 晶体发光 + 深处雾。

float hash21(vec2 p)
{
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

float mapCave(vec3 p)
{
    float wall = abs(length(p.xz) - 1.8 + 0.15 * sin(p.y * 3.0 + p.x)) - 0.55;
    float floor = p.y + 0.9 + 0.12 * sin(p.x * 4.0) * sin(p.z * 3.0);
    return min(wall, floor);
}

float crystal(vec3 p)
{
    vec3 q = p - vec3(0.6, -0.2, 0.3);
    q = abs(q);
    return (q.x + q.y + q.z - 0.18) * 0.55;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float t = iTime;

    vec3 ro = vec3(sin(t * 0.15) * 0.15, 0.05, -2.8);
    vec3 rd = normalize(vec3(uv, 1.35));

    vec3 col = vec3(0.01, 0.015, 0.03);
    float depth = 0.0;

    for (int i = 0; i < 64; i++) {
        vec3 p = ro + rd * depth;
        float d = mapCave(p);
        if (d < 0.002) break;
        depth += d * 0.85;
        if (depth > 12.0) break;
    }

    vec3 p = ro + rd * depth;
    if (depth < 12.0) {
        vec2 e = vec2(0.01, 0.0);
        vec3 n = normalize(vec3(
            mapCave(p + e.xyy) - mapCave(p - e.xyy),
            mapCave(p + e.yxy) - mapCave(p - e.yxy),
            mapCave(p + e.yyx) - mapCave(p - e.yyx)));
        float ao = clamp(0.5 + 0.5 * n.y, 0.0, 1.0);
        col = mix(vec3(0.08, 0.06, 0.05), vec3(0.18, 0.14, 0.12), ao);

        // 晶体
        float cd = crystal(p);
        if (cd < 0.02) {
            vec3 cry = vec3(0.2, 0.85, 1.0);
            float glow = exp(-cd * 80.0);
            col = mix(col, cry, glow);
            col += cry * glow * (0.6 + 0.4 * sin(t * 3.0 + p.x * 8.0));
        }
    }

    // 入口光
    col += vec3(0.4, 0.55, 0.85) * exp(-depth * 0.35) * max(rd.y, 0.0);
    col = mix(vec3(0.01, 0.01, 0.02), col, exp(-depth * 0.08));

    col = pow(max(col, 0.0), vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
