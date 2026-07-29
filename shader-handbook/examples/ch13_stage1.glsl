// 第 13 章 · 阶梯实战 · 阶段 1：假历史拖尾粒子场
// 用 iTime 相位 + hash 模拟最近 N 个历史笔迹点做发光拖尾；真拖尾需 Buffer 读上一帧。
// （Shadertoy 里 Buffer 读自己 = 上一帧，单 Pass 无法持久化像素状态。）
#define TRAIL_N 10

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

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p  = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // 鼠标位置；未按下时用时间驱动的螺旋笔迹
    vec2 m = iMouse.xy / iResolution.xy;
    bool useMouse = (iMouse.z > 0.0);
    if (!useMouse) {
        m = vec2(0.5 + 0.28 * sin(iTime * 0.9),
                 0.5 + 0.22 * cos(iTime * 1.15));
    }

    vec3 col = vec3(0.015, 0.018, 0.045);

    // 假「时间环缓冲」：N 个衰减的历史点
    for (int i = 0; i < TRAIL_N; i++) {
        float fi = float(i);
        float age = fi / float(TRAIL_N - 1);

        vec2 pos;
        if (useMouse) {
            // 残影：沿螺旋偏移模拟笔迹惯性
            float ang = iTime * 2.2 - age * 5.5;
            pos = m + age * 0.22 * vec2(sin(ang * 1.6), cos(ang * 2.1));
        } else {
            float t = iTime - age * 0.35;
            pos = vec2(0.5 + 0.28 * sin(t * 0.9 + hash11(fi) * 6.28),
                       0.5 + 0.22 * cos(t * 1.15 + hash11(fi + 7.0) * 6.28));
        }

        vec2 q = pos * iResolution.xy;
        vec2 d = (fragCoord - q) / iResolution.y;
        float r = length(d);

        float core = exp(-r * r * 900.0);
        float glow = exp(-r * 12.0) * 0.35;
        vec3  c = mix(vec3(0.15, 0.55, 1.0), vec3(1.0, 0.35, 0.65), hash11(fi * 3.7));
        col += c * (core + glow) * (1.0 - age * 0.85);
    }

    // 微弱背景网格，方便看出拖尾在动
    col += vec3(0.03) * (0.5 + 0.5 * sin(p.x * 20.0)) * (0.5 + 0.5 * sin(p.y * 20.0));

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
