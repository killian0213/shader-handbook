// 第 13 章 · 阶梯实战 · 阶段 3：「寄存器状态」可视化
// 用 floor(iTime) 驱动的小球位置哈希跳动，模拟每帧读写 Buffer 状态；真状态在 Buffer 里。
float hash11(float p)
{
    p = fract(p * 0.1031);
    p *= p + 33.33;
    return fract(p);
}

float hash21(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// 模拟 Buffer A 里存的 8 个「寄存器」位置
vec2 regPos(int id, float frame)
{
    float h0 = hash11(float(id) * 17.3 + frame * 0.91);
    float h1 = hash11(float(id) * 31.7 + frame * 1.37);
    return vec2(-0.75 + h0 * 1.5, -0.55 + h1 * 1.1);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float frame = floor(iTime * 2.0);
    float blend = fract(iTime * 2.0);

    vec3 col = vec3(0.04, 0.05, 0.08);

    // 网格：暗示「像素格 = 存储单元」
    vec2 g = fract(uv * 8.0);
    col += vec3(0.02) * step(0.92, max(g.x, g.y));

    const int REGS = 8;
    for (int i = 0; i < REGS; i++) {
        vec2 p0 = regPos(i, frame);
        vec2 p1 = regPos(i, frame + 1.0);
        vec2 pos = mix(p0, p1, smoothstep(0.0, 1.0, blend));

        float d = length(uv - pos);
        vec3  c = 0.5 + 0.5 * cos(vec3(0.0, 2.1, 4.2) + float(i) * 1.7);
        col += c * exp(-d * d * 200.0);
        col += c * 0.12 * exp(-d * 10.0);
    }

    // 标注当前「帧号」
    float bar = smoothstep(0.02, 0.0, abs(uv.y + 0.82));
    col += vec3(0.25, 0.55, 0.85) * bar * (0.3 + 0.7 * hash21(vec2(frame, 0.0)));

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
