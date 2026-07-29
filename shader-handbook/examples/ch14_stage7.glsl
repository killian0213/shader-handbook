// 第 14 章 · 阶梯实战 · 阶段 7：鸟群 / 粒子流
// 80+ 粒子沿噪声 curl 似流向场运动（位置 = 积分噪声方向的近似），拖尾用短线段。
// 真版 = Buffer 存每粒子 pos/vel，每帧 Euler 积分 + 邻居对齐；这里解析近似轨迹。
const int N = 88;

float hash11(float n) { return fract(sin(n) * 43758.5453); }
vec2  hash12(float n) { return fract(sin(vec2(n, n + 17.1)) * vec2(43758.5453, 22578.145)); }

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

// 流向场：噪声梯度旋转 90° ≈ curl 方向
vec2 flowField(vec2 p, float t)
{
    float e = 0.02;
    float n0 = vnoise(p * 2.5 + t * 0.15);
    float nx = vnoise((p + vec2(e, 0.0)) * 2.5 + t * 0.15) - n0;
    float ny = vnoise((p + vec2(0.0, e)) * 2.5 + t * 0.15) - n0;
    vec2 grad = vec2(nx, ny) / e;
    return normalize(vec2(-grad.y, grad.x) + 1e-4);
}

// 解析积分：沿流向场走若干小步
vec2 particlePos(float id, float t)
{
    vec2 seed = hash12(id);
    vec2 p = (seed - 0.5) * 1.6;
    p += 0.3 * vec2(sin(t * 0.3 + seed.x * 6.28), cos(t * 0.25 + seed.y * 6.28));

    const int STEPS = 6;
    float dt = 0.08;
    for (int s = 0; s < STEPS; s++) {
        vec2 v = flowField(p, t - float(s) * dt);
        p += v * dt * (0.6 + 0.4 * seed.x);
    }
    return p;
}

// 点到线段距离
float segDist(vec2 p, vec2 a, vec2 b)
{
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec3 col = vec3(0.015, 0.02, 0.04);

    //  faint flow field visualization
    vec2 fv = flowField(uv, iTime);
    col += vec3(0.02, 0.03, 0.05) * (0.5 + 0.5 * fv.x);

    for (int i = 0; i < N; i++) {
        float id = float(i);
        vec2 seed = hash12(id);

        vec2 pos = particlePos(id, iTime);
        vec2 prev = particlePos(id, iTime - 0.06);

        // 拖尾线段
        float sd = segDist(uv, prev, pos);
        float trail = exp(-sd * sd * 1200.0) * 0.5;

        // 粒子头
        float d = length(uv - pos);
        float head = exp(-d * d * 800.0);

        vec3 pc = 0.55 + 0.45 * cos(6.28318 * (seed.x + vec3(0.0, 0.33, 0.67)) + iTime * 0.2);
        col += pc * (head * 1.2 + trail);
    }

    col = col / (col + 0.35);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
