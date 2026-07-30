// 第 19 章 · 步数热力图（必学调试工具）
// 场景：球 + 环面。颜色 = 用掉的步进数 / MAX_STEPS。
// 红/黄=贵，蓝/黑=便宜。优化前先看这张图。
#define MAX_STEPS 80
#define MAX_DIST  40.0

float sdSphere(vec3 p, float r) { return length(p) - r; }
float sdTorus(vec3 p, vec2 t)
{
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float map(vec3 p)
{
    float d = sdSphere(p - vec3(0.0, 1.0, 0.0), 0.7);
    d = min(d, sdTorus(p - vec3(0.0, 0.9, 0.0), vec2(1.35, 0.28)));
    d = min(d, p.y);
    return d;
}

mat3 setCamera(vec3 ro, vec3 ta)
{
    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(cw, vec3(0, 1, 0)));
    return mat3(cu, cross(cu, cw), cw);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float an = 0.6 + iTime * 0.12;
    vec3 ro = vec3(3.8 * sin(an), 1.8, 3.8 * cos(an));
    vec3 rd = setCamera(ro, vec3(0.0, 0.8, 0.0)) * normalize(vec3(p, 2.0));

    float t = 0.0;
    int steps = 0;
    for (int i = 0; i < MAX_STEPS; i++) {
        steps = i;
        float d = map(ro + rd * t);
        if (d < 0.0015 * t || t > MAX_DIST) break;
        t += d;
    }

    float cost = float(steps) / float(MAX_STEPS - 1);
    // 黑→蓝→青→黄→红
    vec3 heat = vec3(0.0);
    heat = mix(vec3(0.02, 0.05, 0.15), vec3(0.1, 0.35, 0.95), smoothstep(0.0, 0.25, cost));
    heat = mix(heat, vec3(0.1, 0.9, 0.7), smoothstep(0.25, 0.5, cost));
    heat = mix(heat, vec3(0.95, 0.9, 0.2), smoothstep(0.5, 0.75, cost));
    heat = mix(heat, vec3(0.95, 0.15, 0.1), smoothstep(0.75, 1.0, cost));

    // 未命中天空略压暗，突出物体轮廓上的步数环
    if (t > MAX_DIST) heat *= 0.35;

    // 底部图例条
    if (p.y < -0.85) {
        float u = clamp(p.x * 0.5 + 0.5, 0.0, 1.0);
        heat = mix(vec3(0.02, 0.05, 0.15), vec3(0.1, 0.35, 0.95), smoothstep(0.0, 0.25, u));
        heat = mix(heat, vec3(0.1, 0.9, 0.7), smoothstep(0.25, 0.5, u));
        heat = mix(heat, vec3(0.95, 0.9, 0.2), smoothstep(0.5, 0.75, u));
        heat = mix(heat, vec3(0.95, 0.15, 0.1), smoothstep(0.75, 1.0, u));
    }

    fragColor = vec4(heat, 1.0);
}
