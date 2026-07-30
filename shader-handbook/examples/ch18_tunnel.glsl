// 第 18 章 · 效果配方 · 经典隧道
// 心法：极坐标 / 对数映射 + 沿 z 或 r 的纹理采样感；飞行 forward。
// 语料对照：Tunnel / fly-through 类经典

float hash11(float n) { return fract(sin(n) * 43758.5453); }

float vnoise(vec2 p)
{
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash11(dot(i, vec2(127.1, 311.7)));
    float b = hash11(dot(i + vec2(1, 0), vec2(127.1, 311.7)));
    float c = hash11(dot(i + vec2(0, 1), vec2(127.1, 311.7)));
    float d = hash11(dot(i + vec2(1, 1), vec2(127.1, 311.7)));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = (uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);
    float t = iTime * 1.2;

    float angle = atan(p.y, p.x);
    float radius = length(p);

    // 对数极坐标：r 小 = 深处，模拟向前飞
    float depth = 1.0 / max(radius, 0.02) + t;
    float u = angle / 6.2831853 + 0.5;
    vec2 tex = vec2(u * 8.0, depth * 0.35);

    // 程序化「砖纹」
    float band = sin(depth * 0.8) * 0.5 + 0.5;
    float bricks = step(0.5, fract(tex.x)) * step(0.5, fract(tex.y * 0.5 + band * 0.5));
    float pat = vnoise(tex * 2.0) * 0.5 + vnoise(tex * 6.0 + vec2(0.0, t)) * 0.3;

    // 隧道边界：sin 环
    float tunnel = abs(sin(angle * 6.0 + depth * 0.4)) * 0.5 + 0.5;
    tunnel *= smoothstep(0.55, 0.15, radius);

    vec3 cA = vec3(0.15, 0.4, 0.85);
    vec3 cB = vec3(0.85, 0.25, 0.55);
    vec3 cC = vec3(0.95, 0.75, 0.2);
    vec3 col = mix(cA, cB, tunnel);
    col = mix(col, cC, pat * 0.6);
    col *= 0.4 + 0.6 * bricks;
    col *= exp(-radius * 0.8) * (0.3 + 0.7 * band);

    // 中心辉光
    col += vec3(0.9, 0.95, 1.0) * exp(-radius * 6.0) * 0.25;

    vec3 bg = vec3(0.01, 0.015, 0.03);
    col = mix(bg, col, smoothstep(0.0, 0.08, tunnel));

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
