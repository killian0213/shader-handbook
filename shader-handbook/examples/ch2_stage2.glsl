// 第 2 章 · 坐标阶梯 · 阶段 2：平移 = 减坐标
// 想让形状「动」，不是改 SDF 公式，而是 p - offset。
// offset 往右 → 形状在屏幕上往右；背景网格不动，运动一目了然。

const float TAU = 6.2831853;

float sdCircle(vec2 p, float r) { return length(p) - r; }
float sdBox(vec2 p, vec2 b) { vec2 d = abs(p) - b; return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0); }

float gridLines(vec2 p, float scale)
{
    vec2 g = abs(fract(p * scale - 0.5) - 0.5);
    float lx = smoothstep(0.015, 0.0, g.x);
    float ly = smoothstep(0.015, 0.0, g.y);
    return max(lx, ly);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float aa = 2.0 / iResolution.y;

    // 背景网格：画在【未平移】的 p 上
    float g = gridLines(p, 6.0);
    vec3 col = mix(vec3(0.03, 0.035, 0.06), vec3(0.12, 0.13, 0.20), g);

    // 轨道中心随时间画圆；也可改 iMouse 手动拖
    vec2 ctr = (iMouse.z > 0.0)
        ? (2.0 * iMouse.xy - iResolution.xy) / iResolution.y
        : vec2(0.38 * cos(iTime * 0.9), 0.28 * sin(iTime * 1.15));

    // 平移坐标，不是平移屏幕
    vec2 q = p - ctr;

    // 每 3 秒在圆与方之间切换
    bool square = mod(floor(iTime / 3.0), 2.0) > 0.5;
    float d = square ? sdBox(q, vec2(0.18)) : sdCircle(q, 0.22);

    float body = smoothstep(aa, -aa, d);
    float edge = exp(-abs(d) * 55.0);
    float glow = exp(-max(d, 0.0) * 8.0);

    vec3 shapeCol = square ? vec3(1.0, 0.55, 0.22) : vec3(0.30, 0.88, 1.00);
    col = mix(col, shapeCol * 0.25, body);
    col += shapeCol * edge * 1.4;
    col += shapeCol * glow * 0.35;

    // 轨道虚线：同样用 p（世界）而非 q（局部）
    float orbit = abs(length(p - ctr) - 0.38) - 0.004;
    col += vec3(0.35, 0.40, 0.55) * smoothstep(0.012, 0.0, orbit) * 0.35;

    fragColor = vec4(col, 1.0);
}
