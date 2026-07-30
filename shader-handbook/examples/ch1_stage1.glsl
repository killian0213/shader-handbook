// 第 1 章 · 平台入门 · Uniform 仪表盘
// 可视化 iTime / iResolution / iMouse / iFrame —— Shadertoy 四大输入。

float hash21(vec2 p)
{
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec3 bg = mix(vec3(0.07, 0.09, 0.16), vec3(0.12, 0.14, 0.22), uv.y);
    vec3 col = bg;

    // iTime：底部滚动进度条
    float bar = smoothstep(0.08, 0.0, abs(uv.y - 0.08));
    float prog = fract(iTime * 0.15);
    col = mix(col, vec3(0.25), bar);
    col = mix(col, vec3(0.35, 0.85, 1.0), bar * step(abs(uv.x - prog), 0.012));

    // iResolution：宽高比 —— 两圆，横圆 vs 正圆
    float ar = iResolution.x / iResolution.y;
    float c1 = length(p - vec2(-0.55, 0.15)) - 0.22;
    float c2 = length((p - vec2(0.55, 0.15)) * vec2(1.0 / ar, 1.0)) - 0.22;
    col = mix(col, vec3(0.95, 0.45, 0.55), smoothstep(0.008, 0.0, abs(c1)));
    col = mix(col, vec3(0.45, 0.85, 0.95), smoothstep(0.008, 0.0, abs(c2)));

    // iMouse：十字准星光晕（未点击时在中心）
    vec2 mp = (iMouse.xy - 0.5 * iResolution.xy) / iResolution.y;
    if (iMouse.z <= 0.0) mp = vec2(0.0);
    vec2 d = abs(p - mp);
    float cross = exp(-min(d.x, d.y) * 40.0) * 0.9;
    col += vec3(1.0, 0.85, 0.35) * cross;
    col += vec3(1.0, 0.6, 0.2) * exp(-length(p - mp) * 8.0) * 0.35;

    // iFrame：右上角闪烁角标
    float flash = 0.5 + 0.5 * sin(float(iFrame) * 0.08);
    vec2 corner = uv - vec2(0.92, 0.88);
    float badge = smoothstep(0.07, 0.0, length(corner));
    col = mix(col, vec3(0.95, 0.35, 0.55) * flash, badge);

    // 细网格装饰
    vec2 g = fract(fragCoord / 24.0);
    float grid = (1.0 - smoothstep(0.0, 0.04, min(g.x, g.y))) * 0.04;
    col += vec3(grid);

    fragColor = vec4(col, 1.0);
}
