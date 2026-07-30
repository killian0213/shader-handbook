// 第 2 章 · 坐标阶梯 · 阶段 5：极坐标折叠万花筒
// abs(atan) 镜像 + mod 分扇区 → N 瓣对称。
// 在折叠后的坐标里画纹理，图案自动重复 —— 不用手写 N 份。

const float TAU = 6.2831853;
const float SECTORS = 8.0;

vec2 kaleido(vec2 p, float n)
{
    float a = atan(p.y, p.x);
    float r = length(p);
    float seg = TAU / n;
    a = abs(mod(a + 0.5 * seg, seg) - 0.5 * seg);
    return vec2(cos(a), sin(a)) * r;
}

float pattern(vec2 q)
{
    float rings = sin(q.y * 28.0 + iTime * 1.2) * 0.5 + 0.5;
    float stripes = sin(q.x * 22.0 - q.y * 8.0 + iTime * 0.7);
    return 0.55 * rings + 0.45 * (0.5 + 0.5 * stripes);
}

vec3 palette(float t)
{
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // 慢旋 + 鼠标微调
    float spin = iTime * 0.18;
    if (iMouse.z > 0.0) spin += (iMouse.x / iResolution.x - 0.5) * 2.0;
    float c = cos(spin), s = sin(spin);
    p = mat2(c, -s, s, c) * p;

    vec2 q = kaleido(p, SECTORS);
    float v = pattern(q);

    vec3 col = palette(v * 0.35 + length(q) * 0.15 + iTime * 0.05);
    col *= 0.35 + 0.65 * v;

    // 扇区边界微光
    float a = atan(p.y, p.x);
    float seg = TAU / SECTORS;
    float seam = abs(mod(a + 0.5 * seg, seg) - 0.5 * seg);
    col += vec3(1.0) * exp(-seam * 90.0) * 0.08;

    // 中心亮核 + 暗角
    col += vec3(1.0, 0.85, 0.65) * exp(-dot(p, p) * 6.0) * 0.35;
    vec2 uvn = fragCoord / iResolution.xy;
    col *= 0.65 + 0.35 * pow(16.0 * uvn.x * uvn.y * (1.0 - uvn.x) * (1.0 - uvn.y), 0.25);

    fragColor = vec4(col, 1.0);
}
