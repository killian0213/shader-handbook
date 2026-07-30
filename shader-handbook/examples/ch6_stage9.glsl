// 第 6 章 · 网格扩展 · 阶段 9：多尺度四叉树 / 城市灯光（HARD）
// 嵌套正方形细分：hash 决定是否继续 split，叶子格点亮霓虹边 —— 像俯瞰城市。
//
// 递归-as-循环结构（GLSL 无真递归，用 for 模拟）：
//   for depth in 0..MAX:
//     当前格 id = floor(uv * 2^depth)
//     若 hash(id, depth) > 阈值 → 在此层停止，画边框/灯光
//     否则 uv = fract(uv * 2) 进入下一层子格
const int MAX_DEPTH = 7;

float hash21(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash13(vec2 p, float d)
{
    return fract(sin(dot(p + d * 17.0, vec2(269.5, 183.3))) * 43758.5453);
}

// 一层四叉树：返回该层边框强度 + 是否叶子
vec2 quadLayer(vec2 f, vec2 id, float depth, float splitThresh)
{
    float h = hash13(id, depth);
    float isLeaf = step(splitThresh, h);  // h 大 → 不再细分
    float edge = abs(min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)) - 0.02);
    edge = smoothstep(0.015, 0.0, edge);
    return vec2(edge, isLeaf);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p  = (uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);
    p = p * 1.15 + 0.5;

    vec3 col = vec3(0.015, 0.012, 0.035);
    float glowAccum = 0.0;
    vec3  glowCol   = vec3(0.0);

    vec2 f = p;
    // --- 伪递归：每层把 UV 放大 2 倍，相当于进入子节点 ---
    for (int depth = 0; depth < MAX_DEPTH; depth++) {
        float d = float(depth);
        vec2 id = floor(f);
        vec2 ff = fract(f);

        float thresh = 0.52 + 0.06 * sin(iTime * 0.2 + d * 0.4);
        vec2 layer = quadLayer(ff, id, d, thresh);
        float edge = layer.x;
        float leaf = layer.y;

        if (leaf > 0.5) {
            float h = hash13(id, d);
            vec3 neon = mix(vec3(0.1, 0.85, 1.0), vec3(1.0, 0.35, 0.75), h);
            neon = mix(neon, vec3(1.0, 0.92, 0.45), step(0.85, h));
            float pulse = 0.4 + 0.6 * sin(iTime * (1.5 + h * 3.0) + h * 6.28);
            float w = pow(0.55, d);  // 深层更暗更小
            glowAccum += edge * w;
            glowCol += neon * edge * w * pulse;

            // 叶子内部：微弱填充像窗户
            float fill = (1.0 - edge) * smoothstep(0.3, 0.0, length(ff - 0.5));
            col += neon * fill * 0.04 * pulse * w;
        }

        f = ff * 2.0;  // 进入下一层（等价于递归 quadtree 的 descend）
    }

    col += glowCol * 1.2;
    col += vec3(0.05, 0.08, 0.15) * glowAccum * 0.3;

    // 星空底
    float star = step(0.998, hash21(uv * iResolution.xy + 0.1));
    col += vec3(0.7, 0.8, 1.0) * star * 0.5;

    col = col / (col + vec3(0.8));
    col = pow(col, vec3(0.92));
    fragColor = vec4(col, 1.0);
}
