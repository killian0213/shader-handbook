// 第 2 章 · 坐标阶梯 · 阶段 1：三种 UV 模式对照
// 同一颗 r=0.4 的圆，换坐标系就会变椭圆 —— 因为像素不是正方形。
// (a) fragCoord 原样映射：除以 iResolution.xy → 宽屏上圆被拉扁
// (b) [0,1] uv 中心化：仍不等比，圆还是椭圆
// (c) iq 式 p = (2*fragCoord - R) / R.y：纵向固定 [-1,1]，圆保持正圆
//
// 核心：除以 .y（高度）而不是 .xy，才能让「一个单位」在 x/y 上等长。

const float DEMO_R = 0.40;

float sdCircle(vec2 p, float r) { return length(p) - r; }

vec3 heat(vec2 fc)
{
    vec2 v = fc / iResolution.xy;
    return mix(vec3(0.02, 0.04, 0.12), vec3(1.0, 0.35, 0.08), v.x * 0.6 + v.y * 0.4);
}

vec3 drawShape(vec2 q, float r, vec3 tint, vec3 bg)
{
    float d = sdCircle(q, r);
    vec3 col = mix(bg, tint, smoothstep(0.008, -0.008, d) * 0.85);
    col += tint * exp(-abs(d) * 80.0) * 1.2;
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    float aa = 2.0 / iResolution.y;
    int panel = int(clamp(floor(uv.x * 3.0), 0.0, 2.0));

    vec3 tintA = vec3(0.35, 0.85, 1.00);
    vec3 tintB = vec3(1.00, 0.72, 0.28);
    vec3 tintC = vec3(0.82, 0.42, 1.00);
    vec3 col;

    if (panel == 0) {
        // (a) fragCoord 热力 + xy 分别归一化（经典「椭圆」陷阱）
        vec2 q = (fragCoord - 0.5 * iResolution.xy) / iResolution.xy;
        col = heat(fragCoord);
        col = drawShape(q, DEMO_R, tintA, col);
    } else if (panel == 1) {
        // (b) [0,1] uv 中心化；x 乘 aspect 仍不够 —— 圆仍扁
        vec2 u = uv - 0.5;
        u.x *= iResolution.x / iResolution.y;
        col = vec3(u * 0.5 + 0.5, 0.22);
        col = drawShape(u, DEMO_R, tintB, col);
    } else {
        // (c) iq p：正圆
        vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
        col = vec3(0.5 + 0.5 * sin(p * 3.0 + iTime * 0.2), 0.35);
        col = drawShape(p, DEMO_R, tintC, col);
    }

    // 分屏竖线 + 底部色条
    col += vec3(0.55) * exp(-abs(fract(uv.x * 3.0) - 0.5) * 60.0) * 0.25;
    vec3 barCol = (panel == 0) ? tintA : ((panel == 1) ? tintB : tintC);
    col = mix(col, barCol * 0.5, smoothstep(aa, 0.0, uv.y - 0.035));

    fragColor = vec4(col, 1.0);
}
