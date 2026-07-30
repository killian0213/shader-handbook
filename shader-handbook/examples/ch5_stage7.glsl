// 第 5 章 · 阶梯实战 · 阶段 7：Voronoi 彩色玻璃
// 动画站点 + 细胞边界当铅条；每格独立 hue，教"噪声格子 = 材质分区"。
const float TAU = 6.2831853;

vec2 hash22(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

// 返回：x = 到最近站距离差（边界），y = 细胞 id 哈希
vec3 voronoi(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);

    float md = 8.0;
    float md2 = 8.0;
    vec2  id = vec2(0.0);

    for (int y = -1; y <= 1; y++)
    {
        for (int x = -1; x <= 1; x++)
        {
            vec2 g = vec2(float(x), float(y));
            vec2 o = hash22(i + g);
            // 站点动画
            o = 0.5 + 0.35 * sin(iTime * 0.6 + TAU * o);
            vec2 r = g + o - f;
            float d = dot(r, r);
            if (d < md)
            {
                md2 = md;
                md = d;
                id = hash22(i + g + 0.31);
            }
            else if (d < md2)
                md2 = d;
        }
    }

    // 边界：两最近站距离差
    float edge = md2 - md;
    return vec3(sqrt(md), edge, id.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec3 p = abs(fract(c.xxx + vec3(0.0, 0.666, 0.333)) * 6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec2 p  = uv * 2.8;

    vec3 v = voronoi(p);
    float cell = v.z;
    float edge = v.y;

    // 每格颜色：hash → hue，加时间慢漂
    float hue = fract(cell + iTime * 0.04);
    vec3 glass = hsv2rgb(vec3(hue, 0.55 + 0.25 * hash22(vec2(cell)).x, 0.65 + 0.25 * v.x));

    // 细胞内部渐变：距站点中心渐亮，模拟透光
    glass *= 0.55 + 0.55 * exp(-v.x * 3.5);

    // 铅条
    float lead = smoothstep(0.045, 0.012, edge);
    vec3 col = mix(vec3(0.06, 0.06, 0.07), glass, lead);

    // 边缘高光
    col += vec3(1.0, 0.95, 0.85) * smoothstep(0.018, 0.0, edge) * 0.35;

    // 背景暗场
    col = mix(vec3(0.02, 0.03, 0.06), col, smoothstep(1.4, 0.7, length(uv)));

    // 整体微光
    col += glass * exp(-length(uv) * 0.8) * 0.08;

    col = pow(max(col, 0.0), vec3(1.0 / 2.2));
    col += (fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.545) - 0.5) / 255.0;
    fragColor = vec4(col, 1.0);
}
