// 第 19 章 · Overshoot 痤疮对照（左坏右好）
// 左：步长过大，薄环面被一步跨过 → 黑洞/闪烁感
// 右：t += clamp(d, minStep, maxStep) + 命中阈值 → 稳定
#define MAX_STEPS 64

float sdTorus(vec3 p, vec2 t)
{
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float map(vec3 p)
{
    float d = sdTorus(p, vec2(0.85, 0.08)); // 故意做薄
    d = min(d, length(p - vec3(0.0, 0.0, 0.0)) - 0.35);
    d = min(d, p.y + 0.9);
    return d;
}

vec3 calcNormal(vec3 p)
{
    vec2 e = vec2(0.0015, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)));
}

vec3 render(vec3 ro, vec3 rd, bool fix)
{
    float t = 0.0;
    float hit = -1.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        float d = map(ro + rd * t);
        if (fix) {
            if (d < 0.001 * t) { hit = 1.0; break; }
            t += clamp(d, 0.02, 0.5);
        } else {
            // 坏：大步长 + 过松阈值 → 薄面易被跨过
            if (d < 0.02) { hit = 1.0; break; }
            t += max(d, 0.35);
        }
        if (t > 20.0) break;
    }

    vec3 sky = mix(vec3(0.15, 0.18, 0.28), vec3(0.45, 0.55, 0.75), rd.y * 0.5 + 0.5);
    if (hit < 0.0) return sky;

    vec3 pos = ro + rd * t;
    vec3 nor = calcNormal(pos);
    vec3 lig = normalize(vec3(0.5, 0.8, 0.3));
    float dif = clamp(dot(nor, lig), 0.0, 1.0);
    vec3 mate = vec3(0.75, 0.72, 0.68);
    // 坏侧：若法线炸掉会变黑 —— 用 nor 长度检测
    if (!fix && (any(isnan(nor)) || length(nor) < 0.5))
        return vec3(0.0);
    return mate * (0.2 + 0.9 * dif) + sky * 0.08;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    bool right = p.x > 0.0;
    vec2 q = p;
    q.x = abs(q.x) * 2.0 - 0.55; // 每侧各自构图

    float an = 0.9 + 0.2 * sin(iTime * 0.4);
    vec3 ro = vec3(2.6 * sin(an), 1.1, 2.6 * cos(an));
    vec3 ta = vec3(0.0, 0.1, 0.0);
    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(cw, vec3(0, 1, 0)));
    vec3 cv = cross(cu, cw);
    vec3 rd = normalize(q.x * cu + q.y * cv + 1.8 * cw);

    vec3 col = render(ro, rd, right);

    // 中线
    col = mix(col, vec3(1.0, 0.95, 0.4), 1.0 - smoothstep(0.0, 0.008, abs(p.x)));

    // 角标：左红=坏，右绿=好
    if (p.y > 0.82) {
        if (p.x < -0.55) col = mix(col, vec3(0.9, 0.2, 0.15), 0.85);
        if (p.x > 0.55)  col = mix(col, vec3(0.2, 0.85, 0.35), 0.85);
    }

    col = pow(max(col, 0.0), vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
