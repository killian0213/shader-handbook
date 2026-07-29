// 第 13 章 · 阶梯实战 · 阶段 7：色散拖影 / 棱镜残像
// 同一发光体 RGB 三通道不同偏移 + 衰减，像棱镜相机长曝光。
// 真版 = 分别对 R/G/B 做 Buffer 拖尾或后处理 pass 再合成。
#define GHOST_N 8

float hash11(float p)
{
    p = fract(p * 0.1031);
    p *= p + 33.33;
    return fract(p);
}

// 单个发光体（返回亮度，不含色）
float glowBody(vec2 uv, vec2 cen, float size)
{
    vec2 d = uv - cen;
    float r = length(d);
    float core = exp(-r * r / (size * size));
    float halo = exp(-r * 6.0) * 0.35;
    return core + halo;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // 运动轨迹：李萨如曲线
    float t = iTime * 0.9;
    vec2 cen = vec2(0.38 * sin(t * 1.2), 0.30 * cos(t * 1.5 + 0.5));
    vec2 vel = vec2(cos(t * 1.2), -sin(t * 1.5 + 0.5)) * 0.38;
    vel = normalize(vel + 1e-4);

    vec3 col = vec3(0.008, 0.01, 0.022);

    // 暗背景微网格
    col += vec3(0.015) * (0.5 + 0.5 * sin(uv.x * 30.0)) * (0.5 + 0.5 * sin(uv.y * 30.0));

    // 色散方向：垂直于运动方向（棱镜感）
    vec2 dispDir = vec2(-vel.y, vel.x);

    // 8 帧残像，每帧 RGB 通道偏移量不同
    for (int i = 0; i < GHOST_N; i++) {
        float fi = float(i);
        float age = fi / float(GHOST_N - 1);
        float fade = pow(1.0 - age, 1.8);

        float gt = t - age * 0.45;
        vec2 gCen = vec2(0.38 * sin(gt * 1.2), 0.30 * cos(gt * 1.5 + 0.5));

        // 色散量：R 偏红方向、B 偏蓝方向，G 居中
        float disp = 0.025 + age * 0.06;
        float br = glowBody(uv, gCen + dispDir * disp *  1.2, 0.012);
        float bg = glowBody(uv, gCen,                         0.012);
        float bb = glowBody(uv, gCen - dispDir * disp *  1.2, 0.012);

        col.r += br * fade * 1.1;
        col.g += bg * fade * 0.95;
        col.b += bb * fade * 1.15;
    }

    // 当前帧主体 + 强色散边
    float disp0 = 0.018;
    col.r += glowBody(uv, cen + dispDir * disp0 * 1.5, 0.014) * 1.8;
    col.g += glowBody(uv, cen,                         0.014) * 1.6;
    col.b += glowBody(uv, cen - dispDir * disp0 * 1.5, 0.014) * 1.9;

    // 光谱色带点缀
    col += vec3(1.0, 0.6, 0.2) * exp(-abs(dot(uv - cen, dispDir)) * 80.0) * 0.15;

    col = col / (col + 0.4);
    col = pow(col, vec3(0.4545));
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
