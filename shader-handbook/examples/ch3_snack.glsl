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

float sdCircle(vec2 p, float r) { return length(p) - r; }
float sdBox(vec2 p, vec2 b) {
    vec2 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    int st = snackStage();
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec3 col = vec3(0.02, 0.02, 0.05);
    float d = sdCircle(p, 0.45);

    if (st >= 1) d = abs(sdCircle(p, 0.42)) - 0.04;
    if (st >= 2) {
        float aa = 1.5 / iResolution.y;
        float m = smoothstep(aa, -aa, d);
        col = mix(col, vec3(1.0, 0.3, 0.55), m);
    } else if (st == 0) {
        col = mix(col, vec3(0.3, 0.5, 1.0), smoothstep(0.01, -0.01, d));
    } else if (st == 1) {
        col = mix(col, vec3(0.3, 0.5, 1.0), smoothstep(0.01, -0.01, d));
    }
    if (st >= 3) {
        float glow = exp(-max(d, 0.0) * 18.0);
        col += vec3(1.0, 0.25, 0.55) * glow * 0.55;
        col += vec3(0.4, 0.7, 1.0) * exp(-max(d, 0.0) * 6.0) * 0.25;
    }
    if (st >= 4) {
        float cut = sdBox(p - vec2(0.0, -0.02), vec2(0.18, 0.06));
        float ring = abs(sdCircle(p, 0.42)) - 0.04;
        float logo = max(ring, -cut);
        float aa = 1.5 / iResolution.y;
        float m = smoothstep(aa, -aa, logo);
        float pulse = 0.7 + 0.3 * sin(iTime * 5.0);
        col = vec3(0.02, 0.02, 0.05);
        col = mix(col, vec3(1.0, 0.35, 0.6) * pulse, m);
        col += vec3(1.0, 0.3, 0.55) * exp(-max(logo, 0.0) * 16.0) * 0.6 * pulse;
        col += vec3(0.3, 0.8, 1.0) * exp(-max(logo, 0.0) * 5.0) * 0.3;
        // 星尘
        float star = 0.0;
        for (int i = 0; i < 12; i++) {
            float fi = float(i);
            vec2 sp = 0.85 * vec2(sin(fi * 2.7), cos(fi * 1.9 + iTime * 0.2));
            star += exp(-length(p - sp) * 80.0);
        }
        col += star * 0.5;
    }
    col = snackHud(fragCoord, col, st);
    fragColor = vec4(col, 1.0);
}
