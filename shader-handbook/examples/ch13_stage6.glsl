// 第 13 章 · 阶梯实战 · 阶段 6：反馈万花筒味
// 极坐标折叠 + 每帧旋转的程序化纹理叠加衰减感（多层相位 sin 模拟 feedback zoom）。
// 真版 = BufA 读自己再 zoom/rotate/mix：col = mix(texel(BufA, uv), newScene, 0.02)。
#define FOLDS 6
#define LAYERS 5

float hash21(vec2 p)
{
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

// 极坐标折叠：N 瓣对称
vec2 kaleido(vec2 p, int n)
{
    float a = atan(p.y, p.x);
    float r = length(p);
    float seg = 6.28318 / float(n);
    a = abs(mod(a + seg * 0.5, seg) - seg * 0.5);
    return vec2(cos(a), sin(a)) * r;
}

// 单层程序化纹理（旋转 + 缩放）
float layerPattern(vec2 uv, float scale, float rot, float phase)
{
    float c = cos(rot), s = sin(rot);
    vec2 q = mat2(c, -s, s, c) * uv * scale;
    float v = sin(q.x * 8.0 + phase) * sin(q.y * 7.0 - phase * 1.3);
    v += 0.5 * sin((q.x + q.y) * 12.0 + phase * 2.0);
    float rings = sin(length(q) * 18.0 - phase * 3.0);
    return 0.35 * v + 0.65 * rings;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec2 p  = kaleido(uv, FOLDS);

    vec3 col = vec3(0.01, 0.012, 0.025);
    float acc = 0.0;

    // 假 feedback：多层 = 不同「虚拟帧龄」的 zoom/rotate 叠加
    for (int i = 0; i < LAYERS; i++) {
        float fi = float(i);
        float age = fi / float(LAYERS - 1);

        // 模拟每帧 zoom 0.98 + rotate 0.02 rad
        float zoom = pow(0.965, fi * 4.0);
        float rot  = iTime * 0.25 + fi * 0.18;
        float ph   = iTime * (1.2 - age * 0.4) + fi * 1.7;

        vec2 q = p * zoom;
        float pat = layerPattern(q, 1.0 + fi * 0.3, rot, ph);

        // 衰减 = 真 feedback 里 mix 系数累积的效果
        float decay = pow(0.72, fi);
        acc += pat * decay;

        vec3 lc = 0.5 + 0.5 * cos(vec3(0.0, 2.2, 4.4) + fi * 1.1 + iTime * 0.3);
        col += lc * smoothstep(-0.2, 0.65, pat) * decay * 0.35;
    }

    // 中心亮核 + 边缘暗角
    float vig = 1.0 - 0.45 * dot(uv, uv);
    vec3 fbCol = vec3(0.15, 0.35, 0.75) * (0.5 + 0.5 * acc);
    fbCol += vec3(1.0, 0.55, 0.25) * pow(max(acc, 0.0), 3.0) * 0.6;
    fbCol += vec3(0.9, 0.85, 1.0) * exp(-dot(p, p) * 8.0) * 0.4;

    col = mix(col, fbCol, 0.85) * vig;
    col = col / (col + 0.55);
    col = pow(col, vec3(0.4545));
    col += (hash21(fragCoord) - 0.5) / 255.0;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
