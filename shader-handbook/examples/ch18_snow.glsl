// 第 18 章 · 效果配方 · 飘雪
// 心法：多层 hash 粒子 + 景深模糊；背景渐变 + 简单树剪影。
// 语料对照：Snow / winter particle 类

float hash11(float n) { return fract(sin(n) * 43758.5453); }
float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float treeSilhouette(vec2 uv)
{
    float ground = smoothstep(0.38, 0.36, uv.y);
    float tr = 0.0;
    for (int i = 0; i < 6; i++) {
        float fi = float(i);
        float x = 0.12 + fi * 0.16;
        float h = 0.15 + hash11(fi * 7.0) * 0.12;
        float w = 0.04 + hash11(fi * 3.0) * 0.02;
        vec2 q = uv - vec2(x, 0.36);
        float cone = length(vec2(q.x / w, (q.y + h) / h)) - 1.0;
        tr = max(tr, smoothstep(0.02, 0.0, -cone) * ground);
        // 树干
        tr = max(tr, smoothstep(0.008, 0.0, abs(q.x) - 0.008) * step(q.y, 0.0) * step(-0.06, q.y) * ground);
    }
    return tr;
}

float snowLayer(vec2 uv, float scale, float speed, float t)
{
    vec2 p = uv * scale;
    p.y += t * speed;
    vec2 id = floor(p);
    vec2 f = fract(p) - 0.5;
    float h = hash21(id);
    if (h > 0.65) return 0.0;
    vec2 off = vec2(hash11(h * 10.0), hash11(h * 20.0)) - 0.5;
    float d = length(f - off * 0.6);
    float size = 0.02 + h * 0.04;
    return smoothstep(size, 0.0, d) * (0.4 + 0.6 * h);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = (uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);
    float t = iTime;

    // 冬日黄昏渐变
    vec3 col = mix(vec3(0.45, 0.55, 0.72), vec3(0.12, 0.15, 0.25), uv.y);
    col = mix(col, vec3(0.08, 0.1, 0.18), smoothstep(0.0, 0.45, uv.y));

    float trees = treeSilhouette(uv);
    col = mix(col, vec3(0.04, 0.05, 0.08), trees);

    // 多层雪花：远小近大
    float s = 0.0;
    s += snowLayer(p + vec2(0.3, 0.0), 8.0, 0.08, t);
    s += snowLayer(p, 14.0, 0.12, t + 2.0);
    s += snowLayer(p - vec2(0.2, 0.0), 22.0, 0.18, t + 4.0);
    s += snowLayer(p, 35.0, 0.25, t + 1.0) * 0.7;

    col += vec3(0.95, 0.97, 1.0) * s;
    col += vec3(1.0) * s * s * 0.3;

    // 地面积雪微亮
    col += vec3(0.7, 0.75, 0.85) * smoothstep(0.38, 0.35, uv.y) * 0.08;

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
