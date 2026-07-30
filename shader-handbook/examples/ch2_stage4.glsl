// 第 2 章 · 坐标阶梯 · 阶段 4：缩放 = 除坐标
// 想放大形状 → p /= s；非均匀缩放 sx≠sy → 圆变椭圆。
// 左半：圆（均匀 scale）；右半：椭圆（非均匀 squash/stretch 动画）。

const float TAU = 6.2831853;

float sdCircle(vec2 p, float r) { return length(p) - r; }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float aa = 2.0 / iResolution.y;
    bool left = p.x < 0.0;

    vec3 bgL = vec3(0.04, 0.05, 0.10);
    vec3 bgR = vec3(0.05, 0.04, 0.09);
    vec3 col = mix(bgR, bgL, float(left));

    // 动画 squash：sx, sy 交替
    float t = iTime * 1.1;
    vec2 squash = vec2(1.0 + 0.45 * sin(t), 1.0 + 0.45 * cos(t * 1.3));

    vec2 q;
    float d;
    vec3 tint;

    if (left) {
        // 均匀缩放：p / s → 等效于形状放大 s 倍
        float s = 1.0 + 0.35 * sin(iTime * 0.8);
        q = p / s;
        d = sdCircle(q - vec2(-0.35, 0.0), 0.28);
        tint = vec3(0.35, 0.88, 1.00);
    } else {
        // 非均匀：p / squash → 圆在屏幕上变椭圆
        q = p / squash;
        d = sdCircle(q - vec2(0.35, 0.0), 0.28);
        tint = vec3(1.00, 0.55, 0.32);
    }

    float body = smoothstep(aa, -aa, d);
    float edge = exp(-abs(d) * 55.0);
    col = mix(col, tint * 0.22, body);
    col += tint * edge * 1.25;
    col += tint * exp(-max(d, 0.0) * 6.0) * 0.25;

    // 参考圆：未缩放空间里的虚线轮廓（右屏显示椭圆包络）
    vec2 ref = left ? p : p * squash;
    float refD = abs(sdCircle(ref - vec2(0.35, 0.0), 0.28)) - 0.004;
    col += vec3(0.45, 0.50, 0.65) * smoothstep(0.012, 0.0, refD) * 0.35;

    // 中线分割
    col += vec3(0.55) * exp(-abs(p.x) * 80.0) * 0.12;

    fragColor = vec4(col, 1.0);
}
