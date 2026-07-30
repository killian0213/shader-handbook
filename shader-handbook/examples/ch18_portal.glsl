// 第 18 章 · 效果配方 · 传送门 / Droste 螺旋
// 心法：极坐标 log 映射 + 递归缩放旋转；环面隧道感。
// 语料对照：Portal / Droste / recursive ring 类

const float TAU = 6.2831853;

vec3 palette(float t)
{
    return 0.5 + 0.5 * cos(TAU * (vec3(0.0, 0.33, 0.67) + t));
}

vec3 portalLayer(vec2 p, float scale, float rot, float t)
{
    float r = length(p);
    float a = atan(p.y, p.x) + rot;

    // log 极坐标：缩放 + 角度折叠 → 自相似
    float u = log(max(r, 1e-4)) * scale - t * 0.3;
    float v = a / TAU;

    float rings = abs(sin(u * TAU * 2.0)) * 0.5 + 0.5;
    float spokes = abs(sin(v * 12.0 + u * 3.0)) * 0.5 + 0.5;
    float depth = fract(u * 0.5);

    vec3 col = palette(depth + spokes * 0.2);
    col *= rings * (0.4 + 0.6 * spokes);
    col *= exp(-r * 0.6);
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = (uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);
    float t = iTime;

    // 递归三层：每层缩小旋转，模拟「穿进门里还有门」
    vec3 col = vec3(0.0);
    float w = 1.0;
    vec2 q = p;
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        col += portalLayer(q, 2.5 + fi * 0.3, t * 0.15 + fi * 0.5, t + fi) * w;
        q = q * 1.8;
        q *= mat2(cos(0.6 + fi * 0.2), sin(0.6 + fi * 0.2),
                  -sin(0.6 + fi * 0.2), cos(0.6 + fi * 0.2));
        w *= 0.45;
    }

    // 中心 portal 环
    float r = length(p);
    float ring = abs(r - 0.35 - 0.02 * sin(t * 2.0));
    col += palette(t * 0.1) * exp(-ring * 80.0) * 1.5;
    col += vec3(0.9, 0.95, 1.0) * exp(-r * 8.0) * 0.2;

    vec3 bg = vec3(0.02, 0.025, 0.05);
    col = mix(bg, col, smoothstep(0.0, 0.05, col.r + col.g + col.b));

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
