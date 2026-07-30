// 第 16 章 · 交互模拟 · 阶段 2：鼠标绘画 / 涟漪
// iMouse 拖尾：当前鼠标发光 + 若未按下则用 iTime 驱动的自动轨迹；
// 多个「历史涟漪」叠加，模拟点击水面。
//
// iMouse.xy = 像素坐标；iMouse.z > 0 表示左键按下。
const int RIPPLES = 6;
const float TAU = 6.2831853;

float hash21(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 mouseNDC()
{
    if (iMouse.z > 0.0)
        return (2.0 * iMouse.xy - iResolution.xy) / iResolution.y;
    // 无鼠标：自动 Lissajous 轨迹
    float t = iTime * 0.55;
    return vec2(0.55 * sin(t * 1.1), 0.38 * cos(t * 0.85 + 1.2));
}

// 第 k 个历史涟漪中心（用时间量化模拟「过去点击」）
vec2 rippleCenter(int k, float t)
{
    float seed = float(k) * 17.3;
    float period = 2.8 + float(k) * 0.4;
    float phase = floor(t / period) * period + hash21(vec2(seed, 0.0)) * period;
    return vec2(
        0.65 * sin(phase * 0.7 + seed),
        0.55 * cos(phase * 0.55 + seed * 1.3)
    );
}

float rippleRing(vec2 p, vec2 cen, float t, float birth)
{
    float age = t - birth;
    if (age < 0.0 || age > 3.5) return 0.0;
    float r = age * 0.35;
    float w = 0.025 + age * 0.008;
    float d = abs(length(p - cen) - r);
    return exp(-d / w) * exp(-age * 0.55) * smoothstep(0.0, 0.15, age);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float t = iTime;

    vec3 bg = vec3(0.02, 0.04, 0.08);
    vec3 col = bg;

    // 水纹底色
    col += vec3(0.03, 0.06, 0.12) * (0.5 + 0.5 * sin(p.x * 12.0 + p.y * 8.0 + t * 0.3));

    // 历史涟漪叠加
    float rip = 0.0;
    for (int k = 0; k < RIPPLES; k++) {
        float fk = float(k);
        float period = 2.8 + fk * 0.4;
        float birth  = floor(t / period) * period + hash21(vec2(fk * 17.3, 0.0)) * period * 0.5;
        rip += rippleRing(p, rippleCenter(k, t), t, birth);
    }
    col += vec3(0.2, 0.75, 1.0) * rip * 0.45;

    // 鼠标/轨迹光晕
    vec2 m = mouseNDC();
    float glow = exp(-length(p - m) * 5.5);
    col += vec3(0.95, 0.55, 0.25) * glow * 0.55;

    // 拖尾：沿过去几个时间点采样鼠标位置（近似历史）
    for (int i = 1; i <= 5; i++) {
        float dt = float(i) * 0.06;
        vec2 past;
        if (iMouse.z > 0.0) {
            past = m; // 按下时拖尾集中在当前路径
        } else {
            float pt = t - dt;
            past = vec2(0.55 * sin(pt * 0.55 * 1.1), 0.38 * cos(pt * 0.55 * 0.85 + 1.2));
        }
        float trail = exp(-length(p - past) * (8.0 + float(i))) * exp(-float(i) * 0.35);
        col += vec3(0.4, 0.85, 1.0) * trail * 0.22;
    }

    // 鼠标涟漪（按下时从鼠标发出）
    if (iMouse.z > 0.0) {
        float clickRip = rippleRing(p, m, t, floor(t * 4.0) / 4.0);
        col += vec3(1.0, 0.9, 0.6) * clickRip * 0.5;
    }

    col = col / (col + vec3(0.35));
    fragColor = vec4(col, 1.0);
}
