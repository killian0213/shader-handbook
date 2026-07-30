// 第 2 章 · 坐标阶梯 · 阶段 3：旋转 = mat2(c,-s,s,c) * p
// rot(p, a) 把坐标系转 a 弧度；形状公式不变，只是「换了个角度看」。
// 演示：旋转矩形 SDF + 极坐标放射线，公式 rot(p,a) = mat2(c,-s,s,c)*p。

const float TAU = 6.2831853;

vec2 rot(vec2 p, float a)
{
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c) * p;
}

float sdBox(vec2 p, vec2 b)
{
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float aa = 2.0 / iResolution.y;
    float ang = iTime * 0.55;

    // 背景：极坐标放射 spokes（在未旋转的 p 上画，对比旋转后的矩形）
    float a0 = atan(p.y, p.x);
    float r0 = length(p);
    float spokes = 0.5 + 0.5 * cos(a0 * 16.0);
    vec3 col = mix(vec3(0.02, 0.025, 0.05), vec3(0.10, 0.08, 0.18), spokes);
    col *= 0.55 + 0.45 * smoothstep(1.2, 0.1, r0);

    // 旋转后的局部坐标
    vec2 q = rot(p, ang);
    float d = sdBox(q, vec2(0.42, 0.16));

    float body = smoothstep(aa, -aa, d);
    float edge = exp(-abs(d) * 60.0);
    vec3 rectCol = vec3(0.95, 0.42, 0.28);
    col = mix(col, rectCol * 0.30, body);
    col += rectCol * edge * 1.3;

    // 角点高光：四个顶点在 rot 空间里是 ±(bx,by)
    vec2 c = abs(q) - vec2(0.42, 0.16);
    float corner = exp(-dot(c, c) * 120.0);
    col += vec3(1.0, 0.85, 0.55) * corner * 4.0;

    // 中心十字：证明 rot 绕原点转
    float cross = min(smoothstep(0.012, 0.0, abs(p.x)),
                      smoothstep(0.012, 0.0, abs(p.y)));
    col += vec3(0.55, 0.65, 0.85) * cross * 0.25;

    // 外圈参考圆
    float ring = abs(r0 - 0.55) - 0.003;
    col += vec3(0.35, 0.45, 0.70) * smoothstep(0.01, 0.0, ring) * 0.4;

    fragColor = vec4(col, 1.0);
}
