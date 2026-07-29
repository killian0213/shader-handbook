// 第 13 章 · 阶梯实战 · 阶段 5：时间回声 / 残影切片
// 用 iTime 相位在圆环上放 12 个「过去的鼠标/笔尖」衰减克隆，像延迟摄影。
// 真版 = Buffer 环形历史纹理：每帧把当前笔迹写入 head 槽，Image 读 N 个历史槽叠加。
#define ECHO_N 12

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

// 当前「笔尖」位置（归一化 0~1）
vec2 penPos()
{
    if (iMouse.z > 0.0)
        return iMouse.xy / iResolution.xy;
    float t = iTime * 0.85;
    return vec2(0.5 + 0.32 * sin(t * 1.1),
                0.5 + 0.26 * cos(t * 1.35 + 0.7));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec2 pen = penPos();
    vec2 penN = (pen * iResolution.xy * 2.0 - iResolution.xy) / iResolution.y;

    vec3 col = vec3(0.012, 0.015, 0.035);

    // 参考圆环：残影沿环排列
    float ringR = 0.38;
    float ringW = abs(length(uv) - ringR);
    col += vec3(0.06, 0.12, 0.22) * exp(-ringW * 55.0);

    // 12 个历史切片：相位 age 映射到圆环角度
    for (int i = 0; i < ECHO_N; i++) {
        float fi = float(i);
        float age = fi / float(ECHO_N - 1);

        // 假环形缓冲：第 i 槽 = iTime 往前 age * 周期 的笔迹
        float sliceT = iTime - age * 0.55;
        vec2 hist;
        if (iMouse.z > 0.0) {
            // 鼠标模式：历史点沿环 + 径向衰减
            float ang = sliceT * 2.4 + age * 6.28318;
            hist = penN + vec2(cos(ang), sin(ang)) * age * 0.18;
        } else {
            hist = vec2(0.32 * sin(sliceT * 1.1),
                        0.26 * cos(sliceT * 1.35 + 0.7));
        }

        vec2 d = uv - hist;
        float r = length(d);

        // 切片「窗口」：环上对应角度的一小段高亮
        float echoAng = atan(d.y, d.x);
        float slotAng = fract(sliceT * 0.35) * 6.28318;
        float angDiff = abs(sin(echoAng - slotAng));
        float slice = smoothstep(0.35, 0.05, angDiff);

        float core = exp(-r * r * 800.0);
        float glow = exp(-r * 14.0) * 0.4;
        float fade = pow(1.0 - age, 2.2);

        vec3 c = mix(vec3(0.2, 0.65, 1.0), vec3(1.0, 0.45, 0.75), hash11(fi * 2.9));
        col += c * (core + glow) * fade * (0.55 + 0.45 * slice);
    }

    // 当前笔尖（最亮）
    {
        vec2 d = uv - penN;
        float r = length(d);
        col += vec3(1.0, 0.95, 0.85) * exp(-r * r * 600.0) * 2.0;
        col += vec3(0.4, 0.7, 1.0) * exp(-r * 10.0) * 0.5;
    }

    col += (hash21(fragCoord + iTime) - 0.5) / 255.0;
    col = pow(col, vec3(0.4545));
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
