// 第 3 章 · 阶梯实战 · 阶段 7：布尔 Logo —— CSG 拼出可识别的标志
// 圆 + 盒 + 胶囊，用并/交/差拼成抽象字母 A；描边 + 填充，教 Logo 级 CSG。
const float TAU = 6.2831853;

const vec3 CY = vec3(0.36, 0.90, 1.00);
const vec3 AM = vec3(1.00, 0.74, 0.32);
const vec3 MG = vec3(1.00, 0.34, 0.72);

float sdCircle(vec2 p, float r)
{
    return length(p) - r;
}

float sdBox(vec2 p, vec2 b, float r)
{
    vec2 d = abs(p) - b + r;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - r;
}

float sdSegment(vec2 p, vec2 a, vec2 b, float w)
{
    vec2  pa = p - a;
    vec2  ba = b - a;
    float h  = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - w;
}

float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

vec2 rotCW(vec2 p, float a)
{
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c) * p;
}

float fill(float d, float aa)
{
    return smoothstep(aa, -aa, d);
}

float stroke(float d, float w, float aa)
{
    return smoothstep(aa, -aa, abs(d) - w);
}

// Logo 距离场：左斜 / 右斜 / 横杠 / 外圈，全部用并(min)与差(max,-)组合。
float logoSDF(vec2 p)
{
    vec2 q = rotCW(p, -0.08);

    // 左斜腿：胶囊从底左到顶中
    float legL = sdSegment(q, vec2(-0.22, -0.38), vec2(-0.04, 0.38), 0.055);

    // 右斜腿
    float legR = sdSegment(q, vec2(0.22, -0.38), vec2(0.04, 0.38), 0.055);

    // 横杠：圆角盒
    float bar = sdBox(q - vec2(0.0, -0.02), vec2(0.165, 0.038), 0.018);

    // 并集：三根笔画合成 A
    float glyph = min(legL, legR);
    glyph = min(glyph, bar);

    // 差集：挖掉中间三角，让 A 中空
    float hole = sdSegment(q, vec2(-0.13, -0.10), vec2(0.13, -0.10), 0.028);
    glyph = max(glyph, -hole);

    // 外圈徽章：圆环与 glyph 并在一起
    float ring = abs(length(q) - 0.52) - 0.028;
    float badge = smin(glyph, ring, 0.04);

    // 顶点小圆点：强调"字母"感
    float dot = sdCircle(q - vec2(0.0, 0.36), 0.045);
    return min(badge, dot);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2  p  = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float aa = 2.0 / iResolution.y;

    vec3 col = mix(vec3(0.04, 0.06, 0.11), vec3(0.01, 0.02, 0.05),
                   smoothstep(0.1, 1.3, length(p)));

    float d = logoSDF(p);

    // 外发光：k/d 长尾
    col += CY * 0.006 / max(abs(d), 0.005);

    // 填充：渐变模拟左上光源
    float lit = smoothstep(-0.6, 0.7, p.y * 0.75 - p.x * 0.55);
    vec3  fillCol = mix(vec3(0.08, 0.14, 0.24), vec3(0.18, 0.32, 0.48), lit);
    col = mix(col, fillCol, fill(d, aa));

    // 描边：双层 —— 外白内青
    col = mix(col, vec3(0.95, 0.98, 1.00), stroke(d, 0.006, aa));
    col = mix(col, CY, stroke(d, 0.003, aa));

    // 贴身辉光
    col += AM * exp(-abs(d) * 85.0) * 0.35;
    col += MG * exp(-abs(d) * 45.0) * 0.12;

    // 暗角
    vec2 uvq = fragCoord / iResolution.xy;
    col *= 0.55 + 0.45 * pow(16.0 * uvq.x * uvq.y * (1.0 - uvq.x) * (1.0 - uvq.y), 0.30);

    col += (fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.545) - 0.5) / 255.0;
    fragColor = vec4(col, 1.0);
}
