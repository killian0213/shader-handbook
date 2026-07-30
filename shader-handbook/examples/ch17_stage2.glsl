// 第 17 章 · 代码高尔夫 · 阶段 2：Creation 紧凑中间态
// 与 stage1 同视觉家族，约一半篇幅：保留关键变量名，去掉逐行注释。

float creationChannel(vec2 fragCoord, float phase, out float radiusLen)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = uv - 0.5;
    p.x *= iResolution.x / iResolution.y;

    radiusLen = length(p);
    vec2 dir = p / max(radiusLen, 1e-4);

    float push = (sin(phase) + 1.0) * abs(sin(radiusLen * 9.0 - 2.0 * phase));
    uv += dir * push;

    vec2 cell = mod(uv, 1.0) - 0.5;
    return 0.01 / length(cell);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec3 col = vec3(0.0);
    float rLen = 0.0;
    float z = iTime;

    for (int i = 0; i < 3; i++) {
        z += 0.07;
        col[i] = creationChannel(fragCoord, z, rLen);
    }

    col /= max(rLen, 0.15);
    vec2 u = fragCoord / iResolution.xy;
    col *= pow(16.0 * u.x * u.y * (1.0 - u.x) * (1.0 - u.y), 0.12);
    fragColor = vec4(col, 1.0);
}
