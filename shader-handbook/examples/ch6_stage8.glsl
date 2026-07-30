// 第 6 章 · 网格扩展 · 阶段 8：动画 Truchet 迷宫
// 每格用 hash(id) 选弧/直线瓦片，相邻格共享边时线条自然衔接；
// iTime 驱动相位偏移，让「能量」沿迷宫流动。难度：中级。
const float TAU = 6.2831853;

float hash21(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 单位格：返回到最近 Truchet 线条的有符号距离
float truchetTile(vec2 p, float tileId, float phase)
{
    // tile 0/1：对角弧；tile 2/3：水平/竖直半弧组合
    float flip = step(0.5, tileId);
    p = abs(p - 0.5) - 0.5;
    if (flip > 0.5) p = p.yx;

    float t = fract(tileId * 3.7 + phase);
    float d;
    if (t < 0.5) {
        // 四分之一圆弧：圆心 (±0.5, ±0.5)
        vec2 c = vec2(-0.5, -0.5);
        d = abs(length(p - c) - 0.5) - 0.06;
    } else {
        vec2 c = vec2(0.5, -0.5);
        d = abs(length(p - c) - 0.5) - 0.06;
    }
    return d;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p  = (uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);
    p *= 6.0;

    vec2 id = floor(p);
    vec2 f  = fract(p);

    // 相位随时间流动 —— 视觉上像电流在迷宫中跑
    float phase = iTime * 0.35 + dot(id, vec2(0.31, 0.17));

    float tile = floor(hash21(id) * 4.0);
    float d = truchetTile(f, tile, phase * 0.15);

    // 流动高光：沿线条方向的 traveling pulse
    float flow = 0.5 + 0.5 * sin(phase * 4.0 - length(f - 0.5) * 8.0);
    float line = smoothstep(0.018, 0.0, d);
    float glow = exp(-abs(d) * 38.0) * (0.35 + 0.65 * flow);

    vec3 bg  = vec3(0.04, 0.035, 0.07);
    vec3 ink = mix(vec3(0.15, 0.55, 0.95), vec3(0.95, 0.45, 0.85), hash21(id + 7.0));
    vec3 col = mix(bg, ink, line * 0.85);
    col += ink * glow * 0.75;

    // 格心微暗，突出线条网络
    col *= 0.88 + 0.12 * smoothstep(0.45, 0.0, length(f - 0.5));

    col = pow(col, vec3(0.95));
    fragColor = vec4(col, 1.0);
}
