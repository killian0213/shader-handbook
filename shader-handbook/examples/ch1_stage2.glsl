// 第 1 章 · 像素独立 —— 每像素只读自身 uv，无邻域记忆
// 对比：Buffer 通道才能保存上一帧历史；本例纯 hash(id) 着色。

float hash21(vec2 p)
{
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

vec3 agentColor(vec2 id)
{
    float h = hash21(id);
    return 0.55 + 0.45 * cos(vec3(0.0, 2.1, 4.2) + h * 6.283);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // 网格：每格一个"独立智能体"，颜色仅由 id 决定
    float cell = 14.0;
    vec2 id = floor(fragCoord / cell);
    vec2 f = fract(fragCoord / cell) - 0.5;

    vec3 col = vec3(0.06, 0.07, 0.10);
    float r = length(f * cell / iResolution.y);
    float body = smoothstep(0.38, 0.32, r);
    vec3 ac = agentColor(id);
    col = mix(col, ac * 0.35, body);
    col = mix(col, ac, smoothstep(0.36, 0.30, r));

    // 瞳孔：仍只依赖本格 id 的 hash，不读邻居
    vec2 eye = f * cell / iResolution.y;
    float pupil = smoothstep(0.06, 0.03, length(eye - vec2(0.06, 0.04)));
    col = mix(col, vec3(0.02), pupil);

    // 分隔线
    vec2 g = fract(fragCoord / cell);
    float edge = min(min(g.x, 1.0 - g.x), min(g.y, 1.0 - g.y));
    col = mix(vec3(0.18, 0.20, 0.28), col, smoothstep(0.0, 0.06, edge));

    // 注释条：顶部说明无 Buffer = 无历史
    if (uv.y > 0.92) col = mix(vec3(0.95, 0.75, 0.35), col, step(abs(uv.x - 0.5), 0.35));

    fragColor = vec4(col, 1.0);
}
