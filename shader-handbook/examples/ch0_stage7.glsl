// 第 0 章 · 四种场对照（教学可跑）
// 左上距离场 / 右上密度场 / 左下高度场 / 右下图案场
float hash21(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float vnoise(vec2 p)
{
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1, 0));
    float c = hash21(i + vec2(0, 1));
    float d = hash21(i + vec2(1, 1));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p)
{
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * vnoise(p);
        p = p * 2.02 + 17.0;
        a *= 0.5;
    }
    return v;
}

vec2 voronoi(vec2 p)
{
    vec2 n = floor(p), f = fract(p);
    float md = 8.0, mid = 0.0;
    for (int j = -1; j <= 1; j++)
    for (int i = -1; i <= 1; i++) {
        vec2 g = vec2(float(i), float(j));
        vec2 o = 0.5 + 0.5 * sin(iTime + 6.2831 * vec2(hash21(n + g), hash21(n + g + 19.7)));
        vec2 r = g + o - f;
        float d = dot(r, r);
        if (d < md) { md = d; mid = hash21(n + g); }
    }
    return vec2(sqrt(md), mid);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // 象限 id 与象限内 [0,1]^2
    float qx = step(0.5, uv.x);
    float qy = step(0.5, uv.y);
    vec2 quv = fract(uv * 2.0);

    // 象限本地：中心原点，近似方形
    vec2 local = (quv - 0.5) * 2.0;
    local.x *= (iResolution.x * 0.5) / (iResolution.y * 0.5); // 半屏宽高比

    vec3 col = vec3(0.06, 0.07, 0.10);

    if (qx < 0.5 && qy > 0.5) {
        // 左上：距离场
        float d = length(local) - 0.55;
        col = (d < 0.0)
            ? mix(vec3(0.10, 0.45, 0.95), vec3(0.03, 0.10, 0.28), clamp(-d * 1.8, 0.0, 1.0))
            : mix(vec3(0.95, 0.50, 0.18), vec3(0.10, 0.08, 0.08), clamp(d * 1.5, 0.0, 1.0));
        col = mix(col, vec3(1.0), 1.0 - smoothstep(0.0, 0.02, abs(d)));
    } else if (qx > 0.5 && qy > 0.5) {
        // 右上：密度场
        float dens = fbm(local * 1.8 + vec2(0.0, -iTime * 0.18));
        dens = smoothstep(0.32, 0.72, dens);
        col = mix(vec3(0.04, 0.06, 0.12), vec3(0.85, 0.92, 1.0), dens);
        col += dens * dens * vec3(0.25, 0.4, 0.75) * 0.4;
    } else if (qx < 0.5 && qy < 0.5) {
        // 左下：高度场剪影
        float x = local.x;
        float h = 0.18 * sin(x * 2.8 + iTime)
                + 0.09 * sin(x * 6.5 - iTime * 0.6)
                + 0.04 * sin(x * 12.0 + 1.3);
        float ground = local.y + 0.2 - h;
        col = mix(vec3(0.16, 0.34, 0.14), vec3(0.55, 0.72, 0.92),
                  smoothstep(0.0, 0.025, ground));
        col = mix(col, vec3(1.0, 0.92, 0.35), 1.0 - smoothstep(0.0, 0.018, abs(ground)));
    } else {
        // 右下：Voronoi 图案场
        vec2 c = voronoi(local * 3.0);
        vec3 pal = 0.5 + 0.5 * cos(6.28318 * (c.y + vec3(0.0, 0.33, 0.67)));
        col = mix(pal * 0.3, pal, smoothstep(0.28, 0.02, c.x));
    }

    // 分隔十字
    float gx = 1.0 - smoothstep(0.0, 0.0035, abs(uv.x - 0.5));
    float gy = 1.0 - smoothstep(0.0, 0.0035, abs(uv.y - 0.5));
    col = mix(col, vec3(0.95, 0.88, 0.55), max(gx, gy));

    fragColor = vec4(col, 1.0);
}
