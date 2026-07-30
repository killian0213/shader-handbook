// 第 19 章 · 性能调试 · 软阴影采样代价可视化
// 颜色 = shadow rays / MAX；步长越小越精确、越"热"。

const int SHADOW_STEPS = 32;

float sdRoundBox(vec3 p, vec3 b, float r)
{
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

float mapScene(vec3 p)
{
    float g = sdRoundBox(p, vec3(2.5, 0.05, 2.5), 0.02);
    float a = sdRoundBox(p - vec3(-0.7, 0.35, 0.3), vec3(0.35, 0.55, 0.35), 0.06);
    float b = sdRoundBox(p - vec3(0.8, 0.25, -0.4), vec3(0.3, 0.45, 0.3), 0.05);
    float c = sdRoundBox(p - vec3(0.0, 0.55, 0.0), vec3(0.25, 0.25, 0.25), 0.04);
    return min(g, min(a, min(b, c)));
}

vec3 heat(float x)
{
    x = clamp(x, 0.0, 1.0);
    return mix(vec3(0.08, 0.15, 0.35), vec3(1.0, 0.35, 0.08), smoothstep(0.2, 1.0, x));
}

float softShadow(vec3 ro, vec3 rd, float k, out float cost)
{
    float res = 1.0;
    float t = 0.02;
    cost = 0.0;
    for (int i = 0; i < SHADOW_STEPS; i++) {
        cost += 1.0;
        float h = mapScene(ro + rd * t);
        res = min(res, k * h / t);
        t += clamp(h, 0.02, 0.25);
        if (res < 0.002 || t > 8.0) break;
    }
    return clamp(res, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float t = iTime * 0.35;

    vec3 ro = vec3(sin(t) * 1.2, 1.1, 2.8 + cos(t) * 0.5);
    vec3 ta = vec3(0.0, 0.35, 0.0);
    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(cw, vec3(0, 1, 0)));
    vec3 cv = cross(cu, cw);
    vec3 rd = normalize(uv.x * cu + uv.y * cv + 1.3 * cw);

    float depth = 0.1;
    vec3 col = mix(vec3(0.55, 0.65, 0.82), vec3(0.72, 0.78, 0.92), uv.y * 0.5 + 0.5);

    for (int i = 0; i < 80; i++) {
        vec3 p = ro + rd * depth;
        float d = mapScene(p);
        if (d < 0.001) {
            vec2 e = vec2(0.001, 0.0);
            vec3 n = normalize(vec3(
                mapScene(p + e.xyy) - mapScene(p - e.xyy),
                mapScene(p + e.yxy) - mapScene(p - e.yxy),
                mapScene(p + e.yyx) - mapScene(p - e.yyx)));
            vec3 lig = normalize(vec3(0.5, 0.85, 0.3));
            float cost;
            float sh = softShadow(p + n * 0.002, lig, 16.0, cost);
            vec3 diff = vec3(0.72, 0.68, 0.62) * (0.25 + 0.75 * max(dot(n, lig), 0.0)) * sh;
            col = mix(heat(cost / float(SHADOW_STEPS)), diff, 0.45);
            break;
        }
        depth += d;
        if (depth > 12.0) break;
    }

    col = pow(max(col, 0.0), vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
