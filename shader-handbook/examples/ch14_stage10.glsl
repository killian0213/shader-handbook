// 第 14 章 · 阶梯实战 · 阶段 10：SmoothLife 有机 CA 味道
// 连续场 + 邻域积分：blob 融合/分裂，比离散格点更「生物膜」。
// 真 SmoothLife = 环形邻域 + 连续 birth/survival 核；这里用 FBM 域近似。
float hash11(float n) { return fract(sin(n) * 43758.5453); }

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

float fbm(vec2 p)
{
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * vnoise(p);
        p = p * 2.03 + vec2(17.0, 31.0);
        a *= 0.5;
    }
    return v;
}

// 高斯核邻域平均（SmoothLife 核心思想：连续而非 0/1）
float smoothNeighborhood(vec2 uv, float t)
{
    float sum = 0.0, wsum = 0.0;
    const int R = 3;
    for (int j = -R; j <= R; j++)
        for (int i = -R; i <= R; i++) {
            vec2 o = vec2(float(i), float(j));
            float w = exp(-dot(o, o) * 0.35);
            vec2 q = uv + o * 0.018;
            float n = fbm(q * 4.0 + t * 0.12);
            float blob = smoothstep(0.38, 0.62, n);
            sum += blob * w;
            wsum += w;
        }
    return sum / wsum;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float t = iTime * 0.4;

    float field = fbm(uv * 3.2 + vec2(t * 0.08, -t * 0.06));
    float state = smoothstep(0.35, 0.65, field);

    float neigh = smoothNeighborhood(uv, t);
    // 连续 birth/survival：外环密度驱动分裂，内环过高则收缩
    float birth = smoothstep(0.22, 0.38, neigh) * (1.0 - smoothstep(0.55, 0.72, neigh));
    float surv  = smoothstep(0.18, 0.42, neigh) * smoothstep(0.78, 0.52, neigh);
    float organic = mix(birth, surv, state);
    organic = smoothstep(0.25, 0.75, organic + 0.15 * sin(t * 2.0 + fbm(uv * 8.0) * 6.28));

    float edge = smoothstep(0.04, 0.0, abs(organic - 0.5));
    vec3 inner = mix(vec3(0.08, 0.55, 0.42), vec3(0.95, 0.82, 0.25), fbm(uv * 5.0 + t));
    vec3 outer = vec3(0.02, 0.04, 0.07);
    vec3 col = mix(outer, inner, organic);
    col += vec3(0.6, 0.95, 0.75) * edge * 0.35;

    // 薄膜高光
    col += vec3(0.3, 0.5, 0.4) * pow(organic, 3.0) * 0.2;

    col = pow(col, vec3(0.88));
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
