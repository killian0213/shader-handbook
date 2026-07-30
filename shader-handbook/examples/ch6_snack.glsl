// 课间餐点 · 自动分阶段（STAGE_SEC=2.75）· 鼠标拖拽 scrub
#define STAGE_N 5
#define STAGE_SEC 2.75

// —— 课间餐点通用：分阶段实时解锁 ——
// 自动：每 STAGE_SEC 秒进入下一阶段并循环
// 交互：按住鼠标左右拖 = 手动 scrub 阶段
#ifndef STAGE_N
#define STAGE_N 5
#endif
#ifndef STAGE_SEC
#define STAGE_SEC 2.75
#endif

int snackStage()
{
    if (iMouse.z > 0.0) {
        float u = clamp(iMouse.x / max(iResolution.x, 1.0), 0.0, 0.999);
        return int(u * float(STAGE_N));
    }
    return int(mod(floor(iTime / STAGE_SEC), float(STAGE_N)));
}

// 底部整条阶段指示（当前格高亮）
vec3 snackHud(vec2 frag, vec3 col, int st)
{
    vec2 uv = frag / iResolution.xy;
    if (uv.y > 0.055) return col;
    float slot = floor(uv.x * float(STAGE_N));
    float on = (int(slot) == st) ? 1.0 : 0.22;
    vec3 bar = mix(vec3(0.05, 0.06, 0.09), vec3(0.98, 0.78, 0.32), on);
    float edge = step(0.96, fract(uv.x * float(STAGE_N)));
    bar = mix(bar, vec3(0.015), edge);
    float a = smoothstep(0.055, 0.028, uv.y);
    return mix(col, bar, a);
}

const float TAU = 6.2831853;
vec3 pal(float t) {
    return vec3(0.45, 0.25, 0.55) + vec3(0.55, 0.45, 0.35) * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}
vec2 fold(vec2 p, float n) {
    float s = TAU / n;
    float a = atan(p.x, p.y);
    a = mod(a + 0.5 * s, s) - 0.5 * s;
    return length(p) * vec2(sin(a), cos(a));
}
float sdVesica(vec2 p, float r, float d) {
    p = abs(p);
    float b = sqrt(max(r * r - d * d, 0.0));
    return ((p.y - b) * d > p.x * b) ? length(p - vec2(0.0, b)) : length(p - vec2(-d, 0.0)) - r;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    int st = snackStage();
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float r = length(p);
    vec3 col = vec3(0.03, 0.02, 0.06);

    if (st == 0) {
        float rings = abs(fract(r * 5.0 - iTime * 0.2) - 0.5);
        col = mix(col, vec3(0.8, 0.7, 1.0), smoothstep(0.08, 0.0, rings));
    } else {
        float n = 8.0;
        vec2 f = (st >= 1) ? fold(p, n) : p;
        float d = abs(r - 0.55) - 0.02;
        if (st >= 2) {
            vec2 q = f - vec2(0.0, 0.42);
            float L = 0.28, W = 0.11;
            float s = L * L / W;
            d = min(d, sdVesica(q, 0.5 * (W + s), 0.5 * (s - W)));
            // 旋转整朵
            float ca = cos(iTime * 0.25), sa = sin(iTime * 0.25);
            vec2 pr = mat2(ca, -sa, sa, ca) * p;
            f = fold(pr, n);
            q = f - vec2(0.0, 0.42);
            d = sdVesica(q, 0.5 * (W + s), 0.5 * (s - W));
            d = min(d, abs(length(pr) - 0.2) - 0.015);
        }
        float m = smoothstep(0.01, -0.01, d);
        if (st >= 3) col = mix(col, pal(r * 1.5 - iTime * 0.1), m);
        else col = mix(col, vec3(0.9, 0.85, 1.0), m);
        if (st >= 4) {
            float glow = exp(-max(d, 0.0) * 14.0);
            col += pal(0.3 + iTime * 0.05) * glow * 0.45;
            float breath = 0.85 + 0.15 * sin(iTime * 2.0);
            col *= breath;
            vec2 q = fragCoord / iResolution.xy;
            col *= 0.55 + 0.45 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.35);
        }
    }
    col = snackHud(fragCoord, col, st);
    fragColor = vec4(col, 1.0);
}
