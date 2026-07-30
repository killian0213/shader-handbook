// 第 12 章 · 焦散阶梯 · 阶段 6：伪水面焦散
// 真焦散 = 光经曲面聚焦；这里用 Voronoi + 域扭曲做【亮度图案】。
// 俯视角略透视：焦散 = 地板上的亮斑，不是几何，是 mod 后的高光。

const float TAU = 6.2831853;

vec2 hash22(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(vec2(p.x * p.y, p.y * p.x));
}

// 2D Voronoi：返回到最近种子距离 + 细胞 id
vec3 voronoi(vec2 p)
{
    vec2 n = floor(p);
    vec2 f = fract(p);
    float md = 8.0;
    vec2 mg;
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = hash22(n + g);
            o = 0.5 + 0.5 * sin(iTime * 0.6 + TAU * o);
            vec2 r = g + o - f;
            float d = dot(r, r);
            if (d < md) { md = d; mg = r; }
        }
    }
    return vec3(sqrt(md), mg);
}

float causticField(vec2 uv)
{
    // 域扭曲：让 Voronoi 边界的尖角变柔和、更像水纹
    vec2 q = uv;
    q += 0.35 * vec2(sin(q.y * 3.2 + iTime), cos(q.x * 2.8 - iTime * 0.7));
    q *= 1.0 + 0.08 * sin(iTime * 0.4 + dot(q, vec2(1.3, 0.9)));

    vec3 v = voronoi(q * 4.5);
    float c1 = pow(1.0 - smoothstep(0.0, 0.55, v.x), 3.0);
    vec3 v2 = voronoi(q * 7.0 + 3.7);
    float c2 = pow(1.0 - smoothstep(0.0, 0.45, v2.x), 4.0);
    return c1 * 0.65 + c2 * 0.55;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // 轻微透视：远处 uv 压缩
    float persp = 0.55 + 0.45 * uv.y;
    vec2 planeUV = vec2(p.x / persp, (1.0 - uv.y) * 2.2 + iTime * 0.08);

    float caust = causticField(planeUV);

    // 池底底色：浅蓝绿渐变
    vec3 base = mix(vec3(0.05, 0.18, 0.28), vec3(0.12, 0.42, 0.52), uv.y);
    base += vec3(0.08, 0.15, 0.12) * sin(planeUV.x * 6.0) * sin(planeUV.y * 5.0) * 0.08;

    vec3 col = base;
    col += vec3(0.85, 0.98, 1.00) * caust * 1.1;
    col += vec3(1.0, 0.95, 0.75) * pow(caust, 3.0) * 0.6;

    // 水面 shimmer 高光（屏幕上方）
    float shimmer = exp(-abs(p.y - 0.55) * 5.0)
                  * (0.5 + 0.5 * sin(p.x * 12.0 + iTime * 2.0));
    col += vec3(0.7, 0.9, 1.0) * shimmer * 0.15;

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
